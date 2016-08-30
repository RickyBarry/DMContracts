/**********************************************************************/
/***  Migrate External Forest Contacts						    	***/
/***  Created by RB Jun 2016								    	***/
/***                                                                ***/
/***  Insert Exernal Forest contacts								***/
/***	into wts_coillte.PARTY table								***/
/***	and wts_coillte.PARTY_FUNCTIONS	- May not be needed			***/
/***	and wts_coillte.PARTY_ORG_SCOPE - May not be needed			***/
/***	and	wts_coillte.SD_PARTY_FOREST_CONTACTS					***/
/***	and wts_coillte.SD_PARTY_FC_DETAIL							***/
/***	and tfm.TFM_CMN_FOREST_CONTACTS table						***/
/***                                                                ***/
/***	This code inserts all external forest Contacts in to the	***/
/***	party table as there is no UID to check if they are already	***/ 
/***	in the table.												***/ 
/***	Last modified												***/
/***																***/
/***                                                                ***/
/**********************************************************************/

USE wts_coillte 

DECLARE @ID	varchar(10)
DECLARE @SQL varchar(1000)

-- Insert External Forest Contacts

-- First Part create temp tables and insert into the wts_coillte tables ---------------------------------------------------------------------

-- Get the Next ID to use for PARTY
SELECT @ID = NEXT_ID          
FROM [wts_coillte].[wts_coillte].[NEXT_SEQ]         
WHERE KEYWORD = 'PARTY';    

-- Create a temp table for Party
CREATE TABLE #Party	(
--					PartyID			int IDENTITY	(24186,1),				-- starting ID hard coded should be from NEXT_SEQ table
					FCName			varchar(50),
					OfficePhone		varchar(50),
					MobilePhone		varchar(50),
					Address1		varchar(50),
					FCContactID		numeric(38,0)
					)

-- Add an identity column that has the seed as @ID
SELECT  @SQL = 'ALTER TABLE #Party ADD PartyID int IDENTITY(' + @ID + ' ,1)'
Exec (@SQL) 
-- test - SELECT @SQL

INSERT INTO #Party
  SELECT	DISTINCT 
			FC_NAME,
			OFFICE_PHONE_NO,
			MOBILE_NO,
			ADDRESS_1,
			FC_CONTACT_ID 
	FROM [FOPSQL01].[FIS].[dbo].[FC_01]
	WHERE	COMPANY_EMPLOYEE = 'N'
	  AND	DISTRICT LIKE 'B%'
	  AND	FC_NAME is not null

-- Create a temp table for Contact Groups
CREATE TABLE #ContactGroups (
								ContactCode varchar(10),
								ContactGroup varchar(50)
							)

INSERT INTO #ContactGroups
SELECT DISTINCT CODE,
				CONTACT_GROUP
		FROM	tfm.dbo.TFM_VT_CMN_FOREST_CONTACTS

-- Create a temp table for External forest Contacts with populated id
CREATE TABLE #ExtForestContacts (
--								ExtForConID		int	IDENTITY (24186,1),     -- starting ID hard coded should be from NEXT_SEQ table
								ForestCode		varchar(4),
								ForestOID		int,
								District		varchar(2),
								FCContactID		numeric(38,0),
								FCName			varchar(50),
								FCType			varchar(30),
								FCRole			varchar(5),
								OfficePhone		varchar(24),
								MobilePhone		varchar(24),
								Address1		varchar(50),
								Address2		varchar(50),
								Address3		varchar(50),
								Address4		varchar(50),
								PartyID			int
							)

-- Add an identity column that has the seed as @ID
SELECT  @SQL = 'ALTER TABLE #ExtForestContacts ADD ExtForConID int IDENTITY(' + @ID + ' ,1)'
Exec (@SQL) 
-- test - SELECT @SQL

