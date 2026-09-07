-- rpt_top_selling_products.sql
select
    dp.product_id,
    dp.product_name,
    sum(f.quantity_sold)       as total_units_sold,
    sum(f.total_sales_amount)  as total_revenue
from {{ ref('fact_sales') }} f
join {{ ref('dim_product') }} dp on f.product_key = dp.product_key
group by dp.product_id, dp.product_name
order by total_revenue desc