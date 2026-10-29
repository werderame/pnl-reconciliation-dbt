{{
  config(
    materialized = 'view',
    tags = ['daily', 'view']
  )
}}

WITH stg_sales_product_lines AS (
  SELECT
    opportunity_id
    , product_sku
    , opportunity_product_type
    , quantity
    , created_timestamp_cet
  FROM {{ ref('stg_sales_product_lines') }}
)

, stg_customer_orders AS (
  SELECT

    order_number
    , opportunity_id
    , is_customer_in_revenue
    , opportunity_stage
  FROM {{ ref('stg_customer_orders') }}
  WHERE order_number != 'DEMO_DUMMY'
)

, stg_opportunities AS (

  SELECT
    opportunity_id
    , is_deleted
  FROM {{ ref('stg_opportunities') }}
  WHERE is_deleted = FALSE
)

, stg_fulfilment_cases AS (

  SELECT
    opportunity_id
    , setup_monitoring_closed_timestamp_cet
  FROM {{ ref('stg_fulfilment_cases') }}
  WHERE YEAR(setup_monitoring_closed_timestamp_cet) >= 2024
)

, cases AS (
  SELECT
    opportunity_id
    , DATE(setup_monitoring_closed_timestamp_cet) AS monitoring_closed_date
  FROM stg_fulfilment_cases

  QUALIFY ROW_NUMBER() OVER (PARTITION BY opportunity_id ORDER BY setup_monitoring_closed_timestamp_cet DESC) = 1
)

, customer_order_lines AS (
  SELECT
    orders.order_number
    , orders.opportunity_id
    , cases.monitoring_closed_date
    , products.product_sku
    , products.opportunity_product_type
    , products.quantity
    , products.created_timestamp_cet
  FROM stg_customer_orders AS orders
    INNER JOIN stg_opportunities AS opps
      ON orders.opportunity_id = opps.opportunity_id
    INNER JOIN stg_sales_product_lines AS products
      ON orders.opportunity_id = products.opportunity_id
    LEFT JOIN cases
      ON orders.opportunity_id = cases.opportunity_id
  WHERE

    cases.monitoring_closed_date IS NOT NULL

  QUALIFY DENSE_RANK() OVER (
    PARTITION BY orders.opportunity_id, products.opportunity_product_type
    ORDER BY products.created_timestamp_cet DESC
  ) = 1
)

, final AS (
  SELECT
    order_number
    , opportunity_id
    , monitoring_closed_date
    , product_sku
    , opportunity_product_type
    , SUM(quantity) AS quantity
    , created_timestamp_cet

  FROM customer_order_lines
  GROUP BY ALL
)

SELECT * FROM final
