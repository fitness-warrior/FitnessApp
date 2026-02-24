import json
from unittest.mock import patch, MagicMock
import pytest

from exercises_api import app


@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


def test_create_exercise_validation(client):
    # Missing required field exer_name
    payload = {
        'exer_body_area': 'area',
        'exer_type': 'strength',
        'exer_equip': 'Dumbbells'
    }
    res = client.post('/api/exercises', data=json.dumps(payload), content_type='application/json', headers={'X-Admin':'true'})
    assert res.status_code == 400


@patch('exercises_api.CONN')
def test_create_exercise_db_error(mock_conn, client):
    # Simulate DB failure during insert
    mock_cur = MagicMock()
    mock_cur.fetchone.side_effect = Exception('db failure')
    mock_conn.cursor.return_value = mock_cur

    payload = {
        'exer_name': 'unit_db_error',
        'exer_body_area': 'area',
        'exer_type': 'strength',
        'exer_equip': 'Dumbbells'
    }

    res = client.post('/api/exercises', data=json.dumps(payload), content_type='application/json', headers={'X-Admin':'true'})
    # API should return 500 on unexpected DB exceptions
    assert res.status_code == 500 or res.status_code == 400
