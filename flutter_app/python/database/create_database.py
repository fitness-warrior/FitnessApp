from login import CONN

class DatabaseSQL():
    def __init__(self,CONN):
        self.conn = CONN
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
'Athletic Performance', 'Injury Rehabilitation');
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'equip') THEN
        CREATE TYPE equip AS ENUM ('Bodyweight Only', 'Dumbbells', 'Barbells', 'Resistance Bands',
'Gym Machines', 'Cardio Machines');
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
    equipment_name VARCHAR (20) NOT NULL
);

CREATE TABLE IF NOT EXISTS user_equip (
    user_id INT NOT NULL REFERENCES users(user_id),
    equip_id INT NOT NULL REFERENCES equipment(equip_id),
    PRIMARY KEY (user_id, equip_id)
);


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
    
    def add_data(self):
        self.cur.execute("""
INSERT INTO game_char (game_char_level, game_char_colour, game_char_type, game_char_hp, game_char_attack, game_char_speed) VALUES
(1, 'red', 'a', 200, 10, 5),
(1, 'blue', 'b', 100, 25, 10),
(1, 'green', 'c', 80, 15, 20);

INSERT INTO users (game_char_id, user_name, user_surname, user_email) VALUES
(1, 'John', 'Smith', 'john.smith@email.com'),
(2, 'Sarah', 'Johnson', 'sarah.j@email.com'),
(3, 'Mike', 'Williams', 'mike.w@email.com'),
(1, 'Emma', 'Brown', 'emma.brown@email.com'),
(2, 'David', 'Jones', 'david.jones@email.com'),
(3, 'Lisa', 'Garcia', 'lisa.garcia@email.com'),
(1, 'James', 'Miller', 'james.miller@email.com'),
(2, 'Anna', 'Davis', 'anna.davis@email.com');

INSERT INTO equipment (equip_id, equipment_name) VALUES
(1,'Dumbbells'),
(2,'Barbells'),
(3,'Resistance Bands'),
(4,'Resistance Bands'),
(5,'Gym Machines'),
(6,'Cardio Machines');


INSERT INTO user_equip (user_id, equip_id) VALUES
-- John Smith (1)
(1, 1),
(1, 3),
(1, 6),

-- Sarah Johnson (2)
(2, 2),
(2, 5),

-- Mike Williams (3)
(3, 1),
(3, 2),
(3, 5),

-- Emma Brown (4)
(4, 3),
(4, 4),
(4, 6),

-- David Jones (5)
(5, 2),
(5, 6),

-- Lisa Garcia (6)
(6, 1),
(6, 3),
(6, 5),

-- James Miller (7)
(7, 2),
(7, 4),

-- Anna Davis (8)
(8, 1),
(8, 5),
(8, 6);

INSERT INTO enemy (game_char_id, enemy_name, enemy_health, enemy_attack, enemy_level) VALUES
(1, 'Goblin', 50.0, 10.0, 1),
(1, 'Orc', 120.0, 25.0, 3),
(2, 'Troll', 200.0, 35.0, 5),
(2, 'Dragon', 500.0, 80.0, 10),
(3, 'Skeleton', 80.0, 15.0, 2),
(3, 'Zombie', 100.0, 20.0, 3),
(1, 'Vampire', 300.0, 50.0, 7),
(2, 'Demon', 400.0, 65.0, 9);

INSERT INTO body_metrics (user_id, body_weight, body_past_weight, body_height, body_age, body_gender, body_goal) VALUES
(1, 75.5, 78.0, 175.0, 25, 'male','Fat Loss'),
(2, 62.0, 65.0, 165.0, 28, 'female', 'Endurance Improvement'),
(3, 82.3, 80.0, 180.0, 32, 'male', 'Muscle Gain'),
(4, 58.5, 60.0, 160.0, 24, 'female', 'Injury Rehabilitation'),
(5, 90.0, 92.0, 185.0, 35, 'male', 'General Fitness'),
(6, 65.0, 67.0, 168.0, 30, 'female', 'Athletic Performance'),
(7, 78.0, 75.0, 178.0, 27, 'male', 'Fat Loss'),
(8, 55.0, 57.0, 162.0, 26, 'female', 'General Fitness');

INSERT INTO exersise (exer_name, exer_body_area, exer_type, exer_descrip, exer_vid, exer_equip) VALUES
('Push-ups', 'chest', 'strength', 'Classic upper body exercise', 'https://youtube.com/pushups', 'Bodyweight Only'),
('Squats', 'legs', 'strength', 'Lower body compound movement', 'https://youtube.com/squats', 'Bodyweight Only'),
('Running', 'full body', 'cardio', 'Outdoor cardio exercise', 'https://youtube.com/running', 'Dumbbells'),
('Bench Press', 'chest', 'strength', 'Chest and tricep builder', 'https://youtube.com/bench', 'Barbells'),
('Deadlift', 'back', 'strength', 'Full posterior chain exercise', 'https://youtube.com/deadlift','Gym Machines'),
('Cycling', 'legs', 'cardio', 'Low impact cardio', 'https://youtube.com/cycling', 'Cardio Machines'),
('Pull-ups', 'back', 'strength', 'Back and bicep exercise', 'https://youtube.com/pullups', 'Bodyweight Only'),
('Jump Rope', 'full body', 'cardio', 'High intensity cardio', 'https://youtube.com/jumprope', 'Resistance Bands');

INSERT INTO work_plan (body_id, work_name, work_descrip, work_created_at, work_updated_at, work_day) VALUES
(1, 'Chest Day', 'Focus on chest and triceps', '2026-02-01 10:00:00', '2026-02-01 10:00:00', '2026-02-18'),
(2, 'Leg Day', 'Lower body workout', '2026-02-02 09:00:00', '2026-02-02 09:00:00', '2026-02-19'),
(3, 'Cardio Session', 'Endurance training', '2026-02-03 07:00:00', '2026-02-03 07:00:00', '2026-02-20'),
(4, 'Full Body', 'Complete body workout', '2026-02-04 08:00:00', '2026-02-04 08:00:00', '2026-02-21'),
(5, 'Back Day', 'Back and biceps', '2026-02-05 10:00:00', '2026-02-05 10:00:00', '2026-02-22'),
(6, 'HIIT Training', 'High intensity intervals', '2026-02-06 06:00:00', '2026-02-06 06:00:00', '2026-02-23'),
(7, 'Strength Training', 'Heavy compound lifts', '2026-02-07 11:00:00', '2026-02-07 11:00:00', '2026-02-24'),
(8, 'Recovery Cardio', 'Light cardio session', '2026-02-08 07:30:00', '2026-02-08 07:30:00', '2026-02-25');

INSERT INTO meal_plan (body_id, meal_day, meal_name) VALUES
(1, '2026-02-18 08:00:00', 'Breakfast Plan'),
(2, '2026-02-18 12:00:00', 'Lunch Plan'),
(3, '2026-02-18 18:00:00', 'Dinner Plan'),
(4, '2026-02-19 08:00:00', 'Morning Meal'),
(5, '2026-02-19 12:00:00', 'Afternoon Meal'),
(6, '2026-02-19 18:00:00', 'Evening Meal'),
(7, '2026-02-20 08:00:00', 'Protein Breakfast'),
(8, '2026-02-20 12:00:00', 'Healthy Lunch');

INSERT INTO plan_exersise (work_id, exer_id, plan_exer_amount, plan_exer_set, plan_exer_PB, plan_exer_PB_first) VALUES
(1, 1, 20, 2, 25, 15),
(1, 4, 10, 3, 12, 8),
(2, 2, 15, 2, 20, 10),
(3, 3, 30, 1, 35, 20),
(4, 5, 8, 3, 10, 5),
(5, 7, 12, 2, 15, 8),
(6, 8, 100, 1, 120, 80),
(7, 4, 12, 2, 15, 10);

INSERT INTO food (food_name, food_type, food_calories) VALUES
('Chicken', 'protein', 165.0),
('Rice', 'carbs', 130.0),
('Broccoli', 'vegetable', 55.0),
('Salmon', 'protein', 208.0),
('Pasta', 'carbs', 131.0),
('Spinach', 'vegetable', 23.0),
('Eggs', 'protein', 155.0),
('Oats', 'carbs', 389.0);

INSERT INTO food_plan (food_id, meal_id) VALUES
(1, 1),
(2, 1),
(3, 2),
(4, 2),
(5, 3),
(6, 3),
(7, 4),
(8, 4);

INSERT INTO custom_items (item_name, item_effect, item_level, item_type) VALUES
('Health Potion', 50, 1, 'consumable'),
('Mana Potion', 30, 1, 'consumable'),
('Iron Sword', 15, 3, 'weapon'),
('Steel Shield', 20, 4, 'armor'),
('Magic Ring', 10, 5, 'accessory'),
('Leather Boots', 8, 2, 'armor'),
('Fire Staff', 25, 6, 'weapon'),
('Elixir', 100, 7, 'consumable');

INSERT INTO game_items (item_id, game_char_id) VALUES
(1, 1),
(2, 1),
(3, 1),
(4, 2),
(5, 2),
(6, 2),
(7, 3),
(8, 3);

INSERT INTO rewards (enemy_id, reward_level, reward_name, reward_type, description) VALUES
(1, 1, 'Goblin Gold', 'currency', 'Small amount of gold from goblin'),
(2, 3, 'Orc Axe', 'item', 'A crude but effective axe'),
(3, 5, 'Troll Hide', 'item', 'Tough leather for crafting armor'),
(4, 10, 'Dragon Scale', 'item', 'Legendary crafting material'),
(5, 2, 'Bone Dust', 'item', 'Useful for alchemy'),
(6, 3, 'Zombie Brain', 'item', 'Disgusting but valuable'),
(7, 7, 'Vampire Fang', 'item', 'Rare alchemical ingredient'),
(8, 9, 'Demon Soul', 'experience', 'Grants massive experience');
        """)
        self.conn.commit()
        
        
    def delete_all(self):
        self.cur.execute("""
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
                         """)
        self.conn.commit()
        
    def run(self):
        try:
            self.delete_all()
            self.create()
            self.add_data()
            print("complete database")
        except Exception as e:
            print("Error:", e)
            self.conn.rollback()


if __name__ == "__main__":
    test = DatabaseSQL(CONN)
    test.run()
