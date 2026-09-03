select
    {{ dbt_utils.generate_surrogate_key(['store_id']) }} as store_key,

    store_id,
    store_name,
    street,
    city,
    state,
    country,
    zip_code,
    region,
    store_type,
    opening_date,
    size_category

from {{ ref('stg_store') }}