-- rpt_customer_lifetime_value.sql
select
    dc.customer_id,
    dc.full_name                as customer_name,
    count(distinct f.order_id)  as total_orders,
    sum(f.total_sales_amount)    as lifetime_revenue,
    sum(f.profit_amount)          as lifetime_profit
from {{ ref('fact_sales') }} f
join {{ ref('dim_customer') }} dc on f.customer_key = dc.customer_key
group by dc.customer_id, dc.full_name
order by lifetime_revenue desc