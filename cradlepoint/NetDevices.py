import os
import requests
import psycopg2
from psycopg2.extensions import AsIs
import logging.handlers

def get_net_devices():
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

    API_OBJ_RESPONSE_SIZE = 50

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

    conn_string = "host={0} user={1} dbname={2} password={3} sslmode={4}".format(host, db_user, db, db_pass, 'require')
    try:
        conn = psycopg2.connect(conn_string)
        cursor = conn.cursor()
        truncate = 'TRUNCATE cradlepoint.net_devices RESTART IDENTITY CASCADE'
        cursor.execute(truncate)
        url = 'https://www.cradlepointecm.com/api/v2/net_devices/?limit={}'. \
            format(API_OBJ_RESPONSE_SIZE)
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
                for net_device in resp['data']:
                    url = next_url(resp)
                    columns = net_device.keys()
                    values = [net_device[column] for column in columns]
                    insert = 'INSERT INTO cradlepoint.net_devices (%s) values %s'
                    cursor.execute(insert, (AsIs(','.join(columns)), tuple(values)))
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