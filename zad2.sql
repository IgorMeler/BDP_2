/*sql serwer*/
EXEC sp_help 'AdventureWorksDW2019.dbo.FactInternetSales';

/*Oracle*/
DESCRIBE AdventureWorksDW2019.dbo.FactInternetSales;

/*Postgre*/
\d+ "AdventureWorksDW2019.dbo.FactInternetSales";

/*Mysql*/
SHOW CREATE TABLE AdventureWorksDW2019.dbo.FactInternetSales;

/*INNER JOIN zwraca tylko te wiersze, kt�re maj� dopasowanie w obu tabelach,
LEFT OUTER JOIN zwraca wszystkie wiersze z lewej tabeli, a z prawej tylko te, 
kt�re maj� dopasowanie, natomiast FULL OUTER JOIN zwraca wszystkie wiersze z obu tabel, 
dopasowuj�c je tam, gdzie to mo�liwe, a tam, gdzie nie ma dopasowania, wstawia warto�ci NULL.*/