/****************************************************************************************/
/* Migrate FIS Contracts to wts_coillte/TFM												*/
/*																						*/
/* FIS CONTRACT HEADS																	*/
/* FIS CONTRACT LINES																	*/
/*																						*/
/* Tables to update																		*/
/*																						*/
/* WTS_COILLTE.CONTRACTS						- Contract								*/
/* WTS_COILLTE.SD_CONTRACTS						- Contract Extension 					*/
/* WTS_COILLTE.SD_CCF_RCT_FORM					- Relevant Contract Tax Form			*/
/* WTS_COILLTE.SD_CCF_AWARD_APPROVAL			- Contract Approver						*/	
/* WTS_COILLTE.CONTRACT_ORG_SCOPE				- Contract Organisation Scope			*/
/* WTS_COILLTE.CONTRACTED_PARTY					- Contracted Party						*/
/* WTS_COILLTE.SD_TFM_ACTIVITY_CONTRACT_LINK											*/
/* WTS_COILLTE.SD_CONTRACT_ACTIVITY_LINE												*/
/* TFM.VMV_TFM_SILV_ACTIVITY															*/
/* WTS_COILLTE.SD_SIN							- Site Identification Number (SIN)      */
/* TFM.VMV_TFM_SILV_UNIT*																*/
/* WTS_COILLTE.SD_CONTRACT_BIDDING_SCHEDULE*											*/
/* WTS_COILLTE.SD_CONTRACT_REVIEW_STATUS_LOG*											*/
/*																						*/
/*	Entry Criteria																		*/
/*	Contract Status = A (Authorised), H (Hold), W (Work Recorded) or U (Unauthorised)	*/
/*	Analysis Code = ESTB (Establishment)												*/
/*	Expiry Date > Cutoff Date agreed with Finance										*/
/*	Contract Value - Contract Value Received > 0										*/		
/*																						*/
/*   *OPTIONAL																			*/
/*																						*/
/*																						*/
/*  RF July 2016											  							*/
/*																						*/
/*  Last modified				     													*/
/*																						*/
/*	Added Data Migration as Create User and Getdate() as Create Date					*/
/*	to SD_Contracts to be able to recognise which ones are added.						*/
/*	Added expiry date as entry criteria													*/
/*											RB 11-Jul-2016								*/
/*	Added filter for Tendered Establishment Contracts 'T/E1','T/E4','T/ES','T/GP'		*/
/*											RB 13-Jul-2016								*/
/*  Insert for WTS_COILLTE.CONTRACT_ORG_SCOPE											*/
/*											RB 15-Jul-2016								*/
/*  Divided Contract Value by 100 in SD_Contracts										*/
/*											RB 18-Jul-2016								*/
/*  Added filter for Maintenance Contracts 'T/MA'										*/
/*											RB 19-Jul-2016								*/
/*  Added filter for Roads Contracts 'ROAD'												*/
/*											RB 19-Jul-2016								*/
/*  Added filter for Haulage Contracts 'HAUL'											*/
/*											RB 19-Jul-2016								*/
/*  Added filter for Harvesting Contracts 'HARV'										*/
/*											RB 19-Jul-2016								*/
/*	Insert for SD_CCF_RCT_FORM															*/
/*											RB 21/07/2016								*/
/*	Modify Insert for SD_CCF_RCT_FORM												    */
/*											RF 04/08/2016								*/
/*	Insert for WTS_COILLTE.SD_SIN													    */
/*											RF 04/08/2016								*/
/*	Insert for WTS_COILLTE.SD_CCF_AWARD_APPROVAL									    */
/*											RF 10/08/2016								*/
/*																						*/
/*	Delete all migrated data in all contexts    									    */
/*											RF 17/08/2016								*/
/*																						*/
/*	To Do																				*/
/*			Contract Lines																*/
/****************************************************************************************/

USE wts_coillte
GO

-- Set up Temp Files with data drawn from FOPSQL01 FIS over Linked Server

IF OBJECT_ID('tempdb..#TEMP_CTRS') IS NOT NULL DROP TABLE #TEMP_CTRS
GO
IF OBJECT_ID('tempdb..#TEMP_CTR_INSURANCE_DETS') IS NOT NULL DROP TABLE #TEMP_CTR_INSURANCE_DETS
GO
IF OBJECT_ID('tempdb..#TEMP_CT_HEADS') IS NOT NULL DROP TABLE #TEMP_CT_HEADS
GO
IF OBJECT_ID('tempdb..#TEMP_CT_HEAD_AUDIT') IS NOT NULL DROP TABLE #TEMP_CT_HEAD_AUDIT
GO
IF OBJECT_ID('tempdb..#TEMP_CT_DATE_AUTHORIZED') IS NOT NULL DROP TABLE #TEMP_CT_DATE_AUTHORIZED
GO
IF OBJECT_ID('tempdb..#TEMP_CT_LINES') IS NOT NULL DROP TABLE #TEMP_CT_LINES
GO
IF OBJECT_ID('tempdb..#TEMP_CTR_ADDRESSES') IS NOT NULL DROP TABLE #TEMP_CTR_ADDRESSES
GO
IF OBJECT_ID('tempdb..#TEMP_CT_USERS') IS NOT NULL DROP TABLE #TEMP_CT_USERS
GO
IF OBJECT_ID('tempdb..#TEMP_HAUL_DESTS') IS NOT NULL DROP TABLE #TEMP_HAUL_DESTS
GO
IF OBJECT_ID('tempdb..#TEMP_SUB_OPERATIONS') IS NOT NULL DROP TABLE #TEMP_SUB_OPERATIONS
GO
IF OBJECT_ID('tempdb..#TEMP_OPERATIONS') IS NOT NULL DROP TABLE #TEMP_OPERATIONS
GO
IF OBJECT_ID('tempdb..#TEMP_AGRESSO_MRCTCONTRACT') IS NOT NULL DROP TABLE #TEMP_AGRESSO_MRCTCONTRACT
GO
IF OBJECT_ID('tempdb..#TEMP_APPROVER') IS NOT NULL DROP TABLE #TEMP_APPROVER
GO
IF OBJECT_ID('tempdb..#TEMP_GRN_HEADS') IS NOT NULL DROP TABLE #TEMP_GRN_HEADS
GO
IF OBJECT_ID('tempdb..#TEMP_GRN_LINES') IS NOT NULL DROP TABLE #TEMP_GRN_LINES
GO
IF OBJECT_ID('tempdb..#TEMP_IPC_PLAN_ENTITIES') IS NOT NULL DROP TABLE #TEMP_IPC_PLAN_ENTITIES
GO
IF OBJECT_ID('tempdb..#TEMP_FORESTS') IS NOT NULL DROP TABLE #TEMP_FORESTS
GO
IF OBJECT_ID('tempdb..#TEMP_CT_LINE_FOREST') IS NOT NULL DROP TABLE #TEMP_CT_LINE_FOREST
GO

-- FIS CTRS Temp Table
SELECT *
INTO #TEMP_CTRS
FROM
OPENQUERY([FOPSQL01],'SELECT * FROM [FIS].[dbo].[CTRS]') 
GO
-- FIS CTR_INSURANCE_DETS Temp Table
SELECT *
INTO #TEMP_CTR_INSURANCE_DETS
FROM
OPENQUERY([FOPSQL01],'SELECT * FROM [FIS].[dbo].[CTR_INSURANCE_DETS]') 
GO
-- FIS CT_HEADS Temp Table
SELECT *
INTO #TEMP_CT_HEADS
FROM
OPENQUERY([FOPSQL01],'SELECT * FROM [FIS].[dbo].[CT_HEADS]') 
GO
-- FIS CT_HEAD_AUDIT Temp Table
SELECT *
INTO #TEMP_CT_HEAD_AUDIT
FROM
OPENQUERY([FOPSQL01],'SELECT * FROM [FIS].[dbo].[CT_HEAD_AUDIT]') 
GO
-- FIS #TEMP_CT_DATE_AUTHORIZED Temp Table
SELECT CT_NO, MAX(DATE_MODIFIED) AS DATE_AUTHORIZED 
INTO #TEMP_CT_DATE_AUTHORIZED
FROM #TEMP_CT_HEAD_AUDIT WHERE CT_AUTHORIZER = USER_MODIFIED AND LEN(CT_AUTHORIZER) > 1 
GROUP BY CT_NO
ORDER BY CT_NO
-- FIS CT_LINES Temp Table
SELECT *, (CT_QTY/1000) * (CT_PRICE/10000) AS CT_LINE_VALUE, ROW_NUMBER() OVER(PARTITION BY CT_NO ORDER BY CT_LINE_NO) AS NEW_CT_LINE_NO
INTO #TEMP_CT_LINES
FROM
OPENQUERY([FOPSQL01],'SELECT * FROM [FIS].[dbo].[CT_LINES]') 
GO
-- FIS CTR_ADDRESSES Temp Table
SELECT *
INTO #TEMP_CTR_ADDRESSES
FROM
OPENQUERY([FOPSQL01],'SELECT * FROM [FIS].[dbo].[CTR_ADDRESSES]') 
GO
-- FIS CT_USERS Temp Table
SELECT *
INTO #TEMP_CT_USERS
FROM
OPENQUERY([FOPSQL01],'SELECT * FROM [FIS].[dbo].[CT_USERS]') 
GO
-- FIS HAUL_DESTS Temp Table
SELECT *
INTO #TEMP_HAUL_DESTS
FROM
OPENQUERY([FOPSQL01],'SELECT * FROM [FIS].[dbo].[HAUL_DESTS]') 
GO
-- FIS SUB_OPERATIONS Temp Table
SELECT *
INTO #TEMP_SUB_OPERATIONS
FROM
OPENQUERY([FOPSQL01],'SELECT * FROM [FIS].[dbo].[SUB_OPERATIONS]') 
GO
-- FIS OPERATIONS Temp Table
SELECT *
INTO #TEMP_OPERATIONS
FROM
OPENQUERY([FOPSQL01],'SELECT * FROM [FIS].[dbo].[OPERATIONS]') 
GO
-- FIS AGRESSO_MRCTCONTRACT Temp Table
SELECT *
INTO #TEMP_AGRESSO_MRCTCONTRACT
FROM
OPENQUERY([FOPSQL01],'SELECT * FROM [FIS].[dbo].[AGRESSO_MRCTCONTRACT]') 
GO
-- FIS GRN_HEADS Temp Table
SELECT *
INTO #TEMP_GRN_HEADS
FROM
OPENQUERY([FOPSQL01],'SELECT * FROM [FIS].[dbo].[GRN_HEADS]') 
GO
-- FIS GRN_LINES Temp Table
SELECT *
INTO #TEMP_GRN_LINES
FROM
OPENQUERY([FOPSQL01],'SELECT * FROM [FIS].[dbo].[GRN_LINES]') 
GO
-- FIS IPC_PLAN_ENTITIES Temp Table
SELECT *
INTO #TEMP_IPC_PLAN_ENTITIES
FROM
OPENQUERY([FOPSQL01],'SELECT * FROM [FIS].[dbo].[IPC_PLAN_ENTITIES]') 
GO
-- FIS FORESTS Temp Table
SELECT *
INTO #TEMP_FORESTS
FROM
OPENQUERY([FOPSQL01],'SELECT * FROM [FIS].[dbo].[FORESTS]') 
GO

-- Approver Temp Table
CREATE TABLE #TEMP_APPROVER
  ( 
ORG_UNIT_ID	numeric(10,0),
DISPLAY_NAME VARCHAR(50),	
FIRST_NAME VARCHAR(20),
LAST_NAME VARCHAR(20),	
USERNAME VARCHAR(20)
  ) 

INSERT INTO #TEMP_APPROVER
(ORG_UNIT_ID,DISPLAY_NAME,FIRST_NAME,LAST_NAME,USERNAME)
VALUES
(100,	'GERARD BRITCHFIELD',	'GERARD',	'BRITCHFIELD',	'BRITCHFLD_G'),
(8,	'BERNARD BURKE',	'BERNARD',	'BURKE',	'BURKE_BJ'),
(100,	'MARK CARLIN',	'MARK',	'CARLIN',	'CARLIN_M'),
(7,	'PAT CARROLL',	'PAT',	'CARROLL',	'CARROLL_P'),
(3,	'NOEL CASSIDY',	'NOEL',	'CASSIDY',	'CASSIDY_N'),
(2,	'TONY CLARKE',	'TONY',	'CLARKE',	'CLARKE_T'),
(100,	'SEAMUS CORRY',	'SEAMUS',	'CORRY',	'CORRY_S'),
(100,	'FINDAN COX',	'FINDAN',	'COX',	'COX_F'),
(1,	'JIM CROWLEY',	'JIM',	'CROWLEY',	'CROWLEY_J'),
(5,	'CONOR DEVANE',	'CONOR',	'DEVANE',	'DEVANE_C'),
(100,	'DAVID FEENEY',	'DAVID',	'FEENEY',	'FEENEY_D'),
(4,	'GERRY GAVIN',	'GERRY',	'GAVIN',	'GAVIN_G'),
(100,	'EAMONN KEELY',	'EAMONN',	'KEELY',	'KEELY_E'),
(100,	'FERGAL LEAMY',	'FERGAL',	'LEAMY',	'LEAMY_F'),
(5,	'PETER MCGLOIN',	'PETER',	'MCGLOIN',	'MCGLOIN_P'),
(100,	'GERRY MURPHY',	'GERRY',	'MURPHY',	'MURPHY_G'),
(100,	'GERARD MURPHY',	'GERARD',	'MURPHY',	'MURPHY_GP'),
(1,	'JOHN O''CONNOR',	'JOHN',	'O''CONNOR',	'OCONNOR_JG'),
(1,	'JIM O''NEILL',	'JIM',	'O''NEILL',	'ONEILL_J'),
(100,	'JOHN O''SULLIVAN',	'JOHN',	'O''SULLIVAN',	'OSULLIVAN_J'),
(6,	'MICHAEL POWER',	'MICHAEL',	'POWER',	'POWER_M'),
(100,	'GERRY RIORDAN',	'GERRY',	'RIORDAN',	'RIORDAN_G'),
(1,	'PAT ROCHE',	'PAT',	'ROCHE',	'ROCHE_P'),
(4,	'PAUL RUANE',	'PAUL',	'RUANE',	'RUANE_PF'),
(100,	'NICK RYAN',	'NICK',	'RYAN',	'RYAN_N'),
(100,	'PJ TRAIT',	'PJ',	'TRAIT'	,'TRAIT_PJ'),
(8,	'IZABELLA WITKOWSKA',	'IZABELLA',	'WITKOWSKA', 'WITKOWSKA_I'),
(3,	'PATRICK BRADY',	'PATRICK',	'BRADY',	'BRADY_P'),
(3,	'COLM BROPHY',	'COLM',	'BROPHY',	'BROPHY_C'),
(3,	'GER BUCKLEY',	'GER',	'BUCKLEY',	'BUCKLEY_G'),
(6,	'RICKY BYRNE',	'RICKY',	'BYRNE',	'BYRNE_RI'),
(100,	'JOHN CONNOLLY',	'JOHN',	'CONNOLLY',	'CONNOLLY_J'),
(4,	'MICHAEL DONNELLAN',	'MICHAEL',	'DONNELLAN',	'DONNELLAN_M'),
(2,	'JOSEPH FINN',	'JOSEPH',	'FINN',	'FINN_J'),
(2,	'FRANK FLANAGAN',	'FRANK',	'FLANAGAN',	'FLANAGAN_F'),
(7,	'JOHN GALVIN',	'JOHN',	'GALVIN',	'GALVIN_J'),
(3,	'RICHARD JACK',	'RICHARD',	'JACK',	'JACK_R'),
(7,	'PIOTR JONCA',	'PIOTR',	'JONCA',	'JONCA_P'),
(2,	'MICHAEL KILCULLEN',	'MICHAEL',	'KILCULLEN',	'KILCULLEN_M'),
(4,	'PATRICK LYONS', 'PATRICK',	'LYONS',	'LYONS_P'),
(1,	'BRIAN MCGARRAGHY',	'BRIAN',	'MCGARRAGHY',	'MCGARRAGHY_B'),
(1,	'KIERAN MOLONEY',	'KIERAN',	'MOLONEY',	'MOLONEY_K'),
(6,	'JOHN MOORE',	'JOHN',	'MOORE',	'MOORE_JG'),
(7,	'PAT MUNGOVAN',	'PAT',	'MUNGOVAN',	'MUNGOVAN_P'),
(7,	'M J O''HALLORAN',	'M J',	'O''HALLORAN',	'OHALLORAN_J'),
(4,	'MARK O''LOUGHLIN',	'MARK',	'O''LOUGHLIN',	'OLOUGHLIN_M'),
(8,	'WILLIAM O''REGAN',	'WILLIAM',	'O''REGAN',	'OREGAN_W'),
(7,	'TOM QUINN',	'TOM',	'QUINN',	'QUINN_TO'),
(5,	'LUKE SWEETMAN',	'LUKE',	'SWEETMAN',	'SWEETMAN_L'),
(5,	'AIDAN WALSH',	'AIDAN',	'WALSH',	'WALSH_A'),
(5,	'MARTIN WHELAN',	'MARTIN',	'WHELAN',	'WHELAN_M')

