import 'package:json_annotation/json_annotation.dart';
part 'TilerError.g.dart';

@JsonSerializable()
class TilerError {
  TilerError();
  String? Message;
  int? Code;

  factory TilerError.fromJson(Map<String, dynamic> json) =>
      _$TilerErrorFromJson(json);

  Map<String, dynamic> toJson() => _$TilerErrorToJson(this);
}