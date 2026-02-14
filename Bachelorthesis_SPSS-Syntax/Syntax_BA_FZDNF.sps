* Encoding: UTF-8.
*------------------------------------------------------------------.
*Grundsätzliche Informationen
*------------------------------------------------------------------.
* Bachelorarbeit-Syntax
*Vorgelegt von: Fabian Zaudig
*Matrikelnummer: 451211039
*Prüfer/in: Frau Prof. Dr. Alina Hernandez-Bark
*Fachrichtung: Wirtschaft, Psychologie & Recht
*Studiengang: Psychologie
* Thema: Der Zusammenhang von subjektiv erfasster Achtsamkeit und subjektiv erfasstem akademischen Erfolg
*Ziel: Datenbereinigung und Testung der Regressionsvoraussetzungen, *anschließend Durchführung der Regression mit PROCESS V4.3 Model 4

*Vorab werden alle irrelevanten Variablen gelöscht.
DELETE VARIABLES SERIAL REF QUESTNNR MODE STARTED TIME001 TIME002 TIME003 TIME004 TIME005 MAILSENT LASTDATA STATUS FINISHED LASTPAGE MAXPAGE Q_VIEWER A301_06

*------------------------------------------------------------------.
* BLOCK 1 – Stringvariablen umwandeln und Missings zählen
*------------------------------------------------------------------.
* 1) Variable A001 (Geschlecht) – prüfen & numerisch ablegen.
FORMATS A001 (F8.0).
COMPUTE Geschlecht_num = A001.
EXECUTE.

*Für die Variable Alter (A002_01) das gleiche machen. ANMERKUNG: Die *Warnungsnummer 635 kann ignoriert werden, der Code funktioniert.
COMPUTE Alter_num = NUMBER(A002_01, F8.0).
EXECUTE.


*------------------------------------------------------------------.
* 2) Variable A005_01 (Note) – robust numerisch umwandeln.
* Kommas & Punkte angleichen.
STRING Note_Komma (A20).
COMPUTE Note_Komma = REPLACE(A005_01, ".", ",").
EXECUTE.

*------------------------------------------------------------------.
* Fälle mit mehr als einer Nachkommastelle entfernen.
SELECT IF (CHAR.INDEX(Note_Komma, ",") = 0 OR CHAR.LENGTH(CHAR.SUBSTR(Note_Komma, CHAR.INDEX(Note_Komma, ",") + 1)) <= 1).
EXECUTE.

*------------------------------------------------------------------.
*Werte ohne Komma zusätzlich entfernen (z.B. "3" statt "3,0").
SELECT IF (CHAR.INDEX(Note_Komma, ",") > 0).
EXECUTE.

NUMERIC Note_num (F8.2).
DO IF (RTRIM(LTRIM(Note_Komma)) = "" OR RTRIM(LTRIM(Note_Komma)) = ",").
    COMPUTE Note_num = $SYSMIS.
ELSE.
    COMPUTE Note_num = NUMBER(Note_Komma, COMMA8.2).
END IF.
EXECUTE.

DELETE VARIABLES Note_Komma.
EXECUTE.

DESCRIPTIVES VARIABLES = Note_num
  /STATISTICS = MEAN STDDEV MIN MAX

*------------------------------------------------------------------.
* 3) –9 als fehlend definieren.
RECODE
  Geschlecht_num Note_num
  A003 A004
  A101_01 TO A101_16
  A201_01 TO A201_11
  A301_01 TO A301_05
  (-9 = SYSMIS).
EXECUTE.

*------------------------------------------------------------------.
* 4) Fehlende Werte pro Fall zählen.
COMPUTE Missings_gesamt = NMISS(
  Geschlecht_num, Note_num,
  A003, A004,
  A101_01 TO A101_16,
  A201_01 TO A201_11,
  A301_01 TO A301_05
).
COMPUTE Missings_Prozent = (Missings_gesamt / 39) * 100.
EXECUTE.

*------------------------------------------------------------------.
* 5) Fälle mit >20 % Missing entfernen.
FILTER OFF.
USE ALL.
SELECT IF (Missings_Prozent <= 20).
EXECUTE.

DESCRIPTIVES VARIABLES = Missings_gesamt Missings_Prozent
  /STATISTICS = MEAN STDDEV MIN MAX.

*------------------------------------------------------------------.
* BLOCK 2 – Ausreißer bei Reaktionszeit (außerhalb 95%-Intervall)
*------------------------------------------------------------------.

* 1)Perzentile bestimmen (empirisch, 2.5% und 97.5%).
FREQUENCIES VARIABLES = TIME_RSI
  /FORMAT = NOTABLE
  /PERCENTILES = 2.5 97.5.

*------------------------------------------------------------------.
* 2) Auf Basis dessen Variablen bilden

COMPUTE LOWER_PERC = 0.374500.
COMPUTE UPPER_PERC = 1.946000.
EXECUTE.

