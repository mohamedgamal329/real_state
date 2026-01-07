import 'package:intl/intl.dart';

const AED = '\u00EA ';
final NumberFormat amountFormat = NumberFormat.currency(
  symbol: AED,
  decimalDigits: 0,
);
