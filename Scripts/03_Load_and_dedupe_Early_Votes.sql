--=============================================================================
-- Create the table to hold the cumulative early vote file
--=============================================================================
IF OBJECT_ID( 'Clark_County_Election_2024.dbo.EarlyVotes' ) IS NOT NULL
	DROP TABLE Clark_County_Election_2024.dbo.EarlyVotes
CREATE TABLE Clark_County_Election_2024.dbo.EarlyVotes
( 
	IDNUMBER INT
	, NAME VARCHAR(255)
	, PRECINCT CHAR(4)
	, PARTY VARCHAR(255)
	, PARTY_ABBR VARCHAR(255)
	, CONGRESS CHAR(1)
	, ASSEMBLY CHAR(2)
	, SENATE VARCHAR(2)
	, COMMISSION CHAR(1)
	, EDUCATION CHAR(1)
	, REGENT VARCHAR(2)
	, SCHOOL CHAR(1)
	, CITY VARCHAR(3)
	, WARD VARCHAR(3)
	, TOWNSHIP CHAR(3)
	, STATUS VARCHAR(3)
	, EV_SITE VARCHAR(255)
	, ELECTION_CODE VARCHAR(5)
	, ACTIVITY_DATE DATE 
)

--=============================================================================
-- Load the flat file into the table that was created
--=============================================================================
BULK INSERT Clark_County_Election_2024.dbo.EarlyVotes
FROM 
	'Z:\Clark_County_Elections_2024\Data\Early_Voting\EV_24G.csv' 
	WITH 
	( 
		FORMAT = 'CSV'
		, FIRSTROW = 2
		, FIELDQUOTE = '"'
		, FIELDTERMINATOR = ','		
		, ROWTERMINATOR = '\n'
		, TABLOCK
	)

--=============================================================================
-- Today's combined file wasn't updated to include yesterday's data, so loading
-- it separately (10/19/2024)
--=============================================================================
BULK INSERT Clark_County_Election_2024.dbo.EarlyVotes
FROM 
	'Z:\Clark_County_Elections_2024\Data\Early_Voting\EV_20241028.csv' 
	WITH 
	( 
		FORMAT = 'CSV'
		, FIRSTROW = 2
		, FIELDQUOTE = '"'
		, FIELDTERMINATOR = ','		
		, ROWTERMINATOR = '\n'
		, TABLOCK
	)

--=============================================================================
-- Looks like a few people early voted multiple times...
--=============================================================================
SELECT *
FROM Clark_County_Election_2024.dbo.EarlyVotes
WHERE IDNUMBER IN(
	SELECT IDNUMBER
	FROM Clark_County_Election_2024.dbo.EarlyVotes
	GROUP BY IDNUMBER
	HAVING COUNT(*) > 1
)
ORDER BY IDNUMBER

--=============================================================================
-- let's go ahead and remove those duplicate entries, I don't see any differences 
-- between the two entries, so doesn't matter which gets chosen
--=============================================================================
ALTER TABLE Clark_County_Election_2024.dbo.EarlyVotes
ADD xid INT IDENTITY( 1, 1 )

IF OBJECT_ID( 'tempdb..#tmp' ) IS NOT NULL
	DROP TABLE #tmp
SELECT *
	, RN = ROW_NUMBER() OVER( PARTITION BY IDNUMBER ORDER BY Activity_Date DESC, STATUS )
INTO #tmp
FROM Clark_County_Election_2024.dbo.EarlyVotes

DELETE a
FROM Clark_County_Election_2024.dbo.EarlyVotes a
INNER JOIN #tmp b
	ON a.IDNUMBER = b.IDNUMBER
	AND a.xid = b.xid
WHERE b.RN > 1

--=============================================================================
-- Put a unique clustered index on the registration number field in the table
-- as we will be using this field for joining to other tables
--=============================================================================
CREATE UNIQUE CLUSTERED INDEX UC_IDX_REG ON Clark_County_Election_2024.dbo.EarlyVotes( IDNUMBER )