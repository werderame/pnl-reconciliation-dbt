select order_number
from {{ ref('int_pnl_order_scope') }}
group by order_number
having count(distinct opportunity_id)>1
