--1
create schema Bronze;
GO
create schema Silver;
GO
create schema Gold;
GO
--Create tables
--DROP TABLE [Bronze].[SampleTripData];
CREATE TABLE [Bronze].[SampleTripData](
	[PassengerCount] [int] NULL,
	[TripDurationSeconds] [int] NULL,
	[TripDistanceMiles] [float] NULL,
	[PaymentType] [varchar](8000) NULL,
	[FareAmount] [int] NULL,
	[TaxAmount] [int] NULL,
	[ZipCodeBKey] varchar(200),
	[City] varchar(300) NULL,
	[State] varchar(300) NULL,
	[TripDate] varchar(300) NULL
) 
GO
--silver zone tables
--DROP TABLE [Silver].[Geography];
CREATE TABLE [Silver].[Geography](
	[GeographyID] BIGINT NOT NULL,
	[ZipCodeBKey] [varchar](200) NULL,
	[City] [varchar](100) NULL,
	[State] [varchar](100) NULL
)  
GO

ALTER TABLE [Silver].[Geography]
 ADD CONSTRAINT PK_Geography PRIMARY KEY NONCLUSTERED  (GeographyID) 
 NOT ENFORCED

--DROP TABLE [Silver].[Trips];
CREATE TABLE [Silver].[Trips](
	[PassengerCount] [int] NULL,
	[TripDurationSeconds] [int] NULL,
	[TripDistanceMiles] [float] NULL,
	[PaymentType] [varchar](8000) NULL,
	[FareAmount] [int] NULL,
	[TaxAmount] [int] NULL,
	[GeographyID] BIGINT,
	[TripDate] DATE NULL
) 
GO

ALTER TABLE  [Silver].[Trips]
 ADD CONSTRAINT FK_Trips FOREIGN KEY (GeographyID) 
 REFERENCES  [Silver].[Geography](GeographyID)  
 NOT ENFORCED

--DROP TABLE [Silver].[TableIDWatermarks];
CREATE TABLE [Silver].[TableIDWatermarks]
(TableName VARCHAR(100),
LastID INT)
GO

--Dimensional tables
--DROP TABLE [Gold].[DimGeography];
CREATE TABLE [Gold].[DimGeography](
	[GeographyKey] INT NOT NULL,
	[GeographyID] INT,
	[ZipCodeBKey] [varchar](200) NULL,
	[City] [varchar](300) NULL,
	[State] [varchar](300) NULL,
	[EffectiveFromDate] DATE,
	[EffectiveToDate] DATE,
	[IsActive] BIT
)  
GO
--Set up constraints
ALTER TABLE [Gold].[DimGeography] 
 ADD CONSTRAINT PK_DimGeography 
 PRIMARY KEY NONCLUSTERED  (GeographyKey) 
 NOT ENFORCED;

--DROP TABLE [Gold].[DimDate];
CREATE TABLE [Gold].[DimDate]
([DateKey] BIGINT NOT NULL,
 [DATE] DATE,
 [Year] INT,
 [MONTH] INT,
 [DAY] INT
 );

ALTER TABLE [Gold].[DimDate] 
 ADD CONSTRAINT PK_DATE PRIMARY KEY NONCLUSTERED  (DateKey) NOT ENFORCED;

--DROP TABLE [Gold].[FactTrips];
CREATE TABLE [Gold].[FactTrips](
	[PassengerCount] [int] NULL,
	[TripDurationSeconds] [int] NULL,
	[TripDistanceMiles] [float] NULL,
	[PaymentType] [varchar](8000) NULL,
	[FareAmount] [int] NULL,
	[TaxAmount] [int] NULL,
	[GeographyKey] INT,
	[TripDateKey] BIGINT NULL
); 
GO

ALTER TABLE   [Gold].[FactTrips]
 ADD CONSTRAINT FK_Trips FOREIGN KEY (GeographyKey) 
 REFERENCES  [Gold].[DimGeography](GeographyKey)  
 NOT ENFORCED;

