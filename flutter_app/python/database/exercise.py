from login import CONN


class ExerciseSelection:

    def __init__(self, conn=CONN):
        self.conn = conn
        self.cur = self.conn.cursor()

    # note i have got the info from database but this needs to be give to the front end somehow
    def exer_filter(self, name=None, area=None, type=None, equipment=None):

        # Select exer_id as well so we can identify records from the frontend
        query = """
        SELECT e.exer_id, e.exer_name, e.exer_body_area, e.exer_type,
            e.exer_descrip, e.exer_vid, e.exer_equip,
            pe.plan_exer_set, pe.plan_exer_amount
        FROM exercise AS e
        JOIN plan_exercise AS pe ON e.exer_id = pe.exer_id
        WHERE 1=1
        """

        params = []

        if name:
            query += " AND e.exer_name ILIKE %s"
            params.append(f"%{name}%")

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
        rows = self.cur.fetchall()

        # Map DB rows (tuples) to dictionaries matching the API schema
        results = []
        for row in rows:
            # row layout: exer_id, exer_name, exer_body_area, exer_type, exer_descrip, exer_vid, exer_equip, plan_exer_set, plan_exer_amount
            exer_id, exer_name, exer_body_area, exer_type, exer_descrip, exer_vid, exer_equip, plan_sets, plan_reps = row

            # Normalize equipment into list (DB may store CSV string)
            if exer_equip is None:
                equipment_list = []
            elif isinstance(exer_equip, str) and "," in exer_equip:
                equipment_list = [e.strip() for e in exer_equip.split(",") if e.strip()]
            elif isinstance(exer_equip, str):
                equipment_list = [exer_equip]
            else:
                equipment_list = list(exer_equip)

            results.append({
                "id": exer_id,
                "name": exer_name,
                "body_area": exer_body_area,
                "type": exer_type,
                "description": exer_descrip,
                "video_url": exer_vid,
                "equipment": equipment_list,
                "plan": {"sets": plan_sets, "reps": plan_reps},
            })

        return results
        
    def auto_equipment(self, user_id):
        self.cur.execute("""
SELECT equipment_name
FROM equipment e
JOIN user_equip ue ON e.equip_id = ue.equip_id
WHERE ue.user_id = %s 
""", (user_id,))
        return [row[0] for row in self.cur.fetchall()]
        
def test():    
    plan = ExerciseSelection(CONN)
    equipment = plan.auto_equipment(2)
    results = plan.exer_filter(equipment=equipment)
    print(results)
    
if __name__ == "__main__":
    test()