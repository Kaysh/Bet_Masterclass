# 🌀 CDC & Debezium Training 

Welcome to the CDC & Debezium training repo! This project is designed to help you understand how **Change Data Capture (CDC)** works in SQL Server and how **Debezium** can stream those changes in real time using Kafka.

Whether you're new to data streaming or just brushing up, this hands-on environment will guide you through the essentials.

## Demonstration.

We are going to play with Prime Numbers.
We will have 4 Python processes mining prime numbers.

  Process 1 (prime1.py) will mine and persist to a database table dbo.Prime1, the prime number 2 and all other prime numbers that end with 1, until we tell it to stop.

  Process 2 (prime3.py) will mine and persist to a database table dbo.Prime3, the prime number 3 and all other prime numbers that end with 3, until we tell it to stop.

  Process 3 (prime7.py) will mine and persist to a database table dbo.Prime7 the prime number 5 and all other prime numbers that end with 7, until we tell it to stop.

  Process 4 (prime9.py) will mine and persist to a database table dbo.Prime9 the prime number 7 and all other prime numbers that end with 9, until we tell it to stop.

  While this is happening, those messages will be published to a different sql server in 1 table dbo.Prime to collate the prime numbers (This will also rank them so we have to take care with how we publish the records. The data will not arrive in the correct order from kafka)

🥇 We will also update a tables schema with minimal downtime.


### Demonstration Instructions.


## Signal approach to deploy and automatically change schema.

1.) Worker connector consuming from a topic (single partition).
  - message examples: 
  
    {"Event" : "SQL", "Destination" : "SQL1", "Code" : "USE MASTER; \\n CREATE DATABASE Prime;"}

    {"Event" : "KAFKA", "Destination" : "Kafka", "Code" : "kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 6  --topic prime.Prime.dbo.Prime;"}

    {"Event" : "CONNECT", "Destination" : "CONNECT", "Code" : "some connect endpoint call"}

2.) Adding a new table to an already running connector

  a) In your terminal execute ./startup.ps1
  b) Create the new table and enable CDC on it

      CREATE TABLE dbo.Prime11
        (
        ServerID                   TINYINT    NOT NULL DEFAULT(11), --Change per server
        ServerPrimeRank            INT        IDENTITY(1, 1) NOT NULL,
        PrimeNumber                BIGINT     NOT NULL,
        SourceLandingDate          DATETIME   NOT NULL DEFAULT(GETDATE()),
        CONSTRAINT pk_dbo_Prime11  PRIMARY KEY(ServerID, ServerPrimeRank)
        );
      GO 
      --Enable CDC on the Prime11
      EXEC sys.sp_cdc_enable_table
	        @source_schema = N'dbo',
	        @source_name   = N'Prime11',
	        @role_name     = NULL,
	        @supports_net_changes = 0; 
      GO      

  c) Insert into Prime11
     DECLARE @num INT = 2;  -- Start from the first prime number
     DECLARE @isPrime BIT;

      WHILE @num <= 10000
      BEGIN
      SET @isPrime = 1;  -- Assume number is prime unless proven otherwise

    -- Check divisibility from 2 up to sqrt(@num)
      DECLARE @div INT = 2;
      WHILE @div * @div <= @num
      BEGIN
        IF @num % @div = 0
        BEGIN
            SET @isPrime = 0;
            BREAK;
        END
        SET @div += 1;
      END

      IF @isPrime = 1
        BEGIN
        INSERT INTO dbo.Prime11 (primenumber) VALUES (@num);
        END

      SET @num += 1;
    END
  GO

 c) Import the Masterclass Postman collection into postman and execute the PRIMENewTableAdd request
    In the below config the Prime11 table has been added to the table.include.list config
    ![alt text](image.png)
 d) Events should now be flowing through in confluent (http://localhost:9021/clusters/GtFAfe8FSiyXpI0Q65omLA/management/topics/prime.Prime.dbo.Prime/message-viewer)  

 1. Debezium
    https://debezium.io/documentation//reference/2.3/transformations/index.html
 2. Kafka
    https://developer.confluent.io/courses/#fundamentals
 3. 

 




                      
    