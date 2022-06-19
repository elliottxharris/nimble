import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nimble_test/Model/detailed_pharmacy.dart';
import 'package:nimble_test/Model/order_list.dart';
import 'package:nimble_test/Model/pharmacy.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../Model/order.dart';

class PharmacyDetail extends StatefulWidget {
  const PharmacyDetail({Key? key, required this.pharmacy}) : super(key: key);

  final Pharmacy pharmacy;

  @override
  State<PharmacyDetail> createState() => _PharmacyDetailState();
}

class _PharmacyDetailState extends State<PharmacyDetail> {
  late Future<DetailedPharmacy?> detailedPharmacy;

  Future<DetailedPharmacy?> getDetailedPharmacy() async {
    http.Response res = await http.get(Uri.parse(
        'https://api-qa-demo.nimbleandsimple.com/pharmacies/info/${widget.pharmacy.id}'));

    if (res.statusCode == 200) {
      return DetailedPharmacy.fromJson(jsonDecode(res.body)['value']);
    }

    return null;
  }

  String formatPhone(String num) => num != 'N/A'
      ? '(${num.substring(2, 5)}) ${num.substring(5, 8)}-${num.substring(8, 12)}'
      : 'N/A';

  @override
  void initState() {
    detailedPharmacy = getDetailedPharmacy();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.pharmacy.name)),
      body: FutureBuilder(
        future: detailedPharmacy,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasData) {
            DetailedPharmacy pharmacy = snap.data! as DetailedPharmacy;

            return SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 200,
                    child: FlutterMap(
                      options: MapOptions(
                          center: LatLng(pharmacy.lat, pharmacy.long),
                          zoom: 18),
                      layers: [
                        TileLayerOptions(
                          urlTemplate:
                              "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                          subdomains: ['a', 'b', 'c'],
                        ),
                        MarkerLayerOptions(
                          markers: [
                            Marker(
                              width: 30.0,
                              height: 30.0,
                              point: LatLng(pharmacy.lat, pharmacy.long),
                              builder: (context) {
                                return Stack(
                                  children: const [
                                    Align(
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.circle,
                                          color: Colors.blue,
                                          size: 25,
                                        )),
                                    Align(
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.circle,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    )
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                      nonRotatedChildren: [
                        AttributionWidget.defaultWidget(
                          source: 'OpenStreetMap contributors',
                          onSourceTapped: () {},
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Text('Address'),
                        const Spacer(),
                        Text(
                            '${pharmacy.street}, ${pharmacy.city}, ${pharmacy.state}')
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Text('Phone Number'),
                        const Spacer(),
                        Text(formatPhone(pharmacy.phone))
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const Text('Hours'),
                        (pharmacy.hours.isNotEmpty)
                            ? ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: pharmacy.hours.length,
                                itemBuilder: (context, index) => Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(pharmacy.hours[index]),
                                  ),
                                ),
                              )
                            : const Text('Not Available')
                      ],
                    ),
                  ),
                  Visibility(
                    visible: widget.pharmacy.hasOrderedFrom,
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Consumer<OrderList>(
                          builder: (context, provider, child) {
                            List<Order> orders = provider.getOrders;
                            Order order = orders.firstWhere(
                              (element) => element.pharmacy == pharmacy.name,
                              orElse: () {
                                return Order(pharmacy: pharmacy.name, meds: []);
                              },
                            );
                            return Column(
                              children: [
                                const Text('Previous Order'),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: order.meds.length,
                                  itemBuilder: (context, index) => Center(
                                    child: Text(order.meds[index])
                                  ),
                                )
                              ],
                            );
                          },
                        )),
                  ),
                ],
              ),
            );
          } else {
            return const Center(
              child: Text('Unavailable'),
            );
          }
        },
      ),
    );
  }
}
