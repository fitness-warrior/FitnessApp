from login import CONN

class DatabaseSQL():
    def __init__(self,CONN):
        self.conn = CONN
        self.cur = self.conn.cursor()
        
    def create_type(self):
        self.cur.execute("""
    CREATE TABLE game_char (
    game_char_id SERIAL PRIMARY KEY,
    game_char_level INT NOT NULL,
    game_char_colour VARCHAR(20) NOT NULL,
    game_char_type type NOT NULL,
    game_char_hp INT NOT NULL,
    game_char_attack INT NOT NULL,
    game_char_speed INT NOT NULL
);

---------------- USERS ----------------

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    game_char_id INT NOT NULL REFERENCES game_char(game_char_id),
    user_name VARCHAR(40) NOT NULL,
    user_surname VARCHAR(40) NOT NULL,
    user_email VARCHAR(40) UNIQUE NOT NULL
);

---------------- EQUIPMENT ----------------

CREATE TABLE equipment (
    equip_id SERIAL PRIMARY KEY,
    equipment VARCHAR(20) NOT NULL
);

CREATE TABLE user_equip (
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    equip_id INT REFERENCES equipment(equip_id),
    PRIMARY KEY (user_id,equip_id)
);

---------------- BODY METRICS ----------------

CREATE TABLE body_metrics (
    body_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    body_weight FLOAT NOT NULL,
    body_past_weight FLOAT,
    body_height FLOAT NOT NULL,
    body_age INT NOT NULL,
    body_gender gender NOT NULL,
    body_goal goal NOT NULL
);

---------------- EXERCISE ----------------

CREATE TABLE exercise (
    exer_id SERIAL PRIMARY KEY,
    exer_name VARCHAR(50) NOT NULL,
    exer_body_area VARCHAR(20) NOT NULL,
    exer_type focus NOT NULL,
    exer_descrip TEXT,
    exer_vid TEXT,
    exer_equip equip NOT NULL
);

CREATE TABLE training (
    train_id SERIAL PRIMARY KEY,
    train_data TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    train_mins INT,
    train_reps INT,
    train_effort decimal NOT NULL,
);

CREATE TABLE training_exercise (
    training_exercise_id SERIAL PRIMARY KEY,
    train_id INT REFERENCES training(train_id),
    exer_id INT REFERENCES exercise(exer_id)
);

---------------- WORK PLAN ----------------

CREATE TABLE work_plan (
    work_id SERIAL PRIMARY KEY,
    body_id INT REFERENCES body_metrics(body_id),
    work_name VARCHAR(50) NOT NULL,
    work_descrip TEXT,
    work_created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    work_updated_at TIMESTAMP,
    work_day DATE
);

CREATE TABLE plan_exercise (
    plan_exer_id SERIAL PRIMARY KEY,
    work_id INT REFERENCES work_plan(work_id),
    exer_id INT REFERENCES exercise(exer_id),
    plan_exer_amount INT NOT NULL,
    plan_exer_set INT NOT NULL,
    plan_exer_PB INT,
    plan_exer_PB_first INT
);

---------------- MEALS ----------------

CREATE TABLE meal_plan (
    meal_id SERIAL PRIMARY KEY,
    body_id INT REFERENCES body_metrics(body_id),
    meal_day TIMESTAMP,
    meal_name VARCHAR(20) NOT NULL
);

CREATE TABLE food (
    food_id SERIAL PRIMARY KEY,
    food_name VARCHAR(50),
    food_type VARCHAR(50),
    food_calories FLOAT NOT NULL,
    food_fat FLOAT NOT NULL,
    food_fibre Float NOT NULL,
    food_protein Float NOT NULL,
);

CREATE TABLE food_plan (
    food_plan_id SERIAL PRIMARY KEY,
    food_id INT REFERENCES food(food_id),
    meal_id INT REFERENCES meal_plan(meal_id)
);

---------------- GAME ITEMS ----------------

CREATE TABLE custom_items (
    item_id SERIAL PRIMARY KEY,
    item_name VARCHAR(20),
    item_effect INT,
    item_level INT,
    item_type VARCHAR(20)
);

CREATE TABLE game_items (
    item_id INT REFERENCES custom_items(item_id),
    game_char_id INT REFERENCES game_char(game_char_id),
    PRIMARY KEY (item_id,game_char_id)
);

---------------- ENEMY ----------------

CREATE TABLE enemy (
    enemy_id SERIAL PRIMARY KEY,
    game_char_id INT REFERENCES game_char(game_char_id),
    enemy_name VARCHAR(20) NOT NULL,
    enemy_health FLOAT NOT NULL,
    enemy_attack FLOAT NOT NULL,
    enemy_level INT NOT NULL
);

CREATE TABLE rewards (
    reward_id SERIAL PRIMARY KEY,
    enemy_id INT REFERENCES enemy(enemy_id),
    reward_level INT NOT NULL,
    reward_name VARCHAR(20) NOT NULL,
    reward_type reward_type NOT NULL,
    reward_description TEXT
);

---------------- MEAL COLLECTION ----------------

CREATE TABLE meal_collection (
    collection_id SERIAL PRIMARY KEY,
    collection_name VARCHAR(50) NOT NULL,
    collection_type VARCHAR(20) NOT NULL,
    collection_description TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    collection_link TEXT
);

CREATE TABLE collection_foods (
    collection_id INT REFERENCES meal_collection(collection_id),
    food_id INT REFERENCES food(food_id),
    PRIMARY KEY (collection_id,food_id)
);

        """)
        self.conn.commit()
    
    def add_data(self):
        self.cur.execute("""
INSERT INTO game_char
(game_char_level, game_char_colour, game_char_type,
 game_char_hp, game_char_attack, game_char_speed)
VALUES
(1,'red','a',200,10,5),
(1,'blue','b',100,25,10),
(1,'green','c',80,15,20),
(1,'yellow','a',210,12,6),
(1,'purple','b',150,20,9),
(1,'black','c',120,18,11),
(1,'white','a',170,14,8),
(1,'orange','b',140,16,10);

INSERT INTO users
(game_char_id, user_name, user_surname, user_email)
VALUES
(1, 'John', 'Smith', 'john.smith@email.com'),
(2, 'Sarah', 'Johnson', 'sarah.j@email.com'),
(3, 'Mike', 'Williams', 'mike.w@email.com'),
(4, 'Emma', 'Brown', 'emma.brown@email.com'),
(5, 'David', 'Jones', 'david.jones@email.com'),
(6, 'Lisa', 'Garcia', 'lisa.garcia@email.com'),
(7, 'James', 'Miller', 'james.miller@email.com'),
(8, 'Anna', 'Davis', 'anna.davis@email.com');

INSERT INTO equipment (equip_id, equipment) VALUES
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
(2, 'Orc', 120.0, 25.0, 3),
(3, 'Troll', 200.0, 35.0, 5),
(4, 'Dragon', 500.0, 80.0, 10),
(5, 'Skeleton', 80.0, 15.0, 2),
(6, 'Zombie', 100.0, 20.0, 3),
(7, 'Vampire', 300.0, 50.0, 7),
(8, 'Demon', 400.0, 65.0, 9);

INSERT INTO body_metrics (user_id, body_weight, body_past_weight, body_height, body_age, body_gender, body_goal) VALUES
(1, 75.5, 78.0, 175.0, 25, 'male','Fat Loss'),
(2, 62.0, 65.0, 165.0, 28, 'female', 'Endurance Improvement'),
(3, 82.3, 80.0, 180.0, 32, 'male', 'Muscle Gain'),
(4, 58.5, 60.0, 160.0, 24, 'female', 'Injury Rehabilitation'),
(5, 90.0, 92.0, 185.0, 35, 'male', 'General Fitness'),
(6, 65.0, 67.0, 168.0, 30, 'female', 'Athletic Performance'),
(7, 78.0, 75.0, 178.0, 27, 'male', 'Fat Loss'),
(8, 55.0, 57.0, 162.0, 26, 'female', 'General Fitness');

INSERT INTO exercise
(exer_name, exer_body_area, exer_type, exer_descrip, exer_vid, exer_equip)
VALUES
('Push-ups','chest','strength','Classic upper body exercise','https://youtube.com/pushups','Bodyweight Only'),
('Squats','legs','strength','Lower body compound movement','https://youtube.com/squats','Bodyweight Only'),
('Running','full body','cardio','Outdoor cardio exercise','https://youtube.com/running','Dumbbells'),
('Bench Press','chest','strength','Chest and tricep builder','https://youtube.com/bench','Barbells'),
('Deadlift','back','strength','Full posterior chain exercise','https://youtube.com/deadlift','Gym Machines'),
('Cycling','legs','cardio','Low impact cardio','https://youtube.com/cycling','Cardio Machines'),
('Pull-ups','back','strength','Back and bicep exercise','https://youtube.com/pullups','Bodyweight Only'),
('Jump Rope','full body','cardio','High intensity cardio','https://youtube.com/jumprope','Resistance Bands');

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

INSERT INTO plan_exercise
(work_id, exer_id, plan_exer_amount, plan_exer_set,
 plan_exer_PB, plan_exer_PB_first)
VALUES
(1, 1, 20, 3, 25, 15),
(2, 4, 10, 4, 12, 8),
(3, 2, 15, 3, 20, 10),
(4, 3, 30, 2, 35, 20),
(5, 5, 8, 5, 10, 5),
(6, 7, 12, 3, 15, 8),
(7, 8, 100, 2, 120, 80),
(8, 4, 12, 4, 15, 10);

-- food_name, food_type, food_calories, food_fat, food_fibre, food_protein
INSERT INTO food (food_name, food_type, food_calories, food_fat, food_fibre, food_protein) VALUES
('Chicken', 'protein', 165.0, 3.6, 0.0, 31.0),
('Rice', 'carbs', 130.0, 0.3, 0.4, 2.7),
('Broccoli', 'vegetable', 55.0, 0.6, 5.1, 3.7),
('Salmon', 'protein', 208.0, 13.0, 0.0, 20.0),
('Pasta', 'carbs', 131.0, 1.1, 1.8, 5.0),
('Spinach', 'vegetable', 23.0, 0.4, 2.2, 2.9),
('Eggs', 'protein', 155.0, 11.0, 0.0, 13.0),
('Oats', 'carbs', 389.0, 6.9, 10.6, 16.9);

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

INSERT INTO rewards (enemy_id, reward_level, reward_name, reward_type, reward_description) VALUES
(1, 1, 'Goblin Gold', 'currency', 'Small amount of gold from goblin'),
(2, 3, 'Orc Axe', 'item', 'A crude but effective axe'),
(3, 5, 'Troll Hide', 'item', 'Tough leather for crafting armor'),
(4, 10, 'Dragon Scale', 'item', 'Legendary crafting material'),
(5, 2, 'Bone Dust', 'item', 'Useful for alchemy'),
(6, 3, 'Zombie Brain', 'item', 'Disgusting but valuable'),
(7, 7, 'Vampire Fang', 'item', 'Rare alchemical ingredient'),
(8, 9, 'Demon Soul', 'experience', 'Grants massive experience');

INSERT INTO meal_collection (collection_name, collection_type, collection_description, collection_link) VALUES
('Vegan Meals', 'vegan', 'Plant-based meals with no animal products', 'https://example.com/collections/vegan'),
('Vegetarian Meals', 'vegetarian', 'Meals without meat but may include dairy/eggs', 'https://example.com/collections/vegetarian'),
('High Protein', 'high_protein', 'Protein-rich meals for muscle building', 'https://example.com/collections/high-protein'),
('Low Carb', 'low_carb', 'Low carbohydrate meals for weight management', 'https://example.com/collections/low-carb'),
('Keto Friendly', 'keto', 'High fat, low carb meals for ketogenic diet', 'https://example.com/collections/keto'),
('Low Calorie', 'low_calorie', 'Meals under 300 calories for weight loss', 'https://example.com/collections/low-calorie'),
('Post Workout', 'post_workout', 'Recovery meals with protein and carbs', 'https://example.com/collections/post-workout'),
('Quick Snacks', 'snacks', 'Fast and easy snack options', 'https://example.com/collections/snacks');

--Run this before inserting additional food data;
ALTER TABLE food ALTER COLUMN food_name TYPE VARCHAR(50);

-- food_name, food_type, food_calories, food_fat, food_fibre, food_protein
INSERT INTO food (food_name, food_type, food_calories, food_fat, food_fibre, food_protein) VALUES
-- Proteins
('Beef', 'protein', 250.0, 15.0, 0.0, 26.0),
('Tuna', 'protein', 132.0, 1.0, 0.0, 28.0),
('Turkey', 'protein', 135.0, 1.0, 0.0, 30.0),
('Tofu', 'protein', 76.0, 4.8, 0.3, 8.0),
('Greek Yogurt', 'protein', 100.0, 0.7, 0.0, 17.0),
('Cottage Cheese', 'protein', 98.0, 4.3, 0.0, 11.0),
('Protein Shake', 'protein', 120.0, 1.0, 1.0, 24.0),
('Pork Chop', 'protein', 231.0, 13.0, 0.0, 27.0),

-- Carbs
('Quinoa', 'carbs', 222.0, 3.6, 5.2, 8.1),
('Brown Rice', 'carbs', 218.0, 1.6, 3.5, 4.5),
('Sweet Potato', 'carbs', 112.0, 0.1, 3.8, 2.0),
('White Bread', 'carbs', 265.0, 3.2, 2.7, 9.0),
('Whole Wheat Bread', 'carbs', 247.0, 3.4, 6.0, 13.0),
('Bagel', 'carbs', 289.0, 1.7, 2.3, 11.0),
('Couscous', 'carbs', 176.0, 0.3, 2.2, 6.0),
('Cereal', 'carbs', 379.0, 1.5, 5.0, 7.0),

-- Vegetables
('Carrots', 'vegetable', 41.0, 0.2, 2.8, 0.9),
('Kale', 'vegetable', 33.0, 0.5, 2.0, 2.9),
('Bell Peppers', 'vegetable', 31.0, 0.3, 2.1, 1.0),
('Tomatoes', 'vegetable', 18.0, 0.2, 1.2, 0.9),
('Cucumber', 'vegetable', 16.0, 0.1, 0.5, 0.7),
('Cauliflower', 'vegetable', 25.0, 0.3, 2.0, 1.9),
('Green Beans', 'vegetable', 31.0, 0.1, 3.4, 1.8),
('Lettuce', 'vegetable', 15.0, 0.2, 1.3, 1.4),

-- Fruits
('Apple', 'fruit', 95.0, 0.3, 4.4, 0.5),
('Banana', 'fruit', 105.0, 0.4, 3.1, 1.3),
('Orange', 'fruit', 62.0, 0.2, 3.1, 1.2),
('Strawberries', 'fruit', 49.0, 0.5, 3.0, 1.0),
('Blueberries', 'fruit', 84.0, 0.5, 2.4, 1.1),
('Grapes', 'fruit', 104.0, 0.2, 1.4, 1.1),
('Watermelon', 'fruit', 86.0, 0.4, 1.1, 1.7),
('Mango', 'fruit', 135.0, 0.6, 3.7, 1.1),

-- Fats/Oils
('Avocado', 'fat', 240.0, 22.0, 10.0, 3.0),
('Olive Oil', 'fat', 119.0, 13.5, 0.0, 0.0),
('Almonds', 'fat', 164.0, 14.0, 3.5, 6.0),
('Peanut Butter', 'fat', 188.0, 16.0, 1.9, 8.0),
('Walnuts', 'fat', 185.0, 18.5, 1.9, 4.3),
('Cheese', 'fat', 113.0, 9.0, 0.0, 7.0),
('Butter', 'fat', 102.0, 11.5, 0.0, 0.1),
('Cashews', 'fat', 157.0, 12.0, 0.9, 5.2),

-- Snacks
('Granola Bar', 'snack', 140.0, 5.0, 2.0, 3.0),
('Protein Bar', 'snack', 200.0, 7.0, 3.0, 20.0),
('Trail Mix', 'snack', 173.0, 11.0, 2.0, 5.0),
('Popcorn', 'snack', 55.0, 0.6, 2.0, 1.8),
('Rice Cakes', 'snack', 35.0, 0.3, 0.4, 0.7),
('Crackers', 'snack', 120.0, 4.0, 1.0, 2.5),
('Chips', 'snack', 152.0, 10.0, 1.0, 2.0),
('Pretzels', 'snack', 108.0, 1.0, 0.9, 2.6),

-- Additional Proteins / Legumes / Seafood
('Shrimp', 'protein', 99.0, 0.3, 0.0, 24.0),
('Lentils', 'protein', 116.0, 0.4, 7.9, 9.0),
('Chickpeas', 'protein', 164.0, 2.6, 7.6, 8.9),
('Black Beans', 'protein', 132.0, 0.5, 8.7, 8.9),
('Edamame', 'protein', 121.0, 5.2, 5.2, 11.0),
('Tempeh', 'protein', 193.0, 11.0, 0.0, 19.0),
('Seitan', 'protein', 143.0, 1.9, 0.6, 25.0),
('Sardines', 'protein', 208.0, 11.5, 0.0, 25.0),
('Herring', 'protein', 158.0, 9.0, 0.0, 18.0),
('Venison', 'protein', 158.0, 3.2, 0.0, 30.0),
('Lamb', 'protein', 294.0, 21.0, 0.0, 25.0),

-- Additional Carbs
('Barley', 'carbs', 354.0, 2.3, 17.3, 12.5),
('Millet', 'carbs', 378.0, 4.2, 8.5, 11.0),
('Buckwheat', 'carbs', 343.0, 3.4, 10.0, 13.3),
('Polenta', 'carbs', 70.0, 0.4, 1.0, 1.5),
('Soba Noodles', 'carbs', 99.0, 0.1, 0.0, 5.1),

-- Additional Vegetables
('Brussels Sprouts', 'vegetable', 43.0, 0.3, 3.8, 3.4),
('Eggplant', 'vegetable', 25.0, 0.2, 3.0, 1.0),
('Zucchini', 'vegetable', 17.0, 0.3, 1.0, 1.2),
('Asparagus', 'vegetable', 20.0, 0.1, 2.1, 2.2),

-- Additional Fruits
('Pineapple', 'fruit', 50.0, 0.1, 1.4, 0.5),
('Pear', 'fruit', 101.0, 0.2, 5.5, 0.6),
('Papaya', 'fruit', 43.0, 0.3, 1.7, 0.5),
('Kiwi', 'fruit', 61.0, 0.5, 3.0, 1.1),

-- Additional Fats / Oils / Seeds
('Flaxseed', 'fat', 534.0, 42.0, 27.0, 18.0),
('Chia Seeds', 'fat', 486.0, 31.0, 34.0, 17.0),
('Sunflower Seeds', 'fat', 584.0, 51.0, 8.6, 21.0),
('Ghee', 'fat', 900.0, 100.0, 0.0, 0.0),

-- Additional Snacks
('Beef Jerky', 'snack', 116.0, 3.0, 0.5, 9.4),
('Dark Chocolate', 'snack', 546.0, 31.0, 7.0, 5.0),
('Energy Ball', 'snack', 120.0, 6.0, 2.0, 4.0);
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
