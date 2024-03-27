// Query 1: Direct MSFT stock ownership in individual accounts.
MATCH (c:Customer)-[rc:HAS]->(a:Account)-[rs:PURCHASED]->(s:Stock {ticker: "MSFT"})
WHERE a.account_type = "Individual"
RETURN a,s,c,rs,rc

// Query 2: MSFT stock ownership through mutual funds.
MATCH (acc:Account)-[raf:PURCHASED]->(f:Fund)-[rfs:HOLDS]->(stock:Stock {ticker: "MSFT"})
RETURN acc,f,stock,raf,rfs

// Query 3: Count of funds holding each stock, sorted by count.
MATCH (f:Fund)-[:HOLDS]->(s:Stock)
WITH s.ticker AS StockTicker, COUNT(f) AS FundsHolding
ORDER BY FundsHolding DESC
RETURN StockTicker, FundsHolding

// Query 4: Value of Ed Chowder's mutual fund holdings on 2017-12-01.
MATCH (c:Customer {owner_name: 'Ed Chowder'})-[:HAS]->(a:Account)-[p:PURCHASED]->(f:Fund),
      (f)-[:HOLDS]->(s:Stock),
      (f)-[:DAILY_CLOSE {date: '2017-12-01'}]->(dc)
WHERE p.purchase_date = '2017-12-01'
WITH c, f, toFloat(p.quantity) AS UnitsPurchased, toFloat(dc.close) AS UnitPrice, f.fund_name AS FundName
RETURN c.owner_name AS OwnerName, FundName, UnitsPurchased * UnitPrice AS FundHoldingValue
ORDER BY FundName

// Query 5: Account owners and types with direct or indirect MSFT stock ownership.
// Direct MSFT ownership in individual accounts
MATCH (c:Customer)-[:HAS]->(a:Account {account_type: "Individual"})-[:PURCHASED]->(s:Stock {ticker: "MSFT"})
RETURN c.owner_name AS OwnerName, a.account_type AS AccountType
UNION
// Indirect MSFT ownership through mutual funds
MATCH (c:Customer)-[:HAS]->(a:Account)-[:PURCHASED]->(f:Fund)-[:HOLDS]->(s:Stock {ticker: "MSFT"})
RETURN c.owner_name AS OwnerName, a.account_type AS AccountType

// Query 6: Last trading day's total value of assets owned by each account.
// Direct stock ownership
MATCH (dc:DayClose)
WITH MAX(dc.date) AS LastDay
MATCH (c:Customer)-[:HAS]->(a:Account)-[p:PURCHASED]->(s:Stock)-[:DAILY_CLOSE {date: LastDay}]->(dc)
RETURN c.owner_name AS OwnerName, a.account_type AS AccountType, s.ticker AS OwnedAsset, toFloat(p.quantity) * toFloat(dc.close) AS TotalValue
UNION
// Indirect stock ownership through funds
MATCH (dc:DayClose)
WITH MAX(dc.date) AS LastDay
MATCH (c:Customer)-[:HAS]->(a:Account)-[p:PURCHASED]->(f:Fund)-[:HOLDS]->(s:Stock)-[:DAILY_CLOSE {date: LastDay}]->(dc)
RETURN c.owner_name AS OwnerName, a.account_type AS AccountType, f.fund_name AS OwnedAsset, toFloat(p.quantity) * toFloat(dc.close) AS TotalValue


// Come up with any other interesting queries or observations about the model you built and the types of queries that it entails. 

// Query 7: Top 5 customers by total value of MSFT holdings, direct and indirect.
// Direct MSFT stock ownership
MATCH (dc:DayClose)
WITH MAX(dc.date) AS LastDay
MATCH (c:Customer)-[:HAS]->(a:Account)-[p:PURCHASED]->(s:Stock {ticker: "MSFT"})-[:DAILY_CLOSE]->(dc)
WITH c, SUM(toFloat(p.quantity) * toFloat(dc.close)) AS TotalValue
RETURN c.owner_name AS OwnerName, TotalValue
ORDER BY TotalValue DESC
LIMIT 5
UNION
// Indirect MSFT ownership through funds
MATCH (dc:DayClose)
WITH MAX(dc.date) AS LastDay
MATCH (c:Customer)-[:HAS]->(a:Account)-[p:PURCHASED]->(f:Fund)-[:HOLDS]->(s:Stock {ticker: "MSFT"})-[:DAILY_CLOSE {date: LastDay}]->(dc)
WITH c, SUM(toFloat(p.quantity) * toFloat(dc.close)) AS TotalValue
RETURN c.owner_name AS OwnerName, TotalValue
ORDER BY TotalValue DESC
LIMIT 5

// Query 8: Analyze portfolio diversification by counting unique stocks and funds per customer.
MATCH (c:Customer)-[:HAS]->(a:Account)-[:PURCHASED]->(asset)
RETURN c.owner_name AS OwnerName, COUNT(DISTINCT asset) AS NumberOfUniqueAssets

// Query 9: Track historical performance of a mutual fund by its monthly closing price over a year.
MATCH (f:Fund {fund_name: "Vanguard Dividend Growth Fund"})-[:DAILY_CLOSE]->(dc)
WHERE dc.date >= "2012-01-01" AND dc.date <= "2014-01-01"
  AND SUBSTRING(dc.date, 8, 2) = "01"
RETURN f.fund_name AS FundName, dc.date AS Date, dc.close AS ClosingPrice
ORDER BY dc.date