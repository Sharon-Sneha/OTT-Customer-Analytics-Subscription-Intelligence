                      # OBJECTIVE - Customer Churn Analysis and Subscription Behavior Insights in OTT Platforms
                      

# create database ott_datbase;  

# Basic Query                    
show databases;
use ott_database;
show tables;
describe ott_data;
select * from ott_data;

# Modifying The Table Structure
SET SQL_SAFE_UPDATES = 0;
delete from ott_data where director = 1;   
SET SQL_SAFE_UPDATES = 1;   
ALTER TABLE ott_data
DROP COLUMN Subscription_Type_y,
DROP COLUMN Device_Type_y;    
ALTER TABLE ott_data
RENAME COLUMN  Subscription_Type_x TO Subscription_Type,
RENAME COLUMN Device_Type_x TO Device_Type; 

# Overall Business KPI Summary
SELECT 
    COUNT(*) AS Total_Users,
    SUM(Monthly_Fee) AS Total_Revenue,
    AVG(Monthly_Fee) AS Avg_Revenue,
    MAX(Watch_Duration_Minutes) AS Max_Watch,
    MIN(Watch_Duration_Minutes) AS Min_Watch
FROM ott_data;

# Churn vs Retention Behavior
SELECT 
    Churn_Flag,
    COUNT(*) AS Users,
    AVG(Watch_Duration_Minutes) AS Avg_Watch,
    AVG(Completion_Percentage) AS Avg_Completion
FROM ott_data
GROUP BY Churn_Flag;

# Revenue Contribution by Subscription Type
SELECT 
    Subscription_Type,
    COUNT(*) AS Users,
    SUM(Monthly_Fee) AS Revenue
FROM ott_data
GROUP BY Subscription_Type
ORDER BY Revenue DESC;

# Region-wise Churn Rate 
SELECT 
    Region,
    COUNT(*) AS Total_Users,
    SUM(Churn_Flag) AS Churned,
    (SUM(Churn_Flag) * 100.0 / COUNT(*)) AS Churn_Rate
FROM ott_data
GROUP BY Region
ORDER BY Churn_Rate DESC;

# High Value Users Who Churned (Subquery)
SELECT DISTINCT 
    User_ID,
    Subscription_Type,
    Monthly_Fee,
    Churn_Flag
FROM ott_data
WHERE Churn_Flag = 1
AND Monthly_Fee > (
    SELECT AVG(Monthly_Fee) FROM ott_data);

# Users Above Average Engagement (Subquery)
SELECT User_ID,Watch_Duration_Minutes,Engagement_Level,Engagement_Proxy FROM ott_data
WHERE Watch_Duration_Minutes > (
    SELECT AVG(Watch_Duration_Minutes) FROM ott_data);

# Subscription vs Feedback Impact
SELECT 
    Subscription_Type,
    Feedback_Category,
    COUNT(*) AS Users,
    AVG(Completion_Percentage) AS Avg_Completion
FROM ott_data 
GROUP BY Subscription_Type, Feedback_Category;

# Self Join: Compare Users in Same Region
SELECT a.User_ID AS User1, b.User_ID AS User2, a.Region AS Region_Name
FROM (
    SELECT DISTINCT User_ID, Region 
    FROM ott_data
) a
JOIN (
    SELECT DISTINCT User_ID, Region 
    FROM ott_data
) b
ON a.Region = b.Region
AND a.User_ID < b.User_ID;

# Temporary Table: High Risk Users
CREATE TEMPORARY TABLE temp_high_risk AS
SELECT User_ID,Subscription_Type,Watch_Duration_Minutes,Completion_Percentage,Engagement_Level,Churn_Flag
FROM ott_data
WHERE Engagement_Level = 'Low'
AND Completion_Percentage < 50;

SELECT 
    COUNT(*) AS High_Risk_Users,
    AVG(Watch_Duration_Minutes) AS Avg_Watch_Time,
    AVG(Completion_Percentage) AS Avg_Completion,
    SUM(Churn_Flag) AS Likely_Churned_Users
FROM temp_high_risk;

# DROP TEMPORARY TABLE IF EXISTS temp_high_risk;

# View: Churn Analysis Layer
CREATE VIEW churn_analysis_view AS
SELECT 
    User_ID,
    Subscription_Type,
    Engagement_Level,
    Watch_Duration_Minutes,
    Completion_Percentage,
    Renewal_Status,
    Churn_Flag
FROM ott_data;
SELECT * FROM churn_analysis_view;

# Stored Procedure: Get High Risk Users
DELIMITER //

CREATE PROCEDURE GetHighRiskUsers()
BEGIN
    SELECT DISTINCT
        User_ID,
        Subscription_Type,
        Engagement_Level,
        Watch_Duration_Minutes,
        Completion_Percentage,
        Churn_Flag
    FROM ott_data
    WHERE Engagement_Level = 'Low'
    AND Completion_Percentage < 50
    AND Churn_Flag = 1;
END //

DELIMITER ;

CALL GetHighRiskUsers();

# Trigger: Auto Update Churn Flag
DELIMITER //

CREATE TRIGGER update_churn_flag
BEFORE UPDATE ON ott_data
FOR EACH ROW
BEGIN
    IF NEW.Renewal_Status = 'Not Renewed' THEN
        SET NEW.Churn_Flag = 1;
    END IF;
END //

DELIMITER ;
