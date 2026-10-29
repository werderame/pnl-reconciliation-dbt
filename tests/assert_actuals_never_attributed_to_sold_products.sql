-- Actual fact total must equal the original actual-side ledger, without a product join multiplier.
with a as (select order_number,item_id,product_category,year_month,sum(net_transfer_quantity) as q
           from {{ ref('fct_actual_component_cost') }} group by all),
     l as (select order_number,item_id,product_category,year_month,sum(net_transfer_quantity) as q
           from {{ ref('int_pnl_cost_ledger') }} where side_type='actual' group by all)
select coalesce(a.order_number,l.order_number) as order_number
from a full outer join l using(order_number,item_id,product_category,year_month)
where a.order_number is null or l.order_number is null or abs(a.q-l.q)>0.00001
