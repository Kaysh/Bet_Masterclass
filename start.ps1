
Write-Host "Starting Docker Compose..."
docker compose up -d


Write-Host "Waiting for SQL Server containers to initialize..."
Start-Sleep -Seconds 10 
Write-Host "Creating sql databases, tables and configuring CDC"
docker cp "C:\Dev\Training\SQL\PrimeSQL1.sql" sql1:/tmp/Prime.sql
docker cp "C:\Dev\Training\SQL\PrimeSQL2.sql" sql2:/tmp/Prime.sql
docker cp "C:\Dev\Training\SQL\signals.sql" sql2:/tmp/signals.sql

docker exec -i sql1 /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P "shh!SHH!" `
    -C -i /tmp/Prime.sql

docker exec -i sql2 /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P "shh!SHH!" `
    -C -i /tmp/Prime.sql

Start-Sleep -Seconds 10

docker exec -i sql2 /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P "shh!SHH!" `
    -C -i /tmp/signals.sql

Write-Host "Creating 6 partition topics..."
docker exec kafka kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 6  --topic prime.Prime.dbo.Prime
#docker exec kafka kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 6  --topic prime.Prime.dbo.Prime1
#docker exec kafka kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 6  --topic prime.Prime.dbo.Prime3
#docker exec kafka kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 6  --topic prime.Prime.dbo.Prime7
#docker exec kafka kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 6  --topic prime.Prime.dbo.Prime9

function Register-Connector {
    param (
        [string]$jsonPath
    )

    $connectorConfig = Get-Content $jsonPath -Raw
    $connectorName = (Get-Item $jsonPath).BaseName

    Write-Host "Registering connector: $connectorName..."

    try {
        Invoke-RestMethod -Method POST `
            -Uri "http://localhost:8083/connectors" `
            -ContentType "application/json" `
            -Body $connectorConfig
        Write-Host "✅ Connector '$connectorName' registered successfully."
    }
    catch {
        Write-Host "❌ Failed to register '$connectorName': $($_.Exception.Message)"
    }
}


Register-Connector -jsonPath "C:\Dev\Training\Connectors\prime.json"
Start-Sleep -Seconds 3
Register-Connector -jsonPath "C:\Dev\Training\Connectors\MissionControl.json"
Start-Sleep -Seconds 3

#Start-Process -FilePath "python" -ArgumentList "C:\Dev\Training\PY\prime1.py"
#Start-Sleep -Seconds 2 
#Start-Process -FilePath "python" -ArgumentList "C:\Dev\Training\PY\prime3.py" 
#Start-Sleep -Seconds 2
#Start-Process -FilePath "python" -ArgumentList "C:\Dev\Training\PY\prime7.py" 
#Start-Sleep -Seconds 2
#Start-Process -FilePath "python" -ArgumentList "C:\Dev\Training\PY\prime9.py" 
#Write-Host "Waiting for Debezium Connector to Stabalize..."
#Start-Sleep -Seconds 10 
#Start-Process -FilePath "python" -ArgumentList "C:\Dev\Training\PY\sink.py" 

Start-Process -FilePath "cmd.exe" -ArgumentList '/k python "C:\Dev\Training\PY\prime1.py"'
Start-Sleep -Seconds 2
Start-Process -FilePath "cmd.exe" -ArgumentList '/k python "C:\Dev\Training\PY\prime3.py"'
Start-Sleep -Seconds 2
Start-Process -FilePath "cmd.exe" -ArgumentList '/k python "C:\Dev\Training\PY\prime7.py"'
Start-Sleep -Seconds 2
Start-Process -FilePath "cmd.exe" -ArgumentList '/k python "C:\Dev\Training\PY\prime9.py"'
Write-Host "Waiting for Debezium Connector to Stabilize..."
Start-Sleep -Seconds 10
Start-Process -FilePath "cmd.exe" -ArgumentList '/k python "C:\Dev\Training\PY\sink.py"'