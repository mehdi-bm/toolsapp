import 'support_receipt.dart';

abstract class AppSupportGateway {
  bool get isConfigured;

  Future<SupportReceipt> submitErrorReport({required String description});

  Future<SupportReceipt> submitAdvertisingRequest({
    required String fullName,
    required String phoneNumber,
    required String province,
    required String city,
    required String details,
  });

  void close();
}
