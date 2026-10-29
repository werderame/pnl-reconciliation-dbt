# Publication and security boundaries

This project runs on synthetic local inputs. It contains no customer names, emails, addresses, real orders, credentials or production connection profiles.

The only configured adapter is local DuckDB. Database files, environment files, raw extracts and generated dbt run artifacts are excluded from Git. Reference contact metadata is replaced with an invalid example address.

Deterministic surrogate keys are modelling tools; they are not privacy protection for real customer identifiers.

For a real deployment, Finance and Operations would need agreed data access roles, secrets management, restricted warehouse schemas, sensitive-field minimisation, retention policy and audit logging. These are deployment requirements, not controls proven by the supplied export or implemented as production permissions in this demo.

Do not replace the synthetic seeds with company extracts in a public repository.
