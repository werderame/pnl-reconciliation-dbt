select
    {{ reconciliation_key(['l.order_number', 'l.item_id', 'l.product_category', 'l.year_month', 'l.product_sku', 'l.category_secondary']) }} as component_cost_key,
    {{ reconciliation_key(['l.order_number']) }} as order_key,
    {{ reconciliation_key(['l.item_id']) }} as component_key,
    {{ reconciliation_key(['l.year_month']) }} as valuation_period_key,
    {{ reconciliation_key(['l.product_sku']) }} as sold_product_key,
    l.product_sku,
    l.order_number,
    l.item_id,
    l.product_category,
    l.year_month,
    l.expected_quantity,
    coalesce(q.cost_status, 'missing') as cost_status,
    q.unit_cost_eur,
    l.expected_cost as expected_cost_eur,
    case when q.cost_status = 'priced' then l.expected_quantity * q.unit_cost_eur end as priced_expected_cost_eur
from {{ ref('int_pnl_cost_ledger') }} as l
left join {{ ref('int_pnl_unit_cost_quality') }} as q
  on l.item_id = q.item_id and l.year_month = q.year_month
where l.side_type = 'expected'
