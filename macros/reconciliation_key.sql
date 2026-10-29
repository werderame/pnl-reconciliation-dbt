{% macro reconciliation_key(columns) -%}
md5(concat(
  {%- for column in columns %}
  case when {{ column }} is null then 'N;'
       else concat('V', length(cast({{ column }} as varchar)), ':', cast({{ column }} as varchar), ';') end
  {%- if not loop.last %}, {% endif %}
  {%- endfor %}
))
{%- endmacro %}
