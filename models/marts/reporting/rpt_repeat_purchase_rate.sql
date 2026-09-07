-- rpt_repeat_purchase_rate.sql
with customer_orders as (
    select
        customer_key,
        count(distinct order_id) as order_count
    from {{ ref('fact_sales') }}
    group by customer_key
)

select
    count(*)                                                     as total_customers,
    sum(case when order_count > 1 then 1 else 0 end)             as repeat_customers,
    (sum(case when order_count > 1 then 1 else 0 end) / count(*)) * 100 as repeat_purchase_rate_pct
from customer_orders