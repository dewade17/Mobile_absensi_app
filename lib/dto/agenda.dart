import 'package:absensi_app/dto/work_agenda_item.dart';

class Workagenda {
  String? agendaId;
  String? userId;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<WorkagendaItem>? items;

  Workagenda({
    this.agendaId,
    this.userId,
    this.createdAt,
    this.updatedAt,
    this.items,
  });

  factory Workagenda.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'];
    final updatedAtRaw = json['updatedAt'];

    DateTime? safeParse(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return Workagenda(
      agendaId: json['agenda_id'],
      userId: json['user_id'],
      createdAt: safeParse(createdAtRaw),
      updatedAt: safeParse(updatedAtRaw),
      items: (json['items'] is List)
          ? (json['items'] as List)
              .map((e) => WorkagendaItem.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJsonWithItems() => {
        "agenda_id": agendaId,
        "user_id": userId,
        "items": items?.map((item) => item.toJson()).toList(),
      };
}
