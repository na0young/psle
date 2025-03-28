class User {
  int? id; // 사용자 식별 아이디
  String? loginId; // 사용자 로그인 아이디
  String? password; // 사용자 로그인 비밀번호
  String? name; // 사용자 이름
  List<String>? alarmTimes; // 알람시간 목록

  User({this.id, this.loginId, this.password, this.name, this.alarmTimes});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      loginId: json['loginId'],
      password: json['password'],
      name: json['name'],
      alarmTimes: json['esmAlarms'] != null
          ? List<String>.from(json['esmAlarms'])
          : ['9:00:00', '12:00:00', '15:00:00', '18:08:00'], // API 통신 실패시 디폴트값
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "loginId": loginId,
        "password": password,
        "name": name,
        "alarmTimes": alarmTimes,
      };
}
