-- ===== ENUMS =====
CREATE TYPE Bundesland AS ENUM('DE-BB', 'DE-BE', 'DE-BW', 'DE-BY', 'DE-HB', 'DE-HE', 'DE-HH', 'DE-MV', 'DE-NI', 'DE-NW', 'DE-RP', 'DE-SH', 'DE-SL', 'DE-SN', 'DE-ST', 'DE-TH');
CREATE TYPE Dringlichkeit AS ENUM('dringliche Operation', 'elektive Operation', 'frühelektive Operation', 'Notoperation');
CREATE TYPE Geschlecht AS ENUM('d', 'm', 'w');
CREATE TYPE Zahlungsart AS ENUM('Selbstzahler', 'Versichert');
CREATE TYPE Zusatzinformation AS ENUM('A', 'B', 'G', 'L', 'R', 'V');


CREATE SEQUENCE sq_vorfallid START 1;

CREATE TABLE Gesundheitseinrichtung (
    SteuerID VARCHAR NOT NULL,
    Name VARCHAR NOT NULL,
    Bundesland Bundesland NOT NULL,
    Adresse VARCHAR NOT NULL,
    Umsatz DECIMAL(15,2) NOT NULL,
    Zahlungsart Zahlungsart,
    Fachrichtung VARCHAR,
    Bettenanzahl USMALLINT,
    Bettenauslastung FLOAT DEFAULT NULL,
    ist_Uniklinikum BOOLEAN, 
    PRIMARY KEY(SteuerID, Name),
    CHECK(regexp_full_match(SteuerID, 'DE[0-9]{9}')), 
    CHECK(Bettenanzahl <= 1500), 
    CHECK(Bettenauslastung BETWEEN 0 AND 1), 
    CHECK((Zahlungsart IS NOT NULL AND Fachrichtung IS NOT NULL AND Bettenanzahl IS NULL AND ist_Uniklinikum IS NULL) OR (Zahlungsart IS NULL AND Fachrichtung IS NULL AND Bettenanzahl IS NOT NULL AND ist_Uniklinikum IS NOT NULL))
);

CREATE TABLE Patient_in (
    Versichertennummer CHAR PRIMARY KEY,
    Name STRUCT(
        Titel VARCHAR,
        Vorname VARCHAR,
        Nachname VARCHAR
    ) NOT NULL, 
    Geburtsdatum DATE NOT NULL,
    Geschlecht Geschlecht,
    CHECK(regexp_full_match(Versichertennummer, '[A-Z][0-9]{9}')),
    CHECK(struct_extract(Name, 'Vorname') IS NOT NULL AND struct_extract(Name, 'Nachname') IS NOT NULL)
);



CREATE TABLE "OP-Saal" (
    SteuerID CHAR,
    Name VARCHAR,
    Raumnummer UTINYINT,
    FOREIGN KEY(SteuerID, Name) REFERENCES Gesundheitseinrichtung, 
    PRIMARY KEY(SteuerID, Name, Raumnummer), 
    CHECK(Raumnummer < 20)
);

CREATE TABLE OP (
    VorfallID UINTEGER PRIMARY KEY DEFAULT nextval('sq_vorfallid'),
    Versichertennummer VARCHAR,
    SteuerID VARCHAR NOT NULL,
    Name VARCHAR NOT NULL,
    Raumnummer UTINYINT NOT NULL, 
    Dringlichkeit Dringlichkeit NOT NULL,
    ist_Vollnarkose BOOLEAN NOT NULL,
    Datum DATE NOT NULL,
    Startzeit TIME NOT NULL,
    Endzeit TIME NOT NULL,
    FOREIGN KEY(Versichertennummer) REFERENCES Patient_in,
    FOREIGN KEY(SteuerID, Name, Raumnummer) REFERENCES "OP-Saal",
    CHECK(DATEDIFF('minute', Startzeit, Endzeit) BETWEEN 15 and 9*60)
);



