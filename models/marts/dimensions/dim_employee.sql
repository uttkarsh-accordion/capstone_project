with employee_agg as (

    select
        employee_id,
        count(distinct order_id)  as orders_processed,
        sum(order_revenue)        as total_sales_amount
    from {{ ref('stg_order_header') }}
    group by employee_id

)

select
    {{ dbt_utils.generate_surrogate_key(['e.employee_id']) }} as employee_key,

    e.employee_id,
    e.full_name,
    e.role,
    e.work_location,
    e.tenure_years as tenure,
    e.email,
    e.phone,
    e.target_achievement_percentage,

    coalesce(a.orders_processed, 0)   as orders_processed,
    coalesce(a.total_sales_amount, 0) as total_sales_amount

from {{ ref('stg_employee') }} e
left join employee_agg a
    on e.employee_id = a.employee_id