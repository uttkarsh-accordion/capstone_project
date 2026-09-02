with src_customer as (

    select * from {{ ref('snp_customer') }}
    where dbt_valid_to is null

),

transformed as (

    select
        customer_id,

        initcap(trim(raw_payload:first_name::string)) || ' ' ||
        initcap(trim(raw_payload:last_name::string))                    as full_name,

        -- Email: validate structure, null if malformed
        case
            when raw_payload:email::string is null then null
            when regexp_like(trim(raw_payload:email::string), '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$')
                then lower(trim(raw_payload:email::string))
            else null
        end as email,

        case
            when raw_payload:email::string is not null
             and not regexp_like(trim(raw_payload:email::string), '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$')
            then true else false
        end as is_email_invalid,

        -- Phone: strip non-digits, drop leading country code '1' if present, then validate 10 digits
        regexp_replace(raw_payload:phone::string, '[^0-9]', '')          as phone_digits_raw,

        case
            when length(regexp_replace(raw_payload:phone::string, '[^0-9]', '')) = 11
            and left(regexp_replace(raw_payload:phone::string, '[^0-9]', ''), 1) = '1'
                then substr(regexp_replace(raw_payload:phone::string, '[^0-9]', ''), 2)
            else regexp_replace(raw_payload:phone::string, '[^0-9]', '')
        end as phone_digits_only,

        case
            when regexp_replace(raw_payload:phone::string, '[^0-9]', '') is null then null
            when length(regexp_replace(raw_payload:phone::string, '[^0-9]', '')) = 10
                then regexp_replace(raw_payload:phone::string, '[^0-9]', '')
            when length(regexp_replace(raw_payload:phone::string, '[^0-9]', '')) = 11
            and left(regexp_replace(raw_payload:phone::string, '[^0-9]', ''), 1) = '1'
                then substr(regexp_replace(raw_payload:phone::string, '[^0-9]', ''), 2)
            else null
        end as phone,

        case
            when raw_payload:phone::string is null then false
            when length(regexp_replace(raw_payload:phone::string, '[^0-9]', '')) = 10 then false
            when length(regexp_replace(raw_payload:phone::string, '[^0-9]', '')) = 11
            and left(regexp_replace(raw_payload:phone::string, '[^0-9]', ''), 1) = '1' then false
            else true
        end as is_phone_invalid,

        raw_payload:birth_date::date                                    as birth_date,

        -- Age calculation
        datediff(year, raw_payload:birth_date::date, current_date())    as age,

        -- Customer segmentation (explicit bounds, no swallowed under-18s)
        case
            when datediff(year, raw_payload:birth_date::date, current_date()) < 18 then 'Minor'
            when datediff(year, raw_payload:birth_date::date, current_date()) between 18 and 35 then 'Young'
            when datediff(year, raw_payload:birth_date::date, current_date()) between 36 and 55 then 'Middle-aged'
            when datediff(year, raw_payload:birth_date::date, current_date()) >= 56 then 'Senior'
            else 'Unknown'
        end as age_segment,

        initcap(trim(raw_payload:address:city::string))                 as city,
        upper(trim(raw_payload:address:state::string))                  as state,
        trim(raw_payload:address:street::string)                        as street,
        trim(raw_payload:address:zip_code::string)                      as zip_code,

        last_modified_date,
        _source_file,
        _loaded_at

    from src_customer

)

select * from transformed