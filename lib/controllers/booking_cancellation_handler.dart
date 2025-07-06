import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingCancellationHandler {
  final supabase = Supabase.instance.client;
  
  /// Cancels a booking and handles all related cleanup including membership_data
  Future<bool> cancelBookingWithMembership({
    required String bookingId,
    required String? customerId,
  }) async {
    try {
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      String? centerSlug = preferences.getString('centerSlug');
      
      if (centerSlug == null) {
        print('Error: centerSlug not found');
        return false;
      }
      
      // Start a transaction-like operation
      bool success = true;
      
      // 1. Update booking status to cancelled
      final bookingUpdate = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('bookings')
          .update({
            'is_cancelled': true,
            'status': 'Cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId)
          .select()
          .single();
          
      print('Booking $bookingId cancelled: $bookingUpdate');
      
      // 2. Update all booking slots to cancelled
      final slotsUpdate = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('booking_slots')
          .update({
            'status': 'Cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('booking_id', bookingId);
          
      print('Booking slots cancelled for booking $bookingId');
      
      // 3. Check if this booking has an associated pending membership
      if (customerId != null) {
        // Look for pending membership_data for this customer
        final pendingMembership = await supabase
            .schema('${centerSlug}_prod_schema')
            .from('membership_data')
            .select('*')
            .eq('customer_id', customerId)
            .eq('status', false) // false = pending
            .maybeSingle();
            
        if (pendingMembership != null) {
          print('Found pending membership for customer $customerId');
          
          // Check if this pending membership was created around the same time as the booking
          // This helps ensure we're deleting the right membership_data record
          final bookingCreatedAt = bookingUpdate['created_at'];
          final membershipCreatedAt = pendingMembership['created_at'];
          
          if (bookingCreatedAt != null && membershipCreatedAt != null) {
            final bookingTime = DateTime.parse(bookingCreatedAt);
            final membershipTime = DateTime.parse(membershipCreatedAt);
            final timeDifference = bookingTime.difference(membershipTime).abs();
            
            // If membership was created within 5 minutes of the booking, it's likely related
            if (timeDifference.inMinutes <= 5) {
              // Delete the pending membership_data record
              await supabase
                  .schema('${centerSlug}_prod_schema')
                  .from('membership_data')
                  .delete()
                  .eq('id', pendingMembership['id']);
                  
              print('Deleted pending membership_data record: ${pendingMembership['id']}');
              
              // Also clear any membership references in the customer record
              await supabase
                  .schema('${centerSlug}_prod_schema')
                  .from('customers')
                  .update({
                    'membership_data': null,  // Clear the membership_data JSON column
                    'membership_data_id': null,
                    'membershipplan_id': null,
                  })
                  .eq('id', customerId);
                  
              print('Cleared membership references from customer record');
            } else {
              print('Pending membership found but created at different time - not deleting');
            }
          }
        }
      }
      
      // 4. Cancel any pending membership payments if they exist
      try {
        await supabase
            .schema('${centerSlug}_prod_schema')
            .from('membershippayment')
            .update({
              'status': false,
              'notes': 'Cancelled with booking $bookingId',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .match({
              'booking_id': bookingId,
              'status': true, // Only update pending payments
            });
            
        print('Updated any pending membership payments');
      } catch (e) {
        print('No membership payments to update or error: $e');
      }
      
      return success;
    } catch (e) {
      print('Error cancelling booking: $e');
      return false;
    }
  }
  
  /// Check if a booking has associated membership that needs cleanup
  Future<bool> bookingHasPendingMembership({
    required String bookingId,
  }) async {
    try {
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      String? centerSlug = preferences.getString('centerSlug');
      
      if (centerSlug == null) return false;
      
      // Get booking details
      final booking = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('bookings')
          .select('customer_id, created_at')
          .eq('id', bookingId)
          .single();
          
      if (booking == null || booking['customer_id'] == null) return false;
      
      // Check for pending membership
      final pendingMembership = await supabase
          .schema('${centerSlug}_prod_schema')
          .from('membership_data')
          .select('id')
          .eq('customer_id', booking['customer_id'])
          .eq('status', false)
          .maybeSingle();
          
      return pendingMembership != null;
    } catch (e) {
      print('Error checking for pending membership: $e');
      return false;
    }
  }
}