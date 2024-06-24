import time
import requests
import psycopg
import logging.handlers
import vars
def get_net_device_usage_samples():
    ret = False
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    API_OBJ_RESPONSE_SIZE = 500
    fields = [
        'bytes_in',
        'bytes_out',
        'created_at',
        'net_device',
        'period',
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
        cursor.execute('SELECT to_json(COALESCE(date_trunc(\'day\',MAX("created_at")), (CURRENT_DATE-7)::TIMESTAMPTZ))#>>\'{}\' FROM cradlepoint.net_device_usage_samples;')
        lim = cursor.fetchone()[0]
        cursor.execute('DELETE FROM cradlepoint.net_device_usage_samples WHERE "created_at">=%s::TIMESTAMPTZ OR "created_at"<(CURRENT_DATE-365)::TIMESTAMPTZ;',(lim,))
        lim = lim.replace('+', '%2b')
        with cursor.copy("COPY cradlepoint.net_device_usage_samples ({}) FROM STDIN;".format(fields)) as copy:
            for chunk in id_chunks:
                url = "https://www.cradlepointecm.com/api/v2/net_device_usage_samples/?fields={0}&limit={1}&created_at__gt={2}&net_device__in={3}".format(fields, API_OBJ_RESPONSE_SIZE, lim, chunk)
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
            'INSERT INTO cradlepoint.net_device_usage_samples\n'
            'SELECT\n'
            '  SUM("bytes_in") AS "bytes_in",\n'
            '  SUM("bytes_out") AS "bytes_out",\n'
            '  MAX("created_at") AS "created_at",\n'
            '  NULL AS "net_device",\n'
            '  SUM("period") AS "period",\n'
            '  MAX("uptime") AS "uptime",\n'
            '  SUBSTRING("net_device", \'\\d+(?=/$)\')::INT AS "net_device_id"\n'
            'FROM cradlepoint.net_device_usage_samples\n'
            'WHERE "net_device_id" IS NULL\n'
            'GROUP BY "created_at"::DATE, "net_device";'
        )
        cursor.execute('DELETE FROM cradlepoint.net_device_usage_samples WHERE "net_device_id" IS NULL;')
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