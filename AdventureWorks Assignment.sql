--1.Retrieve the top 10 customers by total purchase amount.
--using the total_due(final sum of all money spent by the customer)
SELECT TOP 10 sc.CustomerID,ROUND(SUM(TotalDue),2) AS Total_Purchase_Amount
FROM Sales.Customer SC JOIN Sales.SalesOrderHeader SOH ON SC.CustomerID = SOH.CustomerID
GROUP BY sc.CustomerID
ORDER BY Total_Purchase_Amount DESC;

--2.Find customers who have made repeat purchases of the same product on different orders.
SELECT SOH.CustomerID,P.Name,COUNT(SOH.SalesOrderID) AS Counts
FROM Sales.SalesOrderHeader SOH 
JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
JOIN Production.Product P ON SOD.ProductID = P.ProductID
GROUP BY SOH.CustomerID,P.Name
HAVING COUNT(SOH.SalesOrderID) > 1
ORDER BY Counts DESC;

--3.List customers whose spending has dropped by more than 30% compared to the previous 
--year.
--total amount spent by each customer
WITH CustomersSpending AS(
SELECT CustomerID,
YEAR(OrderDate) AS OrderYear,
SUM(TotalDue) AS Total_Spent
FROM Sales.SalesOrderHeader
GROUP BY CustomerID,YEAR(OrderDate)
--comparing the total amount spent on current year vs previous year
),CustomerSpents AS
( SELECT 
cs1.CustomerID,Cs1.Total_Spent AS CurrentYear,
cs2.Total_Spent AS PreviousYear,
((cs2.Total_Spent - cs1.Total_Spent )* 100)/ cs2.Total_Spent  AS Spending_Duration
FROM CustomersSpending cs1
JOIN CustomersSpending cs2 ON  cs1.CustomerID = cs2.CustomerID
AND cs1.OrderYear = cs2.OrderYear + 1 
--selecting the current year money spend and the previous money spents
) SELECT CustomerID,CurrentYear,PreviousYear,Spending_Duration
FROM CustomerSpents
WHERE Spending_Duration > 30
ORDER BY Spending_Duration DESC;

--4.Identify the average number of days between repeat purchases for each customer.
--Using the LAG Function to get the previous purchase for the same customer
WITH Repeat_Purchase AS (
SELECT CustomerID,OrderDate,
LAG(OrderDate) OVER (PARTITION BY CustomerID ORDER BY OrderDate DESC) AS Previous_Date
FROM Sales.SalesOrderHeader
) SELECT CustomerID,AVG(DATEDIFF(DAY,OrderDate,Previous_Date)) AS Differences_InDays
FROM Repeat_Purchase
WHERE Previous_Date IS NOT NULL
GROUP BY CustomerID
ORDER BY Differences_InDays DESC

--5.Find the top 5 most common product categories purchased by customers.
SELECT TOP 5 
FROM Production.prod





WITH CustomerSpending AS (
    SELECT 
        SOH.CustomerID,
        FirstName + ' ' + LastName AS FullName,
        YEAR(OrderDate) AS OrderYear,
        ROUND(SUM(TotalDue),2) AS Total_Spent,
        LAG(SUM(TotalDue), 1) OVER (PARTITION BY CustomerID ORDER BY YEAR(OrderDate)) AS PreviousYear_Spending,
        LAG(SUM(TotalDue), 2) OVER (PARTITION BY CustomerID ORDER BY YEAR(OrderDate)) AS TwoYearsAgo_Spending
    FROM Sales.Customer sc 
JOIN
    Sales.SalesOrderHeader soh ON SC.CustomerID = soh.CustomerID
JOIN 
    Person.person PP ON sc.PersonID = PP.BusinessEntityID
    GROUP BY SC.CustomerID,FirstName + ' ' + LastName, YEAR(OrderDate)
)
SELECT 
    SC.CustomerID, 
    OrderYear,
    Total_Spent, 
    PreviousYear_Spending,
    TwoYearsAgo_Spending,
    (Total_Spent - PreviousYear_Spending) AS OneYear_Change,
    ((Total_Spent - PreviousYear_Spending) * 100) / NULLIF(PreviousYear_Spending, 0) AS OneYear_Percentage_Change,
    (Total_Spent - TwoYearsAgo_Spending) AS TwoYear_Change,
    ((Total_Spent - TwoYearsAgo_Spending) * 100) / NULLIF(TwoYearsAgo_Spending, 0) AS TwoYear_Percentage_Change
FROM CustomerSpending
WHERE TwoYearsAgo_Spending IS NOT NULL
ORDER BY CustomerID, OrderYear;