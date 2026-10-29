with components as (
    select item_id, product_name as component_name from {{ ref('stg_bom_lines') }}
    union all
    select item_id, null as component_name from {{ ref('stg_warehouse_movements') }}
)
select
    {{ reconciliation_key(['item_id']) }} as component_key,
    item_id,
    min(component_name) as component_name
from components
group by item_id
