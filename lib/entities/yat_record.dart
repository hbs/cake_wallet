class YatRecord {
  String category;
  String address;

  YatRecord({
    this.category,
    this.address,
  });

  YatRecord.fromJson(Map<String, dynamic> json) {
    address = json['address'] as String;
    category = json['category'] as String;
  }

  static const tags = {
    'XMR': '0x1001,0x1002',
    'BTC': '0x1003',
    'LTC': '0x3fff'
  };
}
