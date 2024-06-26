import time
import requests
import psycopg
import logging.handlers
import vars
def get_routers():
    ret = False
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    API_OBJ_RESPONSE_SIZE = 50
    fields = [
        'config_status',
        'created_at',
        'description',
        'device_type',
        'full_product_name',
        'id',
        'ipv4_address',
        'locality',
        'mac',
        'name',
        'reboot_required',
        'serial_number',
        'state',
        'state_updated_at',
        'updated_at',
        'upgrade_pending'
    ]
    fields = ','.join(fields)
    try:
        conn = psycopg.connect(vars.conn_string)
        cursor = conn.cursor()
        cursor.execute('TRUNCATE cradlepoint.routers RESTART IDENTITY CASCADE;')
        with cursor.copy("COPY cradlepoint.routers ({}) FROM STDIN;".format(fields)) as copy:
            url = "https://www.cradlepointecm.com/api/v2/routers/?fields={0}&limit={1}".format(fields, API_OBJ_RESPONSE_SIZE)
            while url:
                vars.hits+=1
                if vars.hits%50==0:
                    time.sleep(10)
                req = requests.get(url, headers=vars.headers)
                req.raise_for_status()
                resp = req.json()
                url = resp['meta']['next']
                for router in resp['data']:
                    copy.write_row(router[column] for column in router.keys())
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