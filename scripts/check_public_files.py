"""Small publication checks for this synthetic fixture package, not a PII certification."""
from pathlib import Path
import csv
import re

ROOT=Path(__file__).resolve().parents[1]
RULES={
 'order_number':r'(O_[A-Z_]+|DEMO_DUMMY)',
 'erp_order_number':r'(O_[A-Z_]+|DEMO_DUMMY)',
 'opportunity_id':r'OP_(O_[A-Z_]+|DEMO_DUMMY)',
 'product_sku':r'SYN_[A-Z0-9_]+',
 'manufactured_item_number':r'SYN_[A-Z0-9_]+',
 'item_id':r'C_[A-Z0-9_]+',
 'movement_id':r'M[0-9]+',
}

def check():
    count=0
    for path in (ROOT/'seeds').glob('*.csv'):
        with path.open(newline='') as f:
            for row in csv.DictReader(f):
                count+=1
                for k,v in row.items():
                    if k in RULES and not re.fullmatch(RULES[k],v):
                        raise AssertionError(f'Unexpected non-demo identifier in {path.name}: {k}')
                    if '@' in v:raise AssertionError(f'Email-like fixture value in {path.name}')
    for path in (ROOT/'reference/export').glob('*'):
        if '@enpal.de' in path.read_text().lower():
            raise AssertionError('Original contact metadata remains')
    return count

if __name__=='__main__':
    print(f'Checked {check()} synthetic fixture rows and public reference metadata.')
