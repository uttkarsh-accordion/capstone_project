with order_agg as (

    select
        order_id,
        employee_id,
        sum(quantity * unit_price) as order_amount
    from {{ ref('stg_orders') }}
    group by order_id, employee_id

),

employee_agg as (

    select
        employee_id,
        count(distinct order_id) as orders_processed,
        sum(order_amount)        as total_sales_amount
    from order_agg
    group by employee_id

)

select
    {{ dbt_utils.generate_surrogate_key(['e.employee_id']) }} as employee_key,

    e.employee_id,
    e.full_name,
    e.role,
    e.work_location as work_location,
    e.tenure_years as tenure,
    e.email,
    e.phone,
    e.target_achievement_percentage,

    coalesce(a.orders_processed, 0)   as orders_processed,
    coalesce(a.total_sales_amount, 0) as total_sales_amount

from {{ ref('stg_employee') }} e
left join employee_agg a
    on e.employee_id = a.employee_id