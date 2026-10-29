-- Investigation aid, not a replacement for the exported classification rule.
select order_number, count(distinct category_secondary) as mounting_types,
       string_agg(distinct category_secondary, ', ' order by category_secondary) as observed_types
from {{ ref('int_pnl_product_rules') }}
where product_category='Mounting Structure'
group by order_number
having count(distinct category_secondary)>1
