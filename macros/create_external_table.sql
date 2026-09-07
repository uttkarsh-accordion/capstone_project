{% macro create_external_table(table_name, file_pattern) %}

create or replace external table {{ table_name }} (
    FILE_NAME        VARCHAR(16777216) AS (METADATA$FILENAME),
    FILE_ROW_NUMBER   NUMBER(38,0)       AS (METADATA$FILE_ROW_NUMBER),
    LAST_MODIFIED      TIMESTAMP_NTZ(9)   AS (METADATA$FILE_LAST_MODIFIED)
)
location = @BRONZE.ADLS_CAPSTONE_STAGE/
auto_refresh = false
pattern = '{{ file_pattern }}'
file_format = BRONZE.JSON_FORMAT
;

{% endmacro %}