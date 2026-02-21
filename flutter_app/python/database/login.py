import psycopg2
from dotenv import load_dotenv
import os   
          
load_dotenv()
CONN = psycopg2.connect(
    host= "localhost",   #just login stuff that is default 
    dbname= "fitApp",    #name of database
    user= "postgres",    #just login stuff that is default 
    password= os.getenv("DB_PASS")) #your password you made in a .env file