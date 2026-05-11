from login import CONN


class CollectedData:

    def __init__(self,body_id, conn=CONN):
        self.body_id = body_id
        self.conn = conn
        self.cur = self.conn.cursor()

    def _formatted_date(self,unform):
        return unform.strftime("%Y-%m-%d")
    
    def _collect_rows(self,name):
        rows = self._get_train_name(name)
        if rows is None:
            return None
        formatted_rows = []
        for row in rows:
            formatted_row = list(row)
            formatted_row[0] = self._formatted_date(formatted_row[0])
            formatted_rows.append(formatted_row)
        return formatted_rows
    
    def _find_type(self,exer):
        measure = "kg"
        find = 3
        if exer == "cardio":
            measure = "km"
            find = 1
        return measure, find
    
    def find_user_done(self):
        self.cur.execute("""
            SELECT e.exer_name, e.exer_type, pe.plan_exer_PB
            FROM exercise e
            JOIN plan_exercise pe ON pe.exer_id = e.exer_id
            JOIN training_exercise te ON te.exer_id = e.exer_id
            JOIN training t ON t.train_id = te.train_id 
            JOIN training_body tb ON tb.train_id = t.train_id
            WHERE t.train_data IS NOT NULL
            AND tb.body_id = %s
            ORDER BY
                CASE WHEN e.exer_type = 'cardio' THEN 0 ELSE 1 END,
                pe.plan_exer_PB DESC
        """, (self.body_id,))
        return self.cur.fetchall()
    
    def find_body_type(self):
        self.cur.execute("""
            SELECT e.exer_body_area, COUNT(*) AS area_count
            FROM training t
            JOIN training_body tb ON tb.train_id = t.train_id
            JOIN training_exercise te ON te.train_id = t.train_id
            JOIN exercise e ON e.exer_id = te.exer_id
            WHERE tb.body_id = %s
              AND t.train_data IS NOT NULL
            GROUP BY e.exer_body_area
            ORDER BY area_count DESC, e.exer_body_area
        """, (self.body_id,))

        rows = self.cur.fetchall()
        if not rows:
            return []

        total_done = sum(row[1] for row in rows)
        if total_done == 0:
            return []

        return [
            {
                "body_area": row[0],
                "count": row[1],
                "percentage": round((row[1] / total_done) * 100, 2),
            }
            for row in rows
        ]
        
    def _get_train_name(self,name):
        self.cur.execute("""
            SELECT t.train_data, t.train_mins, t.train_effort, t.train_reps, e.exer_type
            FROM training t
            JOIN training_body tb ON tb.train_id = t.train_id
            JOIN training_exercise te ON te.train_id = t.train_id
            JOIN exercise e ON e.exer_id = te.exer_id 
            JOIN (
                SELECT t2.train_data AS train_data, MAX(t2.train_effort) AS max_effort
                FROM training t2
                JOIN training_body tb2 ON tb2.train_id = t2.train_id
                WHERE tb2.body_id = %s
                GROUP BY t2.train_data
            ) m ON t.train_data = m.train_data AND t.train_effort = m.max_effort
            WHERE tb.body_id = %s
            AND e.exer_name = %s
            ORDER BY t.train_data
            LIMIT 7
        """, (self.body_id, self.body_id, name))
        return self.cur.fetchall()

    def _get_cadio_callories (self):
        self.cur.execute("""
            SELECT t.train_data, t.train_mins, t.train_effort, bm.body_weight, e.exer_light, e.exer_mid, e.exer_high
            FROM training t
            JOIN training_exercise te ON t.train_id = te.train_id 
            JOIN exercise e ON e.exer_id = te.exer_id 
            JOIN training_body tb ON tb.train_id = t.train_id 
            JOIN body_metrics bm ON bm.body_id = tb.body_id 
            WHERE bm.body_id = %s
            AND e.exer_type = 'cardio'
            ORDER BY t.train_data
""", (self.body_id,))
        return self.cur.fetchall()
    
    def get_weight(self):
        self.cur.execute("""
            SELECT b.body_weight, b.body_weight_past
            FROM body_metrics
            WHERE bm.body_id = %s
""", (self.body_id,))
        return self.cur.fetchone()
    
    
    
