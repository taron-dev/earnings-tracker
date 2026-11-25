/// Earning window as Slovaks write a date range, repeating only what differs:
/// `1. – 30. 11. 2026`, `15. 11. – 14. 12. 2026`, `15. 12. 2026 – 14. 1. 2027`.
String formatWindow(DateTime from, DateTime to) {
  final end = '${to.day}. ${to.month}. ${to.year}';
  if (from.year != to.year) return '${from.day}. ${from.month}. ${from.year} – $end';
  if (from.month != to.month) return '${from.day}. ${from.month}. – $end';
  return '${from.day}. – $end';
}

/// Earning window in a chip, where the year would only take space: `1. 11. – 30. 11.`; a window
/// across New Year keeps the years, as in [formatWindow].
String formatWindowShort(DateTime from, DateTime to) {
  if (from.year != to.year) return formatWindow(from, to);
  return '${from.day}. ${from.month}. – ${to.day}. ${to.month}.';
}

/// How many days of the window are left, today included: `ešte 19 dní`, `ešte 2 dni`,
/// `posledný deň`.
String daysLeftLabel(DateTime windowEnd, DateTime today) {
  // Whole calendar days between the dates, counted in UTC so a daylight saving change
  // (a 23 or 25 hour day) does not shift the result.
  final days = DateTime.utc(windowEnd.year, windowEnd.month, windowEnd.day)
          .difference(DateTime.utc(today.year, today.month, today.day))
          .inDays +
      1;
  if (days <= 1) return 'posledný deň';
  if (days <= 4) return 'ešte $days dni';
  return 'ešte $days dní';
}

const _weekdays = ['po', 'ut', 'st', 'št', 'pi', 'so', 'ne'];

/// Slovak weekday abbreviation: `po` to `ne`.
String weekdayAbbreviation(DateTime day) => _weekdays[day.weekday - 1];

/// Monday of the week [day] falls in; Slovak weeks run Monday to Sunday.
DateTime weekStart(DateTime day) => DateTime(day.year, day.month, day.day - (day.weekday - 1));

/// A Monday to Sunday week in a list of work logs: `Tento týždeň` for the week of [today], else
/// `16. – 22. 11.` or `26. 10. – 1. 11.` (no year, these are recent days).
String weekLabel(DateTime monday, DateTime today) {
  if (monday == weekStart(today)) return 'Tento týždeň';
  final sunday = DateTime(monday.year, monday.month, monday.day + 6);
  if (monday.month == sunday.month) return '${monday.day}. – ${sunday.day}. ${sunday.month}.';
  return '${monday.day}. ${monday.month}. – ${sunday.day}. ${sunday.month}.';
}

/// A day in a list of work logs: `št 12. 11.`
String formatDay(DateTime day) => '${_weekdays[day.weekday - 1]} ${day.day}. ${day.month}.';
