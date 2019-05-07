#standardSQL

WITH 
  /* EVENT LOG */
  event_log AS (
    SELECT fullVisitorId, 
          TIMESTAMP_SECONDS(SAFE_CAST(visitStartTime AS INT64))  AS visitStartTime,  
          channelGrouping

    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`

    WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'

    ORDER BY fullVisitorId, visitStartTime
  ),

 /* VISITORS WHO CONVERTED */
 conversions AS (
    SELECT fullVisitorId, 
           MIN(TIMESTAMP_SECONDS(SAFE_CAST(visitStartTime AS INT64)))  AS purchasetime

    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`

    WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
     AND totals.transactions IS NOT NULL

    GROUP BY fullVisitorId

    ORDER BY fullVisitorId
  ),
  
  /* LATEST VISIT TIME FOR ALL VISITORS */
   maxtimes AS (
    SELECT fullVisitorId, 
    MAX(visitStartTime) AS maxvisittime
    
    FROM event_log
    
    GROUP BY fullVisitorId
  )

  /*== MAIN QUERY THAT UNIONS CONVERTING AND NON CONVERTING PATHS WITHA GIVEN TIME WINDOW ==*/
  
  /* CONVERTING PATHS */
  SELECT a.*,
         'conversion' AS outcome

  FROM event_log a
    INNER JOIN conversions b ON a.fullVisitorId = b.fullVisitorId  

  WHERE a.visitStartTime <= b.purchasetime 
    AND DATE_DIFF(DATE(b.purchasetime), DATE(a.visitStartTime), DAY)  <= 7

UNION ALL

  /* NON CONVERTING PATHS */
  SELECT a.*,
         'non_conversion' AS outcome

  FROM event_log a
    INNER JOIN maxtimes b ON a.fullVisitorId = b.fullVisitorId 

  WHERE a.fullVisitorId NOT IN (SELECT DISTINCT fullVisitorID FROM conversions)
   AND  DATE_DIFF(DATE(b.maxvisittime), DATE(a.visitStartTime), DAY) <= 7


