with src_employee as (

    select * from {{ ref('snp_employee') }}
    where dbt_valid_to is null

),

transformed as (

    select
        employee_id,

        initcap(trim(raw_payload:first_name::string)) || ' ' ||
        initcap(trim(raw_payload:last_name::string))                   as full_name,

        -- Role standardization
        case
            when lower(trim(raw_payload:role::string)) = 'store manager' then 'Manager'
            when lower(trim(raw_payload:role::string)) = 'sales associate' then 'Associate'
            else initcap(trim(raw_payload:role::string))
        end as role,

        raw_payload:department::string                                 as department,
        raw_payload:work_location::string                              as work_location,

        -- Email validation
        case
            when raw_payload:email::string is null then null
            when regexp_like(raw_payload:email::string, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$')
                then lower(trim(raw_payload:email::string))
            else null
        end as email,

        case
            when raw_payload:email::string is not null
             and not regexp_like(raw_payload:email::string, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$')
            then true else false
        end as is_email_invalid,

        -- Phone validation (same logic as customer)
        case
            when raw_payload:phone::string is null then null
            when regexp_like(raw_payload:phone::string, '.*[A-Za-z].*') then null
            when length(regexp_replace(raw_payload:phone::string, '[^0-9]', '')) = 10
                then regexp_replace(raw_payload:phone::string, '[^0-9]', '')
            when length(regexp_replace(raw_payload:phone::string, '[^0-9]', '')) = 11
             and left(regexp_replace(raw_payload:phone::string, '[^0-9]', ''), 1) = '1'
                then substr(regexp_replace(raw_payload:phone::string, '[^0-9]', ''), 2)
            else null
        end as phone,

        case
            when raw_payload:phone::string is null then false
            when regexp_like(raw_payload:phone::string, '.*[A-Za-z].*') then true
            when length(regexp_replace(raw_payload:phone::string, '[^0-9]', '')) = 10 then false
            when length(regexp_replace(raw_payload:phone::string, '[^0-9]', '')) = 11
             and left(regexp_replace(raw_payload:phone::string, '[^0-9]', ''), 1) = '1' then false
            else true
        end as is_phone_invalid,

        raw_payload:date_of_birth::date                                 as date_of_birth,
        raw_payload:hire_date::date                                     as hire_date,

        -- Tenure in years
        datediff(year, raw_payload:hire_date::date, current_date())     as tenure_years,

        initcap(trim(raw_payload:address:city::string))                 as city,
        upper(trim(raw_payload:address:state::string))                  as state,
        trim(raw_payload:address:street::string)                       as street,
        trim(raw_payload:address:zip_code::string)                      as zip_code,

        raw_payload:current_sales::number(12,2)                         as current_sales,
        raw_payload:sales_target::number(12,2)                          as sales_target,

        -- Target achievement %
        case
            when raw_payload:sales_target::number(12,2) > 0
            then (raw_payload:current_sales::number(12,2) / raw_payload:sales_target::number(12,2)) * 100
            else null
        end as target_achievement_percentage,

        raw_payload:salary::number(12,2)                                as salary,
        raw_payload:performance_rating::number(3,1)                    as performance_rating,
        raw_payload:employment_status::string                          as employment_status,
        raw_payload:education::string                                  as education,
        raw_payload:manager_id::string                                 as manager_id,

        last_modified_date as _file_last_modified,
        _source_file,
        _loaded_at

    from src_employee

)

select * from transformed