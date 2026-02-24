import json
import pytest
from exercises_api import app
from login import CONN

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

@pytest.fixture
def cursor():
    cur = CONN.cursor()
    yield cur
    cur.close()


@pytest.fixture(autouse=True)
def transactional(cursor):
    """Create a savepoint before each test and rollback after to keep DB state isolated.

    Requires the app to set `app.config['TESTING'] = True` so handlers avoid committing.
    """
    try:
        cursor.execute("SAVEPOINT test_sp")
    except Exception:
        pass
    yield
    try:
        cursor.execute("ROLLBACK TO SAVEPOINT test_sp")
        cursor.execute("RELEASE SAVEPOINT test_sp")
    except Exception:
        pass

def test_create_and_get_exercise(client, cursor):
    # Create a unique exercise
    payload = {
        'exer_name': 'test_create_get_exer',
        'exer_body_area': 'test_area',
        'exer_type': 'strength',
        'exer_descrip': 'Test description',
        'exer_vid': '',
        'exer_equip': 'Dumbbells'
    }
    res = client.post('/api/exercises', data=json.dumps(payload), content_type='application/json', headers={'X-Admin':'true'})
    assert res.status_code == 201
    data = res.get_json()
    assert 'exer_id' in data
    exer_id = data['exer_id']

    # Fetch the created exercise
    res2 = client.get(f'/api/exercises/{exer_id}')
    assert res2.status_code == 200
    fetched = res2.get_json()
    assert fetched['exer_id'] == exer_id
    assert fetched['exer_name'] == payload['exer_name']
    assert fetched['exer_descrip'] == payload['exer_descrip']

    # Cleanup
    cursor.execute('DELETE FROM plan_exersise WHERE exer_id = %s', (exer_id,))
    cursor.execute('DELETE FROM exersise WHERE exer_id = %s', (exer_id,))
    CONN.commit()


def test_list_filter_by_name_and_equipment(client, cursor):
    # Insert two test exercises
    cursor.execute("SELECT exer_id FROM exersise WHERE exer_name = %s", ('test_filter_exer_1',))
    if not cursor.fetchone():
        cursor.execute('''
            INSERT INTO exersise (exer_name, exer_body_area, exer_type, exer_descrip, exer_vid, exer_equip)
            VALUES (%s,%s,%s,%s,%s,%s) RETURNING exer_id
        ''', ('test_filter_exer_1','area1','strength','desc1','', 'Dumbbells'))
        id1 = cursor.fetchone()[0]
    else:
        cursor.execute('SELECT exer_id FROM exersise WHERE exer_name = %s', ('test_filter_exer_1',))
        id1 = cursor.fetchone()[0]

    cursor.execute("SELECT exer_id FROM exersise WHERE exer_name = %s", ('test_filter_exer_2',))
    if not cursor.fetchone():
        cursor.execute('''
            INSERT INTO exersise (exer_name, exer_body_area, exer_type, exer_descrip, exer_vid, exer_equip)
            VALUES (%s,%s,%s,%s,%s,%s) RETURNING exer_id
        ''', ('test_filter_exer_2','area2','cardio','desc2','', 'Bodyweight Only'))
        id2 = cursor.fetchone()[0]
    else:
        cursor.execute('SELECT exer_id FROM exersise WHERE exer_name = %s', ('test_filter_exer_2',))
        id2 = cursor.fetchone()[0]

    CONN.commit()

    # Filter by name
    res = client.get('/api/exercises?name=test_filter_exer_1')
    assert res.status_code == 200
    items = res.get_json()
    assert any(it['exer_name'] == 'test_filter_exer_1' for it in items)

    # Filter by equipment
    res2 = client.get('/api/exercises?equipment=Dumbbells')
    assert res2.status_code == 200
    items2 = res2.get_json()
    # At least one item with Dumbbells (our inserted one should be included)
    assert any(it['exer_equip'] == 'Dumbbells' and it['exer_name'] == 'test_filter_exer_1' for it in items2)

    # Cleanup inserted test rows
    cursor.execute('DELETE FROM plan_exersise WHERE exer_id IN (%s, %s)', (id1, id2))
    cursor.execute('DELETE FROM exersise WHERE exer_id IN (%s, %s)', (id1, id2))
    CONN.commit()


def test_create_plan_exercise_and_inclusion_in_get(client, cursor):
    # Create a test exercise
    cursor.execute('''
        INSERT INTO exersise (exer_name, exer_body_area, exer_type, exer_descrip, exer_vid, exer_equip)
        VALUES (%s,%s,%s,%s,%s,%s) RETURNING exer_id
    ''', ('test_plan_exer','area_plan','strength','desc','', 'Dumbbells'))
    exer_id = cursor.fetchone()[0]

    # Create a test work_plan (minimal)
    cursor.execute('INSERT INTO work_plan (body_id, work_name) VALUES (%s,%s) RETURNING work_id', (1, 'test_work_plan'))
    work_id = cursor.fetchone()[0]
    CONN.commit()

    # Link exercise to plan via API
    payload = {'work_id': work_id, 'exer_id': exer_id, 'sets': 3, 'reps': 10}
    res = client.post('/api/plan_exercises', data=json.dumps(payload), content_type='application/json', headers={'X-Admin':'true'})
    assert res.status_code == 201
    data = res.get_json()
    assert 'plan_exer_id' in data

    # Fetch exercise and confirm plan data present
    res2 = client.get(f'/api/exercises/{exer_id}')
    assert res2.status_code == 200
    fetched = res2.get_json()
    assert fetched['plan'] is not None
    assert fetched['plan']['sets'] == 3
    assert fetched['plan']['reps'] == 10

    # Cleanup
    cursor.execute('DELETE FROM plan_exersise WHERE exer_id = %s', (exer_id,))
    cursor.execute('DELETE FROM work_plan WHERE work_id = %s', (work_id,))
    cursor.execute('DELETE FROM exersise WHERE exer_id = %s', (exer_id,))
    CONN.commit()
