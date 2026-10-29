select p.*
from {{ ref('int_pnl_product_rules') }} p
where not exists (
    select 1 from {{ ref('int_pnl_expected_components') }} e
    where p.order_number=e.order_number and p.opportunity_id=e.opportunity_id
      and p.product_sku=e.product_sku and p.product_category=e.product_category
)
