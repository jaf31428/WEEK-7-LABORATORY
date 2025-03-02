/*Step 1: Setting Up the MySQL Environment*/

/*1.Open MySQL Workbench and connect to the local MySQL server*/
/*2.Create a new database for this lab session*/
CREATE DATABASE BankingSystem;
USE BankingSystem;

/*3.Create five normalized tables to simulate a real banking system*/
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY AUTO_INCREMENT,
    FullName VARCHAR(100),
    Email VARCHAR(100) UNIQUE,
    PhoneNumber VARCHAR(15),
    Address TEXT
);
 
CREATE TABLE Accounts (
    AccountID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT,
    AccountType ENUM('Savings', 'Checking', 'Business'),
    Balance DECIMAL(10,2),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON DELETE CASCADE
);
 
CREATE TABLE Transactions (
    TransactionID INT PRIMARY KEY AUTO_INCREMENT,
    AccountID INT,
    TransactionType ENUM('Deposit', 'Withdrawal', 'Transfer'),
    Amount DECIMAL(10,2),
    TransactionDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (AccountID) REFERENCES Accounts(AccountID) ON DELETE CASCADE
);
 
CREATE TABLE Loans (
    LoanID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT,
    LoanAmount DECIMAL(12,2),
    InterestRate DECIMAL(5,2),
    LoanTerm INT COMMENT 'Loan duration in months',
    Status ENUM('Active', 'Paid', 'Defaulted'),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON DELETE CASCADE
);
 
CREATE TABLE Payments (
    PaymentID INT PRIMARY KEY AUTO_INCREMENT,
    LoanID INT,
    AmountPaid DECIMAL(10,2),
    PaymentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (LoanID) REFERENCES Loans(LoanID) ON DELETE CASCADE
);

/*4.Populate the Customers table with 10,000 random customers*/
INSERT INTO Customers (FullName, Email, PhoneNumber, Address)
SELECT 
    CONCAT('Customer_', FLOOR(RAND() * 10000)),
    CONCAT('user', FLOOR(RAND() * 10000), '@bank.com'),
    CONCAT('+639', FLOOR(RAND() * 1000000000)),
    CONCAT('Street_', FLOOR(RAND() * 10000), ', City_', FLOOR(RAND() * 100))
FROM 
   information_schema.tables
LIMIT 10000;

/*5.Similarly, generate random accounts, transactions, loans, and payments for customers*/
INSERT INTO Accounts (CustomerID, AccountType, Balance)
SELECT
    CustomerID,
    IF(RAND() > 0.5, 'Savings', 'Checking'),
    ROUND(RAND() * 100000, 2)
FROM Customers;
INSERT INTO Transactions (AccountID, TransactionType, Amount)
SELECT
    AccountID,
    IF(RAND() > 0.5, 'Deposit', 'Withdrawal'),
    ROUND(RAND() * 5000, 2)
FROM Accounts;
INSERT INTO Loans (CustomerID, LoanAmount, InterestRate, LoanTerm,
Status)
SELECT
    CustomerID,
    ROUND(RAND() * 100000,
2),
    ROUND(RAND() * 10, 2),
    FLOOR(RAND() * 60) + 12,
    IF(RAND() > 0.5, 'Active', 'Paid')
FROM Customers;
INSERT INTO Payments (LoanID, AmountPaid)
SELECT
    LoanID,
    ROUND(RAND() * 5000, 2) FROM Loans;
    
/*6.Verify the inserted data*/
SELECT COUNT(*) FROM Customers;
SELECT COUNT(*) FROM Accounts;
SELECT COUNT(*) FROM Transactions;
SELECT COUNT(*) FROM Loans;
SELECT COUNT(*) FROM Payments;


/*Activity 1: Implementing Transactions on Interconnected Tables*/
/*Step 2: Handling Complex Transactions*/

/*1.Simulating a bank transfer involving multiple updates across tables*/
START TRANSACTION;
UPDATE Accounts SET Balance = Balance - 1000 WHERE AccountID = 1;
UPDATE Accounts SET Balance = Balance + 1000 WHERE AccountID = 2;
INSERT INTO Transactions (AccountID, TransactionType, Amount)
VALUES (1, 'Transfer', 1000), (2, 'Transfer', 1000);
COMMIT;

/*2.Processing a loan payment that updates multiple tables*/
START TRANSACTION;
UPDATE Loans SET Status = 'Paid' WHERE LoanID = 5;
INSERT INTO Payments (LoanID, AmountPaid) VALUES (5, 5000);
COMMIT;


/*Activity 2: Managing User Roles and Access Control on Large Datasets*/
/*Step 3: Creating Users and Assigning Privileges*/

/*1.Create a new user with limited access*/
CREATE USER 'bank_clerk'@'localhost' IDENTIFIED BY 'securepassword';

/*2.Grant specific privileges*/
GRANT SELECT, UPDATE ON BankingSystem.Accounts TO 'bank_clerk'@'localhost';

/*3.Create a read-only user for auditors*/
CREATE USER 'auditor'@'localhost' IDENTIFIED BY 'readonlypass';
GRANT SELECT ON BankingSystem.* TO 'auditor'@'localhost';

/*4.Verify the user permissions*/
SHOW GRANTS FOR 'bank_clerk'@'localhost';
SHOW GRANTS FOR 'auditor'@'localhost';

/*5.Revoke access if necessary*/
REVOKE UPDATE ON BankingSystem.Accounts FROM
'bank_clerk'@'localhost';


/*Activity 3: Preventing SQL Injection Attacks on Large Datasets*/
/*Step 4: Understanding SQL Injection Risks*/

/*1.Simulate an SQL Injection Attack*/
/*Observe how an attacker can retrieve all account details.*/
SELECT * FROM Accounts WHERE AccountHolder = '' OR 1=1;

/*2.Mitigate SQL Injection using Prepared Statements*/
/*Use prepared statements in application-level programming to prevent direct query manipulation.*/
PREPARE stmt FROM 'SELECT * FROM Accounts WHERE AccountHolder = ?';
SET @holder = 'Alice Johnson';
EXECUTE stmt USING @holder;
DEALLOCATE PREPARE stmt;

/*3.Use input validation techniques*/
/*Always validate and sanitize user input in applications interacting with MySQL.*/


/*Activity 4: Advanced Bulk Transactions and Concurrency Control*/
/*Step 5: Processing Bulk Transactions Safel*/

/*1.Start a bulk transaction involving multiple accounts*/
START TRANSACTION;
UPDATE Accounts SET Balance = Balance - 100 WHERE AccountID BETWEEN 1 AND 2000;
UPDATE Accounts SET Balance = Balance + 100 WHERE AccountID BETWEEN 2001 AND 4000;
SAVEPOINT bulk_transaction;

/*2.Check balances and verify changes*/
SELECT * FROM Accounts WHERE AccountID BETWEEN 1 AND 5;

/*3.If an issue is detected, rollback partially*/
ROLLBACK TO bulk_transaction;

/*4.If everything is fine, commit*/
COMMIT;

/*5.Demonstrate concurrency control by processing transactions for multiple users simultaneously*/
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
START TRANSACTION;
UPDATE Accounts SET Balance = Balance - 500 WHERE AccountID = 3;
UPDATE Accounts SET Balance = Balance + 500 WHERE AccountID = 4;
COMMIT;

/*6.Verify the transaction isolation level*/
SELECT @@TRANSACTION_ISOLATION;
