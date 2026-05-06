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
        for row in rows:
            row[0] = self._formatted_date(row[0])
        return rows
    
    def find_user_done(self):
        self.cur.execute("""
            SELECT e.exer_name, pe.plan_exer_PB
            FROM exercise e
            JOIN plan_exercise pe ON pe.exer_id = e.exer_id
            JOIN training_exercise te ON te.exer_id = e.exer_id
            JOIN training t ON t.train_id = te.train_id 
            JOIN training_body tb ON tb.train_id = t.train_id
            WHERE t.train_data IS NOT NULL
            AND tb.body_id = %s
            ORDER BY pe.plan_exer_PB DESC
        """, (self.body_id,))
        return self.cur.fetchall()
    
    
    def _get_train_name(self,name):
        self.cur.execute("""
            SELECT t.train_data, t.train_mins, t.train_effort, t.train_reps
            FROM training t
            JOIN training_body tb ON tb.train_id = t.train_id
            JOIN (
                SELECT t2.train_data AS train_data, MAX(t2.train_effort) AS max_effort
                FROM training t2
                JOIN training_body tb2 ON tb2.train_id = t2.train_id
                WHERE tb2.body_id = %s
                GROUP BY t2.train_data
            ) m ON t.train_data = m.train_data AND t.train_effort = m.max_effort
            WHERE tb.body_id = %s
            ORDER BY t.train_data
            LIMIT 7
        """, (self.body_id, self.body_id))
        return self.cur.fetchall()
    
    def _get_cadio_callories (self):
        self.cur.execute("""
            SELECT t.train_data, t.train_mins, t.train_effort, bm.body_weight, e.exer_easy, e.exer_mid, e.exer_hard,
            FROM training t
            JOIN training_exercise te ON t.train_id = te.train_id 
            JOIN exercies e ON e.exer_id = te.exer_id 
            JOIN training_body tb ON tb.train_id = t.train_id 
            JOIN body_metrics bm ON bm.body_id = tb.body_id 
            Where bm.body_id = %s
            AND exer_type = "cardio"
            ORDER BY t.train_data
""", (self.body_id))
        return self.cur.fetchall()
    
#set a limmit for 7 days but not max how much 1 can do in a day 
    
    def day_cadio_callories (self):
        rows = self._get_cadio_callories()
        final_collection = []
        i = 0
        date = rows[0][0]
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
            
            if row[0] == date:
                total += exerices_cal
            else:
                final_collection.append(row[0],total)
                total = 0
            
            i += 1
            
        #get all for the day ✅
        #calulate roundabout cal ✅
        #out put the last 7 days 
            
    
    def no_change_data (self,name,find):
        #1 = endurance
        #2 = distance/weight make code to know what one is needed km/kg
        rows = self._collect_rows(name)
        final_collection = []
        for row in rows:
            new_row = [row[0],row[find]]
            final_collection.append (new_row)
        return final_collection 

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
      

if __name__ == "__main__":
    CD = CollectedData(4)
    print(CD.find_user_done())
    print(CD.cardio_speed("Jump Rope"))