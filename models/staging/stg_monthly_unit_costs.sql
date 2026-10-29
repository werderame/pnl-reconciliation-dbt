select
    cast(item_id as varchar) as item_id,
    cast(year_month as varchar) as year_month,
    cast(wac_eur as decimal(18,4)) as wac_eur
from {{ source('demo_inputs', 'monthly_unit_costs') }}
