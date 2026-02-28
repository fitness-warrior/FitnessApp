from login import CONN
from datetime import datetime

class WorkoutPlanGenerator:

    def __init__(self, CONN):
        self.conn = CONN
        self.cur = self.conn.cursor()

    def auto_generate_plan(self, user_id, focus_type = 'strength', plan_name = 'Auto Generated Workout'):
        """
        Inputs:
        user_id (int): The user's ID
        focus_type (str): Either 'strength' or 'cardio'
        plan_name (str): Name for the workout plan
        
        Output:
        int: The work_id of the created plan, or None if failed
        """
        try:
            #Get Users body ID
            body_id = self._get_body_id(user_id)
            if not body_id:
                print(f"No body metrics found for user {user_id}")
                return None

            #Get exercises for the workout plan
            exercises = self._select_exercises(focus_type)
            if not exercises:
                print(f"No exercises found for type {focus_type}")
                return None
            
            #Create the workout plan in the database
            work_id = self._create_work_plan(body_id, plan_name, focus_type)
            
            #Add the exercises to the plan
            self._add_exercises_to_plan(work_id, exercises)
            
            print(f"Successfully created workout plan {work_id} with {len(exercises)} exercises")
            return work_id
            
        except Exception as e:
            print(f"Error generating workout plan: {e}")
            self.conn.rollback()
            return None
        
    def _get_body_id(self, user_id):
        
        self.cur.execute("""
            SELECT body_id 
            FROM body_metrics 
            WHERE user_id = %s
        """, (user_id,))
        
        result = self.cur.fetchone()
        return result[0] if result else None
    
    def _select_exercises(self, focus_type):

        # Define body areas
        body_areas = ['chest', 'legs', 'back', 'full body']
        selected_exercises = []
        
        for area in body_areas:
            # Get one exercise for each body area
            self.cur.execute("""
                SELECT exer_id 
                FROM exercise 
                WHERE exer_body_area = %s 
                AND exer_type = %s
                LIMIT 1
            """, (area, focus_type))
            
            result = self.cur.fetchone()
            if result:
                selected_exercises.append(result[0])
        
        return selected_exercises
    
    def _create_work_plan(self, body_id, plan_name, focus_type):
        
        now = datetime.now()
        
        self.cur.execute("""
            INSERT INTO work_plan (
                body_id, 
                work_name, 
                work_descrip, 
                work_created_at, 
                work_updated_at, 
                work_day
            )
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING work_id
        """, (
            body_id,
            plan_name,
            f'Auto-generated {focus_type} workout',
            now,
            now,
            now.date()
        ))
        
        self.conn.commit()
        work_id = self.cur.fetchone()[0]
        return work_id
    
    def _add_exercises_to_plan(self, work_id, exercise_ids):
        
        for exer_id in exercise_ids:
            self.cur.execute("""
                INSERT INTO plan_exercise (
                    work_id, 
                    exer_id, 
                    plan_exer_amount, 
                    plan_exer_PB,
                    plan_exer_PB_first
                )
                VALUES (%s, %s, %s, %s, %s)
            """, (
                work_id,
                exer_id,
                12,
                0,
                0
            ))
        
        self.conn.commit()

def test():
    """Test the workout plan generator"""
    generator = WorkoutPlanGenerator(CONN)
    
    # Test: Generate a strength workout for user 1
    work_id = generator.auto_generate_plan(
        user_id=1, 
        focus_type='strength',
        plan_name='My Auto Workout'
    )
    
    if work_id:
        print(f"✓ Created workout plan with ID: {work_id}")
    else:
        print("✗ Failed to create workout plan")


if __name__ == "__main__":
    test()
