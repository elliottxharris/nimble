import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nimble_test/Model/detailed_pharmacy.dart';
import 'package:nimble_test/Model/order_list.dart';
import 'package:nimble_test/Model/pharmacy.dart';
import 'package:nimble_test/Views/order_page.dart';
import 'package:nimble_test/Views/pharmacy_detail.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late List<Pharmacy> pharmacies;
  final String json = '''
  {
    "pharmacies": [
      {
        "name": "ReCept",
        "pharmacyId": "NRxPh-HLRS"
      },
      {
        "name": "My Community Pharmacy", 
        "pharmacyId": "NRxPh-BAC1"
      }, 
      {
        "name": "MedTime Pharmacy",
        "pharmacyId": "NRxPh-SJC1" 
      },
      {
        "name": "NY Pharmacy", 
        "pharmacyId": "NRxPh-ZEREiaYq"
      }
    ]
  }
  ''';

  Future<String> findClosest() async {
    LatLng currentLocation = LatLng(37.48771670017411, -122.22652739630438);
    List<DetailedPharmacy> detailedPharmacies = [];
    Iterable<String> ids = pharmacies.map((e) => e.id);
    List<Map<String, dynamic>> lengths = [];

    for (var id in ids) {
      http.Response res = await http.get(Uri.parse(
          'https://api-qa-demo.nimbleandsimple.com/pharmacies/info/$id'));

      if (res.statusCode == 200) {
        detailedPharmacies
            .add(DetailedPharmacy.fromJson(jsonDecode(res.body)['value']));
      }
    }

    for (var pharmacy in detailedPharmacies) {
      LatLng pharmacyLocation = LatLng(pharmacy.lat, pharmacy.long);
      Distance distance = const Distance();

      lengths.add({
        'name': pharmacy.name,
        'length': distance(currentLocation, pharmacyLocation)
      });
    }

    lengths.sort(((a, b) => a['length'].compareTo(b['length'])));

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString('lengths', jsonEncode(lengths));

    return lengths.first['name'];
  }

  @override
  Widget build(BuildContext context) {
    pharmacies = List.of((jsonDecode(json)['pharmacies']! as List)
        .map((e) => Pharmacy.fromJson(e)));
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Stack(
        children: [
          ListView.separated(
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            PharmacyDetail(pharmacy: pharmacies[index])));
                  },
                  child: ListTile(
                    title: Text(pharmacies[index].name),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
              separatorBuilder: (context, index) => const Divider(
                    color: Colors.black,
                  ),
              itemCount: pharmacies.length),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton(
                onPressed: () async{
                  String closest = await findClosest();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => OrderPage(
                        pharmacy: closest,
                      ),
                    ),
                  );
                },
                child: const Text('Order'),
              ),
            ),
          )
        ],
      ),
    );
  }
}
