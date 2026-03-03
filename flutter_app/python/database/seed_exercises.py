from login import CONN

EXERCISES = [
    {
        'exer_name': 'Kettlebell Swing',
        'exer_body_area': 'full body',
        'exer_type': 'strength',
        'exer_descrip': 'Hip-hinge explosive swing: hinge at hips, keep back flat, drive hips forward.',
        'exer_vid': '',
        'exer_equip': 'Dumbbells'
    },
    {
        'exer_name': 'Walking Lunge',
        'exer_body_area': 'legs',
        'exer_type': 'strength',
        'exer_descrip': 'Step forward into lunge, keep torso upright, push through front heel to return.',
        'exer_vid': '',
        'exer_equip': 'Bodyweight Only'
    },
    {
        'exer_name': 'Mountain Climbers',
        'exer_body_area': 'full body',
        'exer_type': 'cardio',
        'exer_descrip': 'From plank, drive knees toward chest alternating fast. Keep core tight.',
        'exer_vid': '',
        'exer_equip': 'Bodyweight Only'
    }
]


def seed():
    cur = CONN.cursor()
    inserted = []
    for ex in EXERCISES:
        # check if exercise exists by name
        cur.execute('SELECT exer_id FROM exercise WHERE exer_name = %s', (ex['exer_name'],))
        row = cur.fetchone()
        if row:
            inserted.append((ex['exer_name'], row[0], False))
            continue
        cur.execute('''
            INSERT INTO exercise (exer_name, exer_body_area, exer_type, exer_descrip, exer_vid, exer_equip)
            VALUES (%s, %s, %s, %s, %s, %s) RETURNING exer_id
        ''', (
            ex['exer_name'], ex['exer_body_area'], ex['exer_type'], ex['exer_descrip'], ex['exer_vid'], ex['exer_equip']
        ))
        new_id = cur.fetchone()[0]
        inserted.append((ex['exer_name'], new_id, True))
    CONN.commit()
    cur.close()
    for name, eid, created in inserted:
        status = 'created' if created else 'exists'
        print(f"{name}: {status} (id={eid})")


if __name__ == '__main__':
    seed()
