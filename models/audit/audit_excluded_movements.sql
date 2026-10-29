with marked as (
select m.*,
 case
  when erp_transfer_order_type is null then 'missing_transfer_order_type'
  when erp_transfer_order_type like '%Retro%' then 'retrofitting'
  when not exists (select 1 from {{ ref('int_pnl_order_scope') }} o where o.order_number=m.erp_order_number)
    then 'order_out_of_scope'
  when not exists (select 1 from {{ ref('int_pnl_expected_components') }} e where e.item_id=m.item_id)
    then 'component_out_of_global_scope'
  when not exists (select 1 from {{ ref('int_pnl_expected_components') }} e where e.order_number=m.erp_order_number)
    then 'order_without_expected_components'
 end as exclusion_reason
from {{ ref('stg_warehouse_movements') }} m
)
select * from marked where exclusion_reason is not null
