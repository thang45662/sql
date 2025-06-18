import pyodbc

server = '10.24.113.1'
port = '1433'
database = 'KV_TimeSheet_Booking_Dev2'
username = 'kiotvietdev'
password = 'C1t1g000$6162'

conn_str = (
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={server},{port};"
    f"DATABASE={database};"
    f"UID={username};"
    f"PWD={password}"
)

conn = pyodbc.connect(conn_str)
cursor = conn.cursor()

output_file = "schema_only_export.sql"

with open(output_file, "w", encoding="utf-8") as f:
    cursor.execute("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'")
    tables = cursor.fetchall()

    for table in tables:
        table_name = table[0]
        f.write(f"\n-- Table: {table_name}\n")

        cursor.execute(f"""
            SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_NAME = '{table_name}'
            ORDER BY ORDINAL_POSITION
        """)
        columns = cursor.fetchall()

        create_stmt = f"CREATE TABLE [{table_name}] (\n"
        col_defs = []
        for col in columns:
            name, dtype, length, nullable = col
            if dtype in ['varchar', 'nvarchar', 'char', 'nchar'] and length:
                type_str = f"{dtype}({length})"
            elif dtype in ['decimal', 'numeric']:
                # optional: fetch precision/scale if needed
                type_str = f"{dtype}(18, 2)"
            else:
                type_str = dtype

            null_str = "NULL" if nullable == 'YES' else "NOT NULL"
            col_defs.append(f"  [{name}] {type_str} {null_str}")

        create_stmt += ",\n".join(col_defs) + "\n);\n"
        f.write(create_stmt)