-- CT_LINE_FOREST Temp Table
SELECT 
      cth.CT_NO,
	  ctl.CT_LINE_NO, 

         (CASE 
          WHEN CTL.WR_LOC_TYPE IN ('D','M')
           AND CTL.WR_LOCATION != ' '
              AND (SELECT E.COST_CENTRE 
                        FROM #TEMP_IPC_PLAN_ENTITIES E 
                       WHERE CTL.WR_LOCATION = E.ENTITY_ID
                     ) IS NOT NULL
          THEN -- Use the entity on the contract line
               (SELECT E.COST_CENTRE 
                        FROM #TEMP_IPC_PLAN_ENTITIES E 
                       WHERE CTL.WR_LOCATION = E.ENTITY_ID
                     )
          WHEN CTL.WR_LOC_TYPE IN ('F','P')
           AND CTL.WR_LOCATION != ' '
              AND (SELECT E.COST_CENTRE 
                        FROM #TEMP_IPC_PLAN_ENTITIES E 
                       INNER JOIN #TEMP_FORESTS F ON E.COST_CENTRE = F.FOREST_CODE AND F.REALLY_A_FOREST = 'Y'
                       WHERE CTL.WR_LOCATION = E.ENTITY_ID
                     ) IS NOT NULL
          THEN -- Use the entity on the contract line
               (SELECT E.COST_CENTRE 
                        FROM #TEMP_IPC_PLAN_ENTITIES E 
                       INNER JOIN #TEMP_FORESTS F ON E.COST_CENTRE = F.FOREST_CODE AND F.REALLY_A_FOREST = 'Y'
                       WHERE CTL.WR_LOCATION = E.ENTITY_ID
                     )
          WHEN -- lookup and CWRs using the contract number and line number
               (SELECT MAX(E.COST_CENTRE) 
                        FROM #TEMP_GRN_LINES CWRL 
                       INNER JOIN #TEMP_IPC_PLAN_ENTITIES E ON CWRL.WR_LOCATION = E.ENTITY_ID
                       INNER JOIN #TEMP_FORESTS F ON E.COST_CENTRE = F.FOREST_CODE AND F.REALLY_A_FOREST = 'Y'
                       WHERE CTL.CT_NO      = CWRL.CT_NO 
                         AND CTL.CT_LINE_NO = CWRL.CT_LINE_NO
                     ) IS NOT NULL
          THEN
               (SELECT MAX(E.COST_CENTRE) 
                        FROM #TEMP_GRN_LINES CWRL 
                       INNER JOIN #TEMP_IPC_PLAN_ENTITIES E ON CWRL.WR_LOCATION = E.ENTITY_ID
                       INNER JOIN #TEMP_FORESTS F ON E.COST_CENTRE = F.FOREST_CODE AND F.REALLY_A_FOREST = 'Y'
                       WHERE CTL.CT_NO      = CWRL.CT_NO 
                         AND CTL.CT_LINE_NO = CWRL.CT_LINE_NO
                     )
          WHEN -- lookup and CWRs using the contract number only
               (SELECT MAX(E.COST_CENTRE) 
                        FROM #TEMP_GRN_LINES CWRL 
                       INNER JOIN #TEMP_IPC_PLAN_ENTITIES E ON CWRL.WR_LOCATION = E.ENTITY_ID
                       INNER JOIN #TEMP_FORESTS F ON E.COST_CENTRE = F.FOREST_CODE AND F.REALLY_A_FOREST = 'Y'
                       WHERE CTL.CT_NO      = CWRL.CT_NO 
                      ) IS NOT NULL
          THEN
               (SELECT MAX(E.COST_CENTRE) 
                        FROM #TEMP_GRN_LINES CWRL 
                       INNER JOIN #TEMP_IPC_PLAN_ENTITIES E ON CWRL.WR_LOCATION = E.ENTITY_ID
                       INNER JOIN #TEMP_FORESTS F ON E.COST_CENTRE = F.FOREST_CODE AND F.REALLY_A_FOREST = 'Y'
                       WHERE CTL.CT_NO      = CWRL.CT_NO 
                      )
          ELSE  (Case ct_manager
              When 'BRADY_P'      Then 'CN02'
              When 'BROPHY_C'     Then 'CN04'
              When 'BUCKLEY_G'    Then 'LS06'
              When 'BUCKLEY_G'    Then 'LS06'
              When 'BYRNE_RI'     Then 'KK06'
			  When 'CONNOLLY_J'   Then 'WH04'
              When 'DONNELLAN_M'  Then 'GY18'
              When 'FINN_J'       Then 'MO25'
              When 'FLANAGAN_F'   Then 'GY25'
              When 'GALVIN_J'     Then 'CK13'
              When 'JACK_R'       Then 'LS01'
              When 'JONCA_P'      Then 'TY17'
              When 'KILCULLEN_M'  Then 'MO08'
              When 'LYONS_P'      Then 'CE03'
              When 'MCGARRAGHY_B' Then 'LM03'
              When 'MCGLOIN_P'    Then 'CW01'
              When 'MOLONEY_K'    Then 'DL24'
              When 'MOORE_JG'     Then 'LK03'
              When 'MUNGOVAN_P'   Then 'CK01'
              When 'OHALLORAN_J'  Then 'WD08'
              When 'OLOUGHLIN_M'  Then 'CE02'
              When 'OREGAN_W'     Then 'CK19'
              When 'QUINN_TO'     Then 'CN06'
              When 'SWEETMAN_L'   Then 'WW09'
              When 'WALSH_A'      Then 'WW07'
              When 'WHELAN_M'     Then 'WX02'
              When 'WITKOWSKA_I'  Then 'KY03'
                       End)
          END) AS DERIVED_FOREST_CODE

	INTO #TEMP_CT_LINE_FOREST

   FROM 
      #TEMP_CT_HEADS  AS cth 
         LEFT OUTER JOIN #TEMP_CT_LINES  AS ctl 
         ON ctl.CT_NO = cth.CT_NO 
         LEFT OUTER JOIN #TEMP_CTRS  AS ctr 
         ON ctr.CTR_CODE = cth.CTR_CODE 
         LEFT OUTER JOIN #TEMP_CTR_ADDRESSES  AS cta 
         ON cta.CTR_CODE = ctr.CTR_CODE 
         LEFT OUTER JOIN #TEMP_CT_USERS  AS auth 
         ON auth.USERNAME = cth.CT_AUTHORIZER
   -- CONTRACT CRITERIA
   WHERE cth.CT_STATUS IN ('A', 'H', 'W')
       AND cth.CT_ANAL_CODE = 'ESTB'                                                     -- Use for Establishment Contracts
--     AND cth.CT_ANAL_CODE IN ('T/E1','T/E4','T/ES','T/GP')         -- Use for Tendered Establishment Contracts
--     AND cth.CT_ANAL_CODE = 'T/MA'                                                     -- Use for Tendered Maintenance Contracts
--     AND cth.CT_ANAL_CODE = 'ROAD'                                                     -- Use for Road Contracts
--     AND cth.CT_ANAL_CODE = 'HAUL'                                                     -- Use for Haulage Contracts
--     AND cth.CT_ANAL_CODE = 'HARV'                                                     -- Use for Harvesting Contracts
       AND cth.CT_PLAN_END >  '2016-08-15'                                               -- Cutoff Date to be agreed with Finance for expiry of contracts in FIS
ORDER BY cth.CT_NO, ctl.CT_LINE_NO
GO

SELECT * FROM #TEMP_CT_LINE_FOREST




SELECT * FROM #TEMP_CT_LINES

------------------------
-- Declaration Section
------------------------

DECLARE @NEXT_ID	numeric(10,0)


--------------------------------------------------------------------------------------------------------------------------------------
-- CONTRACTS
--------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- WTS_COILLTE.SD_SIN 
--
-- Do the Site Identification Number table first. Populate with all types 
-- of legacy contracts in scope
-------------------------------------------------------------------------------

DECLARE @NEXT_ID	numeric(10,0)

SELECT @NEXT_ID = NEXT_ID          
FROM [wts_coillte].[NEXT_SEQ]         
WHERE KEYWORD = 'SD_SIN'

INSERT INTO WTS_COILLTE.SD_SIN		(
										SIN_ID,
										SIN,
										ORG_UNIT_ID,
										COUNTY
									 )

-------------------------------------------------------------------------
---  Test this SELECT statement before running the INSERT            ----
-------------------------------------------------------------------------

SELECT

MAX(SIN_ID) AS SIN_ID,
MAX(SIN_NUMBER) AS SIN_NUMBER,
100 AS ORG_UNIT_ID,
MAX(COUNTY) AS COUNTY

FROM

(
SELECT
ISNULL((@NEXT_ID - 1),1) + ROW_NUMBER() OVER(ORDER BY AG_MRCT.CONTRACT_ID) AS SIN_ID,
AG_MRCT.SIN_NUMBER, 
AG_MRCT.SITE_COUNTY AS COUNTY
  FROM #TEMP_CT_HEADS  AS cth
	JOIN #TEMP_AGRESSO_MRCTCONTRACT AS AG_MRCT
	ON cth.CT_NO = AG_MRCT.CONTRACT_ID
	WHERE LEN(AG_MRCT.SIN_NUMBER) > 1 
	AND cth.CT_STATUS IN ('A', 'H', 'W')
	AND cth.CT_PLAN_END >  '2016-08-15'							-- Cutoff Date to be agreed with Finance for expiry of contracts in FIS
) A

GROUP BY A.SIN_NUMBER

GO

-----------------------------
-- Update sequence numbers --
-----------------------------
UPDATE [wts_coillte].[NEXT_SEQ]
SET NEXT_ID = (
				SELECT MAX (SIN_ID) + 1
				FROM WTS_COILLTE.SD_SIN
			  )
WHERE KEYWORD = 'SD_SIN'

SELECT * FROM WTS_COILLTE.SD_SIN

--SELECT COUNT (*), SIN FROM WTS_COILLTE.SD_SIN GROUP BY SIN  --** Check for duplicates


-------------------------------------------------------------------------------
-- WTS_COILLTE.CONTRACTS 
-------------------------------------------------------------------------------
----------------------------------------------------

-- Begin Insert into CONTRACTS table

-- Get the Next ID to use for CONTRACTS
DECLARE @NEXT_ID	numeric(10,0)

SELECT @NEXT_ID = NEXT_ID          
FROM [wts_coillte].[NEXT_SEQ]         
WHERE KEYWORD = 'CONTRACTS'


INSERT INTO WTS_COILLTE.CONTRACTS
(
CONTRACT_ID,
CONTRACT_NUM,
CONTRACT_TYPE_CODE,
CREATE_DATE,
EXPIRY_DATE,
CONTRACT_STATUS_CODE,
CONTRACT_NOTES,
START_DATE_DESC,
CONTRACT_MANAGER_ID,
MAIN_PARTY_ID,
failed_condition,
contract_template,
user_name,
deleted
)
SELECT
(@NEXT_ID - 1) + ROW_NUMBER() OVER(ORDER BY cth.CT_NO) AS CONTRACT_ID,
--'L' + RIGHT(YEAR(cth.CT_DATE),2) + REPLICATE('0',5-LEN(ROW_NUMBER() OVER(ORDER BY cth.CT_NO))) + RTRIM(ROW_NUMBER() OVER(ORDER BY cth.CT_NO)) AS CONTRACT_NUM,
CAST(cth.CT_NO AS VARCHAR) AS CONTRACT_NUM,
'SILV' AS CONTRACT_TYPE_CODE,
cth.CT_DATE AS CREATE_DATE,
cth.CT_PLAN_END AS EXPIRY_DATE,
--CASE cth.CT_STATUS 
--WHEN 'H' THEN 'HOLD' 
--WHEN 'U' THEN 'DRFT'
--WHEN 'W' THEN 'AC'
--ELSE 'AC' END AS CONTRACT_STATUS_CODE,
'AC' AS CONTRACT_STATUS_CODE,
cth.COMMENTS AS CONTRACT_NOTES,
CAST(DATEPART(YEAR, cth.CT_DATE) AS VARCHAR) AS START_DATE_DESC,
1034 AS CONTRACT_MANAGER_ID,   -- Seamus Corry
(SELECT TOP 1 PARTY_ID FROM WTS_COILLTE.PARTY PTY 
	WHERE PTY.CORPORATE_PARTY_NUMBER = cth.CTR_CODE COLLATE SQL_Latin1_General_CP1_CI_AS) AS MAIN_PARTY_ID,
'No' AS failed_condition,
'No' AS contract_template,
'DATA_MIGRATION' AS user_name,
'No' AS deleted
FROM #TEMP_CT_HEADS  AS cth
   -- CONTRACT CRITERIA
   WHERE cth.CT_STATUS IN ('A', 'H', 'W')
	AND cth.CT_ANAL_CODE = 'ESTB'								-- Use for Establishment Contracts
--	AND cth.CT_ANAL_CODE IN ('T/E1','T/E4','T/ES','T/GP')		-- Use for Tendered Establishment Contracts
--	AND cth.CT_ANAL_CODE = 'T/MA'								-- Use for Tendered Maintenance Contracts
--	AND cth.CT_ANAL_CODE = 'ROAD'								-- Use for Road Contracts
--	AND cth.CT_ANAL_CODE = 'HAUL'								-- Use for Haulage Contracts
--	AND cth.CT_ANAL_CODE = 'HARV'								-- Use for Harvesting Contracts
	AND cth.CT_PLAN_END >  '2016-08-15'							-- Cutoff Date to be agreed with Finance for expiry of contracts in FIS

GO
-----------------------------
-- Update sequence numbers --
-----------------------------

UPDATE [wts_coillte].[NEXT_SEQ]
SET NEXT_ID = (
				SELECT MAX (CONTRACT_ID) + 1
				FROM [wts_coillte].[wts_coillte].[CONTRACTS]
			  )
WHERE KEYWORD = 'CONTRACTS'

SELECT * FROM WTS_COILLTE.CONTRACTS
------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- WTS_COILLTE.SD_CONTRACTS 
-------------------------------------------------------------------------------

INSERT INTO WTS_COILLTE.SD_CONTRACTS 
(
CONTRACT_ID,
PROCUREMENT_PACKAGE_ID,
RESOURCE_TYPE_ID,
WORK_PACKAGE_TYPE,
TAX_TYPE,
INSURANCE_TYPE,
--AWARD_DATE,
CONTRACT_VALUE,
TAX_VALUE,
VALUE_RECEIPTED,   -- CWR total value
ROS_NUMBER,
ROS_EXPIRY,
CONTRACT_STATUS_CODE,
--COMPLETION_DATE,
CONTRACT_LINE_VALUE,  -- total of contract value
PROACTIS_CONTRACT_ID,
--CONTRACT_STATUS_UPDATE,
CREATE_USER,
CREATE_DATE,
MODIFY_USER,
MODIFY_DATE
--START_DATE_UPDATE,
--END_DATE_UPDATE
)
SELECT
(SELECT CONTRACT_ID FROM WTS_COILLTE.CONTRACTS CTRS 
  WHERE CTRS.CONTRACT_NUM = cth.CT_NO COLLATE SQL_Latin1_General_CP1_CI_AS) AS CONTRACT_ID,
