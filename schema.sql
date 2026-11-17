

CREATE TABLE Gesundheitseinrichtung(
    SteuerID VARCHAR,
    Name VARCHAR,
    Bundesland Bundesland NOT NULL,
    Adresse VARCHAR NOT NULL,
    Umsatz DECIMAL(15,2) NOT NULL,
    Zahlungsart Zahlungsart,
    Fachrichtung VARCHAR,
    Bettenanzahl USMALLINT CHECK Bettenanzahl <= 1500,
    Bettenauslastung FLOAT DEFAULT NULL CHECK Bettenauslastung <= 1 AND Bettenauslastung >= 0
    ist_Uniklinikum BOOLEAN, 
    PRIMARY KEY(SteuerID, Name)
    CHECK((Zahlungsart IS NOT NULL AND Fachrichtung IS NOT NULL AND Bettenanzahl IS NULL AND ist_Uniklinikum IS NULL) OR (Zahlungsart IS NULL AND Fachrichtung IS NULL AND Bettenanzahl IS NOT NULL AND ist_Uniklinikum IS NOT NULL))
);

CREATE VIEW Bettenauslastung AS (
    SELECT Gesundheitseinrichtung.SteuerID, Gesundheitseinrichtung.Name, COUNT(liegt_in.VorfallID) / Gesundheitseinrichtung.Bettenanzahl as Bettenauslastung
    FROM Gesundheitseinrichtung 
    LEFT JOIN liegt_in 
        ON Gesundheitseinrichtung.SteuerID = liegt_in.SteuerID
        AND Gesundheitseinrichtung.Name = liegt_in.Name
    GROUP BY Gesundheitseinrichtung.SteuerID, Gesundheitseinrichtung.Name
    WHERE Gesundheitseinrichtung.Bettenanzahl IS NOT NULL
);

-- weak type -> krankenhaus
CREATE TABLE OP-Saal(
    SteuerID CHAR,
    Name VARCHAR,
    Raumnummer VARCHAR,
    FOREIGN KEY(SteuerID, Name) REFERENCES Gesundheitseinrichtung
    PRIMARY KEY(SteuerID, Name, Raumnummer)
)

CREATE TABLE OP(
    VorfallID INTEGER PRIMARY KEY DEFAULT next_val('sq_vorfallid'),
    Versichertennummer VARCHAR,
    Dringlichkeit Dringlichkeit,
    ist_Vollnarkose BOOLEAN,
    Datum DATE,
    Startzeit TIME,
    Endzeit TIME,
    FOREIGN KEY(Versichertennummer) REFERENCES Patient_in,
    CHECK DATEDIFF()
)

CREATE TABLE angestellt(
    LANR CHAR,
    SteuerID VARCHAR,
    Name VARCHAR,
    Einstellungsdatum DATE CHECK strftime(Einstellungsdatum, '%d.%m.') not in('01.01.', '08.03.', '01.05.', '03.10.', '25.12.', '26.12.'), 
    PRIMARY KEY(LANR, SteuerID, Name),
    FOREIGN KEY(LANR) REFERENCES Ärzt_in(LANR),
    FOREIGN KEY(SteuerID, Name) REFERENCES Gesundheitseinrichtung
);

CREATE TABLE Ärzt_in(
    LANR CHAR PRIMARY KEY,
    Name STRUCT(
        Titel VARCHAR,
        Vorname VARCHAR NOT NULL,
        Nachname VARCHAR NOT NULL
    ) NOT NULL, 
    Geburtsdatum DATE CHECK Geburtsdatum < '1958-11-17',
    Fachgebiet VARCHAR,
    Sprachen VARCHAR NOT NULL
    CHECK length(LANR) = 9
);

CREATE TABLE stellt(
    LANR CHAR,
    ICD VARCHAR,
    Zeitpunkte DATETIME,
    FOREIGN KEY(LANR) REFERENCES Ärzt_in
    FOREIGN KEY(ICD) REFERENCES Diagnose
    PRIMARY KEY(LANR, ICD, Zeitpunkt)
)

CREATE TABLE Diagnose(
    ICD VARCHAR PRIMARY KEY,
    Zusatzinformation Zusatzinformation,
    Beschreibung VARCHAR
);



CREATE TABLE Termin(
    ID INTEGER PRIMARY KEY DEFAULT next_val('sq_terminid') , 
    Zeitpunkt DATETIME,
    Zusatzgebühren DECIMAL(5,2) CHECK Zusatzgebühren < 500.0,
    LANR VARCHAR,
    FOREIGN KEY(LANR) REFERENCES Ärzt_in
)

CREATE TABLE hat(
    ICD VARCHAR,
    ID INTEGER,
    Versichertennummer CHAR
    FOREIGN KEY(ICD) REFERENCES Diagnose,
    FOREIGN KEY(ID) REFERENCES Termin,
    FOREIGN KEY(Versichertennummer) REFERENCES Patient_in,
    PRIMARY KEY (ICD, ID, Versichertennummer)
)

 
CREATE TABLE liegt_in(
    VorfallID INTEGER PRIMARY KEY DEFAULT next_val('sq_vorfallid'),
    Versichertennummer CHAR,
    SteuerID VARCHAR,
    Name VARCHAR,
    FOREIGN KEY(Versichertennummer) REFERENCES Patient_in
    FOREIGN KEY(SteuerID, Name) REFERENCES Gesundheitseinrichtung
)




CREATE TABLE Patient_in(
    Versichertennummer CHAR(10) PRIMARY KEY CHECK reexp_matches(Versichertennummer, '[A-Z][0-9]{9}'),
    Name STRUCT(
        Titel VARCHAR,
        Vorname VARCHAR NOT NULL,
        Nachname VARCHAR NOT NULL
    ) NOT NULL,
    Geburtsdatum DATE NOT NULL,
    Geschlecht Geschlecht
)

-- ===== SEQUENCES =====
CREATE SEQUENCE sq_terminid START 1; 
CREATE SEQUENCE sq_vorfallid START 1;

-- ===== ENUMS =====
CREATE TYPE Bundesland AS ENUM('DE-BW', 'DE-BY', 'DE-BE', 'DE-BB', 'DE-HB', 'DE-HH', 'DE-HE', 'DE-MV', 'DE-NI', 'DE-NW', 'DE-RP', 'DE-SL', 'DE-SN', 'DE-ST', 'DE-SH', 'DE-TH');
CREATE TYPE Dringlichkeit AS ENUM('dringliche Operation', 'elektive Operation', 'frühelektive Operation', 'Notoperation');
CREATE TYPE Geschlecht AS ENUM('d', 'm', 'w');
CREATE TYPE Zahlungsart AS ENUM('Privatzahler', 'Versichert')
CREATE TYPE Zusatzinformation AS ENUM('A', 'B', 'G', 'L', 'R', 'V');
