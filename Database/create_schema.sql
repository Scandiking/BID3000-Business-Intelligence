DROP SCHEMA IF EXISTS bid3000_eksamen CASCADE;
CREATE SCHEMA bid3000_eksamen;
SET search_path TO bid3000_eksamen;

-- Dimension Tables
CREATE TABLE dimcustomer (
    customerid BIGINT PRIMARY KEY,
    customername VARCHAR(100)
);

CREATE TABLE dimproduct (
    productid SERIAL PRIMARY KEY,
    stockcode VARCHAR(20),
    description VARCHAR(255),
    price DECIMAL(10,2),
    is_shipping BOOLEAN DEFAULT FALSE,
	effective_date DATE DEFAULT CURRENT_DATE,
	end_date DATE DEFAULT NULL,
	is_current BOOLEAN DEFAULT TRUE
	
);

CREATE TABLE dimdate (
    dateid SERIAL PRIMARY KEY,
    date DATE,
    year INT,
    month INT,
    day INT,
    quarter INT,
    dayofweek VARCHAR(10)
);

CREATE TABLE dimcountry (
    countryid SERIAL PRIMARY KEY,
    countryname VARCHAR(100)
);

-- Fact Tables
CREATE TABLE factsales (
    salesid SERIAL PRIMARY KEY,
    dateid_fk INT NOT NULL,
    customerid_fk INT NOT NULL,
    productid_fk INT NOT NULL,
    countryid_fk INT NOT NULL,
    quantity INT,
    unitprice DECIMAL(10, 2),
    revenue DECIMAL(15, 2),
    FOREIGN KEY (dateid_fk) REFERENCES dimdate(dateid),
    FOREIGN KEY (customerid_fk) REFERENCES dimcustomer(customerid),
    FOREIGN KEY (productid_fk) REFERENCES dimproduct(productid),
    FOREIGN KEY (countryid_fk) REFERENCES dimcountry(countryid)
);

CREATE TABLE factcancellations (
    cancellationid SERIAL PRIMARY KEY,
    dateid_fk INT NOT NULL,
    customerid_fk INT NOT NULL,
    productid_fk INT NOT NULL,
    countryid_fk INT NOT NULL,
    quantity_cancelled INT,
    revenue_lost DECIMAL(15, 2),
    FOREIGN KEY (dateid_fk) REFERENCES dimdate(dateid),
    FOREIGN KEY (customerid_fk) REFERENCES dimcustomer(customerid),
    FOREIGN KEY (productid_fk) REFERENCES dimproduct(productid),
    FOREIGN KEY (countryid_fk) REFERENCES dimcountry(countryid)
);