NULL AS PROCUREMENT_PACKAGE_ID,
2 AS RESOURCE_TYPE_ID, -- contractor
'STC' AS WORK_PACKAGE_TYPE, -- from SD_D_TENDER_TYPE
'Relevant Contract Tax' AS TAX_TYPE,
CASE cth.CT_INS_TYPE
WHEN 'A' THEN 'CI'
WHEN 'S' THEN 'CONT'
WHEN 'N' THEN 'NR'
ELSE NULL END AS INSURANCE_TYPE, 
--AS AWARD_DATE,
cth.CT_VALUE / 100 AS CONTRACT_VALUE,
cth.CT_VAT_VALUE / 100 AS TAX_VALUE,
cth.CT_VALUE_RECEIVED / 100 AS VALUE_RECEIPTED,
AG_MRCT.RCT_CONTRACT AS ROS_NUMBER,
AG_MRCT.DATE_END AS ROS_EXPIRY,
--CASE cth.CT_STATUS 
--WHEN 'H' THEN 'HOLD' 
--WHEN 'U' THEN 'DRFT'
--WHEN 'W' THEN 'ACC'
--ELSE 'AC' END AS CONTRACT_STATUS_CODE,
'AC' AS CONTRACT_STATUS_CODE,
--AS COMPLETION_DATE,
(SELECT SUM(CT_LINE_VALUE) FROM #TEMP_CT_LINES CTL
 WHERE CTL.CT_NO = CTH.CT_NO) AS CONTRACT_LINE_VALUE,
cth.PROACTIS_CONTRACT_CODE AS PROACTIS_CONTRACT_ID,
--AS CONTRACT_STATUS_UPDATE,
'DATA_MIGRATION' AS CREATE_USER,
CAST(GETDATE() AS datetime2) AS CREATE_DATE,
'DATA_MIGRATION' AS MODIFY_USER,
CAST(GETDATE() AS datetime2) AS MODIFY_DATE
--AS START_DATE_UPDATE,
--AS END_DATE_UPDATE

 FROM #TEMP_CT_HEADS  AS cth
	LEFT JOIN #TEMP_AGRESSO_MRCTCONTRACT AS AG_MRCT
	ON cth.CT_NO = AG_MRCT.CONTRACT_ID
   -- CONTRACT CRITERIA
   WHERE cth.CT_STATUS IN ('A', 'H', 'W')
	AND cth.CT_ANAL_CODE = 'ESTB'								-- Use for Establishment Contracts
--	AND cth.CT_ANAL_CODE IN ('T/E1','T/E4','T/ES','T/GP')		-- Use for Tendered Establishment Contracts
--	AND cth.CT_ANAL_CODE = 'T/MA'								-- Use for Tendered Maintenance Contracts
--	AND cth.CT_ANAL_CODE = 'ROAD'								-- Use for Road Contracts
--	AND cth.CT_ANAL_CODE = 'HAUL'								-- Use for Haulage Contracts
--	AND cth.CT_ANAL_CODE = 'HARV'								-- Use for Harvesting Contracts
	AND cth.CT_PLAN_END >  '2016-08-15'							-- Cutoff Date to be agreed with Finance for expiry of contracts in FIS

SELECT * FROM WTS_COILLTE.SD_CONTRACTS 


-----------------------------------------------------------------------------



-------------------------------------------------------------------------------
-- WTS_COILLTE.SD_CCF_RCT_FORM    
-------------------------------------------------------------------------------

-- *Must have run WTS_COILLTE.SD_SIN above first
DECLARE @NEXT_ID	numeric(10,0)

SELECT @NEXT_ID = NEXT_ID          
FROM [wts_coillte].[NEXT_SEQ]         
WHERE KEYWORD = 'SD_CCF_RCT_FORM'

INSERT INTO WTS_COILLTE.SD_CCF_RCT_FORM (
	[SD_CCF_RCT_FORM_ID],							-- [numeric](10, 0) NOT NULL,
	[CONTRACT_ID],									-- [numeric](10, 0) NOT NULL,
	[DECLARATION],									-- [numeric](1, 0) NULL,
	[RCT_SECTOR],									-- [varchar](5) NULL,
	[SUB_NOT_LABOUR_ONLY],							-- [numeric](1, 0) NULL,
	[SUB_MATERIALS],								-- [numeric](1, 0) NULL,
	[SUB_MACHINERY],								-- [numeric](1, 0) NULL,
	[SUB_HAS_OTHERS],								-- [numeric](1, 0) NULL,
	[SUB_CONTRACT_PYMT],							-- [numeric](1, 0) NULL,
	[SUB_PENSION_EX],								-- [numeric](1, 0) NULL,
	[SUB_OWN_TRANSPORT],							-- [numeric](1, 0) NULL,
	[SUB_AGREES_COST],								-- [numeric](1, 0) NULL,
	[SUB_OWN_INSURANCE],							-- [numeric](1, 0) NULL,
	[SUB_CHOOSE_METHOD],							-- [numeric](1, 0) NULL,
	[SUB_OWN_ACCOUNT],								-- [numeric](1, 0) NULL,
	[SUB_RISK_EXPOSED],								-- [numeric](1, 0) NULL,
	[SIN],											-- [numeric](10, 0) NULL
	[ADDRESS_LINE_1],								-- [varchar](250) NULL
	[ADDRESS_LINE_2],								-- [varchar](250) NULL
	[ADDRESS_LINE_3],								-- [varchar](250) NULL
	[COUNTY],										-- [varchar](5) NULL
	[EIRCODE]										-- [varchar](10) NULL
									)
SELECT
(@NEXT_ID - 1) + ROW_NUMBER() OVER(ORDER BY cth.CT_NO) AS SD_CCF_RCT_FORM_ID,
(SELECT CONTRACT_ID FROM WTS_COILLTE.CONTRACTS CTRS 
  WHERE CTRS.CONTRACT_NUM = cth.CT_NO COLLATE SQL_Latin1_General_CP1_CI_AS) AS CONTRACT_ID,
1 AS DECLARATION,
AG_MRCT.RCT_SECTOR AS RCT_SECTOR,
AG_MRCT.SUB_NOT_LABOUR_ONLY AS SUB_NOT_LABOUR_ONLY,
AG_MRCT.SUB_MATERIALS AS SUB_MATERIALS,
1 AS SUB_MACHINERY,
AG_MRCT.SUB_HAS_OTHERS AS SUB_HAS_OTHERS,
AG_MRCT.SUB_CONTRACT_PYMT AS SUB_CONTRACT_PYMT,
AG_MRCT.SUB_PENSION_EX AS SUB_PENSION_EX,
AG_MRCT.SUB_OWN_TRANSPORT AS SUB_OWN_TRANSPORT,
AG_MRCT.SUB_AGREES_COST AS SUB_AGREES_COST,
AG_MRCT.SUB_OWN_INSURANCE AS SUB_OWN_INSURANCE,
AG_MRCT.SUB_CHOOSE_METHOD AS SUB_CHOOSE_METHOD,
AG_MRCT.SUB_OWN_ACCOUNT AS SUB_OWN_ACCOUNT,
AG_MRCT.SUB_RISK_EXPOSED AS SUB_RISK_EXPOSED,
(SELECT SIN_ID FROM WTS_COILLTE.SD_SIN SD_SIN
	WHERE SD_SIN.SIN = AG_MRCT.SIN_NUMBER COLLATE SQL_Latin1_General_CP1_CI_AS) AS SIN,
AG_MRCT.SITE_ADDR1 AS ADDRESS_LINE_1,		-- Address 1
AG_MRCT.SITE_ADDR2 AS ADDRESS_LINE_2,		-- Address 2
AG_MRCT.SITE_ADDR3 AS ADDRESS_LINE_3,		-- Address 3
AG_MRCT.SITE_COUNTY AS COUNTY,		-- County
'DW' AS EIRCODE		-- Identify migrated rows
  FROM #TEMP_CT_HEADS  AS cth
	LEFT JOIN #TEMP_AGRESSO_MRCTCONTRACT AS AG_MRCT
	ON cth.CT_NO = AG_MRCT.CONTRACT_ID

   -- CONTRACT CRITERIA
   WHERE cth.CT_STATUS IN ('A', 'H', 'W')
	AND cth.CT_ANAL_CODE = 'ESTB'
--	AND cth.CT_ANAL_CODE IN ('T/E1','T/E4','T/ES','T/GP')		-- Use for Tendered Establishment Contracts
--	AND cth.CT_ANAL_CODE = 'T/MA'								-- Use for Tendered Maintenance Contracts
--	AND cth.CT_ANAL_CODE = 'ROAD'								-- Use for Road Contracts
--	AND cth.CT_ANAL_CODE = 'HAUL'								-- Use for Haulage Contracts
--	AND cth.CT_ANAL_CODE = 'HARV'								-- Use for Harvesting Contracts
	AND cth.CT_PLAN_END >  '2016-08-15'							-- Cutoff Date to be agreed with Finance for expiry of contracts in FIS

-----------------------------
-- Update sequence numbers --
-----------------------------


UPDATE [wts_coillte].[NEXT_SEQ]
SET NEXT_ID = (
				SELECT MAX (SD_CCF_RCT_FORM_ID) + 1
				FROM [wts_coillte].[wts_coillte].[SD_CCF_RCT_FORM]
			  )
WHERE KEYWORD = 'SD_CCF_RCT_FORM'

SELECT * FROM WTS_COILLTE.SD_CCF_RCT_FORM

-------------------------------------------------------------------------------
-- WTS_COILLTE.CONTRACT_ORG_SCOPE 
-------------------------------------------------------------------------------

DECLARE @NEXT_ID	numeric(10,0)

SELECT @NEXT_ID = NEXT_ID          
FROM [wts_coillte].[NEXT_SEQ]         
WHERE KEYWORD = 'CONTRACT_ORG_SCOPE'

INSERT INTO WTS_COILLTE.CONTRACT_ORG_SCOPE (
											[CONTRACT_ORG_SCOPE_ID],
											[CONTRACT_ID],
											[ORG_UNIT_ID]
										   )

-------------------------------------------------------------------------
---  Test this SELECT statement before running the INSERT            ----
--												RB 15/07/2016		-----
-------------------------------------------------------------------------

SELECT
(@NEXT_ID - 1) + ROW_NUMBER() OVER(ORDER BY cth.CT_NO),
(SELECT CONTRACT_ID FROM WTS_COILLTE.CONTRACTS CTRS 
  WHERE CTRS.CONTRACT_NUM = cth.CT_NO COLLATE SQL_Latin1_General_CP1_CI_AS) AS CONTRACT_ID,
ISNULL((SELECT TOP 1 ORG_UNIT_ID FROM wts_coillte.HUMAN_RESOURCE HR
WHERE HR.LAST_NAME = TA.LAST_NAME COLLATE Latin1_General_CI_AS AND HR.FIRST_NAME = TA.FIRST_NAME COLLATE Latin1_General_CI_AS), 100) AS ORG_UNIT_ID
  FROM #TEMP_CT_HEADS  AS cth
  LEFT JOIN #TEMP_APPROVER TA
  ON cth.CT_MANAGER = TA.USERNAME COLLATE Latin1_General_CI_AS
   -- CONTRACT CRITERIA
   WHERE cth.CT_STATUS IN ('A', 'H', 'W')
	AND cth.CT_ANAL_CODE = 'ESTB'
--	AND cth.CT_ANAL_CODE IN ('T/E1','T/E4','T/ES','T/GP')		-- Use for Tendered Establishment Contracts
--	AND cth.CT_ANAL_CODE = 'T/MA'								-- Use for Tendered Maintenance Contracts
--	AND cth.CT_ANAL_CODE = 'ROAD'								-- Use for Road Contracts
--	AND cth.CT_ANAL_CODE = 'HAUL'								-- Use for Haulage Contracts
--	AND cth.CT_ANAL_CODE = 'HARV'			Hi 					-- Use for Harvesting Contracts
	AND cth.CT_PLAN_END >  '2016-08-15'							-- Cutoff Date to be agreed with Finance for expiry of contracts in FIS

-----------------------------
-- Update sequence numbers --
-----------------------------
UPDATE [wts_coillte].[NEXT_SEQ]
SET NEXT_ID = (
				SELECT MAX (CONTRACT_ORG_SCOPE_ID) + 1
				FROM [wts_coillte].[wts_coillte].[CONTRACT_ORG_SCOPE]
			  )
WHERE KEYWORD = 'CONTRACT_ORG_SCOPE'

SELECT * FROM WTS_COILLTE.CONTRACT_ORG_SCOPE




----------------------------------------------------------------------------------------------------------------
-- WTS_COILLTE.SD_CCF_AWARD_APPROVAL 
--
--* Disable Trigger [wts_coillte].[SD_TRIG_APPROVE_ACTIVE] on this table first then enable it again after insert
-----------------------------------------------------------------------------------------------------------------
DECLARE @NEXT_ID	numeric(10,0)

SELECT @NEXT_ID = NEXT_ID          
FROM [wts_coillte].[NEXT_SEQ]         
WHERE KEYWORD = 'SD_CCF_AWARD_APPROVAL'

INSERT INTO WTS_COILLTE.SD_CCF_AWARD_APPROVAL 
(
[SD_CCF_AWARD_APPROVAL_ID],
[CONTRACT_ID],
[BIDDING_RANKING],
[SUPPLIER_PERFORMANCE_SCORE],
[PANEL_ID_REFERENCE],
[ACTIVITY_MONITORING_SCORE],
[NOTES],
[APPROVAL_1_DATE],
[APPROVAL_2_DATE],
[SPS_ATTACHMENT],
--[APPROVER_1_ID],
--[APPROVER_2_ID],
--[APPROVER_1_ROLE_ID],
--[APPROVER_2_ROLE_ID],
[TENDER_PACKAGE_NUM]
)

-------------------------------------------------------------------------
---  Test this SELECT statement before running the INSERT            ----
-------------------------------------------------------------------------

SELECT
(@NEXT_ID - 1) + ROW_NUMBER() OVER(ORDER BY cth.CT_NO) AS SD_CCF_AWARD_APPROVAL_ID,
(SELECT CONTRACT_ID FROM WTS_COILLTE.CONTRACTS CTRS 
  WHERE CTRS.CONTRACT_NUM = cth.CT_NO COLLATE SQL_Latin1_General_CP1_CI_AS) AS CONTRACT_ID,

NULL AS BIDDING_RANKING,
NULL AS SUPPLIER_PERFORMANCE_SCORE,
NULL AS PANEL_ID_REFERENCE,
NULL AS ACTIVITY_MONITORING_SCORE,
'ORIGINAL AUTHORIZER: ' + cth.CT_AUTHORIZER + '; AUTHORIZE DATE: ' + LEFT(CONVERT(VARCHAR, CDA.DATE_AUTHORIZED, 103), 10) AS NOTES,
NULL AS APPROVAL_1_DATE,
NULL AS APPROVAL_2_DATE,
NULL AS SPS_ATTACHMENT,
--NULL AS APPROVER_1_ID,
--(SELECT TOP 1 HUMAN_RESOURCE_ID FROM wts_coillte.HUMAN_RESOURCE HR
--WHERE HR.LAST_NAME = TA.LAST_NAME COLLATE Latin1_General_CI_AS AND HR.FIRST_NAME = TA.FIRST_NAME COLLATE Latin1_General_CI_AS) AS APPROVER_1_ID,
--NULL AS APPROVER_2_ID,
--NULL AS APPROVER_1_ROLE_ID,
--NULL AS APPROVER_2_ROLE_ID,
cth.PACKAGE_NUMBER AS TENDER_PACKAGE_NUM

  FROM #TEMP_CT_HEADS  AS cth
  LEFT JOIN #TEMP_APPROVER TA
  ON cth.CT_AUTHORIZER = TA.USERNAME COLLATE Latin1_General_CI_AS
  LEFT JOIN #TEMP_CT_DATE_AUTHORIZED CDA
  ON CDA.CT_NO = cth.CT_NO

   -- CONTRACT CRITERIA
   WHERE cth.CT_STATUS IN ('A', 'H', 'W')
	AND cth.CT_ANAL_CODE = 'ESTB'
