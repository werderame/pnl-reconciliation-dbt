select
    {{ reconciliation_key(['order_number']) }} as order_key,
    order_number,
    min(opportunity_id) as opportunity_id,
    max(monitoring_closed_date) as monitoring_closed_date
from {{ ref('int_pnl_order_scope') }}
group by order_number
