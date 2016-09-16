
/**********************************************************************/
/***  Migrate Internal Forest Contacts						    	***/
/***  Created by RB Jun 2016								    	***/
/***                                                                ***/
/***  Insert Forest Contact data in FOPSQL01.FIS FC01 view			***/
/***	Where the FC_TYPE = Coillte Environment Officer				***/
/***	into wts_coillte.Party table								***/
/***                                                                ***/
/***	Last modified												***/
/***                                                                ***/
/**********************************************************************/

USE [tfm]

-- Create a temp table for Internal Forest Contacts
CREATE TABLE #ForestContactsInternal (
								ForestOID		int,
								FCName			varchar(50),
								FC_HRID			int,
								ForestCode		varchar(4),
								FCContactID		int,
								FCRole			varchar(5)
							)

INSERT INTO #ForestContactsInternal (
									ForestOID, 
									FCName,
									FC_HRID,
									ForestCode,
									FCContactID,
									FCRole
									)
SELECT	fst.OBJECTID,
		fc.[FC_NAME],
		0,
		fc.[FOREST_CODE],
		fc.[FC_CONTACT_ID],
		'CENVO'
  FROM [FOPSQL01].[FIS].[dbo].[FC_01] AS fc
  INNER JOIN [TFM].[dbo].[TFM_CMN_FOREST] AS fst
  ON fc.[FOREST_CODE] collate SQL_Latin1_General_CP1_CI_AS = fst.[FOREST_CODE] collate SQL_Latin1_General_CP1_CI_AS
  WHERE FC_TYPE = 'Coillte Environment Officer'    -- Just the Coillte Environment Officer

UPDATE #ForestContactsInternal 
	SET FC_HRID =  fcint.[HR_ID]
	FROM #ForestContactsInternal AS fci
	INNER JOIN [FOPSQL01].[tfm].[dbo].[ForestContactsINTID] AS fcint
	ON fci.FCContactID = fcint.FC_CONTACT_ID 

-- Test  
-- Select * from #ForestContactsInternal

/*******************************************************************************************/
/*** Create Version First                                                                ***/
/*******************************************************************************************/

EXEC SDE.sde.create_version
'sde.DEFAULT', 'mvInsert_ForestEnvOfficer', 1, 1, 'multiversioned view insert - Forest Internal Contact'

EXEC SDE.SDE.set_current_version 'mvInsert_ForestEnvOfficer'

EXEC SDE.SDE.edit_version 'mvInsert_ForestEnvOfficer', 1

GO

BEGIN TRANSACTION

INSERT INTO [tfm].[dbo].[VMV_TFM_CMN_FOREST_CONTACTS]
	( 
	 [FOREST_OID]
    ,[FOREST_CONTACTS_NAME]
    ,[FOREST_CONTACTS_TYPE]
    ,[PARTY_ID]
    ,[HUMAN_RESOURCE_ID]
    ,[FOREST_CONTACTS_ROLE]
    ,[FOREST_CODE]
    ,[COMMENTS]
    ,[CREATEDBY]
    ,[CREATEDON]
    ,[CREATEDUSING]
    ,[MODIFIEDBY]
    ,[MODIFIEDON]
    ,[MODIFIEDUSING]
    ,[DOCUMENTKEY]
    ,[IMPORTERPK]
    ,[IMPORTERFK]
	,[RANKING]
	)
	SELECT
		ForestOID,
		FCName,
		'INT'	AS FCType,		-- Forest Contact Type is Internal
		NULL	AS PartyID,
		FC_HRID,
		'CENVO',				-- Hard coded for Coillte Environment Officer code
		ForestCode,
		'' AS Comments,
		'DATA MIGRATION' AS CreatedBy,
		CAST(GETDATE() AS datetime2) AS CreatedON,
		'DATA MIGRATION SCRIPT' AS CreatedUsing,
		'DATA MIGRATION' AS ModifiedBy,
		CAST(GETDATE() AS datetime2) AS ModifiedOn,
		'DATA MIGRATION SCRIPT' AS ModifiedUsing,
		NULL AS DocumentKey,
		NULL AS ImporterPK,
		NULL AS ImporterFK,
		NULL AS Ranking
	  FROM #ForestContactsInternal
	  WHERE FC_HRID <> 0				-- Do not bring in any contacts that are not in the Human Resource table

COMMIT



/*******************************************************************************************/
/*** Close Version  (Dont forget to also Reconcile and Post Version in ArcCatalog)       ***/
/*******************************************************************************************/

EXEC SDE.SDE.edit_version 'mvInsert_ForestEnvOfficer', 2

-- Drop temp tables
DROP TABLE #ForestContactsInternal


-- Test
--SELECT * FROM VMV_TFM_CMN_FOREST_CONTACTS
--  WHERE [FOREST_CONTACTS_ROLE] = 'CENVO'