--	AND cth.CT_ANAL_CODE IN ('T/E1','T/E4','T/ES','T/GP')		-- Use for Tendered Establishment Contracts
--	AND cth.CT_ANAL_CODE = 'T/MA'								-- Use for Tendered Maintenance Contracts
--	AND cth.CT_ANAL_CODE = 'ROAD'								-- Use for Road Contracts
--	AND cth.CT_ANAL_CODE = 'HAUL'								-- Use for Haulage Contracts
--	AND cth.CT_ANAL_CODE = 'HARV'								-- Use for Harvesting Contracts
	AND cth.CT_PLAN_END >  '2016-08-15'							-- Cutoff Date to be agreed with Finance for expiry of contracts in FIS



-----------------------------
-- Update sequence numbers --
-----------------------------
UPDATE [wts_coillte].[NEXT_SEQ]
SET NEXT_ID = (
				SELECT MAX (SD_CCF_AWARD_APPROVAL_ID) + 1
				FROM [wts_coillte].[wts_coillte].[SD_CCF_AWARD_APPROVAL]
			  )
WHERE KEYWORD = 'SD_CCF_AWARD_APPROVAL'

SELECT * FROM WTS_COILLTE.SD_CCF_AWARD_APPROVAL



--------------------------------------------------------------------------------------------------------------------------------------
-- CONTRACT ACTIVITY LINES
--------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- tfm.[dbo].[TFM_VT_CMN_ACTIVITY_TYPE]
--
-- Create dummy activity for Establishment
-------------------------------------------------------------------------------

-- Activity Type First

  INSERT INTO [tfm].[dbo].[TFM_VT_CMN_ACT_TYPE]
  (
  TFMContextID
  ,Activity_Group
  ,Activity_Type
  ,Activity_Type_Desc
  ,ActiveFlag
  )
  VALUES
  (
  2100,
  'Establishment',
  'EST_LEGACY',
  'LEGACY',
  1
  )

-- Activity Subtype
  
INSERT INTO [tfm].[dbo].[TFM_VT_CMN_ACT_SUBTYPE]
(TFMContextID
 ,Activity_Type
 ,Activity_SubType
 ,Activity_SubType_Desc
 ,Detailed_Description
 ,Planning_Entity
 ,SU_Type
 ,EXPENDITURE_TYPE
 ,COILLTE_NOMINAL
 )
 VALUES
 (
 2100,
 'EST_LEGACY',
 'LEGACY',	
 'Legacy Silviculture Activity',	
 'Legacy Silviculture Activity',	
 'SU',
 'Establishment',
 'Capital',	
 '4200'
 )


SELECT * FROM tfm.[dbo].[TFM_VT_CMN_ACTIVITY_TYPE] WHERE TFMContextID = 2100

-------------------------------------------------------------------------------
-- tfm.dbo.TFM_VT_SILV_UNIT_SUBTYPE
--
-- Create dummy Silv Unit Subtype for Establishment
-------------------------------------------------------------------------------

INSERT INTO tfm.dbo.TFM_VT_SILV_UNIT_SUBTYPE
(
CODE
,DESCRIPTION
,ACTIVEFLAG
,MODIFIEDBY
,MODIFIEDON
,MODIFIEDUSING
,TYPE
)
VALUES
(
'Legacy' 
,'Legacy SU' 
,1 
,'DATA MIGRATION' 
,CAST(GETDATE() AS datetime2) 
,'SQL' 
,'Estab' 
)

-------------------------------------------------------------------------------
-- tfm.dbo.TFM_VT_CMN_ACT_SUBTYPE_VAL
--
-- Create dummy Silv Unit Subtype Value for Establishment
-------------------------------------------------------------------------------


INSERT INTO tfm.dbo.TFM_VT_CMN_ACT_SUBTYPE_VAL
(
[TFMContextID]
,[Activity_Type]
,[Activity_SubType]
,[value]
,[ActiveFlag]
)
VALUES
(
2100,
'EST_LEGACY',
'LEGACY',
'Legacy',
1
)




-------------------------------------------------------------------------------
-- [tfm].[dbo].[VMV_TFM_SILV_UNIT]
--
-- Create dummy Establishment Silv Unit
-- 
-- [tfm].[dbo].[VMV_TFM_SILV_ACTIVITY]
--
-- Create dummy Establishment Silv Activity 
-------------------------------------------------------------------------------
USE tfm

/*******************************************************************************************/
/*** Create Version First                                                                ***/
/*******************************************************************************************/


EXEC SDE.sde.create_version
'sde.DEFAULT', 'mvedit_SU', 1, 1, 'multiversioned view edit version - SU'

EXEC SDE.SDE.set_current_version 'dbo.mvedit_SU'

EXEC SDE.SDE.edit_version 'dbo.mvedit_SU', 1


      
-- Create dummy Establishment Silv Unit


INSERT INTO [tfm].[dbo].[VMV_TFM_SILV_UNIT]
(
[FOREST_OID]
,[DATA_SOURCE]
,[TYPE]
,[SUBTYPE]
,[CROP_TYPE]
,[COMMENTS]
,[CREATEDBY]
,[CREATEDON]
,[CREATEDUSING]
,[STATUS]
,[SU_YEAR]
,[ISGISLOCKED]
)
SELECT
F.OBJECTID  AS FOREST_OID
,3 AS DATA_SOURCE
,'Estab' AS TYPE
,'Legacy' AS SUBTYPE
,'Standard' AS CROP_TYPE
,'Dummy SU for migrated legacy FIS Contracts' AS COMMENTS
,'DATA MIGRATION' AS CREATEDBY
,CAST(GETDATE() AS datetime2) AS CREATEDON
,'SQL' AS CREATEDUSING
,'Active' AS STATUS
,2017 AS SU_YEAR
,'Y' AS ISGISLOCKED

FROM 

#TEMP_CT_LINE_FOREST CLF JOIN dbo.TFM_CMN_FOREST F
ON F.FOREST_CODE =  CLF.DERIVED_FOREST_CODE COLLATE SQL_Latin1_General_CP1_CI_AS
GROUP BY CLF.DERIVED_FOREST_CODE, F.OBJECTID

GO


--------------------------------------
-- Increment SILV_NUMBER column
--------------------------------------

exec [dbo].[TFM_CF_PRC_SU_SILV_NUMBER]
GO

-------------------------------------------------------------------------------
-- Create dummy Establishment Silv Activity 
-------------------------------------------------------------------------------


INSERT INTO [tfm].[dbo].[VMV_TFM_SILV_ACTIVITY]
(
[SILVUNIT_OID]
,[ACTIVITY_TYPE]
,[ACTIVITY_SUBTYPE]   
,[ACTIVITY_STATUS]    
,[ACTIVITY_APPROVAL_STATUS]
,[RESOURCE_TYPE]
,[UNIT_OF_MEASUREMENT]
,[PLANNED_NUM_UNITS]
,[PLANNED_EFFORT]
,[STANDARD_UNIT_COST]
,[VARIANCE_COST]
,[PLANNED_UNIT_COST] 
,[PLANNED_TOTAL_COST]
,[START_DATE]
,[END_DATE]     
,[WORK_PACKAGE_TYPE]    
,[FL_SPECIES_DIFF_IND]
,[TARGET_PLANTS_HA]
,[CROP_TYPE]
,[PLANNED_AREA]
,[NET_AREA]
,[ACTUAL_AREA]
,[EXPENDITURE_TYPE]
,[COMMENTS]
,[CREATEDBY]
,[CREATEDON]
,[CREATEDUSING]
,[GIS_AREA]
,[SU_STATUS]
,[SU_TYPE]
,[ISGISLOCKED]
)
SELECT 
SU.OBJECTID AS [SILVUNIT_OID]
,'EST_LEGACY' AS [ACTIVITY_TYPE]
,'LEGACY' AS [ACTIVITY_SUBTYPE]
,'A' AS [ACTIVITY_STATUS]
,'Approved' AS [ACTIVITY_APPROVAL_STATUS]
,2 AS [RESOURCE_TYPE]
,'hectare' AS [UNIT_OF_MEASUREMENT]
,0 AS [PLANNED_NUM_UNITS]
,0 AS [PLANNED_EFFORT]
,0 AS [STANDARD_UNIT_COST]
,0 AS [VARIANCE_COST]
,0 AS [PLANNED_UNIT_COST]
,0 AS [PLANNED_TOTAL_COST]
,'2016-01-01' AS [START_DATE]
,'2017-01-01' AS [END_DATE]
,'STC' AS [WORK_PACKAGE_TYPE]
,'N' AS [FL_SPECIES_DIFF_IND]
,2500 AS [TARGET_PLANTS_HA]
,'Standard' AS [CROP_TYPE]
,0 AS [PLANNED_AREA]
,0 AS [NET_AREA]
,0 AS [ACTUAL_AREA]
,'Capital' AS [EXPENDITURE_TYPE]
,'Legacy Establishment Silviculture Activity' AS [COMMENTS]
,'DATA MIGRATION' AS [CREATEDBY]
,CAST(GETDATE() AS datetime2) AS [CREATEDON]
,'SQL' AS [CREATEDUSING]
,0 AS [GIS_AREA]
,'Pending' AS [SU_STATUS]
,'Estab' AS [SU_TYPE]
,'Y' AS [ISGISLOCKED]


FROM #TEMP_CT_LINE_FOREST CLF
JOIN dbo.TFM_CMN_FOREST F
ON F.FOREST_CODE =  CLF.DERIVED_FOREST_CODE COLLATE SQL_Latin1_General_CP1_CI_AS
JOIN
[tfm].[dbo].[VMV_TFM_SILV_UNIT] SU
ON SU.FOREST_OID = F.OBJECTID AND SU.CREATEDBY = 'DATA MIGRATION'
ORDER BY CLF.CT_NO, CLF.CT_LINE_NO




/*******************************************************************************************/
/*** Close Version  (Dont forget to also Reconcile and Post Version in ArcCatalog)       ***/
/*******************************************************************************************/

EXEC SDE.SDE.edit_version 'dbo.mvedit_SU', 2


SELECT * FROM [tfm].[dbo].[VMV_TFM_SILV_UNIT] WHERE CREATEDBY = 'DATA MIGRATION' ORDER BY OBJECTID

SELECT * FROM [tfm].[dbo].[VMV_TFM_SILV_ACTIVITY] WHERE CREATEDBY = 'DATA MIGRATION'

SELECT * FROM [tfm].dbo.TFM_CMN_FOREST

SELECT * FROM [tfm].[dbo].[VMV_TFM_SILV_UNIT] SU
JOIN
[tfm].[dbo].[VMV_TFM_SILV_ACTIVITY] SA
ON SU.OBJECTID = SA.SILVUNIT_OID

WHERE SA.CREATEDBY = 'DATA MIGRATION'

SELECT * FROM wts_coillte.WTS_COILLTE.SD_CONTRACT_ACTIVITY_LINE



-------------------------------------------------------------------------------
-- WTS_COILLTE.SD_CONTRACT_ACTIVITY_LINE
-------------------------------------------------------------------------------
----------------------------------------------------
USE wts_coillte

-- Get the Next ID to use for CONTRACT_ACTIVITY_LINE
DECLARE @NEXT_ID	numeric(10,0)

SELECT @NEXT_ID = NEXT_ID          
FROM [wts_coillte].[NEXT_SEQ]         
WHERE KEYWORD = 'SD_CONTRACT_ACTIVITY_LINE'


INSERT INTO WTS_COILLTE.SD_CONTRACT_ACTIVITY_LINE
(
 [ACTIVITY_LINE_ID]
,[CONTRACT_ID]
,[TFMCONTEXTID]
,[OBJECTID]
,[ACTIVITY_TYPE]
,[ACTIVITY_TYPE_SUBTYPE]
,[AWARDED_QUANTITY]
,[AWARDED_UNIT_COST]
,[AWARDED_UOM]
,[AWARDED_TOTAL_COST]
--,[POSTED_CWRS]
--,[PENDING_CWRS]
,[VALUE_REMAINING]
--,[ACTIVE_CONTRACT_FLAG]
--,[AWARD_MANUAL_UPDATE_FLAG]
--,[AVG_TREE]
)
SELECT
--(@NEXT_ID - 1) + ROW_NUMBER() OVER(ORDER BY cth.CT_NO, ctl.CT_LINE_NO) AS ACTIVITY_LINE_ID,
(SELECT CONTRACT_ID FROM WTS_COILLTE.CONTRACTS CTRS 
  WHERE CTRS.CONTRACT_NUM = ctl.CT_NO COLLATE SQL_Latin1_General_CP1_CI_AS) AS CONTRACT_ID,
2100 AS [TFMCONTEXTID],
0 AS [OBJECTID],   -- Dummy Silv Activity OBJECTID
'Establishment' AS [ACTIVITY_TYPE],
'EST_LEGACY' AS [ACTIVITY_TYPE_SUBTYPE],
ctl.CT_QTY/1000 AS [AWARDED_QUANTITY],
ctl.CT_PRICE/10000 AS [AWARDED_UNIT_COST],
CASE CONTRACT_UNIT
WHEN 'ha' THEN 'hectare' 
WHEN 'm' THEN 'cubic metre'
ELSE CONTRACT_UNIT END AS [AWARDED_UOM],
ctl.CT_LINE_VALUE AS [AWARDED_TOTAL_COST],
--AS [POSTED_CWRS],
--AS [PENDING_CWRS],
ctl.CT_LINE_VALUE - (ctl.VALUE_RECEIVED/10000) AS [VALUE_REMAINING]
--AS [ACTIVE_CONTRACT_FLAG],
--AS [AWARD_MANUAL_UPDATE_FLAG],
--AS [AVG_TREE]

FROM #TEMP_CT_HEADS  AS cth
LEFT JOIN #TEMP_CT_LINES AS ctl
ON cth.CT_NO = ctl.CT_NO

   -- CONTRACT CRITERIA
   WHERE cth.CT_STATUS IN ('A', 'H', 'W')
	AND cth.CT_ANAL_CODE = 'ESTB'								-- Use for Establishment Contracts
--	AND cth.CT_ANAL_CODE IN ('T/E1','T/E4','T/ES','T/GP')		-- Use for Tendered Establishment Contracts
--	AND cth.CT_ANAL_CODE = 'T/MA'								-- Use for Tendered Maintenance Contracts
--	AND cth.CT_ANAL_CODE = 'ROAD'								-- Use for Road Contracts
--	AND cth.CT_ANAL_CODE = 'HAUL'								-- Use for Haulage Contracts
--	AND cth.CT_ANAL_CODE = 'HARV'								-- Use for Harvesting Contracts
	AND cth.CT_PLAN_END >  '2016-08-15'							-- Cutoff Date to be agreed with Finance for expiry of contracts in FIS
ORDER BY cth.CT_NO, ctl.CT_LINE_NO

-----------------------------
-- Update sequence numbers --
-----------------------------

UPDATE [wts_coillte].[NEXT_SEQ]
SET NEXT_ID = (
				SELECT MAX (ACTIVITY_LINE_ID) + 1
				FROM [wts_coillte].[wts_coillte].[SD_CONTRACT_ACTIVITY_LINE]
			  )
WHERE KEYWORD = 'SD_CONTRACT_ACTIVITY_LINE'

UPDATE A

SET A.OBJECTID = B.OBJECTID
FROM

(SELECT ROW_NUMBER() OVER(ORDER BY ACTIVITY_LINE_ID) AS AOBJECTID, OBJECTID FROM wts_COILLTE.WTS_COILLTE.SD_CONTRACT_ACTIVITY_LINE 
WHERE CONTRACT_ID IN (SELECT CONTRACT_ID FROM WTS_COILLTE.CONTRACTS WHERE user_name = 'DATA_MIGRATION')) A

JOIN