ALTER TABLE   [Gold].[FactTrips]
 ADD CONSTRAINT FK_Date FOREIGN KEY (TripDateKey) 
 REFERENCES  [Gold].[DimDate](DateKey)  
 NOT ENFORCED

 --2
--DROP PROCEDURE [Bronze].sp_IngestIntoStaging;
GO
CREATE PROCEDURE [Bronze].sp_IngestIntoStaging
AS
	DELETE  [Bronze].[SampleTripData];
	COPY INTO [Bronze].[SampleTripData]
	(PassengerCount,TripDurationSeconds,TripDistanceMiles,PaymentType,FareAmount,
	TaxAmount,[ZipCodeBKey],City,[State],[TripDate])
	FROM 'https://XXX.blob.core.windows.net/sampledata/SampleTripData.csv'
	WITH (FILE_TYPE =  'CSV'
	 ,CREDENTIAL= (IDENTITY = 'Shared Access Signature', SECRET = 'sp=r&st=2024-05-22T00:31:59Z&se=2024-05-23T08:31:59Z&spr=https&sv=2022-11-02&sr=b&sig=4M%2FjqL%2Fl5vQP%2F08ad%2BcpwKw075sIKqnta9YZGPB8JOE%3D') 
   	 ,FIRSTROW =2
	 ,ERRORFILE = '/ingestion-errors'
	 ,ERRORFILE_CREDENTIAL = (IDENTITY = 'Shared Access Signature', SECRET = '')
	)
GO
--Test
EXEC [Bronze].sp_IngestIntoStaging;

select * from [Bronze].[SampleTripData] order by TripDate


--3 Creating TVF
--DROP FUNCTION [Silver].GetLastID;
GO
CREATE FUNCTION [Silver].GetLastID
(@TableName VARCHAR(100))
RETURNS TABLE
RETURN (
	SELECT MAX(LastID) AS LastID 
	 FROM [Silver].[TableIDWatermarks]  
	 WHERE TableName=@TableName )
GO
--Testing TVF
SELECT * FROM [Silver].GetLastID('Geography')

--4
--DROP PROCEDURE [Silver].sp_NormalizeSchema;
GO

CREATE PROCEDURE [Silver].SplitGeography
AS
--Step 1: Update matching rows -- notice usage of DISTINCT clause to deduplicate rows 
	;WITH DistinctGeography AS (
	  SELECT DISTINCT COALESCE(S.[ZipCodeBKey],'Missing key') AS [ZipCodeBKey]
	   ,CAST(S.[City] AS VARCHAR(100)) AS [City],S.[State] 
	   FROM [Bronze].[SampleTripData] S)
	UPDATE T SET City=S.City,T.State=S.State
	 FROM [Silver].[Geography] T 
	 JOIN  DistinctGeography S ON S.[ZipCodeBKey]= T.[ZipCodeBKey]

--Step 2: Append missing rows 	
	;WITH DistinctGeography AS (
	  SELECT DISTINCT S.[ZipCodeBKey],S.[City],S.[State] 
	   FROM [Bronze].[SampleTripData] S 
	   LEFT JOIN [Silver].[Geography] T ON S.[ZipCodeBKey]= T.[ZipCodeBKey] 
	   WHERE T.[ZipCodeBKey]  IS NULL
	)
	INSERT INTO [Silver].[Geography]
	 SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) +COALESCE(LID.LastID,0) AS GeographyID
	 ,[ZipCodeBKey],[City],[State] 
	 FROM DistinctGeography
	 CROSS APPLY [Silver].GetLastID('Geography') LID;		--Reading last ID dynamically
--Step 3: Saving latest watermark
	 DELETE FROM [Silver].[TableIDWatermarks]  WHERE TableName='Geography';
	 INSERT INTO [Silver].[TableIDWatermarks] 
	  SELECT 'Geography' AS TableName, MAX(GeographyID) As LastID FROM [Silver].[Geography];
	
	GO	

--Testing stored procedure 
EXEC [Silver].SplitGeography

Select * from [Silver].[Geography]

