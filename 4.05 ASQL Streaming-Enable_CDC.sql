--1. Add user for replication
create user new_fabric_usr with password='XXX';
GO
sp_addrolemember 'db_owner','new_fabric_usr' 
--2
--Enable CDC on Db and table levels
EXEC sys.sp_cdc_enable_db;
GO

EXEC sys.sp_cdc_enable_table
    @source_schema = N'SalesLT',
    @source_name = N'Customer',
    @role_name = NULL;
GO


--3 Imitate transactions
update [SalesLT].[Customer] set ModifiedDate=getdate(), suffix='TestSuffix';

--4 Query CDC
-- ========  
-- Enumerate All Changes for Valid Range Template  
-- ========  

DECLARE @from_lsn binary(10), @to_lsn binary(10);  
SET @from_lsn = sys.fn_cdc_get_min_lsn('SalesLT_Customer');  
SET @to_lsn   = sys.fn_cdc_get_max_lsn();  
SELECT * FROM cdc.fn_cdc_get_all_changes_SalesLT_Customer 
  (@from_lsn, @to_lsn, N'all') ORDER BY CustomerID,ModifiedDate  ;  
GO


