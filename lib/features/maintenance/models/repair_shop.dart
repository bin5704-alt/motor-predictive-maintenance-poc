class Review {
  final String userName;
  final String role;
  final double rating;
  final String date;
  final String comment;

  const Review({
    required this.userName,
    required this.role,
    required this.rating,
    required this.date,
    required this.comment,
  });
}

class RepairShop {
  final int id;
  final String name;
  final String location;
  final double distanceKm;
  final double rating;
  final int reviewCount;
  final bool isPremium;
  final List<String> specializations;
  final List<String> equipment;
  final String imageUrl;
  final List<Review> reviews; // Added reviews list

  const RepairShop({
    required this.id,
    required this.name,
    required this.location,
    required this.distanceKm,
    required this.rating,
    required this.reviewCount,
    required this.isPremium,
    required this.specializations,
    required this.equipment,
    required this.imageUrl,
    this.reviews = const [], // Default to empty
  });
}
