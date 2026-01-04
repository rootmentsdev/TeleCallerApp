import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:telecaller_app/model/booking_cofirmation_model.dart';
import 'package:telecaller_app/services/api_service.dart';

class BookingConfirmationController extends ChangeNotifier {
  final ApiService _apiService;

  BookingConfirmationController({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  bool _isLoading = false;
  List<BookingConfirmationLead> _leads = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<BookingConfirmationLead> get leads => _leads;
  String? get errorMessage => _errorMessage;

  Future<void> fetchLeads({String? store}) async {
    if (_isLoading) {
      print(
        'BookingConfirmationController: Already loading Booking Confirmation leads, skipping...',
      );
      return;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      print(
        'BookingConfirmationController: Fetching Booking Confirmation leads',
      );

      // Pass store in "Brand - Location" format (e.g., "Suitor Guy - Edappal")
      final storeFilter =
          (store == null || store == 'All Stores') ? null : store;
      final res = await _apiService.getBookingConfirmationLeads(
        store: storeFilter,
      );
      final List data = (res['data'] ?? []) as List;

      _leads =
          data
              .map(
                (e) => BookingConfirmationLead.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();

      print(
        'BookingConfirmationController: Total Booking Confirmation leads: ${_leads.length}',
      );
    } catch (e, s) {
      _errorMessage = e.toString();
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'fetchBookingConfirmationLeads failed');
      print(
        'BookingConfirmationController: Error while fetching Booking Confirmation leads: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
