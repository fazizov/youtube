--Multistatement scalar UDF (can be tested in AdventureWorks)
CREATE FUNCTION dbo.fn_customer_category(@price DECIMAL(18,2),@qty INT)
RETURNS CHAR(10) AS
BEGIN
  DECLARE @category CHAR(10),@total_cost DECIMAL(18,2);
  --1
  SET @total_cost=@price*@qty
  --2
  IF @total_cost < 5000
    SET @category = 'REGULAR';
  ELSE IF @total_cost < 10000
    SET @category = 'GOLD';
  ELSE
    SET @category = 'PLATINUM';
  RETURN @category;
END
GO
--Testing
select UnitPrice,OrderQty,dbo.fn_customer_category(UnitPrice,OrderQty) 
 FROM [SalesLT].[SalesOrderDetail];
--

-- Converted version, works in Synapse WH
CREATE FUNCTION dbo.tvf_customer_category
(@price DECIMAL(18,2),@qty INT)
RETURNS TABLE AS
RETURN (
WITH costCTE AS (SELECT @price*@qty AS TotalCost)
SELECT IIF(TotalCost<5000,'REGULAR',IIF(TotalCost<5000,'GOLD','PLATINUM')) As category 
FROM costCTE
)
GO
--Referring to TVF
select S.UnitPrice,S.OrderQty,C.category FROM [SalesLT].[SalesOrderDetail] S 
 CROSS APPLY dbo.tvf_customer_category(S.UnitPrice,S.OrderQty) C;

--Testing in Warehouse
CREATE TABLE Sales
AS 
SELECT 100 as UnitPrice, 50 as OrderQty
UNION 
SELECT 400 as UnitPrice, 50 as OrderQty;
GO

select S.UnitPrice,S.OrderQty,C.category FROM [Sales] S 
 CROSS APPLY dbo.tvf_customer_category(S.UnitPrice,S.OrderQty) C;




