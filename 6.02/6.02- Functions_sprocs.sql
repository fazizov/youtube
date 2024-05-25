--Functions
create function fn_geography(@GID int)
returns table
return (select City,State from dbo.Geography where GeographyID=@GID)

--Usage 
--select * from dbo.Geography
Select * from fn_geography(77167)

--Joining to another query
select W.*,G.* from Weather W CROSS APPLY fn_geography(W.GeographyID) G

GO
DROP PROCEDURE sp_UpdateTrips;
GO
Create PROCEDURE sp_UpdateTrips
@DateId int,
@Rate float,
@RetCode INT OUTPUT
AS
	UPDATE  Trip SET FareAmount=FareAmount*@rate WHERE DateID=@DateId
	SELECT * FROM Trip WHERE DateID=@DateId
	SET @RetCode=-1
	RETURN 5

--Usage
declare @rtCd int
exec sp_UpdateTrips 20130920,1.1,@rtCd OUTPUT
SELECT @rtCd
