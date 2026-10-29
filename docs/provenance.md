# Code provenance

The selected evidence is five SQL files and five accompanying YAML files from Filippo's supplied archive. The private interview note was used to locate them, not to override their business rules.

## Preserved calculation

The files in reference/export are public-normalised copies. Model references are renamed; manufactured identifiers, dummy order and a vendor name pattern use synthetic equivalents. Comments are removed from SQL because some name colleagues or claim validation without execution artifacts. YAML owner email is replaced by an invalid example address, and example component identifiers use synthetic tokens.

Original and public hashes are recorded in reference/provenance.json. Normalised reference SQL remains recognisable as the five exported calculations. The runnable versions are under models/intermediate/pnl.

## Portability and metadata repairs

- The products model's concatenated tag string is normalised to two explicit tags.
- DuckDB IFF and date-format compatibility functions are supplied locally.
- Snowflake ILIKE ANY becomes the equivalent OR predicates.
- Aggregate GROUP BY ALL clauses that DuckDB cannot infer become explicit lists of the same grouping fields. Mounting grouping is not changed to an order-level window.
- The absent union macro is reconstructed as four schema-identical UNION ALL branches.
- New executable model YAML uses a valid version: 2. The exported BOM YAML contains a stray SQL fragment folded into the version value.

Each SQL-only portability diff is in reference/portability. scripts/verify_provenance.py checks the stored reference and calculation hashes.

## Portfolio extensions

Seven seed-backed staging interfaces; synthetic scenarios and hand-calculated answers; four conformed dimensions; two facts; explicit unit-cost coverage; two consumption marts; three audit views; local integrity tests; exposure metadata; documentation; visual explanations; and the new GitHub Actions workflow.

These additions demonstrate the public project's design. They are not historical claims about the employer's CI, source code, access controls or warehouse size.

No unrelated inventory or Weeks-of-Stock model was copied into this repository.
