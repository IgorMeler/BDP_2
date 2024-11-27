CREATE PROCEDURE GetHistoricalCurrencyRates
    @YearsAgo INT
AS
BEGIN
    DECLARE @CutoffDate DATE = DATEADD(YEAR, -@YearsAgo, GETDATE());

    WITH FilteredCurrencyRates AS (
        SELECT
            f.Date,
            f.AverageRate,
            f.EndOfDayRate,
            f.CurrencyKey,
            d.CurrencyAlternateKey
        FROM 
            AdventureWorksDW2019.dbo.FactCurrencyRate f
        INNER JOIN 
            AdventureWorksDW2019.dbo.DimCurrency d
            ON f.CurrencyKey = d.CurrencyKey
        WHERE 
            f.Date < @CutoffDate
            AND d.CurrencyAlternateKey IN ('GBP', 'EUR')
    )
    SELECT 
        Date,
        AverageRate,
        EndOfDayRate,
        CurrencyKey,
        CurrencyAlternateKey
    FROM 
        FilteredCurrencyRates
    ORDER BY 
        Date DESC;
END;
GO

EXEC GetHistoricalCurrencyRates @YearsAgo = 12;
