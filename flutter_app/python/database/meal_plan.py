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
    
def test():
    selector = MealPlanSelection(CONN)
    
    print("=== MEAL PLAN SYSTEM TEST ===\n")
    
    # Test 1: Show all collections
    print("1. All Collections:")
    collections = selector.get_collections()
    for c in collections:
        print(f"   [{c[0]}] {c[1]}")
    print()
    
    # Test 2: Foods in Vegan collection (ID 1)
    print("2. Vegan Foods (first 5):")
    vegan = selector.get_foods_in_collection(1)
    for food in vegan[:5]:
        print(f"   - {food[1]} ({food[3]} cal)")
    print(f"   Total: {len(vegan)} foods\n")
    
    # Test 3: Filter within High Protein collection (ID 3)
    print("3. High Protein under 150 calories:")
    lean = selector.filter_foods(collection_id=3, max_calories=150)
    for food in lean:
        print(f"   - {food[1]} ({food[3]} cal)")
    print()
    
    # Test 4: Search across all foods
    print("4. Search 'chicken' (all collections):")
    chicken = selector.filter_foods(search_name='chicken')
    for food in chicken:
        print(f"   - {food[1]} ({food[2]}, {food[3]} cal)")
    print()


if __name__ == "__main__":
    test()