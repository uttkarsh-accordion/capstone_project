with src_store as (

    select * from {{ ref('snp_store') }}
    where dbt_valid_to is null

),

transformed as (

    select
        store_id,

        initcap(trim(raw_payload:store_name::string))         as store_name,

        initcap(trim(raw_payload:address:city::string))        as city,
        upper(trim(raw_payload:address:state::string))         as state,
        trim(raw_payload:address:street::string)               as street,
        trim(raw_payload:address:country::string)              as country,

        -- Zip code validation: must be exactly 5 digits
        case
            when regexp_like(raw_payload:address:zip_code::string, '^[0-9]{5}$')
            then raw_payload:address:zip_code::string
            else null
        end as zip_code,

        case
            when not regexp_like(raw_payload:address:zip_code::string, '^[0-9]{5}$')
            then true else false
        end as is_zip_code_invalid,

        raw_payload:region::string                              as region,
        raw_payload:store_type::string                          as store_type,

        raw_payload:size_sq_ft::number                          as size_sq_ft,

        -- Size category derivation
        case
            when raw_payload:size_sq_ft::number < 5000 then 'Small'
            when raw_payload:size_sq_ft::number between 5000 and 10000 then 'Medium'
            when raw_payload:size_sq_ft::number > 10000 then 'Large'
        end as size_category,

        raw_payload:opening_date::date                          as opening_date,

        -- Store age in years
        datediff(year, raw_payload:opening_date::date, current_date()) as store_age_years,

        raw_payload:employee_count::number                      as employee_count,
        raw_payload:current_sales::number(15,2)                 as current_sales,
        raw_payload:sales_target::number(15,2)                  as sales_target,
        raw_payload:monthly_rent::number(12,2)                  as monthly_rent,
        raw_payload:manager_id::string                          as manager_id,
        raw_payload:is_active::boolean                          as is_active,

        -- Performance metrics, divide-by-zero guarded
        case
            when raw_payload:sales_target::number(15,2) > 0
            then (raw_payload:current_sales::number(15,2) / raw_payload:sales_target::number(15,2)) * 100
            else null
        end as sales_target_achievement_percentage,

        case
            when raw_payload:size_sq_ft::number > 0
            then raw_payload:current_sales::number(15,2) / raw_payload:size_sq_ft::number
            else null
        end as revenue_per_sq_ft,

        case
            when raw_payload:employee_count::number > 0
            then raw_payload:current_sales::number(15,2) / raw_payload:employee_count::number
            else null
        end as employee_efficiency,

        -- Performance issue flag: achievement below 90%
        case
            when raw_payload:sales_target::number(15,2) > 0
             and (raw_payload:current_sales::number(15,2) / raw_payload:sales_target::number(15,2)) * 100 < 90
            then true else false
        end as has_performance_issue,

        last_modified_date as _file_last_modified,
        _source_file,
        _loaded_at

    from src_store

)

select * from transformed