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

/// Self-reported crowding level at a venue right now.
enum VenueOccupancy { unknown, empty, few, full }

extension VenueOccupancyX on VenueOccupancy {
  String get label {
    switch (this) {
      case VenueOccupancy.empty:
        return 'Vazio';
      case VenueOccupancy.few:
        return 'Poucas pessoas';
      case VenueOccupancy.full:
        return 'Cheio';
      case VenueOccupancy.unknown:
        return 'Sem informação';
    }
  }

  String get storageKey => name; // 'unknown' | 'empty' | 'few' | 'full'
}

VenueOccupancy occupancyFromString(String? raw) {
  switch (raw) {
    case 'empty':
      return VenueOccupancy.empty;
    case 'few':
      return VenueOccupancy.few;
    case 'full':
      return VenueOccupancy.full;
    default:
      return VenueOccupancy.unknown;
  }
}

class SportsVenueModel {
  final String id;
  final String name;
  final String sport;
  final double lat;
  final double lng;
  final String? address;
  final String addedBy;
  final String addedByName;
  final bool isPublic;
  final VenueOccupancy occupancy;
  final DateTime? occupancyUpdatedAt;
  final String? occupancyUpdatedBy;
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
    this.isPublic = true,
    this.occupancy = VenueOccupancy.unknown,
    this.occupancyUpdatedAt,
    this.occupancyUpdatedBy,
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
      isPublic: data['isPublic'] as bool? ?? true,
      occupancy: occupancyFromString(data['occupancy'] as String?),
      occupancyUpdatedAt: data['occupancyUpdatedAt'] != null
          ? (data['occupancyUpdatedAt'] as Timestamp).toDate()
          : null,
      occupancyUpdatedBy: data['occupancyUpdatedBy'] as String?,
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
        'isPublic': isPublic,
        'occupancy': occupancy.storageKey,
        'occupancyUpdatedAt': occupancyUpdatedAt != null
            ? Timestamp.fromDate(occupancyUpdatedAt!)
            : null,
        'occupancyUpdatedBy': occupancyUpdatedBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
