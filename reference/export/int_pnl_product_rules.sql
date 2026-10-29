{{
  config(
    materialized = 'view',
    tags = 'daily''view'
  )
}}

WITH pnl_reconciliation_customers_in_scope AS (
  SELECT *
  FROM {{ ref('int_pnl_order_scope') }}
)

, stg_fulfilment_cases AS (
  SELECT *
  FROM {{ ref('stg_fulfilment_cases') }}
)

, customer_products_filtered AS (
  SELECT
    order_number
    , opportunity_id
    , product_sku
    , CASE
      WHEN opportunity_product_type ILIKE '%substructure%' OR opportunity_product_type ILIKE '%extra rafter%'
        THEN 'Mounting Structure'
      WHEN opportunity_product_type ILIKE '%battery%'
        THEN 'Battery'
      WHEN opportunity_product_type ILIKE '%ac box%'
        THEN 'AC Box'
      WHEN opportunity_product_type ILIKE '%inverter%'
        THEN 'Inverter'
      WHEN opportunity_product_type ILIKE '%wallbox%'
        THEN 'Wallbox'
      WHEN opportunity_product_type ILIKE '%back-up%'
        THEN 'Back-up'
      WHEN opportunity_product_type ILIKE '%module%'
        THEN 'PV Module'
    END AS product_category
    , quantity
    , monitoring_closed_date
  FROM pnl_reconciliation_customers_in_scope

  WHERE product_category IS NOT NULL
)

, customer_products_enriched AS (

  SELECT
    order_number
    , opportunity_id
    , product_sku
    , product_category
    , IFF(
      product_category = 'Mounting Structure'
      , CASE
        WHEN MAX(IFF(product_sku = 'SYN_H42', 1, 0)) = 1 THEN 'horizontal'
        WHEN MAX(IFF(product_sku = 'SYN_H180', 1, 0)) = 1 THEN '3ss'
        WHEN MAX(IFF(product_sku = 'SYN_H43', 1, 0)) = 1 THEN 'k2'
        ELSE 'regular'
      END
      , NULL
    ) AS category_secondary
    , quantity
    , monitoring_closed_date
  FROM customer_products_filtered
  GROUP BY ALL
)

, final AS (

  SELECT
    customers.*
    , CASE
      WHEN customers.product_category = 'Mounting Structure' THEN MAX(DATE(cases.installation_start_timestamp_cet))

      ELSE customers.monitoring_closed_date
    END AS validity_date

  FROM customer_products_enriched AS customers
    LEFT JOIN stg_fulfilment_cases AS cases
      ON customers.opportunity_id = cases.opportunity_id

  GROUP BY ALL

  HAVING validity_date IS NOT NULL

)

SELECT * FROM final
