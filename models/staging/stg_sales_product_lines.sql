select
    cast(opportunity_id as varchar) as opportunity_id,
    cast(product_sku as varchar) as product_sku,
    cast(opportunity_product_type as varchar) as opportunity_product_type,
    cast(quantity as decimal(18,4)) as quantity,
    cast(created_timestamp_cet as timestamp) as created_timestamp_cet
from {{ source('demo_inputs', 'sales_product_lines') }}
