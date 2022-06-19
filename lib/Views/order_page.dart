import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nimble_test/Model/order.dart';
import 'package:nimble_test/Model/order_list.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({Key? key, required this.pharmacy}) : super(key: key);

  final String pharmacy;

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  late List<String> medlist;
  List<String> filtered = [];
  List<String> selected = [];

  getMeds() async {
    http.Response res = await http.get(
      Uri.parse(
        'https://s3-us-west-2.amazonaws.com/assets.nimblerx.com/prod/medicationListFromNIH/medicationListFromNIH.txt',
      ),
    );

    medlist = res.body.split(',');
  }

  filterMeds(String pred) {
    setState(() {
      filtered = List.of(medlist.where((element) => element.contains(pred)));
    });
  }

  @override
  void initState() {
    getMeds();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController editingController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Order')),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onChanged: (value) {
                    if (value.length >= 3) {
                      filterMeds(value);
                    } else {
                      setState(() {
                        filtered = [];
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: "Search",
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              Visibility(
                visible: filtered.isNotEmpty,
                child: Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: () {
                          if (selected.contains(filtered[index])) {
                            setState(() {
                              selected.remove(filtered[index]);
                            });
                          } else {
                            setState(() {
                              selected.add(filtered[index]);
                            });
                          }
                        },
                        child: Row(
                          children: [
                            Text(filtered[index]),
                            const Spacer(),
                            Visibility(
                              visible: selected.contains(filtered[index]),
                              child: const Icon(
                                Icons.check,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
          Align(alignment: Alignment.bottomCenter, child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: ElevatedButton(onPressed: () async {
              SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

              OrderList provider = Provider.of<OrderList>(context, listen: false);
              provider.addOrder(Order(pharmacy: widget.pharmacy, meds: selected));

              String lengthsString = sharedPreferences.getString('lengths')!;
              List<dynamic> lengths = jsonDecode(lengthsString);
              lengths[lengths.indexWhere((element) => element['name'] == widget.pharmacy)]['ordered'] = true;
              sharedPreferences.setString('lengths', jsonEncode(lengths));

              print('Pharmacy: ${widget.pharmacy}');
              print('Meds: $selected');

              Navigator.of(context).pop();
            }, child: const Text('Place'),),
          ),)
        ],
      ),
    );
  }
}
