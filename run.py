import duckdb

con = duckdb.connect(":memory:")         # bei jedem Lauf frische, leere DB
con.execute(open("schema.sql", encoding="utf-8").read())
con.sql("SHOW ALL TABLES").show()
con.sql("DESCRIBE Patient_in").show()    # Spalten und Typen prüfen

# eigene Test-INSERTs, die scheitern sollen:
try:
    con.execute("INSERT INTO ... VALUES (...)")
    print("FEHLER: Insert hätte scheitern müssen")
except duckdb.Error as e:
    print("ok, abgelehnt:", e)
