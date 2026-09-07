{% macro is_phone_invalid(raw_col) %}
    case
        when {{ raw_col }}::string is null then null
        when {{ clean_phone(raw_col) }} is null then true
        else false
    end
{% endmacro %}