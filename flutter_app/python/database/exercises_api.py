from flask import Flask, request, jsonify, abort, Response
from login import CONN
import logging
from logging.handlers import RotatingFileHandler
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

# --- Logging configuration ---
logger = logging.getLogger('exercises_api')
logger.setLevel(logging.INFO)
handler = RotatingFileHandler('exercises_api.log', maxBytes=5 * 1024 * 1024, backupCount=2)
formatter = logging.Formatter('%(asctime)s %(levelname)s %(name)s %(message)s')
handler.setFormatter(formatter)
logger.addHandler(handler)

# Log every request
@app.before_request
def log_request_info():
    logger.info('request start', extra={
        'method': request.method,
        'path': request.path,
        'args': dict(request.args),
        'remote_addr': request.remote_addr,
    })

# --- Basic Prometheus metrics ---
REQ_COUNTER = Counter('ex_api_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'http_status'])
ERR_COUNTER = Counter('ex_api_exceptions_total', 'Total exceptions')


@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok'}), 200


@app.route('/metrics')
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

# Helper to convert DB rows to dicts for exercise list/detail
def row_to_exercise(row):
    # row = (exer_id, exer_name, exer_body_area, exer_type, exer_descrip, exer_vid, exer_equip, plan_exer_set, plan_exer_amount)
    return {
        "exer_id": row[0],
        "exer_name": row[1],
        "exer_body_area": row[2],
        "exer_type": row[3],
        "exer_descrip": row[4],
        "exer_vid": row[5],
        "exer_equip": row[6],
        "plan": {"sets": row[7], "reps": row[8]} if row[7] is not None else None
    }


@app.route('/api/exercises', methods=['GET'])
def list_exercises():
    name = request.args.get('name')
    area = request.args.get('area')
    foc_type = request.args.get('type')
    equipment = request.args.getlist('equipment')

    query = '''
    SELECT e.exer_id, e.exer_name, e.exer_body_area, e.exer_type,
           e.exer_descrip, e.exer_vid, e.exer_equip,
           pe.plan_exer_set, pe.plan_exer_amount
    FROM exersise AS e
    LEFT JOIN plan_exersise AS pe ON e.exer_id = pe.exer_id
    WHERE 1=1
    '''
    params = []

    if name:
        query += ' AND e.exer_name = %s'
        params.append(name)
    if area:
        query += ' AND e.exer_body_area = %s'
        params.append(area)
    if foc_type:
        query += ' AND e.exer_type = %s'
        params.append(foc_type)
    if equipment:
        # filter by equipment names (exact match)
        placeholders = ','.join(['%s'] * len(equipment))
        query += f' AND e.exer_equip IN ({placeholders})'
        params.extend(equipment)

    cur = CONN.cursor()
    cur.execute(query, tuple(params))
    rows = cur.fetchall()
    cur.close()

    results = [row_to_exercise(r) for r in rows]
    # commit only when not running tests to allow transactional isolation in tests
    if not app.config.get('TESTING'):
        CONN.commit()
    return jsonify(results)


@app.route('/api/exercises/<int:exer_id>', methods=['GET'])
def get_exercise(exer_id):
    cur = CONN.cursor()
    cur.execute('''
        SELECT e.exer_id, e.exer_name, e.exer_body_area, e.exer_type,
               e.exer_descrip, e.exer_vid, e.exer_equip,
               pe.plan_exer_set, pe.plan_exer_amount
        FROM exersise AS e
        LEFT JOIN plan_exersise AS pe ON e.exer_id = pe.exer_id
        WHERE e.exer_id = %s
    ''', (exer_id,))
    row = cur.fetchone()
    cur.close()
    if not row:
        abort(404, description='Exercise not found')
    return jsonify(row_to_exercise(row))


def require_admin():
    # Simple placeholder auth: require header X-Admin: true
    admin = request.headers.get('X-Admin', 'false').lower()
    if admin != 'true':
        abort(403, description='Admin only')


@app.route('/api/exercises', methods=['POST'])
def create_exercise():
    require_admin()
    data = request.get_json() or {}
    required = ['exer_name', 'exer_body_area', 'exer_type', 'exer_equip']
    for f in required:
        if f not in data:
            abort(400, description=f'Missing field: {f}')

    cur = CONN.cursor()
    cur.execute('''
        INSERT INTO exersise (exer_name, exer_body_area, exer_type, exer_descrip, exer_vid, exer_equip)
        VALUES (%s, %s, %s, %s, %s, %s) RETURNING exer_id
    ''', (
        data.get('exer_name'),
        data.get('exer_body_area'),
        data.get('exer_type'),
        data.get('exer_descrip'),
        data.get('exer_vid'),
        data.get('exer_equip'),
    ))
    new_id = cur.fetchone()[0]
    if not app.config.get('TESTING'):
        CONN.commit()
    cur.close()
    return jsonify({'exer_id': new_id}), 201


@app.route('/api/plan_exercises', methods=['POST'])
def create_plan_exercise():
    require_admin()
    data = request.get_json() or {}
    required = ['work_id', 'exer_id', 'sets', 'reps']
    for f in required:
        if f not in data:
            abort(400, description=f'Missing field: {f}')

    cur = CONN.cursor()
    cur.execute('''
        INSERT INTO plan_exersise (work_id, exer_id, plan_exer_amount, plan_exer_set)
        VALUES (%s, %s, %s, %s) RETURNING plan_exer_id
    ''', (
        data.get('work_id'),
        data.get('exer_id'),
        data.get('reps'),
        data.get('sets'),
    ))
    new_id = cur.fetchone()[0]
    if not app.config.get('TESTING'):
        CONN.commit()
    cur.close()
    return jsonify({'plan_exer_id': new_id}), 201


if __name__ == '__main__':
    app.run(port=5001, debug=True)
