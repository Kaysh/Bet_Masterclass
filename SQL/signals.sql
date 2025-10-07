CREATE DATABASE Signals;
GO
Use Signals;
GO 

EXEC sys.sp_cdc_enable_db;
GO

CREATE TABLE dbo.Signal_SQL
(
    Signal_SQLID                                INT         IDENTITY(1, 1)  NOT NULL,
    ServerInstance                              VARCHAR(50)                 NOT NULL,
    Code                                        VARCHAR(600)                NOT NULL,
    RequestDate                                 DATETIME DEFAULT(GETDATE()) NOT NULL,
    [Event]                                     VARCHAR(15) DEFAULT('SQL')  NOT NULL,
    CONSTRAINT  pk_dbo_signal_SQL               PRIMARY KEY(SIGNAL_SQLID)
);
GO 
CREATE TABLE dbo.Signal_KAFKA
(
    Signal_KAFKAID                              INT         IDENTITY(1, 1)  NOT NULL,
    Code                                        VARCHAR(600)                NOT NULL,
    RequestDate                                 DATETIME DEFAULT(GETDATE()) NOT NULL,
    [Event]                                     VARCHAR(15) DEFAULT('KAFKA')  NOT NULL,
    CONSTRAINT  pk_dbo_signal_KAFKA             PRIMARY KEY(SIGNAL_KAFKAID)
);
GO
CREATE TABLE dbo.Signal_CONNECT
(
    Signal_CONNECTID                             INT         IDENTITY(1, 1)  NOT NULL,
    Code                                        VARCHAR(600)                NOT NULL,
    RequestDate                                 DATETIME DEFAULT(GETDATE()) NOT NULL,
    [Event]                                     VARCHAR(15) DEFAULT('CONNECT')  NOT NULL,
    CONSTRAINT  pk_dbo_signal_CONNECT             PRIMARY KEY(SIGNAL_CONNECTID)
);
GO
EXEC sys.sp_cdc_enable_table
	@source_schema = N'dbo',
	@source_name   = N'Signal_SQL',
	@role_name     = NULL,
	@supports_net_changes = 0;
GO
EXEC sys.sp_cdc_enable_table
	@source_schema = N'dbo',
	@source_name   = N'Signal_KAFKA',
	@role_name     = NULL,
	@supports_net_changes = 0;
GO
EXEC sys.sp_cdc_enable_table
	@source_schema = N'dbo',
	@source_name   = N'Signal_CONNECT',
	@role_name     = NULL,
	@supports_net_changes = 0;
GO
