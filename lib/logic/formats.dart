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
