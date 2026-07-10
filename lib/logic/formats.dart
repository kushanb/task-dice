/// "18:24" — total minutes (no hour rollover) : seconds, like the design timers.
String fmtClock(Duration d) {
  final s = d.inSeconds < 0 ? 0 : d.inSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// "1h 36m" for 96, "24m" for 24.
String fmtHoursMin(int minutes) =>
    minutes >= 60 ? '${minutes ~/ 60}h ${minutes % 60}m' : '${minutes}m';

/// "2,140" — thousands separators.
String fmtThousands(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// "captured 14:38 · mid-focus", "captured yesterday", "captured Wed".
String capturedLabel(DateTime at, {bool midFocus = false}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  final diff = today.difference(day).inDays;
  final hhmm =
      '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
  final base = switch (diff) {
    0 => 'captured $hhmm',
    1 => 'captured yesterday',
    _ => 'captured ${weekdayShort(at)}',
  };
  return midFocus ? '$base · mid-focus' : base;
}

/// "Wed" — short weekday, used in the Plan subtitle.
String weekdayShort(DateTime now) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days[now.weekday - 1];
}

/// "Tuesday afternoon" — header line on Today.
String dayPartLabel(DateTime now) {
  const weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  final part = now.hour < 12 ? 'morning' : (now.hour < 17 ? 'afternoon' : 'evening');
  return '${weekdays[now.weekday - 1]} $part';
}
