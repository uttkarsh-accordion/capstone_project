with line_items as (

    select * from {{ ref('stg_orders') }}

),

customer_at_order_time as (

    select
        li.order_id,
        li.product_id,
        dc.customer_key
    from line_items li
    left join {{ ref('dim_customer') }} dc
        on li.customer_id = dc.customer_id
       and li.order_date >= dc.valid_from
       and (dc.valid_to is null or li.order_date < dc.valid_to)

)

select
    {{ dbt_utils.generate_surrogate_key(['li.order_id', 'li.product_id']) }} as sales_key,

    li.order_id,
    c.customer_key,
    dp.product_key,
    ds.store_key,
    dd.date_key,
    de.employee_key,

    li.quantity                 as quantity_sold,
    li.unit_price,
    li.quantity * li.unit_price as total_sales_amount,
    li.line_cost                as cost_amount,
    li.item_discount_amount     as discount_amount,
    li.allocated_shipping_cost  as shipping_cost,
    li.profit_amount,

    ds.region,
    case
        when li.order_source in ('mobile app', 'website') then 'Online'
        else 'In-Store'
    end as sales_channel,
    dc.segment as customer_segment_impact

from line_items li
join customer_at_order_time c
    on li.order_id = c.order_id and li.product_id = c.product_id
left join {{ ref('dim_customer') }}  dc on c.customer_key  = dc.customer_key
left join {{ ref('dim_product') }}   dp on li.product_id   = dp.product_id
left join {{ ref('dim_store') }}     ds on li.store_id     = ds.store_id
left join {{ ref('dim_date') }}      dd on cast(li.order_date as date) = dd.full_date
left join {{ ref('dim_employee') }}  de on li.employee_id  = de.employee_id