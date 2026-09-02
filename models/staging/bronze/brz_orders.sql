{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['order_id', 'product_id']
  )
}}

with source_data as (

    select
        o.value:order_id::string                   as order_id,
        o.value:customer_id::string                as customer_id,
        o.value:employee_id::string                as employee_id,
        o.value:store_id::string                   as store_id,
        o.value:campaign_id::string                as campaign_id,
        o.value:order_date::timestamp               as order_date,
        o.value:created_at::timestamp                as created_at,
        o.value:delivery_date::timestamp             as delivery_date,
        o.value:estimated_delivery_date::timestamp   as estimated_delivery_date,
        o.value:shipping_date::timestamp             as shipping_date,
        o.value:order_source::string                as order_source,
        o.value:order_status::string                as order_status,
        o.value:payment_method::string               as payment_method,
        o.value:shipping_method::string              as shipping_method,
        o.value:discount_amount::number(10,2)        as order_discount_amount,
        o.value:shipping_cost::number(10,2)          as shipping_cost,
        o.value:tax_amount::number(10,2)             as tax_amount,
        o.value:total_amount::number(10,2)           as total_amount,
        o.value:billing_address                     as billing_address,
        o.value:shipping_address                    as shipping_address,
        i.value:product_id::string                  as product_id,
        i.value:quantity::number                    as quantity,
        i.value:unit_price::number(10,2)             as unit_price,
        i.value:cost_price::number(10,2)             as cost_price,
        i.value:discount_amount::number(10,2)        as item_discount_amount,
        e.FILE_NAME                                  as _source_file,
        e.LAST_MODIFIED                              as last_modified_date,
        current_timestamp()                          as _loaded_at,
        '{{ invocation_id }}'                         as _batch_id
    from {{ source('bronze_ext', 'ext_orders') }} e,
    lateral flatten(input => e.VALUE:orders_data) o,
    lateral flatten(input => o.value:order_items) i

)

select * from source_data

{% if is_incremental() %}
where last_modified_date > (select max(last_modified_date) from {{ this }})
{% endif %}