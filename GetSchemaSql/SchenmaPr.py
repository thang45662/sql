import pyodbc
import os
from datetime import datetime

# --- SQL Server Connection ---
server = '103.252.0.202'
port = '6001'
database = 'KiotVietTimeSheetS1'
username = 'retail_app'
password = 'LnqxffeJulNvQi6u'
conn_str = (
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={server},{port};"
    f"DATABASE={database};"
    f"UID={username};"
    f"PWD={password}"
)

# --- Option: CREATE hoặc ALTER ---
EXPORT_OPTION = "ALTER"  # hoặc "CREATE"
##EXPORT_OPTION = "CREATE"
# --- Output folder ---
output_dir = f"exported_procedures_{database}_retail_dev_sprint58"

os.makedirs(output_dir, exist_ok=True)

# --- Connect and export ---
conn = pyodbc.connect(conn_str)
cursor = conn.cursor()

cursor.execute("""
    SELECT SPECIFIC_NAME
    FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_TYPE = 'PROCEDURE'
""")
procedures = cursor.fetchall()

for proc in procedures:
    proc_name = proc[0]
    file_name = f"{proc_name}.sql"
    file_path = os.path.join(output_dir, file_name)

    with open(file_path, "w", encoding="utf-8") as f:
        now_str = datetime.now().strftime("%Y-%m-%d %H:%M")
        cursor.execute("""
            DECLARE @definition NVARCHAR(MAX);
            SELECT @definition = OBJECT_DEFINITION(OBJECT_ID(?));
            SELECT @definition
        """, proc_name)

        result = cursor.fetchone()
        if result and result[0]:
            definition = result[0]

            # Thay CREATE PROCEDURE bằng ALTER nếu cần
            if EXPORT_OPTION.upper() == "ALTER":
                definition = definition.replace("CREATE PROCEDURE", "ALTER PROCEDURE")
                definition = definition.replace("create procedure", "ALTER PROCEDURE")  # đề phòng viết thường

            # Dọn dòng trống thừa
            cleaned_lines = []
            for line in definition.splitlines():
                stripped = line.rstrip()
                if stripped or (cleaned_lines and cleaned_lines[-1]):
                    cleaned_lines.append(stripped)

            f.write("\n".join(cleaned_lines))
            f.write("\n\nGO\n")
        else:
            f.write("-- Unable to retrieve definition.\n")

print(f"✅ Exported {len(procedures)} procedures to '{output_dir}' as {EXPORT_OPTION.upper()} statements.")
