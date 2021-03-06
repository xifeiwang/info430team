USE TV_SHOWS 
GO 

--GetEpisodeID edited 
ALTER PROCEDURE GetEpisodeID 
@EpisodeName VARCHAR(100), 
@EpisodeID INT OUTPUT
AS
SET @EpisodeID = (SELECT EpisodeID FROM tblEPISODE WHERE EpisodeName = @EpisodeName)
GO 

--GetMembershipID edited 
ALTER PROCEDURE GetMembershipID 
@MembershipName VARCHAR(50), 
@BeginDate DATE,  
@MembershipID INT OUTPUT 
AS 
SET @MembershipID = (SELECT MembershipID FROM tblMEMBERSHIP WHERE MembershipName = @MembershipName AND BeginDate = @BeginDate)
GO 

--GetCustID 
CREATE PROC GetCustID 
@CustFname VARCHAR(30), 
@CustLname VARCHAR(30), 
@CustDOB DATE, 
@CustID INT OUTPUT
AS 
SET @CustID = (Select CustomerID FROM tblCUSTOMER 
WHERE CustFname = @CustFname AND CustLname = @CustLname 
AND CustDOB = @CustDOB)
GO 

-- GetGenreID edited
ALTER PROC GetGenreID
@GenreName VARCHAR(100),
@GenreID INT OUTPUT 
AS
SET @GenreID = (SELECT GenreID FROM tblGENRE
WHERE GenreName = @GenreName)
GO

-- GetLanguageID edited 
ALTER PROC GetLanguageID
@LanguageName VARCHAR(50),
@LanguageID INT OUTPUT
AS
SET @LanguageID = (SELECT LanguageID FROM tblLANGUAGE
WHERE LanguageName = @LanguageName)
GO

-- GetGenderID
CREATE PROC GetGenderID
@GenderName VARCHAR(10),
@GenderID INT OUTPUT
AS
SET @GenderID = (SELECT GenderID FROM tblGender
WHERE GenderName = @GenderName)
GO 

-- GetPersonID edited 
CREATE PROC GetPersonID
@PersonFname VARCHAR(30), 
@PersonLname VARCHAR(30), 
@PersonDOB DATE, 
@PersonID INT OUTPUT
AS
SET @PersonID = (SELECT PersonID FROM tblPERSON
WHERE @PersonFname = PersonFname
AND @PersonLname = PersonLname
AND @PersonDOB = PersonDOB)
GO
-- GetSeriesID EDITED 
CREATE PROC GetSeriesID
@SeriesName VARCHAR(100), 
@SeriesID INT OUTPUT
AS
SET @SeriesID = (SELECT SeriesID FROM tblSERIES
WHERE @SeriesName = SeriesName)
GO

-- Get PlatformID edited 
CREATE PROC GetPlatformID
@PlatformName VARCHAR(50),
@PlatformID INT OUTPUT
AS
SET @PlatformID = (SELECT PlatformID FROM tblPLATFORM
WHERE @PlatformName = PlatformName)
GO

-- stored procedure 1 NewCustomer 
CREATE PROCEDURE newCustomer 
@CustomerFname VARCHAR(30), 
@CustomerLname VARCHAR(30), 
@CustomerDOB DATE, 
@Address VARCHAR(50), 
@State VARCHAR(50),
@City VARCHAR(50),
@PostalCode CHAR(9), 
@Country VARCHAR(50)
AS
IF @CustomerFname IS NULL OR @CustomerLname IS NULL OR @CustomerDOB IS NULL 
    OR @Address IS NULL OR @State IS NULL OR @City IS NULL OR @PostalCode IS NULL OR @Country IS NULL
    BEGIN 
    PRINT 'paramaters can''t be NULL' 
    RAISERROR ('One or more Paramater is Null', 11, 1)
    RETURN 
    END
BEGIN TRAN G1 
    INSERT INTO tblCUSTOMER (CustFname, CustLname, CustDOB, [Address], [State], City, PostalCode, Country)
    VALUES (@CustomerFname, @CustomerLname, @CustomerDOB, @Address, @State, @City, @PostalCode, @Country)
    IF @@ERROR <> 0 
        ROLLBACK TRAN G1
    ELSE 
        COMMIT TRAN G1
GO 

-- business rule 1
--Can only watch Netflix if country 
--is not the US
CREATE FUNCTION fn_OnlyNetflixOutsideOfUS()
RETURNS INT 
AS
BEGIN 
DECLARE @Ret INT = 0

IF EXISTS (SELECT * FROM tblCUSTOMER C
            JOIN tblMEMBERSHIP M ON C.CustomerID = M.CustomerID 
            JOIN tblDOWNLOAD_EPISODE DE ON M.MembershipID = DE.MembershipID
            JOIN tblPLATFORM_EPISODE PE ON DE.PlatformEpisodeID = PE.PlatformEpisodeID
            JOIN tblPLATFORM P ON PE.PlatformID = P.PlatformID
            WHERE C.Country != 'United States' AND P.PlatformName = 'Netflix')
    BEGIN 
    SET @Ret = 1
    END 
RETURN @Ret
END
GO 

ALTER TABLE tblPLATFORM 
ADD CONSTRAINT CK_OnlyNetflixOutsideOfUS
CHECK (dbo.fn_OnlyNetflixOutsideOfUS() = 0) 

GO 
-- Stored procedure 2
-- Inserting new membership 
CREATE PROC newMembership 
@CFname VARCHAR(30), 
@CLname VARCHAR(30), 
@CDOB DATE, 
@MemName VARCHAR(50), 
@MemDescr VARCHAR(150), 
@Price NUMERIC(8,2),
@BeginDate DATE, 
@EndDate DATE
AS 

