select
    cast(opportunity_id as varchar) as opportunity_id,
    cast(setup_monitoring_closed_timestamp_cet as timestamp) as setup_monitoring_closed_timestamp_cet,
    cast(installation_start_timestamp_cet as timestamp) as installation_start_timestamp_cet
from {{ source('demo_inputs', 'fulfilment_cases') }}
