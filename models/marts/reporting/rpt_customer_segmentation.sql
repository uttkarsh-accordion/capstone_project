-- rpt_customer_segmentation.sql
select
    dc.segment                     as loyalty_segment,
    dc.age_segment,
    count(distinct dc.customer_id) as customer_count,
    sum(f.total_sales_amount)        as total_sales_amount,
    avg(f.total_sales_amount)        as avg_sales_per_line
from {{ ref('fact_sales') }} f
join {{ ref('dim_customer') }} dc on f.customer_key = dc.customer_key
group by dc.segment, dc.age_segment
order by total_sales_amount desc