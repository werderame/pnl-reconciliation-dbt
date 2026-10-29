-- Start with the shared-grain comparison, then inspect the source-preserving ledger.
select order_number,item_id,product_category,expected_quantity,net_actual_quantity,
       expected_cost_eur,actual_cost_eur,cost_variance_eur,unpriced_rows,reconciliation_presence
from {{ ref('mart_component_reconciliation') }}
order by order_number,item_id;
