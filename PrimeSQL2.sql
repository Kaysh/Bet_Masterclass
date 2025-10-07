IF EXISTS (SELECT 1 FROM sys.Databases WHERE NAME = 'Prime')
BEGIN
    DROP DATABASE Prime;
END
CREATE DATABASE Prime;
GO
USE Prime;
GO
CREATE TABLE dbo.Prime_wrk
(
        
        PrimeNumber                             BIGINT              NOT NULL,
        SourceLandingDate                       DATETIME            NOT NULL
        CONSTRAINT pk_dbo_Prime_wrk             PRIMARY KEY(PrimeNumber)
);
GO 

CREATE TABLE dbo.Prime
(
        PrimeRank                               INT                 IDENTITY(1, 1) NOT NULL,
        PrimeNumber                             BIGINT              NOT NULL,
        SourceLandingDate                       DATETIME            NOT NULL,
        SinkLandingDate                         DATETIME            NOT NULL  DEFAULT (GETDATE()),
        CONSTRAINT pk_dbo_Prime                 PRIMARY KEY(PrimeNumber)
);
GO 

CREATE PROCEDURE dbo.Prime_Wrk_Insert_1
(
    @PrimeNumber                                BIGINT,
    @SourceLandingDate                          DATETIME
)
AS 
SET NOCOUNT ON;
INSERT INTO dbo.Prime_wrk(PrimeNumber, SourceLandingDate) SELECT @PrimeNumber, @SourceLandingDate;
GO

CREATE PROCEDURE dbo.Prime_Insert_From_Work
AS 
SET NOCOUNT ON;
INSERT INTO dbo.Prime (PrimeNumber, SourceLandingDate)
SELECT w.PrimeNumber, w.SourceLandingDate
FROM (
    SELECT TOP (80) PERCENT PrimeNumber, SourceLandingDate
    FROM dbo.Prime_Wrk
    ORDER BY PrimeNumber
) AS w
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.Prime p
    WHERE p.PrimeNumber = w.PrimeNumber
);

DELETE w
FROM dbo.Prime_Wrk w 
INNER JOIN dbo.Prime p
on w.PrimeNumber = p.PrimeNumber;

GO


