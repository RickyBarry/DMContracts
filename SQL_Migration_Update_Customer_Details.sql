/**********************************************************************/
/***  Update Customer Details								    	***/
/***  Created by RB Oct 2016								    	***/
/***                                                                ***/
/***  Update Customer Details										***/ 
/***	Delivered In Customer; Issue TRP; Paperless Customer		***/
/***	FROM FOPSQL01.FIS Customers and Customers_C table			***/
/***	into wts_coillte.wts_coillte.PARTY							***/
/***                                                                ***/
/***	Last modified												***/
/***                                                                ***/
/**********************************************************************/

use wts_coillte 

-- Gather the required data in to a temp table
SELECT	cst.CUSTOMER_CODE,
		cst.CUSTOMER_NAME,
		cst.CUSTOMER_NO,
		RIGHT('0000000' + CONVERT(VARCHAR,cst.CUSTOMER_NO),7) AS PartyNumber,
		CASE cst.DELIVERED_IN_CUST
			WHEN 'Y' THEN 'Yes'
			ELSE 'No'
		END AS DeliveredInCust,
		CASE cstc.ALLOW_FDS
			WHEN 'Y' THEN 'Yes'
			ELSE 'No'
		END AS IssueTRP,
		CASE cstc.EMAIL_TRP_FLAG
			WHEN 'Y' THEN 'Yes'
			ELSE 'No'
		END AS PaperlessCustomer
  INTO #CustomerDetails
  FROM	FOPSQL01.FIS.dbo.CUSTOMERS AS cst
  LEFT JOIN	FOPSQL01.FIS.dbo.CUSTOMERS_C AS cstc ON cst.CUSTOMER_CODE = cstc.CUSTOMER_CODE
  WHERE cst.CUSTOMER_NO <> 0
  AND cst.DISABLED_FLAG = 'N'
  AND cst.CUSTOMER_NAME <> ''
  
  ORDER BY CUSTOMER_NO

--Need the PartyID going with the PartyNumber to link to the SD_CPF_CUSTOMER_DETAIL table
SELECT	pty.PARTY_ID,
		csd.PartyNumber,
		csd.IssueTRP,
		csd.DeliveredInCust,
		csd.PaperlessCustomer
  INTO #PartyConnect 
  FROM wts_coillte.PARTY AS pty
  JOIN #CustomerDetails AS csd ON pty.PARTY_NUMBER = csd.PartyNumber
 
----Test
--SELECT * FROM #CustomerDetails
--WHERE PartyNumber = '0000003'
SELECT * FROM #PartyConnect
ORDER BY PARTY_ID

-- Update the fields in the SD_CPF_CUSTOMER_DETAIL table
UPDATE	wts_coillte.SD_CPF_CUSTOMER_DETAIL
  SET	ISSUE_TRP_IND = ptc.IssueTRP,
		DELIVERED_IN_IND = ptc.DeliveredInCust,
		PAPERLESS_CUSTOMER = ptc.PaperlessCustomer
  FROM	wts_coillte.SD_CPF_CUSTOMER_DETAIL AS cdl
  JOIN #PartyConnect AS ptc
  ON cdl.PARTY_ID = ptc.PARTY_ID


-- Test
-- SELECT * FROM wts_coillte.SD_CPF_CUSTOMER_DETAIL


-- Drop the temp table
  DROP TABLE #CustomerDetails
  DROP TABLE #PartyConnect