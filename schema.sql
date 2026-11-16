CREATE TABLE Ärzt_in(
    LANR CHAR(8) PRIMARY KEY,
    Name STRUCT(
        Titel VARCHAR,
        Vorname VARCHAR NOT NULL,
        Nachname VARCHAR NOT NULL
    ) NOT NULL, 
    Geburtsdatum DATE CHECK Geburtsdatum < '1958-11-17',
    Fachgebiet VARCHAR,
    Sprachen VARCHAR NOT NULL
);

CREATE TABLE angestellt(
    LANR CHAR(8),
    SteuerID VARCHAR,
    Name VARCHAR,
    Einstellungsdatum DATE CHECK strftime(Einstellungsdatum, '%d.%m.') not in('01.01.', '08.03.', '01.05.', '03.10.', '25.12.', '26.12.'), 
    PRIMARY KEY(LANR, SteuerID, Name),
    FOREIGN KEY(LANR) REFERENCES Ärzt_in(LANR),
    FOREIGN KEY(SteuerID, Name) REFERENCES Gesundheitseinrichtung
);

CREATE TABLE Gesundheitseinrichtung(
    SteuerID CHAR,
    Name VARCHAR,
    Bundesland Bundesland NOT NULL,
    Adresse VARCHAR NOT NULL,
    Umsatz DECIMAL(15,2) NOT NULL,
    Zahlungsart Zahlungsart,
    Fachrichtung VARCHAR,
    Bettenanzahl USMALLINT CHECK Bettenanzahl <= 1500,
    Bettenausltung FLOAT CHECK Bettenauslastung <= 1 AND Bettenauslastung >= 0
    ist_Uniklinikum BOOLEAN, 
    PRIMARY KEY(SteuerID, Name)
    CHECK((Zahlungsart IS NOT NULL AND Fachrichtung IS NOT NULL AND Bettenanzahl IS NULL AND ist_Uniklinikum IS NULL) OR (Zahlungsart IS NULL AND Fachrichtung IS NULL AND Bettenanzahl IS NOT NULL AND ist_Uniklinikum IS NOT NULL))
);

CREATE TABLE Diagnose(
    ICD PRIMARY KEY,
    Zusatzinformation Zusatzinformation,
    Beschreibung VARCHAR
);

CREATE TABLE Termin(
    ID INTEGER PRIMARY KEY DEFAULT next_val('pk_termin') , 
    Zeitpunkt DATETIME,
    Zusatzgebühren DECIMAL(5,2) CHECK Zusatzgebühren < 500.0
)

CREATE SEQUENCE pk_termin START 1; 

CREATE TABLE Patient_in(
    Versichertennummer VARCHAR PRIMARY KEY CHECK reexp_matches(Versichertennummer, '[A-Z][0-9]{9}'),
    Name STRUCT(
        Titel VARCHAR,
        Vorname VARCHAR NOT NULL,
        Nachname VARCHAR NOT NULL
    ) NOT NULL,
    Geburtsdatum DATE NOT NULL,
    Geschlecht Geschlecht
)

-- ===== ENUMS =====
CREATE TYPE Bundesland AS ENUM('DE-BW', 'DE-BY', 'DE-BE', 'DE-BB', 'DE-HB', 'DE-HH', 'DE-HE', 'DE-MV', 'DE-NI', 'DE-NW', 'DE-RP', 'DE-SL', 'DE-SN', 'DE-ST', 'DE-SH', 'DE-TH');
CREATE TYPE Dringlichkeit AS ENUM('dringliche Operation', 'elektive Operation', 'frühelektive Operation', 'Notoperation');
CREATE TYPE Geschlecht AS ENUM('d', 'm', 'w');
CREATE TYPE Zahlungsart AS ENUM('Privatzahler', 'Versichert')
CREATE TYPE Zusatzinformation AS ENUM('A', 'B', 'G', 'L', 'R', 'V');
