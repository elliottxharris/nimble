import 'package:nimble_test/Model/order.dart';
import 'package:flutter/material.dart';

class OrderList extends ChangeNotifier {
  List<Order> orders = [];

  List<Order> get getOrders => orders;

  addOrder(Order order) {
    orders.add(order);
    notifyListeners();
  }
}