# dbt + Snowflake Capstone: Sales and Customer Analytics

A medallion-architecture (Bronze/Silver/Gold) data pipeline built with dbt and Snowflake, covering sales and customer analytics.

## Architecture

- **Bronze** (`models/staging/bronze/`): Raw, incremental landing from Snowflake external tables over ADLS JSON files. No business logic applied.
- **Silver** (`models/intermediate/`): Cleaned, conformed, deduplicated data. SCD2 history for customers via dbt snapshots (`snapshots/`).
- **Gold** (`models/marts/`): Star schema — 5 dimensions, 1 fact table (`facts/`), plus reporting views (`reporting/`) for sales performance, customer insights, and employee performance.

## Key design decisions

- **Order header/item split**: `stg_order_header` (one row per order) and `stg_order_items` (one row per order line item) are kept separate to avoid duplicating order-level attributes across line items.
- **Profit metrics**: `line_profit_amount` (in `stg_order_items`) is revenue minus cost of goods only, at line grain. `net_profit` (in `stg_order_header`) additionally subtracts shipping and tax, at order grain. These are intentionally different metrics at different grains — see model descriptions for detail.
- **Customer SCD2**: `dim_customer` carries full history (`valid_from`/`valid_to`/`is_current`) sourced from `snp_customer` via `int_customer_cleaned`. Other dimensions carry current-state only, per spec.

## Known open items

- Duplicate `(order_id, product_id)` rows exist in the source for a small number of orders — pending decision on whether to merge or treat as distinct line items.
- No campaign source data — campaign-window flagging on `dim_date` and marketing ROI validation are out of scope.

## Running the project

```bash
dbt deps
dbt snapshot
dbt run
dbt test
```
