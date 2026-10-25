
CREATE OR REPLACE VIEW vw_order_payment_summary AS
SELECT
    order_id,
    SUM(payment_value)        AS order_value,
    MAX(payment_installments) AS max_installments,
    COUNT(*)                  AS n_payments
FROM order_payments
GROUP BY order_id;


CREATE OR REPLACE VIEW vw_customer_rfm AS
SELECT
    c.customer_unique_id,
    DATEDIFF(
        (SELECT DATE_ADD(MAX(order_purchase_timestamp), INTERVAL 1 DAY) FROM orders),
        MAX(o.order_purchase_timestamp)
    )                              AS recency_days,
    COUNT(DISTINCT o.order_id)     AS frequency,
    ROUND(SUM(ps.order_value), 2)  AS monetary
FROM orders o
JOIN customers c                   ON c.customer_id = o.customer_id
JOIN vw_order_payment_summary ps   ON ps.order_id   = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id;


CREATE OR REPLACE VIEW vw_customer_rfm_scored AS
SELECT
    t.*,
    CASE
        WHEN r_score >= 4 AND m_score >= 4 THEN 'Recent high-value'
        WHEN r_score <= 2 AND m_score >= 4 THEN 'At-risk high-value'
        WHEN r_score >= 4 AND m_score <= 3 THEN 'Recent low-value'
        WHEN r_score <= 2 AND m_score <= 2 THEN 'Lapsed low-value'
        ELSE 'Middle'
    END AS segment
FROM (
    SELECT
        r.*,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,  -- 5 = most recent
        NTILE(5) OVER (ORDER BY monetary ASC)      AS m_score   -- 5 = biggest spender
    FROM vw_customer_rfm r
) t;


CREATE OR REPLACE VIEW vw_order_delivery_features AS
SELECT
    -- identifiers
    o.order_id,
    c.customer_unique_id,
    c.customer_state,
    o.order_purchase_timestamp,

    -- analysis-only (known only AFTER delivery -> leakage if used as features)
    DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)      AS actual_delivery_days,
    DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) AS delay_days,

    -- target
    (o.order_delivered_customer_date > o.order_estimated_delivery_date) + 0    AS is_late,

    -- features known at order time
    DATEDIFF(o.order_estimated_delivery_date, o.order_purchase_timestamp)      AS estimated_delivery_days,
    MONTH(o.order_purchase_timestamp)                                          AS purchase_month,
    DAYOFWEEK(o.order_purchase_timestamp)                                      AS purchase_dow,
    HOUR(o.order_purchase_timestamp)                                           AS purchase_hour,
    i.item_count,
    i.seller_count,
    i.total_price,
    i.total_freight,
    ROUND(i.total_freight / NULLIF(i.total_price, 0), 3)                       AS freight_ratio,
    i.total_weight_g,
    i.avg_distance_km,
    (i.seller_state = c.customer_state) + 0                                    AS same_state,
    ps.max_installments,
    ps.n_payments
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN (
    SELECT
        oi.order_id,
        COUNT(*)                        AS item_count,
        COUNT(DISTINCT oi.seller_id)    AS seller_count,
        SUM(oi.price)                   AS total_price,
        SUM(oi.freight_value)           AS total_freight,
        SUM(p.product_weight_g)         AS total_weight_g,
        MIN(s.seller_state)             AS seller_state,   -- arbitrary if multi-seller
        -- haversine distance (km) between seller zip and customer zip
        AVG(6371 * 2 * ASIN(SQRT(
              POWER(SIN(RADIANS(cg.geolocation_lat - sg.geolocation_lat) / 2), 2)
            + COS(RADIANS(sg.geolocation_lat)) * COS(RADIANS(cg.geolocation_lat))
              * POWER(SIN(RADIANS(cg.geolocation_lng - sg.geolocation_lng) / 2), 2)
        ))) AS avg_distance_km
    FROM order_items oi
    JOIN products p   ON p.product_id = oi.product_id
    JOIN sellers s    ON s.seller_id  = oi.seller_id
    JOIN orders o2    ON o2.order_id  = oi.order_id
    JOIN customers c2 ON c2.customer_id = o2.customer_id
    LEFT JOIN geolocation sg ON sg.geolocation_zip_code_prefix = s.seller_zip_code_prefix
    LEFT JOIN geolocation cg ON cg.geolocation_zip_code_prefix = c2.customer_zip_code_prefix
    GROUP BY oi.order_id
) i ON i.order_id = o.order_id
LEFT JOIN vw_order_payment_summary ps ON ps.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL;


CREATE OR REPLACE VIEW vw_segment_delivery_experience AS
SELECT
    r.customer_unique_id,
    r.recency_days, r.frequency, r.monetary,
    r.r_score, r.m_score, r.segment,
    COUNT(d.order_id)           AS delivered_orders,
    SUM(d.is_late)              AS late_orders,
    ROUND(AVG(d.is_late), 3)    AS late_rate
FROM vw_customer_rfm_scored r
JOIN vw_order_delivery_features d ON d.customer_unique_id = r.customer_unique_id
GROUP BY r.customer_unique_id, r.recency_days, r.frequency, r.monetary,
         r.r_score, r.m_score, r.segment;

SELECT
    segment,
    COUNT(*)                                         AS customers,
    ROUND(SUM(monetary), 0)                          AS total_revenue,
    SUM(late_orders)                                 AS late_orders,
    ROUND(SUM(late_orders) / SUM(delivered_orders) * 100, 2) AS late_order_pct
FROM vw_segment_delivery_experience
GROUP BY segment
ORDER BY late_order_pct DESC;

