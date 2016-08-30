/**********************************************************************/
/***  Migrate Hauliers										    	***/
/***  Created by RB May 2016								    	***/
/***                                                                ***/
/***  Insert Hauliers data in FOPSQL01.FIS.FD_HAULIERS				***/
/***	Where the disabled flag is set to N							***/
/***	into wts_coillte.Party table								***/
/***                                                                ***/
/***	Last modified												***/
/***                                                                ***/
/**********************************************************************/

USE wts_coillte


DECLARE @ID	varchar(10)
DECLARE @SQL varchar(1000)

-- Get the Next ID to use for PARTY
SELECT @ID = NEXT_ID          
FROM [wts_coillte].[NEXT_SEQ]         
WHERE KEYWORD = 'PARTY';    

-- Insert Hauliers

-- Create a temp table for Hauliers with populated id
CREATE TABLE #Hauliers (
--								HaulierID		int	IDENTITY (24186,1),     -- starting ID hard coded should be from NEXT_SEQ table
								CtrCode			varchar(20),
								HaulierBase		varchar(15),
								HaulierEmail	varchar(50),
								HaulierName		varchar(50),
								HaulierCode		varchar(50),
								LicenceNo		numeric(6,0),
								LicenceExpiry	datetime,
								LicencedLorries numeric(2,0),
								ManualUpdateMax char(1)
							)

-- Add an identity column that has the seed as @ID
SELECT  @SQL = 'ALTER TABLE #Hauliers ADD HaulierID int IDENTITY(' + @ID + ' ,1)'
Exec (@SQL) 
-- test - SELECT @SQL

INSERT INTO #Hauliers
  SELECT	CTR_CODE,
			HAULIER_BASE,
			HAULIER_EMAIL,
			UPPER(HAULIER_NAME),
			HAULIER_CODE,
			LICENCE_NO,
			LICENCE_EXPIRY,
			LICENCED_LORRIES,
			MANUAL_UPDATE_MAX_DOCKETS
	FROM [FOPSQL01].[FIS].[dbo].[FD_HAULIERS]
	WHERE DISABLED_FLAG = 'N'


-- Get the Next ID to use for PARTY_FUNCTIONS
SELECT @ID = NEXT_ID          
FROM [wts_coillte].[NEXT_SEQ]         
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
  SELECT	HaulierID,
			'TR'
	FROM #Hauliers

-- Get the Next ID to use for PARTY_ORG_SCOPE
SELECT @ID = NEXT_ID          
FROM [wts_coillte].[NEXT_SEQ]         
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
  SELECT	HaulierID,
			100
	FROM #Hauliers

-- Get the Next ID to use for SD_HAULIER
SELECT @ID = NEXT_ID          
FROM [wts_coillte].[NEXT_SEQ]         
WHERE KEYWORD = 'SD_HAULIER';

-- Create a temp table for SD_Hauliers
CREATE TABLE #SDHaulier (
--							SDHaulierID			int IDENTITY (41,1),		-- starting ID hard coded; should be from NEXT_SEQ table
							PartyID				numeric(10,0),
							HaulierCode			varchar(4),
							ManualUpdate		varchar(3),
							HaulageLicenseNo	numeric(6,0),
							NumOfLorries		numeric(5,0),
							ExpiryDate			datetime
						)

-- Add an identity column that has the seed as @ID
SELECT  @SQL = 'ALTER TABLE #SDHaulier ADD SDHaulierID int IDENTITY(' + @ID + ' ,1)'
Exec (@SQL) 

INSERT INTO #SDHaulier
  SELECT	HaulierID,
			HaulierCode,
			ManualUpdateMax,
			LicenceNo,
			LicencedLorries,
			LicenceExpiry
  FROM #Hauliers

--Test  
--select * from #Hauliers
--select * from #PartyFunction
--select * from #PartyOrgScope
--select * from #SDHaulier

-- Insert Hauliers into Party table
INSERT INTO [wts_coillte].[wts_coillte].[PARTY]
  SELECT	pty.HaulierID,
			pty.CtrCode,
			pty.HaulierBase,
			NULL,
			NULL,
			NULL,
			NULL,
			pty.HaulierEmail,
			'AC',
			NULL,
			NULL,
			NULL,
			pty.HaulierName,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			pty.HaulierName,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			pty.HaulierCode,
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
	FROM	#Hauliers AS pty

 --Insert the Hauliers in to the PARTY_FUNCTIONS TABLE (fcn_code for Haulier = TR)
INSERT INTO [wts_coillte].[wts_coillte].[PARTY_FUNCTIONS]
  SELECT	ptf.PartyFunctionID,
			ptf.PartyID,
			ptf.FcnCode,
			NULL,
			NULL
	FROM	#PartyFunction AS ptf

-- Insert the Hauliers in to the PARTY_ORG_SCOPE
INSERT INTO [wts_coillte].[wts_coillte].[PARTY_ORG_SCOPE]
  SELECT	pos.PartyOrgScopeID,
			pos.PartyID,
			pos.OrgUnitID
  FROM #PartyOrgScope AS pos


-- Insert into SD_Haulier table
INSERT INTO [wts_coillte].[wts_coillte].[SD_HAULIER]
  SELECT	sdh.SDHaulierID,
			sdh.PartyID,
			sdh.HaulierCode,
			sdh.ManualUpdate,
			sdh.HaulageLicenseNo,
			sdh.NumOfLorries,
			sdh.ExpiryDate
    FROM #SDHaulier AS sdh

select * from #Hauliers
-- Update the next_seq table for Party, Party Function, Party Org Scope and SD_Haulier

UPDATE [wts_coillte].[NEXT_SEQ]
  SET NEXT_ID = (
					SELECT MAX (pty.HaulierID) + 1
					FROM #hauliers AS pty
				)
	WHERE KEYWORD = 'PARTY'

UPDATE [wts_coillte].[NEXT_SEQ]
  SET NEXT_ID = (
					SELECT MAX (ptf.PartyFunctionID) + 1
					FROM	#PartyFunction AS ptf
				)
	WHERE KEYWORD = 'PARTY_FUNCTIONS'

UPDATE [wts_coillte].[NEXT_SEQ]
  SET NEXT_ID = (
					SELECT MAX (pos.PartyOrgScopeID) + 1
					FROM #PartyOrgScope AS pos
				)
	WHERE KEYWORD = 'PARTY_ORG_SCOPE'

UPDATE [wts_coillte].[NEXT_SEQ]
  SET NEXT_ID = (
					SELECT MAX (hal.HaulierID) + 1
					FROM #SDHaulier AS hal
				)
	WHERE KEYWORD = 'SD_HAULIER'

--  drop temp tables
 DROP TABLE #Hauliers 
 DROP TABLE #PartyFunction
 DROP TABLE #PartyOrgScope
 DROP TABLE #SDHaulier


--  TEST
  --select * from [wts_coillte].[PARTY]
  --where PARTY_ID in (SELECT [PARTY_ID]
		--				FROM [wts_coillte].[wts_coillte].[PARTY_FUNCTIONS]
		--				WHERE FCN_CODE = 'TR'
		--			)

 