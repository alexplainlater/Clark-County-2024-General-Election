
--=============================================================================
-- Create the table that holds the 2024 voter role of all registered voters
--=============================================================================
IF OBJECT_ID( 'Clark_County_Election_2024.dbo.VoterListAll' ) IS NOT NULL
	DROP TABLE Clark_County_Election_2024.dbo.VoterListAll
CREATE TABLE Clark_County_Election_2024.dbo.VoterListAll
(
	STATUS CHAR(1)
	, PRECINCT CHAR(4)
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
	, FIRST_NAME VARCHAR(255)
	, MIDDLE_NAME VARCHAR(255)
	, LAST_NAME VARCHAR(255)
	, NAME_SUFFIX VARCHAR(255)
	, SEX CHAR(1)
	, PARTY_REG VARCHAR(3)
	, BIRTH_YEAR CHAR(4)
	, PHONE_NUM VARCHAR(15)
	, RES_STREET_NUM VARCHAR(255)
	, RES_DIRECTION VARCHAR(5)
	, RES_STREET_NAME VARCHAR(255)
	, RES_ADDRESS_TYPE VARCHAR(255)
	, RES_UNIT VARCHAR(255)
	, RES_CITY VARCHAR(255)
	, RES_STATE CHAR(2)
	, RES_ZIP_CODE VARCHAR(10)
	, MAIL_ADDRESS VARCHAR(255)
	, MAIL_CITY VARCHAR(255)
	, MAIL_STATE CHAR(2)
	, MAIL_ZIP_CODE VARCHAR(10)
	, ACTIVITY_DATE DATE
	, REGISTRATION_DATE DATE
	, REGISTRATION_NUM INT
	, LANGUAGE_PREF VARCHAR(255)
	, POLLING_CODE VARCHAR(20)
	, CONFIDENTIAL_FLAG CHAR(1)
	, ID_NOT_REQD CHAR(1)
	, AFFIDAVIT VARCHAR(255)
	, ELECTION1 VARCHAR(5)
	, VOTE_TYPE1 CHAR(1)
	, ELECTION2 VARCHAR(5)
	, VOTE_TYPE2 CHAR(1)
	, ELECTION3 VARCHAR(5)
	, VOTE_TYPE3 CHAR(1)
	, ELECTION4 VARCHAR(5)
	, VOTE_TYPE4 CHAR(1)
	, ELECTION5 VARCHAR(5)
	, VOTE_TYPE5 CHAR(1)
	, ELECTION6 VARCHAR(5)
	, VOTE_TYPE6 CHAR(1)
	, ELECTION7 VARCHAR(5)
	, VOTE_TYPE7 CHAR(1)
	, ELECTION8 VARCHAR(5)
	, VOTE_TYPE8 CHAR(1)
	, ELECTION9 VARCHAR(5)
	, VOTE_TYPE9 CHAR(1)
	, ELECTION10 VARCHAR(5)
	, VOTE_TYPE10 CHAR(1)
	, ELECTION11 VARCHAR(5)
	, VOTE_TYPE11 CHAR(1)
	, ELECTION12 VARCHAR(5)
	, VOTE_TYPE12 CHAR(1)
	, ELECTION13 VARCHAR(5)
	, VOTE_TYPE13 CHAR(1)
	, ELECTION14 VARCHAR(5)
	, VOTE_TYPE14 CHAR(1)
	, ELECTION15 VARCHAR(5)
	, VOTE_TYPE15 CHAR(1)
	, ELECTION16 VARCHAR(5)
	, VOTE_TYPE16 CHAR(1)
	, ELECTION17 VARCHAR(5)
	, VOTE_TYPE17 CHAR(1)
	, ELECTION18 VARCHAR(5)
	, VOTE_TYPE18 CHAR(1)
	, ELECTION19 VARCHAR(5)
	, VOTE_TYPE19 CHAR(1)
	, ELECTION20 VARCHAR(5)
	, VOTE_TYPE20 CHAR(1)
)

