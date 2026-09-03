

{% snapshot snp_employee %}
{{ config(target_schema='silver', unique_key='employee_id', strategy='check', check_cols=['raw_payload']) }}
select * from {{ ref('brz_employees') }}
qualify row_number() over (partition by employee_id order by raw_payload:last_modified_date::date desc, _loaded_at desc) = 1
{% endsnapshot %}