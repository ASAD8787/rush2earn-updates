class DailySteps {
  const DailySteps({
    required this.dayLabel,
    required this.steps,
    required this.isToday,
  });

  final String dayLabel;
  final int steps;
  final bool isToday;
}
