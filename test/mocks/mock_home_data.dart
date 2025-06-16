import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import 'package:qanta/modules/home/models/index.dart';
import 'package:qanta/modules/home/models/recent_transaction_view_model.dart';

class MockData {
  static List<PaymentModel> get payments => [
    const PaymentModel(
      title: 'Elektrik Faturası',
      company: 'BEDAŞ',
      amount: 245.80,
      dueDate: 'Yarın',
      isUrgent: true,
    ),
    const PaymentModel(
      title: 'İnternet Faturası',
      company: 'Türk Telekom',
      amount: 89.90,
      dueDate: '3 gün',
      isUrgent: false,
    ),
    const PaymentModel(
      title: 'Kredi Kartı',
      company: 'Qanta Bank',
      amount: 1250.00,
      dueDate: '5 gün',
      isUrgent: false,
    ),
  ];

  static List<RecentTransactionViewModel> get transactions => [
    const RecentTransactionViewModel(
      icon: Icons.shopping_bag_outlined,
      title: 'Apple Store',
      subtitle: 'Macbook Pro 16',
      time: '10:45 AM',
      amount: -2499.99,
      color: Colors.orange,
    ),
    const RecentTransactionViewModel(
      icon: Icons.receipt_long_outlined,
      title: 'Monthly Salary',
      subtitle: 'From: QANTA Tech Inc.',
      time: '09:00 AM',
      amount: 5000.00,
      color: Colors.green,
    ),
    const RecentTransactionViewModel(
      icon: Icons.coffee_outlined,
      title: 'Starbucks',
      subtitle: 'Latte & Croissant',
      time: 'Yesterday',
      amount: -8.50,
      color: Colors.brown,
    ),
  ];

  static List<PaymentModel> get upcomingPayments => [
    const PaymentModel(
      title: 'Elektrik Faturası',
      company: 'BEDAŞ',
      amount: 245.80,
      dueDate: 'Yarın',
      isUrgent: true,
    ),
    const PaymentModel(
      title: 'İnternet Faturası',
      company: 'Türk Telekom',
      amount: 89.90,
      dueDate: '3 gün',
      isUrgent: false,
    ),
    const PaymentModel(
      title: 'Kredi Kartı',
      company: 'Qanta Bank',
      amount: 1250.00,
      dueDate: '5 gün',
      isUrgent: false,
    ),
  ];
} 