--DROP PROCEDURE [Silver].sp_NormalizeTrips;
GO
CREATE PROCEDURE [Silver].sp_NormalizeTrips
@TripDate DATE
AS
--Saving Fact data and creating FK link  to Geography table
	DELETE FROM [Silver].Trips WHERE [TripDate]=@TripDate
	INSERT INTO [Silver].[Trips] ([PassengerCount] ,[TripDurationSeconds] ,[TripDistanceMiles] ,[PaymentType]
		  ,[FareAmount] ,[TaxAmount],[TripDate] ,[GeographyID])
		SELECT [PassengerCount] ,[TripDurationSeconds],[TripDistanceMiles]
		  ,[PaymentType],[FareAmount],[TaxAmount]
		  ,CAST([TripDate] AS Date) AS [TripDate]	  --Data type conversion		
		  ,COALESCE(G.GeographyID,-1) AS GeographyID  -- Handling Null values
	  FROM [Bronze].[SampleTripData] T 
	  LEFT JOIN [Silver].[Geography] G ON T.ZipCodeBKey=G.ZipCodeBKey
	GO

exec [Silver].sp_NormalizeTrips '2013-01-01'

select * from [Silver].[Trips]

---------------------------------
--Dimensional modelling
--5
--DROP PROCEDURE [Gold].sp_UpdateDimGeography;
GO
CREATE PROCEDURE [Gold].sp_UpdateDimGeography
AS
--Type 2 dimension handling
--Step1: Appending rows for matches between source and target tables
--Note: New values are coming from source with new start/end dates
--Note: The transformation includes only rows that have changes in certain fields
	INSERT INTO [Gold].[DimGeography]
	SELECT
		   ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) +COALESCE(LID.LastID,0) AS [GeographyKey]	
		  ,S.[GeographyID]
		  ,S.[ZipCodeBKey]
		  ,S.[City]
		  ,S.[State]
		  ,CAST(GetDate() AS DATE) AS [EffectiveFromDate]	--Start date
		  ,'9999-12-31' AS [EffectiveToDate]				--End date
		  ,1 AS IsActive									--IsActive set to 2 (temporarily)
	  FROM [Silver].[Geography] S 
	  INNER JOIN [Gold].[DimGeography] T 
	    ON S.[GeographyID]=T.[GeographyID]  --Joining on natural key
	  CROSS APPLY [Silver].GetLastID('DimGeography') LID
	  WHERE T.IsActive=1 
	  AND HASHBYTES('SHA2_256',CONCAT(S.[ZipCodeBKey],S.[City] ,S.[State])) !=   
	  HASHBYTES('SHA2_256',CONCAT(T.[ZipCodeBKey],T.[City] ,T.[State]))

--Saving latest watermarks
	DELETE FROM [Silver].[TableIDWatermarks]  WHERE TableName='DimGeography'
	INSERT INTO [Silver].[TableIDWatermarks] 
	 SELECT 'DimGeography' AS TableName, MAX(GeographyKey) As LastID 
	 FROM [Gold].[DimGeography] 

--Step 2: Expiring matching rows 
	UPDATE T SET 
		 T.[EffectiveToDate]=CAST(GetDate() AS DATE)
		,T.IsActive=0
		  FROM [Gold].[DimGeography] T
		  INNER JOIN [Silver].[Geography] S
			ON T.[GeographyID]=S.[GeographyID]
			WHERE T.IsActive=1  
			AND HASHBYTES('SHA2_256',CONCAT(S.[ZipCodeBKey],S.[City] ,S.[State])) !=
			 HASHBYTES('SHA2_256',CONCAT(T.[ZipCodeBKey],T.[City] ,T.[State]))
