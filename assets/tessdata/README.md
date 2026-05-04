# Tesseract-Sprachdaten

Damit die Tesseract-OCR-Engine funktioniert, brauchst Du hier die
deutsche Sprachdatei `deu.traineddata`.

## Schritte

1. Lade die Datei runter:
   - **Empfohlen (kleiner, schneller, ~7 MB):**
     https://github.com/tesseract-ocr/tessdata_fast/raw/main/deu.traineddata
   - Beste Qualitaet (~15 MB):
     https://github.com/tesseract-ocr/tessdata_best/raw/main/deu.traineddata
   - Standard (~30 MB):
     https://github.com/tesseract-ocr/tessdata/raw/main/deu.traineddata

   Wichtig: NICHT die GitHub-Web-Vorschau speichern, sondern den
   Direct-Download via "Raw"-Link. Wenn die Datei < 5 MB ist, hast
   Du wahrscheinlich nur die HTML-Vorschau gespeichert.

2. Speichere sie als
   `assets/tessdata/deu.traineddata`
   (genau dieser Name, sonst findet flutter_tesseract_ocr sie nicht).

3. **Manifest pruefen:** Die Datei `assets/tessdata_config.json`
   listet alle Sprachdateien auf, die Flutter ins App-Bundle packt.
   Wenn Du eine andere Sprache hinzufuegst, dort eintragen.

4. `flutter clean` + `flutter pub get` laufen lassen, damit das
   neue Asset im Build landet.

5. App neu bauen: `flutter run`.

## Hinweis

Die `.traineddata` ist absichtlich NICHT im git eingecheckt
(siehe `.gitignore`) - sie ist gross und sprachenspezifisch.
