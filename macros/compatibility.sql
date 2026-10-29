{% macro bootstrap_demo_functions() %}
  create or replace macro iff(c, a, b) as case when c then a else b end;
  create or replace macro pnl_to_char(x, fmt := NULL) as
    case
      when fmt = 'YYYY-MM' then strftime(try_cast(x as date), '%Y-%m')
      when fmt = 'YYYY-' then strftime(try_cast(x as date), '%Y-')
      else cast(x as varchar)
    end
{% endmacro %}

{% macro union_tables(relations) %}
  {% for relation in relations %}
    select * from {{ relation }}
    {% if not loop.last %} union all {% endif %}
  {% endfor %}
{% endmacro %}
