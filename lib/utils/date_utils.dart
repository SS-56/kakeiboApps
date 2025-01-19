DateTime calculateEndDate(DateTime startDate) {
  int year = startDate.year;
  int month = startDate.month;

  // 現在の月の日数を取得
  int daysInCurrentMonth = DateTime(year, month + 1, 0).day;

  // 翌月の日数を取得
  int daysInNextMonth = DateTime(year, month + 2, 0).day;

  // 翌月に移動
  month += 1;
  if (month > 12) {
    year += 1;
    month = 1;
  }

  // 終了日は翌月の開始日 - 1
  int endDay = startDate.day - 1;
  if (endDay > daysInNextMonth) {
    endDay = daysInNextMonth; // 翌月の月末を終了日に設定
  } else if (endDay <= 0) {
    endDay = daysInCurrentMonth; // 現在の月末を終了日に設定
    month -= 1;
    if (month <= 0) {
      month = 12;
      year -= 1;
    }
  }

  return DateTime(year, month, endDay);
}
