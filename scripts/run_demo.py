"""Build the synthetic-only local demo; optionally prove the guards reject bad changes."""
from pathlib import Path
from importlib.metadata import version
import argparse
import json
import os
import shutil
import subprocess
import sys
import duckdb
from verify_provenance import verify as verify_provenance
from verify_demo import verify as verify_examples
from check_public_files import check as check_public_files

ROOT = Path(__file__).resolve().parents[1]

def run(args, *, expected_test_failure=False):
    executable = Path(sys.executable).parent / ('dbt.exe' if os.name=='nt' else 'dbt')
    command = [str(executable), *args, '--profiles-dir', str(ROOT), '--no-use-colors']
    p = subprocess.run(command,cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    log_dir=ROOT/'logs';log_dir.mkdir(exist_ok=True)
    (log_dir/('demo_'+args[0]+'.log')).write_text(p.stdout)
    if expected_test_failure:
        result = json.loads((ROOT/'target/run_results.json').read_text())
        failed=[x for x in result['results'] if x['status']=='fail' and x.get('failures',0)>0]
        if p.returncode==0 or not failed:
            raise RuntimeError('Expected a data-test failure, not a compilation/runtime failure:\n'+p.stdout)
        return {'test':args[-1], 'status':'rejected', 'failing_rows':sum(x['failures'] for x in failed)}
    if p.returncode:
        raise RuntimeError(p.stdout)
    print(p.stdout[-1000:])
    return None

def inject_failures(database):
    outcomes=[]
    model=ROOT/'models/intermediate/pnl/int_pnl_expected_components.sql'
    original=model.read_text()
    needle='products.quantity AS expected_quantity'
    assert original.count(needle)==1
    try:
        model.write_text(original.replace(needle,'products.quantity * bom.bill_of_material_quantity AS expected_quantity'))
        run(['run','--select','int_pnl_expected_components'])
        outcomes.append(run(['test','--select','assert_expected_components'],expected_test_failure=True))
    finally:
        model.write_text(original)
        run(['run','--select','int_pnl_expected_components'])
    try:
        with duckdb.connect(str(database)) as c:
            c.execute("insert into seed_monthly_unit_costs values ('C_AC','2025-05','121')")
        outcomes.append(run(['test','--select','assert_monthly_cost_grain'],expected_test_failure=True))
    finally:
        run(['seed','--select','seed_monthly_unit_costs'])
    verify_provenance()
    check_public_files()
    return outcomes

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check-failures',action='store_true',
                        help='Temporarily mutate this synthetic demo and verify two guards fail; always restore inputs/code.')
    args=parser.parse_args()
    database=Path(os.environ.get('PNL_DEMO_DB',ROOT/'pnl_demo.duckdb')).resolve()
    os.environ['PNL_DEMO_DB']=str(database)
    verify_provenance()
    check_public_files()
    # Source interfaces are seed-backed and must exist before model execution.
    run(['seed'])
    run(['build'])
    failures=inject_failures(database) if args.check_failures else []
    if failures:
        # Publish a final green result, not the intentionally failing run.
        run(['build'])
    checks=verify_examples(database)
    run(['docs','generate'])
    manifest=json.loads((ROOT/'target/manifest.json').read_text())
    results=json.loads((ROOT/'target/run_results.json').read_text())
    nodes=list(manifest['nodes'].values())
    report={
        'scope':'Synthetic local portfolio demo; not historical production execution',
        'versions':{k:version(k) for k in ['dbt-core','dbt-duckdb','duckdb']},
        'models':sum(n['resource_type']=='model' for n in nodes),
        'data_tests':sum(n['resource_type']=='test' for n in nodes),
        'sources':len(manifest['sources']),
        'exposures':len(manifest['exposures']),
        'synthetic_seeds':sum(n['resource_type']=='seed' for n in nodes),
        'injected_failures':failures,
        **checks,
    }
    (ROOT/'docs/verification.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))

if __name__=='__main__':
    main()