*------------------------------------------------------------------.
* 3) Nur Fälle im 95%-KI behalten.
SELECT IF (TIME_RSI >= LOWER_PERC AND TIME_RSI <= UPPER_PERC).
EXECUTE.

*------------------------------------------------------------------.
* 4) Kontrolle der verbleibenden Werte.
DESCRIPTIVES VARIABLES = TIME_RSI
  /STATISTICS = MEAN STDDEV MIN MAX.

*------------------------------------------------------------------.
* 5) Hilfsvariablen wieder löschen.
DELETE VARIABLES LOWER_PERC UPPER_PERC.
EXECUTE.

*------------------------------------------------------------------.
* Nur Fälle behalten, die A101_11 = 5 UND A201_09 = 2 haben.
SELECT IF (A101_11 = 5 AND A201_09 = 2).
EXECUTE.

*------------------------------------------------------------------.
* Diese Selektionsvariablen entfernen (nicht für Skalen oder Analysen relevant).
DELETE VARIABLES A101_11 A201_09.
EXECUTE.

*------------------------------------------------------------------.
* BLOCK 3 – Skalenbildung (Mittelwerte)für Regression.
*------------------------------------------------------------------.
*SKALEN UMPOLEN UND NEU BILDEN
*------------------------------------------------------------------.
* 1) MAAS (Achtsamkeit) – alle Items umpolen (1–6 Skala)
* MAAS misst Unachtsamkeit → hohe Werte = unachtsam.
* Umkehrung: 7 - Item, damit hohe Werte = achtsam.
DO REPEAT item = A101_01 TO A101_16.
    COMPUTE item = 7 - item.
END REPEAT.
EXECUTE.

*------------------------------------------------------------------.
* Skalenmittelwert neu berechnen.
COMPUTE Achtsam = MEAN(A101_01 TO A101_16).
EXECUTE.

*------------------------------------------------------------------.
* 2) PSS (Perceived Stress Scale) – teilweise umpolen (1–5 Skala)
* Positiv formulierte Items: 4, 5, 7, 8 → umpolen.
DO REPEAT item = A201_04 A201_05 A201_07 A201_08.
    COMPUTE item = 6 - item.
END REPEAT.
EXECUTE.

*------------------------------------------------------------------.
* Skalenmittelwert bilden.
COMPUTE Stress = MEAN(A201_01 TO A201_11).
EXECUTE.

*------------------------------------------------------------------.
* 3) SAAS (Subjektiver Erfolg) – keine Umpolung nötig

COMPUTE Erfolg = MEAN(A301_01 TO A301_05).
EXECUTE.

*------------------------------------------------------------------.
* BLOCK 4 - Reliabilitätsanalyse d. Skalen
*------------------------------------------------------------------.
*MAAS:

RELIABILITY
  /VARIABLES=A101_01 A101_02 A101_03 A101_04 A101_05 A101_06 A101_07 A101_08 A101_09 A101_10
    A101_12 A101_13 A101_14 A101_15 A101_16
  /SCALE('ALL VARIABLES') ALL
  /MODEL=ALPHA
  /SUMMARY=TOTAL.


*------------------------------------------------------------------.
*PSS:

RELIABILITY
  /VARIABLES=A201_01 A201_02 A201_03 A201_04 A201_05 A201_06 A201_07 A201_08 A201_10 A201_11
  /SCALE('ALL VARIABLES') ALL
  /MODEL=ALPHA
  /SUMMARY=TOTAL.


*------------------------------------------------------------------.
*SAAS:

RELIABILITY
  /VARIABLES=A301_01 A301_02 A301_03 A301_04 A301_05
  /SCALE('ALL VARIABLES') ALL
  /MODEL=ALPHA
  /SUMMARY=TOTAL.



*------------------------------------------------------------------.
* BLOCK 5 – Voraussetzungen prüfen
*------------------------------------------------------------------.
*Deskriptive Statistiken und Normalverteilungsprüfung.
EXAMINE VARIABLES = Achtsam Stress Erfolg Note_num
  /PLOT = BOXPLOT HISTOGRAM NPPLOT
  /STATISTICS = DESCRIPTIVES
  /CINTERVAL = 95
  /MISSING = LISTWISE
  /NOTOTAL.

*------------------------------------------------------------------.
*Pearson-Korrelation für Multikollinearitätstest der UVs

CORRELATIONS
  /VARIABLES=Achtsam Stress
  /PRINT=TWOTAIL NOSIG FULL
  /MISSING=PAIRWISE.

*------------------------------------------------------------------.
*Streudiagramm für Normalverteilung der Residuen für subj. Erfolg, *Kollinearitätsmatrix

REGRESSION
  /MISSING LISTWISE
  /STATISTICS COEFF OUTS R ANOVA COLLIN TOL 
  /CRITERIA=PIN(.05) POUT(.10) TOLERANCE(.0001)
  /NOORIGIN
  /DEPENDENT Erfolg
  /METHOD=ENTER Achtsam Stress
  /SCATTERPLOT=(*ZRESID ,*ZPRED)
  /RESIDUALS HIST(ZRESID) NORM(ZRESID)DURBIN
  /SAVE RESID(ZRESID_Erfolg).

