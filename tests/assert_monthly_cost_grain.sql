select item_id,year_month,count(*) as source_rows
from {{ ref('stg_monthly_unit_costs') }}
group by item_id,year_month having count(*)>1
