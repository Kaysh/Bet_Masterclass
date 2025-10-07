--just test creation of a table

INSERT INTO dbo.Signal_SQL
(
    ServerInstance,
    Code
)
SELECT 
    'SQL1',
    'USE Prime;
    CREATE TABLE dbo.IWasCreatedOnTheFly(theid  INT);'


--create a topic
INSERT INTO dbo.Signal_KAFKA
(
    Code
)
SELECT 
    'docker exec kafka kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 6  --topic I_was_created_on_the_fly'


--***NOw the real process.
-- 1.) stop connector.
-- 2.) disable cdc
-- 3.) alter table 
-- 4.) enable cdc 
-- 5.) restart connector

-- 1.) stop connector.
INSERT INTO dbo.Signal_CONNECT
(
    Code
)
SELECT 
    'http://localhost:8083/connectors/PRIME/pause'


--2.) disable cdc
INSERT INTO dbo.Signal_SQL
(
    ServerInstance,
    Code
)
SELECT 
    'SQL1',
    'USE Prime;
EXEC sys.sp_cdc_disable_table  
    @source_schema = N''dbo'',  
    @source_name   = N''Prime1'',  
    @capture_instance = N''dbo_Prime1'';'

-- 3.) alter table 
INSERT INTO dbo.Signal_SQL
(
    ServerInstance,
    Code
)
SELECT 
    'SQL1',
    'USE Prime;
ALTER TABLE dbo.Prime1 ADD IwasCreatedontheFly  VARCHAR(5) DEFAULT(''HELLO''); '

-- 4.) enable cdc 
INSERT INTO dbo.Signal_SQL
(
    ServerInstance,
    Code
)
SELECT 
    'SQL1',
    'USE Prime;
EXEC sys.sp_cdc_enable_table
	@source_schema = N''dbo'',
	@source_name   = N''Prime1'',
	@role_name     = NULL,
	@supports_net_changes = 0;'


-- 5.) restart connector
INSERT INTO dbo.Signal_CONNECT
(
    Code
)
SELECT 
    'http://localhost:8083/connectors/PRIME/resume'

    

