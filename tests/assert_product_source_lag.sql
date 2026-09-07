with product_max as (
    select max(record_last_modified) as max_date
    from {{ ref('brz_products') }}
),

other_max as (
    select max(record_last_modified) as max_date
    from {{ ref('brz_customers') }}
)

select *
from product_max, other_max
where datediff(day, product_max.max_date, other_max.max_date) <> 12