-- Same product/component/threshold must not have overlapping intervals.
with numbered as (
 select *, row_number() over () as row_id
 from {{ ref('stg_bom_lines') }}
)
select a.manufactured_item_number,a.item_id
from numbered a join numbered b
 on a.row_id<b.row_id and a.manufactured_item_number=b.manufactured_item_number
and a.item_id=b.item_id and a.from_quantity=b.from_quantity
and a.valid_from_date <= case when b.valid_to_date=date '1900-01-01' then date '9999-12-31' else b.valid_to_date end
and b.valid_from_date <= case when a.valid_to_date=date '1900-01-01' then date '9999-12-31' else a.valid_to_date end
