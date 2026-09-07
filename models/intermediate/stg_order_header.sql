with src_orders as (

    select * from {{ ref('brz_orders') }}

),

parsed as (

    select
        raw_payload:order_id::string            as order_id,
        raw_payload:customer_id::string          as customer_id,
        raw_payload:store_id::string             as store_id,
        raw_payload:employee_id::string          as employee_id,
        raw_payload:campaign_id::string           as campaign_id,

        raw_payload:order_date::timestamp                as order_date,
        raw_payload:created_at::timestamp                 as created_at,
        raw_payload:shipping_date::timestamp              as shipping_date,
        raw_payload:delivery_date::timestamp              as delivery_date,
        raw_payload:estimated_delivery_date::timestamp    as estimated_delivery_date,

        raw_payload:order_status::string      as order_status,
        raw_payload:order_source::string       as order_source,
        raw_payload:payment_method::string      as payment_method,
        raw_payload:shipping_method::string      as shipping_method,

        raw_payload:shipping_cost::number(12,2)    as order_shipping_cost,
        raw_payload:tax_amount::number(12,2)        as order_tax_amount,
        raw_payload:discount_amount::number(12,2)    as order_discount_amount,
        raw_payload:total_amount::number(12,2)        as order_total_amount,

        _source_file,
        _loaded_at

    from src_orders

),

order_item_totals as (

    select
        order_id,
        sum(line_revenue) as order_revenue,
        sum(line_cost)    as order_cost
    from {{ ref('stg_order_items') }}
    group by order_id

),

transformed as (

    select
        p.*,

        year(p.order_date)     as order_year,
        quarter(p.order_date)  as order_quarter,
        month(p.order_date)    as order_month,
        week(p.order_date)     as order_week,

        datediff(day, p.order_date, p.shipping_date)    as processing_days,
        datediff(day, p.shipping_date, p.delivery_date) as shipping_days,

        case
            when p.delivery_date is not null and p.delivery_date <= p.estimated_delivery_date then 'On Time'
            when p.delivery_date is not null and p.delivery_date >  p.estimated_delivery_date then 'Delayed'
            when p.delivery_date is null and '{{ var("analysis_date") }}'::date > p.estimated_delivery_date then 'Potentially Delayed'
            else 'In Transit'
        end as delivery_status,

        case
            when hour(p.order_date) >= 5  and hour(p.order_date) < 12 then 'Morning'
            when hour(p.order_date) >= 12 and hour(p.order_date) < 17 then 'Afternoon'
            when hour(p.order_date) >= 17 and hour(p.order_date) < 22 then 'Evening'
            else 'Night'
        end as order_time_of_day,

        t.order_revenue,
        t.order_cost,
        (t.order_revenue - t.order_cost)                                        as gross_profit,
        (t.order_revenue - t.order_cost - p.order_shipping_cost - p.order_tax_amount) as net_profit,
        case
            when t.order_revenue > 0
            then ((t.order_revenue - t.order_cost - p.order_shipping_cost - p.order_tax_amount) / t.order_revenue) * 100
            else null
        end as net_profit_margin_percentage

    from parsed p
    left join order_item_totals t
        on p.order_id = t.order_id

)

select * from transformed