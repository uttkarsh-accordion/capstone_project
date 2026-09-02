{% snapshot snp_product %}

{{
    config(
      target_schema='silver',
      unique_key='product_id',
      strategy='timestamp',
      updated_at='last_modified_date',
    )
}}

select * from {{ ref('brz_products') }}

{% endsnapshot %}