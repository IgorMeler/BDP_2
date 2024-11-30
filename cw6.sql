IF OBJECT_ID('AdventureWorksDW2019.dbo.stg_dimemp', 'U') IS NOT NULL
    DROP TABLE AdventureWorksDW2019.dbo.stg_dimemp;

SELECT EMPLOYEEKEY, firstname, lastname, title 
INTO AdventureWorksDW2019.dbo.stg_dimemp 
FROM DimEmployee 
WHERE EmployeeKey BETWEEN 270 AND 275



/*CREATE TABLE dbo.scd_dimemp (
EmployeeKey int ,
FirstName nvarchar(50) not null,
LastName nvarchar(50) not null,
Title nvarchar(50),
StartDate datetime,
EndDate datetime);
INSERT INTO dbo.scd_dimemp (EmployeeKey, FirstName, LastName, Title, StartDate, EndDate)
SELECT EmployeeKey, FirstName, LastName, Title, StartDate, EndDate
FROM dbo.DimEmployee
WHERE EmployeeKey >= 270 AND EmployeeKey <= 275*/

SELECT * FROM AdventureWorksDW2019.dbo.stg_dimemp

update STG_DimEmp
set LastName = 'Nowak'
where EmployeeKey = 270;
update STG_DimEmp
set TITLE = 'Senior Design Engineer'
where EmployeeKey = 274;


update STG_DimEmp
set FIRSTNAME = 'Ryszard'
where EmployeeKey = 275

/*

AD. 6. 5b:
LastName (changing): SCD Type 1 (nadpisanie wartoœci, brak historii).
Title: SCD Type 2 (nowy rekord, zachowana historia).
5c:
FirstName (fixed): Zmiana zablokowana (fixed attribute, brak dzia³ania SCD).
(w przypadku gdy Firstname ustawione jako changing - FirstName: SCD Type 1).


AD. 7. Z uwagi na to, ¿e atrybut firstname ustawiony jest jako fixed nie mo¿na go zmieniæ, bo proces wtedy zwraca b³¹d. 
Aby b³¹d nie by³ zwracany dla tego zapytania nale¿a³oby ustawiæ to pole jako changing w zadaniu 4.