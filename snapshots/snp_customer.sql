
{% snapshot snp_customer %}
{{ config(target_schema='silver', unique_key='customer_id', strategy='check', check_cols=['raw_payload']) }}
select * from {{ ref('brz_customers') }}
qualify row_number() over (partition by customer_id order by raw_payload:last_modified_date::date desc, _loaded_at desc) = 1
{% endsnapshot %}