import os
import requests
import psycopg2
from psycopg2.extensions import AsIs
from datetime import datetime
import logging.handlers

def get_net_device_signal():
    ret = False
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.ERROR)
    cp_api_id = os.environ["X_CP_API_ID"]
    cp_api_key = os.environ["X_CP_API_KEY"]
    ecm_api_id = os.environ["X_ECM_API_ID"]
    ecm_api_key = os.environ["X_ECM_API_KEY"]
    host = os.environ["postgresql_url"]
    #db = os.environ["postgresql_database"]
    db = "deviceanalytics"
    db_user = os.environ["postgresql_user"]
    db_pass = os.environ["postgresql_pass"]

    API_OBJ_REQUEST_SIZE = 100
    API_OBJ_RESPONSE_SIZE = 500

    # Chunk lists into blocks
    def chunker(seq, size):
        return (seq[pos:pos + size] for pos in range(0, len(seq), size))

    # Get the next url, at completion return None
    def next_url(resp):
        if resp['meta']['next']:
            url = resp['meta']['next']
        else:
            url = None
        return url

    # Cradlepoint API keys
    headers = {
        'X-CP-API-ID': cp_api_id,
        'X-CP-API-KEY': cp_api_key,
        'X-ECM-API-ID': ecm_api_id,
        'X-ECM-API-KEY': ecm_api_key,
        'Content-Type': 'application/json'
    }

    # Connect to devicesanalytics postgres
    conn_string = "host={0} user={1} dbname={2} password={3} sslmode={4}".format(host, db_user, db, db_pass, 'require')
    try:
        conn = psycopg2.connect(conn_string)
        cursor = conn.cursor()

        #Truncate records > today - 1 day; we go back 1 day when syncing to avoid conflicts
        truncate_usage = "DELETE FROM cradlepoint.net_device_signal WHERE DATE_TRUNC('day',created_at) >= current_date - interval '1 day'"
        cursor.execute(truncate_usage)

        # Get all net_devices
        devices_from_db = "select id from cradlepoint.net_devices where carrier_id like 'Verizon%' order by id"
        cursor.execute(devices_from_db)
        net_device_ids = set(row[0] for row in cursor.fetchall())

        # Get last successful net_device_signal sync
        pg_date = "select max(next_run) as next_run from cradlepoint.run_history where entity = 'net_device_signal_samples'"
        cursor.execute(pg_date)
        max_date = cursor.fetchone()[0]
        SIGNAL_START_DATE = max_date.strftime("%Y-%m-%d")

        # Get signal samples
        for net_devices in chunker(sorted(net_device_ids), API_OBJ_REQUEST_SIZE):
            url = 'https://www.cradlepointecm.com/api/v2/net_device_signal_samples/' \
                '?limit={}'.format(API_OBJ_RESPONSE_SIZE)
            url += '&net_device__in={}'.format(','.join(map(str, net_devices)))
            url += '&created_at__gt={}'.format(SIGNAL_START_DATE)
            url += '&order_by=created_at_timeuuid'

            try:
                req = requests.get(url, headers=headers)
                req.raise_for_status()
            except requests.exceptions.HTTPError as errh:
                logger.exception(errh)
                ret = True
            except requests.exceptions.ConnectionError as errc:
                logger.exception(errc)
                ret = True
            except requests.exceptions.Timeout as errt:
                logger.exception(errt)
                ret = True
            except requests.exceptions.RequestException as err:
                logger.exception(err)
                ret = True
            else:
                while url:
                    req = requests.get(url, headers=headers)
                    resp = req.json()
                    if (len(resp['data']) > 0):
                        for usage in resp['data']:
                            url = next_url(resp)
                            columns = usage.keys()
                            values = [usage[column] for column in columns]
                            insert = 'INSERT INTO cradlepoint.net_device_signal (%s) VALUES %s'
                            cursor.execute(insert, (AsIs(','.join(columns)), tuple(values)))

        # Insert signal_samples timestamp into run_history
        insert = """INSERT INTO cradlepoint.run_history (entity, last_run, next_run) VALUES (%s, %s, %s)"""
        ulast_run = datetime.utcnow()
        unext_run = datetime.utcnow().replace(hour=0, minute=0, second = 0, microsecond=0)
        cursor.execute(insert, ('net_device_signal_samples',ulast_run, unext_run))

        # Commit database transactions and close the connection
        conn.commit()
    except Exception as e:
        logger.exception(e)
        ret = True
    try:
        cursor.close()
        conn.close()
    except Exception as e:
        logger.exception(e)
        ret = True
    return ret