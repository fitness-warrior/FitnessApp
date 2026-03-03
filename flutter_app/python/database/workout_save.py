import json
from login import CONN
from datetime import datetime


class WorkoutSave:

    def __init__(self, conn=CONN):
        self.conn = conn
        self.cur = self.conn.cursor()

    def save_workout(self, exercises: list, work_name: str = None):
        """
        Save a completed workout.
        exercises: list of {exer_id, exer_name, sets: [{kg, reps}]}
        Returns the new work_id.
        """
        now = datetime.now()
        name = work_name or f"Workout {now.strftime('%Y-%m-%d')}"

        self.cur.execute(
            """
            INSERT INTO completed_workouts (work_name, work_date)
            VALUES (%s, %s)
            RETURNING work_id
            """,
            (name, now),
        )
        work_id = self.cur.fetchone()[0]

        for ex in exercises:
            self.cur.execute(
                """
                INSERT INTO completed_workout_logs
                    (work_id, exer_id, exer_name, sets_data)
                VALUES (%s, %s, %s, %s)
                """,
                (
                    work_id,
                    ex.get("exer_id"),
                    ex.get("exer_name"),
                    json.dumps(ex.get("sets", [])),
                ),
            )

        self.conn.commit()
        return work_id

    def get_workouts(self):
        """Returns all saved workouts newest first."""
        self.cur.execute(
            "SELECT work_id, work_name, work_date FROM completed_workouts ORDER BY work_date DESC"
        )
        rows = self.cur.fetchall()
        return [
            {"work_id": r[0], "work_name": r[1], "work_date": str(r[2])}
            for r in rows
        ]

    def get_workout_logs(self, work_id: int):
        """Returns exercise logs for a specific workout."""
        self.cur.execute(
            "SELECT exer_id, exer_name, sets_data FROM completed_workout_logs WHERE work_id = %s",
            (work_id,),
        )
        rows = self.cur.fetchall()
        return [
            {
                "exer_id": r[0],
                "exer_name": r[1],
                "sets": json.loads(r[2]),
            }
            for r in rows
        ]
