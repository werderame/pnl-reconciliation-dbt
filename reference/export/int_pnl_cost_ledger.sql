{{
  config(
    materialized = 'view'
  )
}}

WITH int_pnl_actual_components AS (
  SELECT * FROM {{ ref('int_pnl_actual_components') }}
)

, int_pnl_expected_components AS (
  SELECT * FROM {{ ref('int_pnl_expected_components') }}
)

, stg_monthly_unit_costs AS (
  SELECT * FROM {{ ref('stg_monthly_unit_costs') }}
)

, expected_and_actual AS (
  SELECT
    'expected' AS side_type
    , order_number
    , product_sku
    , product_category
    , category_secondary
    , item_id
    , expected_quantity
    , 0 AS outbound_transfer_quantity
    , 0 AS inbound_transfer_quantity
    , 0 AS net_transfer_quantity
  FROM int_pnl_expected_components

  UNION ALL

  SELECT
    'actual' AS side_type
    , order_number
    , NULL AS product_sku
    , procurement_category AS product_category
    , NULL AS category_secondary
    , item_id
    , 0 AS expected_quantity
    , outbound_transfer_quantity
    , inbound_transfer_quantity
    , net_transfer_quantity
  FROM int_pnl_actual_components
)

, dated_rows AS (

  SELECT
    all_rows.*
    , COALESCE(MAX(TO_CHAR(bom.validity_date, 'YYYY-MM')), '1900-01') AS year_month
    , COALESCE(MAX(TO_CHAR(bom.validity_date, 'YYYY-') || LPAD(TO_CHAR(EXTRACT(WEEK FROM bom.validity_date)), 2, '0')), '1900-01') AS week_number

  FROM expected_and_actual AS all_rows
    INNER JOIN int_pnl_expected_components AS bom
      ON all_rows.order_number = bom.order_number
  GROUP BY ALL
)

, status_mapped_customers AS (
  SELECT
    order_number
    , product_category
    , SUM(expected_quantity) AS expq
    , SUM(net_transfer_quantity) AS actq
    , CASE
      WHEN expq = actq THEN 'equal'
      WHEN expq > actq THEN 'undership'
      WHEN expq < actq THEN 'overship'
    END AS status_map
  FROM expected_and_actual
  WHERE product_category != 'Mounting Structure'
  GROUP BY ALL
)

, final AS (

  SELECT
    dated_rows.*
    , status.status_map
    , ROUND(COALESCE(MAX(wac.wac_eur), 0), 2) AS match_wac_eur
    , dated_rows.expected_quantity * match_wac_eur AS expected_cost
    , dated_rows.net_transfer_quantity * match_wac_eur AS actual_cost
    , expected_cost - actual_cost AS pnl

  FROM dated_rows
    LEFT JOIN stg_monthly_unit_costs AS wac
      ON
        dated_rows.item_id = wac.item_id
        AND dated_rows.year_month = wac.year_month

    LEFT JOIN status_mapped_customers AS status
      ON
        dated_rows.order_number = status.order_number
        AND dated_rows.product_category = status.product_category
  GROUP BY ALL

)

SELECT * FROM final