(SELECT ROW_NUMBER() OVER(ORDER BY SA.OBJECTID) AS BOBJECTID, SA.OBJECTID FROM [tfm].[dbo].[VMV_TFM_SILV_UNIT] SU
JOIN
[tfm].[dbo].[VMV_TFM_SILV_ACTIVITY] SA
ON SU.OBJECTID = SA.SILVUNIT_OID
WHERE SA.CREATEDBY = 'DATA MIGRATION') B

ON A.AOBJECTID = B.BOBJECTID


SELECT * FROM WTS_COILLTE.SD_CONTRACT_ACTIVITY_LINE



------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- [wts_coillte].[wts_coillte].[SD_TFM_ACTIVITY_CONTRACT_LINK]
-------------------------------------------------------------------------------

-- Get the Next ID to use for CONTRACT_ACTIVITY_LINE
DECLARE @NEXT_ID	numeric(10,0)

SELECT @NEXT_ID = NEXT_ID          
FROM [wts_coillte].[NEXT_SEQ]         
WHERE KEYWORD = 'SD_TFM_ACTIVITY_CONTRACT_LINK'


INSERT INTO [wts_coillte].[wts_coillte].[SD_TFM_ACTIVITY_CONTRACT_LINK]
(
ACTIVITY_CONTRACT_LINK_ID
,TFMCONTEXTID
,CONTEXTOID
,CONTRACT_ID
)
SELECT
(@NEXT_ID - 1) + ROW_NUMBER() OVER(ORDER BY CT.CONTRACT_ID) AS ACTIVITY_CONTRACT_LINK_ID,
2100,
CAL.OBJECTID,   -- Dummy Silv Activity OBJECTID
CT.CONTRACT_ID
FROM WTS_COILLTE.SD_CONTRACTS CT
JOIN 
WTS_COILLTE.SD_CONTRACT_ACTIVITY_LINE CAL
ON CT.CONTRACT_ID = CAL.CONTRACT_ID

WHERE CAL.CONTRACT_ID IN (SELECT CONTRACT_ID FROM WTS_COILLTE.CONTRACTS WHERE user_name = 'DATA_MIGRATION')



-----------------------------
-- Update sequence numbers --
-----------------------------

UPDATE [wts_coillte].[NEXT_SEQ]
SET NEXT_ID = (
				SELECT MAX (ACTIVITY_CONTRACT_LINK_ID) + 1
				FROM [wts_coillte].[wts_coillte].[SD_TFM_ACTIVITY_CONTRACT_LINK]
			  )
WHERE KEYWORD = 'SD_TFM_ACTIVITY_CONTRACT_LINK'


SELECT * FROM [wts_coillte].[wts_coillte].[SD_TFM_ACTIVITY_CONTRACT_LINK]

--------------------------------------------------------------------------------------------------------------------------------------
-- CONTRACT CWR
--------------------------------------------------------------------------------------------------------------------------------------



-------------------------------------------------------------------------------
-- WTS_COILLTE.SD_CWR_HEADER
-------------------------------------------------------------------------------
----------------------------------------------------

-------------------------
-- Get the Next ID to use
-------------------------
DECLARE @NEXT_ID	numeric(10,0)

SELECT @NEXT_ID = NEXT_ID          
FROM [wts_coillte].[NEXT_SEQ]         
WHERE KEYWORD = 'SD_CWR_HEADER'

-----

INSERT INTO WTS_COILLTE.SD_CWR_HEADER
(
CWR_HEADER_ID
,CONTRACT_ID
,CWR_NUM
,WE_DATE
,VALUE
,STATUS
,CREATED_BY
)
SELECT
(@NEXT_ID - 1) + ROW_NUMBER() OVER(ORDER BY GH.GRN_NO) AS CWR_HEADER_ID,
(SELECT CONTRACT_ID FROM WTS_COILLTE.CONTRACTS CT 
  WHERE CT.CONTRACT_NUM = GH.CT_NO COLLATE SQL_Latin1_General_CP1_CI_AS) AS CONTRACT_ID,
GH.GRN_NO AS CWR_NUM,
GH.WE_DATE AS WE_DATE,
GH.GRN_VALUE/1000 AS GRN_VALUE,
GH.GRN_STATUS AS STATUS,
'DATA MIGRATION' AS CREATED_BY


FROM #TEMP_GRN_HEADS  AS GH
JOIN #TEMP_CT_HEADS AS cth
ON GH.CT_NO = cth.CT_NO
   -- CONTRACT CRITERIA
   WHERE cth.CT_STATUS IN ('A', 'H', 'W')
	AND cth.CT_ANAL_CODE = 'ESTB'								-- Use for Establishment Contracts
--	AND cth.CT_ANAL_CODE IN ('T/E1','T/E4','T/ES','T/GP')		-- Use for Tendered Establishment Contracts
--	AND cth.CT_ANAL_CODE = 'T/MA'								-- Use for Tendered Maintenance Contracts
--	AND cth.CT_ANAL_CODE = 'ROAD'								-- Use for Road Contracts
--	AND cth.CT_ANAL_CODE = 'HAUL'								-- Use for Haulage Contracts
--	AND cth.CT_ANAL_CODE = 'HARV'								-- Use for Harvesting Contracts
	AND cth.CT_PLAN_END >  '2016-08-15'							-- Cutoff Date to be agreed with Finance for expiry of contracts in FIS

--SELECT * FROM #TEMP_GRN_HEADS ORDER BY GRN_STATUS
--SELECT * FROM WTS_COILLTE.SD_CWR_HEADER

-----------------------------
-- Update sequence numbers --
-----------------------------

UPDATE [wts_coillte].[NEXT_SEQ]
SET NEXT_ID = (
				SELECT MAX (CWR_HEADER_ID) + 1
				FROM [wts_coillte].[wts_coillte].[SD_CWR_HEADER]
			  )
WHERE KEYWORD = 'SD_CWR_HEADER'

------------------------------------------------------------------------



-------------------------------------------------------------------------------
-- WTS_COILLTE.SD_CWR
-------------------------------------------------------------------------------
----------------------------------------------------


-- Get the Next ID to use


SELECT @NEXT_ID = NEXT_ID          
FROM [wts_coillte].[NEXT_SEQ]         
WHERE KEYWORD = 'SD_CWR'


