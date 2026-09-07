with src_product as (

    select * from {{ ref('snp_product') }}
    where dbt_valid_to is null

),

transformed as (

    select
        product_id,

        initcap(trim(raw_payload:name::string))              as product_name,

        -- Full description: name + short_description + technical_specs
        initcap(trim(raw_payload:name::string)) || ' - ' ||
        raw_payload:short_description::string || '. ' ||
        raw_payload:technical_specs::string                   as full_description,

        -- Hierarchical categorization, Pascal Case normalized
        initcap(trim(raw_payload:category::string))           as category,
        initcap(trim(raw_payload:subcategory::string))         as subcategory,
        initcap(trim(raw_payload:product_line::string))        as product_line,

        initcap(trim(raw_payload:brand::string))               as brand,
        initcap(trim(raw_payload:color::string))               as color,
        raw_payload:size::string                               as size,
        raw_payload:dimensions::string                         as dimensions,
        raw_payload:weight::string                             as weight,

        raw_payload:unit_price::number(10,2)                   as unit_price,
        raw_payload:cost_price::number(10,2)                   as cost_price,

        -- Profit margin %, guarded against divide-by-zero
        case
            when raw_payload:unit_price::number(10,2) > 0
            then ((raw_payload:unit_price::number(10,2) - raw_payload:cost_price::number(10,2))
                  / raw_payload:unit_price::number(10,2)) * 100
            else null
        end as profit_margin_percentage,

        raw_payload:stock_quantity::number                    as stock_quantity,
        raw_payload:reorder_level::number                     as reorder_level,

        -- Low-stock flag
        case
            when raw_payload:stock_quantity::number < raw_payload:reorder_level::number
            then true else false
        end as is_low_stock,

        raw_payload:is_featured::boolean                       as is_featured,
        raw_payload:warranty_period::string                    as warranty_period,
        raw_payload:supplier_id::string                        as supplier_id,
        raw_payload:launch_date::date                          as launch_date,
        raw_payload:last_modified_date::date                   as product_last_modified_date,

        last_modified_date                                     as _file_last_modified,
        _source_file,
        _loaded_at

    from src_product

)

select * from transformed