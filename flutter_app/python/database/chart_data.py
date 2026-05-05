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
        
    def cardio_speed(self,name):
        rows = self._collect_rows()
        final_collection = []
        for row in rows:
            speed = (row[2]*1000) / row[1]
            new_row = [row[0],speed]
            final_collection.append (new_row)
        return final_collection  
    
    def cardio_endurance(self,name):
        rows = self._collect_rows()
        final_collection = []
        for row in rows:
            new_row = [row[0],row[1]]
            final_collection.append (new_row)
        return final_collection 
    
    def cardio_endurance(self,name):
        rows = self._collect_rows()
        final_collection = []
        for row in rows:
            new_row = [row[0],row[2]]
            final_collection.append (new_row)
        return final_collection  
    
    def strength_total(self,name):
        rows = self._collect_rows()
        final_collection = []
        for row in rows:
            total = row[2] * row[3]
            new_row = [row[0],total]
            final_collection.append (new_row)
        return final_collection  
    
    def strength_max(self,name):
        rows = self._collect_rows()
        final_collection = []
        for row in rows:
            new_row = [row[0],row[2]]
            final_collection.append (new_row)
        return final_collection  
#if date is same select highest one lol 

if __name__ == "__main__":
    CD = CollectedData(4)
    print(CD.find_user_done())
    print(CD.cardio_speed("Jump Rope"))