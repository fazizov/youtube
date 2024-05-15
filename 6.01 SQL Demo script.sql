--COPY INTO DEMO
CREATE TABLE JanuarySales
(Date DATE,	Country VARCHAR(20),	Units INT,	Revenue FLOAT);

COPY INTO JanuarySales
(Date,	Country,	Units,	Revenue)
FROM '/Sales2019.csv'
WITH (FILE_TYPE =  'CSV'
   ,CREDENTIAL= (IDENTITY = 'Shared Access Signature', SECRET = '') 
   ,ENCODING = 'UTF8'
   ,FIRSTROW =5
--    ,MAXERRORS = 3
--    ,ROWTERMINATOR='0X0A'
--    ,ERRORFILE = '/dwh-errors'
--    ,ERRORFILE_CREDENTIAL = (IDENTITY = 'Shared Access Signature', SECRET = '')
   )

SELECT * FROM JanuarySales;

--CTAS DEMO
CREATE TABLE SalesProcessed AS
SELECT Country,	Units,	Revenue,Date,YEAR(Date) AS SalesYear FROM JanuarySales;

--INSERT INTO DEMO
INSERT INTO SalesProcessed SELECT Country,	Units,	Revenue,Date,YEAR(Date) AS SalesYear FROM JanuarySales;

--Shortcuts demo

select * from [Bronze].[dbo].[stocks]