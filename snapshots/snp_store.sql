{% snapshot snp_store %}

{{
    config(
      target_schema='silver',
      unique_key='store_id',
      strategy='timestamp',
      updated_at='last_modified_date',
    )
}}

select * from {{ ref('brz_stores') }}

{% endsnapshot %}