INSERT INTO WTS_COILLTE.SD_CWR
(
CWR_ID
,ACTIVITY_LINE_ID
,CWR_LINE_NUM
,SERVICE_DESC
,HAULAGE_DEST
,QUANTITY_RECEIVED
,VALUE
,PRODUCTION_DATA
,CWR_HEADER_ID
,CREATED_BY
,CONTRACT_LINE
,LORRY_REG
,UNIT_NAME
--,DISTANCE
--,AWARDED_RATE
--,FUEL_VARIANCE
--,TONNAGE
,VOLUME
--,PAYMENT_NUM 
)
SELECT
(@NEXT_ID - 1) + ROW_NUMBER() OVER(ORDER BY cth.CT_NO, cth.CT_LINE_NO) AS CWR_ID,
(SELECT ACTIVITY_LINE_ID FROM WTS_COILLTE.SD_CONTRACT_ACTIVITY_LINE CAL
WHERE CAL.CONTRACT_ID = GL.CT_NO AS ACTIVITY_LINE_ID,
GL.GRN_LINE_NO AS CWR_LINE_NUM,
NULL AS SERVICE_DESC,
NULL AS HAULAGE_DEST,
GL.QTY_RECEIVED AS QUANTITY_RECEIVED,
GL.GRN_LINE_VALUE AS VALUE,
GL.PROD_DATA AS PRODUCTION_DATA,
 AS CWR_HEADER_ID,
'DATA MIGRATION' AS CREATED_BY,
GL.CT_LINE_NO AS CONTRACT_LINE,
NULL AS LORRY_REG,
GL.CONTRACT_UNIT AS UNIT_NAME,
--GL. AS DISTANCE,
-- AS AWARDED_RATE,
-- AS FUEL_VARIANCE,
-- AS TONNAGE,
GL.QTY_INVOICED AS VOLUME
-- AS PAYMENT_NUM


FROM 

#TEMP_GRN_LINES  AS GL
JOIN #TEMP_CT_HEADS AS cth
ON GL.CT_NO = cth.CT_NO
   -- CONTRACT CRITERIA
   WHERE cth.CT_STATUS IN ('A', 'H', 'W')
	AND cth.CT_ANAL_CODE = 'ESTB'								-- Use for Establishment Contracts
--	AND cth.CT_ANAL_CODE IN ('T/E1','T/E4','T/ES','T/GP')		-- Use for Tendered Establishment Contracts
--	AND cth.CT_ANAL_CODE = 'T/MA'								-- Use for Tendered Maintenance Contracts
--	AND cth.CT_ANAL_CODE = 'ROAD'								-- Use for Road Contracts
--	AND cth.CT_ANAL_CODE = 'HAUL'								-- Use for Haulage Contracts
--	AND cth.CT_ANAL_CODE = 'HARV'								-- Use for Harvesting Contracts
	AND cth.CT_PLAN_END >  '2016-08-15'							-- Cutoff Date to be agreed with Finance for expiry of contracts in FIS

SELECT * FROM #TEMP_GRN_LINES ORDER BY CT_NO
SELECT * FROM #TEMP_GRN_HEADS

SELECT * FROM [wts_coillte].[wts_coillte].SD_CWR
-----------------------------
-- Update sequence numbers --
-----------------------------

UPDATE [wts_coillte].[NEXT_SEQ]
SET NEXT_ID = (
				SELECT MAX (CWR_ID) + 1
				FROM [wts_coillte].[wts_coillte].[SD_CWR]
			  )
WHERE KEYWORD = 'SD_CWR'

------------------------------------------------------------------------






------------------------------------------------------------------------
-- Delete migrated contracts data for all contexts
------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- [wts_coillte].[wts_coillte].[SD_TFM_ACTIVITY_CONTRACT_LINK]  Delete
-------------------------------------------------------------------------------


DELETE FROM [wts_coillte].[wts_coillte].[SD_TFM_ACTIVITY_CONTRACT_LINK]

WHERE CONTRACT_ID IN (SELECT CONTRACT_ID FROM WTS_COILLTE.SD_CONTRACTS CT
WHERE CT.MODIFY_USER = 'DATA_MIGRATION')

-----------------------------
-- Update sequence numbers --
-----------------------------

UPDATE [wts_coillte].[NEXT_SEQ]
SET NEXT_ID = (
				SELECT MAX (ACTIVITY_CONTRACT_LINK_ID) + 1
				FROM [wts_coillte].[wts_coillte].[SD_TFM_ACTIVITY_CONTRACT_LINK]
			  )
WHERE KEYWORD = 'SD_TFM_ACTIVITY_CONTRACT_LINK'



---------------------------------------------------------------------------------
-- [tfm].[dbo].[VMV_TFM_SILV_UNIT]  dummy Establishment Silv Unit Delete
--
-- [tfm].[dbo].[VMV_TFM_SILV_ACTIVITY]  dummy Establishment Silv Activity Delete
---------------------------------------------------------------------------------

USE tfm

/*******************************************************************************************/
/*** Create Version First                                                                ***/
/*******************************************************************************************/


EXEC SDE.sde.create_version
'sde.DEFAULT', 'mvedit_SU', 1, 1, 'multiversioned view edit version - SU'

EXEC SDE.SDE.set_current_version 'dbo.mvedit_SU'

EXEC SDE.SDE.edit_version 'dbo.mvedit_SU', 1

-- Delete

DELETE FROM [tfm].[dbo].[VMV_TFM_SILV_UNIT] WHERE CREATEDBY = 'DATA MIGRATION'

DELETE FROM [tfm].[dbo].[VMV_TFM_SILV_ACTIVITY] WHERE CREATEDBY = 'DATA MIGRATION'


/*******************************************************************************************/
/*** Close Version  (Dont forget to also Reconcile and Post Version in ArcCatalog)       ***/
/*******************************************************************************************/

EXEC SDE.SDE.edit_version 'dbo.mvedit_SU', 2

SELECT * FROM [tfm].[dbo].[VMV_TFM_SILV_UNIT] WHERE CREATEDBY = 'DATA MIGRATION'

SELECT * FROM [tfm].[dbo].[VMV_TFM_SILV_ACTIVITY] WHERE CREATEDBY = 'DATA MIGRATION'



-----------------------------------------
-- WTS_COILLTE.SD_CWR Delete
-----------------------------------------

DELETE FROM WTS_COILLTE.SD_CWR 
WHERE CREATED_BY = 'DATA MIGRATION'

UPDATE [wts_coillte].[NEXT_SEQ]
SET NEXT_ID = (
				SELECT MAX (CWR_ID) + 1
				FROM [wts_coillte].[wts_coillte].[SD_CWR]
			  )
WHERE KEYWORD = 'SD_CWR'


-----------------------------------------
-- WTS_COILLTE.SD_CWR_HEADER Delete
-----------------------------------------

DELETE FROM WTS_COILLTE.SD_CWR_HEADER 
WHERE CREATED_BY = 'DATA MIGRATION'

UPDATE [wts_coillte].[NEXT_SEQ]
SET NEXT_ID = (
				SELECT MAX (CWR_HEADER_ID) + 1
				FROM [wts_coillte].[wts_coillte].[SD_CWR_HEADER]
			  )
WHERE KEYWORD = 'SD_CWR_HEADER'

-----------------------------------------
-- WTS_COILLTE.SD_CONTRACT_ACTIVITY_LINE Delete
-----------------------------------------

DELETE FROM WTS_COILLTE.SD_CONTRACT_ACTIVITY_LINE 
WHERE CONTRACT_ID IN (SELECT CONTRACT_ID FROM WTS_COILLTE.CONTRACTS WHERE user_name = 'DATA_MIGRATION')

UPDATE [wts_coillte].[NEXT_SEQ]
SET NEXT_ID = (
				SELECT MAX (ACTIVITY_LINE_ID) + 1
				FROM [wts_coillte].[wts_coillte].[SD_CONTRACT_ACTIVITY_LINE]
			  )
WHERE KEYWORD = 'SD_CONTRACT_ACTIVITY_LINE'

------------------------------------------

-----------------------------------------
-- WTS_COILLTE.SD_CCF_AWARD_APPROVAL Delete
-----------------------------------------

DELETE FROM WTS_COILLTE.SD_CCF_AWARD_APPROVAL
WHERE CONTRACT_ID IN (SELECT CONTRACT_ID FROM WTS_COILLTE.CONTRACTS WHERE user_name = 'DATA_MIGRATION')

UPDATE [wts_coillte].[NEXT_SEQ]
SET NEXT_ID = (
				SELECT MAX (SD_CCF_AWARD_APPROVAL_ID) + 1
				FROM [wts_coillte].[wts_coillte].[SD_CCF_AWARD_APPROVAL]
			  )
WHERE KEYWORD = 'SD_CCF_AWARD_APPROVAL'

-----------------------------------------
-- WTS_COILLTE.CONTRACT_ORG_SCOPE Delete
-----------------------------------------

DELETE FROM WTS_COILLTE.CONTRACT_ORG_SCOPE
WHERE CONTRACT_ID IN (SELECT CONTRACT_ID FROM WTS_COILLTE.CONTRACTS WHERE user_name = 'DATA_MIGRATION')

UPDATE [wts_coillte].[NEXT_SEQ]
SET NEXT_ID = (
				SELECT MAX (CONTRACT_ORG_SCOPE_ID) + 1
				FROM [wts_coillte].[wts_coillte].[CONTRACT_ORG_SCOPE]
			  )
WHERE KEYWORD = 'CONTRACT_ORG_SCOPE'


-----------------------------------------
-- WTS_COILLTE.SD_CCF_RCT_FORM Delete
-----------------------------------------

DELETE FROM WTS_COILLTE.SD_CCF_RCT_FORM
WHERE CONTRACT_ID IN (SELECT CONTRACT_ID FROM WTS_COILLTE.CONTRACTS WHERE user_name = 'DATA_MIGRATION')

UPDATE [wts_coillte].[NEXT_SEQ]
SET NEXT_ID = (
				SELECT MAX (SD_CCF_RCT_FORM_ID) + 1
				FROM [wts_coillte].[wts_coillte].[SD_CCF_RCT_FORM]
			  )
WHERE KEYWORD = 'SD_CCF_RCT_FORM'

-----------------------------------------
-- WTS_COILLTE.SD_CONTRACTS Delete
-----------------------------------------

DELETE FROM WTS_COILLTE.SD_CONTRACTS 
WHERE CONTRACT_ID IN (SELECT CONTRACT_ID FROM WTS_COILLTE.CONTRACTS WHERE user_name = 'DATA_MIGRATION')


-----------------------------------------
-- wts_coillte.CONTRACTED_PARTY Delete 
-----------------------------------------

DELETE FROM wts_coillte.CONTRACTED_PARTY 
WHERE CONTRACT_ID IN (SELECT CONTRACT_ID FROM WTS_COILLTE.CONTRACTS WHERE user_name = 'DATA_MIGRATION')

UPDATE [wts_coillte].[NEXT_SEQ]
SET NEXT_ID = (
				SELECT MAX (CPARTY_ID) + 1
				FROM wts_coillte.CONTRACTED_PARTY
			  )
WHERE KEYWORD = 'CONTRACTED_PARTY'

SELECT * FROM wts_coillte.CONTRACTED_PARTY

-----------------------------------------
-- WTS_COILLTE.CONTRACTS Delete 
-----------------------------------------

DELETE FROM WTS_COILLTE.CONTRACTS WHERE user_name = 'DATA_MIGRATION'

UPDATE [wts_coillte].[NEXT_SEQ]
SET NEXT_ID = (
				SELECT MAX (CONTRACT_ID) + 1
				FROM [wts_coillte].[wts_coillte].[CONTRACTS]
			  )
WHERE KEYWORD = 'CONTRACTS'


SELECT * FROM WTS_COILLTE.CONTRACTS

-----------------------------------------
-- WTS_COILLTE.SD_SIN Delete 
-----------------------------------------

DELETE FROM WTS_COILLTE.SD_SIN WHERE SIN IN 
(SELECT AG_MRCT.SIN_NUMBER COLLATE SQL_Latin1_General_CP1_CI_AS
  FROM #TEMP_CT_HEADS  AS cth
	JOIN #TEMP_AGRESSO_MRCTCONTRACT AS AG_MRCT
	ON cth.CT_NO COLLATE SQL_Latin1_General_CP1_CI_AS = AG_MRCT.CONTRACT_ID 
	WHERE LEN(AG_MRCT.SIN_NUMBER) > 1 
	AND cth.CT_STATUS IN ('A', 'H', 'W')
	AND cth.CT_PLAN_END >  '2016-08-15')		

UPDATE [wts_coillte].[NEXT_SEQ]
SET NEXT_ID = (
				SELECT MAX (SIN_ID) + 1
				FROM WTS_COILLTE.SD_SIN
			  )
WHERE KEYWORD = 'SD_SIN'
------------------------------------------------------------------------
-- End of Delete migrated contracts data for all contexts
------------------------------------------------------------------------





/*
*  Contract Header
*/

/* Columns in Contract Header query
   CTR_CODE, 
   CTR_NAME, 
   CT_NO, 
   CT_DATE, 
   CT_TYPE, 
   CT_ANAL_CODE, 
   CT_MANAGER, 
   LAST_GRN_DATE, 
   CT_VALUE, 
   CT_VALUE_RECEIVED, 
   CT_PAY_FREQUENCY, 
   CT_STATUS, 
   CT_STATUS_SHORT, 
   CT_SPECIFIC, 
   CT_SPECIFIC_DESC, 
   CT_AUTHORIZER, 
   CT_PLAN_END, 
   CT_INS_TYPE, 
   INSURANCE_EXPIRY_DATE, 
   INSURANCE_EXPIRED, 
   CT_TYPE_ABBREV, 
   CT_BALANCE, 
   AUTHORIZED_VALUE, 
   UNAUTHORIZED_VALUE
*/


-- Query FIS Contract Headers data source

   SELECT 
      cth.CTR_CODE, 
      
         (
            SELECT ctr.CTR_NAME
            FROM #TEMP_CTRS  AS ctr
            WHERE ctr.CTR_CODE = cth.CTR_CODE
         ) AS CTR_NAME, 
      cth.CT_NO, 
      cth.CT_DATE, 
      cth.CT_TYPE, 
      cth.CT_ANAL_CODE, 
      cth.CT_MANAGER, 
      cth.LAST_GRN_DATE, 
      cth.CT_VALUE / 100 AS CT_VALUE, 
      cth.CT_VALUE_RECEIVED / 100 AS CT_VALUE_RECEIVED, 
      cth.CT_PAY_FREQUENCY, 
      cth.CT_STATUS, 
      CASE cth.CT_STATUS
         WHEN 'G' THEN 'Gen''ed'
         WHEN 'U' THEN 'Unauth'
         WHEN 'A' THEN 'Auth''d'
         WHEN 'H' THEN 'Held'
         WHEN 'C' THEN 'Complt'
         WHEN 'X' THEN 'Cancld'
         WHEN 'W' THEN 'WrkRec'
         ELSE cth.CT_STATUS
      END AS CT_STATUS_SHORT, 
      cth.CT_SPECIFIC, 
      CASE cth.CT_SPECIFIC
         WHEN 'Y' THEN 'Spec'
         ELSE 'Unsp'
      END AS CT_SPECIFIC_DESC, 
      cth.CT_AUTHORIZER, 
      cth.CT_PLAN_END, 
      cth.CT_INS_TYPE, 
          (
            SELECT max(ctr.EXPIRY_DATE) AS expr
            FROM #TEMP_CTR_INSURANCE_DETS  AS ctr
            WHERE ctr.CTR_CODE = cth.CTR_CODE
         ) AS INSURANCE_EXPIRY_DATE, 
      CASE 
         WHEN cth.CT_INS_TYPE != 'S' THEN 'N'
         WHEN 
            (
               SELECT max(isnull(ctr.EXPIRY_DATE, '01-JAN-1900')) AS expr
               FROM #TEMP_CTR_INSURANCE_DETS  AS ctr
               WHERE cth.CTR_CODE = ctr.CTR_CODE
            ) < GETDATE() THEN 'Y'
         ELSE 'N'
      END AS INSURANCE_EXPIRED, 
      CASE cth.CT_TYPE
         WHEN 'C' THEN 'C2'
         WHEN 'G' THEN 'Gen.'
         WHEN 'P' THEN 'Prof'
         ELSE cth.CT_TYPE
      END AS CT_TYPE_ABBREV, 
      CASE 
         WHEN isnull(cth.CT_STATUS, ' ') IN ( 'A', 'H', 'W' ) AND isnull(cth.CT_VALUE, 0) > isnull(cth.CT_VALUE_RECEIVED, 0) 
			THEN isnull(cth.CT_VALUE, 0) - isnull(cth.CT_VALUE_RECEIVED, 0)
         ELSE 0
      END / 100 AS CT_BALANCE, 
      CASE 
         WHEN isnull(cth.CT_STATUS, ' ') NOT IN ( 'G', 'X' ) 
			THEN isnull(cth.CT_VALUE, 0)
         ELSE 0
      END / 100 AS AUTHORIZED_VALUE, 
      CASE 
         WHEN isnull(cth.CT_STATUS, ' ') IN ( 'G', 'X' ) 
			THEN isnull(cth.CT_VALUE, 0)
         ELSE 0
      END / 100 AS UNAUTHORIZED_VALUE
   FROM #TEMP_CT_HEADS  AS cth
   -- CONTRACT CRITERIA
   WHERE cth.CT_STATUS IN ('A', 'H', 'W')
	AND cth.CT_ANAL_CODE = 'ESTB'								-- Use for Establishment Contracts
--	AND cth.CT_ANAL_CODE IN ('T/E1','T/E4','T/ES','T/GP')		-- Use for Tendered Establishment Contracts
--	AND cth.CT_ANAL_CODE = 'T/MA'								-- Use for Tendered Maintenance Contracts
--	AND cth.CT_ANAL_CODE = 'ROAD'								-- Use for Road Contracts
--	AND cth.CT_ANAL_CODE = 'HAUL'								-- Use for Haulage Contracts
--	AND cth.CT_ANAL_CODE = 'HARV'								-- Use for Harvesting Contracts
	AND cth.CT_PLAN_END >  '2016-08-15'							-- Cutoff Date to be agreed with Finance for expiry of contracts in FIS

GO



/*
*  Contract Lines  - use one field as an identifier of migrated data (RB)
*/

/* Columns in Contract Lines query
   CTR_CODE, 
   CT_NO, 
   CT_DATE, 
   CT_PLAN_START, 
   CT_PLAN_END, 
   CT_AUTHORIZER, 
   CT_MANAGER, 
   CT_ANAL_CODE, 
   LAST_GRN_DATE, 
   CT_VALUE, 
   CT_VALUE_RECEIVED, 
   CT_PRINTED, 
   CT_ISSUED, 
   SW_NOTIFIED, 
   NEAR_COMP_NOTIFIED, 
   CT_INS_CERT_PRINTED, 
   CT_INS_TYPE, 
   CT_TYPE, 
   CT_TYPE_ABBREV, 
   CT_STATUS, 
   CT_STATUS_SHORT, 
   CT_SPECIFIC, 
   CT_SPECIFIC_DESC, 
   CT_PAY_FREQUENCY, 
   CT_LINE_NO, 
   OP_CODE, 
   OP_NAME, 
   OP_SNAME, 
   SUB_OP_NO, 
   SUB_OP_NAME, 
   SUB_OP_SNAME, 
   CTL_STATUS, 
   FOREST_CODE, 
   TEAM_MEMBER, 
   CONTRACT_UNIT, 
   CT_QTY, 
   CT_PRICE, 
   CT_QTY_RECEIVED, 
   PLANTING_YEAR, 
   SPECIES_CODE, 
   HAUL_DEST, 
   HAUL_DEST_NAME, 
   VALUE_RECEIVED, 
   CTR_NAME, 
   CTR_TAX_REF, 
   NURSERY_LOCATION, 
   CTL_LOCATION_1, 
   CTL_LOCATION_DESC, 
   CT_BALANCE, 
   CTL_BALANCE_QTY, 
   CTL_BALANCE_VALUE, 
   CTL_VALUE, 
   CTR_ADDRESS_LINE_1, 
   CTR_ADDRESS_LINE_2, 
   CTR_ADDRESS_LINE_3, 
   CTR_ADDRESS_LINE_4, 
   CTR_ADDRESS_LINE_5, 
   CTR_ADDRESS_LINE_6, 
   AUTHORISER_REGION, 
   AUTHORISER_CT_LIMIT
   */

      SELECT 
      cth.CTR_CODE, 
      cth.CT_NO, 
      cth.CT_DATE, 
      cth.CT_PLAN_START, 
      cth.CT_PLAN_END, 
      cth.CT_AUTHORIZER, 
      cth.CT_MANAGER, 
      cth.CT_ANAL_CODE, 
      cth.LAST_GRN_DATE, 
      cth.CT_VALUE / 100 AS CT_VALUE, 
      cth.CT_VALUE_RECEIVED / 100 AS CT_VALUE_RECEIVED, 
      cth.CT_PRINTED, 
      cth.CT_ISSUED, 
      cth.SW_NOTIFIED, 
      cth.NEAR_COMP_NOTIFIED, 
      cth.CT_INS_CERT_PRINTED, 
      cth.CT_INS_TYPE, 
      cth.CT_TYPE, 
      CASE cth.CT_TYPE
         WHEN 'C' THEN 'C2'
         WHEN 'G' THEN 'Gen.'
         WHEN 'P' THEN 'Prof'
         ELSE cth.CT_TYPE
      END AS CT_TYPE_ABBREV, 
      cth.CT_STATUS, 
      CASE cth.CT_STATUS
         WHEN 'G' THEN 'Gen''ed'
         WHEN 'U' THEN 'Unauth'
         WHEN 'A' THEN 'Auth''d'
         WHEN 'H' THEN 'Held'
         WHEN 'C' THEN 'Complt'
         WHEN 'X' THEN 'Cancld'
         WHEN 'W' THEN 'WrkRec'
         ELSE cth.CT_STATUS
      END AS CT_STATUS_SHORT, 
      cth.CT_SPECIFIC, 
      CASE cth.CT_SPECIFIC
         WHEN 'Y' THEN 'Spec'
         ELSE 'Unsp'
      END AS CT_SPECIFIC_DESC, 
      cth.CT_PAY_FREQUENCY, 
      ctl.CT_LINE_NO, 
      ctl.OP_CODE, 
      
         (
            SELECT op.OP_NAME
            FROM #TEMP_OPERATIONS  AS op
            WHERE ctl.OP_CODE IS NOT NULL AND op.OP_CODE = ctl.OP_CODE
         ) AS OP_NAME, 
      
         (
            SELECT op.OP_SNAME
            FROM #TEMP_OPERATIONS  AS op
            WHERE ctl.OP_CODE IS NOT NULL AND op.OP_CODE = ctl.OP_CODE
         ) AS OP_SNAME, 
      ctl.SUB_OP_NO, 
      
         (
            SELECT sop.SUB_OP_NAME
            FROM #TEMP_SUB_OPERATIONS  AS sop
            WHERE 
               ctl.OP_CODE IS NOT NULL AND 
               ctl.SUB_OP_NO IS NOT NULL AND 
               sop.OP_CODE = ctl.OP_CODE AND 
               sop.SUB_OP_NO = ctl.SUB_OP_NO
         ) AS SUB_OP_NAME, 
      
         (
            SELECT sop.SUB_OP_SNAME
            FROM #TEMP_SUB_OPERATIONS  AS sop
            WHERE 
               ctl.OP_CODE IS NOT NULL AND 
               ctl.SUB_OP_NO IS NOT NULL AND 
               sop.OP_CODE = ctl.OP_CODE AND 
               sop.SUB_OP_NO = ctl.SUB_OP_NO
         ) AS SUB_OP_SNAME, 
      ctl.CTL_STATUS, 
      ctl.FOREST_CODE, 
      ctl.TEAM_MEMBER, 
      ctl.CONTRACT_UNIT, 
      ctl.CT_QTY / 1000 AS CT_QTY, 
      ctl.CT_PRICE / 10000 AS CT_PRICE, 
      ctl.CT_QTY_RECEIVED / 1000 AS CT_QTY_RECEIVED, 
      ctl.PLANTING_YEAR, 
      ctl.SPECIES_CODE, 
      ctl.HAUL_DEST, 
      
         (
            SELECT hd.HAUL_DEST_NAME
            FROM #TEMP_HAUL_DESTS  AS hd
            WHERE ctl.HAUL_DEST IS NOT NULL AND hd.HAUL_DEST = ctl.HAUL_DEST
         ) AS HAUL_DEST_NAME, 
      ctl.VALUE_RECEIVED / 100 AS VALUE_RECEIVED, 
      ctr.CTR_NAME, 
      ctr.CTR_TAX_REF, 
      ISNULL(CAST(ctl.PLANTING_YEAR as nvarchar), '') + ' ' + ISNULL(ltrim(rtrim(ctl.SPECIES_CODE)), '') AS NURSERY_LOCATION, 
      CASE 
         WHEN rtrim(ltrim(ctl.WR_LOCATION)) IS NOT NULL AND isnull(ctl.WR_LOC_TYPE, ' ') IN ( 'S', 'R' ) THEN ISNULL(substring(ctl.WR_LOCATION, 1, 4), '') + '-' + ISNULL(substring(ctl.WR_LOCATION, 5, 6), '')
         WHEN rtrim(ltrim(ctl.WR_LOCATION)) IS NOT NULL THEN ctl.WR_LOCATION
         WHEN isnull(CAST(ctl.PLANTING_YEAR as nvarchar), 0) <> 0 OR ltrim(rtrim(ctl.SPECIES_CODE)) IS NOT NULL THEN ISNULL(CAST(ctl.PLANTING_YEAR as nvarchar), '') + ' ' + ISNULL(ltrim(rtrim(ctl.SPECIES_CODE)), '')
         ELSE ' '
      END AS CTL_LOCATION_1, 
      CASE 
         WHEN rtrim(ltrim(ctl.WR_LOCATION)) IS NOT NULL AND isnull(ctl.WR_LOC_TYPE, ' ') IN ( 'S', 'R' ) THEN ISNULL(substring(ctl.WR_LOCATION, 1, 4), '') + '-' + ISNULL(substring(ctl.WR_LOCATION, 5, 6), '')
         ELSE ctl.WR_LOCATION
      END AS CTL_LOCATION_DESC, 
      CASE 
         WHEN isnull(cth.CT_STATUS, ' ') IN ( 'A', 'H', 'W' ) AND isnull(cth.CT_VALUE, 0) > isnull(cth.CT_VALUE_RECEIVED, 0) THEN isnull(cth.CT_VALUE, 0) - isnull(cth.CT_VALUE_RECEIVED, 0)
         ELSE 0
      END / 100 AS CT_BALANCE, 
      CASE 
         WHEN isnull(cth.CT_STATUS, ' ') IN ( 'A', 'H', 'W' ) AND isnull(ctl.CT_QTY, 0) > isnull(ctl.CT_QTY_RECEIVED, 0) THEN isnull(ctl.CT_QTY, 0) - isnull(ctl.CT_QTY_RECEIVED, 0)
         ELSE 0
      END / 1000 AS CTL_BALANCE_QTY, 
      CASE 
         WHEN isnull(cth.CT_STATUS, ' ') IN ( 'A', 'H', 'W' ) AND isnull(ctl.CT_QTY, 0) > isnull(ctl.CT_QTY_RECEIVED, 0) THEN (isnull(ctl.CT_QTY, 0) - isnull(ctl.CT_QTY_RECEIVED, 0)) * isnull(ctl.CT_PRICE, 0) / 100000
         ELSE 0
      END / 100 AS CTL_BALANCE_VALUE, 
      isnull(ctl.CT_QTY, 0) * isnull(ctl.CT_PRICE, 0) / 10000000 AS CTL_VALUE, 
      cta.CTR_ADDRESS_LINE_1, 
      cta.CTR_ADDRESS_LINE_2, 
      cta.CTR_ADDRESS_LINE_3, 
      cta.CTR_ADDRESS_LINE_4, 
      cta.CTR_ADDRESS_LINE_5, 
      cta.CTR_ADDRESS_LINE_6, 
      auth.DIVISION_CODE AS AUTHORISER_REGION, 
      auth.CT_LIMIT AS AUTHORISER_CT_LIMIT
   FROM 
      #TEMP_CT_HEADS  AS cth 
         LEFT OUTER JOIN #TEMP_CT_LINES  AS ctl 
         ON ctl.CT_NO = cth.CT_NO 
         LEFT OUTER JOIN #TEMP_CTRS  AS ctr 
         ON ctr.CTR_CODE = cth.CTR_CODE 
         LEFT OUTER JOIN #TEMP_CTR_ADDRESSES  AS cta 
         ON cta.CTR_CODE = ctr.CTR_CODE 
         LEFT OUTER JOIN #TEMP_CT_USERS  AS auth 
         ON auth.USERNAME = cth.CT_AUTHORIZER
   -- CONTRACT CRITERIA
   WHERE cth.CT_STATUS IN ('A', 'H', 'W')
	AND cth.CT_ANAL_CODE = 'ESTB'								-- Use for Establishment Contracts
--	AND cth.CT_ANAL_CODE IN ('T/E1','T/E4','T/ES','T/GP')		-- Use for Tendered Establishment Contracts
--	AND cth.CT_ANAL_CODE = 'T/MA'								-- Use for Tendered Maintenance Contracts
--	AND cth.CT_ANAL_CODE = 'ROAD'								-- Use for Road Contracts
--	AND cth.CT_ANAL_CODE = 'HAUL'								-- Use for Haulage Contracts
--	AND cth.CT_ANAL_CODE = 'HARV'								-- Use for Harvesting Contracts
	AND cth.CT_PLAN_END >  '2016-08-15'							-- Cutoff Date to be agreed with Finance for expiry of contracts in FIS


AND cth.CT_NO = 'K1201265'
ORDER BY ctl.CT_LINE_NO
---------------------------------------------------------------------------------------------------------------------------------------------

SELECT OP_CODE, OP_NAME, SUB_OP_NO, SUB_OP_NAME FROM 
(
      SELECT 
 
      ctl.OP_CODE, 
      
         (
            SELECT op.OP_NAME
            FROM #TEMP_OPERATIONS  AS op
            WHERE ctl.OP_CODE IS NOT NULL AND op.OP_CODE = ctl.OP_CODE
         ) AS OP_NAME, 
      
         (
            SELECT op.OP_SNAME
            FROM #TEMP_OPERATIONS  AS op
            WHERE ctl.OP_CODE IS NOT NULL AND op.OP_CODE = ctl.OP_CODE
         ) AS OP_SNAME, 
      ctl.SUB_OP_NO, 
      
         (
            SELECT sop.SUB_OP_NAME
            FROM #TEMP_SUB_OPERATIONS  AS sop
            WHERE 
               ctl.OP_CODE IS NOT NULL AND 
               ctl.SUB_OP_NO IS NOT NULL AND 
               sop.OP_CODE = ctl.OP_CODE AND 
               sop.SUB_OP_NO = ctl.SUB_OP_NO
         ) AS SUB_OP_NAME, 
      
         (
            SELECT sop.SUB_OP_SNAME
            FROM #TEMP_SUB_OPERATIONS  AS sop
            WHERE 
               ctl.OP_CODE IS NOT NULL AND 
               ctl.SUB_OP_NO IS NOT NULL AND 
               sop.OP_CODE = ctl.OP_CODE AND 
               sop.SUB_OP_NO = ctl.SUB_OP_NO
         ) AS SUB_OP_SNAME
      
   FROM 
      #TEMP_CT_HEADS  AS cth 
         LEFT OUTER JOIN #TEMP_CT_LINES  AS ctl 
         ON ctl.CT_NO = cth.CT_NO 
         LEFT OUTER JOIN #TEMP_CTRS  AS ctr 
         ON ctr.CTR_CODE = cth.CTR_CODE 
         LEFT OUTER JOIN #TEMP_CTR_ADDRESSES  AS cta 
         ON cta.CTR_CODE = ctr.CTR_CODE 
         LEFT OUTER JOIN #TEMP_CT_USERS  AS auth 
         ON auth.USERNAME = cth.CT_AUTHORIZER
   -- CONTRACT CRITERIA
   WHERE cth.CT_STATUS IN ('A', 'H', 'W')
	AND cth.CT_ANAL_CODE = 'ESTB'								-- Use for Establishment Contracts
--	AND cth.CT_ANAL_CODE IN ('T/E1','T/E4','T/ES','T/GP')		-- Use for Tendered Establishment Contracts
--	AND cth.CT_ANAL_CODE = 'T/MA'								-- Use for Tendered Maintenance Contracts
--	AND cth.CT_ANAL_CODE = 'ROAD'								-- Use for Road Contracts
--	AND cth.CT_ANAL_CODE = 'HAUL'								-- Use for Haulage Contracts
--	AND cth.CT_ANAL_CODE = 'HARV'								-- Use for Harvesting Contracts
	AND cth.CT_PLAN_END >  '2016-08-15'							-- Cutoff Date to be agreed with Finance for expiry of contracts in FIS
) A

GROUP BY OP_CODE, OP_NAME, SUB_OP_NO, SUB_OP_NAME
ORDER BY OP_CODE, OP_NAME, SUB_OP_NO, SUB_OP_NAME


SELECT cth.CT_AUTHORIZER
FROM #TEMP_CT_HEADS  AS cth
   -- CONTRACT CRITERIA
   WHERE cth.CT_STATUS IN ('A', 'H', 'W')
	AND (cth.CT_ANAL_CODE = 'ESTB'								-- Use for Establishment Contracts
	OR cth.CT_ANAL_CODE IN ('T/E1','T/E4','T/ES','T/GP')		-- Use for Tendered Establishment Contracts
	OR cth.CT_ANAL_CODE = 'T/MA'								-- Use for Tendered Maintenance Contracts
	OR cth.CT_ANAL_CODE = 'ROAD'								-- Use for Road Contracts
	OR cth.CT_ANAL_CODE = 'HAUL'								-- Use for Haulage Contracts
	OR cth.CT_ANAL_CODE = 'HARV')								-- Use for Harvesting Contracts
	AND cth.CT_PLAN_END >  '2016-08-15'							-- Cutoff Date to be agreed with Finance for expiry of contracts in FIS

GROUP BY cth.CT_AUTHORIZER

SELECT cth.CT_AUTHORIZER, CT_STATUS
FROM #TEMP_CT_HEADS  AS cth
WHERE cth.CT_STATUS IN ('A', 'H', 'W')
	AND (cth.CT_ANAL_CODE = 'ESTB'								-- Use for Establishment Contracts
	OR cth.CT_ANAL_CODE IN ('T/E1','T/E4','T/ES','T/GP')		-- Use for Tendered Establishment Contracts
	OR cth.CT_ANAL_CODE = 'T/MA'								-- Use for Tendered Maintenance Contracts
	OR cth.CT_ANAL_CODE = 'ROAD'								-- Use for Road Contracts
	OR cth.CT_ANAL_CODE = 'HAUL'								-- Use for Haulage Contracts
	OR cth.CT_ANAL_CODE = 'HARV')								-- Use for Harvesting Contracts
	AND cth.CT_PLAN_END >  '2016-08-15'							-- Cutoff Date to be agreed with Finance for expiry of contracts in FIS
	AND LEN(cth.CT_AUTHORIZER) > 2


-----------------------------------------------------------------------------------------------------------------------------------------

SELECT 
      cth.CTR_CODE, 
      cth.CT_NO, 
      cth.CT_DATE, 
      cth.CT_PLAN_START, 
      cth.CT_PLAN_END, 
      cth.CT_AUTHORIZER, 
      cth.CT_MANAGER, 
      cth.CT_ANAL_CODE, 
      cth.LAST_GRN_DATE, 
      cth.CT_VALUE / 100 AS CT_VALUE, 
      cth.CT_VALUE_RECEIVED / 100 AS CT_VALUE_RECEIVED, 
      cth.CT_PRINTED, 
      cth.CT_ISSUED, 
      cth.SW_NOTIFIED, 
      cth.NEAR_COMP_NOTIFIED, 
      cth.CT_INS_CERT_PRINTED, 
      cth.CT_INS_TYPE, 
      cth.CT_TYPE, 
      CASE cth.CT_TYPE
         WHEN 'C' THEN 'C2'
         WHEN 'G' THEN 'Gen.'
         WHEN 'P' THEN 'Prof'
         ELSE cth.CT_TYPE
      END AS CT_TYPE_ABBREV, 
      cth.CT_STATUS, 
      CASE cth.CT_STATUS
         WHEN 'G' THEN 'Gen''ed'
         WHEN 'U' THEN 'Unauth'
         WHEN 'A' THEN 'Auth''d'
         WHEN 'H' THEN 'Held'
         WHEN 'C' THEN 'Complt'
         WHEN 'X' THEN 'Cancld'
         WHEN 'W' THEN 'WrkRec'
         ELSE cth.CT_STATUS
      END AS CT_STATUS_SHORT, 
      cth.CT_SPECIFIC, 
      CASE cth.CT_SPECIFIC
         WHEN 'Y' THEN 'Spec'
         ELSE 'Unsp'
      END AS CT_SPECIFIC_DESC, 
      cth.CT_PAY_FREQUENCY, 
      ctl.CT_LINE_NO, 
      ctl.OP_CODE, 
      
         (
            SELECT op.OP_NAME
            FROM #TEMP_OPERATIONS  AS op
            WHERE ctl.OP_CODE IS NOT NULL AND op.OP_CODE = ctl.OP_CODE
         ) AS OP_NAME, 
      
         (
            SELECT op.OP_SNAME
            FROM #TEMP_OPERATIONS  AS op
            WHERE ctl.OP_CODE IS NOT NULL AND op.OP_CODE = ctl.OP_CODE
         ) AS OP_SNAME, 
      ctl.SUB_OP_NO, 
      
         (
            SELECT sop.SUB_OP_NAME
            FROM #TEMP_SUB_OPERATIONS  AS sop
            WHERE 
               ctl.OP_CODE IS NOT NULL AND 
               ctl.SUB_OP_NO IS NOT NULL AND 
               sop.OP_CODE = ctl.OP_CODE AND 
               sop.SUB_OP_NO = ctl.SUB_OP_NO
         ) AS SUB_OP_NAME, 
      
         (
            SELECT sop.SUB_OP_SNAME
            FROM #TEMP_SUB_OPERATIONS  AS sop
            WHERE 
               ctl.OP_CODE IS NOT NULL AND 
               ctl.SUB_OP_NO IS NOT NULL AND 
               sop.OP_CODE = ctl.OP_CODE AND 
               sop.SUB_OP_NO = ctl.SUB_OP_NO
         ) AS SUB_OP_SNAME, 
      ctl.CTL_STATUS, 
      ctl.FOREST_CODE, 
      ctl.TEAM_MEMBER, 
      ctl.CONTRACT_UNIT, 
      ctl.CT_QTY / 1000 AS CT_QTY, 
      ctl.CT_PRICE / 10000 AS CT_PRICE, 
      ctl.CT_QTY_RECEIVED / 1000 AS CT_QTY_RECEIVED, 
      ctl.PLANTING_YEAR, 
      ctl.SPECIES_CODE, 
      ctl.HAUL_DEST, 
      
         (
            SELECT hd.HAUL_DEST_NAME
            FROM #TEMP_HAUL_DESTS  AS hd
            WHERE ctl.HAUL_DEST IS NOT NULL AND hd.HAUL_DEST = ctl.HAUL_DEST
         ) AS HAUL_DEST_NAME, 
      ctl.VALUE_RECEIVED / 100 AS VALUE_RECEIVED, 
      ctr.CTR_NAME, 
      ctr.CTR_TAX_REF, 
      ISNULL(CAST(ctl.PLANTING_YEAR as nvarchar), '') + ' ' + ISNULL(ltrim(rtrim(ctl.SPECIES_CODE)), '') AS NURSERY_LOCATION, 
      CASE 
         WHEN rtrim(ltrim(ctl.WR_LOCATION)) IS NOT NULL AND isnull(ctl.WR_LOC_TYPE, ' ') IN ( 'S', 'R' ) THEN ISNULL(substring(ctl.WR_LOCATION, 1, 4), '') + '-' + ISNULL(substring(ctl.WR_LOCATION, 5, 6), '')
         WHEN rtrim(ltrim(ctl.WR_LOCATION)) IS NOT NULL THEN ctl.WR_LOCATION
         WHEN isnull(CAST(ctl.PLANTING_YEAR as nvarchar), 0) <> 0 OR ltrim(rtrim(ctl.SPECIES_CODE)) IS NOT NULL THEN ISNULL(CAST(ctl.PLANTING_YEAR as nvarchar), '') + ' ' + ISNULL(ltrim(rtrim(ctl.SPECIES_CODE)), '')
         ELSE ' '
      END AS CTL_LOCATION_1, 
      CASE 
         WHEN rtrim(ltrim(ctl.WR_LOCATION)) IS NOT NULL AND isnull(ctl.WR_LOC_TYPE, ' ') IN ( 'S', 'R' ) THEN ISNULL(substring(ctl.WR_LOCATION, 1, 4), '') + '-' + ISNULL(substring(ctl.WR_LOCATION, 5, 6), '')
         ELSE ctl.WR_LOCATION
      END AS CTL_LOCATION_DESC, 
      CASE 
         WHEN isnull(cth.CT_STATUS, ' ') IN ( 'A', 'H', 'W' ) AND isnull(cth.CT_VALUE, 0) > isnull(cth.CT_VALUE_RECEIVED, 0) THEN isnull(cth.CT_VALUE, 0) - isnull(cth.CT_VALUE_RECEIVED, 0)
         ELSE 0
      END / 100 AS CT_BALANCE, 
      CASE 
         WHEN isnull(cth.CT_STATUS, ' ') IN ( 'A', 'H', 'W' ) AND isnull(ctl.CT_QTY, 0) > isnull(ctl.CT_QTY_RECEIVED, 0) THEN isnull(ctl.CT_QTY, 0) - isnull(ctl.CT_QTY_RECEIVED, 0)
         ELSE 0
      END / 1000 AS CTL_BALANCE_QTY, 
      CASE 
         WHEN isnull(cth.CT_STATUS, ' ') IN ( 'A', 'H', 'W' ) AND isnull(ctl.CT_QTY, 0) > isnull(ctl.CT_QTY_RECEIVED, 0) THEN (isnull(ctl.CT_QTY, 0) - isnull(ctl.CT_QTY_RECEIVED, 0)) * isnull(ctl.CT_PRICE, 0) / 100000
         ELSE 0
      END / 100 AS CTL_BALANCE_VALUE, 
      isnull(ctl.CT_QTY, 0) * isnull(ctl.CT_PRICE, 0) / 10000000 AS CTL_VALUE, 
      cta.CTR_ADDRESS_LINE_1, 
      cta.CTR_ADDRESS_LINE_2, 
      cta.CTR_ADDRESS_LINE_3, 
      cta.CTR_ADDRESS_LINE_4, 
      cta.CTR_ADDRESS_LINE_5, 
      cta.CTR_ADDRESS_LINE_6, 
      auth.DIVISION_CODE AS AUTHORISER_REGION, 
      auth.CT_LIMIT AS AUTHORISER_CT_LIMIT,
         CTL.WR_LOC_TYPE,
          (SELECT COUNT(*)
             FROM #TEMP_GRN_LINES CWRL 
                WHERE CTL.CT_NO      = CWRL.CT_NO 
                  AND CTL.CT_LINE_NO = CWRL.CT_LINE_NO
              ) AS NO_OF_CWR_LINES,
         (CASE 
          WHEN CTL.WR_LOC_TYPE IN ('D','M')
           AND CTL.WR_LOCATION != ' '
              AND (SELECT E.COST_CENTRE 
                        FROM #TEMP_IPC_PLAN_ENTITIES E 
                       WHERE CTL.WR_LOCATION = E.ENTITY_ID
                     ) IS NOT NULL
          THEN -- Use the entity on the contract line
               (SELECT E.COST_CENTRE 
                        FROM #TEMP_IPC_PLAN_ENTITIES E 
                       WHERE CTL.WR_LOCATION = E.ENTITY_ID
                     )
          WHEN CTL.WR_LOC_TYPE IN ('F','P')
           AND CTL.WR_LOCATION != ' '
              AND (SELECT E.COST_CENTRE 
                        FROM #TEMP_IPC_PLAN_ENTITIES E 
                       INNER JOIN #TEMP_FORESTS F ON E.COST_CENTRE = F.FOREST_CODE AND F.REALLY_A_FOREST = 'Y'
                       WHERE CTL.WR_LOCATION = E.ENTITY_ID
                     ) IS NOT NULL
          THEN -- Use the entity on the contract line
               (SELECT E.COST_CENTRE 
                        FROM #TEMP_IPC_PLAN_ENTITIES E 
                       INNER JOIN #TEMP_FORESTS F ON E.COST_CENTRE = F.FOREST_CODE AND F.REALLY_A_FOREST = 'Y'
                       WHERE CTL.WR_LOCATION = E.ENTITY_ID
                     )
          WHEN -- lookup and CWRs using the contract number and line number
               (SELECT MAX(E.COST_CENTRE) 
                        FROM #TEMP_GRN_LINES CWRL 
                       INNER JOIN #TEMP_IPC_PLAN_ENTITIES E ON CWRL.WR_LOCATION = E.ENTITY_ID
                       INNER JOIN #TEMP_FORESTS F ON E.COST_CENTRE = F.FOREST_CODE AND F.REALLY_A_FOREST = 'Y'
                       WHERE CTL.CT_NO      = CWRL.CT_NO 
                         AND CTL.CT_LINE_NO = CWRL.CT_LINE_NO
                     ) IS NOT NULL
          THEN
               (SELECT MAX(E.COST_CENTRE) 
                        FROM #TEMP_GRN_LINES CWRL 
                       INNER JOIN #TEMP_IPC_PLAN_ENTITIES E ON CWRL.WR_LOCATION = E.ENTITY_ID
                       INNER JOIN #TEMP_FORESTS F ON E.COST_CENTRE = F.FOREST_CODE AND F.REALLY_A_FOREST = 'Y'
                       WHERE CTL.CT_NO      = CWRL.CT_NO 
                         AND CTL.CT_LINE_NO = CWRL.CT_LINE_NO
                     )
          WHEN -- lookup and CWRs using the contract number only
               (SELECT MAX(E.COST_CENTRE) 
                        FROM #TEMP_GRN_LINES CWRL 
                       INNER JOIN #TEMP_IPC_PLAN_ENTITIES E ON CWRL.WR_LOCATION = E.ENTITY_ID
                       INNER JOIN #TEMP_FORESTS F ON E.COST_CENTRE = F.FOREST_CODE AND F.REALLY_A_FOREST = 'Y'
                       WHERE CTL.CT_NO      = CWRL.CT_NO 
                      ) IS NOT NULL
          THEN
               (SELECT MAX(E.COST_CENTRE) 
                        FROM #TEMP_GRN_LINES CWRL 
                       INNER JOIN #TEMP_IPC_PLAN_ENTITIES E ON CWRL.WR_LOCATION = E.ENTITY_ID
                       INNER JOIN #TEMP_FORESTS F ON E.COST_CENTRE = F.FOREST_CODE AND F.REALLY_A_FOREST = 'Y'
                       WHERE CTL.CT_NO      = CWRL.CT_NO 
                      )
          ELSE  (Case ct_manager
              When 'BRADY_P'      Then 'CN02'
              When 'BROPHY_C'     Then 'CN04'
              When 'BUCKLEY_G'    Then 'LS06'
              When 'BUCKLEY_G'    Then 'LS06'
              When 'BYRNE_RI'     Then 'KK06'
			  When 'CONNOLLY_J'   Then 'WH04'
              When 'DONNELLAN_M'  Then 'GY18'
              When 'FINN_J'       Then 'MO25'
              When 'FLANAGAN_F'   Then 'GY25'
              When 'GALVIN_J'     Then 'CK13'
              When 'JACK_R'       Then 'LS01'
              When 'JONCA_P'      Then 'TY17'
              When 'KILCULLEN_M'  Then 'MO08'
              When 'LYONS_P'      Then 'CE03'
              When 'MCGARRAGHY_B' Then 'LM03'
              When 'MCGLOIN_P'    Then 'CW01'
              When 'MOLONEY_K'    Then 'DL24'
              When 'MOORE_JG'     Then 'LK03'
              When 'MUNGOVAN_P'   Then 'CK01'
              When 'OHALLORAN_J'  Then 'WD08'
              When 'OLOUGHLIN_M'  Then 'CE02'
              When 'OREGAN_W'     Then 'CK19'
              When 'QUINN_TO'     Then 'CN06'
              When 'SWEETMAN_L'   Then 'WW09'
              When 'WALSH_A'      Then 'WW07'
              When 'WHELAN_M'     Then 'WX02'
              When 'WITKOWSKA_I'  Then 'KY03'
                       End)
          END) AS DERIVED_FOREST_CODE
   FROM 
      #TEMP_CT_HEADS  AS cth 
         LEFT OUTER JOIN #TEMP_CT_LINES  AS ctl 
         ON ctl.CT_NO = cth.CT_NO 
         LEFT OUTER JOIN #TEMP_CTRS  AS ctr 
         ON ctr.CTR_CODE = cth.CTR_CODE 
         LEFT OUTER JOIN #TEMP_CTR_ADDRESSES  AS cta 
         ON cta.CTR_CODE = ctr.CTR_CODE 
         LEFT OUTER JOIN #TEMP_CT_USERS  AS auth 
         ON auth.USERNAME = cth.CT_AUTHORIZER
   -- CONTRACT CRITERIA
   WHERE cth.CT_STATUS IN ('A', 'H', 'W')
       AND cth.CT_ANAL_CODE = 'ESTB'                                                     -- Use for Establishment Contracts
--     AND cth.CT_ANAL_CODE IN ('T/E1','T/E4','T/ES','T/GP')         -- Use for Tendered Establishment Contracts
--     AND cth.CT_ANAL_CODE = 'T/MA'                                                     -- Use for Tendered Maintenance Contracts
--     AND cth.CT_ANAL_CODE = 'ROAD'                                                     -- Use for Road Contracts
--     AND cth.CT_ANAL_CODE = 'HAUL'                                                     -- Use for Haulage Contracts
--     AND cth.CT_ANAL_CODE = 'HARV'                                                     -- Use for Harvesting Contracts
       AND cth.CT_PLAN_END >  '2016-08-15'                                               -- Cutoff Date to be agreed with Finance for expiry of contracts in FIS
ORDER BY cth.CT_NO


--------------------------------------------------------------------------------------


SELECT 

      cth.CT_NO,
	  ctl.CT_LINE_NO, 

         (CASE 
          WHEN CTL.WR_LOC_TYPE IN ('D','M')
           AND CTL.WR_LOCATION != ' '
              AND (SELECT E.COST_CENTRE 
                        FROM #TEMP_IPC_PLAN_ENTITIES E 
                       WHERE CTL.WR_LOCATION = E.ENTITY_ID
                     ) IS NOT NULL
          THEN -- Use the entity on the contract line
               (SELECT E.COST_CENTRE 
                        FROM #TEMP_IPC_PLAN_ENTITIES E 
                       WHERE CTL.WR_LOCATION = E.ENTITY_ID
                     )
          WHEN CTL.WR_LOC_TYPE IN ('F','P')
           AND CTL.WR_LOCATION != ' '
              AND (SELECT E.COST_CENTRE 
                        FROM #TEMP_IPC_PLAN_ENTITIES E 
                       INNER JOIN #TEMP_FORESTS F ON E.COST_CENTRE = F.FOREST_CODE AND F.REALLY_A_FOREST = 'Y'
                       WHERE CTL.WR_LOCATION = E.ENTITY_ID
                     ) IS NOT NULL
          THEN -- Use the entity on the contract line
               (SELECT E.COST_CENTRE 
                        FROM #TEMP_IPC_PLAN_ENTITIES E 
                       INNER JOIN #TEMP_FORESTS F ON E.COST_CENTRE = F.FOREST_CODE AND F.REALLY_A_FOREST = 'Y'
                       WHERE CTL.WR_LOCATION = E.ENTITY_ID
                     )
          WHEN -- lookup and CWRs using the contract number and line number
               (SELECT MAX(E.COST_CENTRE) 
                        FROM #TEMP_GRN_LINES CWRL 
                       INNER JOIN #TEMP_IPC_PLAN_ENTITIES E ON CWRL.WR_LOCATION = E.ENTITY_ID
                       INNER JOIN #TEMP_FORESTS F ON E.COST_CENTRE = F.FOREST_CODE AND F.REALLY_A_FOREST = 'Y'
                       WHERE CTL.CT_NO      = CWRL.CT_NO 
                         AND CTL.CT_LINE_NO = CWRL.CT_LINE_NO
                     ) IS NOT NULL
          THEN
               (SELECT MAX(E.COST_CENTRE) 
                        FROM #TEMP_GRN_LINES CWRL 
                       INNER JOIN #TEMP_IPC_PLAN_ENTITIES E ON CWRL.WR_LOCATION = E.ENTITY_ID
                       INNER JOIN #TEMP_FORESTS F ON E.COST_CENTRE = F.FOREST_CODE AND F.REALLY_A_FOREST = 'Y'
                       WHERE CTL.CT_NO      = CWRL.CT_NO 
                         AND CTL.CT_LINE_NO = CWRL.CT_LINE_NO
                     )
          WHEN -- lookup and CWRs using the contract number only
               (SELECT MAX(E.COST_CENTRE) 
                        FROM #TEMP_GRN_LINES CWRL 
                       INNER JOIN #TEMP_IPC_PLAN_ENTITIES E ON CWRL.WR_LOCATION = E.ENTITY_ID
                       INNER JOIN #TEMP_FORESTS F ON E.COST_CENTRE = F.FOREST_CODE AND F.REALLY_A_FOREST = 'Y'
                       WHERE CTL.CT_NO      = CWRL.CT_NO 
                      ) IS NOT NULL
          THEN
               (SELECT MAX(E.COST_CENTRE) 
                        FROM #TEMP_GRN_LINES CWRL 
                       INNER JOIN #TEMP_IPC_PLAN_ENTITIES E ON CWRL.WR_LOCATION = E.ENTITY_ID
                       INNER JOIN #TEMP_FORESTS F ON E.COST_CENTRE = F.FOREST_CODE AND F.REALLY_A_FOREST = 'Y'
                       WHERE CTL.CT_NO      = CWRL.CT_NO 
                      )
          ELSE  (Case ct_manager
              When 'BRADY_P'      Then 'CN02'
              When 'BROPHY_C'     Then 'CN04'
              When 'BUCKLEY_G'    Then 'LS06'
              When 'BUCKLEY_G'    Then 'LS06'
              When 'BYRNE_RI'     Then 'KK06'
			  When 'CONNOLLY_J'   Then 'WH04'
              When 'DONNELLAN_M'  Then 'GY18'
              When 'FINN_J'       Then 'MO25'
              When 'FLANAGAN_F'   Then 'GY25'
              When 'GALVIN_J'     Then 'CK13'
              When 'JACK_R'       Then 'LS01'
              When 'JONCA_P'      Then 'TY17'
              When 'KILCULLEN_M'  Then 'MO08'
              When 'LYONS_P'      Then 'CE03'
              When 'MCGARRAGHY_B' Then 'LM03'
              When 'MCGLOIN_P'    Then 'CW01'
              When 'MOLONEY_K'    Then 'DL24'
              When 'MOORE_JG'     Then 'LK03'
              When 'MUNGOVAN_P'   Then 'CK01'
              When 'OHALLORAN_J'  Then 'WD08'
              When 'OLOUGHLIN_M'  Then 'CE02'
              When 'OREGAN_W'     Then 'CK19'
              When 'QUINN_TO'     Then 'CN06'
              When 'SWEETMAN_L'   Then 'WW09'
              When 'WALSH_A'      Then 'WW07'
              When 'WHELAN_M'     Then 'WX02'
              When 'WITKOWSKA_I'  Then 'KY03'
                       End)
          END) AS DERIVED_FOREST_CODE
   FROM 
      #TEMP_CT_HEADS  AS cth 
         LEFT OUTER JOIN #TEMP_CT_LINES  AS ctl 
         ON ctl.CT_NO = cth.CT_NO 
         LEFT OUTER JOIN #TEMP_CTRS  AS ctr 
         ON ctr.CTR_CODE = cth.CTR_CODE 
         LEFT OUTER JOIN #TEMP_CTR_ADDRESSES  AS cta 
         ON cta.CTR_CODE = ctr.CTR_CODE 
         LEFT OUTER JOIN #TEMP_CT_USERS  AS auth 
         ON auth.USERNAME = cth.CT_AUTHORIZER
   -- CONTRACT CRITERIA
   WHERE cth.CT_STATUS IN ('A', 'H', 'W')
       AND cth.CT_ANAL_CODE = 'ESTB'                                                     -- Use for Establishment Contracts
--     AND cth.CT_ANAL_CODE IN ('T/E1','T/E4','T/ES','T/GP')         -- Use for Tendered Establishment Contracts
--     AND cth.CT_ANAL_CODE = 'T/MA'                                                     -- Use for Tendered Maintenance Contracts
--     AND cth.CT_ANAL_CODE = 'ROAD'                                                     -- Use for Road Contracts
--     AND cth.CT_ANAL_CODE = 'HAUL'                                                     -- Use for Haulage Contracts
--     AND cth.CT_ANAL_CODE = 'HARV'                                                     -- Use for Harvesting Contracts
       AND cth.CT_PLAN_END >  '2016-08-15'                                               -- Cutoff Date to be agreed with Finance for expiry of contracts in FIS
ORDER BY cth.CT_NO, ctl.CT_LINE_NO