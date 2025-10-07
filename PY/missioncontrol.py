from confluent_kafka import Consumer, KafkaError
import pyodbc
import json 
import time 
from datetime import datetime, timedelta 
import subprocess
import requests

def db_connect(server: str, db: str, u: str, p: str) -> pyodbc.Connection:
    conn_str = (
        f"DRIVER={{ODBC Driver 17 for SQL Server}};"
        f"SERVER={server};"
        f"DATABASE={db};"
        f"UID={u};"
        f"PWD={p}"
    )
    return pyodbc.connect(conn_str)


def process_sql(payload : dict, dbconn: pyodbc.Connection):
     code = payload.get("Code")
     with dbconn.cursor() as cursor:
         print(f"Executing:\n {code}")
         cursor.execute(code)
         dbconn.commit()
     print(f"Completed executing..\n {code}")

def process_connect(payload : dict, connectendpoint : str):
    endpoint = payload.get("Code")
    #response = requests.post(connectendpoint, headers={"Content-Type": "application/json"}, data=json.dumps(body))
    print(f"ENDPOINT IS {endpoint}")
    if "pause" in endpoint or "resume" in endpoint:
        response = requests.put(endpoint)
    else:
        response = requests.post(endpoint) 
        
    if response.status_code >= 201 and response.status_code <= 299:
        print(f"Connect enpoint returned SUCCESS.\n{response.text}")
    else:
        print(f"Connect api error: {response.status_code}")
        print(response.text)

def process_kafka(payload : dict):
    cmd = payload.get("Code")
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=True)
        print(f"Kafka command.{cmd} executed succesfully")
        print(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error executing Kafka command: {cmd}")
        print(e.stderr)
    pass 

kafkaConfig = {
            "bootstrap.servers"                     :   "localhost:29092",
            "group.id"                              :   "mc01",
            "auto.offset.reset"                     :   "earliest",
            "enable.auto.commit"                    :   True
        }

connecturl = "http://localhost:8083/connectors"
dbconn1 = db_connect("localhost,1433", "Prime", "sa", "shh!SHH!")
dbconn2 = db_connect("localhost,1434", "Prime", "sa", "shh!SHH!")
consumer = Consumer(kafkaConfig)
cons = consumer.subscribe(["MISSION_CONTROL"])
PollInterval = 10
while True:
        start_time = time.time()
        while time.time() - start_time < PollInterval:
            msg = consumer.poll(1.0)
            try:
                if msg != None:
                    print(msg)
                    print(msg.value())
                    payload = json.loads(msg.value().decode('utf-8'))
                    after = payload.get("after")
                    event = after.get("Event")
                    if event == "SQL":
                        if after.get("ServerInstance") == "SQL1": 
                            process_sql(after, dbconn1)
                        else:
                            process_sql(after, dbconn2)
                    elif event == "KAFKA":
                        process_kafka(after)
                    elif event == "CONNECT":
                        process_connect(after, connecturl)
                    else:
                        print(f"INCORRECT EVENT SUPPLIED {event}")
            except json.JSONDecodeError as e:
                print(f"JSON decode error: {e}")
            except Exception as e:
                if e == "'NoneType' object has no attribute 'value'":
                    print(f"Message has no value (NoneType). Skipping.")
                else:
                    print(f"Unexpected error: {e}")
            except AttributeError:
                print(f"Message has no value (NoneType). Skipping.")
                continue
            except KeyboardInterrupt:
                print(f"Keyboard interrupt received. Exiting....")
                exit() 
