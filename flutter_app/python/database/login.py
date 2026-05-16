import psycopg2
from dotenv import load_dotenv
from pathlib import Path
load_dotenv(Path(__file__).parent / '.env')
import os   
          
CONN = psycopg2.connect(
    host= "localhost",   #just login stuff that is default 
    dbname= "fitapp",    #name of database
    user= "postgres",    #just login stuff that is default 
    password= os.getenv("DB_PASS")) #your password you made in a .env file