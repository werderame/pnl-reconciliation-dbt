"""Business examples calculated independently of the transformation SQL."""
from decimal import Decimal
from pathlib import Path
import csv
import json
import os
import duckdb

ROOT = Path(__file__).resolve().parents[1]

def verify(database):
    c = duckdb.connect(str(database), read_only=True)
    def row(order, item):
        result = c.execute("""
            select expected_quantity,net_actual_quantity,expected_cost_eur,actual_cost_eur,
                   cost_variance_eur,unpriced_rows,reconciliation_presence
            from mart_component_reconciliation where order_number=? and item_id=?
        """, [order,item]).fetchall()
        assert len(result) == 1, (order,item,result)
        return result[0]
    assert row('O_EQUAL','C_AC')[:5] == (Decimal(2),Decimal(2),Decimal(240),Decimal(240),Decimal(0))
    assert row('O_RETURN','C_BAT_CELL')[:5] == (Decimal(6),Decimal(6),Decimal(300),Decimal(300),Decimal(0))
    assert row('O_SHORT','C_PV')[:5] == (Decimal(3),Decimal(2),Decimal(120),Decimal(80),Decimal(40))
    assert row('O_EXTRA','C_INV')[4] == Decimal(-200)
    assert row('O_MOUNT','C_HOOK')[2:5] == (Decimal(96),Decimal(84),Decimal(12))
    assert row('O_SHARED','C_SHARED')[2:5] == (Decimal(210),Decimal(210),Decimal(0))
    assert c.execute("select count(*) from fct_expected_component_cost where order_number='O_SHARED'").fetchone()[0] == 2
    assert c.execute("select count(*) from fct_actual_component_cost where order_number='O_SHARED'").fetchone()[0] == 1
    assert row('O_MISSING','C_CHARGER')[2:6] == (Decimal(0),Decimal(0),Decimal(0),2)
    assert c.execute("select fully_priced_cost_variance_eur from mart_component_reconciliation where order_number='O_MISSING'").fetchone()[0] is None
    assert row('O_ZERO','C_ZERO')[2:6] == (Decimal(0),Decimal(0),Decimal(0),0)
    assert row('O_UNEXPECTED','C_INV')[4:] == (Decimal(-200),0,'actual_only')
    assert row('O_EXPECTED_ONLY','C_AC')[4:] == (Decimal(120),0,'expected_only')
    assert row('O_ZERO_TRANSFER','C_BACKUP')[1:5] == (Decimal(0),Decimal(150),Decimal(0),Decimal(150))
    assert c.execute("select count(*) from int_pnl_order_scope where order_number='O_FLAG_FALSE'").fetchone()[0] == 1
    assert c.execute("select count(*) from audit_unmatched_sold_products where order_number='O_NO_BOM'").fetchone()[0] == 1
    assert c.execute("select count(*) from int_pnl_cost_ledger where order_number='O_NO_BOM'").fetchone()[0] == 0
    assert c.execute("select mounting_types from audit_multiple_mounting_types where order_number='O_MOUNT'").fetchone()[0] == 4
    # Agreed report convention stays zero; the optional pricing-complete view is unavailable.
    assert c.execute("select cost_variance_eur, fully_priced_cost_variance_eur from mart_cost_variance_summary where product_category='Wallbox'").fetchone() == (Decimal(0), None)
    columns = ['order_number','item_id','product_category','year_month','expected_quantity','net_actual_quantity',
               'expected_cost_eur','actual_cost_eur','cost_variance_eur','fully_priced_cost_variance_eur','unpriced_rows','reconciliation_presence']
    data = c.execute("select "+','.join(columns)+" from mart_component_reconciliation order by order_number,item_id").fetchall()
    output = ROOT / "docs/examples/component_reconciliation.csv"
    output.parent.mkdir(parents=True,exist_ok=True)
    with output.open('w',newline='') as f:
        writer=csv.writer(f);writer.writerow(columns);writer.writerows(data)
    counts = {name:c.execute("select count(*) from "+name).fetchone()[0] for name in [
        'int_pnl_order_scope','int_pnl_expected_components','int_pnl_actual_components','int_pnl_cost_ledger',
        'fct_expected_component_cost','fct_actual_component_cost','mart_component_reconciliation',
        'audit_unmatched_sold_products','audit_excluded_movements','audit_multiple_mounting_types']}
    c.close()
    return {'business_examples':'passed','row_counts':counts}

if __name__ == '__main__':
    path = Path(os.environ.get('PNL_DEMO_DB',ROOT/'pnl_demo.duckdb')).resolve()
    print(json.dumps(verify(path),indent=2))
