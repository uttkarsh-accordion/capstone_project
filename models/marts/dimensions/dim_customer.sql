select
    {{ dbt_utils.generate_surrogate_key(['customer_id', 'dbt_valid_from']) }} as customer_key,

    customer_id,
    full_name,
    email,
    phone,
    city,
    state,
    street,
    zip_code,
    country,
    age,
    age_segment,
    loyalty_tier as segment,
    registration_date,

    dbt_valid_from as valid_from,
    dbt_valid_to   as valid_to,
    is_current

from {{ ref('int_customer_cleaned') }}