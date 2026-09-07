{% snapshot snp_customer %}
{{ config(target_schema='silver', unique_key='customer_id', strategy='timestamp', updated_at='record_last_modified') }}
select * from {{ ref('brz_customers') }}
qualify row_number() over (partition by customer_id order by record_last_modified desc, _loaded_at desc) = 1
{% endsnapshot %}