import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ocr_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/services/category_classifier.dart';
import '../../../data/services/photo_capture_service.dart';
import '../../../data/services/receipt_parser.dart';
import '../../providers/categories_state.dart';
import '../../providers/settings_state.dart';
import 'expense_form_screen.dart';

/// Bildschirm fuer „Bon scannen" → OCR → vorbefuelltes Formular.
///
/// Ablauf:
/// 1. Nutzer waehlt Quelle (Kamera oder Galerie)
/// 2. PhotoCaptureService kopiert Bild in eigenes Temp-Verzeichnis
/// 3. ML Kit erzeugt Zeilen
/// 4. ReceiptParser erkennt Felder
/// 5. Foto wird _vor_ Anzeige des Formulars geloescht (Privacy)
/// 6. ExpenseFormScreen wird mit `prefill` geoeffnet
class ReceiptScanScreen extends ConsumerStatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  ConsumerState<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends ConsumerState<ReceiptScanScreen> {
  bool _busy = false;
  String? _statusText;

  Future<void> _scanFrom(PhotoSource source) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _statusText = source == PhotoSource.camera
          ? l10n.receiptScanOpeningCamera
          : l10n.receiptScanOpeningGallery;
    });

    final capture = ref.read(photoCaptureServiceProvider);
    final ocr = ref.read(receiptOcrServiceProvider);

    // Auto-Logout unterdruecken, solange Kamera/Galerie offen sind
    // (laeuft in separater Activity, App geht in 'paused' - sonst wuerde
    // der Nutzer beim Zurueckkommen ausgeloggt).
    final suppression = ref.read(autoLogoutSuppressionProvider.notifier);
    suppression.acquire();

    File? image;
    try {
      image = await capture.capture(source);
      if (image == null) {
        if (mounted) {
          setState(() {
            _busy = false;
            _statusText = null;
          });
        }
        return;
      }

      setState(() => _statusText = l10n.receiptScanReading);

      final ocrResult = await ocr.recognize(image);
      final parsed = ReceiptParser.parse(ocrResult.lines);
      if (kDebugMode) debugPrint('OCR LINES: ${ocrResult.lines}');

      // Foto loeschen, BEVOR wir weiter navigieren – das Bild war nur
      // fuer die OCR noetig.
      await capture.deleteSafe(image);
      image = null;

      if (!mounted) return;

      // Vorgeschlagene Kategorie aus Item-Namen ableiten (Heuristik).
      // Faellt auf die erste sichtbare Kategorie zurueck, wenn der
      // Classifier keinen Treffer hat oder der Slug nicht zu einer
      // sichtbaren Kategorie matcht.
      String? categoryId;
      try {
        final cats = await ref.read(visibleCategoriesProvider.future);
        if (cats.isNotEmpty) {
          final slug = const CategoryClassifier().suggestSlug(parsed.items);
          if (slug != null) {
            for (final c in cats) {
              if (c.name.toLowerCase() == slug) {
                categoryId = c.id;
                break;
              }
            }
          }
          categoryId ??= cats.first.id;
        }
      } catch (_) {}

      final prefill = ExpensePrefill(
        merchant: parsed.merchant,
        occurredAt: parsed.occurredAt,
        totalCents: parsed.totalCents,
        items: parsed.items,
        categoryId: categoryId,
      );

      if (parsed.confidence < 0.3 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.receiptScanLowConfidence(
                (parsed.confidence * 100).round(),
                CurrencyFormatter.formatCents(parsed.totalCents),
              ),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => ExpenseFormScreen(prefill: prefill),
      ));
    } catch (e) {
      if (kDebugMode) debugPrint('OCR error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.receiptScanFailed),
          ),
        );
      }
    } finally {
      suppression.release();
      // Sicherheits-Reinigung: falls Bild noch existiert.
      if (image != null) {
        await capture.deleteSafe(image);
      }
      if (mounted) {
        setState(() {
          _busy = false;
          _statusText = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.receiptScanTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.privacy_tip_rounded,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          l10n.receiptScanPrivacyTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.receiptScanPrivacyBody,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : () => _scanFrom(PhotoSource.camera),
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(l10n.receiptScanCamera),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _scanFrom(PhotoSource.gallery),
              icon: const Icon(Icons.photo_library_rounded),
              label: Text(l10n.receiptScanGallery),
            ),
            const SizedBox(height: 32),
            if (_busy)
              Column(
                children: <Widget>[
                  const CircularProgressIndicator(),
                  if (_statusText != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(_statusText!),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
