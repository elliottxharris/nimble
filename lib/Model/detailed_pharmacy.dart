class DetailedPharmacy {
  String name, street, city, state, zip, phone;
  double lat, long;
  List<String> hours;

  DetailedPharmacy.fromJson(Map<String, dynamic> json)
      : name = json['name'] ?? 'N/A',
        street = json['address']['streetAddress1'] ?? 'N/A',
        city = json['address']['city'] ?? 'N/A',
        state = json['address']['usTerritory'] ?? 'N/A',
        hours = (json['pharmacyHours'] != null) ? json['pharmacyHours'].split(' \\n ') : [],
        zip = json['address']['postalCode'] ?? 'N/A',
        phone = json['primaryPhoneNumber'] ?? 'N/A',
        lat = json['address']['latitude'] ?? 'N/A',
        long = json['address']['longitude'] ?? 'N/A';
}
