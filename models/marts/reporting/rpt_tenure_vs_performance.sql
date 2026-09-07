-- rpt_tenure_vs_performance.sql
select
    employee_id,
    full_name                       as employee_name,
    tenure                          as tenure_years,
    target_achievement_percentage,
    orders_processed,
    total_sales_amount
from {{ ref('dim_employee') }}
order by tenure_years desc