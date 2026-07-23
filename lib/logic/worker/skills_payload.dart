List<Map<String, dynamic>> buildSkillsPayload(Map<String, int> selectedSkills) {
  return selectedSkills.entries.map((e) => {'serviceId': e.key, 'experienceMonths': e.value}).toList();
}
