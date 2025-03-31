-- Object name : ecotax_nl_textile

WITH Data_t AS (
  SELECT 
    VBELN,
    POSNR,
    MATNR,
    REGEXP_REPLACE(MATNR, '^0+', '') AS matnr_trm,
    LFIMG,
    SPART AS Division,
    VGBEL,
    CASE
      WHEN PSTYV IN ('ZTAN', 'ZREN', 'ZRCA', 'RENN') THEN 'Carton'
      WHEN PSTYV IN ('ZSL2', 'ZSLN', 'ZSE1', 'ZRSL', 'ZRSE', 'ZRS2', 'ZFR1') THEN 'SlsItem'
      ELSE '-'
    END AS ItemType,
    ERDAT AS Order_date,
    WERKS AS Warehouse
  FROM `lips`
  WHERE MANDT = '300' AND ERDAT BETWEEN "2019-01-01" AND CURRENT_DATE() 
      AND WERKS IN ('2000', '2100') AND LFIMG > 0 
      AND SPART IN ('01', '02', '03', '04', '05')
)

, VBLEN_ AS (
  SELECT
    min(VBELN) AS min_VBELN,
    max(VBELN) AS max_VBELN
  FROM Data_t
)

, likp AS (
  SELECT 
    VBELN,
    SUBSTR(VTEXT, INSTR(VTEXT, '-') + 1) AS Delivery_type,
    VKORG AS Sales_organization
  FROM `likp`
  LEFT JOIN `tvlkt`
    ON likp.LFART = tvlkt.LFART AND tvlkt.SPRAS = 'E'
  WHERE ERDAT >= "2019-01-01" AND ERDAT < CURRENT_DATE()
      AND likp.LFART IN ('LF', 'ZF01', 'ZF02', 'ZKE')
      AND VBELN BETWEEN (SELECT min_VBELN FROM VBLEN_) 
        AND (SELECT max_VBELN FROM VBLEN_)
)

, d_1 AS (
  SELECT 
    Data_t.*,
    Delivery_type,
    Sales_organization
  FROM Data_t
  INNER JOIN likp 
    ON Data_t.VBELN = likp.VBELN
)

, vbpa AS (
  SELECT DISTINCT 
    VBELN,
    LAND1 AS Cus_Cntry
  FROM `vbpa`
  WHERE PARVW = 'WE' 
    AND VBELN BETWEEN (SELECT min_VBELN FROM VBLEN_) 
      AND (SELECT max_VBELN FROM VBLEN_)
)

, d_2 AS (
  SELECT 
    d_1.*,
    Cus_Cntry
  FROM d_1
  INNER JOIN vbpa 
    ON d_1.VBELN = vbpa.VBELN
)

, md_file AS (
  SELECT
    CountryCode AS Cus_Cntry,  
    CountryNm AS Cus_CntryNm
  FROM `excel_sheet.stg_sheet_countrycodes`  
)

, d_3 AS (
  SELECT 
    d_2.*,
    Cus_CntryNm
  FROM d_2
  LEFT JOIN md_file
    ON d_2.Cus_Cntry = md_file.Cus_Cntry
)

, nl_textile AS (
  SELECT DISTINCT
    SKU AS matnr_trm, 
    Title AS product_lines,
    epr_subjection,
    CAST(REPLACE(Net_weight_kg, ',', '.') AS NUMERIC) AS Weight_per_unit_kg,
    hs_code
  FROM `excel_sheet.stg_sheet_textile_NL`   
)

, d_7 AS (
  SELECT 
    d_3.*,
    nl_textile.* EXCEPT(matnr_trm)
  FROM d_3
  INNER JOIN nl_textile
    ON d_3.matnr_trm = nl_textile.matnr_trm
)

  SELECT DISTINCT
    order_date,
    EXTRACT(YEAR FROM Order_date) AS year,
    cus_cntry,
    cus_cntryNm,
    sales_organization,
    delivery_type,
    division,
    warehouse,
    matnr_trm AS sku,
    product_lines,
    epr_subjection,
    hs_code,
    lfimg,
    vbeln,
    weight_per_unit_kg,
    SUBSTR(hs_code, 1, 2) AS code
  FROM d_7
  WHERE cus_cntry = 'NL'
