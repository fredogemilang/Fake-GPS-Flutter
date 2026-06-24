class RoutePoint {
  final double latitude;
  final double longitude;
  final int order;

  const RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.order,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'order': order,
      };

  factory RoutePoint.fromJson(Map<String, dynamic> json) => RoutePoint(
        latitude: json['latitude'] as double,
        longitude: json['longitude'] as double,
        order: json['order'] as int,
      );
}
