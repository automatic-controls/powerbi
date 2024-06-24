import time
import requests
import psycopg
import logging.handlers
import vars
def get_net_device_signal_samples():
    ret = False
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    API_OBJ_RESPONSE_SIZE = 500
    fields = [
        'cinr',
        'created_at',
        'dbm',
        'ecio',
        'net_device',
        'rsrp',
        'rsrp5g',
        'rsrp5g_highband',
        'rsrq',
        'rsrq5g',
        'rsrq5g_highband',
        'rssi',
        'rssnr',
        'signal_percent',
        'sinr',
        'sinr5g',
        'sinr5g_highband',
        'uptime'
    ]
    fields = ','.join(fields)
    try:
        conn = psycopg.connect(vars.conn_string)
        cursor = conn.cursor()
        cursor.execute('SELECT DISTINCT "id" FROM cradlepoint.net_devices;')
        id_chunks = []
        ids = cursor.fetchmany(100)
        while len(ids)>0:
            id_chunks.append(','.join(str(id[0]) for id in ids))
            ids = cursor.fetchmany(100)
        cursor.execute('SELECT to_json(COALESCE(date_trunc(\'day\',MAX("created_at")), (CURRENT_DATE-7)::TIMESTAMPTZ))#>>\'{}\' FROM cradlepoint.net_device_signal_samples;')
        lim = cursor.fetchone()[0]
        cursor.execute('DELETE FROM cradlepoint.net_device_signal_samples WHERE "created_at">=%s::TIMESTAMPTZ OR "created_at"<(CURRENT_DATE-365)::TIMESTAMPTZ;',(lim,))
        lim = lim.replace('+', '%2b')
        with cursor.copy("COPY cradlepoint.net_device_signal_samples ({}) FROM STDIN;".format(fields)) as copy:
            for chunk in id_chunks:
                url = "https://www.cradlepointecm.com/api/v2/net_device_signal_samples/?fields={0}&limit={1}&created_at__gt={2}&net_device__in={3}".format(fields, API_OBJ_RESPONSE_SIZE, lim, chunk)
                while url:
                    vars.hits+=1
                    if vars.hits%50==0:
                        time.sleep(10)
                    req = requests.get(url, headers=vars.headers)
                    req.raise_for_status()
                    resp = req.json()
                    url = resp['meta']['next']
                    for sample in resp['data']:
                        copy.write_row(sample[column] for column in sample.keys())
        cursor.execute(
            'INSERT INTO cradlepoint.net_device_signal_samples\n'
            'SELECT\n'
            '  AVG("cinr") AS "cinr",\n'
            '  MAX("created_at") AS "created_at",\n'
            '  AVG("dbm") AS "dbm",\n'
            '  AVG("ecio") AS "ecio",\n'
            '  NULL AS "net_device",\n'
            '  AVG("rsrp") AS "rsrp",\n'
            '  AVG("rsrp5g") AS "rsrp5g",\n'
            '  AVG("rsrp5g_highband") AS "rsrp5g_highband",\n'
            '  AVG("rsrq") AS "rsrq",\n'
            '  AVG("rsrq5g") AS "rsrq5g",\n'
            '  AVG("rsrq5g_highband") AS "rsrq5g_highband",\n'
            '  AVG("rssi") AS "rssi",\n'
            '  AVG("rssnr") AS "rssnr",\n'
            '  AVG("signal_percent") AS "signal_percent",\n'
            '  AVG("sinr") AS "sinr",\n'
            '  AVG("sinr5g") AS "sinr5g",\n'
            '  AVG("sinr5g_highband") AS "sinr5g_highband",\n'
            '  MAX("uptime") AS "uptime",\n'
            '  SUBSTRING("net_device", \'\\d+(?=/$)\')::INT AS "net_device_id"\n'
            'FROM cradlepoint.net_device_signal_samples\n'
            'WHERE "net_device_id" IS NULL\n'
            'GROUP BY "created_at"::DATE, "net_device";'
        )
        cursor.execute('DELETE FROM cradlepoint.net_device_signal_samples WHERE "net_device_id" IS NULL;')
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