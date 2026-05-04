# Tesseract-Sprachdaten

Damit die Tesseract-OCR-Engine funktioniert, brauchst Du hier die
deutsche Sprachdatei `deu.traineddata`.

## Schritte

1. Lade die Datei runter:
   - **Empfohlen (kleiner, schneller, ~7 MB):**
     https://github.com/tesseract-ocr/tessdata_fast/blob/main/deu.traineddata
   - Vollversion (~30 MB, etwas genauer):
     https://github.com/tesseract-ocr/tessdata/blob/main/deu.traineddata

2. Speichere sie als
   `assets/tessdata/deu.traineddata`
   (genau dieser Name, sonst findet flutter_tesseract_ocr sie nicht).

3. `flutter pub get` und `flutter clean` laufen lassen.

4. App neu bauen: `flutter run`.

## Hinweis

Die `.traineddata` ist absichtlich NICHT im git eingecheckt
(siehe `.gitignore`) - sie ist gross und sprachenspezifisch. Wenn
Du auch englische Bons scannen willst, lege zusaetzlich
`eng.traineddata` ab und stelle in den App-Settings die Sprache
um (TODO).
