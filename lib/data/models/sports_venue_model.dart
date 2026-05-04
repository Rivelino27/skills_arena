import 'package:cloud_firestore/cloud_firestore.dart';

const List<String> kSportsList = [
  'Futebol',
  'Basquete',
  'Vôlei',
  'Tênis',
  'Beach Tennis',
  'Futevôlei',
  'Natação',
  'Corrida',
  'Outros',
];

class SportsVenueModel {
  final String id;
  final String name;
  final String sport;
  final double lat;
  final double lng;
  final String? address;
  final String addedBy;
  final String addedByName;
  final DateTime createdAt;

  const SportsVenueModel({
    required this.id,
    required this.name,
    required this.sport,
    required this.lat,
    required this.lng,
    this.address,
    required this.addedBy,
    required this.addedByName,
    required this.createdAt,
  });

  factory SportsVenueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SportsVenueModel(
      id: doc.id,
      name: data['name'] as String,
      sport: data['sport'] as String,
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      address: data['address'] as String?,
      addedBy: data['addedBy'] as String,
      addedByName: data['addedByName'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'sport': sport,
        'lat': lat,
        'lng': lng,
        'address': address,
        'addedBy': addedBy,
        'addedByName': addedByName,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
