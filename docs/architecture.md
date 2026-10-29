# Architecture and grain

## The original product boundary

Only the five P&L reconciliation SQL files and their five YAML files were selected from the supplied archive. Other inventory, stock-depletion and product-specific reporting models are outside this package.

| Exported model | Public calculation | Responsibility and grain |
| --- | --- | --- |
| int_scm_pnl_reconciliation_01_customers | int_pnl_order_scope | ERP order, opportunity, sold SKU and product-type scope; latest product timestamp per opportunity/type |
| int_scm_pnl_reconciliation_02_products | int_pnl_product_rules | Category and effective-date rules per retained order/product record |
| int_scm_pnl_reconciliation_03_boms | int_pnl_expected_components | Order, opportunity, sold product, category, effective date and physical component |
| int_scm_pnl_reconciliation_04_movements | int_pnl_actual_components | Order, physical component and normalised procurement category |
| rep_scm_pnl_reconciliation_05_expected_vs_actuals | int_pnl_cost_ledger | A union of differently detailed expected and actual records, valued in an order-derived month |

The sequence is a domain pipeline, not five independent reporting tables.

~~~mermaid
flowchart TD
  A["Order, opportunity, product and case interfaces"] --> B["Eligible order/product scope"]
  B --> C["Product category and effective date"]
  C --> D["Expected component quantities"]
  E["Versioned BOM interface"] --> D
  F["Warehouse movement interface"] --> G["Net actual components"]
  B --> G
  D --> G
  D --> H["Side-labelled cost ledger"]
  G --> H
  I["Monthly WAC interface"] --> H
~~~

## Dimensional serving layer

This layer is a portfolio addition. It makes the analytical contract explicit without replacing the five calculation stages.

- dim_reconciliation_order: one natural ERP order; an identity test rejects multiple opportunity IDs per order rather than accepting the displayed MIN ID as a resolution.
- dim_component: one physical item. The illustrative label is MIN of available BOM names; it is not a reconstructed enterprise item master.
- dim_valuation_period: one order-derived valuation month. It is not a full calendar dimension or a shipment date dimension.
- dim_sold_product: one sold SKU and its observed category/type; uniqueness rejects inconsistent definitions.
- fct_expected_component_cost: order × sold product × component × category × secondary category × valuation month.
- fct_actual_component_cost: order × component × category × valuation month.
- mart_component_reconciliation: independently aggregate the two facts to order × component × category × month, then full-outer compare.

The facts share order, component and period keys. Sold-product attribution is present only where the input establishes it. No arbitrary allocation bridge is invented for actual movements.

Product category remains a shared controlled attribute. Expected and actual category mappings must agree; adding a product-category dimension is possible when an independent authoritative taxonomy is supplied.

## Identity and temporal modelling

Surrogate keys hash a length-prefixed, null-aware encoding of natural-key fields. Null and empty string, or delimiter-containing IDs, remain distinguishable before hashing. They are warehouse identities, not anonymisation or encryption.

Effective-dated BOM lookups use inclusive boundaries and an open-ended 1900-01-01 sentinel. No Type 2 history of orders or products is invented: this is a current-scope reconstruction using available business timestamps.

## Materialisation

Views keep the small demo transparent and avoid storing multiple copies. This does not establish a historical company materialisation strategy or performance benchmark. Larger deployments could materialise heavy stages based on warehouse profiling and update requirements.
