
{% snapshot snp_product %}
{{ config(target_schema='silver', unique_key='product_id', strategy='check', check_cols=['raw_payload']) }}
select * from {{ ref('brz_products') }}
qualify row_number() over (partition by product_id order by raw_payload:last_modified_date::date desc, _loaded_at desc) = 1
{% endsnapshot %}