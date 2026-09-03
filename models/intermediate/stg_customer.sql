select * from {{ ref('int_customer_cleaned') }}
where is_current