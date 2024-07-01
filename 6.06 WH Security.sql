--1.1. Row-level security- direct mapping
--Creating mapping table
--DROP TABLE dbo.UserMapping; 
CREATE TABLE dbo.UserMapping 
AS 
SELECT  'AlexW@07gsz.onmicrosoft.com' as UserName,'United States' AS Country
UNION 
SELECT 'JoniS@07gsz.onmicrosoft.com' as UserName,'Canada' AS Country;
GO

Select * from dbo.UserMapping

--1.2. Granting read/write access
GRANT SELECT,INSERT,DELETE,UPDATE ON [dbo].[Geography] TO [AlexW@07gsz.onmicrosoft.com];
GRANT SELECT,INSERT,DELETE,UPDATE ON [dbo].[Geography] TO [JoniS@07gsz.onmicrosoft.com];
GRANT SELECT,INSERT,DELETE,UPDATE ON [dbo].[UserMapping] TO [AlexW@07gsz.onmicrosoft.com];
GRANT SELECT,INSERT,DELETE,UPDATE ON [dbo].[UserMapping] TO [JoniS@07gsz.onmicrosoft.com];
GO
--1.3.Creating security function
--DROP FUNCTION tvf_sec_userMapping;
GO
CREATE FUNCTION tvf_sec_userMapping(@UserName VARCHAR(100))
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN (
	SELECT 1 AS UserExist FROM dbo.UserMapping UM 
	WHERE @UserName=USER_NAME());
GO
--1.4.Creating security policy
--DROP SECURITY POLICY [RLSPolicy_UserMapping];  
CREATE SECURITY POLICY [RLSPolicy_UserMapping]   
	ADD FILTER PREDICATE dbo.tvf_sec_userMapping([UserName])   
	ON dbo.UserMapping
	WITH (STATE = ON);
GO
--1.5. Row-level security- indirect mapping
--DROP FUNCTION tvf_sec_Geography;
--GO
CREATE FUNCTION tvf_sec_Geography(@Country VARCHAR(100))
	RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN (
	SELECT 1 AS UserExist FROM [dbo].[Geography] G
	 JOIN dbo.UserMapping UM ON G.Country=UM.Country
	 WHERE UserName=USER_NAME() AND G.Country=@Country);
GO
--1.6
--DROP SECURITY POLICY [RLSPolicy_Geography];  
CREATE SECURITY POLICY [RLSPolicy_Geography]   
	ADD FILTER PREDICATE dbo.tvf_sec_Geography([Country])   
	ON [dbo].[Geography];
GO


--Querying all security policies
Select * from sys.security_policies


--2.1 Column-level security
DENY SELECT ON [dbo].[Geography] TO [AlexW@07gsz.onmicrosoft.com];
GO
GRANT SELECT ([City],[State],[Country]) ON [dbo].[Geography] TO [AlexW@07gsz.onmicrosoft.com]; 
GO
--3 Data masking
ALTER TABLE [dbo].[Geography]
 ALTER COLUMN City ADD MASKED WITH (FUNCTION = 'default()') 

ALTER TABLE [dbo].[Geography]
 ALTER COLUMN City ADD MASKED WITH (FUNCTION = 'partial(3,"****",2)') 

GRANT UNMASK ON [dbo].[Geography] TO [AlexW@07gsz.onmicrosoft.com];
GO
REVOKE UNMASK ON [dbo].[Geography] TO [AlexW@07gsz.onmicrosoft.com];

select * from [dbo].[Geography]