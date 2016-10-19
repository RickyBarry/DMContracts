/**********************************************************************/
/***  Migrate Stakeholders									    	***/
/***  Created by RB Oct 2016								    	***/
/***                                                                ***/
/***  Insert Stakeholders											***/
/***	from FIS.STAKEHOLDERS										***/
/***	into wts_coillte.PARTY table								***/
/***	and wts_coillte.PARTY_FUNCTIONS								***/
/***	and wts_coillte.PARTY_ORG_SCOPE								***/
/***	and wts_coillte.SD_PARTY_STAKEHOLDERS						***/
/***                                                                ***/
/***	Last modified												***/
/***                                                                ***/
/**********************************************************************/

USE wts_coillte 

DECLARE @ID	varchar(10)		-- Hold the Next ID value
DECLARE @SQL varchar(1000)  -- Add ID row to tables

-- Create temp tables and insert into the wts_coillte tables ---------------------------------------------------------------------

-- Get the Next ID to use for PARTY
SELECT @ID = NEXT_ID          
FROM [wts_coillte].[wts_coillte].[NEXT_SEQ]         
WHERE KEYWORD = 'PARTY';    

-- Create a temp table for Party
CREATE TABLE #Party	(
--					PartyID			numeric(10,0) IDENTITY	(1,1),				-- starting ID is from NEXT_SEQ table
					StakeholderID	varchar(30),
					Address1		varchar(50),
					StakeholderType	varchar(50),
					Email			varchar(100),
					AddressCounty	varchar(50),
					Surname			varchar(50),
					Organisation	varchar(100),
					PhoneNo			varchar(35),
					FirstName		varchar(50),
					Comments		varchar(100),
					District		varchar(7),
					RegistrationDate datetime,
					Title			varchar(20),
					OrganisationRole varchar(30),
					StakeholderCategory varchar(30)
					)

-- Add an identity column that has the seed as @ID
SELECT  @SQL = 'ALTER TABLE #Party ADD PartyID numeric(10,0) IDENTITY(' + @ID + ' ,1)'
-- test - SELECT @SQL
Exec (@SQL) 

INSERT INTO #Party
  SELECT	Stakeholder_ID,
			LEFT(ADDRESS_1,50), 
			STAKEHOLDER_TYPE,
			EMAIL,
			LEFT(ADDRESS_COUNTY,50),
			SURNAME,
			ORGANISATION,
			LEFT(PHONE_NO,35),
			FIRST_NAME,
			COMMENTS,
			DISTRICT,
			DATETIME_MODIFIED,
			TITLE,
			ORGANISATIONAL_ROLE,
			STAKEHOLDER_CATEGORY  
	FROM [FOPSQL01].[FIS].[dbo].[STAKEHOLDERS]
	WHERE	DISABLED_FLAG = 'N'

-------------------------------------------------------------------------------------

-- Get the Next ID to use for PARTY_FUNCTIONS
SELECT @ID = NEXT_ID          
FROM [wts_coillte].[wts_coillte].[NEXT_SEQ]         
WHERE KEYWORD = 'PARTY_FUNCTIONS';
    
-- Create a temp table for party_functions with a populated id
CREATE TABLE #PartyFunction (
--							PartyFunctionID		int	IDENTITY (1,1),		-- starting ID is from NEXT_SEQ table
							PartyID				int,
							FcnCode				varchar(5)
							)

-- Add an identity column that has the seed as @ID
SELECT  @SQL = 'ALTER TABLE #PartyFunction ADD PartyFunctionID int IDENTITY(' + @ID + ' ,1)'
Exec (@SQL) 

INSERT INTO #PartyFunction
  SELECT	PartyID,
			'SH'						-- Stakeholder
	FROM	#Party 

--------------------------------------------------------------------------------------------------

------ Get the Next ID to use for PARTY_ORG_SCOPE
SELECT @ID = NEXT_ID          
FROM [wts_coillte].[wts_coillte].[NEXT_SEQ]         
WHERE KEYWORD = 'PARTY_ORG_SCOPE';


-- Create a temp table for party_org_scope  with a populated id
CREATE TABLE #PartyOrgScope (
--								PartyOrgScopeID	numeric(10,0) IDENTITY (1,1),		-- starting ID is from NEXT_SEQ table
								PartyID			numeric(10,0),
								OrgUnitID		numeric(10,0)
							)

------ Add an identity column that has the seed as @ID
SELECT  @SQL = 'ALTER TABLE #PartyOrgScope ADD PartyOrgScopeID numeric(10,0) IDENTITY(' + @ID + ' ,1)'
Exec (@SQL) 

INSERT INTO #PartyOrgScope
  SELECT	PartyID,
			CASE 
				WHEN DISTRICT = 'Central' THEN 100
				ELSE RIGHT(DISTRICT,1)
			END
	FROM #Party

----------------------------------------------------------------------------------------------------------------

