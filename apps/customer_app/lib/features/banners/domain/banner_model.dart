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

  static List<BannerModel> get pilotBanners => [
    BannerModel(
      id: 'banner-1',
      title: '50% OFF Biryani Feast',
      subtitle: 'Valid on Sultan\'s Dine & Kacchi Bhai',
      imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=800&q=80',
      actionType: 'CATEGORY',
      actionValue: 'Biryani',
    ),
    BannerModel(
      id: 'banner-2',
      title: 'Free Delivery in Banani & Gulshan',
      subtitle: 'On all orders above ৳300',
      imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80',
      actionType: 'OUTLET',
      actionValue: 'b8b33bf6-6b22-4bb3-9d41-e9fb94c25601',
    ),
    BannerModel(
      id: 'banner-3',
      title: 'Instant Fresh Groceries',
      subtitle: 'Delivered in 15 mins from Shwapno',
      imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&q=80',
      actionType: 'CATEGORY',
      actionValue: 'Groceries',
    ),
  ];
}
