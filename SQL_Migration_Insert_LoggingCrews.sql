/**********************************************************************/
/***  Migrate Harvesters and Logging Crew					    	***/
/***  Created by RB Jun 2016								    	***/
/***                                                                ***/
/***  Insert Harvester and Logging Crew								***/
/***	into wts_coillte.Party table								***/
/***	and wts_coillte.SD_D_LOGGING_CREW							***/
/***                                                                ***/
/***	Last modified												***/
/***                                                                ***/
/**********************************************************************/

USE tfm 


DECLARE @ID	varchar(10)
DECLARE @SQL varchar(1000)

-- Get the Next ID to use for PARTY
SELECT @ID = NEXT_ID          
FROM [wts_coillte].[wts_coillte].[NEXT_SEQ]         
WHERE KEYWORD = 'PARTY';    

-- Insert Harvester and Logging Crews

-- First Part insert into the party table ---------------------------------------------------------------------------------------------
-- Create a temp table for Harvesters with populated id
CREATE TABLE #Harvester (
--							HarvesterID		int	IDENTITY (24186,1),     -- starting ID hard coded should be from NEXT_SEQ table
							CorporatePartyNumber		varchar(30),
							StreetAddress				varchar(25),
							Community					varchar(50),
							Email						varchar(255),
							ActiveStatus				varchar(15),
							CountyRM					varchar(50),
							CompanyName					varchar(255),
							Country						varchar(50),
							MobilePhone					varchar(35),
							SI_Number					varchar(20),
							TaxCode						varchar(20),
							PartyNumber					varchar(30),
							DisplayName					varchar(255),
							BusinessPhone1				varchar(35),
							Comments					varchar(2000)	
						)

-- Add an identity column that has the seed as @ID
SELECT  @SQL = 'ALTER TABLE #Harvester ADD HarvesterID int IDENTITY(' + @ID + ' ,1)'
Exec (@SQL) 
-- test - SELECT @SQL

INSERT INTO #Harvester 
  SELECT	[CORPORATE_PARTY_NUMBER],
			LEFT([STREET_ADDRESS],25),
			[COMMUNITY],
			[E_MAIL],
			[ACTIVE_STATUS],
			[COUNTY_RM],
      		[COMPANY_NAME],
			[COUNTRY],
			[MOBILE_PHONE],
			[SI_NUMBER],
			[TAX_CODE],
			[PARTY_NUMBER],
			[DISPLAY_NAME],
			LEFT([BUSINESS_PHONE_1],35),
			[COMMENTS]
  FROM [FOPSQL01].[tfm].[dbo].[Harvester]

-- Get the Next ID to use for PARTY_FUNCTIONS
SELECT @ID = NEXT_ID          
FROM [wts_coillte].[wts_coillte].[NEXT_SEQ]         
WHERE KEYWORD = 'PARTY_FUNCTIONS';
    
-- Create a temp table for party_functions with a populated id
CREATE TABLE #PartyFunction (
--							PartyFunctionID		int	IDENTITY (18447,1),		-- starting ID hard coded should be from NEXT_SEQ table
							PartyID				int,
							FcnCode				varchar(5)
							)

-- Add an identity column that has the seed as @ID
SELECT  @SQL = 'ALTER TABLE #PartyFunction ADD PartyFunctionID int IDENTITY(' + @ID + ' ,1)'
Exec (@SQL) 

INSERT INTO #PartyFunction
  SELECT	HarvesterID,
			'HA'						-- Harvester
	FROM	#Harvester

-- Get the Next ID to use for PARTY_ORG_SCOPE
SELECT @ID = NEXT_ID          
FROM [wts_coillte].[wts_coillte].[NEXT_SEQ]         
WHERE KEYWORD = 'PARTY_ORG_SCOPE';

-- Create a temp table for party_org_scope  with a populated id
CREATE TABLE #PartyOrgScope (
--								PartyOrgScopeID	int IDENTITY (58184,1),		-- starting ID hard coded; should be from NEXT_SEQ table
								PartyID			int,
								OrgUnitID		int
							)

-- Add an identity column that has the seed as @ID
SELECT  @SQL = 'ALTER TABLE #PartyOrgScope ADD PartyOrgScopeID int IDENTITY(' + @ID + ' ,1)'
Exec (@SQL) 

INSERT INTO #PartyOrgScope
  SELECT	HarvesterID,
			100
	FROM #Harvester

-- Get the Next ID to use for SD_D_LOGGING_CREW
SELECT @ID = NEXT_ID          
FROM [wts_coillte].[wts_coillte].[NEXT_SEQ]         
WHERE KEYWORD = 'SD_D_LOGGING_CREW';    

-- Create a temp table for Logging Crew with populated id
CREATE TABLE #LoggingCrew (
--							LoggingCrewID			int	IDENTITY (24186,1),     -- starting ID hard coded should be from NEXT_SEQ table
							PartyID					int,
							LogCrewCode				varchar(8),
							HarvesterModel			varchar(15),
							HarvesterYearProduction	int,
							ForwarderModel			varchar(15),
							ForwarderYearProduction	int,
							OperatorProductivityPct	int,
							MachineType				int,
							MachineProdDowngradePct	int
						)