--Step 3: Appending new rows
	INSERT INTO [Gold].[DimGeography]
	SELECT
		ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) +COALESCE(LID.LastID,0) AS [GeographyKey]	--Generating ID
		,S.[GeographyID]
		,S.[ZipCodeBKey]
		,S.[City]
		,S.[State]
		,CAST(GetDate() AS DATE) AS [EffectiveFromDate]
		,'9999-12-31' AS [EffectiveToDate]
		,1 AS IsActive
	  FROM [Silver].[Geography] S 
	  LEFT JOIN [Gold].[DimGeography] T ON S.[GeographyID]=T.[GeographyID] --Unmatched rows
	  CROSS APPLY [Silver].GetLastID('DimGeography') LID
	  WHERE T.GeographyKey IS NULL --Unmatched rows
--Saving latest watermarks
	DELETE FROM [Silver].[TableIDWatermarks]  WHERE TableName='DimGeography'
	INSERT INTO [Silver].[TableIDWatermarks] 
	 SELECT 'DimGeography' AS TableName, MAX(GeographyKey) As LastID FROM [Gold].[DimGeography] 
--Adding 'Unknown dimension' if it doesn't exist
	IF NOT EXISTS (SELECT * FROM [Gold].[DimGeography]  WHERE GeographyKey=-1)	 
		INSERT INTO [Gold].[DimGeography] 
		 VALUES (-1,-1,'Unknown','Unknown','Unknown','1900-01-01','9999-12-31',1) 
	 GO

--testing 
exec [Gold].sp_UpdateDimGeography;

select * from [Gold].[DimGeography] where GeographyID=9106;
select * from [Silver].[Geography] where GeographyID=9106
--Update source table
UPDATE [Silver].[Geography] SET City ='Jersey' WHERE  GeographyID=9106
GO
-- Date dimension

CREATE PROCEDURE [Gold].sp_UpdateDimDate
AS
	;WITH DatesCTE AS (
	SELECT DAY(TripDate)+MONTH(TripDate)*100+ YEAR(TripDate)*10000 AS DateKey,
	TripDate AS [Date],YEAR(TripDate) AS [Year],MONTH(TripDate) AS [Month],
	DAY(TripDate) As [Day] FROM [Silver].[Trips])
	INSERT INTO [Gold].[DimDate] 
	 SELECT S.[DateKey],S.[Date],S.[Year],S.[Month],S.[Day] 
	 FROM DatesCTE S LEFT JOIN [Gold].[DimDate] T 
	 ON S.DateKey=T.DateKey WHERE T.DateKey IS NULL

--Adding 'Unknown dimension' if it doesn't exist
	IF NOT EXISTS (SELECT * FROM [Gold].[DimDate]  WHERE DateKey=-1)	 
		INSERT INTO [Gold].[DimDate] 
		 VALUES (-1,'1900-01-01',1900,1,1) 
	 GO
--test
exec [Gold].sp_UpdateDimDate

SELECT * FROM [Gold].[DimDate] 


--DROP PROCEDURE [Gold].sp_UpdateFactTrips;
GO
CREATE PROCEDURE [Gold].sp_UpdateFactTrips
@TripDate DATE
AS 
	DELETE FROM T
	    FROM [Gold].FactTrips T
		INNER JOIN [Gold].[DimDate] D ON T.[TripDateKey]=D.[DateKey]
		WHERE D.[DATE]=@TripDate;

	INSERT INTO [Gold].FactTrips
	Select T.[PassengerCount]
      ,T.[TripDurationSeconds]
      ,T.[TripDistanceMiles]
      ,T.[PaymentType]
      ,T.[FareAmount]
      ,T.[TaxAmount]
	  ,COALESCE(G.[GeographyKey],-1) As [GeographyKey] 
	  ,COALESCE(D.[DateKey],-1) AS [DateKey]
	 FROM Silver.Trips T 
	 LEFT JOIN [Gold].[DimGeography] G ON T.[GeographyID]=G.[GeographyID] AND G.IsActive=1
	 LEFT JOIN [Gold].[DimDate] D ON T.[TripDate]=D.[DATE]
	WHERE T.[TripDate]=@TripDate
	GO

--Test
EXEC [Gold].sp_UpdateFactTrips '2013-01-01'


select * from [Gold].FactTrips

--delete from [Gold].[DimGeography]