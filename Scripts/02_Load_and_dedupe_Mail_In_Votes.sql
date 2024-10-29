--=============================================================================
-- Create the table to hold the cumulative mail in votes file
--=============================================================================
IF OBJECT_ID( 'Clark_County_Election_2024.dbo.MailInVotes' ) IS NOT NULL
	DROP TABLE Clark_County_Election_2024.dbo.MailInVotes
CREATE TABLE Clark_County_Election_2024.dbo.MailInVotes
( 
	IDNUMBER INT
	, VOTER_NAME VARCHAR(255)
	, STREET_NUMBER VARCHAR(255)
	, STREET_PREDIRECTION VARCHAR(255)
	, STREET_NAME VARCHAR(255)
	, STREET_TYPE VARCHAR(255)
	, UNIT VARCHAR(255)
	, CITY VARCHAR(255)
	, STATE CHAR(2)
	, ZIP VARCHAR(10)
	, PRECINCT CHAR(4)
	, VOTER_REG_PARTY VARCHAR(3)
	, BALLOT_PARTY VARCHAR(3)
	, ELECTION_CODE VARCHAR(5)
	, REQUEST_SOURCE VARCHAR(255)
	, REQUEST_DATE DATE
	, BALLOT_MAIL_DATE DATE
	, BALLOT_RECEIVE_DATE DATE
	, RETURN_CODE VARCHAR(3) 
)

--=============================================================================
-- Load the flat file into the table that was created
--=============================================================================
BULK INSERT Clark_County_Election_2024.dbo.MailInVotes
FROM 
	'Z:\Clark_County_Elections_2024\Data\Mail_In\mbreq24G_20241028_23405006.csv' --**** This appears to change each day
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
-- Looks like a few people received and returned multiple ballots...
--=============================================================================
SELECT *
FROM Clark_County_Election_2024.dbo.MailInVotes
WHERE IDNUMBER IN(
	SELECT IDNUMBER
	FROM Clark_County_Election_2024.dbo.MailInVotes
	GROUP BY IDNUMBER
	HAVING COUNT(*) > 1
)
ORDER BY IDNUMBER, BALLOT_MAIL_DATE

--=============================================================================
-- Let's go ahead and remove those duplicate entries, keep the latest based on
-- BALLOT_RECEIVE_DATE
--=============================================================================
ALTER TABLE Clark_County_Election_2024.dbo.MailInVotes
ADD xid INT IDENTITY( 1, 1 )

IF OBJECT_ID( 'tempdb..#tmp' ) IS NOT NULL
	DROP TABLE #tmp
SELECT *
	, RN = ROW_NUMBER() OVER( PARTITION BY IDNUMBER ORDER BY BALLOT_RECEIVE_DATE DESC )
INTO #tmp
FROM Clark_County_Election_2024.dbo.MailInVotes

DELETE a
FROM Clark_County_Election_2024.dbo.MailInVotes a
INNER JOIN #tmp b
	ON a.IDNUMBER = b.IDNUMBER
	AND a.xid = b.xid
WHERE b.RN > 1

--=============================================================================
-- Put a unique clustered index on the ID number field in the table
-- as we will be using this field for joining to other tables
--=============================================================================
CREATE UNIQUE CLUSTERED INDEX UC_IDX_REG ON Clark_County_Election_2024.dbo.MailInVotes( IDNUMBER )