with src_customer as (

    select * from {{ ref('snp_customer') }}

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

        concat_ws(' ',
            initcap(trim(raw_payload:first_name::string)),
            initcap(trim(raw_payload:last_name::string))
        ) as full_name,

        case
            when raw_payload:email::string is null then null
            when regexp_like(raw_payload:email::string, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$')
                then lower(trim(raw_payload:email::string))
            else null
        end as email,

        {{ clean_phone('raw_payload:phone') }}      as phone,
        {{ is_phone_invalid('raw_payload:phone') }}  as is_phone_invalid,

        clean_birth_date as birth_date,

        datediff(year, clean_birth_date, '{{ var("analysis_date") }}'::date) as age,

        case
            when datediff(year, clean_birth_date, '{{ var("analysis_date") }}'::date) < 18 then 'Minor'
            when datediff(year, clean_birth_date, '{{ var("analysis_date") }}'::date) between 18 and 35 then 'Young'
            when datediff(year, clean_birth_date, '{{ var("analysis_date") }}'::date) between 36 and 55 then 'Middle-aged'
            when datediff(year, clean_birth_date, '{{ var("analysis_date") }}'::date) >= 56 then 'Senior'
            else 'Unknown'
        end as age_segment,

        initcap(trim(raw_payload:address:city::string))    as city,
        upper(trim(raw_payload:address:state::string))     as state,
        trim(raw_payload:address:street::string)           as street,
        trim(raw_payload:address:zip_code::string)         as zip_code,
        upper(trim(raw_payload:address:country::string))   as country,

        raw_payload:registration_date::date               as registration_date,
        raw_payload:last_purchase_date::date               as last_purchase_date,
        upper(trim(raw_payload:loyalty_tier::string))      as loyalty_tier,
        upper(trim(raw_payload:income_bracket::string))    as income_bracket,
        initcap(trim(raw_payload:occupation::string))      as occupation,
        raw_payload:marketing_opt_in::boolean              as marketing_opt_in,
        initcap(trim(raw_payload:preferred_payment_method::string)) as preferred_payment_method,

        dbt_valid_from,
        dbt_valid_to,
        (dbt_valid_to is null) as is_current,

        last_modified_date,
        _source_file,
        _loaded_at

    from parsed

)

select * from transformed