
IF EXISTS (SELECT 1 FROM sys.Databases WHERE NAME = 'Prime')
BEGIN
    DROP DATABASE Prime;
END
CREATE DATABASE Prime;
GO
USE Prime;
GO
CREATE TABLE dbo.Prime1
(
        ServerID                                TINYINT             NOT NULL DEFAULT(1), --Change per server
        ServerPrimeRank                         INT                 IDENTITY(1, 1) NOT NULL,
        PrimeNumber                             BIGINT              NOT NULL,
        SourceLandingDate                       DATETIME            NOT NULL DEFAULT(GETDATE()),
        CONSTRAINT pk_dbo_Prime1                 PRIMARY KEY(ServerID, ServerPrimeRank)
);
GO 
CREATE PROCEDURE dbo.Prime_Insert_1
(
    @PrimeNumber                                BIGINT
)
AS 
SET NOCOUNT ON;
INSERT INTO dbo.Prime1(PrimeNumber) SELECT @PrimeNumber;
GO

CREATE TABLE dbo.Prime3
(
        ServerID                                TINYINT             NOT NULL DEFAULT(3), --Change per server
        ServerPrimeRank                         INT                 IDENTITY(1, 1) NOT NULL,
        PrimeNumber                             BIGINT              NOT NULL,
        SourceLandingDate                       DATETIME            NOT NULL DEFAULT(GETDATE()),
        CONSTRAINT pk_dbo_Prime3                 PRIMARY KEY(ServerID, ServerPrimeRank)
);
GO 
CREATE PROCEDURE dbo.Prime_Insert_3
(
    @PrimeNumber                                BIGINT
)
AS 
SET NOCOUNT ON;
INSERT INTO dbo.Prime3(PrimeNumber) SELECT @PrimeNumber;
GO

CREATE TABLE dbo.Prime7
(
        ServerID                                TINYINT             NOT NULL DEFAULT(7), --Change per server
        ServerPrimeRank                         INT                 IDENTITY(1, 1) NOT NULL,
        PrimeNumber                             BIGINT              NOT NULL,
        SourceLandingDate                       DATETIME            NOT NULL DEFAULT(GETDATE()),
        CONSTRAINT pk_dbo_Prime7                 PRIMARY KEY(ServerID, ServerPrimeRank)
);
GO 
CREATE PROCEDURE dbo.Prime_Insert_7
(
    @PrimeNumber                                BIGINT
)
AS 
SET NOCOUNT ON;
INSERT INTO dbo.Prime7(PrimeNumber) SELECT @PrimeNumber;
GO

CREATE TABLE dbo.Prime9
(
        ServerID                                TINYINT             NOT NULL DEFAULT(9), --Change per server
        ServerPrimeRank                         INT                 IDENTITY(1, 1) NOT NULL,
        PrimeNumber                             BIGINT              NOT NULL,
        SourceLandingDate                       DATETIME            NOT NULL DEFAULT(GETDATE()),
        CONSTRAINT pk_dbo_Prime9                 PRIMARY KEY(ServerID, ServerPrimeRank)
);
GO 
CREATE PROCEDURE dbo.Prime_Insert_9
(
    @PrimeNumber                                BIGINT
)
AS 
SET NOCOUNT ON;
INSERT INTO dbo.Prime9(PrimeNumber) SELECT @PrimeNumber;
GO

EXEC sys.sp_cdc_enable_db;
GO 
EXEC sys.sp_cdc_enable_table
	@source_schema = N'dbo',
	@source_name   = N'Prime1',
	@role_name     = NULL,
	@supports_net_changes = 0;

GO 
EXEC sys.sp_cdc_enable_table
	@source_schema = N'dbo',
	@source_name   = N'Prime3',
	@role_name     = NULL,
	@supports_net_changes = 0;

GO 
EXEC sys.sp_cdc_enable_table
	@source_schema = N'dbo',
	@source_name   = N'Prime7',
	@role_name     = NULL,
	@supports_net_changes = 0;

GO 
EXEC sys.sp_cdc_enable_table
	@source_schema = N'dbo',
	@source_name   = N'Prime9',
	@role_name     = NULL,
	@supports_net_changes = 0;

GO 
