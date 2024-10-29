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
	'Z:\Clark_County_Elections_2024\Data\Voter_List\COUNTY_all_TV\county_all_TV.txt' 
	WITH 
	( 
		FORMAT = 'CSV'
		, FIRSTROW = 2
		, FIELDQUOTE = '"'
		, FIELDTERMINATOR = ','		
		, ROWTERMINATOR = '\n'
		, TABLOCK
	)
--(1,748,135 rows affected) 10/29/2024

--=============================================================================
-- Put a unique clustered index on the registration number field in the table
-- as we will be using this field for joining to other tables
--=============================================================================
CREATE UNIQUE CLUSTERED INDEX UC_IDX_REG ON Clark_County_Election_2024.dbo.VoterListAll( REGISTRATION_NUM )