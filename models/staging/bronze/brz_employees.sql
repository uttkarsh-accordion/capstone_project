{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='employee_id'
  )
}}

with source_data as (

    select
        f.value:employee_id::string         as employee_id,
        f.value                              as raw_payload,
        e.FILE_NAME                          as _source_file,
        e.LAST_MODIFIED                      as last_modified_date,
        current_timestamp()                  as _loaded_at,
        '{{ invocation_id }}'                 as _batch_id
    from {{ source('bronze_ext', 'ext_employees') }} e,
    lateral flatten(input => e.VALUE:employees_data) f

)

select * from source_data

{% if is_incremental() %}
where last_modified_date > (select max(last_modified_date) from {{ this }})
{% endif %}