import json

connection_strings = {
    "KveMasterDb": "Server=dc2d-employee-mssql-01.citigo.io;Database=KiotVietMasterEmployeeDev;User=sa;Password=mssql#C1t1g0@sa;App=KveApi",
    "FnB_KiotVietTimeSheetDatabase": "Server=dc2d-employee-mssql-01.citigo.io;Database=FnbTimeSheetDev;Persist security info=True;User Id=sa;Password=mssql#C1t1g0@sa;MultipleActiveResultSets=True;Max Pool Size=10000;App=KveApi",
    "FnB_KiotVietTimeSheetDatabase9": "Server=dc2d-employee-mssql-01.citigo.io;Database=FnbTimeSheetDev;Persist security info=True;User id=sa;password=mssql#C1t1g0@sa;MultipleActiveResultSets=True;Max Pool Size=10000;App=KveApi",
    "Retail_KiotVietTimeSheetS1Database": "Server=dc2d-retail-mssql-sharding-01.citigo.io,6101;Database=KiotVietTimeSheetS1;Persist security info=True;User id=retail_app;password=LnqxffeJulNvQi6u;MultipleActiveResultSets=True;Max Pool Size=10000;App=KveApi",
    "Retail_KiotVietTimeSheetS2Database": "Server=dc2d-retail-mssql-sharding-01.citigo.io,6101;Database=KiotVietTimeSheetS2;Persist security info=True;User id=retail_app;password=LnqxffeJulNvQi6u;MultipleActiveResultSets=True;Max Pool Size=10000;",
    "BookingSpa_KiotVietTimeSheetDatabase": "Server=10.24.113.1;Database=KV_TimeSheet_Booking_Dev;User=kiotvietdev;Password=C1t1g000$6162;Max Pool Size=10000;App=KveApi;Encrypt=false",
    "BookingSpa_KiotVietTimeSheetDatabaseS1": "Server=10.24.113.1;Database=KV_TimeSheet_Booking_Dev;User=kiotvietdev;Password=C1t1g000$6162;Max Pool Size=10000;App=KveApi;Encrypt=false",
    "BookingSpa_KiotVietTimeSheetDatabaseS2": "Server=10.24.113.1;Database=KV_TimeSheet_Booking_Dev2;User=kiotvietdev;Password=C1t1g000$6162;Max Pool Size=10000;App=KveApi-Spa2;Min Pool Size=0",
    "BookingKeivi_KiotVietTimeSheetKeiviDatabase": "Server=dc2d-employee-mssql-01.citigo.io;Database=KV_TimeSheet_Keivi_Dev;User=sa;Password=mssql#C1t1g0@sa;Max Pool Size=10000;App=KveApi-keivi;Min Pool Size=0",
    "BookingHotel_KiotVietTimeSheetDatabase": "Server=10.24.113.1;Database=KV_TimeSheet_Hotel_Dev;User=kiotvietdev;Password=C1t1g000$6162;Max Pool Size=10000;App=KveApi;Encrypt=false"
}


parsed_connections = {}

def parse_conn_string(name, conn_str):
    parts = dict(
        (k.strip().lower(), v.strip())
        for k, v in [item.split('=', 1) for item in conn_str.split(';') if '=' in item]
    )

    server_full = parts.get("server", "")
    server, port = (server_full.split(',') + ['1433'])[:2]

    return {
        "server": server,
        "port": port,
        "database": parts.get("database", ""),
        "username": parts.get("user id", parts.get("user", "")),
        "password": parts.get("password", "")
    }

# Ghi từng connection ra file JSON và TXT
with open("connections.json", "w", encoding="utf-8") as f_json, open("connection.txt", "w", encoding="utf-8") as f_txt:
    for name, conn_str in connection_strings.items():
        parsed = parse_conn_string(name, conn_str)
        parsed_connections[name] = parsed

        # Ghi txt
        f_txt.write(f"# {name}\n")
        f_txt.write(f"server = '{parsed['server']}'\n")
        f_txt.write(f"port = '{parsed['port']}'\n")
        f_txt.write(f"database = '{parsed['database']}'\n")
        f_txt.write(f"username = '{parsed['username']}'\n")
        f_txt.write(f"password = '{parsed['password']}'\n\n")

    json.dump(parsed_connections, f_json, ensure_ascii=False, indent=4)

print("✅ Exported both 'connections.json' and 'connection.txt'")
