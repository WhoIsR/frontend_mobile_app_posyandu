class AdminSchedule {
  const AdminSchedule({
    required this.id,
    required this.posyanduId,
    required this.date,
    this.startTime,
    this.endTime,
    this.location,
    this.note,
  });

  final int id;
  final int posyanduId;
  final String date;
  final String? startTime;
  final String? endTime;
  final String? location;
  final String? note;
}

class AdminSession {
  const AdminSession({
    required this.id,
    required this.posyanduId,
    required this.date,
    required this.status,
    this.scheduleId,
  });

  final int id;
  final int posyanduId;
  final String date;
  final String status;
  final int? scheduleId;
}
