{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='store_id'
  )
}}

with source_data as (

    select
        f.value:store_id::string            as store_id,
        f.value                              as raw_payload,
        e.FILE_NAME                          as _source_file,
        e.LAST_MODIFIED                      as last_modified_date,
        current_timestamp()                  as _loaded_at,
        '{{ invocation_id }}'                 as _batch_id
    from {{ source('bronze_ext', 'ext_stores') }} e,
    lateral flatten(input => e.VALUE:stores_data) f

)

select * from source_data

{% if is_incremental() %}
where last_modified_date > (select max(last_modified_date) from {{ this }})
{% endif %}