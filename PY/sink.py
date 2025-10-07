from confluent_kafka import Consumer, KafkaError
import json 
import time 
from datetime import datetime, timedelta 
import threading
import traceback 
import pyfiglet
import os
from pathlib import Path
import pyodbc

class severity:
    Info                                =   0
    warning                             =   1
    error                               =   2
    fatal                               =   3 
    success                             =   4
    startup                             =   5

def db_connect(server: str, db: str, u: str, p: str) -> pyodbc.Connection:
    conn_str = (
        f"DRIVER={{ODBC Driver 17 for SQL Server}};"
        f"SERVER={server};"
        f"DATABASE={db};"
        f"UID={u};"
        f"PWD={p}"
    )
    return pyodbc.connect(conn_str)

def persist_prime(p: int, ld : int, conn: pyodbc.Connection):
    try:
        with conn.cursor() as cursor:
            cursor.execute("EXEC dbo.Prime_Wrk_Insert_1 @PrimeNumber = ?, @SourceLandingDate = ?", p, ld)
            conn.commit()
    except Exception as e:
        print(f"Error inserting prime number {p}: {e}")

def commit_primes(conn: pyodbc.Connection):
    try:
        with conn.cursor() as cursor:
            cursor.execute("{CALL dbo.Prime_Insert_From_Work}")
            conn.commit()
    except Exception as e:
        print(f"Error committing primes: {e}")

def log_message(name : str, message: str, sevlev: severity):
    now = datetime.now()
    datestr = now.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
    log_str = f"{datestr}-{name}"
    if sevlev == severity.Info:
        log_str += " ℹ️ "
    elif sevlev == severity.warning:
        log_str += " ⚠️ "
    elif sevlev == severity.error:
        log_str += " ❌ "
    elif sevlev == severity.fatal:
        log_str += " 🛑 "
    elif sevlev == severity.success:
        log_str += " ✅ "
    elif sevlev == severity.startup:
        log_str += " 🚀 "
    log_str += f" : {message}" 
    print(log_str)
    
def launch_worker(worker_id):
    try:
        worker = sinkWorker()
        thread = threading.Thread(target=run_worker_safely, args=(worker, worker_id))
        thread.daemon = True  # Optional: allows threads to exit when main thread exits
        thread.start()
        log_message("sink.py", f"Worker {worker_id} launched.", severity.startup)
    except Exception as e:
        log_message("sink.py", f"Failed to launch worker {worker_id}: {e}.....aborting", severity.error)
        traceback.print_exc()

def run_worker_safely(worker, worker_id):
    try:
        worker.run()
    except Exception as e:
        log_message("sink.py", f"Worker {worker_id} encountered an error during execution: {e}", severity.fatal )
        traceback.print_exc()
        exit()

class sinkWorker:
    def __init__(self, workerId : int):
        self.name                                   =   f"sinkWorker.{workerId}"
        self.sourceKafkaConfig                      =   {
            "bootstrap.servers"                     :   "localhost:29092",
            "group.id"                              :   "sink01",
            "auto.offset.reset"                     :   "earliest",
            "enable.auto.commit"                    :   True
        }
        self.sourceTopic                            =   "prime.Prime.dbo.Prime"
        self.pollInterval                           =   10
        self.consumer                               =   Consumer(self.sourceKafkaConfig)
        self.messagesConsumed                       =   0
        self.messagesProduced                       =   0

        log_message(f"{self.name}.sinkWorker.__init__", f"\n{self.name} - initialised worker", severity.startup)


    def run(self):
        consct = 0
        prodct = 0 
        self.consumer.subscribe([self.sourceTopic])
        log_message(f"{self.name}.sinkWorker.run", f"Subscribed to topic {self.sourceTopic}", severity.success)
        self.producedPayloads = []
        dbconn = db_connect("localhost,1434", "Prime", "sa", "shh!SHH!")
        while True:
            start_time = time.time()
            while time.time() - start_time < self.pollInterval:
                consct += 1
                if consct > 1500:
                    log_message(f"{self.name}.sinkWorker.run", f"{self.name} - Has consumed {self.messagesConsumed} messages from topic {self.sourceTopic} since startup... nom nom nom nom nom", severity.startup)
                    consct = 0
                msg = self.consumer.poll(1.0)
                try:
                    # Decode and parse JSON
                    if msg != None:
                        self.messagesConsumed += 1
                        payload = json.loads(msg.value().decode('utf-8'))

                        # Extract from 'after'
                        after = payload.get('after', {})
                        before = payload.get('before', {})
                        #extracted = {field: after.get(field) for field in self.sourceFields}
                        x = 0
                        pn = after.get("PrimeNumber")
                        ld_raw = after.get("SourceLandingDate")
                        ld = datetime.fromtimestamp(ld_raw / 1000) - timedelta(hours=2) #back to utc
                        self.producedPayloads.append([pn, ld])                        
                        if prodct > 99:
                            log_message(f"{self.name}.sinkWorker.run", f"{self.name} - has produced {self.messagesProduced} messages since startup.", severity.startup)
                            prodct = 0 
                except json.JSONDecodeError as e:
                    log_message(f"{self.name}.sinkWorker.run", f"JSON decode error: {e}", severity.error)
                except Exception as e:
                    if e == "'NoneType' object has no attribute 'value'":
                        log_message(f"{self.name}.sinkWorker.run", f"Message has no value (NoneType). Skipping.", severity.warning)
                    else:
                        log_message(f"{self.name}.sinkWorker.run", f"Unexpected error: {e}", severity.error)
                except AttributeError:
                    log_message(f"{self.name}.sinkWorker.run", f"Message has no value (NoneType). Skipping.", severity.error)
                    continue

                except KeyboardInterrupt:
                    log_message(f"{self.name}.sinkWorker.run", f"Keyboard interrupt received. Exiting....", severity.fatal)
                    exit() 

                # Produce collected payloads
            try:
                for pl in self.producedPayloads:
                    persist_prime(pl[0], pl[1], dbconn)

                log_message(f"{self.name}.sinkWorker.run", f"{len(self.producedPayloads)} messages published....", severity.success)
                self.messagesProduced += len(self.producedPayloads)
                self.producedPayloads.clear()
            except Exception as e:
                log_message(f"{self.name}.sinkWorker.run", f"Unexpected error: {e}.....", severity.error)
            except KeyboardInterrupt:
                log_message(f"{self.name}.sinkWorker.run", f"Keyboard interrupt received. Exiting....", severity.fatal)
                exit
            commit_primes(dbconn)
            time.sleep(1)

os.system("cls" if os.name == "nt" else "clear")
asciiArt = pyfiglet.figlet_format("S I N K", font="standard")
print(asciiArt)
time.sleep(5)
print("\n")
log_message("sink.py", f"👋👋 Starting up conectors from the config specified in in the app.🔍🔍🔍🔍", severity.startup )
print("\n")

threads                                                 =   []
t                                                       =   0

workers                                                 = 6

x = 0
for x in range(workers):
    try:
        worker = sinkWorker(x)
        thread = threading.Thread(target=run_worker_safely, args=(worker, x))
        thread.start()
        threads.append(thread)
        log_message("sink.py", f"Worker {x} launched.", severity.startup)
        time.sleep(1)
        t += 1 
    except Exception as e:
        log_message("sink.py", f"Failed to launch worker {x}: {e}", severity.fatal)
            
log_message("sink.py", f"ALL WORKERS FOR CONNECTOR LAUNCHED!", severity.startup )

