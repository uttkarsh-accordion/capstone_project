{% macro clean_phone(raw_col) %}
    {%- set digits_and_x -%}
        regexp_replace({{ raw_col }}::string, '[^0-9xX]', '')
    {%- endset -%}
    case
        when {{ raw_col }}::string is null then null
        -- reject if it contains any letter OTHER than x/X (genuine garbage, not masking)
        when regexp_like({{ raw_col }}::string, '[A-WYZa-wyz]') then null
        -- accept anything from 10 to 14 digits (covers local, country-code, and the longer format seen in this dataset)
        when length({{ digits_and_x }}) between 10 and 14
            then {{ digits_and_x }}
        else null
    end
{% endmacro %}