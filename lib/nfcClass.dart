import 'dart:typed_data';

class NFCRecord {
  final String id;
  final String? name;
  final String? api;

  NFCRecord({required this.id, this.name, this.api});
  NFCRecord.empty({this.id = "hint", this.name, this.api});
}
