import time
import requests
import psycopg
import logging.handlers
import vars
def get_net_devices():
    ret = False
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    API_OBJ_RESPONSE_SIZE = 50
    fields = [
        'apn',
        'bsid',
        'carrier',
        'carrier_id',
        'channel',
        'connection_state',
        'dns0',
        'dns1',
        'esn',
        'gateway',
        'gsn',
        'homecarrid',
        'hostname',
        'iccid',
        'id',
        'imei',
        'imsi',
        'ipv4_address',
        'ipv6_address',
        'is_asset',
        'is_gps_supported',
        'is_upgrade_supported',
        'ltebandwidth',
        'mac',
        'manufacturer',
        'mdn',
        'meid',
        'mfg_model',
        'mfg_product',
        'mn_ha_spi',
        'mn_ha_ss',
        'mode',
        'model',
        'modem_fw',
        'mtu',
        'nai',
        'name',
        'netmask',
        'pin_status',
        'port',
        'prlv',
        'profile',
        'rfband',
        'rfband5g',
        'rfchannel',
        'roam',
        'router',
        'rxchannel',
        'serial',
        'service_type',
        'ssid',
        'summary',
        'txchannel',
        'type',
        'uid',
        'updated_at',
        'uptime',
        'ver_pkg',
        'version',
        'wimax_realm'
    ]
    fields = ','.join(fields)
    try:
        conn = psycopg.connect(vars.conn_string)
        cursor = conn.cursor()
        cursor.execute('TRUNCATE cradlepoint.net_devices RESTART IDENTITY CASCADE;')
        with cursor.copy("COPY cradlepoint.net_devices ({}) FROM STDIN;".format(fields)) as copy:
            url = "https://www.cradlepointecm.com/api/v2/net_devices/?fields={0}&limit={1}".format(fields, API_OBJ_RESPONSE_SIZE)
            while url:
                vars.hits+=1
                if vars.hits%50==0:
                    time.sleep(10)
                req = requests.get(url, headers=vars.headers)
                req.raise_for_status()
                resp = req.json()
                url = resp['meta']['next']
                for net_device in resp['data']:
                    copy.write_row(net_device[column] for column in net_device.keys())
        cursor.execute('UPDATE cradlepoint.net_devices SET "router_id"=SUBSTRING("router", \'\\d+(?=/$)\')::INT, "router"=NULL WHERE "router" IS NOT NULL;')
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