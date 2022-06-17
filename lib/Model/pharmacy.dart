class Pharmacy {
  String name, id;

  Pharmacy.fromJson(Map<String, dynamic> json) 
    : id = json['pharmacyId']!, name = json['name']!;
}