with observed as (
 select order_number, product_sku, item_id, product_category, sum(expected_quantity) as expected_quantity
 from {{ ref('int_pnl_expected_components') }} group by all
), golden as (
 select order_number, product_sku, item_id, product_category, cast(expected_quantity as decimal(18,4)) as expected_quantity
 from {{ ref('seed_expected_components') }}
)
select coalesce(o.order_number,g.order_number) as order_number,
       coalesce(o.product_sku,g.product_sku) as product_sku, coalesce(o.item_id,g.item_id) as item_id,
       o.expected_quantity as observed, g.expected_quantity as golden
from observed o full outer join golden g
using (order_number,product_sku,item_id,product_category)
where o.order_number is null or g.order_number is null or abs(o.expected_quantity-g.expected_quantity)>0.00001
