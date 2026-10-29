select
    cast(item_id as varchar) as item_id,
    cast(product_name as varchar) as product_name,
    cast(manufactured_item_number as varchar) as manufactured_item_number,
    cast(bill_of_material_quantity as decimal(18,4)) as bill_of_material_quantity,
    cast(from_quantity as decimal(18,4)) as from_quantity,
    cast(valid_from_date as date) as valid_from_date,
    cast(valid_to_date as date) as valid_to_date
from {{ source('demo_inputs', 'bom_lines') }}
