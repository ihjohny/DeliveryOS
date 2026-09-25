class BannerModel {
  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? actionType;
  final String? actionValue;
  final String? deepLink;
  final int sortOrder;

  BannerModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.actionType,
    this.actionValue,
    this.deepLink,
    this.sortOrder = 0,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String? ?? '',
      actionType: json['actionType'] as String? ?? json['action_type'] as String?,
      actionValue: json['actionValue'] as String? ?? json['action_value'] as String?,
      deepLink: json['deepLink'] as String? ?? json['deep_link'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
