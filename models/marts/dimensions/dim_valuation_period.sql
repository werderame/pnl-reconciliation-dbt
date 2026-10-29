select distinct
    {{ reconciliation_key(['year_month']) }} as valuation_period_key,
    year_month,
    try_cast(year_month || '-01' as date) as month_start_date
from {{ ref('int_pnl_cost_ledger') }}
