-- rpt_sales_contribution_by_role.sql
select
    de.role                    as employee_role,
    sum(f.total_sales_amount)  as total_sales_amount,
    sum(f.profit_amount)        as total_profit_amount
from {{ ref('fact_sales') }} f
join {{ ref('dim_employee') }} de on f.employee_key = de.employee_key
group by de.role
order by total_sales_amount desc