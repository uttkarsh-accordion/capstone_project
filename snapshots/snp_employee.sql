{% snapshot snp_employee %}

{{
    config(
      target_schema='silver',
      unique_key='employee_id',
      strategy='timestamp',
      updated_at='last_modified_date',
    )
}}

select * from {{ ref('brz_employees') }}

{% endsnapshot %}