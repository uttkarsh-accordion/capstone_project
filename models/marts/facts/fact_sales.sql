select
    {{ dbt_utils.generate_surrogate_key(['h.order_id', 'i.product_id']) }} as sales_key,

    h.order_id,
    dc.customer_key,
    dp.product_key,
    ds.store_key,
    dd.date_key,
    de.employee_key,

    i.quantity                  as quantity_sold,
    i.unit_price,
    i.quantity * i.unit_price   as total_sales_amount,
    i.line_cost                 as cost_amount,
    i.item_discount_amount      as discount_amount,
    i.line_profit_amount        as profit_amount,
    -- add to fact_sales.sql select list
    h.order_shipping_cost as shipping_cost,
    ds.region,
    case
        when h.order_source in ('mobile app', 'website') then 'Online'
        else 'In-Store'
    end as sales_channel,
    dc.segment as customer_segment_impact

from {{ ref('stg_order_items') }} i
join {{ ref('stg_order_header') }} h
    on i.order_id = h.order_id
left join {{ ref('dim_customer') }}  dc on h.customer_id  = dc.customer_id and dc.is_current
left join {{ ref('dim_product') }}   dp on i.product_id   = dp.product_id
left join {{ ref('dim_store') }}     ds on h.store_id     = ds.store_id
left join {{ ref('dim_date') }}      dd on cast(h.order_date as date) = dd.full_date
left join {{ ref('dim_employee') }}  de on h.employee_id  = de.employee_id