*KS-Test für Normalverteilung d. Residuen für Erfolg

NPAR TESTS
  /K-S(NORMAL)=ZRESID_Erfolg
  /MISSING ANALYSIS.

*------------------------------------------------------------------.
*Streudiagramm für Normalverteilung der Residuen für *Notendurchschnitt, Kollinearitätsmatrix

REGRESSION
  /MISSING LISTWISE
  /STATISTICS COEFF OUTS R ANOVA COLLIN TOL 
  /CRITERIA=PIN(.05) POUT(.10) TOLERANCE(.0001)
  /NOORIGIN
  /DEPENDENT Note_num
  /METHOD=ENTER Achtsam Stress
  /SCATTERPLOT=(*ZRESID ,*ZPRED)
  /RESIDUALS HIST(ZRESID) NORM(ZRESID)DURBIN
  /SAVE RESID(ZRESID_Note).

*KS-Test für Normalverteilung d. Residuen für Note_num

NPAR TESTS
  /K-S(NORMAL)=ZRESID_Note
  /MISSING ANALYSIS.
*------------------------------------------------------------------.
*Test auf Heteroskedastizität für subj. Erfolg

UNIANOVA Erfolg WITH Stress Achtsam
  /METHOD=SSTYPE(3)
  /INTERCEPT=INCLUDE
  /PRINT MBP WHITE BP DESCRIPTIVE HOMOGENEITY
  /PLOT=RESIDUALS
  /CRITERIA=ALPHA(.05)
  /DESIGN=Stress Achtsam.

*------------------------------------------------------------------.
*Test auf Heteroskedastizität für Notendurchschnitt

UNIANOVA Note_num WITH Stress Achtsam
  /METHOD=SSTYPE(3)
  /INTERCEPT=INCLUDE
  /PRINT MBP WHITE BP DESCRIPTIVE HOMOGENEITY
  /PLOT=RESIDUALS
  /CRITERIA=ALPHA(.05)
  /DESIGN=Stress Achtsam.

*------------------------------------------------------------------.
* Zusammenfassung: 
* Normalverteilung gegeben
* Multikollinearität unproblematisch
* Keine Autokorrelation der Residuen
* Homoskedastizität nach White-Test gegeben (p > .05)
*------------------------------------------------------------------.
*BLOCK 6 – Durchführung der PROCESS Model 4 Berechnung (GUI).
*------------------------------------------------------------------.
*PROCESS-Regression und Mediationsanalyse
* Modell 1: Subjektiver Erfolg als AV 
PROCESS vars = Achtsam Stress Erfolg 
  /model = 4
  /x = Achtsam
  /m = Stress
  /y = Erfolg
  /boot = 5000
  /center = 1
  /total = 1
  /stand = 1
  /normal = 1
  /effectsize = 1.

*------------------------------------------------------------------.
* Modell 2: Objektiver Erfolg (Note_num) als AV
PROCESS vars = Achtsam Stress Note_num 
  /model = 4
  /x = Achtsam
  /m = Stress
  /y = Note_num
  /boot = 5000
  /center = 1
  /total = 1
  /stand = 1
  /normal = 1
  /effectsize = 1.
*------------------------------------------------------------------.
* BLOCK 7 – Interkorrelationsmatrix nach Pearson für alle Var.
*------------------------------------------------------------------.

CORRELATIONS
  /VARIABLES=Achtsam Stress Erfolg Note_num A003 A004 A001 Alter_num
  /PRINT=TWOTAIL NOSIG FULL
  /MISSING=PAIRWISE.


*------------------------------------------------------------------.
* BLOCK 8 – Deskriptive Statistiken für demographische Variablen
*------------------------------------------------------------------.
*Tabellarische Auflistung der wichtigsten statistischen Kennwerte *zur Stichprobenbeschreibung

FREQUENCIES VARIABLES=A001 Alter_num A003 A004
  /STATISTICS=STDDEV VARIANCE RANGE MINIMUM MAXIMUM SEMEAN MEAN MEDIAN MODE SUM
  /ORDER=ANALYSIS.


*Balkendiagramm der demographischen Variablen und Note

FREQUENCIES VARIABLES= A001 Alter_num A003 A004 Note_num
  /BARCHART FREQ
  /ORDER=ANALYSIS.


*Zuletzt soll noch die durchschnittliche Bearbeitungszeit *erhoben werden:

FREQUENCIES VARIABLES=TIME_SUM
  /STATISTICS=RANGE MINIMUM MAXIMUM STDDEV MEAN MEDIAN
  /FORMAT=NOTABLE
  /ORDER=ANALYSIS.



*------------------------------------------------------------------.
*Ende der Syntax.
*------------------------------------------------------------------.

