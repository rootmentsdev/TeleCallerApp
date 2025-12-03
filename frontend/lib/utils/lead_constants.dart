/// Constants for Lead Categories and Call Statuses
class LeadConstants {
  // Lead Categories
  static const String categoryLossOfSales = "Loss of Sales";
  static const String categoryRentOut = "Rent out";
  static const String categoryBookingConfirmation = "Booking confirmation";
  static const String categoryJustDial = "Just Dial";
  static const String categoryFollowUp = "Follow Up";
  static const String categoryFeedback = "Feedback";

  // Call Statuses
  static const String callStatusNotCalled = "Not Called";
  static const String callStatusNotCalledYet = "Not called yet";
  static const String callStatusConnected = "Connected";
  static const String callStatusNotConnected = "Not Connected";
  static const String callStatusCallBackLater = "Call Back Later";
  static const String callStatusConfirmed = "Confirmed";
  static const String callStatusCancelled = "Cancelled";
  static const String callStatusBusy = "Busy";

  // Lead Statuses
  static const String leadStatusNewLead = "New Lead";
  static const String leadStatusContacted = "Contacted";
  static const String leadStatusQualified = "Qualified";
  static const String leadStatusNegotiation = "Negotiation";
  static const String leadStatusWon = "Won";
  static const String leadStatusLost = "Lost";

  // Check if call status means "not called"
  static bool isUncalledStatus(String? callStatus) {
    return callStatus == null ||
        callStatus == callStatusNotCalled ||
        callStatus == callStatusNotCalledYet;
  }

  // Check if call status means "called"
  static bool isCalledStatus(String? callStatus) {
    return callStatus != null &&
        callStatus != callStatusNotCalled &&
        callStatus != callStatusNotCalledYet;
  }
}
