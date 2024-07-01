--1
SELECT TOP (1000) [UserName],[Country] FROM [dbo].[UserMapping]
--2
SELECT distinct [Country]   FROM [dbo].[Geography]
--3  
UPDATE [dbo].[Geography] SET ZipCode=18089 WHERE GeographyID=77167
--4
SELECT *  FROM [dbo].[Geography]