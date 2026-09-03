{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='customer_id'
  )
}}

with source_data as (

    select
        f.value:customer_id::string        as customer_id,
        f.value                             as raw_payload,
        f.value:last_modified_date::date as record_last_modified,
        e.FILE_NAME                         as _source_file,
        e.LAST_MODIFIED                     as last_modified_date,
        current_timestamp()                 as _loaded_at,
        '{{ invocation_id }}'                as _batch_id
    from {{ source('bronze_ext', 'ext_customers') }} e,
    lateral flatten(input => e.VALUE:customers_data) f

)

select * from source_data

{% if is_incremental() %}
where last_modified_date > (select max(last_modified_date) from {{ this }})
{% endif %}