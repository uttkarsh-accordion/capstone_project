with src_orders as (

    select * from {{ ref('brz_orders') }}

),

exploded as (

    select
        raw_payload:order_id::string as order_id,

        i.value:product_id::string        as product_id,
        i.value:quantity::number           as quantity,
        i.value:unit_price::number(12,2)     as unit_price,
        i.value:cost_price::number(12,2)      as cost_price,
        i.value:discount_amount::number(12,2)  as item_discount_amount,

        _source_file,
        _loaded_at

    from src_orders,
    lateral flatten(input => raw_payload:order_items) i

),

merged as (

    select
        order_id,
        product_id,
        sum(quantity)                         as quantity,
        -- unit_price/cost_price assumed constant per product within an order;
        -- take any one value rather than averaging
        max(unit_price)                       as unit_price,
        max(cost_price)                        as cost_price,
        sum(item_discount_amount)               as item_discount_amount,
        max(_source_file)                       as _source_file,
        max(_loaded_at)                         as _loaded_at
    from exploded
    group by order_id, product_id

),

transformed as (

    select
        *,
        (quantity * unit_price) - item_discount_amount              as line_revenue,
        quantity * cost_price                                        as line_cost,
        ((quantity * unit_price) - item_discount_amount)
            - (quantity * cost_price)                                as line_profit_amount,
        case
            when (quantity * unit_price - item_discount_amount) > 0
            then (
                (((quantity * unit_price - item_discount_amount) - (quantity * cost_price)))
                / (quantity * unit_price - item_discount_amount)
            ) * 100
            else null
        end as line_profit_margin_percentage
    from merged

)

select * from transformed