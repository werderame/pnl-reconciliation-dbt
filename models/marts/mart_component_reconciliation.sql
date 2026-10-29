-- Aggregate each fact to the shared grain before comparing.
-- Actual movements are never allocated to a sold SKU without attribution evidence.
with expected as (
    select order_key, component_key, valuation_period_key,
           order_number, item_id, product_category, year_month,
           sum(expected_quantity) as expected_quantity,
           sum(expected_cost_eur) as report_expected_cost_eur,
           sum(priced_expected_cost_eur) as known_expected_cost_eur,
           count(*) filter (where cost_status != 'priced') as unpriced_expected_rows
    from {{ ref('fct_expected_component_cost') }}
    group by all
), actual as (
    select order_key, component_key, valuation_period_key,
           order_number, item_id, product_category, year_month,
           sum(outbound_transfer_quantity) as outbound_quantity,
           sum(inbound_transfer_quantity) as returned_quantity,
           sum(net_transfer_quantity) as net_actual_quantity,
           sum(actual_cost_eur) as report_actual_cost_eur,
           sum(priced_actual_cost_eur) as known_actual_cost_eur,
           count(*) filter (where cost_status != 'priced') as unpriced_actual_rows
    from {{ ref('fct_actual_component_cost') }}
    group by all
), compared as (
    select
      coalesce(e.order_key,a.order_key) as order_key,
      coalesce(e.component_key,a.component_key) as component_key,
      coalesce(e.valuation_period_key,a.valuation_period_key) as valuation_period_key,
      coalesce(e.order_number,a.order_number) as order_number,
      coalesce(e.item_id,a.item_id) as item_id,
      coalesce(e.product_category,a.product_category) as product_category,
      coalesce(e.year_month,a.year_month) as year_month,
      coalesce(e.expected_quantity,0) as expected_quantity,
      coalesce(a.outbound_quantity,0) as outbound_quantity,
      coalesce(a.returned_quantity,0) as returned_quantity,
      coalesce(a.net_actual_quantity,0) as net_actual_quantity,
      coalesce(e.expected_quantity,0) - coalesce(a.net_actual_quantity,0) as quantity_variance,
      coalesce(e.unpriced_expected_rows,0) + coalesce(a.unpriced_actual_rows,0) as unpriced_rows,
      coalesce(e.report_expected_cost_eur,0) as expected_cost_eur,
      coalesce(a.report_actual_cost_eur,0) as actual_cost_eur,
      expected_cost_eur - actual_cost_eur as cost_variance_eur,
      case when coalesce(e.unpriced_expected_rows,0) = 0
           then coalesce(e.known_expected_cost_eur,0) end as fully_priced_expected_cost_eur,
      case when coalesce(a.unpriced_actual_rows,0) = 0
           then coalesce(a.known_actual_cost_eur,0) end as fully_priced_actual_cost_eur,
      case when unpriced_rows = 0
           then fully_priced_expected_cost_eur - fully_priced_actual_cost_eur end as fully_priced_cost_variance_eur,
      case when e.order_key is null then 'actual_only'
           when a.order_key is null then 'expected_only' else 'both' end as reconciliation_presence,
      case when quantity_variance = 0 then 'equal'
           when quantity_variance > 0 then 'undership' else 'overship' end as component_quantity_status
    from expected e
    full outer join actual a
      on e.order_key = a.order_key and e.component_key = a.component_key
     and e.valuation_period_key = a.valuation_period_key and e.product_category = a.product_category
)
select {{ reconciliation_key(['order_number','item_id','product_category','year_month']) }} as reconciliation_key,
       *
from compared
