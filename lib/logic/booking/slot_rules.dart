const slotLeadHours = 2;
const slotMaxDaysAhead = 30;

bool isSlotEnabled(DateTime candidate, DateTime now) {
  return !candidate.isBefore(now.add(const Duration(hours: slotLeadHours))) &&
      !candidate.isAfter(now.add(const Duration(days: slotMaxDaysAhead)));
}
