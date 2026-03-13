class PromotionModel {
  final String id;
  final String title;
  final String description;
  final double discountPercentage;
  final String type;
  final bool isAutoApplied;
  final List<int>? activeMonths;
  final String? targetRegion;

  PromotionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.discountPercentage,
    required this.type,
    required this.isAutoApplied,
    this.activeMonths,
    this.targetRegion,
  });

  factory PromotionModel.fromMap(String id, Map<String, dynamic> map) {
    return PromotionModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      discountPercentage: (map['discountPercentage'] ?? 0.0).toDouble(),
      type: map['type'] ?? 'seasonal',
      isAutoApplied: map['isAutoApplied'] ?? false,
      activeMonths: map['activeMonths'] != null
          ? List<int>.from(map['activeMonths'])
          : null,
      targetRegion: map['targetRegion'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'discountPercentage': discountPercentage,
      'type': type,
      'isAutoApplied': isAutoApplied,
      if (activeMonths != null) 'activeMonths': activeMonths,
      if (targetRegion != null) 'targetRegion': targetRegion,
    };
  }
}
