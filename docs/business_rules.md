# Business rule contract

The SQL is the authority for implemented behaviour. YAML and comments explain intent but occasionally differ from the expressions. This contract makes those distinctions explicit.

## 1. Scope and latest records

An order is eligible when it is not the dummy order, its opportunity is not deleted, and a monitoring case from 2024 onward supplies a non-null monitoring-closed date.

ROW_NUMBER selects the latest monitoring timestamp per opportunity. DENSE_RANK retains all equally latest promised product rows per opportunity and product type; it does not arbitrarily pick one tied row. Quantities are summed at the retained line grain.

The customer-in-revenue flag and opportunity stage are selected from the source but not used as filters. The YAML describes the monitoring date as the discriminator. The synthetic O_FLAG_FALSE case preserves this distinction. Filippo does not recall the original scope decision and requested that the implemented rule be retained.

## 2. Category and effective date

Product type text maps to seven in-scope categories. Other types are outside the calculation.

For mounting structures, the effective date is the maximum installation-start date across cases linked to the opportunity. Other categories use the selected monitoring-closed date. A missing effective date removes the product before BOM matching.

The exported secondary mounting classification groups by SKU as well as order. Its MAX expressions therefore classify each product; they do not implement an order-wide winner. Audit views expose orders with multiple mounting types. Filippo recalls priority/exclusion rules specifically for external PV mounting structures, separate from the choice of BOM mechanism. The code is preserved; this recollection does not establish a new order-wide hierarchy.

## 3. Expected components

Each product category selects exactly one mechanism in the CASE expression. Effective dates then select the applicable BOM version; they do not select a second mechanism. Every branch requires a matching manufactured product and an effective BOM interval.

| Mechanism | Additional match | Expected quantity |
| --- | --- | --- |
| component_passthrough | Category-specific primary-component name patterns | Sold quantity directly |
| quantity_match | Opportunity module count equals BOM from_quantity | SUM of matching BOM component quantities |
| even_quantity_match | Both sold quantity and BOM threshold rounded upward to even; mounting-name and exclusion predicates | BOM component quantity directly |
| explosion | Battery branch, matching effective BOM | Sold quantity × BOM component quantity |

Rounding to even is a matching operation, not a universal quantity multiplier. Product-name filters express a source-dependent classification contract; they are not a complete component taxonomy.

The original union macro was absent. The replacement concatenates the four identically ordered branch schemas with UNION ALL; it performs no hidden deduplication or name alignment.

## 4. Actual component quantities

Orders must occur in stage 1. Components must occur anywhere in stage 3. Those are two independent global scopes, not an order/component expected-pair join.

Retro movements are excluded with a case-sensitive NOT LIKE predicate. NULL transfer-order types also disappear under SQL's null semantics.

Finance's documented hierarchy is COALESCE(transfer_quantity, shipped_quantity). Transfer zero remains zero. Interface quantity is not consulted.

Return Inbound contributes to inbound quantity; other non-null helper types contribute to outbound. A null helper type contributes to neither IFF branch in this expression. Net quantity is outbound minus inbound. Portfolio tests reject scoped movements with no direction or with both authoritative quantities missing before aggregation can conceal them.

## 5. Valuation and interpretation

The expected and actual rows are stacked before valuation. The month is MAX(BOM validity month) across the order, not a component-specific month and not the movement month.

WAC matches physical item and that month. The legacy expression takes the maximum matching WAC, rounds it to two decimals and defaults missing WAC to zero. Quantity × rounded unit cost gives the side's cost; expected minus actual gives the legacy pnl field.

Filippo confirmed that zero for missing WAC was an agreed report convention, not evidence of a free component. The public report measures retain it. The portfolio adds cost_status and pricing-complete measures: exactly one non-null monthly source row is priced. Missing or duplicate prices leave those additional measures unavailable. A duplicate-row test fails even when duplicated values happen to agree.

Legacy quantity status is aggregated by order/category, excluding mounting structures. It can mask component substitutions with equal total counts. The new mart adds a separately named component-level quantity status at its comparison grain.

No supplier cost variance, booked revenue, general-ledger matching, overhead, labour cost or gross margin is inferred from these files.
