with spine as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2024-04-01' as date)",
        end_date="dateadd(day, 1, cast('2024-09-27' as date))"
    ) }}

),

enriched as (

    select
        cast(date_day as date) as full_date,

        {{ dbt_utils.generate_surrogate_key(['date_day']) }} as date_key,

        year(date_day)      as year,
        quarter(date_day)   as quarter,
        month(date_day)     as month,
        week(date_day)      as week,
        dayofweek(date_day) as day_of_week,

        -- Federal holidays falling inside the 2024-04-01 to 2024-09-27 window.
        -- Hand-maintained; extend if the data window changes.
        case
            when date_day in ('2024-05-27', '2024-06-19', '2024-07-04') then true
            else false
        end as is_holiday,

        case
            when month(date_day) in (12, 1, 2) then 'Winter'
            when month(date_day) in (3, 4, 5)  then 'Spring'
            when month(date_day) in (6, 7, 8)  then 'Summer'
            else 'Fall'
        end as season

    from spine

)

select * from enriched