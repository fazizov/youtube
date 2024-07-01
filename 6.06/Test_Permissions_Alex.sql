--1.1
SELECT TOP (1000) [UserName],[Country] FROM [dbo].[UserMapping]
--1.2
SELECT distinct [Country]   FROM [dbo].[Geography]
--1.3  
UPDATE [dbo].[Geography] SET ZipCode=18089 WHERE GeographyID=77167
--2.1
SELECT top 100 *  FROM [dbo].[Geography]
SELECT top 100 [City] FROM [dbo].[Geography]
--3.1
SELECT top 100 [City] FROM [dbo].[Geography]

