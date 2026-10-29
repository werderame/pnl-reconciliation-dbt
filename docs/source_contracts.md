# Seven reconstructed source contracts

No upstream implementation is included in the five-model export. Seed-backed sources are minimal synthetic interfaces for exercising the supplied calculation, not recreated company systems.

| Original reference | Public staging interface | Required fields and meaning |
| --- | --- | --- |
| dim_customer_orders | stg_customer_orders | ERP order; opportunity link; revenue flag and stage loaded but not filtered |
| dim_opportunity_products | stg_sales_product_lines | Opportunity; sold SKU; product type; quantity; created timestamp |
| dim_salesforce_opportunities | stg_opportunities | Opportunity; deletion flag; total module count used by the PV branch |
| dim_cases | stg_fulfilment_cases | Opportunity; monitoring close timestamp; installation start timestamp |
| dim_bill_of_material_lines | stg_bom_lines | Manufactured SKU; component item/name; quantity coefficient; from_quantity; inclusive validity dates |
| int_warehouse_movements | stg_warehouse_movements | ERP order; component; category; direction; order type; transfer/shipped quantities; movement and installation dates |
| rep_scm_wac_manual | stg_monthly_unit_costs | Physical item; YYYY-MM period; EUR WAC |

The movement fixture adds movement_id for audit traceability and interface_quantity to prove it is not used by the supplied Finance rule. Neither changes the core aggregation.

All raw fixture columns are seeded as text and explicitly cast by staging, so type inference cannot turn identifiers into numbers or treat empty dates as valid dates.

## Assumptions checked by the serving layer

- A natural ERP order has one opportunity identity.
- A sold SKU has one demonstrated category/type definition.
- One item/month has one WAC row.
- A manufactured item/component/threshold does not have overlapping BOM versions.
- Source quantities and identity fields needed by the facts are populated.

The tests establish these properties for the fixtures and reject violations when run on changed inputs. They do not establish them for missing production sources.

## Inclusion and completeness

Globally unseen movement components, dummy/deleted/undated orders, unrecognised sold product types, retro movements and no-BOM orders affect coverage. The audit layer lists several of these explicitly; it does not claim a complete raw-source exclusion ledger for every category and source-system rule.

Source freshness and ingestion SLAs cannot be inferred from this export. There are no fabricated freshness timestamps or external API connections.

Return rows are expected to arrive with direction-consistent quantity magnitudes. The five-model export subtracts inbound from outbound; it does not normalise negative return quantities. That upstream sign convention must be confirmed before using a different source.
