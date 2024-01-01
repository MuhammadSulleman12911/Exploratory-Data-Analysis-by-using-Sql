--display all data
select * from project.dbo.sales;

--display distinct value for following attributes
select distinct PRODUCTLINE from project.dbo.sales;
select distinct STATUS from project.dbo.sales;
select distinct TERRITORY from project.dbo.sales;
select distinct COUNTRY from project.dbo.sales;
select distinct DEALSIZE from project.dbo.sales;
select distinct YEAR_ID from project.dbo.sales;

select PRODUCTLINE, SUM(SALES) REVENUE from project.dbo.sales
group by PRODUCTLINE
order by 2 desc;

select STATUS, SUM(SALES) REVENUE from project.dbo.sales
group by STATUS
order by 2 desc;

select DEALSIZE, SUM(SALES) REVENUE from project.dbo.sales
group by DEALSIZE
order by 2 desc;

select YEAR_ID, SUM(SALES) REVENUE from project.dbo.sales
group by YEAR_ID
order by 2 desc;

--display month with max sales in calender year 2004 in desc order 
select  YEAR_ID, MONTH_ID, COUNT(ORDERNUMBER) FREQUENCY ,SUM(QUANTITYORDERED) TOTALORDER ,SUM(SALES) REVENUE from project.dbo.sales
where YEAR_ID = 2004
group by MONTH_ID, YEAR_ID
order by 5 desc ;

--display month with max sales across all year in desc order 
select  YEAR_ID, MONTH_ID, SUM(SALES) REVENUE from project.dbo.sales
group by MONTH_ID, YEAR_ID
order by 1 desc, 3 desc ;

select  YEAR_ID, MONTH_ID, COUNT(ORDERNUMBER) FREQUENCY ,SUM(QUANTITYORDERED) TOTALORDER ,SUM(SALES) REVENUE from project.dbo.sales
where YEAR_ID = 2004
group by MONTH_ID, YEAR_ID
order by 5 desc ;

select  YEAR_ID, MONTH_ID,  PRODUCTLINE, COUNT(ORDERNUMBER) FREQUENCY, SUM(SALES) REVENUE from project.dbo.sales
where YEAR_ID = 2004 and MONTH_ID = 11
group by MONTH_ID, YEAR_ID, PRODUCTLINE
order by 5 desc ;




--recency from their last purchase to till date
SELECT
    CUSTOMERNAME,
    COUNT(ORDERNUMBER) AS FREQUENCY,
    SUM(SALES) AS SPEND,
    AVG(SALES) AS AVG,
    MAX(ORDERDATE) AS RECENTORDER,
    DATEDIFF(DAY, MAX(ORDERDATE), GETDATE()) AS RECENCYDAYS
FROM
    project.dbo.sales
GROUP BY
    CUSTOMERNAME


SELECT
    CUSTOMERNAME,
    COUNT(ORDERNUMBER) AS FREQUENCY,
    SUM(SALES) AS SPEND,
    AVG(SALES) AS AVG,
    MAX(ORDERDATE) AS RECENTORDER,
	(select MAX(orderdate) from  project.dbo.sales) MAXORDER,
    DATEDIFF(DAY, MAX(ORDERDATE), (select MAX(orderdate) from  project.dbo.sales))  RECENCYDAYS
FROM
    project.dbo.sales
GROUP BY
    CUSTOMERNAME
	
--calculate rfm
drop table if exists #BOI
	;with rfm as(
	SELECT
    CUSTOMERNAME,
    COUNT(ORDERNUMBER) AS FREQUENCY,
    SUM(SALES) AS SPEND,
    AVG(SALES) AS AVG,
    MAX(ORDERDATE) MOST_RECENT_ORDER,
    (select max(orderdate) from project.dbo.sales) MAX_ORDER,
	DATEDIFF(DD, MAX(ORDERDATE), (select max(orderdate) from project.dbo.sales)) RECENCY_DAYS
	
FROM
    project.dbo.sales
GROUP BY 
    CUSTOMERNAME
	),
	rfm_cal as(
	select *,
	--ntile function creates buckets 
	ntile(4) over (order by RECENCY_DAYS) RFM_RECENCY,
	ntile(4) over (order by FREQUENCY) RFM_FREQUENCY,
	ntile(4) over (order by SPEND) RFM_SPEND
	from rfm 
	)
	select *, 
	--creates new coloums for RFM calculations
	(RFM_RECENCY + RFM_FREQUENCY + RFM_SPEND) RFM_VALUE, 
	CAST(RFM_RECENCY as varchar)+ CAST(RFM_FREQUENCY as varchar)+ CAST(RFM_SPEND as varchar) RFMSTRING 
	 --into # boi now this is a temp table named boi
	INTO #BOI
	from rfm_cal

-- Define a temporary table using the SELECT INTO statement
--categroize custiomers on RFM value
SELECT CUSTOMERNAME, RFM_RECENCY, RFM_FREQUENCY, RFM_SPEND,
case when RFMSTRING in(121, 122, 112, 132, 133, 123, 143, 134, 144) then 'NEW_CUSTOMER'
when RFMSTRING in(222, 232, 233, 244, 243) then 'ACTIVE_CUSTOMER' 
when RFMSTRING in(411, 421, 412, 432, 422, 423, 433, 444) then 'LOST_CUSTOMER'
when RFMSTRING in(321, 322, 211, 344, 311, 211, 312, 332, 323, 333, 323, 334, 344) then 'SLIPPING_CUSTOMER'
end CUSTOMER_SEGMENT
from #BOI


--select * from project.dbo.sales where ORDERNUMBER = 10411

--find out which products sold together the most
select distinct ORDERNUMBER, STUFF(
--stuff replace charaters
(select ',' +  PRODUCTCODE 
from project.dbo.sales p
where ORDERNUMBER in
(
select ORDERNUMBER
from
(select ORDERNUMBER, 
COUNT(*) ORDER_FREQUENCY
from 
project.dbo.sales
where STATUS = 'SHIPPED' 
group by ORDERNUMBER) sub
where ORDER_FREQUENCY = 2)
and p.ORDERNUMBER = s.ORDERNUMBER

--convert rows into couloum
for xml path (''))
, 1, 1, '') PRODUCTCODE
from project.dbo.sales s
order by 2 desc