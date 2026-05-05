from login import CONN


class CollectedData:

    def __init__(self,body_id, conn=CONN):
        self.body_id = body_id
        self.conn = conn
        self.cur = self.conn.cursor()

    def _formatted_date(self,unform):
        return unform.strftime("%Y-%m-%d")
    
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
            SELECT t.train_data, t.train_mins, t.train_effort, t.reps 
            FROM exercise e
            JOIN plan_exercise pe ON pe.exer_id = e.exer_id
            JOIN training_exercise te ON te.exer_id = e.exer_id
            JOIN training t ON t.train_id = te.train_id 
            JOIN training_body tb ON tb.train_id = t.train_id
            WHERE tb.body_id = %s
            ORDER BY pe.plan_exer_PB
            LIMIT 7
        """, (self.body_id,))
        return self.cur.fetchall()
        
    def cardio_speed(self,name)
        row =  self._get_train_name
        if row is None:
            return None

        date = self._formatted_date(row[0])
        speed = (row[2]*1000) / row[1]
        return (date, speed)


if __name__ == "__main__":
    CD = CollectedData(4)
    print(CD.find_user_done())
    print(CD.cardio_speed("Jump Rope"))