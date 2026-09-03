with src_customer as (

    select * from {{ ref('snp_customer') }}
    where dbt_valid_to is null

),

parsed as (

    select
        *,
        coalesce(
            try_to_date(raw_payload:birth_date::string, 'YYYY-MM-DD'),
            try_to_date(raw_payload:birth_date::string, 'DD-MM-YYYY'),
            try_to_date(raw_payload:birth_date::string, 'MM-DD-YYYY')
        ) as clean_birth_date
    from src_customer

),

transformed as (

    select
        customer_id,

        initcap(trim(raw_payload:first_name::string)) || ' ' ||
        initcap(trim(raw_payload:last_name::string))                    as full_name,

        -- Email: validate structure, null if malformed
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

        -- Phone: reject anything containing letters BEFORE cleaning; then validate digit count
        {{ clean_phone('raw_payload:phone') }}      as phone,
        {{ is_phone_invalid('raw_payload:phone') }} as is_phone_invalid,
        clean_birth_date                                                as birth_date,

        -- Age calculation
        datediff(year, clean_birth_date, current_date())                as age,

        -- Customer segmentation (explicit bounds, no swallowed under-18s)
        case
            when datediff(year, clean_birth_date, current_date()) < 18 then 'Minor'
            when datediff(year, clean_birth_date, current_date()) between 18 and 35 then 'Young'
            when datediff(year, clean_birth_date, current_date()) between 36 and 55 then 'Middle-aged'
            when datediff(year, clean_birth_date, current_date()) >= 56 then 'Senior'
            else 'Unknown'
        end as age_segment,

        initcap(trim(raw_payload:address:city::string))                 as city,
        upper(trim(raw_payload:address:state::string))                  as state,
        trim(raw_payload:address:street::string)                        as street,
        trim(raw_payload:address:zip_code::string)                      as zip_code,

        last_modified_date,
        _source_file,
        _loaded_at

    from parsed

)

select * from transformed