
/************************************************************************/
/* Update Customer Invoice Method                                       */
/* WTS_COILLTE.SD_CPF_CUSTOMER_DETAIL                                   */
/*                                                                      */
/* RF Sept 2016											    	        */
/*                                                                      */
/* Last modified				     								    */
/*                                                                      */
/************************************************************************/

/*** Create CUSTOMERS temp table from FIS Customers Table       ***/

USE wts_coillte

IF OBJECT_ID('tempdb..#TEMP_CUSTOMERS') IS NOT NULL DROP TABLE #TEMP_CUSTOMERS
GO


-- FIS CUSTOMERS Temp Table
SELECT *
INTO #TEMP_CUSTOMERS
FROM
OPENQUERY([FOPSQL01],'SELECT * FROM [FIS].[dbo].[CUSTOMERS]') 
GO


SELECT * FROM #TEMP_CUSTOMERS
/*** Update the SALES_METHOD and SS_INVOICE_METHOD columns ***/

UPDATE CD
SET SALES_METHOD = CUS.Default_Sales_Method,
	SS_INVOICE_METHOD = CUS.Default_LS_Sales_Method

FROM 
WTS_COILLTE.PARTY P JOIN WTS_COILLTE.SD_CPF_CUSTOMER_DETAIL CD
ON P.PARTY_ID = CD.PARTY_ID 
JOIN #TEMP_CUSTOMERS CUS
ON CUS.CUSTOMER_CODE COLLATE Latin1_General_CI_AS = P.NICKNAME

GO


UPDATE CD
SET SALES_METHOD = 'WD',
	SS_INVOICE_METHOD = 'WD'
FROM
WTS_COILLTE.PARTY P JOIN WTS_COILLTE.SD_CPF_CUSTOMER_DETAIL CD
ON P.PARTY_ID = CD.PARTY_ID 
WHERE P.NICKNAME IN ('M', 'OSB')

UPDATE CD
SET SALES_METHOD = 'SD',
	SS_INVOICE_METHOD = 'SD'
	FROM
WTS_COILLTE.PARTY P JOIN WTS_COILLTE.SD_CPF_CUSTOMER_DETAIL CD
ON P.PARTY_ID = CD.PARTY_ID 
WHERE P.NICKNAME IN ('CASH')

UPDATE CD
SET SALES_METHOD = 'SD'
	FROM
WTS_COILLTE.PARTY P JOIN WTS_COILLTE.SD_CPF_CUSTOMER_DETAIL CD
ON P.PARTY_ID = CD.PARTY_ID 
WHERE CD.SALES_METHOD = 'LS'


UPDATE CD
SET SS_INVOICE_METHOD = 'SD'
	FROM
WTS_COILLTE.PARTY P JOIN WTS_COILLTE.SD_CPF_CUSTOMER_DETAIL CD
ON P.PARTY_ID = CD.PARTY_ID 
WHERE CD.SS_INVOICE_METHOD = 'LS'


