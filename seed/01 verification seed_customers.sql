SELECT COUNT(*) AS customer_count
FROM core.customers;

SELECT country_code, COUNT(*) AS cnt
FROM core.customers
GROUP BY country_code
ORDER BY cnt DESC;


SELECT kyc_status, COUNT(*) AS cnt
FROM core.customers
GROUP BY kyc_status
ORDER BY cnt DESC;



SELECT customer_status, COUNT(*) AS cnt
FROM core.customers
GROUP BY customer_status
ORDER BY cnt DESC;


SELECT risk_segment, COUNT(*) AS cnt
FROM core.customers
GROUP BY risk_segment
ORDER BY cnt DESC;