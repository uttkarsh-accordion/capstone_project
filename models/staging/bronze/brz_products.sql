{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='product_id'
  )
}}

with source_data as (

    select
        f.value:product_id::string          as product_id,
        f.value                              as raw_payload,
        f.value:last_modified_date::date as record_last_modified,
        e.FILE_NAME                          as _source_file,
        e.LAST_MODIFIED                      as last_modified_date,
        current_timestamp()                  as _loaded_at,
        '{{ invocation_id }}'                 as _batch_id
    from {{ source('bronze_ext', 'ext_products') }} e,
    lateral flatten(input => e.VALUE:products_data) f

)

select * from source_data

{% if is_incremental() %}
where last_modified_date > (select max(last_modified_date) from {{ this }})
{% endif %}