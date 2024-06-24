import time
import requests
import psycopg
import logging.handlers
import vars
def get_net_device_health():
    ret = False
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    API_OBJ_RESPONSE_SIZE = 150
    fields = [
        'cellular_health_category',
        'cellular_health_score',
        'id',
        'net_device'
    ]
    fields = ','.join(fields)
    try:
        conn = psycopg.connect(vars.conn_string)
        cursor = conn.cursor()
        cursor.execute('DELETE FROM cradlepoint.net_device_health WHERE "date">=CURRENT_DATE;')
        with cursor.copy("COPY cradlepoint.net_device_health ({}) FROM STDIN;".format(fields)) as copy:
            url = "https://www.cradlepointecm.com/api/v2/net_device_health/?fields={0}&limit={1}".format(fields, API_OBJ_RESPONSE_SIZE)
            while url:
                vars.hits+=1
                if vars.hits%50==0:
                    time.sleep(10)
                req = requests.get(url, headers=vars.headers)
                req.raise_for_status()
                resp = req.json()
                url = resp['meta']['next']
                for health in resp['data']:
                    copy.write_row(health[column] for column in health.keys())
        conn.commit()
    except Exception as e:
        logger.exception(e)
        ret = True
    try:
        if (ret):
            conn.rollback()
        cursor.close()
        conn.close()
    except Exception as e:
        logger.exception(e)
        ret = True
    return ret