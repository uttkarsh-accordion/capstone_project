{% macro clean_phone(raw_col) %}
    {%- set digits -%}
        regexp_replace({{ raw_col }}::string, '[^0-9]', '')
    {%- endset -%}
    case
        when {{ raw_col }}::string is null then null
        when regexp_like({{ raw_col }}::string, '[A-Za-z]') then null
        when length({{ digits }}) >= 11 and left({{ digits }}, 1) = '1'
            then left(substr({{ digits }}, 2), 10)
        when length({{ digits }}) >= 10
            then left({{ digits }}, 10)
        else null
    end
{% endmacro %}