--=============================================================================
-- Load the flat file into the table that was created
--=============================================================================
BULK INSERT Clark_County_Election_2024.dbo.VoterListAll
FROM 
	'Z:\Clark_County_Elections_2024\Voter_List\COUNTY_all_TV\county_all_TV.txt' 
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
-- Put a unique clustered index on the registration number field in the table
-- as we will be using this field for joining to other tables
--=============================================================================
CREATE UNIQUE CLUSTERED INDEX UC_IDX_REG ON Clark_County_Election_2024.dbo.VoterListAll( REGISTRATION_NUM )

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
	'Z:\Clark_County_Elections_2024\Mail_In\mbreq24G_20241028_23405006.csv' 
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
-- Put a unique clustered index on the registration number field in the table
-- as we will be using this field for joining to other tables
--=============================================================================
CREATE CLUSTERED INDEX UC_IDX_REG ON Clark_County_Election_2024.dbo.MailInVotes( IDNUMBER )

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
-- let's go ahead and remove those duplicate entries, keep the latest
--=============================================================================
DELETE a
FROM Clark_County_Election_2024.dbo.MailInVotes a
INNER JOIN 
(
	SELECT *
		, RN = ROW_NUMBER() OVER( PARTITION BY IDNUMBER ORDER BY BALLOT_RECEIVE_DATE DESC )
	FROM Clark_County_Election_2024.dbo.MailInVotes
) b
	ON a.IDNUMBER = b.IDNUMBER
	AND a.BALLOT_RECEIVE_DATE = b.BALLOT_RECEIVE_DATE
	AND a.BALLOT_MAIL_DATE = b.BALLOT_MAIL_DATE
	AND b.RN > 1

--=============================================================================
-- Create the table to hold the cumulative mail in votes file
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
	'Z:\Clark_County_Elections_2024\Early_Voting\EV_24G.csv' 
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
-- Put a unique clustered index on the registration number field in the table
-- as we will be using this field for joining to other tables
--=============================================================================
CREATE CLUSTERED INDEX UC_IDX_REG ON Clark_County_Election_2024.dbo.EarlyVotes( IDNUMBER )

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

DELETE a
FROM Clark_County_Election_2024.dbo.EarlyVotes a
INNER JOIN 
(
	SELECT *
		, RN = ROW_NUMBER() OVER( PARTITION BY IDNUMBER ORDER BY Activity_Date DESC, STATUS )
	FROM Clark_County_Election_2024.dbo.EarlyVotes
) b
	ON a.IDNUMBER = b.IDNUMBER
	AND a.xid = b.xid
	AND b.RN > 1

--=============================================================================
-- I wonder if there are multiple entries for an ID between mail in and early voting
--=============================================================================
SELECT
	*
FROM Clark_County_Election_2024.dbo.VoterListAll a
LEFT JOIN Clark_County_Election_2024.dbo.EarlyVotes e
	ON a.REGISTRATION_NUM = e.IDNUMBER
LEFT JOIN Clark_County_Election_2024.dbo.MailInVotes m
	ON a.REGISTRATION_NUM = m.IDNUMBER
WHERE a.STATUS = 'A' -- Active
	AND e.ACTIVITY_DATE IS NOT NULL
	AND m.BALLOT_RECEIVE_DATE IS NOT NULL

--=============================================================================
-- of course there are...
--=============================================================================
SELECT
	a.REGISTRATION_NUM
	, e.ACTIVITY_DATE
	, m.BALLOT_RECEIVE_DATE
	, WhichToKeep = CASE WHEN m.BALLOT_RECEIVE_DATE > e.ACTIVITY_DATE THEN 'Mail' ELSE 'Early' END
INTO #tmp
FROM Clark_County_Election_2024.dbo.VoterListAll a
LEFT JOIN Clark_County_Election_2024.dbo.EarlyVotes e
	ON a.REGISTRATION_NUM = e.IDNUMBER
LEFT JOIN Clark_County_Election_2024.dbo.MailInVotes m
	ON a.REGISTRATION_NUM = m.IDNUMBER
WHERE a.STATUS = 'A' -- Active
	AND e.ACTIVITY_DATE IS NOT NULL
	AND m.BALLOT_RECEIVE_DATE IS NOT NULL

DELETE m
FROM Clark_County_Election_2024.dbo.MailInVotes m
INNER JOIN #tmp d
	ON m.IDNUMBER = d.REGISTRATION_NUM
WHERE d.WhichToKeep <> 'Mail'

DELETE e
FROM Clark_County_Election_2024.dbo.EarlyVotes e
INNER JOIN #tmp d
	ON e.IDNUMBER = d.REGISTRATION_NUM
WHERE d.WhichToKeep <> 'Early'

DROP TABLE #tmp

--=============================================================================
-- Create a summary table of the current voter turnout status
--=============================================================================
IF OBJECT_ID( 'Clark_County_Election_2024.dbo.VoteStatus' ) IS NOT NULL
	DROP TABLE Clark_County_Election_2024.dbo.VoteStatus
