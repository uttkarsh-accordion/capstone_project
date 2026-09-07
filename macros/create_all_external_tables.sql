{% macro create_all_external_tables() %}

    {{ create_external_table('BRONZE.EXT_CUSTOMERS', '.*customers.*[.]json') }}
    {{ create_external_table('BRONZE.EXT_PRODUCTS',  '.*products.*[.]json') }}
    {{ create_external_table('BRONZE.EXT_ORDERS',    '.*orders.*[.]json') }}
    {{ create_external_table('BRONZE.EXT_STORES',    '.*stores.*[.]json') }}
    {{ create_external_table('BRONZE.EXT_EMPLOYEES', '.*employees.*[.]json') }}

{% endmacro %}