#set a limmit for 7 days but not max how much 1 can do in a day 
    
    def day_cadio_callories (self):
        rows = self._get_cadio_callories()
        if not rows:
            return []
        
        final_collection = []
        date = self._formatted_date(rows[0][0])
        total = 0
        for row in rows:
            speed = (row[2]*1000) / row[1]
            
            if speed <= row[4]:
                met = 6
            elif speed <= row[5]:
                met = 8.3
            else:
                met = 10
                
            exerices_cal = met * row[3] * (row[1]/60)
            
            formatted_row_date = self._formatted_date(row[0])
            if formatted_row_date == date:
                total += exerices_cal
            else:
                final_collection.append([date, total])
                date = formatted_row_date
                total = exerices_cal
        
        # Append the final accumulated total
        final_collection.append([date, total])
        return final_collection
            
        #get all for the day ✅
        #calulate roundabout cal ✅
        #out put the last 7 days 
            
    
    def max_mins_weight (self,name):
        #1 = endurance
        #2 = distance/weight make code to know what one is needed km/kg
        rows = self._collect_rows(name)
        measure, find = self._find_type(rows[0][4])
        final_collection = []
        for row in rows:
            new_row = [row[0],row[find]]
            final_collection.append (new_row)
        return final_collection, measure

    def cardio_speed(self,name):
        rows = self._collect_rows(name)
        final_collection = []
        for row in rows:
            speed = (row[2]*1000) / row[1]
            #meter per min
            new_row = [row[0],speed]
            final_collection.append (new_row)
        return final_collection  
     
    def strength_total(self,name):
        rows = self._collect_rows(name)
        final_collection = []
        for row in rows:
            total = row[2] * row[3]
            new_row = [row[0],total]
            final_collection.append (new_row)
        return final_collection  
    
    def _get_meal_calories(self):
        """Get all meals and their calories for the past 7 days"""
        self.cur.execute("""
            SELECT mp.meal_day, f.food_calories
            FROM meal_plan mp
            JOIN food_plan fp ON fp.meal_id = mp.meal_id
            JOIN food f ON f.food_id = fp.food_id
            WHERE mp.body_id = %s
            AND mp.meal_day >= NOW() - INTERVAL 7 DAY
            ORDER BY mp.meal_day
        """, (self.body_id,))
        return self.cur.fetchall()
    
    def get_daily_calories_7(self):
        rows = self._get_meal_calories()
        if not rows:
            return []
        
        daily_totals = {}
        
        # Accumulate calories by day
        for row in rows:
            meal_date = self._formatted_date(row[0])
            calories = row[1]
            
            if meal_date not in daily_totals:
                daily_totals[meal_date] = 0
            daily_totals[meal_date] += calories
        
        # Convert to sorted list
        final_collection = []
        for date in sorted(daily_totals.keys()):
            final_collection.append([date, round(daily_totals[date], 2)])
        
        return final_collection
    
    def total_calories_7(self):
        intake_data = self.get_daily_calories_7()
        exercise_data = self.day_cadio_callories()
        
        # Create a dictionary for intake by date
        intake_by_date = {}
        for date, calories in intake_data:
            intake_by_date[date] = calories
        
        # Create a dictionary for exercise by date
        exercise_by_date = {}
        for date, calories in exercise_data:
            exercise_by_date[date] = calories
        
        # Combine both datasets
        all_dates = set(intake_by_date.keys()) | set(exercise_by_date.keys())
        final_collection = []
        
        for date in sorted(all_dates):
            intake = intake_by_date.get(date, 0)
            exercise = exercise_by_date.get(date, 0)
            final_collection.append({
                "date": date,
                "intake_calories": intake,
                "exercise_calories_burned": round(exercise, 2),
                "net_calories": round(intake - exercise, 2)
            })
        
        return final_collection
       

if __name__ == "__main__":
    CD = CollectedData(4)
    print(CD.find_user_done())
    print(CD.cardio_speed("Jump Rope")) #average
    print(CD.strength_total("Bench Press")) #add rep and weight
    print(CD.max_mins_weight("Jump Rope" )) #should be km and mins
    print(CD.max_mins_weight("Bench Press")) #should be kg and weight
    print(CD.find_body_type())
    print(CD.get_weight())
    
    print(CD.day_cadio_callories())
    