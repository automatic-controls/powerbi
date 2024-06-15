import os
import requests
import psycopg2
import logging.handlers

def get_routers():
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
        truncate = 'TRUNCATE cradlepoint.routers RESTART IDENTITY CASCADE'
        cursor.execute(truncate)
        url = 'https://www.cradlepointecm.com/api/v2/routers/?limit={}'. \
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
                for router in resp['data']:
                    url = next_url(resp)
                    columns = router.keys()
                    values = [router[column] for column in columns]
                    insert = 'INSERT INTO cradlepoint.routers (account, actual_firmware, asset_id, config_status, configuration_manager, created_at, custom1, custom2, description, device_type, full_product_name, "group", id, ipv4_address, lans, last_known_location, locality, mac, name, overlay_network_binding, product, reboot_required, resource_url, serial_number, state, state_updated_at, target_firmware, updated_at, upgrade_pending) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)'
                    cursor.execute(insert, tuple(values))
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