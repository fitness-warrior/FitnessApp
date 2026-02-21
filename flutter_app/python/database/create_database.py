import psycopg2
from dotenv import load_dotenv
import os


class databaseSQL():
    def connect_database(self):
        load_dotenv()
        self.conn = psycopg2.connect(
            host= "localhost",   #just login stuff that is default 
            dbname= "fitApp",    #name of database
            user= "postgres",    #just login stuff that is default 
            password= os.getenv("DB_PASS")) #your password you made in a .env file
        self.cur = self.conn.cursor()
        
    def create_type(self):
        self.cur.execute("""
    DO $$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'type') THEN
        CREATE TYPE "type" AS ENUM ('a','b','c');
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'gender') THEN
        CREATE TYPE gender AS ENUM ('male','female');
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'focuse') THEN
        CREATE TYPE focuse AS ENUM ('strength','cardio');
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'reward_type') THEN
        CREATE TYPE reward_type AS ENUM ('item','currency','experience');
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'goal') THEN
        CREATE TYPE goal AS ENUM ('Fat Loss', 'Muscle Gain', 'Endurance Improvement', 'General Fitness',
'Athletic Performance', 'Injury Rehabilitation',)
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'equip') THEN
        CREATE TYPE equip AS ENUM ('Bodyweight Only', 'Dumbbells', 'Barbells', 'Resistance Bands',
'Gym Machines', 'Cardio Machines',);
        END IF;
    END$$;
    """)
        self.conn.commit()

    def create(self):
        try:
            self.create_type()
        except:
            print("already made types")
        self.cur.execute("""
CREATE TABLE IF NOT EXISTS game_char (
    game_char_id SERIAL PRIMARY KEY,
    game_char_level INT Not Null,
    game_char_colour Varchar (20) NOT NULL,
    game_char_type type Not Null,
    game_char_hp INT NOt Null,
    game_char_attack INT NOT NULL,
    game_char_speed INT NOT NULL
    );

CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    game_char_id INT NOT NULL REFERENCES game_char(game_char_id),
    user_name Varchar (40) NOT NULL,
    user_surname Varchar (40) NOT NULL,
    user_email Varchar (40) NOT NULL
    );

CREATE TABLE IF NOT EXISTS equipment (
    equip_id SERIAL PRIMARY KEY,
    equipment VARCHAR (20) NOT NULL
)

CREATE TABLE IF NOT EXISTS user_equip (
    user_id INT NOT NULL REFERENCES users(user_id),
    equip_id INT NOT NULL REFERENCES equipment(equip_id),
    PRIMARY KEY (user_id, equip_id)
)


CREATE TABLE IF NOT EXISTS body_metrics (
    body_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id),
    body_weight FLOAT NOT NULL,
    body_past_weight FLOAT,
    body_height FLOAT NOT NULL, -- in CM 
    body_age INT NOT NULL,
    body_gender gender NOT NULL,
    body_goal goal NOT NULL
    );


CREATE TABLE IF NOT EXISTS exersise (
    exer_id SERIAL PRIMARY KEY,
    exer_name VARCHAR (20) Not NULL,
    exer_body_area VARCHAR (20) Not Null,
    exer_type focuse Not Null,
    exer_descrip TEXT,
    exer_vid TEXT,
    exer_equip equip NOT NULL
    );

CREATE TABLE IF NOT EXISTS work_plan (
    work_id SERIAL PRIMARY KEY,
    body_id INT NOT NULL REFERENCES body_metrics(body_id),
    work_name VARCHAR (20) Not NULL,
    work_descrip TEXT,
    work_created_at timestamp,  
    work_updated_at timestamp,
    work_day DATE
    );

CREATE TABLE IF NOT EXISTS plan_exersise (
    plan_exer_id SERIAL PRIMARY KEY,
    work_id INT NOT NULL REFERENCES work_plan(work_id),
    exer_id INT NOT NULL REFERENCES exersise(exer_id),
    plan_exer_amount INT NOT NULL,
    plan_exer_set INT NOT NULL,
    plan_exer_PB INT, --Personal best
    plan_exer_PB_first INT
    );

CREATE TABLE IF NOT EXISTS meal_plan (
    meal_id SERIAL PRIMARY KEY,
    body_id INT NOT NULL REFERENCES body_metrics(body_id),
    meal_day timestamp,
    meal_name Varchar (20) NOT NULL
    ); 

CREATE TABLE IF NOT EXISTS food (
    food_id SERIAL PRIMARY KEY,
    food_name VARCHAR(10),
    food_type VARCHAR(10),
    food_calories FLOAT
);

CREATE TABLE IF NOT EXISTS food_plan (
    food_plan_id SERIAL PRIMARY KEY,
    food_id INT NOT NULL REFERENCES food(food_id),
    meal_id INT NOT NULL REFERENCES meal_plan(meal_id)
);

CREATE TABLE IF NOT EXISTS custom_items (
    item_id SERIAL PRIMARY KEY,
    item_name VARCHAR(20),
    item_effect INT,
    item_level INT,
    item_type VARCHAR(20)
);

-- NOTE: game_char table needs to be created before this table
CREATE TABLE IF NOT EXISTS game_items (
    item_id INT NOT NULL REFERENCES custom_items(item_id),
    game_char_id INT NOT NULL REFERENCES game_char(game_char_id),
    PRIMARY KEY (item_id, game_char_id)
);

--note game_char need to be made 
CREATE TABLE IF NOT EXISTS enemy (
    enemy_id SERIAL PRIMARY KEY,
    game_char_id INT NOT NULL REFERENCES game_char(game_char_id),
    enemy_name VARCHAR (10) Not NULL,
    enemy_health FLOAT Not NULL,
    enemy_attack FLOAT Not NULL,
    enemy_level INT Not NULL
    );



CREATE TABLE IF NOT EXISTS rewards (
    reward_id SERIAL PRIMARY KEY,
    enemy_id INT NOT NULL REFERENCES enemy(enemy_id),
    reward_level INT NOT NULL,
    reward_name VARCHAR (20) Not NULL,
    reward_type reward_type Not NULL,
    description TEXT
    );
        """)
        self.conn.commit()
        
if __name__ == "__main__":
    test = databaseSQL()
    test.connect_database()
    test.create()
