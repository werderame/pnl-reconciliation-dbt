{{
  config(
    materialized = 'view'
  )
}}

WITH int_pnl_product_rules AS (
  SELECT *
  FROM {{ ref('int_pnl_product_rules') }}
)

, stg_bom_lines AS (
  SELECT
    item_id
    , product_name
    , manufactured_item_number
    , bill_of_material_quantity
    , from_quantity
    , valid_from_date
    , valid_to_date
  FROM {{ ref('stg_bom_lines') }}
  WHERE manufactured_item_number LIKE 'SYN_%'
)

, stg_opportunities AS (
  SELECT
    opportunity_id
    , modules
  FROM {{ ref('stg_opportunities') }}
)

, product_bom_explosion_mechanisms AS (

  SELECT

    order_number
    , opportunity_id
    , product_sku
    , quantity
    , product_category
    , category_secondary
    , validity_date
    , CASE
      WHEN product_category IN ('AC Box', 'Inverter', 'Wallbox', 'Back-up') THEN 'component_passthrough'
      WHEN product_category = 'PV Module' THEN 'quantity_match'
      WHEN product_category = 'Mounting Structure' THEN 'even_quantity_match'
      WHEN product_category = 'Battery' THEN 'explosion'
      ELSE 'component_passthrough'
    END AS bom_explosion_mechanism
  FROM int_pnl_product_rules
)

, mechanism_passthrough AS (

  SELECT
    products.order_number
    , products.opportunity_id
    , products.product_sku
    , products.product_category
    , products.category_secondary
    , products.validity_date
    , bom.item_id
    , products.quantity AS expected_quantity
  FROM product_bom_explosion_mechanisms AS products
    INNER JOIN stg_bom_lines AS bom
      ON
        products.product_sku = bom.manufactured_item_number
        AND products.bom_explosion_mechanism = 'component_passthrough'
        AND products.validity_date >= bom.valid_from_date
        AND (products.validity_date <= bom.valid_to_date OR bom.valid_to_date = '1900-01-01')
        AND (

          (products.product_category = 'AC Box' AND bom.product_name LIKE 'AC Box%')
          OR (products.product_category = 'Inverter' AND bom.product_name ILIKE '%inverter%')
          OR (products.product_category = 'Wallbox' AND bom.product_name LIKE '%Charger%' AND bom.product_name NOT LIKE '%Mounting Plate%')
          OR (products.product_category = 'Back-up' AND bom.product_name ILIKE '%back%up%')
        )
  GROUP BY ALL
)

, mechanism_quantity_match AS (

  SELECT
    products.order_number
    , products.opportunity_id
    , products.product_sku
    , products.product_category
    , products.category_secondary
    , products.validity_date
    , bom.item_id
    , SUM(bom.bill_of_material_quantity) AS expected_quantity
  FROM product_bom_explosion_mechanisms AS products
    INNER JOIN stg_opportunities AS opps
      ON products.opportunity_id = opps.opportunity_id
    INNER JOIN stg_bom_lines AS bom
      ON
        products.bom_explosion_mechanism = 'quantity_match'
        AND products.product_sku = bom.manufactured_item_number
        AND opps.modules = bom.from_quantity
        AND products.validity_date >= bom.valid_from_date
        AND (products.validity_date <= bom.valid_to_date OR bom.valid_to_date = '1900-01-01')

        AND bom.product_name ILIKE '%pv%module%'
  GROUP BY ALL
)

, mechanism_even_quantity_match AS (

  SELECT
    products.order_number
    , products.opportunity_id
    , products.product_sku
    , products.product_category
    , products.category_secondary
    , products.validity_date
    , bom.item_id
    , bom.bill_of_material_quantity AS expected_quantity

  FROM product_bom_explosion_mechanisms AS products
    INNER JOIN stg_bom_lines AS bom
      ON
        products.product_category = 'Mounting Structure'

        AND products.product_sku = bom.manufactured_item_number
        AND products.validity_date >= bom.valid_from_date
        AND (products.validity_date <= bom.valid_to_date OR bom.valid_to_date = '1900-01-01')
        AND products.bom_explosion_mechanism = 'even_quantity_match'
        AND CASE
          WHEN (products.quantity % 2) = 0 THEN products.quantity
          ELSE products.quantity + 1
        END
        = CASE
          WHEN (bom.from_quantity % 2) = 0 THEN bom.from_quantity
          ELSE bom.from_quantity + 1
        END

        AND (

          bom.product_name ILIKE ANY ('end caps%', '%hook set%', '%connecting rail%', 'mechanical parts set%', '%mounting vendor%', 'rail set%', 'beaver%')
        )
        AND NOT (

          (products.category_secondary = 'regular' AND products.product_sku IN ('SYN_H42', 'SYN_H180', 'SYN_H43'))
          OR (products.category_secondary = 'horizontal' AND products.product_sku IN ('SYN_H180', 'SYN_H43'))
          OR (products.category_secondary = '3ss' AND products.product_sku IN ('SYN_H42', 'SYN_H43'))
          OR (products.category_secondary = 'k2' AND products.product_sku IN ('SYN_H42', 'SYN_H180'))
        )
  GROUP BY ALL
)

, mechanism_battery AS (

  SELECT
    products.order_number
    , products.opportunity_id
    , products.product_sku
    , products.product_category
    , products.category_secondary
    , products.validity_date
    , bom.item_id
    , products.quantity * bom.bill_of_material_quantity AS expected_quantity
  FROM product_bom_explosion_mechanisms AS products
    INNER JOIN stg_bom_lines AS bom
      ON
        products.product_sku = bom.manufactured_item_number
        AND products.bom_explosion_mechanism = 'explosion'
        AND products.validity_date >= bom.valid_from_date
        AND (products.validity_date <= bom.valid_to_date OR bom.valid_to_date = '1900-01-01')
  GROUP BY ALL
)

, final AS (
 {{ union_tables(
    [
    'mechanism_passthrough'
    , 'mechanism_quantity_match'
    , 'mechanism_even_quantity_match'
    , 'mechanism_battery'
    ])
    }}
)

SELECT * FROM final
