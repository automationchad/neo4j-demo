// Import customers into the database
LOAD CSV WITH HEADERS FROM 'https://docs.google.com/spreadsheets/d/15zik__RmV4ytAVZwhuvW2-e2DE4C2oqrW-bx1ps-ujg/export?format=csv' AS row
CREATE (c:Customer {customer_id: row.customer_id, owner_name: row.owner_name, address1: row.address1, address2: row.address2, city: row.city, state: row.state, zip: row.zip})

// Import the accounts into the database
LOAD CSV WITH HEADERS FROM 'https://docs.google.com/spreadsheets/d/1VTWrK5WMmw2F9evtdUXK_0NVIbMQyjIxyiAbvDTQYK4/export?format=csv' as row
CREATE (n:Account {account_id: row.account_id, customer_id: row.customer_id, account_type: row.account_type, channel: row.channel})

// Create relationship between accounts and customers
MATCH (a:Account), (c:Customer)
WHERE a.customer_id = c.customer_id
CREATE (c)-[:HAS]->(a)

// Create funds
LOAD CSV WITH HEADERS FROM 'https://docs.google.com/spreadsheets/d/11PHRqNDAjpgJy-7hir5Y-mwuygfrzutf6Hg5DCRp0Xs/export?format=csv' as row
CREATE (n:Fund {fund_name: row.fund_name, ticker: row.ticker, assets: row.assets, manager: row.manager, inception_date: row.inception_date, company: row.company, expense_ratio: row.expense_ratio})

// Create stocks
LOAD CSV WITH HEADERS FROM 'https://docs.google.com/spreadsheets/d/10YkNH4RD4zyr9B-6Kp5szrL-wz1sAxR2xSXNVZBvcoo/export?format=csv' as row
CREATE (n:Stock {ticker: row.ticker,holding_company: row.holding_company})

// Create relationship between accounts and funds
LOAD CSV WITH HEADERS FROM 'https://docs.google.com/spreadsheets/d/1YSTWpOHaAv4fYb7NnOqu4Lnvv1qAIPcKVvZoVquVoi8/export?format=csv' as row
MATCH (a:Account {account_id: row.account_id}), (f:Fund {ticker: row.ticker}) CREATE (a)-[:PURCHASED {quantity: row.number_of_shares, purchase_date: row.purchase_date}]->(f)

// Create relationship between accounts and stocks
LOAD CSV WITH HEADERS FROM 'https://docs.google.com/spreadsheets/d/1YSTWpOHaAv4fYb7NnOqu4Lnvv1qAIPcKVvZoVquVoi8/export?format=csv' as row
MATCH (a:Account {account_id: row.account_id}), (s:Stock {ticker: row.ticker}) CREATE (a)-[:PURCHASED {quantity: row.number_of_shares, purchase_date: row.purchase_date}]->(s)

// Create relationshio between funds and stocks
LOAD CSV WITH HEADERS FROM 'https://docs.google.com/spreadsheets/d/1D85kVjbgnn-5Y6IAi_7S02MF91tLGc3ywc3yHFmDEJk/export?format=csv' as row
MATCH (f:Fund {ticker: row.fund_ticker}), (s:Stock {ticker: row.holding_ticker}) CREATE (f)-[:HOLDS {percent: row.percent}]->(s)

// Create daily close data, properties: "ticker","date","close","volume","open","high","low"
CALL apoc.periodic.iterate(
  "LOAD CSV WITH HEADERS FROM 'https://docs.google.com/spreadsheets/d/1sbD949dnCUOn0cJZoRgGERRtubow0V_m97oD5mE2My0/export?format=csv' AS row RETURN row",
  "CREATE (n:DayClose {ticker: row.ticker, date: row.date, close: row.close, volume: row.volume, open: row.open, high: row.high, low: row.low})",
  {batchSize:10000, parallel:true}
);
// Create relationships between daily close data and stocks
CALL apoc.periodic.iterate(
"MATCH (s:Stock), (dc:DayClose) WHERE s.ticker = dc.ticker RETURN s, dc",
"CREATE (s)-[:DAILY_CLOSE {date: dc.date}]->(dc)",
{batchSize:10000, parallel:true});

// Create relationships between daily close data and funds
CALL apoc.periodic.iterate(
"MATCH (f:Fund), (dc:DayClose) WHERE f.ticker = dc.ticker RETURN f, dc",
"CREATE (f)-[:DAILY_CLOSE {date: dc.date}]->(dc)",
{batchSize:10000, parallel:true});



