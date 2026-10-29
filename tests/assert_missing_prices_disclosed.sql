-- The agreed report uses zero for missing WAC. The additional pricing-complete
-- measures must not imply that those same rows have a known price.
select * from {{ ref('mart_component_reconciliation') }}
where unpriced_rows > 0 and fully_priced_cost_variance_eur is not null
   or unpriced_rows = 0 and (
       fully_priced_expected_cost_eur is null
       or fully_priced_actual_cost_eur is null
       or fully_priced_cost_variance_eur is null
   )
   or expected_cost_eur is null or actual_cost_eur is null or cost_variance_eur is null
