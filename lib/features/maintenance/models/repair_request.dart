import 'package:ai_poc_monitoring_app/features/maintenance/models/repair_status.dart';

class RepairRequest {
  final String id;
  final String userId;
  final String shopId;
  final String shopName;
  final String shopImageUrl; // Snapshot for display
  final RepairStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  RepairRequest({
    required this.id,
    required this.userId,
    required this.shopId,
    required this.shopName,
    required this.shopImageUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RepairRequest.fromJson(Map<String, dynamic> json) {
    return RepairRequest(
      id: json['id'],
      userId: json['user_id'],
      shopId: json['shop_id'],
      shopName: json['shop_name'],
      shopImageUrl: json['shop_image_url'] ?? '',
      status: RepairStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RepairStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'shop_id': shopId,
      'shop_name': shopName,
      'shop_image_url': shopImageUrl,
      'status': status.name,
      // created_at and updated_at are usually handled by DB, but sending for consistency if needed
    };
  }
}
