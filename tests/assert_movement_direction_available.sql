-- The exported IFF expressions would count a null direction as neither side.
select m.*
from {{ ref('stg_warehouse_movements') }} m
where m.erp_transfer_order_type not like '%Retro%'
  and exists (select 1 from {{ ref('int_pnl_order_scope') }} o where o.order_number=m.erp_order_number)
  and exists (select 1 from {{ ref('int_pnl_expected_components') }} e where e.item_id=m.item_id)
  and m.helper_type is null