IF @CFname IS NULL OR @CLname IS NULL OR @CDOB IS NULL OR @MemName IS NULL OR 
@MemDescr IS NULL OR @Price IS NULL OR @BeginDate IS NULL OR @EndDate IS NULL 
    BEGIN 
    PRINT 'Parameters cannot be null'
    RAISERROR ('one or more of your parameters are null', 11, 1)
    RETURN 
    END

DECLARE @CID INT 

EXECUTE getCustID 
@CustFname = @CFname, 
@CustLname = @CLname, 
@CustDOB = @CDOB, 
@CustID = @CID OUTPUT 

IF @CID IS NULL 
    BEGIN  
    PRINT 'CID cannot be null'
    RAISERROR ('CID is null', 11, 1)
    RETURN 
    END

BEGIN TRAN G1
    INSERT INTO tblMEMBERSHIP (CustomerID, MembershipName, MembershipDescr, MembershipPrice, BeginDate, EndDate)
    VALUES (@CID, @MemName, @MemDescr, @Price, @BeginDate, @EndDate)
    IF @@ERROR <> 0
        ROLLBACK TRAN G1
    ELSE 
        COMMIT TRAN G1

GO 

-- View 1
-- Find all the customers from (United Kingdom) that watched (Friends) on netflix
CREATE VIEW [UnitedKingdomCustomers] AS 
SELECT C.CustomerID, CustFname, CustLname
FROM tblCUSTOMER C 
JOIN tblMEMBERSHIP M ON C.CustomerID = M.CustomerID
JOIN tblDOWNLOAD_EPISODE DE ON M.MembershipID = DE.MembershipID
JOIN tblPLATFORM_EPISODE PE ON DE.PlatformEpisodeID = PE.PlatformEpisodeID
JOIN tblPLATFORM P ON PE.PlatformID = P.PlatformID
JOIN tblEPISODE E ON PE.EpisodeID = E.EpisodeID
JOIN tblSERIES S ON E.SeriesID = S.SeriesID
WHERE C.Country = 'United Kingdom' AND S.SeriesName = 'Friends'
AND P.PlatformName = 'Netflix'
GO

--View 2
-- Find all episodes in (Comedy) in (English) with (Matthew Perry)
CREATE VIEW [ActorInComediesInEnglish] AS 
SELECT E.EpisodeID, EpisodeName 
FROM tblEPISODE E 
JOIN tblEPISODE_GENRE EG ON E.EpisodeID = EG.EpisodeID
JOIN tblGENRE G ON EG.GenreID = G.GenreID
JOIN tblSERIES S ON E.SeriesID = S.SeriesID
JOIN tblLANGUAGE L ON S.LanguageID = L.LanguageID
JOIN tblPERSON_CREDIT_EPISODE PCE ON E.EpisodeID = PCE.EpisodeID
JOIN tblPERSON P ON PCE.PersonID = P.PersonID
WHERE G.GenreName = 'Comedy' AND P.PersonFname = 'Matthew' AND P.PersonLname = 'Perry'
AND L.LanguageName = 'English'

GO 


-- Computed column 

CREATE FUNCTION fn_NumOfCustomersFromTexasWatchNetflix(@CustomerID INT)
RETURNS INT 
AS 
BEGIN 
    DECLARE @Ret INT = (
        SELECT SUM(C.CustomerID)
        FROM tblCUSTOMER C 
            JOIN tblMEMBERSHIP M ON C.CustomerID = M.CustomerID
            JOIN  tblDOWNLOAD_EPISODE DE ON  M.MembershipID = DE.MembershipID
            JOIN tblPLATFORM_EPISODE PE ON DE.PlatformEpisodeID = PE.PlatformEpisodeID
            JOIN tblPLATFORM P ON PE.PlatformID = P.PlatformID
        WHERE C.[State] = 'Texas' AND P.PlatformName = 'Netflix')
        RETURN @Ret
END 
GO 
ALTER TABLE tblCUSTOMER
ADD TotalTexans AS (dbo.fn_NumOfCustomersFromTexasWatchNetflix(CustomerID))
GO 

CREATE FUNCTION fn_numberOfCustomersWatchGossipGirl(@CustomerID INT) 
RETURNS INT 
AS
BEGIN 
    DECLARE @Ret INT = (
        SELECT SUM(C.CustomerID)
        FROM tblCUSTOMER C
            JOIN tblMEMBERSHIP M ON C.CustomerID = M.CustomerID
            JOIN  tblDOWNLOAD_EPISODE DE ON  M.MembershipID = DE.MembershipID
            JOIN tblPLATFORM_EPISODE PE ON DE.PlatformEpisodeID = PE.PlatformEpisodeID
            JOIN tblEPISODE E ON PE.EpisodeID = E.EpisodeID
            JOIN tblSERIES S ON E.SeriesID = S.SeriesID
        WHERE S.SeriesName = 'Gosip Girl')
    RETURN @Ret
END 
GO 

ALTER TABLE tblCUSTOMER 
ADD totalCustWatchGosipGirl AS (dbo.fn_numberOfCustomersWatchGossipGirl(CustomerID))
GO 

Create proc getCreditID
@CreditName VARCHAR(50),
@CreditDescr VARCHAR(150),
@CreditID int out 
as
Set @CreditID =(Select CreditID from tblCREDIT where @CreditName = @CreditName and @CreditDescr = @CreditDescr)
Go
