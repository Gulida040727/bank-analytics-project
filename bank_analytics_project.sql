--=============================================
--ЗАДАНИЕ 1--
--=============================================
--1--
--Посчитать:
-- количество уникальных клиентов по годам
-- количество транзакций по годам
-- общую сумму транзакций по годам
-- среднюю сумму транзакций по годам
SELECT 
    SUBSTR(transaction_date, 1, 4) AS year,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount,
    AVG(amount) AS avg_amount
FROM transactions
GROUP BY year
ORDER BY year;

--2--
--Определить:
--Какие каналы используются чаще всего:
-- ATM
-- Mobile App
-- Online Banking
-- Branch Office
-- Cash Desk
SELECT 
	channel,
	COUNT(*) AS transaction_count
FROM transactions 
WHERE channel <> 'Partner Terminal'
GROUP BY channel 
ORDER BY transaction_count  DESC;

--3--
--Найти:
--Топ 20 клиентов:
-- по количеству транзакций
-- по сумме транзакций
SELECT 
    customer_id,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount
FROM transactions 
GROUP BY customer_id 
ORDER BY total_amount DESC
LIMIT 20;

--4--
-- Провести анализ валют:
--Посчитать:
-- количество операций по валютам
-- сумму операций по валютам
SELECT 
    currency,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount
FROM transactions
GROUP BY currency
ORDER BY total_amount DESC;

--5--
--Найти клиентов:
-- у которых более 50 успешных транзакций
-- общая сумма операций больше 500000
SELECT 
	customer_id,
	COUNT(*) AS transaction_count,
	SUM(amount) AS total_amount
FROM transactions 
WHERE status = 'SUCCESS'
GROUP BY customer_id 
HAVING COUNT(*) > 50
	AND SUM(amount) > 500000;

--=====================================================
--ЗАДАНИЕ 2--
--=====================================================

--1--
--Посчитать:
-- количество кредитов
-- сумму кредитов
-- среднюю процентную ставку

--по годам
SELECT 
	SUBSTR(issue_date, 1, 4) AS year,
	COUNT(*) AS loan_count,
	SUM(loan_amount) AS total_amount,
	AVG(interest_rate) AS avg_interest_rate
FROM loans
GROUP BY year
ORDER BY year;

--по продуктам кредита
SELECT 
	product_name,
	COUNT(*) AS loan_count,
	SUM(loan_amount) AS total_amount,
	AVG(interest_rate) AS avg_interest_rate
FROM loans 
GROUP BY product_name
ORDER BY total_amount DESC;

--филиалам
SELECT 
	l.branch_id,
	b.branch_name,
	COUNT(*) AS loan_count,
	SUM(loan_amount) AS total_amount,
	AVG(interest_rate) AS avg_interest_rate
FROM loans l
JOIN branches b 
	ON l.branch_id = b.branch_id 
GROUP BY l.branch_id, b.branch_name 
ORDER BY total_amount DESC;

--2--
--Найти:
--Количество:
-- ACTIVE кредитов
-- CLOSED кредитов
-- OVERDUE кредитов
SELECT 
	status,
	COUNT(*) AS loan_count
FROM loans 
GROUP BY status;

--3--
--Найти клиентов:
-- у которых больше 2 кредитов
-- сумма кредитов больше 300000
SELECT 
	customer_id,
	COUNT(*) AS loan_count,
	SUM(loan_amount) AS total_amount
FROM loans 
GROUP BY customer_id 
HAVING COUNT(*) > 2
	AND SUM(loan_amount) > 300000;

--4--
--Провести анализ просрочки:
--Найти:
-- филиалы с самым большим количеством OVERDUE кредитов
SELECT 
	l.branch_id,
	b.branch_name,
	COUNT(*) AS overdue_count
FROM loans l
JOIN branches b 
	ON l.branch_id = b.branch_id 
WHERE status = 'OVERDUE'
GROUP BY l.branch_id, b.branch_name 
ORDER BY overdue_count DESC;

-- сотрудников с самым большим количеством OVERDUE кредитов
SELECT 
	l.employee_id,
	e.full_name,
	COUNT(*) AS overdue_count
FROM loans l
JOIN employees e 
	ON l.employee_id = e.employee_id 
WHERE status = 'OVERDUE'
GROUP BY l.employee_id, e.full_name  
ORDER BY overdue_count DESC;

--5--
--Проанализировать платежи:
--Посчитать:
-- сумму погашений
-- сумму процентов
-- каналы погашения
SELECT 
	source_channel,
	COUNT(*) AS payment_count,
	SUM(principal_amount) AS principal_sum,
    SUM(interest_amount) AS interest_sum
FROM loan_payments 
WHERE status = 'SUCCESS'
GROUP BY source_channel 
ORDER BY payment_count DESC;

--=============================================
--ЗАДАНИЕ 3--
--=============================================

--Необходимо объединить:
-- customers
-- accounts
-- cards
-- transactions
-- loans
-- applications
--
--в единый аналитический dataset.
--
--Для каждого клиента вывести:
-- customer_id
-- full_name
-- city
-- количество счетов
-- количество карт
-- количество кредитов
-- общую сумму транзакций
-- количество транзакций
-- сумму кредитов
-- статус последней заявки
-- дату последней транзакции
--
--Дополнительно:
--
--Создать сегментацию клиентов:
--
--VIP:
-- сумма операций > 1000000
--
--Active:
-- больше 50 операций
--
--Risk:
-- есть OVERDUE кредит
--
--Regular:
-- остальные
SELECT 
	c.customer_id,
	c.full_name,
	c.city,
	COUNT(DISTINCT a.account_id) AS account_count,
	COUNT(DISTINCT c2.card_id) AS card_count,
	COUNT(DISTINCT l.loan_id) AS loan_count,
	SUM(t.amount) AS transaction_amount,
	COUNT(DISTINCT t.transaction_id) AS transaction_count,
	SUM(l.loan_amount) AS loan_amount,
	(
		SELECT ap.decision_status
    	FROM applications ap
    	WHERE ap.customer_id = c.customer_id
    	ORDER BY ap.decision_date DESC
    	LIMIT 1
	) AS last_application_status,
	MAX(t.transaction_date) AS last_transaction_date,
	CASE 
		WHEN SUM(t.amount) > 1000000 THEN 'VIP'
		WHEN COUNT(DISTINCT t.transaction_id) > 50 THEN 'Active'
        WHEN SUM(CASE WHEN l.status = 'OVERDUE' THEN 1 ELSE 0 END) > 0 THEN 'Risk'
        ELSE 'Regular'
	END AS customer_segment
FROM customers c 
LEFT JOIN accounts a 
	ON c.customer_id = a.customer_id 
LEFT JOIN cards c2
	ON c.customer_id  = c2.customer_id  
LEFT JOIN transactions t 
	ON c.customer_id = t.customer_id 
LEFT JOIN loans l 
	ON c.customer_id = l.customer_id 
GROUP BY 
	c.customer_id,
	c.full_name,
	c.city 