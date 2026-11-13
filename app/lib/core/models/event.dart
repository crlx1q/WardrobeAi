class WardrobeEvent {
  final String id;
  final String title;
  final DateTime date;
  final String dressCode;
  final String notes;
  final String? plannedOutfitId;

  const WardrobeEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.dressCode,
    required this.notes,
    this.plannedOutfitId,
  });

  factory WardrobeEvent.fromJson(Map<String, dynamic> json) {
    return WardrobeEvent(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      dressCode: json['dressCode'] ?? '',
      notes: json['notes'] ?? '',
      plannedOutfitId: json['plannedOutfitId']?.toString(),
    );
  }
}
