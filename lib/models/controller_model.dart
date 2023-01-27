class ControllrtModel {
  final int id;
  final int sendingType;
  final int status;

  ControllrtModel(
      {required this.id, required this.sendingType, required this.status});
  factory ControllrtModel.fromJson(Map<String, dynamic> json) {
    return ControllrtModel(
      id: json['id'],
      sendingType: json['sendingType'],
      status: json['status'],
    );
  }
}
