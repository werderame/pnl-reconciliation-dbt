select
    cast(opportunity_id as varchar) as opportunity_id,
    cast(modules as integer) as modules,
    cast(is_deleted as boolean) as is_deleted
from {{ source('demo_inputs', 'opportunities') }}
