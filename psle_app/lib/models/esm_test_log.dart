class EsmTestLog {
  String? date; // YYYY-mm-dd
  String? time; // HH:mm:ss

  EsmTestLog({this.date, this.time});

  factory EsmTestLog.fromJson(Map<String, dynamic> json) {
    return EsmTestLog(
      date: json['date'],
      time: json['time'],
    );
  }

  Map<String, dynamic> toJson() => {
        "date": date,
        "time": time,
      };
}