INSERT INTO #ExtForestContacts
  SELECT	fc.FOREST_CODE,
			fst.OBJECTID,
			fc.DISTRICT,
			fc.FC_CONTACT_ID,
			fc.FC_NAME,
			fc.FC_TYPE,
			frc.CODE,
			fc.OFFICE_PHONE_NO,
			fc.MOBILE_NO,
			fc.ADDRESS_1,
			fc.ADDRESS_2,
			fc.ADDRESS_3,
			fc.ADDRESS_4,
			pty.PartyID

	FROM [FOPSQL01].[FIS].[dbo].[FC_01] AS fc
	INNER JOIN [TFM].[dbo].[TFM_CMN_FOREST] AS fst 
	  ON fc.[FOREST_CODE] collate SQL_Latin1_General_CP1_CI_AS = fst.[FOREST_CODE] collate SQL_Latin1_General_CP1_CI_AS
	INNER JOIN [TFM].[dbo].[TFM_VT_CMN_FOREST_CONTACTS] AS frc
	  ON fc.[FC_TYPE] collate SQL_Latin1_General_CP1_CI_AS = frc.DESCRIPTION collate SQL_Latin1_General_CP1_CI_AS
	INNER JOIN #Party AS pty
	  ON fc.FC_CONTACT_ID = pty.FCContactID
	WHERE fc.COMPANY_EMPLOYEE = 'N'
	  AND fc.DISTRICT LIKE 'B%'

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
  SELECT	PartyID,
			'FC'						-- Forest Contact
	FROM	#Party 



---- Get the Next ID to use for PARTY_ORG_SCOPE
SELECT @ID = NEXT_ID          
FROM [wts_coillte].[wts_coillte].[NEXT_SEQ]         
WHERE KEYWORD = 'PARTY_ORG_SCOPE';


-- Create a temp table for party_org_scope  with a populated id
CREATE TABLE #PartyOrgScope (
--								PartyOrgScopeID	int IDENTITY (65401,1),		-- starting ID hard coded; should be from NEXT_SEQ table
								PartyID			int,
								OrgUnitID		int
							)

---- Add an identity column that has the seed as @ID
SELECT  @SQL = 'ALTER TABLE #PartyOrgScope ADD PartyOrgScopeID int IDENTITY(' + @ID + ' ,1)'
Exec (@SQL) 

INSERT INTO #PartyOrgScope
  SELECT	DISTINCT PartyID,
			RIGHT(DISTRICT,1)
	FROM #ExtForestContacts


-- Get the Next ID to use for SD_PARTY_FOREST_CONTACTS
SELECT @ID = NEXT_ID          
FROM [wts_coillte].[wts_coillte].[NEXT_SEQ]         
WHERE KEYWORD = 'SD_PARTY_FOREST_CONTACTS';

-- Create a temp table for SD_PARTY_FOREST_CONTACTS  with a populated id
CREATE TABLE #SDPartyForestContacts (
--								PartyForestContactID	int IDENTITY (40,1),		-- starting ID hard coded; should be from NEXT_SEQ table
								PartyID			int,
								BAUCode			int
							)

-- Add an identity column that has the seed as @ID
SELECT  @SQL = 'ALTER TABLE #SDPartyForestContacts ADD PartyForestContactID int IDENTITY(' + @ID + ' ,1)'
Exec (@SQL) 

INSERT INTO #SDPartyForestContacts
  SELECT	DISTINCT PartyID,
			RIGHT(DISTRICT,1)
	FROM #ExtForestContacts


-- Get the Next ID to use for SD_PARTY_FC_DETAIL
SELECT @ID = NEXT_ID          
FROM [wts_coillte].[wts_coillte].[NEXT_SEQ]         
WHERE KEYWORD = 'SD_PARTY_FC_DETAIL';

-- Create a temp table for SD_PARTY_FC_DETAIL  with a populated id
CREATE TABLE #SDPartyFCDetail (
--								PartyFCDetailID	int IDENTITY (250,1),		-- starting ID hard coded; should be from NEXT_SEQ table
								PSH_ID				int,
								ForestContactGroup	varchar(50),
								ForestRole			varchar(50),
								BAU					int,
								ForestCode			varchar(50)
							)

-- Add an identity column that has the seed as @ID
SELECT  @SQL = 'ALTER TABLE #SDPartyFCDetail ADD PartyFCDetailID int IDENTITY(' + @ID + ' ,1)'
Exec (@SQL) 

INSERT INTO #SDPartyFCDetail								
  SELECT	pfc.PartyForestContactID,
			cgp.ContactGroup,
			efc.FCRole,
			RIGHT(efc.District,1),
			efc.ForestCode
	FROM #ExtForestContacts AS efc 
	RIGHT JOIN #SDPartyForestContacts AS pfc 
		ON efc.PartyID = pfc.PartyID AND RIGHT(efc.District,1) = pfc.BAUCode
	INNER JOIN #ContactGroups AS cgp
		ON efc.FCRole = cgp.ContactCode

