-- rpt_sales_by_category.sql
select
    dp.category                as product_category,
    sum(f.total_sales_amount)  as total_sales_amount,
    sum(f.profit_amount)       as total_profit_amount
from {{ ref('fact_sales') }} f
join {{ ref('dim_product') }} dp on f.product_key = dp.product_key
group by dp.category
order by total_sales_amount desc