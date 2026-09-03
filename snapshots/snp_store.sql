{% snapshot snp_store %}
{{ config(target_schema='silver', unique_key='store_id', strategy='check', check_cols=['raw_payload']) }}
select * from {{ ref('brz_stores') }}
qualify row_number() over (partition by store_id order by raw_payload:last_modified_date::date desc, _loaded_at desc) = 1
{% endsnapshot %}