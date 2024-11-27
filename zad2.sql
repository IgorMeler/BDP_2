/*sql serwer*/
EXEC sp_help 'AdventureWorksDW2019.dbo.FactInternetSales';

/*Oracle*/
DESCRIBE AdventureWorksDW2019.dbo.FactInternetSales;

/*Postgre*/
\d+ "AdventureWorksDW2019.dbo.FactInternetSales";

/*Mysql*/
SHOW CREATE TABLE AdventureWorksDW2019.dbo.FactInternetSales;

/*INNER JOIN zwraca tylko te wiersze, które maj¹ dopasowanie w obu tabelach,
LEFT OUTER JOIN zwraca wszystkie wiersze z lewej tabeli, a z prawej tylko te, 
które maj¹ dopasowanie, natomiast FULL OUTER JOIN zwraca wszystkie wiersze z obu tabel, 
dopasowuj¹c je tam, gdzie to mo¿liwe, a tam, gdzie nie ma dopasowania, wstawia wartoœci NULL.*/