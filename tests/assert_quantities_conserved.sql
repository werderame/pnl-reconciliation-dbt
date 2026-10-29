select * from {{ ref('mart_component_reconciliation') }}
where abs(outbound_quantity-returned_quantity-net_actual_quantity)>0.00001
   or abs(expected_quantity-net_actual_quantity-quantity_variance)>0.00001
