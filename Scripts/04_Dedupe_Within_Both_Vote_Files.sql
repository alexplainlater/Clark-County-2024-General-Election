--=============================================================================
-- I wonder if there are multiple entries for an ID between mail in and early voting
--=============================================================================
IF OBJECT_ID( 'tempdb..#tmp' ) IS NOT NULL
	DROP TABLE #tmp
SELECT
	IDNUMBER
	, Activity_Date = ACTIVITY_DATE
	, src = 'Early Vote'
	, xid
INTO #tmp
FROM Clark_County_Election_2024.dbo.EarlyVotes

UNION

SELECT
	IDNUMBER
	, Activity_Date = BALLOT_RECEIVE_DATE
	, src = 'Mail Vote'
	, xid
FROM Clark_County_Election_2024.dbo.MailInVotes

SELECT *
FROM #tmp
WHERE IDNUMBER IN(
	SELECT
		IDNUMBER
	FROM #tmp
	GROUP BY
		IDNUMBER
	HAVING COUNT(*) > 1
)
ORDER BY IDNUMBER, src

--=============================================================================
-- of course there are...
-- Let's keep the most recent record received and if they're both the same
-- we'll keep the early vote record since it was in person.
--=============================================================================
IF OBJECT_ID( 'tempdb..#tmp2' ) IS NOT NULL
	DROP TABLE #tmp2
SELECT *
	, RN = ROW_NUMBER() OVER( 
		PARTITION BY 
			IDNUMBER 
		ORDER BY 
			Activity_Date DESC 
			, CASE WHEN src = 'Early Vote' THEN 1 ELSE 9 END ASC
	)
INTO #tmp2
FROM #tmp

DELETE m
FROM Clark_County_Election_2024.dbo.MailInVotes m
INNER JOIN #tmp2 d
	ON m.IDNUMBER = d.IDNUMBER
	AND m.xid = d.xid
	AND d.src = 'Mail Vote'
WHERE d.RN > 1

DELETE e
FROM Clark_County_Election_2024.dbo.EarlyVotes e
INNER JOIN #tmp2 d
	ON e.IDNUMBER = d.IDNUMBER
	AND e.xid = d.xid
	AND d.src = 'Early Vote'
WHERE d.RN > 1