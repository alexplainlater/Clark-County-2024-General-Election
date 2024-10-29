--=============================================================================
-- There are a few records that show up in one of the voter files that don't
-- show up in the main voter role, so weneed to bring all the ID numbers 
-- together and then de-dupe.
--=============================================================================
IF OBJECT_ID( 'tempdb..#tmp' ) IS NOT NULL
	DROP TABLE #tmp
SELECT
	IDNUMBER = REGISTRATION_NUM
	, PRECINCT
	, PARTY = PARTY_REG
	, BIRTH_YEAR
	, src = 'Voter List'
INTO #tmp
FROM Clark_County_Election_2024.dbo.VoterListAll

UNION

SELECT
	IDNUMBER
	, PRECINCT
	, PARTY
	, BIRTH_YEAR = NULL
	, src = 'Early Vote'
FROM Clark_County_Election_2024.dbo.EarlyVotes

UNION

SELECT
	IDNUMBER
	, PRECINCT
	, PARTY = NULL
	, BIRTH_YEAR = NULL
	, src = 'Mail In'
FROM Clark_County_Election_2024.dbo.MailInVotes

--=============================================================================
-- Dedupe, keeping the records with a birth year populated, then records with a 
-- party populated, then records in person, by mail, and then voter list as it 
-- may be the least up-to-date
--=============================================================================
IF OBJECT_ID( 'tempdb..#tmp2' ) IS NOT NULL
	DROP TABLE #tmp2
SELECT *
	, RN = ROW_NUMBER() OVER( 
		PARTITION BY 
			IDNUMBER 
		ORDER BY 
			CASE WHEN BIRTH_YEAR IS NOT NULL THEN 1 ELSE 99 END
			, CASE WHEN NULLIF( PARTY, 'NA' ) IS NOT NULL THEN 1 ELSE 99 END
			, CASE WHEN src = 'Early Vote' THEN 1 WHEN src = 'Mail In' THEN 2 WHEN src = 'Voter List' THEN 3 END 
	)
INTO #tmp2
FROM #tmp

DELETE a
FROM #tmp2 a
WHERE a.RN > 1

--=============================================================================
-- Create a summary table of the current voter turnout status
--=============================================================================
IF OBJECT_ID( 'Clark_County_Election_2024.dbo.VoteStatus' ) IS NOT NULL
	DROP TABLE Clark_County_Election_2024.dbo.VoteStatus
SELECT
	a.PRECINCT
	, PARTY =	CASE 
					WHEN a.PARTY = 'DEM' THEN 'Democrat'
					WHEN a.PARTY = 'REP' THEN 'Republican'
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
			ELSE '9. Unknown'
		END
	, G2024_Voted_Date = COALESCE( m.BALLOT_RECEIVE_DATE, e.ACTIVITY_DATE )
	, QTY = COUNT(*)
	, Voted_Mail = SUM( CASE WHEN m.IDNUMBER IS NOT NULL THEN 1 ELSE 0 END )
	, Voted_Early = SUM( CASE WHEN e.IDNUMBER IS NOT NULL THEN 1 ELSE 0 END )
	, Not_Voted = SUM( CASE WHEN m.IDNUMBER IS NULL AND e.IDNUMBER IS NULL THEN 1 ELSE 0 END )
INTO Clark_County_Election_2024.dbo.VoteStatus
FROM #tmp2 a
LEFT JOIN Clark_County_Election_2024.dbo.EarlyVotes e
	ON a.IDNUMBER = e.IDNUMBER
LEFT JOIN Clark_County_Election_2024.dbo.MailInVotes m
	ON a.IDNUMBER = m.IDNUMBER
GROUP BY 
	a.PRECINCT
	, CASE 
		WHEN a.PARTY = 'DEM' THEN 'Democrat'
		WHEN a.PARTY = 'REP' THEN 'Republican'
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
			ELSE '9. Unknown'
		END
	, COALESCE( m.BALLOT_RECEIVE_DATE, e.ACTIVITY_DATE )
ORDER BY 1,2,3,4