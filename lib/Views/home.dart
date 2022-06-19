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
  late Future<String?> lengthsString;
  bool gettingLocations = false;
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
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? lengthsString = sharedPreferences.getString('lengths');
    if (lengthsString == null) {
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
          'length': distance(currentLocation, pharmacyLocation),
          'ordered': false
        });
      }

      lengths.sort(((a, b) => a['length'].compareTo(b['length'])));

      sharedPreferences.setString('lengths', jsonEncode(lengths));

      return lengths.first['name'];
    } else {
      List<dynamic> lengths = jsonDecode(lengthsString);

      return lengths
          .firstWhere((element) => element['ordered'] == false)['name'];
    }
  }

  Future<String?> getLengths() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString('lengths');
  }

  @override
  void initState() {
    lengthsString = getLengths();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    pharmacies = List.of((jsonDecode(json)['pharmacies']! as List)
        .map((e) => Pharmacy.fromJson(e)));
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Stack(
        children: [
          FutureBuilder(
            future: lengthsString,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (snap.hasData) {
                List<dynamic> lengths = jsonDecode(snap.data!.toString());
                List<String> filtered = List.of(lengths
                    .where((element) => element['ordered'] == true)
                    .map((e) => e['name']));

                pharmacies = List.of(pharmacies.map((e) {
                  if (filtered.contains(e.name)) {
                    e.hasOrderedFrom = true;
                  }

                  return e;
                }));
              }
              return ListView.separated(
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                PharmacyDetail(pharmacy: pharmacies[index])));
                      },
                      child: ListTile(
                        title: Row(children: [
                          Text(pharmacies[index].name),
                          if (pharmacies[index].hasOrderedFrom)
                            const Icon(Icons.check)
                        ]),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => const Divider(
                        color: Colors.black,
                      ),
                  itemCount: pharmacies.length);
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      gettingLocations = true;
                    });
                    String closest = await findClosest();
                    setState(() {
                      gettingLocations = false;
                    });
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => OrderPage(
                          pharmacy: closest,
                        ),
                      ),
                    );
                    setState(() {
                      lengthsString = getLengths();
                    });
                  },
                  child: (gettingLocations)
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                      : const Text('Order')),
            ),
          )
        ],
      ),
    );
  }
}
