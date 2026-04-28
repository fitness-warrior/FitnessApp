from .login import CONN


class CollectedData:

    def __init__(self,body_id, conn=CONN):
        self.body_id = body_id
        self.conn = conn
        self.cur = self.conn.cursor()

    def find_user_done(self):
        self.cur.execute("""
            SELECT e.exer_name, pe.plan_exer_PB
            FROM exersise
            JOIN plan_exercise pe ON pe.exer_id = e.exer_id
            JOIN training_exersise te ON te.exer_id = e.exer_id
            JOIN training t ON t.train_id = te.train_id 
            JOIN training_body tb ON tb.train_id = t.train_id
            WHERE t.train_data IS NOT NULL
            AND tb.body_id = %s
            ORDER BY pe.plan_exer_PB
        """, (self.body_id,))
        return self.cur.fetchall()
    
    def cardio_speed(self,name):
        self.cur.execute("""
            SELECT t.train_data
            FROM exersise
            JOIN plan_exercise pe ON pe.exer_id = e.exer_id
            JOIN training_exersise te ON te.exer_id = e.exer_id
            JOIN training t ON t.train_id = te.train_id 
            JOIN training_body tb ON tb.train_id = t.train_id
            WHERE t.train_data IS NOT NULL
            AND tb.body_id = %s
            ORDER BY pe.plan_exer_PB
        """, (self.body_id,))
        return self.cur.fetchall()
