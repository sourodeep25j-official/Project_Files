-- Creating Database, Table

create database zomato;
use zomato;

create table main(RestaurantID bigint primary key,
RestaurantName varchar(255),
CountryCode bigint,
City varchar(100),
Address text,
Locality varchar(100),
LocalityVerbose varchar(255),
Cuisines varchar(255),
Currency varchar(50),
Has_Table_booking varchar(10),
Has_Online_delivery varchar(10),
Is_delivering_now varchar(10),
Switch_to_order_menu varchar(10),
Price_range int,
Votes int,
Average_Cost_for_two int,
Rating float,
`Year Opening` int,
`Month Opening` int,
`Day Opening` int
);


select * from main limit 15000;
truncate table main;






-- 1. Build a Data Model using the Sheets in the Excel File


SELECT DISTINCT Currency FROM main WHERE Currency NOT IN (SELECT Currency FROM currency);

UPDATE main
SET Currency = 'Pounds(Œ£)'
WHERE Currency = 'Pounds(£)';

set sql_safe_updates = 0;

alter table main 
add foreign key(currency) references currency(currency);


select * from currency;
desc currency;
alter table currency modify Currency varchar(50) primary key;




select * from country;
desc country;
alter table country modify CountryID bigint primary key;

alter table main 
add foreign key(CountryCode) references country(CountryID);







/* Build a Calendar Table using the Columns Datekey_Opening ( Which has Dates from Minimum Dates and Maximum Dates)
  Add all the below Columns in the Calendar Table using the Formulas.
   A.Year
   B.Monthno
   C.Monthfullname
   D.Quarter(Q1,Q2,Q3,Q4)
   E. YearMonth ( YYYY-MMM)
   F. Weekdayno
   G.Weekdayname
   H.FinancialMOnth ( April = FM1, May= FM2  …. March = FM12)
   I. Financial Quarter ( Quarters based on Financial Month FQ-1 . FQ-2..) */
   
   
  ALTER TABLE main
ADD COLUMN Date_Opening DATE;

update main
set Date_Opening = str_to_date(concat(`Year Opening`,"-",`Month Opening`,"-",`Day Opening`),"%Y-%m-%d");

select * from main limit 10000;



# Calendar Table

CREATE TABLE Calendar_Table (
    Date_opening DATE PRIMARY KEY,
    Year INT,
    Monthno INT,
    Monthfullname VARCHAR(20),
    Quarter VARCHAR(3),
    YearMonth VARCHAR(10),
    Weekdayno INT,
    Weekdayname VARCHAR(10),
    FinancialMonth VARCHAR(5),
    FinancialQuarter VARCHAR(5)
);

    
    

INSERT INTO Calendar_Table (Date_opening)
SELECT
    ADDDATE(
        (SELECT MIN(Date_opening) FROM main),
        INTERVAL t4.num * 1000 + t3.num * 100 + t2.num * 10 + t1.num DAY
    ) AS generated_date
