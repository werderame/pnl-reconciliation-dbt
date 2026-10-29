{{
  config(
    materialized = 'view'
  )
}}

WITH components_in_scope AS (

  SELECT DISTINCT item_id
  FROM {{ ref('int_pnl_expected_components') }}
)

, customers_in_scope AS (

  SELECT DISTINCT order_number
  FROM {{ ref('int_pnl_order_scope') }}
)

, stg_warehouse_movements_filtered AS (
  SELECT *
  FROM {{ ref('stg_warehouse_movements') }}
  WHERE erp_transfer_order_type NOT LIKE '%Retro%'
)

, movements_in_scope AS (
  SELECT
    movements.helper_type
    , movements.movement_date
    , movements.installation_on_date
    , movements.erp_from_warehouse AS inventory_warehouse
    , movements.erp_transfer_order_type
    , movements.transfer_order_status
    , movements.erp_order_number AS order_number
    , movements.item_id

    , CASE movements.procurement_category
      WHEN 'Charger' THEN 'Wallbox'
      WHEN 'Backup Switch' THEN 'Back-up'
      ELSE movements.procurement_category
    END AS procurement_category

    , COALESCE(movements.transfer_quantity, movements.shipped_quantity) AS actual_quantity

  FROM stg_warehouse_movements_filtered AS movements

    INNER JOIN customers_in_scope AS customers
      ON movements.erp_order_number = customers.order_number
    INNER JOIN components_in_scope AS components
      ON movements.item_id = components.item_id

)

, movements_pivoted AS (
  SELECT
    order_number
    , item_id
    , procurement_category
    , IFF(helper_type != 'Return Inbound', actual_quantity, 0) AS outbound_quantity
    , IFF(helper_type = 'Return Inbound', actual_quantity, 0) AS inbound_quantity
  FROM movements_in_scope

)

, final AS (
  SELECT
    order_number
    , item_id
    , procurement_category
    , SUM(outbound_quantity) AS outbound_transfer_quantity
    , SUM(inbound_quantity) AS inbound_transfer_quantity
    , outbound_transfer_quantity - inbound_transfer_quantity AS net_transfer_quantity
  FROM movements_pivoted
  GROUP BY ALL
)

SELECT * FROM final
