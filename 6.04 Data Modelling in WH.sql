--Creating primary keys
ALTER TABLE [Geography]
 ADD CONSTRAINT PK_Geography 
 PRIMARY KEY NONCLUSTERED (GeographyID) 
 NOT ENFORCED

ALTER TABLE [Date] 
 ADD CONSTRAINT PK_Date 
 PRIMARY KEY NONCLUSTERED  (DateID) 
 NOT ENFORCED

--Creating unique keys
ALTER TABLE [Geography]
 ADD CONSTRAINT UK_Geography 
 UNIQUE NONCLUSTERED (GeographyID) 
 NOT ENFORCED

 ALTER TABLE [Geography]
 ADD CONSTRAINT UK_Geography_ZipCodeBKey 
 UNIQUE NONCLUSTERED (ZipCodeBKey) 
 NOT ENFORCED

 --Creating foreign keys
 ALTER TABLE  [Trip] 
  ADD CONSTRAINT FK_TripsDropOff FOREIGN KEY (DropoffGeographyID)
  REFERENCES  [Geography](GeographyID)
  NOT ENFORCED;

ALTER TABLE  [Trip] --DROP CONSTRAINT FK_Trips
  ADD CONSTRAINT FK_TripsPickup FOREIGN KEY (PickupGeographyID)
  REFERENCES  [Geography](GeographyID)
  NOT ENFORCED;

ALTER TABLE  [Trip]  
  ADD CONSTRAINT FK_Date 
  FOREIGN KEY (DateID) 
  REFERENCES  [Date](DateID)  
  NOT ENFORCED;

--Querying data integrity constraints in WH

select * from [INFORMATION_SCHEMA].[TABLE_CONSTRAINTS]
select * from [INFORMATION_SCHEMA].[REFERENTIAL_CONSTRAINTS]
select * from [INFORMATION_SCHEMA].[KEY_COLUMN_USAGE]
select * from [INFORMATION_SCHEMA].[CONSTRAINT_COLUMN_USAGE]

--Generating unique ID values
SELECT TOP 100 ROW_NUMBER() OVER (ORDER BY (SELECT NULL))  AS GeographyKey
	 ,[ZipCodeBKey],[City],[State] 
	 FROM [Geography]
	 