------ Get the Next ID to use for PARTY_STAKEHOLDERS
SELECT @ID = NEXT_ID          
FROM [wts_coillte].[wts_coillte].[NEXT_SEQ]         
WHERE KEYWORD = 'SD_PARTY_STAKEHOLDERS';

-- Create a temp table for party_org_scope  with a populated id
CREATE TABLE #PartyStakeholders (
--								PartyStakeholderID	int IDENTITY (1,1),		-- starting ID is from NEXT_SEQ table
								PartyID			numeric(10,0),
								RegistrationDate datetime,
								BAUCode			numeric(10,0),
								Title			numeric(10,0),
								OrgRole			numeric(10,0),
								Category		numeric(15,0)
							)

------ Add an identity column that has the seed as @ID
SELECT  @SQL = 'ALTER TABLE #PartyStakeholders ADD PartyStakeholderID numeric(10,0) IDENTITY(' + @ID + ' ,1)'
Exec (@SQL) 

INSERT INTO #PartyStakeholders
  SELECT	pty.PartyID,
			CASE
				WHEN pty.RegistrationDate IS NULL THEN '2015-12-31 12:00:00.000'  -- Have to do CASE statement this way to recognise NULL
				ELSE pty.RegistrationDate
			END,
			CASE 
				WHEN pty.District = 'Central' THEN 100
				ELSE RIGHT(pty.District,1)
			END,
			ttl.code,
			rol.code,
			stc.code
	FROM #Party AS pty
	  LEFT JOIN wts_coillte.SD_D_TITLE AS ttl 
	    ON pty.Title COLLATE SQL_Latin1_General_CP1_CI_AS = ttl.description COLLATE SQL_Latin1_General_CP1_CI_AS
	  LEFT JOIN wts_coillte.SD_D_ORG_ROLE AS rol
	    ON pty.OrganisationRole COLLATE SQL_Latin1_General_CP1_CI_AS = rol.description COLLATE SQL_Latin1_General_CP1_CI_AS
	  LEFT JOIN wts_coillte.SD_D_SH_CATEGORY AS stc
	    ON pty.StakeholderCategory COLLATE SQL_Latin1_General_CP1_CI_AS = stc.description COLLATE SQL_Latin1_General_CP1_CI_AS

--Test  
--select * from #Party     
--select * from #PartyFunction
--select * from #PartyOrgScope			
--select * from #PartyStakeholders 

-------- Insert External Forest Contacts into Party table ------------------------------------------------------
INSERT INTO [wts_coillte].[PARTY]
(
	[PARTY_ID] ,
	[CORPORATE_PARTY_NUMBER] ,
	[STREET_ADDRESS],
	[COMMUNITY],
	[STATE_PROVINCE],
	[ZIP_POSTAL_CODE],
	[FAX_PHONE],
	[E_MAIL],
	[ACTIVE_STATUS],				-- Insert AC as Active
	[COUNTY_RM],
	[DIRECTIONS],
	[LAST_NAME],
	[COMPANY_NAME],
	[NICKNAME],
	[COUNTRY],
	[MOBILE_PHONE],
	[WEBSITE],
	[SI_NUMBER],
	[TAX_CODE],
	[PARTY_NUMBER],
	[DISPLAY_NAME],
	[FIRST_NAME],
	[JOB_TITLE],
	[BUSINESS_PHONE_1],
	[BUSINESS_PHONE_2],
	[BUSINESS_PHONE_3],				-- Inserting DM in this field to identify Parties we have migrated
	[HOME_PHONE],
	[COMMENTS],
	[CREDIT_LIMIT] ,
	[CURRENT_DEBT] ,
	[TAX_1_EXEMPT],
	[TAX_2_EXEMPT],
	[direct_deposit] ,
	[TAX_3_EXEMPT],
	[PRODUCTION_RATE_AMT] ,
	[PRODUCTION_CAPABILITY_AMT],
	[SAME_AS_MAILING_ADDRESS_IND],
	[SHIPPING_STREET_ADDRESS],
	[SHIPPING_COMMUNITY] ,
	[SHIPPING_COUNTY_RM],
	[SHIPPING_STATE_PROVINCE] ,
	[SHIPPING_ZIP_POSTAL_CODE],
	[SHIPPING_COUNTRY]
)
  SELECT	pty.PartyID AS PARTY_ID,
			NULL,
			pty.Address1 AS STREET_ADDRESS,
			NULL,
			NULL,
			NULL,
			NULL,
			pty.Email AS E_MAIL,
			'AC' AS ACTIVE_STATUS,									-- Active
			pty.AddressCounty AS COUNTY_RM,
			NULL,
			pty.Surname AS LAST_NAME,
			pty.Organisation AS COMPANY_NAME,
			NULL,
			NULL,
			pty.PhoneNo AS MOBILE_PHONE,
			NULL,
			NULL,
			NULL,
			'FIS SH ID: ' + pty.StakeholderID AS Party_Number,		-- Putting the FIS ID inParty Number,
			pty.FirstName + ' ' + pty.Surname AS DISPLAY_NAME,
			pty.FirstName AS FIRST_NAME ,
			pty.OrganisationRole AS JOB_TITLE,
			pty.PhoneNo AS BUSINESS_PHONE_1,
			NULL,
			'DM' As BUSINESS_PHONE_3,				-- To distinguish Data Migration added Party
			NULL, 
			pty.Comments AS Comments,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			'Yes' AS SAME_AS_MAILING_ADDRESS_IND,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL
	FROM	#Party AS pty

