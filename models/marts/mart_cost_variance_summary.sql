select year_month, product_category,
       count(*) as compared_components,
       sum(unpriced_rows) as unpriced_rows,
       sum(expected_cost_eur) as expected_cost_eur,
       sum(actual_cost_eur) as actual_cost_eur,
       sum(cost_variance_eur) as cost_variance_eur,
       sum(fully_priced_expected_cost_eur) as known_expected_cost_subtotal_eur,
       sum(fully_priced_actual_cost_eur) as known_actual_cost_subtotal_eur,
       case when sum(unpriced_rows) = 0 then sum(fully_priced_expected_cost_eur) end as fully_priced_expected_cost_eur,
       case when sum(unpriced_rows) = 0 then sum(fully_priced_actual_cost_eur) end as fully_priced_actual_cost_eur,
       case when sum(unpriced_rows) = 0 then sum(fully_priced_cost_variance_eur) end as fully_priced_cost_variance_eur,
       sum(case when component_quantity_status != 'equal' then 1 else 0 end) as components_with_quantity_variance
from {{ ref('mart_component_reconciliation') }}
group by year_month, product_category
