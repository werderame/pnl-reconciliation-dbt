select
    cast(order_number as varchar) as order_number,
    cast(opportunity_id as varchar) as opportunity_id,
    cast(is_customer_in_revenue as boolean) as is_customer_in_revenue,
    cast(opportunity_stage as varchar) as opportunity_stage
from {{ source('demo_inputs', 'customer_orders') }}
