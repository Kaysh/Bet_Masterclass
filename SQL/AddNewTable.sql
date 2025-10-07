--1 Create new prime table
CREATE TABLE dbo.Prime11
(
        ServerID                                TINYINT             NOT NULL DEFAULT(11), --Change per server
        ServerPrimeRank                         INT                 IDENTITY(1, 1) NOT NULL,
        PrimeNumber                             BIGINT              NOT NULL,
        SourceLandingDate                       DATETIME            NOT NULL DEFAULT(GETDATE()),
        CONSTRAINT pk_dbo_Prime11               PRIMARY KEY(ServerID, ServerPrimeRank)
);
GO 

--2 enable CDC
EXEC sys.sp_cdc_enable_table
	@source_schema = N'dbo',
	@source_name   = N'Prime11',
	@role_name     = NULL,
	@supports_net_changes = 0;


--3 - Add some data to the new table
DECLARE @num INT = 2;  -- Start from the first prime number
DECLARE @isPrime BIT;

WHILE @num <= 20000
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

SELECT COUNT(1) FROM dbo.Prime11

--Jump to postman and Import the Prime Postman collection into postman and execute the PRIMENewTableAdd request

--Replaying data through the signal table to trigger snapshot for Prime11
/*
  INSERT INTO dbo.debezium_signal (id, type, data)
    VALUES (
    'signal-001',
    'execute-snapshot',
    '{"data-collections":["Prime.dbo.Prime11"], "additional-condition":"SourceLandingDate > ''2025-10-01 13:45:00.000''"}')
*/