CREATE TABLE Ärzt_in (
    LANR CHAR PRIMARY KEY,
    Name STRUCT(
        Titel VARCHAR,
        Vorname VARCHAR,
        Nachname VARCHAR
    ) NOT NULL, 
    Geburtsdatum DATE NOT NULL,
    Fachgebiet VARCHAR NOT NULL,
    Sprachen VARCHAR[] NOT NULL, 
    CHECK(length(LANR) = 9),
    CHECK(Geburtsdatum > '1958-11-17'), 
    CHECK(struct_extract(Name, 'Vorname') IS NOT NULL AND struct_extract(Name, 'Nachname') IS NOT NULL)
);

CREATE TABLE angestellt (
    LANR CHAR,
    SteuerID VARCHAR,
    Name VARCHAR,
    Einstellungsdatum DATE NOT NULL, 
    PRIMARY KEY(LANR, SteuerID, Name),
    FOREIGN KEY(LANR) REFERENCES Ärzt_in(LANR),
    FOREIGN KEY(SteuerID, Name) REFERENCES Gesundheitseinrichtung, 
    CHECK(strftime(Einstellungsdatum, '%d.%m.') not in ('01.01.', '08.03.', '01.05.', '03.10.', '25.12.', '26.12.'))
);

CREATE TABLE Diagnose (
    ICD VARCHAR PRIMARY KEY,
    Zusatzinformation Zusatzinformation NOT NULL,
    Beschreibung VARCHAR,
    CHECK(regexp_full_match(ICD, '[A-Z][0-9]{2}'))
);

CREATE TABLE stellt (
    LANR CHAR,
    ICD VARCHAR,
    Zeitpunkt DATETIME NOT NULL,
    FOREIGN KEY(LANR) REFERENCES Ärzt_in, 
    FOREIGN KEY(ICD) REFERENCES Diagnose, 
    PRIMARY KEY(LANR, ICD)
);

CREATE TABLE Termin (
    ID UUID PRIMARY KEY DEFAULT uuid(), 
    Zeitpunkt DATETIME NOT NULL,
    Zusatzgebühren DECIMAL(5,2) NOT NULL DEFAULT 0,
    LANR VARCHAR NOT NULL,
    ist_Neupatient_in BOOLEAN NOT NULL, 
    FOREIGN KEY(LANR) REFERENCES Ärzt_in,
    CHECK(Zusatzgebühren <= 500 AND Zusatzgebühren >= 0),
    UNIQUE (LANR, Zeitpunkt)
);

CREATE TABLE hat (
    ICD VARCHAR,
    ID UUID,
    Versichertennummer VARCHAR NOT NULL,
    FOREIGN KEY(ICD) REFERENCES Diagnose,
    FOREIGN KEY(ID) REFERENCES Termin,
    FOREIGN KEY(Versichertennummer) REFERENCES Patient_in,
    PRIMARY KEY (ICD, ID)
);

CREATE TABLE liegt_in (
    VorfallID UINTEGER DEFAULT nextval('sq_vorfallid'),
    Versichertennummer VARCHAR NOT NULL,
    SteuerID VARCHAR NOT NULL,
    Name VARCHAR NOT NULL,
    FOREIGN KEY(Versichertennummer) REFERENCES Patient_in, 
    FOREIGN KEY(SteuerID, Name) REFERENCES Gesundheitseinrichtung, 
    PRIMARY KEY(Versichertennummer, SteuerID, Name)
);

CREATE VIEW Bettenauslastung AS (
    SELECT Gesundheitseinrichtung.SteuerID, Gesundheitseinrichtung.Name, COUNT(liegt_in.VorfallID) / Gesundheitseinrichtung.Bettenanzahl as Bettenanzahl
    FROM Gesundheitseinrichtung 
    LEFT JOIN liegt_in 
        ON Gesundheitseinrichtung.SteuerID = liegt_in.SteuerID
        AND Gesundheitseinrichtung.Name = liegt_in.Name
    WHERE Gesundheitseinrichtung.Bettenanzahl IS NOT NULL
      AND Gesundheitseinrichtung.Bettenanzahl > 0
    GROUP BY Gesundheitseinrichtung.SteuerID, Gesundheitseinrichtung.Name, Gesundheitseinrichtung.Bettenanzahl
);