List<String> getWeekdayNames(List<int> days) {
  const weekdayMap = {
    1: 'Sat',
    2: 'Sun',
    3: 'Mon',
    4: 'Tue',
    5: 'Wed',
    6: 'Thu',
    7: 'Fri',
  };
  return days.map((d) => weekdayMap[d] ?? 'Invalid').toList();
}