FROM 
    (SELECT 0 AS num UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
     UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t1,
    (SELECT 0 AS num UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
     UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t2,
    (SELECT 0 AS num UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
     UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t3,
    (SELECT 0 AS num UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
     UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t4
WHERE
    ADDDATE((SELECT MIN(Date_opening) FROM main), 
    INTERVAL t4.num * 1000 + t3.num * 100 + t2.num * 10 + t1.num DAY) <= (SELECT MAX(Date_opening) FROM main);

    
    
    
UPDATE Calendar_Table
SET
    Year = YEAR(Date_opening),
    Monthno = MONTH(Date_opening),
    Monthfullname = MONTHNAME(Date_opening),
    Quarter = CONCAT('Q', QUARTER(Date_opening)),
    YearMonth = DATE_FORMAT(Date_opening, '%Y-%b'),
    Weekdayno = DAYOFWEEK(Date_opening),  -- Sunday = 1 ... Saturday = 7
    Weekdayname = DAYNAME(Date_opening),

    FinancialMonth = CASE 
        WHEN MONTH(Date_opening) = 4 THEN 'FM1'
        WHEN MONTH(Date_opening) = 5 THEN 'FM2'
        WHEN MONTH(Date_opening) = 6 THEN 'FM3'
        WHEN MONTH(Date_opening) = 7 THEN 'FM4'
        WHEN MONTH(Date_opening) = 8 THEN 'FM5'
        WHEN MONTH(Date_opening) = 9 THEN 'FM6'
        WHEN MONTH(Date_opening) = 10 THEN 'FM7'
        WHEN MONTH(Date_opening) = 11 THEN 'FM8'
        WHEN MONTH(Date_opening) = 12 THEN 'FM9'
        WHEN MONTH(Date_opening) = 1 THEN 'FM10'
        WHEN MONTH(Date_opening) = 2 THEN 'FM11'
        WHEN MONTH(Date_opening) = 3 THEN 'FM12'
    END,

    FinancialQuarter = CASE
        WHEN MONTH(Date_opening) BETWEEN 4 AND 6 THEN 'FQ1'
        WHEN MONTH(Date_opening) BETWEEN 7 AND 9 THEN 'FQ2'
        WHEN MONTH(Date_opening) BETWEEN 10 AND 12 THEN 'FQ3'
        WHEN MONTH(Date_opening) BETWEEN 1 AND 3 THEN 'FQ4'
    END;



select * from calendar_table; 





-- 3. Convert the Average cost for 2 column into USD dollars (currently the Average cost for 2 in local currencies

alter table currency rename column `USD Rate`to USD_Rate;
select * from currency;

SELECT m.RestaurantID, m.RestaurantName, m.Currency, m.Average_Cost_for_two, c.USD_Rate,
(m.Average_Cost_for_two * c.USD_Rate) AS Average_Cost_for_two_USD
FROM main m
JOIN 
currency c ON m.Currency = c.Currency
order by m.Average_Cost_for_two
limit 10000;





-- 4.Find the Numbers of Resturants based on City and Country

SELECT c.CountryName, m.City, COUNT(*) AS Number_of_Restaurants
FROM main m
JOIN 
country c ON m.CountryCode = c.CountryID
GROUP BY c.CountryName, m.City
ORDER BY c.CountryName, m.City;






-- 5.Numbers of Resturants opening based on Year , Quarter , Month

select * from calendar_table;

SELECT cal.Year, cal.Quarter, cal.Monthfullname, COUNT(DISTINCT restaurantid) AS total_restaurants
FROM main m
JOIN calendar_table cal
ON m.`Year Opening` = cal.Year
AND m.`Month Opening` = cal.Monthno
GROUP BY cal.Year, cal.Quarter, cal.Monthfullname
ORDER BY cal.Year, cal.Quarter, cal.Monthfullname;







-- 6. Count of Resturants based on Average Ratings

SELECT ROUND(Rating, 1) AS AvgRating,
COUNT(*) AS RestaurantCount
FROM main
GROUP BY AvgRating
ORDER BY AvgRating DESC;
    
    
SELECT ROUND(avg_rating, 1) AS AvgRating, 
COUNT(*) AS RestaurantCount
FROM (SELECT RestaurantID, AVG(Rating) AS avg_rating FROM main GROUP BY RestaurantID) AS subquery
GROUP BY AvgRating
ORDER BY AvgRating DESC;







-- 7. Create buckets based on Average Price of reasonable size and find out how many resturants falls in each buckets

SELECT 
  CASE 
    WHEN Average_Cost_for_two <= 250 THEN '0–250'
    WHEN Average_Cost_for_two <= 500 THEN '251–500'
    WHEN Average_Cost_for_two <= 750 THEN '501–750'
    WHEN Average_Cost_for_two <= 1000 THEN '751–1000'
    WHEN Average_Cost_for_two <= 1500 THEN '1001–1500'
    WHEN Average_Cost_for_two <= 3000 THEN '1501-3000'
    WHEN Average_Cost_for_two <= 5000 THEN '3001-5000'
    WHEN Average_Cost_for_two <= 10000 THEN '5001-10000'
    WHEN Average_Cost_for_two <= 20000 THEN '10001–20000'
    WHEN Average_Cost_for_two <= 50000 THEN '20001-50000'
    WHEN Average_Cost_for_two <= 80000 THEN '50001-80000'
    WHEN Average_Cost_for_two <= 100000 THEN '80001-100000'
    WHEN Average_Cost_for_two <= 500000 THEN '100001-500000'
    WHEN Average_Cost_for_two <= 800000 THEN '500001-800000'
    ELSE '800000+'
  END AS Price_Bucket,
COUNT(*) AS RestaurantCount
FROM main
GROUP BY Price_Bucket
ORDER BY MIN(Average_Cost_for_two);


SELECT 
  CASE 
    WHEN Price_range <= 1 THEN '0–1'
    WHEN Price_range <= 2 THEN '1-2'
    WHEN Price_range <= 3 THEN '2-3'
    WHEN Price_range <= 4 THEN '3-4'
    WHEN Price_range <= 5 THEN '4-5'
    ELSE '5+'
  END AS Price_Bucket,
COUNT(*) AS RestaurantCount
FROM main
GROUP BY Price_Bucket
ORDER BY MIN(Price_range);







-- 8.Percentage of Resturants based on "Has_Table_booking"

SELECT Has_Table_booking,
COUNT(*) AS RestaurantCount,
concat(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM main), 2), "%") AS Percentage
FROM main
GROUP BY Has_Table_booking;






-- 9.Percentage of Resturants based on "Has_Online_delivery"

SELECT Has_Online_delivery,
COUNT(*) AS RestaurantCount,
concat(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM main), 2),"%") AS `% Online_booking`
FROM main
GROUP BY Has_Online_delivery;



-- END PROJECT
