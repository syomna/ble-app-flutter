class SendDataModel {
  final String command;
  final int value;

  SendDataModel({required this.command, required this.value});

  factory SendDataModel.fromJson(Map<String, dynamic> json) {
    return SendDataModel(
      command: json['command'],
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'command': command,
      'value': value,
    };
  }
}
