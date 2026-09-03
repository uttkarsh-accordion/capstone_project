with src_orders as (

    select * from {{ ref('brz_orders') }}

),

exploded as (

    select
        order_id,
        raw_payload:customer_id::string                                  as customer_id,
        raw_payload:employee_id::string                                  as employee_id,
        raw_payload:store_id::string                                     as store_id,
        raw_payload:campaign_id::string                                  as campaign_id,

        raw_payload:order_date::timestamp                                as order_date,
        raw_payload:created_at::timestamp                                as created_at,
        raw_payload:delivery_date::timestamp                             as delivery_date,
        raw_payload:estimated_delivery_date::timestamp                   as estimated_delivery_date,
        raw_payload:shipping_date::timestamp                             as shipping_date,

        initcap(trim(raw_payload:order_source::string))                  as order_source,
        initcap(trim(raw_payload:order_status::string))                  as order_status,
        initcap(trim(raw_payload:payment_method::string))                as payment_method,
        initcap(trim(raw_payload:shipping_method::string))               as shipping_method,

        raw_payload:discount_amount::number(10,2)                        as order_discount_amount,
        raw_payload:shipping_cost::number(10,2)                          as shipping_cost,
        raw_payload:tax_amount::number(10,2)                             as tax_amount,
        raw_payload:total_amount::number(10,2)                           as total_amount,

        raw_payload:billing_address                                      as billing_address,
        raw_payload:shipping_address                                     as shipping_address,

        i.value:product_id::string                                       as product_id,
        i.value:quantity::number                                         as quantity,
        i.value:unit_price::number(10,2)                                 as unit_price,
        i.value:cost_price::number(10,2)                                 as cost_price,
        i.value:discount_amount::number(10,2)                            as item_discount_amount,

        _source_file,
        last_modified_date,
        _loaded_at

    from src_orders,
    lateral flatten(input => raw_payload:order_items) i

),

with_order_totals as (

    select
        *,
        sum(quantity * unit_price - item_discount_amount) over (partition by order_id) as order_line_revenue_total
    from exploded

),

transformed as (

    select
        order_id, customer_id, employee_id, store_id, campaign_id, product_id,
        order_date, created_at, delivery_date, estimated_delivery_date, shipping_date,
        order_source, order_status, payment_method, shipping_method,
        quantity, unit_price, cost_price, item_discount_amount,

        (quantity * unit_price) - item_discount_amount                   as line_revenue,
        quantity * cost_price                                            as line_cost,

        order_discount_amount, shipping_cost, tax_amount, total_amount,

        case when order_line_revenue_total > 0
            then ((quantity * unit_price - item_discount_amount) / order_line_revenue_total) * order_discount_amount
            else 0 end as allocated_order_discount,
        case when order_line_revenue_total > 0
            then ((quantity * unit_price - item_discount_amount) / order_line_revenue_total) * shipping_cost
            else 0 end as allocated_shipping_cost,
        case when order_line_revenue_total > 0
            then ((quantity * unit_price - item_discount_amount) / order_line_revenue_total) * tax_amount
            else 0 end as allocated_tax_amount,

        ((quantity * unit_price) - item_discount_amount) - (quantity * cost_price)
            - case when order_line_revenue_total > 0 then ((quantity * unit_price - item_discount_amount) / order_line_revenue_total) * order_discount_amount else 0 end
            - case when order_line_revenue_total > 0 then ((quantity * unit_price - item_discount_amount) / order_line_revenue_total) * shipping_cost else 0 end
            - case when order_line_revenue_total > 0 then ((quantity * unit_price - item_discount_amount) / order_line_revenue_total) * tax_amount else 0 end
            as profit_amount,

        case when (quantity * unit_price - item_discount_amount) > 0 then (
            (
                ((quantity * unit_price) - item_discount_amount) - (quantity * cost_price)
                - case when order_line_revenue_total > 0 then ((quantity * unit_price - item_discount_amount) / order_line_revenue_total) * order_discount_amount else 0 end
                - case when order_line_revenue_total > 0 then ((quantity * unit_price - item_discount_amount) / order_line_revenue_total) * shipping_cost else 0 end
                - case when order_line_revenue_total > 0 then ((quantity * unit_price - item_discount_amount) / order_line_revenue_total) * tax_amount else 0 end
            ) / (quantity * unit_price - item_discount_amount)
        ) * 100 else null end as profit_margin_percentage,

        case
            when hour(created_at) >= 5 and hour(created_at) < 12 then 'Morning'
            when hour(created_at) >= 12 and hour(created_at) < 17 then 'Afternoon'
            when hour(created_at) >= 17 and hour(created_at) < 22 then 'Evening'
            else 'Night'
        end as order_time_of_day,

        year(order_date) as order_year,
        quarter(order_date) as order_quarter,
        month(order_date) as order_month,
        week(order_date) as order_week,

        datediff(day, order_date, shipping_date) as processing_days,
        datediff(day, shipping_date, delivery_date) as shipping_days,

        case
            when delivery_date is not null and delivery_date <= estimated_delivery_date then 'On Time'
            when delivery_date is not null and delivery_date > estimated_delivery_date then 'Delayed'
            when delivery_date is null and current_date() > estimated_delivery_date then 'Potentially Delayed'
            else 'In Transit'
        end as delivery_status,

        billing_address, shipping_address,
        _source_file, last_modified_date, _loaded_at

    from with_order_totals

)

select * from transformed