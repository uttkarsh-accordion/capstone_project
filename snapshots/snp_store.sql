{% snapshot snp_store %}

{{ config(
    target_schema='silver',
    unique_key='store_id',
    strategy='timestamp',
    updated_at='record_last_modified'
) }}

select * from {{ ref('brz_stores') }}
qualify row_number() over (partition by store_id order by record_last_modified desc, _loaded_at desc) = 1

{% endsnapshot %}