SELECT
	a.PRECINCT
	, PARTY =	CASE 
					WHEN a.PARTY_REG = 'DEM' THEN 'Democrat'
					WHEN a.PARTY_REG = 'REP' THEN 'Republican'
					ELSE 'Z. Other'
				END
	, Age_Group = CASE
			WHEN YEAR( GETDATE() ) - CONVERT( INT, a.BIRTH_YEAR ) BETWEEN 17 AND 24 THEN '1. 17-24'
			WHEN YEAR( GETDATE() ) - CONVERT( INT, a.BIRTH_YEAR ) BETWEEN 25 AND 34 THEN '2. 25-34'
			WHEN YEAR( GETDATE() ) - CONVERT( INT, a.BIRTH_YEAR ) BETWEEN 35 AND 44 THEN '3. 35-44'
			WHEN YEAR( GETDATE() ) - CONVERT( INT, a.BIRTH_YEAR ) BETWEEN 45 AND 54 THEN '4. 45-54'
			WHEN YEAR( GETDATE() ) - CONVERT( INT, a.BIRTH_YEAR ) BETWEEN 55 AND 64 THEN '5. 55-64'
			WHEN YEAR( GETDATE() ) - CONVERT( INT, a.BIRTH_YEAR ) BETWEEN 65 AND 74 THEN '6. 65-74'
			WHEN YEAR( GETDATE() ) - CONVERT( INT, a.BIRTH_YEAR ) BETWEEN 75 AND 84 THEN '7. 75-84'
			WHEN YEAR( GETDATE() ) - CONVERT( INT, a.BIRTH_YEAR ) >= 85 THEN '8. 85+'
		END
	, G2024_Voted_Date = COALESCE( m.BALLOT_RECEIVE_DATE, e.ACTIVITY_DATE )
	, QTY = COUNT(*)
	, Voted_Mail = SUM( CASE WHEN m.IDNUMBER IS NOT NULL THEN 1 ELSE 0 END )
	, Voted_Early = SUM( CASE WHEN e.IDNUMBER IS NOT NULL THEN 1 ELSE 0 END )
	, Not_Voted = SUM( CASE WHEN m.IDNUMBER IS NULL AND e.IDNUMBER IS NULL THEN 1 ELSE 0 END )
INTO Clark_County_Election_2024.dbo.VoteStatus
FROM Clark_County_Election_2024.dbo.VoterListAll a
LEFT JOIN Clark_County_Election_2024.dbo.EarlyVotes e
	ON a.REGISTRATION_NUM = e.IDNUMBER
LEFT JOIN Clark_County_Election_2024.dbo.MailInVotes m
	ON a.REGISTRATION_NUM = m.IDNUMBER
WHERE a.STATUS = 'A' -- Active
GROUP BY 
	a.PRECINCT
	, CASE 
		WHEN a.PARTY_REG = 'DEM' THEN 'Democrat'
		WHEN a.PARTY_REG = 'REP' THEN 'Republican'
		ELSE 'Z. Other'
	END
	, CASE
			WHEN YEAR( GETDATE() ) - CONVERT( INT, a.BIRTH_YEAR ) BETWEEN 17 AND 24 THEN '1. 17-24'
			WHEN YEAR( GETDATE() ) - CONVERT( INT, a.BIRTH_YEAR ) BETWEEN 25 AND 34 THEN '2. 25-34'
			WHEN YEAR( GETDATE() ) - CONVERT( INT, a.BIRTH_YEAR ) BETWEEN 35 AND 44 THEN '3. 35-44'
			WHEN YEAR( GETDATE() ) - CONVERT( INT, a.BIRTH_YEAR ) BETWEEN 45 AND 54 THEN '4. 45-54'
			WHEN YEAR( GETDATE() ) - CONVERT( INT, a.BIRTH_YEAR ) BETWEEN 55 AND 64 THEN '5. 55-64'
			WHEN YEAR( GETDATE() ) - CONVERT( INT, a.BIRTH_YEAR ) BETWEEN 65 AND 74 THEN '6. 65-74'
			WHEN YEAR( GETDATE() ) - CONVERT( INT, a.BIRTH_YEAR ) BETWEEN 75 AND 84 THEN '7. 75-84'
			WHEN YEAR( GETDATE() ) - CONVERT( INT, a.BIRTH_YEAR ) >= 85 THEN '8. 85+'
		END
	, COALESCE( m.BALLOT_RECEIVE_DATE, e.ACTIVITY_DATE )
ORDER BY 1,2,3,4,5,6