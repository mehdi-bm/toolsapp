import 'package:toolbax/features/app_support/domain/app_support_gateway.dart';
import 'package:toolbax/features/app_support/domain/support_receipt.dart';

class FakeAppSupportGateway implements AppSupportGateway {
  bool isConfiguredValue = true;
  Object? errorToThrow;
  SupportReceipt? receiptToReturn;
  Map<String, String>? lastErrorReportArgs;
  Map<String, String>? lastAdvertisingRequestArgs;
  int errorReportCallCount = 0;
  int advertisingRequestCallCount = 0;

  @override
  bool get isConfigured => isConfiguredValue;

  @override
  Future<SupportReceipt> submitErrorReport({required String description}) async {
    errorReportCallCount++;
    lastErrorReportArgs = {'description': description};
    if (errorToThrow != null) throw errorToThrow!;
    return receiptToReturn ??
        const SupportReceipt(id: 'r1', type: 'ErrorReport', status: 'New');
  }

  @override
  Future<SupportReceipt> submitAdvertisingRequest({
    required String fullName,
    required String phoneNumber,
    required String province,
    required String city,
    required String details,
  }) async {
    advertisingRequestCallCount++;
    lastAdvertisingRequestArgs = {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'province': province,
      'city': city,
      'details': details,
    };
    if (errorToThrow != null) throw errorToThrow!;
    return receiptToReturn ??
        const SupportReceipt(id: 'a1', type: 'AdvertisingRequest', status: 'New');
  }

  @override
  void close() {}
}
