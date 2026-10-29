with golden as (
 select order_number,item_id,procurement_category,
        cast(outbound_transfer_quantity as decimal(18,4)) as outbound_transfer_quantity,
        cast(inbound_transfer_quantity as decimal(18,4)) as inbound_transfer_quantity,
        cast(net_transfer_quantity as decimal(18,4)) as net_transfer_quantity
 from {{ ref('seed_actual_components') }}
)
select coalesce(o.order_number,g.order_number) as order_number, coalesce(o.item_id,g.item_id) as item_id
from {{ ref('int_pnl_actual_components') }} o full outer join golden g
using (order_number,item_id,procurement_category)
where o.order_number is null or g.order_number is null
   or abs(o.outbound_transfer_quantity-g.outbound_transfer_quantity)>0.00001
   or abs(o.inbound_transfer_quantity-g.inbound_transfer_quantity)>0.00001
   or abs(o.net_transfer_quantity-g.net_transfer_quantity)>0.00001
