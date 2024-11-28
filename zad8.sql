
WITH DailyOrders AS (
    SELECT 
        OrderDate,
        COUNT(*) AS Orders_cnt
    FROM AdventureWorksDW2019.dbo.FactInternetSales
    GROUP BY OrderDate
    HAVING COUNT(*) < 100 
),

TopProductsPerDay AS (
    SELECT 
        fs.OrderDate,
        fs.ProductKey,
        fs.UnitPrice,
        ROW_NUMBER() OVER (PARTITION BY fs.OrderDate ORDER BY fs.UnitPrice DESC) AS RankPerDay
    FROM AdventureWorksDW2019.dbo.FactInternetSales fs
)

SELECT 
    d.OrderDate,
    d.Orders_cnt,
    tp.ProductKey,
    tp.UnitPrice,
	dp.EnglishProductName
FROM DailyOrders d
JOIN TopProductsPerDay tp
    ON d.OrderDate = tp.OrderDate
JOIN DimProduct dp ON dp.ProductKey = tp.ProductKey
WHERE tp.RankPerDay <= 3 
ORDER BY d.OrderDate, tp.RankPerDay;
