select
    item_id,
    year_month,
    count(*) as source_row_count,
    count(wac_eur) as priced_row_count,
    count(distinct wac_eur) as distinct_price_count,
    case when count(wac_eur) = 0 then 'missing'
         when count(*) > 1 then 'ambiguous'
         else 'priced' end as cost_status,
    case when count(*) = 1 and count(wac_eur) = 1
         then round(max(wac_eur), 2) end as unit_cost_eur
from {{ ref('stg_monthly_unit_costs') }}
group by item_id, year_month
