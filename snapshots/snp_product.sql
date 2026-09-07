{% snapshot snp_product %}

{{ config(
    target_schema='silver',
    unique_key='product_id',
    strategy='timestamp',
    updated_at='record_last_modified'
) }}

select * from {{ ref('brz_products') }}
qualify row_number() over (partition by product_id order by record_last_modified desc, _loaded_at desc) = 1

{% endsnapshot %}