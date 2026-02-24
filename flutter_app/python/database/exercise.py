from login import CONN

class ExersiseSelection():
    
    def __init__(self, CONN):
        self.conn = CONN
        self.cur = self.conn.cursor()

    # note i have got the info from database but this needs to be give to the front end somehow
    def exer_filter(self, name=None, area=None, type=None, equipment=None):
        
        query = """
        SELECT e.exer_name, e.exer_body_area, e.exer_type,
            e.exer_descrip, e.exer_vid, e.exer_equip,
            pe.plan_exer_set, pe.plan_exer_amount
        FROM exersise AS e
        JOIN plan_exersise AS pe ON e.exer_id = pe.exer_id
        WHERE 1=1
        """

        params = []

        if name:
            query += " AND e.exer_name = %s"
            params.append(name)

        if area:
            query += " AND e.exer_body_area = %s"
            params.append(area)

        if type:
            query += " AND e.exer_type = %s"
            params.append(type)

        if equipment:
            # accept list of strings or list of single-value tuples from fetchall()
            if isinstance(equipment, list) and equipment and isinstance(equipment[0], tuple):
                equipment = [row[0] for row in equipment]
            elif isinstance(equipment, tuple):
                equipment = list(equipment)

            placeholders = ", ".join(["%s"] * len(equipment))
            query += f" AND e.exer_equip IN ({placeholders})"
            params.extend(equipment)

        self.cur.execute(query, tuple(params))
        
        return self.cur.fetchall()
        
    def auto_equipment(self, user_id):
        self.cur.execute("""
SELECT equipment_name
FROM equipment e
JOIN user_equip ue ON e.equip_id = ue.equip_id
WHERE ue.user_id = %s 
""", (user_id,))
        return [row[0] for row in self.cur.fetchall()]
        
def test():    
    plan = ExersiseSelection(CONN)
    equipment = plan.auto_equipment(2)
    results = plan.exer_filter(equipment=equipment)
    print(results)
    
if __name__ == "__main__":
    test()