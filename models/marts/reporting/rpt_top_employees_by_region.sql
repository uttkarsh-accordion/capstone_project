-- rpt_top_employees_by_region.sql
with regional_sales as (
    select
        f.region                    as sales_region,
        de.employee_id,
        de.full_name                as employee_name,
        sum(f.total_sales_amount)   as total_sales_amount
    from {{ ref('fact_sales') }} f
    join {{ ref('dim_employee') }} de on f.employee_key = de.employee_key
    group by f.region, de.employee_id, de.full_name
)

select *
from regional_sales
qualify row_number() over (partition by sales_region order by total_sales_amount desc) <= 5