USE rto_db;

-- Data warehousing: summary view over the transactional tables
CREATE OR REPLACE VIEW v_courier_performance AS
SELECT k.name AS courier,
       COUNT(*) AS shipments,
       SUM(s.status = 'RTO') AS rto_count,
       ROUND(AVG(s.status = 'RTO') * 100, 1) AS rto_pct
FROM shipments s
JOIN couriers k ON k.courier_id = s.courier_id
WHERE s.status IN ('DELIVERED', 'RTO')
GROUP BY k.name;

SELECT * FROM v_courier_performance ORDER BY rto_pct DESC;

-- Query processing: EXPLAIN shows the optimizer using our composite index
EXPLAIN SELECT shipment_id FROM shipments WHERE courier_id = 3 AND status = 'RTO';

-- Semi-structured data: querying inside the JSON column
SELECT attempt_id, shipment_id, remarks->>'$.logged_via' AS source
FROM delivery_attempts
WHERE remarks->>'$.logged_via' = 'web';