-- Add an identity column that has the seed as @ID
SELECT  @SQL = 'ALTER TABLE #LoggingCrew ADD LoggingCrewID int IDENTITY(' + @ID + ' ,1)'
Exec (@SQL) 
-- test - SELECT @SQL


INSERT INTO #LoggingCrew  

	SELECT	hrv.HarvesterID, 
			lgc.[LOG_CREW_CODE],
			lgc.[HARVESTER_MODEL],
			lgc.[HARVESTER_YEAR_PRODUCTION],
			lgc.[FORWARDER_MODEL],
			lgc.[FORWARDER_YEAR_PRODUCTION],
			lgc.[OPERATOR_PRODUCTIVITY_PCT],
			lgc.[MACHINE_TYPE],
			lgc.[MACHINE_PROD_DOWNGRADE_PCT]
  FROM [FOPSQL01].[tfm].[dbo].[LoggingCrew] AS lgc
  INNER JOIN #Harvester AS hrv ON lgc.[PARTY_NUMBER] =  hrv.PartyNumber


--Test  
--SELECT * FROM #Harvester
--SELECT * from #PartyFunction
--SELECT * from #PartyOrgScope
--SELECT * FROM #LoggingCrew

---------- Insert Harvesters into Party table
INSERT INTO [wts_coillte].[wts_coillte].[PARTY]
  SELECT	hrv.HarvesterID,
			hrv.CorporatePartyNumber,
			hrv.StreetAddress,
			hrv.Community,
			NULL,
			NULL,
			NULL,
			hrv.Email,
			'AC',			-- Active
			hrv.CountyRM,
			NULL,
			NULL,
			hrv.CompanyName,
			NULL,
			hrv.Country,
			hrv.MobilePhone,
			NULL,
			hrv.SI_Number,
			hrv.TaxCode,
			hrv.PartyNumber,
			hrv.DisplayName,
			NULL,
			NULL,
			hrv.BusinessPhone1,
			NULL,
			NULL,
			NULL,
			hrv.Comments,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			'Yes',
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL
	FROM	#Harvester AS hrv

-- Insert the Harvesters in to the PARTY_FUNCTIONS TABLE (fcn_code for Forest Contacts = HA)
INSERT INTO [wts_coillte].[wts_coillte].[PARTY_FUNCTIONS]
  SELECT	ptf.PartyFunctionID,
			ptf.PartyID,
			ptf.FcnCode,
			NULL,
			NULL
	FROM	#PartyFunction As ptf

---- Insert the Harvesters in to the PARTY_ORG_SCOPE
INSERT INTO [wts_coillte].[wts_coillte].[PARTY_ORG_SCOPE]
  SELECT	pos.PartyOrgScopeID,
			pos.PartyID,
			pos.OrgUnitID
  FROM #PartyOrgScope AS pos

-- Insert into SD_D_LOGGING_CREW----------------------------------------------------------------
INSERT INTO [wts_coillte].[wts_coillte].[SD_D_LOGGING_CREW]
	SELECT	LoggingCrewID,
			PartyID,
			LogCrewCode,
			HarvesterModel,
			HarvesterYearProduction,
			ForwarderModel,
			ForwarderYearProduction,
			OperatorProductivityPct,
			MachineType,
			MachineProdDowngradePct
		FROM #LoggingCrew


-- Update the next_seq table for Party, Party Function, Party Org Scope, Logging Crew
UPDATE [wts_coillte].[wts_coillte].[NEXT_SEQ]
  SET NEXT_ID = (
					SELECT MAX (PARTY_ID) + 1
					FROM [wts_coillte].[wts_coillte].[PARTY] 
				)
	WHERE KEYWORD = 'PARTY'

UPDATE [wts_coillte].[wts_coillte].[NEXT_SEQ]
  SET NEXT_ID = (
					SELECT MAX (ptf.PartyFunctionID) + 1
					FROM	#PartyFunction AS ptf
				)
	WHERE KEYWORD = 'PARTY_FUNCTIONS'

UPDATE [wts_coillte].[wts_coillte].[NEXT_SEQ]
  SET NEXT_ID = (
					SELECT MAX (pos.PartyOrgScopeID) + 1
					FROM #PartyOrgScope AS pos
				)
	WHERE KEYWORD = 'PARTY_ORG_SCOPE'

UPDATE [wts_coillte].[wts_coillte].[NEXT_SEQ]
  SET NEXT_ID = (
					SELECT MAX (pos.PartyOrgScopeID) + 1
					FROM #PartyOrgScope AS pos
				)
	WHERE KEYWORD = 'SD_D_LOGGING_CREW'

 DROP TABLE #Harvester 
 DROP TABLE #PartyFunction
 DROP TABLE #PartyOrgScope
 DROP TABLE #LoggingCrew

--  TEST
  select * from [wts_coillte].[wts_coillte].[PARTY]
  where PARTY_ID in (SELECT [PARTY_ID]
						FROM [wts_coillte].[wts_coillte].[PARTY_FUNCTIONS]
						WHERE FCN_CODE = 'HA'
					)

