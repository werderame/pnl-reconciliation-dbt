# Observed behaviour and business context

These are scope and interpretation questions identified from the selected export. They are not assumptions silently repaired in the portfolio calculation.

| Topic | Observed SQL | Presentation or guard |
| --- | --- | --- |
| Revenue eligibility | Monitoring date is filtered; customer-in-revenue flag is not | Retain date-proxy scope as requested; original rationale is not recalled |
| Mounting priority | Classification groups by product SKU; comments also describe order-level priority and base/add-on combinations | Priority/exclusion logic for PV mounting is recalled; retain the actual expressions and expose multiple-type orders |
| Mounting BOM quantities | Use coefficient directly after even-threshold matching | Preserve, with hand-calculated examples |
| Battery timing | Uses monitoring date for BOM selection; no later movement-date override exists in these five models | No retroactive timing algorithm invented |
| Movement scope | Order and item eligibility are independent global sets | Keep globally known unexpected components; audit globally unseen ones |
| No expected BOM on an order | Actual records can reach stage 4, then disappear at stage 5's inner order/BOM join | Audit the lost order before presenting financial totals |
| Valuation month | Latest expected-BOM month over the entire order | Label as cohort valuation, not movement-period accounting |
| Price conflicts | MAX of matched WAC rows | New duplicate-grain test rejects ambiguous pricing |
| Missing WAC | Legacy unit cost is zero | Agreed report convention confirmed by Filippo; retain zero and add separate pricing-coverage fields |
| Status definitions | SQL: expected greater than actual means undership | Correct the reversed status wording in public documentation |
| Legacy week label | Calendar year concatenated with week-of-year | Keep as a legacy field; not advertised as a valid ISO year/week key |
| Coverage | Filtered input, not a full warehouse or ledger reconciliation | Exclusion views travel with the cost view |

## Recollection and remaining boundaries

Filippo requested preservation of the code's eligibility rule because he does not recall its original rationale. He confirmed that external PV mounting used priority/exclusion logic, separate from the general BOM mechanisms, but did not confirm a replacement order-wide algorithm. He also confirmed that zero for missing WAC was an agreed report convention. Report measures preserve it; additional pricing-coverage measures are explicitly portfolio additions.

The latest expected-BOM month over the entire order is observed in SQL. This is labelled cohort valuation; no claim is made that a movement-period or general-ledger accounting rule was independently confirmed. Return quantity sign conventions and the seven upstream implementations were not included in the export.

Before changing production business behaviour, an owner would need to confirm the detailed mounting hierarchy, the valuation period for cross-month returns, and the resolution policy for duplicate monthly prices. These are documented limits, not blockers to reproducing the supplied calculation.
