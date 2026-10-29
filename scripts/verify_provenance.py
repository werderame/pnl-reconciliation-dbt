"""Check the published calculation against its recorded, sanitised reference."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]

def verify():
    entries = json.loads((ROOT / "reference/provenance.json").read_text())
    for entry in entries:
        for path_key, hash_key in [("reference_file", "reference_sha256"), ("model_file", "model_sha256")]:
            if path_key not in entry:
                continue
            observed = hashlib.sha256((ROOT / entry[path_key]).read_bytes()).hexdigest()
            if observed != entry[hash_key]:
                raise AssertionError(f"Calculation/reference changed: {entry[path_key]}")
    return len(entries)

if __name__ == "__main__":
    print(f"Provenance verified for {verify()} exported SQL/YAML files.")