---- Update the next sequence number for PARTY
UPDATE [wts_coillte].[wts_coillte].[NEXT_SEQ]
  SET NEXT_ID = (
					SELECT MAX (pty.PARTY_ID) + 1
					FROM [wts_coillte].[wts_coillte].[PARTY] AS pty
				)
	WHERE KEYWORD = 'PARTY'
--------------------------------------------------------------------------------------------------------------

---- Insert the Stakeholders in to the PARTY_FUNCTIONS TABLE (fcn_code for Stakeholders = SH)
INSERT INTO [wts_coillte].[wts_coillte].[PARTY_FUNCTIONS]
	(
		[PARTY_FCN_ID],
		[PARTY_ID],
		[FCN_CODE],
		[FUNCTION_RATE],
		[FUNCTION_RATE_UOM]
	)
  SELECT	ptf.PartyFunctionID,
			ptf.PartyID,
			ptf.FcnCode,
			NULL,
			NULL
	FROM	#PartyFunction AS ptf

-- Update the next sequence number for PARTY_FUNCTION
UPDATE [wts_coillte].[wts_coillte].[NEXT_SEQ]
  SET NEXT_ID = (
					SELECT MAX (ptf.PARTY_FCN_ID) + 1
					FROM	[wts_coillte].[PARTY_FUNCTIONS] AS ptf
				)
	WHERE KEYWORD = 'PARTY_FUNCTIONS'

------------------------------------------------------------------------------------------------------------------

------ Insert the Stakeholders in to the PARTY_ORG_SCOPE ---------------------------------------------

INSERT INTO [wts_coillte].[wts_coillte].[PARTY_ORG_SCOPE]
	(
		[PARTY_ORG_SCOPE_ID],
		[PARTY_ID],
		[ORG_UNIT_ID]
	)
  SELECT	pos.PartyOrgScopeID,
			pos.PartyID,
			pos.OrgUnitID
  FROM #PartyOrgScope AS pos

-- Update the next sequence number for PARTY_ORG_SCOPE
UPDATE [wts_coillte].[wts_coillte].[NEXT_SEQ]
  SET NEXT_ID = (
					SELECT MAX (pos.PARTY_ORG_SCOPE_ID) + 1
					FROM [wts_coillte].[PARTY_ORG_SCOPE] AS pos
				)
	WHERE KEYWORD = 'PARTY_ORG_SCOPE'

------------------------------------------------------------------------------------------------------------------------

------ Insert the Stakeholders in to the SD_PARTY_STAKEHOLDERS ------------------------------------------
INSERT INTO [wts_coillte].[SD_PARTY_STAKEHOLDERS]
	(
		[PSH_ID],
		[PARTY_ID],
		[REGISTRATION_DATE],
		[BAU_CODE],
		[TITLE],
		[ORG_ROLE],
		[CATEGORY]
	)
  SELECT	psh.PartyStakeholderID,
			psh.PartyID,
			psh.RegistrationDate,
			psh.BAUCode,
			psh.Title,
			psh.OrgRole,
			psh.Category
  FROM #PartyStakeholders AS psh

-- Update the next sequence number for PARTY_STAKEHOLDERS
UPDATE [wts_coillte].[wts_coillte].[NEXT_SEQ]
  SET NEXT_ID = (
					SELECT MAX (pfc.PSH_ID) + 1
					FROM [wts_coillte].[SD_PARTY_STAKEHOLDERS] AS pfc
				)
	WHERE KEYWORD = 'SD_PARTY_STAKEHOLDERS'

------------------------------------------------------------------------------------------------------------------------

DROP TABLE #Party
DROP TABLE #PartyFunction
DROP TABLE #PartyOrgScope
DROP TABLE #PartyStakeholders

--  TEST
--select * from [wts_coillte].[wts_coillte].[PARTY]
--where PARTY_ID in (SELECT [PARTY_ID]
--				FROM [wts_coillte].[wts_coillte].[PARTY_FUNCTIONS]
--				WHERE FCN_CODE = 'SH'
--			)
--select * from wts_coillte.PARTY_ORG_SCOPE
--select * from [wts_coillte].[SD_PARTY_STAKEHOLDERS]
