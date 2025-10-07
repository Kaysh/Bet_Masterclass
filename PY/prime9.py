import math, pyodbc, time
from datetime import datetime 

def isPrime(xp: int)->bool:
    if xp < 2:                                      return False 
    if xp in (2,3,5,7, 11):                         return True 
    if xp <= 12:                                    return False 
    if xp % 2 == 0:                                 return False 
    if xp % 3 == 0:                                 return False 
    if xp % 5 == 0:                                 return False 
    if xp % 7 == 0:                                 return False 
    if xp % 11 == 0:                                return False 
    d = 11
    lim = int(math.sqrt(xp)) + 1 
    while d <= lim:
        if xp % d == 0:                             return False
        if d % 10 in (1,7): d += 2 
        else: d += 4
    return True 

def find_primes(start : int, tot : int, inc: int):
    start_time = datetime.now()
    dbconn = db_connect("localhost,1433", "Prime", "sa", "shh!SHH!")
    persist_prime(7, dbconn)
    x = start 
    ct = 0 
    while ct < tot:
        if ct % 500 == 0: 
            time.sleep(1)
        if isPrime(x) == True:
            persist_prime(x, dbconn)
            curr_time = datetime.now()
            ct += 1
            duration = (curr_time - start_time).total_seconds()
            print(f"Prime9.py {x} - Is Prime! count = {ct}. Duration = {duration:.2f}, primes per second = {(ct/duration):.4f} ")
        x += inc

def db_connect(server: str, db: str, u: str, p: str) -> pyodbc.Connection:
    conn_str = (
        f"DRIVER={{ODBC Driver 17 for SQL Server}};"
        f"SERVER={server};"
        f"DATABASE={db};"
        f"UID={u};"
        f"PWD={p}"
    )
    return pyodbc.connect(conn_str)

def persist_prime(p: int, conn: pyodbc.Connection):
    try:
        with conn.cursor() as cursor:
            cursor.execute("EXEC dbo.Prime_Insert_9 @PrimeNumber = ?", p)
            conn.commit()
    except Exception as e:
        print(f"Error inserting prime number {p}: {e}")

find_primes(19, 13000, 10)

print("prime9.py - completed succesfully")
time.sleep(3)
