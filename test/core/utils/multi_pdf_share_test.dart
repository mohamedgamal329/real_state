import 'package:flutter_test/flutter_test.dart';
import 'package:real_state/core/utils/multi_pdf_share.dart';

void main() {
  group('buildSharePdfFileName', () {
    test('returns base filename when no conflicts', () {
      final usedNames = <String>{};
      final result = buildSharePdfFileName(
        title: 'Palm Hills',
        fallbackTitle: 'Property',
        usedNames: usedNames,
        propertyId: 'prop-123',
      );
      expect(result, 'Palm Hills.pdf');
      expect(usedNames, contains('Palm Hills.pdf'));
    });

    test('uses fallback title when title is empty', () {
      final usedNames = <String>{};
      final fileName = buildSharePdfFileName(
        title: '   ',
        fallbackTitle: 'property',
        usedNames: usedNames,
        propertyId: '1',
      );
      expect(fileName, 'property.pdf');
    });

    test('adds numeric suffix (2) for first duplicate', () {
      final usedNames = <String>{'Palm Hills.pdf'};
      final result = buildSharePdfFileName(
        title: 'Palm Hills',
        fallbackTitle: 'Property',
        usedNames: usedNames,
        propertyId: 'prop-456',
      );
      expect(result, 'Palm Hills (2).pdf');
      expect(result, isNot(contains('prop-456'))); // NO ID in filename
    });

    test('increments numeric suffix for multiple duplicates', () {
      final usedNames = <String>{'Palm Hills.pdf', 'Palm Hills (2).pdf'};
      final result = buildSharePdfFileName(
        title: 'Palm Hills',
        fallbackTitle: 'Property',
        usedNames: usedNames,
        propertyId: 'prop-789',
      );
      expect(result, 'Palm Hills (3).pdf');
      expect(result, isNot(contains('prop-789'))); // NO ID in filename
    });

    test('never exposes property ID in filename', () {
      final usedNames = <String>{};

      // Even with unique IDs, the filename should never contain them
      final result1 = buildSharePdfFileName(
        title: 'Test',
        fallbackTitle: 'Property',
        usedNames: usedNames,
        propertyId: 'abc-123-xyz',
      );
      expect(result1, isNot(contains('abc-123-xyz')));

      final result2 = buildSharePdfFileName(
        title: 'Test',
        fallbackTitle: 'Property',
        usedNames: usedNames,
        propertyId: 'different-id',
      );
      expect(result2, isNot(contains('different-id')));
    });

    test('maintains stable deterministic ordering', () {
      final usedNames = <String>{};

      final r1 = buildSharePdfFileName(
        title: 'Sunset Villa',
        fallbackTitle: 'Property',
        usedNames: usedNames,
        propertyId: 'p1',
      );
      final r2 = buildSharePdfFileName(
        title: 'Sunset Villa',
        fallbackTitle: 'Property',
        usedNames: usedNames,
        propertyId: 'p2',
      );
      final r3 = buildSharePdfFileName(
        title: 'Sunset Villa',
        fallbackTitle: 'Property',
        usedNames: usedNames,
        propertyId: 'p3',
      );

      expect(r1, 'Sunset Villa.pdf');
      expect(r2, 'Sunset Villa (2).pdf');
      expect(r3, 'Sunset Villa (3).pdf');
    });
  });
}
