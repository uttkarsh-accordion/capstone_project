-- rpt_customer_purchasing_behavior.sql
select
    dc.customer_id,
    dc.full_name                as customer_name,
    count(distinct f.order_id)  as total_orders,
    sum(f.total_sales_amount)    as total_spend,
    avg(f.total_sales_amount)    as avg_order_line_value
from {{ ref('fact_sales') }} f
join {{ ref('dim_customer') }} dc on f.customer_key = dc.customer_key
group by dc.customer_id, dc.full_name
order by total_spend desc