/**********************************************************************/
/***  Migrate Mill Locations								    	***/
/***  Created by RB Apr 2016								    	***/
/***                                                                ***/
/***  Insert imported mill locations data							***/
/***	in FOPSQL01.tfm.Mill_Locations								***/
/***  into mill_locations tables									***/
/**		TFM_OP_MILL_LOCATION										***/
/**		TFM_VT_OP_MILL_LOCATION										***/
/***                                                                ***/
/***	Last modified												***/
/***                                                                ***/
/**********************************************************************/

USE tfm

-- First create a temp table with transformed spatial data to hold the geometry value
CREATE TABLE #MillLocations (
	MillCode		varchar(50),
	CustomerCode	varchar(20),
	DestinationType	varchar(20),
	DestinationName	varchar(100),
	GeomValue		geometry,					--	geometry value
    GeomSTVal AS GeomValue.STAsText()			--	geometry string value for geometry value so that it is readable
	)

-- Insert Mill locations
INSERT INTO #MillLocations
  SELECT	[Code],
			[Customer Code],
			[Destination Type],
			[Company],
			geometry::Point([Easting], [Northing], 2157) AS SHAPE   -- transform Eastings, Northings to geometry point
	FROM [FOPSQL01].[tfm].[dbo].[Mill_Locations]

-- Migrate Mill locations even if they do not have a location currently
-- Set Point(0,0) or Point(2,2) values to NULL as these are not useful spatial points.
 UPDATE #MillLocations
  SET GeomValue = NULL
  WHERE GeomSTVal IN ('POINT (0 0)','POINT (2 2)')

-- Update any Mill Locations already in TFM_OP_MILL_LOCATION
UPDATE TFM_OP_MILL_LOCATION
 SET SHAPE = ml.GeomValue
 FROM TFM_OP_MILL_LOCATION AS tml
 INNER JOIN #MillLocations AS ml 
 ON tml.DESTINATION_CODE collate SQL_Latin1_General_CP1_CI_AS = ml.MillCode collate SQL_Latin1_General_CP1_CI_AS

-- Delete any Mill Locations that are already in the TFM_OP_MILL_LOCATION table
--DELETE FROM #MillLocations
--WHERE MillCode collate SQL_Latin1_General_CP1_CI_AS IN 
--    (SELECT DESTINATION_CODE
--     FROM TFM_OP_MILL_LOCATION
--    )
--Test  
select * from #MillLocations
Order BY MillCode

-- Part 1
--/*******************************************************************************************/
--/*** Create Version First - no longer needed as inserting in to the base table           ***/
--/*******************************************************************************************/
--EXEC SDE.sde.create_version 'sde.DEFAULT', 'mvinsert_mill_locations', 1, 1, 'multiversioned view insert version - ML'

--EXEC SDE.SDE.set_current_version 'mvinsert_mill_locations'

--EXEC SDE.SDE.edit_version 'mvinsert_mill_locations', 1

-- Insert any remaining mill locations
--INSERT INTO TFM_OP_MILL_LOCATION (
--	[COMPANY_OID],
--	[DESTINATION_CODE],
--	[CUSTOMER_CODE],
--	[CREATEDBY],
--	[CREATEDON] ,
--	[CREATEDUSING] ,
--	[MODIFIEDBY] ,
--	[MODIFIEDON],
--	[MODIFIEDUSING] ,
--	[COMMENTS] ,
--	[IMPORTERPK] ,
--	[IMPORTERFK] ,
--	[SHAPE] ,
--	[ISGISLOCKED] ,
--	[DESTINATION_TYPE] ,
--	[DESTINATION_NAME],
--	[ACTIVE_IND] 
--	)
--  SELECT	1							AS COMPANY_OID,
--			MillCode					AS DESTINATION_CODE,
--			CustomerCode				AS CUSTOMER_CODE,
--			'DATA MIGRATION'			AS CREATEDBY,
--			CAST(GETDATE() AS datetime2) AS CREATEDON,
--			'DATA MIGRATION SCRIPT'		AS CREATEDUSING,
--			NULL						AS MODIFIEDBY,
--			NULL						AS MODIFIEDON,
--			NULL						AS MODIFIEDUSING,
--			NULL						AS COMMENTS,
--			NULL						AS IMPORTERPK,
--			NULL						AS IMPORTERFK,
--			GeomValue					AS SHAPE,
--			'Y'							AS ISGISLOCKED,
--			DestinationType				AS DESTINATION_TYPE,
--			DestinationName				AS DESTINATION_NAME,
--			'Y'							AS ACTIVE_IND
--	FROM	#MillLocations
 
--/********************************************************************************************/
--/*** Close Version  (Dont forget to also Reconcile and Post Version in ArcCatalog)        ***/
--/********************************************************************************************/
-- 
--EXEC SDE.SDE.edit_version 'mvinsert_mill_locations', 2;

-- Insert mill location code and name into TFM_VT_OP_MILL_LOCATION for mills not already in this table
--INSERT INTO TFM_VT_OP_MILL_LOCATION
--  SELECT	DESTINATION_CODE,
--			DESTINATION_NAME,
--			'DATA MIGRATION',
--			CAST(GETDATE() AS datetime2),
--			'DATA MIGRATION SCRIPT',
--			1
--	FROM	TFM_OP_MILL_LOCATION AS Mill
--	WHERE	Mill.DESTINATION_CODE NOT IN ( 
--											SELECT MILL_LOCATION_CODE
--											FROM	TFM_VT_OP_MILL_LOCATION
--										 )
-- Drop temp tables
 DROP TABLE #MillLocations
											
-- Test to see that all destination codes are in the VT 
--SELECT DESTINATION_CODE 
--	FROM TFM_OP_MILL_LOCATION
--	WHERE DESTINATION_CODE NOT IN ( 
--									SELECT MILL_LOCATION_CODE
--									FROM	TFM_VT_OP_MILL_LOCATION
--									 )
-- Check that all mill codes are distinct
-- SELECT DISTINCT mill_location_code 
--	FROM TFM_VT_OP_MILL_LOCATION



-- test
--SELECT * FROM TFM_OP_MILL_LOCATION
--SELECT * FROM TFM_VT_OP_MILL_LOCATION
