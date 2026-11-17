import duckdb

con = duckdb.connect(":memory:")         # bei jedem Lauf frische, leere DB

schema_file_text = open("schema.sql", encoding="utf-8").read()

schema_queries = schema_file_text.split(";")

for s in schema_queries:
    name = s.split(" ")
    print(f"===== {name[2]} =====")
    print()

    con.execute(s)

#con.sql("SHOW ALL TABLES").show()
#con.sql("DESCRIBE Patient_in").show()    # Spalten und Typen prüfen

# eigene Test-INSERTs, die scheitern sollen:
try:
    con.execute("INSERT INTO Gesundheitseinrichtung (SteuerID, Name, Adresse, Umsatz, Bundesland, Fachrichtung, Zahlungsart) " \
                "VALUES ('DE149065327', 'Edi+Det', 'Mainzelstraße, 55100 Mainz', 420000, 'DE-BB', 'Knuffologie', 'Selbstzahler');")

    con.sql("SELECT * FROM Gesundheitseinrichtung").show()

    con.execute("INSERT INTO Patient_in (Versichertennummer, Nachname, Vorname, Geburtsdatum) " \
                "VALUES ('absD123456789', 'Schenke', 'Lukas', '2020-01-01');")

    con.sql("SELECT * FROM Patient_in").show()


except duckdb.Error as e:
    print("ok, abgelehnt:", e)
