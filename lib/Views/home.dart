import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nimble_test/Model/order_list.dart';
import 'package:nimble_test/Model/pharmacy.dart';
import 'package:nimble_test/Views/order_page.dart';
import 'package:nimble_test/Views/pharmacy_detail.dart';
import 'package:provider/provider.dart';

class Homepage extends StatelessWidget {
  const Homepage({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    List<Pharmacy> pharmacies = List.of(
        (jsonDecode(json)['pharmacies']! as List)
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
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => OrderPage(
                            pharmacy: pharmacies[0].name,
                          ))),
                  child: const Text('Order'),
                ),
              ),
            )
          ],
        ),
      );
  }
}
