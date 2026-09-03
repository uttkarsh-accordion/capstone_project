{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='order_id'
  )
}}

with source_data as (

    select
        o.value:order_id::string        as order_id,
        o.value                          as raw_payload,
        e.FILE_NAME                      as _source_file,
        e.LAST_MODIFIED                  as last_modified_date,
        current_timestamp()              as _loaded_at,
        '{{ invocation_id }}'             as _batch_id
    from {{ source('bronze_ext', 'ext_orders') }} e,
    lateral flatten(input => e.VALUE:orders_data) o

)

select * from source_data

{% if is_incremental() %}
where last_modified_date > (select max(last_modified_date) from {{ this }})
{% endif %}