--Test  
--select * from #Party where FCName LIKE 'Brendan%'
--select * from #ContactGroups
--select * from #ExtForestContacts WHERE FCContactID = 2057
--select * from #PartyFunction
--select * from #PartyOrgScope order by PartyID 
--select * from #SDPartyForestContacts 
select * from #SDPartyFCDetail


-------- Insert External Forest Contacts into Party table ------------------------------------------------------
--INSERT INTO [wts_coillte].[wts_coillte].[PARTY]
--(
--	[PARTY_ID] ,
--	[CORPORATE_PARTY_NUMBER] ,
--	[STREET_ADDRESS],
--	[COMMUNITY],
--	[STATE_PROVINCE],
--	[ZIP_POSTAL_CODE],
--	[FAX_PHONE],
--	[E_MAIL],
--	[ACTIVE_STATUS],
--	[COUNTY_RM],
--	[DIRECTIONS],
--	[LAST_NAME],
--	[COMPANY_NAME],
--	[NICKNAME],
--	[COUNTRY],
--	[MOBILE_PHONE],
--	[WEBSITE],
--	[SI_NUMBER],
--	[TAX_CODE],
--	[PARTY_NUMBER],
--	[DISPLAY_NAME],
--	[FIRST_NAME],
--	[JOB_TITLE],
--	[BUSINESS_PHONE_1],
--	[BUSINESS_PHONE_2],
--	[BUSINESS_PHONE_3],
--	[HOME_PHONE],
--	[COMMENTS],
--	[CREDIT_LIMIT] ,
--	[CURRENT_DEBT] ,
--	[TAX_1_EXEMPT],
--	[TAX_2_EXEMPT],
--	[direct_deposit] ,
--	[TAX_3_EXEMPT],
--	[PRODUCTION_RATE_AMT] ,
--	[PRODUCTION_CAPABILITY_AMT],
--	[SAME_AS_MAILING_ADDRESS_IND],
--	[SHIPPING_STREET_ADDRESS],
--	[SHIPPING_COMMUNITY] ,
--	[SHIPPING_COUNTY_RM],
--	[SHIPPING_STATE_PROVINCE] ,
--	[SHIPPING_ZIP_POSTAL_CODE],
--	[SHIPPING_COUNTRY]
--)
--  SELECT	pty.PartyID,
--			NULL,
--			pty.Address1,
--			NULL,
--			NULL,
--			NULL,
--			NULL,
--			NULL,
--			'AC',			-- Active
--			NULL,
--			NULL,
--			NULL,
--			pty.FCName,
--			NULL,
--			NULL,
--			pty.MobilePhone,
--			NULL,
--			NULL,
--			NULL,
--			NULL,
--			pty.FCName,
--			NULL,
--			NULL,
--			pty.OfficePhone,
--			NULL,
--			NULL,
--			NULL,
--			pty.FCContactID,
--			NULL,
--			NULL,
--			NULL,
--			NULL,
--			NULL,
--			NULL,
--			NULL,
--			NULL,
--			'Yes',
--			NULL,
--			NULL,
--			NULL,
--			NULL,
--			NULL,
--			NULL
--	FROM	#Party AS pty


---- Update the next sequence number for PARTY
--UPDATE [wts_coillte].[wts_coillte].[NEXT_SEQ]
--  SET NEXT_ID = (
--					SELECT MAX (pty.PARTY_ID) + 1
--					FROM [wts_coillte].[wts_coillte].[PARTY] AS pty
--				)
--	WHERE KEYWORD = 'PARTY'
------------------------------------------------------------------------------------------------------------

---- Insert the External Forest Contacts in to the PARTY_FUNCTIONS TABLE (fcn_code for Forest Contacts = FC)
--INSERT INTO [wts_coillte].[wts_coillte].[PARTY_FUNCTIONS]
--	(
--		[PARTY_FCN_ID],
--		[PARTY_ID],
--		[FCN_CODE],
--		[FUNCTION_RATE],
--		[FUNCTION_RATE_UOM]
--	)
--  SELECT	ptf.PartyFunctionID,
--			ptf.PartyID,
--			ptf.FcnCode,
--			NULL,
--			NULL
--	FROM	#PartyFunction AS ptf

