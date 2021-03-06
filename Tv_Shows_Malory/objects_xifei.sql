use TV_SHOWS
Go

Create --drop
proc insertPERSON_CREDIT_EPISODE
@EpisodeName1 VARCHAR(100), 
@EpisodeOverview1 VARCHAR(500), 
@EpisodeRuntime1 TIME, 
@BroadcastDate1 DATE,

@PersonFname1 VARCHAR(30), 
@PersonLname1 VARCHAR(30), 
@PersonDOB1 DATE, 

@CreditName1 VARCHAR(50),
@Character1 Varchar(50)
as
if @EpisodeName1     is null or
   @EpisodeOverview1 is null or
   @EpisodeRuntime1  is null or
   @BroadcastDate1 	 is null or
   @PersonFname1 	 is null or
   @PersonLname1	 is null or
   @PersonDOB1 		 is null or
   @CreditName1 	 is null or
   @Character1 		 is null 
   begin
   raiserror('parameter cannot be null', 11, 1)
   return
   end

Declare @EpisodeID int
Declare @PersonID int
Declare @CreditID int 
Exec GetEpisodeID  @EpisodeName     =@EpisodeName1     
				  ,@EpisodeOverview	=@EpisodeOverview1	
				  ,@EpisodeRuntime 	=@EpisodeRuntime1 	
				  ,@BroadcastDate 	=@BroadcastDate1
				  ,@EpisodeID = @EpisodeID out
if @EpisodeID is null
begin
raiserror('id is null', 11,1 )
return
end 

Exec GetPersonID @PersonFname        = @PersonFname1
				 ,@PersonLname		 = @PersonLname1
				 ,@PersonDOB 		 = @PersonDOB1 
				 ,@PersonID = @PersonID out
if @PersonID is null
begin
raiserror('id is null', 11,1 )
return
end 

Exec [dbo].[getCreditID] @CreditName  = @CreditName1
						 ,@CreditID = @CreditID out
if @CreditID is null
begin
raiserror('id is null', 11,1 )
return
end 

Begin tran G1
insert into tblPERSON_CREDIT_EPISODE(
EpisodeID
,CreditID 
,PersonID 
,[Character]
)
values(@EpisodeID, @CreditID, @PersonID, @Character1)

if @@error <> 0
rollback tran G1
else
commit tran G1
Go



Create --drop
proc insert_Episode_genre
@GenreName1 VARCHAR(100),

@EpisodeName1 VARCHAR(100), 
@EpisodeOverview1 VARCHAR(500), 
@EpisodeRuntime1 TIME, 
@BroadcastDate1 DATE
as

if @GenreName1       is null or
   @EpisodeName1 	is null or
   @EpisodeOverview1 is null or
   @EpisodeRuntime1 	is null or
   @BroadcastDate1 	is null 
begin
raiserror('parameter is null', 11,1)
return
end


Declare @EpisodeID int
Declare @GenreID int
Exec GetEpisodeID  @EpisodeName     =@EpisodeName1 
				  ,@EpisodeOverview	=@EpisodeOverview1	
				  ,@EpisodeRuntime 	=@EpisodeRuntime1 	
				  ,@BroadcastDate 	=@BroadcastDate1 
				  ,@EpisodeID = @EpisodeID out
if @EpisodeID is null
begin
raiserror('id is null', 11,1 )
return
end 

Exec  GetGenreID @GenreName= @GenreName1
				 ,@GenreID = @GenreID out
if @GenreID is null
begin
raiserror('id is null', 11,1 )
return
end

Begin tran G1
insert into tblEPISODE_GENRE(
 EpisodeID
 ,GenreID 
)
values(@EpisodeID, @GenreID)
if @@Error <> 0
rollback tran G1
Else
commit tran G1
Go

--If you were between the age 18 and 25 then you are not permitted to download a movie between 0 to 4am (Xifei )
Alter function No_15_25_downlaod_movie_past_12()
returns int
AS
BEGIN
DECLARE @Ret INT = 0
if exists (select * from tblCUSTOMER as c join tblMEMBERSHIP as m on c.CustomerID = m.CustomerID
join tblDOWNLOAD_EPISODE as de on de.MembershipID = m.MembershipID
Where (datediff(year, GETDATE(), c.CustDOB) between 18 and 25) and (cast(de.DownloadDateTime as time) between '0:00' and '4:00'))
BEGIN
SET @Ret = 1
END
RETURN @Ret
END
GO

Alter table tblDOWNLOAD_EPISODE
add
constraint No_15_25_downlaod_movie_past_mid
check (dbo.No_15_25_downlaod_movie_past_12() = 0)
Go
-- If you are from washington state and have a membership record less than a year, you cannot answer survey question
Create function No_WA_Survey_Membership_less_than_1()
returns int 
as
begin 
declare @Ret int = 0
if exists (
select * from tblCUSTOMER as c
join tblMEMBERSHIP as m
on m.CustomerID = c.CustomerID
where c.State = 'WA' and (datediff(year, m.EndDate, m.BeginDate) < 1) )
BEGIN
SET @Ret = 1
END
RETURN @Ret
END
GO

Alter table tblCUSTOMER_SURVEY_RESPONSE
Add constraint No_WA_Survey_Membership_less_than_1_year
check (dbo.No_WA_Survey_Membership_less_than_1() = 0)
Go
--How many times have customer download from netflix
Create function Calculate_download_netflix(@CustomerID int)
returns integer
as
Begin 
declare @times int
Set @times = (select count(*) from tblCUSTOMER as c join tblMEMBERSHIP as m on m.CustomerID = c.CustomerID
Join tblDOWNLOAD_EPISODE as de on de.MembershipID = m.MembershipID
join tblPLATFORM_EPISODE as pe on pe.PlatformEpisodeID = de.PlatformEpisodeID
join tblPLATFORM  as p on pe.PlatformID = p.PlatformID
Where p.PlatformName = 'Netflix' and C.CustomerID = @CustomerID)  
return @times
end
Go

Alter Table tblCustomer
Add Count_Download_Netflix as (dbo.Calculate_download_netflix(CustomerID))
Go

--How many episode of shows total for each language
Create Function Calculate_Languege_Episode(@LanguageID int)
returns Int
as 
Begin
Declare @Num int
Set @Num = (Select Count(*) from tblLANGUAGE as l Join tblSERIES as s on s.LanguageID = l.LanguageID
join tblEPISODE as e on e.SeriesID = s.SeriesID
Where l.LanguageID = @LanguageID)
return @Num
end
Go

Alter Table tblLanguage
Add Language_Episodes_Count as (dbo.Calculate_Languege_Episode(LanguageID))
Go

--Find ranking of count episodes of each language(Xifei Done)
Create View Rank_Language_Episodes
as
Select Rank() over (Order by Count(*)) as [Rank], l.LanguageName from tblLANGUAGE as l Join tblSERIES as s on s.LanguageID = l.LanguageID
join tblEPISODE as e on e.SeriesID = s.SeriesID
Group by LanguageName

--Find dense ranking of show by their sum runtime 
Create --drop
View dense_ranking_runtime_show
as
Select DENSE_RANK() over (Order by Sum( 
( DATEPART(hh, e.EpisodeRuntime ) * 3600 ) +
       ( DATEPART(mi, e.EpisodeRuntime ) * 60 ) +
         DATEPART(ss, e.EpisodeRuntime )
)) as Ranking, t.SeriesName from tblSERIES as t
join tblEPISODE as e on t.SeriesID = e.SeriesID
group by t.SeriesID, t.SeriesName