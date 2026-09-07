-- rpt_sales_trend_by_region.sql
select
    dd.year                    as sales_year,
    dd.month                   as sales_month,
    f.region                   as sales_region,
    sum(f.total_sales_amount)  as total_sales_amount
from {{ ref('fact_sales') }} f
join {{ ref('dim_date') }} dd on f.date_key = dd.date_key
group by dd.year, dd.month, f.region
order by sales_year, sales_month, sales_region