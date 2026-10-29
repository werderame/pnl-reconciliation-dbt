select distinct
    {{ reconciliation_key(['product_sku']) }} as sold_product_key,
    product_sku,
    product_category,
    category_secondary
from {{ ref('int_pnl_product_rules') }}
