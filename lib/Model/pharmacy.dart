class Pharmacy {
  String name, id;
  bool hasOrderedFrom = false;

  Pharmacy.fromJson(Map<String, dynamic> json) 
    : id = json['pharmacyId']!, name = json['name']!;
}