class RawDataModel {
  final int id;
  final String serviceName;
  final String serviceValue;
  final String name;
  final String value;

  RawDataModel(
      {required this.id,
      required this.serviceName,
      required this.serviceValue,
      required this.name,
      required this.value});

  factory RawDataModel.fromJson(Map<String, dynamic> json) {
    return RawDataModel(
      id: json['id'],
      serviceName: json['serviceName'],
      serviceValue: json['serviceValue'],
      name: json['name'],
      value: json['value'],
    );
  }
}