---- Update the next sequence number for PARTY_FUNCTION
--UPDATE [wts_coillte].[wts_coillte].[NEXT_SEQ]
--  SET NEXT_ID = (
--					SELECT MAX (ptf.PARTY_FCN_ID) + 1
--					FROM	[wts_coillte].[wts_coillte].[PARTY_FUNCTIONS] AS ptf
--				)
--	WHERE KEYWORD = 'PARTY_FUNCTIONS'

----------------------------------------------------------------------------------------------------------------

---- Insert the External Forest Contacts in to the PARTY_ORG_SCOPE ---------------------------------------------
---- May not be needed as SD_PARTY_FOREST_CONTACTS holds the same data
----
--INSERT INTO [wts_coillte].[wts_coillte].[PARTY_ORG_SCOPE]
--	(
--		[PARTY_ORG_SCOPE_ID],
--		[PARTY_ID],
--		[ORG_UNIT_ID]
--	)
--  SELECT	pos.PartyOrgScopeID,
--			pos.PartyID,
--			pos.OrgUnitID
--  FROM #PartyOrgScope AS pos

---- Update the next sequence number for PARTY_ORG_SCOPE
--UPDATE [wts_coillte].[wts_coillte].[NEXT_SEQ]
--  SET NEXT_ID = (
--					SELECT MAX (pos.PARTY_ORG_SCOPE_ID) + 1
--					FROM [wts_coillte].[PARTY_ORG_SCOPE] AS pos
--				)
--	WHERE KEYWORD = 'PARTY_ORG_SCOPE'

----------------------------------------------------------------------------------------------------------------------
--select * from wts_coillte.PARTY_ORG_SCOPE

---- Insert the External Forest Contacts in to the SD_PARTY_FOREST_CONTACTS ------------------------------------------
--INSERT INTO [wts_coillte].[wts_coillte].[SD_PARTY_FOREST_CONTACTS]
--	(
--		[PSH_ID],
--		[PARTY_ID],
--		[BAU_CODE]
--	)
--  SELECT	pfc.PartyForestContactID,
--			pfc.PartyID,
--			pfc.BAUCode
--  FROM #SDPartyForestContacts AS pfc

---- Update the next sequence number for PARTY_ORG_SCOPE
--UPDATE [wts_coillte].[wts_coillte].[NEXT_SEQ]
--  SET NEXT_ID = (
--					SELECT MAX (pfc.PSH_ID) + 1
--					FROM [wts_coillte].[SD_PARTY_FOREST_CONTACTS] AS pfc
--				)
--	WHERE KEYWORD = 'SD_PARTY_FOREST_CONTACTS'

----------------------------------------------------------------------------------------------------------------------


-- Insert the External Forest Contacts in to the SD_PARTY_FC_DETAIL------------------------------------------

--INSERT INTO [wts_coillte].[wts_coillte].[SD_PARTY_FC_DETAIL]
--	(
--		[PSHD_ID],
--		[PSH_ID],
--		[FOREST_CONTACT_GROUP],
--		[FOREST_ROLE],
--		[BAU],
--		[FOREST_CODE]
--	)
--  SELECT	spd.PartyFCDetailID,
--			spd.PSH_ID,
--			spd.ForestContactGroup,
--			spd.ForestRole,
--			spd.BAU,
--			spd.ForestCode
--  FROM #SDPartyFCDetail AS spd

---- Update the next sequence number for PARTY_FC_DETAIL
--UPDATE [wts_coillte].[wts_coillte].[NEXT_SEQ]
--  SET NEXT_ID = (
--					SELECT MAX (spd.PSHD_ID) + 1
--					FROM [wts_coillte].[SD_PARTY_FC_DETAIL] AS spd
--				)
--	WHERE KEYWORD = 'SD_PARTY_FC_DETAIL'
------------------------------------------------------------------------------------------------------------------------

--  TEST
  --select * from [wts_coillte].[wts_coillte].[PARTY]
  --where PARTY_ID in (SELECT [PARTY_ID]
		--				FROM [wts_coillte].[wts_coillte].[PARTY_FUNCTIONS]
		--				WHERE FCN_CODE = 'FC'
		--			)

DROP TABLE #Party

DROP TABLE #ContactGroups

DROP TABLE #ExtForestContacts

DROP TABLE #PartyFunction

DROP TABLE #PartyOrgScope

DROP TABLE #SDPartyForestContacts

DROP TABLE #SDPartyFCDetail

