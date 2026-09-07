{% snapshot snp_employee %}

{{ config(
    target_schema='silver',
    unique_key='employee_id',
    strategy='timestamp',
    updated_at='record_last_modified'
) }}

select * from {{ ref('brz_employees') }}
qualify row_number() over (partition by employee_id order by record_last_modified desc, _loaded_at desc) = 1

{% endsnapshot %}