# Membership Feature Technical Specification

## Overview
This document outlines the complete membership system implementation for the booking application, tracking completed features and remaining milestones.

## Table of Contents
1. [Membership Structure](#membership-structure)
2. [Implementation Status](#implementation-status)
3. [Feature Specifications](#feature-specifications)
4. [Database Schema](#database-schema)
5. [API Endpoints](#api-endpoints)
6. [Business Logic](#business-logic)
7. [Remaining Milestones](#remaining-milestones)

## Membership Structure

### Core Membership Properties
- **Name**: Membership tier name (e.g., Bronze, Silver, Gold, Platinum)
- **Price**: One-time payment amount
- **Billing Period**: Subscription cycle (Monthly/Yearly)
- **Validity Period**: Duration in months
- **Status**: Active/Inactive/Expired

### Membership Benefits
1. **Discounts**
   - Off-Peak Discount: Fixed amount off regular pricing
   - Peak Hour Discount: Fixed amount off peak pricing
   - Minimum 60-minute booking required for discount application
   - Discounts can stack with promotional offers

2. **Booking Privileges**
   - Max Booking Hours: Maximum hours per court per transaction (e.g., 8 hours for Platinum)
   - Max Courts: Maximum courts per transaction (e.g., 4 courts for Platinum)
   - Important: Limits are PER COURT in a single transaction (4 courts × 8 hours = 32 court-hours possible)
   - Extended Bookings: Recurring bookings up to validity period
   - Advance Booking: Up to validity period (vs 1 week for non-members)

3. **Additional Features**
   - Time Swap: Reschedule bookings with 24-hour notice
   - Priority court booking
   - Guest passes (configurable per tier)
   - Equipment rental included
   - Personal trainer sessions
   - 24/7 support
   - Locker rental

## Implementation Status

### ✅ Completed Features

1. **Basic Membership Structure**
   - Database tables: `membershipplan`, `membership_data`, `membershippayment`
   - Membership plan CRUD operations
   - Customer-membership association

2. **Discount System**
   - Peak/off-peak hour discount application
   - 60-minute minimum booking validation
   - Flat discount per court (not per hour)
   - Discount stacking with promotional codes
   - Implemented in both booking and checkout flows

3. **Membership Purchase Flow**
   - Membership selection UI
   - Payment processing
   - Immediate activation upon payment
   - Membership upgrade with proration

4. **Validation System**
   - Membership validation at booking time
   - Membership validation at checkout
   - Concurrent booking handling
   - Pending membership status tracking

5. **Customer Management**
   - Member listing and search
   - Member detail view
   - Membership history per customer

### ⏳ In Progress Features

1. **Time Swap Functionality** (Partially Implemented)
   - Need to add swap UI in booking management
   - Payment gap calculation for off-peak to peak swaps
   - 24-hour advance notice validation

## Feature Specifications

### 1. Time Swap Feature

#### Requirements:
- Members can swap booked slots with 24-hour advance notice
- No restrictions on number of swaps
- Peak hour charges apply when swapping from off-peak
- Payment gap must be collected for upgrades
- Individual court swaps allowed for multi-court bookings
- No partial time swaps (full slot only)

#### Implementation Plan:
```typescript
interface TimeSwapRequest {
  bookingId: string;
  originalSlotId: string;
  newDate: Date;
  newStartTime: Date;
  newEndTime: Date;
  courtId?: string; // Optional for multi-court bookings
}

interface SwapPriceCalculation {
  originalPrice: number;
  newPrice: number;
  priceDifference: number;
  requiresPayment: boolean;
}
```

### 2. Extended/Recurring Bookings

#### Requirements:
- Members can book recurring slots up to membership validity
- Weekly recurring pattern support
- Individual modification of recurring bookings
- Auto-cancellation on membership expiry
- No blackout dates

#### Implementation Plan:
```typescript
interface RecurringBooking {
  masterBookingId: string;
  pattern: 'weekly' | 'biweekly' | 'monthly';
  dayOfWeek: number;
  startTime: string;
  endTime: string;
  courtId: string;
  endDate: Date; // Limited by membership validity
}
```

### 3. Booking Limits Management

#### Understanding of Limits:
- **Per Transaction Limits**: Members can book up to max_courts with each court bookable for max_hours
- **Example**: Platinum (4 courts × 8 hours) = up to 32 court-hours in one transaction
- **No Progressive Pricing**: Flat rate regardless of booking duration

#### Recommended Fair Usage Policy:
To ensure court availability for all customers while maintaining member benefits:

##### Option 1: Tiered Transaction Limits
```
Bronze: 2 courts × 2 hours per transaction (4 court-hours max)
Silver: 3 courts × 4 hours per transaction (12 court-hours max)  
Gold: 4 courts × 6 hours per transaction (24 court-hours max)
Platinum: 4 courts × 8 hours per transaction (32 court-hours max)
```

##### Option 2: Additional Safeguards
1. **Daily Aggregate Limit**: Total 12-16 court-hours per day across all bookings
2. **Peak Hour Restrictions**: Maximum 2-3 hours per court during peak times
3. **Advance Booking Limits**: For bookings > 3 days ahead, max 4 hours per court
4. **Consecutive Hours Cap**: Maximum 4 consecutive hours on same court

##### Option 3: Dynamic Fair Usage
- **High Demand Periods**: Reduce limits when court utilization > 80%
- **Weekend Limits**: 50% of weekday limits
- **Same-Day Flexibility**: Full limits for same-day bookings if availability > 50%

#### Implementation Requirements:
- Transaction-level validation (current booking)
- Daily aggregate tracking across all member bookings
- Flexible configuration without code changes
- Clear messaging when limits are reached
- Cancelled bookings don't count against limits

### 4. Membership Analytics & History

#### Requirements:
- Track membership purchase history
- Usage analytics (bookings, discounts used)
- Member retention metrics
- Revenue analytics per membership tier

### 5. Digital Membership Card

#### Requirements:
- Digital wallet integration
- QR code for member identification
- Membership details display
- Validity indicator

## Database Schema

### Existing Tables

```sql
-- membershipplan (stores plan templates)
- id: uuid
- name: text
- price: numeric
- billing_cycle: text
- validity: numeric (months)
- peak_price: numeric (discount amount)
- non_peak_price: numeric (discount amount)
- swap_time: boolean
- extended_bookings: boolean
- max_booking_hours: text
- max_courts: text
- highlights: array
- status: boolean

-- membership_data (stores member's active plan snapshot)
- id: uuid
- membershipplan_id: uuid
- customer_id: uuid
- purchased_date: timestamp
- validity_start: date
- validity_end: date
- status: boolean (pending/active)
- price_paid: numeric

-- customers (enhanced with membership)
- membershipplan_id: uuid (current plan reference)
- membership_data: jsonb (historical data)
- membership_data_id: uuid (active membership)
```

### Required New Tables

```sql
-- membership_swap_history
- id: uuid
- membership_data_id: uuid
- booking_slot_id: uuid
- original_datetime: timestamp
- new_datetime: timestamp
- price_difference: numeric
- swap_date: timestamp
- created_by: uuid

-- membership_usage_analytics
- id: uuid
- membership_data_id: uuid
- month: date
- bookings_count: integer
- hours_booked: numeric
- discount_used: numeric
- courts_booked: integer
- court_hours_used: numeric (total court-hours consumed)

-- membership_limits_config (for flexible limit management)
- id: uuid
- membershipplan_id: uuid
- limit_type: text (transaction/daily/peak/advance)
- max_value: numeric
- conditions: jsonb (e.g., {"peak_hours": true, "advance_days": 3})
- created_at: timestamp
```

## API Endpoints

### Existing Endpoints
- GET /membershipplans - List all active plans
- POST /membership/purchase - Purchase membership
- GET /customers/:id/membership - Get member details

### Required New Endpoints
- POST /bookings/:id/swap - Time swap request
- GET /bookings/:id/swap-price - Calculate swap pricing
- POST /bookings/recurring - Create recurring booking
- DELETE /bookings/recurring/:id - Cancel recurring booking
- GET /members/:id/analytics - Member usage analytics
- GET /members/:id/card - Digital membership card

## Business Logic

### Membership Lifecycle
1. **Purchase**: Immediate activation, no scheduling
2. **Active**: Full benefits available
3. **Expiring**: System notifications at 7 days before expiry
4. **Expired**: All future bookings cancelled, no grace period

### Discount Calculation
```typescript
function calculateMemberDiscount(booking: Booking, member: Member): number {
  if (booking.duration < 60) return 0;
  
  const isPeakHour = checkPeakHour(booking.startTime);
  const discountPerCourt = isPeakHour 
    ? member.plan.peak_discount 
    : member.plan.offpeak_discount;
  
  return discountPerCourt * booking.courts.length;
}
```

### Booking Limit Validation
```typescript
// Transaction-level validation (per booking)
function validateTransactionLimits(member: Member, booking: BookingRequest): ValidationResult {
  const maxCourtsPerTx = member.plan.max_courts; // e.g., 4
  const maxHoursPerCourtPerTx = member.plan.max_hours; // e.g., 8
  
  if (booking.courts.length > maxCourtsPerTx) {
    return { valid: false, message: `Maximum ${maxCourtsPerTx} courts per booking` };
  }
  
  for (const court of booking.courts) {
    if (court.hours > maxHoursPerCourtPerTx) {
      return { valid: false, message: `Maximum ${maxHoursPerCourtPerTx} hours per court` };
    }
  }
  
  return { valid: true };
}

// Daily aggregate validation (recommended addition)
function validateDailyLimits(member: Member, date: Date, newBooking: BookingRequest): ValidationResult {
  const existingBookings = await getBookingsForDate(member.id, date);
  const existingCourtHours = existingBookings.reduce((sum, b) => 
    sum + b.courts.reduce((courtSum, c) => courtSum + c.hours, 0), 0
  );
  
  const newCourtHours = newBooking.courts.reduce((sum, c) => sum + c.hours, 0);
  const dailyLimit = member.plan.daily_court_hours_limit || 16; // Configurable
  
  if (existingCourtHours + newCourtHours > dailyLimit) {
    return { 
      valid: false, 
      message: `Daily limit of ${dailyLimit} court-hours exceeded. You have ${dailyLimit - existingCourtHours} hours remaining today.` 
    };
  }
  
  return { valid: true };
}
```

## Remaining Milestones

### Phase 1: Time Swap Feature (Priority: High)
- [ ] Design swap UI in booking management screen
- [ ] Implement swap API endpoint
- [ ] Add price difference calculation
- [ ] Integrate payment collection for upgrades
- [ ] Add 24-hour validation logic
- [ ] Update booking history tracking

### Phase 2: Extended/Recurring Bookings (Priority: High)
- [ ] Design recurring booking UI
- [ ] Implement recurring booking creation
- [ ] Add recurring pattern management
- [ ] Build modification interface
- [ ] Implement auto-cancellation on expiry
- [ ] Add recurring booking indicators in calendar

### Phase 3: Digital Membership Card (Priority: Medium)
- [ ] Design digital card UI
- [ ] Generate unique QR codes
- [ ] Add to mobile wallet support
- [ ] Implement card scanning at venue
- [ ] Add offline validation capability

### Phase 4: Analytics Dashboard (Priority: Medium)
- [ ] Design analytics UI for admin
- [ ] Implement usage tracking
- [ ] Create member insights dashboard
- [ ] Add export functionality
- [ ] Build retention reports

### Phase 5: Enhanced Features (Priority: Low)
- [ ] Guest pass management system
- [ ] Equipment rental tracking
- [ ] Personal trainer booking integration
- [ ] Member communication system
- [ ] Loyalty rewards program

## Testing Requirements

### Unit Tests
- Discount calculation logic
- Daily limit validation
- Membership expiry handling
- Recurring booking generation

### Integration Tests
- Purchase flow with payment
- Booking with membership validation
- Time swap with payment
- Concurrent booking scenarios

### E2E Tests
- Complete member journey
- Upgrade/downgrade flow
- Expiry and cancellation flow

## Performance Considerations

1. **Caching**: Cache member benefits for quick access
2. **Indexing**: Add indexes on frequently queried fields
3. **Batch Processing**: Handle bulk cancellations efficiently
4. **Real-time Updates**: Use websockets for limit updates

## Security Considerations

1. **Access Control**: Verify membership ownership
2. **Payment Security**: PCI compliance for gap payments
3. **Data Privacy**: Encrypt sensitive member data
4. **Audit Trail**: Log all membership transactions

## Monitoring & Alerts

1. **Expiry Notifications**: 7-day advance warnings
2. **Usage Alerts**: Near-limit notifications
3. **Payment Failures**: Immediate admin alerts
4. **System Health**: Membership validation performance

---

## Version History
- v1.0 (2024-01-07): Initial specification created
- Next Update: After Phase 1 completion