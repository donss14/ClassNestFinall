import 'package:classnav/core/utils/time_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimeUtils', () {
    test('formats midnight, noon and afternoon', () {
      expect(TimeUtils.formatMinutes(0), '12:00 AM');
      expect(TimeUtils.formatMinutes(8 * 60 + 5), '8:05 AM');
      expect(TimeUtils.formatMinutes(12 * 60), '12:00 PM');
      expect(TimeUtils.formatMinutes(13 * 60 + 30), '1:30 PM');
    });

    test('formats ranges and day names', () {
      expect(TimeUtils.formatRange(480, 570), '8:00 AM - 9:30 AM');
      expect(TimeUtils.dayName(1), 'Monday');
      expect(TimeUtils.dayName(7), 'Sunday');
    });
  });
}
