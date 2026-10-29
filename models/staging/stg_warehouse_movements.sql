select
    cast(movement_id as varchar) as movement_id,
    cast(helper_type as varchar) as helper_type,
    cast(movement_date as date) as movement_date,
    cast(installation_on_date as date) as installation_on_date,
    cast(erp_from_warehouse as varchar) as erp_from_warehouse,
    cast(erp_transfer_order_type as varchar) as erp_transfer_order_type,
    cast(transfer_order_status as varchar) as transfer_order_status,
    cast(erp_order_number as varchar) as erp_order_number,
    cast(item_id as varchar) as item_id,
    cast(procurement_category as varchar) as procurement_category,
    cast(transfer_quantity as decimal(18,4)) as transfer_quantity,
    cast(shipped_quantity as decimal(18,4)) as shipped_quantity,
    cast(interface_quantity as decimal(18,4)) as interface_quantity
from {{ source('demo_inputs', 'warehouse_movements') }}
