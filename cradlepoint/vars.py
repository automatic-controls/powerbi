import os
hits = 0
conn_string = "host={0} port={1} user={2} dbname={3} password={4} sslmode={5}".format(
    os.environ["_postgresql_url"],
    os.environ["_postgresql_port"],
    os.environ["_postgresql_user"],
    os.environ["_postgresql_database"],
    os.environ["_postgresql_pass"],
    'require'
)
headers = {
    'X-CP-API-ID': os.environ["X_CP_API_ID"],
    'X-CP-API-KEY': os.environ["X_CP_API_KEY"],
    'X-ECM-API-ID': os.environ["X_ECM_API_ID"],
    'X-ECM-API-KEY': os.environ["X_ECM_API_KEY"],
    'Content-Type': 'application/json'
}