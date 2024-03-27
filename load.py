# Loading data

import csv
import json
import os

from neo4j import GraphDatabase

# Connect to the Aura database online

neo4j_url = os.getenv("NEO4J_CONNECTION_URL")
neo4j_user = os.getenv("NEO4J_USERNAME")
neo4j_password = os.getenv("NEO4J_PASSWORD")

driver = GraphDatabase.driver(neo4j_url, auth=(neo4j_user, neo4j_password))
session = driver.session()

# Create a new node for each customer
# Properties are set: customer_id,owner_name,address1,address2,city,state,zip
with open("customers.csv", "r") as f:
    reader = csv.DictReader(f)
    for row in reader:
        session.run("CREATE (n:Customer)", customer_id=row["customer_id"], owner_name=row["owner_name"], address1=row["address1"], address2=row["address2"], city=row["city"], state=row["state"], zip=row["zip"])

# Create a new node for each account and link it to the customer
# Properties are set: account_id : row.account_id, customer_id : row.customer_id, account_type : row.account_type, channel:row.channel }
with open("accounts.csv", "r") as f:
    reader = csv.DictReader(f)
    for row in reader:
        session.run("CREATE (n:Account)", account_id=row["account_id"], customer_id=row["customer_id"], account_type=row["account_type"], channel=row["channel"])
        session.run("MATCH (c:Customer {customer_id: {customer_id}}), (a:Account {account_id: {account_id}}) CREATE (c)-[:HAS]->(a)", customer_id=row["customer_id"], account_id=row["account_id"])
        
        
# Create a new node for each fund
# Properties are set: fund_name, ticker, assets ,manager, inception_date, company, expense_ratio

with open("funds.csv", "r") as f:
    reader = csv.DictReader(f)
    for row in reader:
        session.run("CREATE (n:Fund)", fund_name=row["fund_name"], ticker=row["ticker"], assets=row["assets"], manager=row["manager"], inception_date=row["inception_date"], company = row["company"], expense_ratio=row["expense_ratio"])
        
        
# Create a new node for each stock
# Properties are set: ticker, holding_company

with open("stock_ticker.csv", "r") as f:
    reader = csv.DictReader(f)
    for row in reader:
        session.run("CREATE (n:Stock)", ticker=row["ticker"], holding_company=row["holding_company"])
        
        
# Create a relationship between accounts and funds using ticker value and account_purchases.csv, include quantity & purchase_date on relationship.
with open("account_purchases.csv", "r") as f:
    reader = csv.DictReader(f)
    for row in reader:
        session.run("MATCH (a:Account {account_id: $account_id}), (f:Fund {ticker: $ticker}) CREATE (a)-[:PURCHASED {quantity: $quantity, purchase_date: $purchase_date}]->(f)", account_id=row["account_id"], ticker=row["ticker"], quantity=row["quantity"], purchase_date=row["purchase_date"])



# Create a relationship between accounts and stocks using ticker value and account_purchases.csv, include quantity & purchase_date on relationship.
with open("account_purchases.csv", "r") as f:
    reader = csv.DictReader(f)
    for row in reader:
        session.run("MATCH (a:Account {account_id: $account_id}), (s:Stock {ticker: $ticker}) CREATE (a)-[:PURCHASED {quantity: $quantity, purchase_date: $purchase_date}]->(s)", account_id=row["account_id"], ticker=row["ticker"], quantity=row["quantity"], purchase_date=row["purchase_date"])
        
# Establish a relationship between funds and stock using ticker value and fund_holdings.csv, include percent on relationship
with open("fund_holdings.csv", "r") as f:
    reader = csv.DictReader(f)
    for row in reader:
        session.run("MATCH (f:Fund {ticker: $fund_ticker}), (s:Stock {ticker: $holding_ticker}) CREATE (f)-[:HOLDS {percent: $percent}]->(s)", fund_ticker=row["fund_ticker"], holding_ticker=row["holding_ticker"], percent=row["percent"])
        
# Create dayclose entity from daily_close.csv and establish relationship between dayclose and stock using ticker value
# Properties are set: "ticker","date","close","volume","open","high","low"
with open("daily_close.csv", "r") as f:
    reader = csv.DictReader(f)
    for row in reader:
        session.run("CREATE (n:DayClose {ticker: $ticker, date: $date, close: $close, volume: $volume, open: $open, high: $high, low: $low})", ticker=row["ticker"], date=row["date"], close=row["close"], volume=row["volume"], open=row["open"], high=row["high"], low=row["low"])
        session.run("MATCH (s:Stock {ticker: $ticker}) CREATE (s)-[:DAILY_CLOSE]->(n)", ticker=row["ticker"])