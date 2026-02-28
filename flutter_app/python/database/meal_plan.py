from login import CONN

class MealPlanSelection:
    
    def __init__(self, CONN):
        self.conn = CONN
        self.cur = self.conn.cursor()
    
    def get_collections(self):
        self.cur.execute("""
            SELECT collection_id, collection_name, description
            FROM meal_collection
            ORDER BY collection_name
        """)
        return self.cur.fetchall()
    
    def get_foods_in_collection(self, collection_id):
        self.cur.execute("""
            SELECT f.food_id, f.food_name, f.food_type, f.food_calories
            FROM food f
            JOIN collection_foods cf ON f.food_id = cf.food_id
            WHERE cf.collection_id = %s
            ORDER BY f.food_name
        """, (collection_id,))
        return self.cur.fetchall()
    
    def filter_foods(self, collection_id=None, search_name=None, max_calories=None):
        query = "SELECT f.food_id, f.food_name, f.food_type, f.food_calories FROM food f"
        params = []
        conditions = []
        
        if collection_id:
            query += " JOIN collection_foods cf ON f.food_id = cf.food_id"
            conditions.append("cf.collection_id = %s")
            params.append(collection_id)
        
        if search_name:
            conditions.append("LOWER(f.food_name) LIKE LOWER(%s)")
            params.append(f"%{search_name}%")
        
        if max_calories:
            conditions.append("f.food_calories <= %s")
            params.append(max_calories)
        
        if conditions:
            query += " WHERE " + " AND ".join(conditions)
        
        query += " ORDER BY f.food_name"
        
        self.cur.execute(query, tuple(params))
        return self.cur.fetchall()