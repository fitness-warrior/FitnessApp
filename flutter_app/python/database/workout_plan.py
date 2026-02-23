from login import CONN
from datetime import datetime

class WorkoutPlanGenerator:

    def __init__(self, CONN):
        self.CONN = CONN
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
