/// 站點資料模型
class Station {
  final String id;
  final String name;
  final int price; // 單程價格（來回價格自動為單程的2倍）

  Station({required this.id, required this.name, required this.price});

  /// 取得來回價格（單程的2倍）
  int get roundTripPrice => price * 2;

  /// 取得單程價格
  int get oneWayPrice => price;

  // 從 JSON 轉換（向後相容舊資料）
  factory Station.fromJson(Map<String, dynamic> json) {
    // 優先使用新的 price 欄位，如果沒有則使用 oneWayPrice
    final price = json['price'] as int? ?? json['oneWayPrice'] as int? ?? 0;

    return Station(
      id: json['id'] as String,
      name: json['name'] as String,
      price: price,
    );
  }

  // 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'price': price};
  }

  Station copyWith({String? id, String? name, int? price}) {
    return Station(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }
}
