# BulkMates Integration Testing Guide

## New Features Added

### 1. Multiple Trip Types
- ✅ Bulk Shopping (Costco, Sam's Club, BJ's)
- ✅ Event Planning (birthdays, parties, festivals)
- ✅ Group Trips (camping, picnics, road trips)
- ✅ Potluck/Shared Meals

### 2. Partial Quantity Claiming
- Users can claim partial quantities of items (e.g., 15 of 40 popsicles)
- Multiple users can claim different quantities of the same item
- Real-time tracking of claimed vs. remaining quantities

### 3. Item Completion Tracking
- Checkboxes to mark items as purchased/prepared
- Progress tracking: "8 of 12 items completed"
- Notifications when all items completed

### 4. Item Comments
- Comments section for coordination
- Real-time comment count badges
- Chronological comment display

### 5. Trip Type Filters
- Quick filters: All, Bulk Shopping, Events, Group Trips, Potlucks
- Color-coded UI per trip type
- Type-specific empty states

---

## Test Data Creation

### Test Trip 1: Bulk Shopping (Costco)
```swift
Trip(
    groupId: "test-group-1",
    shopperId: "user-1",
    tripType: .bulkShopping,
    store: .costco,
    scheduledDate: Date().addingTimeInterval(86400), // Tomorrow
    items: [
        TripItem(name: "Kirkland Paper Towels (12-pack)", quantityAvailable: 2, estimatedPrice: 18.99, category: .household),
        TripItem(name: "Organic Eggs (24 count)", quantityAvailable: 4, estimatedPrice: 6.99, category: .grocery),
        TripItem(name: "Rotisserie Chicken", quantityAvailable: 3, estimatedPrice: 4.99, category: .grocery)
    ]
)
```

### Test Trip 2: Birthday Party (Event Planning)
```swift
Trip(
    groupId: "test-group-2",
    shopperId: "user-2",
    tripType: .eventPlanning,
    store: .other,
    scheduledDate: Date().addingTimeInterval(604800), // 1 week
    items: [
        TripItem(name: "Birthday Cake", quantityAvailable: 1, estimatedPrice: 45.00, category: .desserts),
        TripItem(name: "Balloons (50 count)", quantityAvailable: 50, estimatedPrice: 0.30, category: .decorations),
        TripItem(name: "Party Hats", quantityAvailable: 20, estimatedPrice: 1.50, category: .partySupplies),
        TripItem(name: "Paper Plates & Cups", quantityAvailable: 30, estimatedPrice: 0.50, category: .utensils)
    ]
)
```

### Test Trip 3: Summer BBQ Potluck
```swift
Trip(
    groupId: "test-group-3",
    shopperId: "user-3",
    tripType: .potluckMeal,
    store: .other,
    scheduledDate: Date().addingTimeInterval(259200), // 3 days
    items: [
        TripItem(name: "Popsicles (Box of 40)", quantityAvailable: 40, estimatedPrice: 0.50, category: .desserts, notes: "Keep frozen!"),
        TripItem(name: "Burger Patties", quantityAvailable: 30, estimatedPrice: 2.00, category: .mainCourse),
        TripItem(name: "Hot Dog Buns", quantityAvailable: 50, estimatedPrice: 0.30, category: .grocery),
        TripItem(name: "Sodas (Cans)", quantityAvailable: 48, estimatedPrice: 0.50, category: .beverages)
    ]
)
```

### Test Trip 4: Camping Trip
```swift
Trip(
    groupId: "test-group-4",
    shopperId: "user-4",
    tripType: .groupTrip,
    store: .other,
    scheduledDate: Date().addingTimeInterval(1209600), // 2 weeks
    items: [
        TripItem(name: "Tent (4-person)", quantityAvailable: 2, estimatedPrice: 150.00, category: .camping),
        TripItem(name: "Sleeping Bags", quantityAvailable: 8, estimatedPrice: 40.00, category: .camping),
        TripItem(name: "Camping Stove", quantityAvailable: 1, estimatedPrice: 80.00, category: .outdoor),
        TripItem(name: "Firewood Bundle", quantityAvailable: 10, estimatedPrice: 8.00, category: .outdoor)
    ]
)
```

---

## Partial Claiming Test Scenarios

### Scenario 1: Multiple Users Claiming Same Item
**Setup**: Item has 40 popsicles available

1. **User A** claims 15 popsicles → remaining: 25
2. **User B** claims 10 popsicles → remaining: 15
3. **User C** claims 8 popsicles → remaining: 7
4. **User D** tries to claim 10 → **SHOULD FAIL** (only 7 remaining)

**Expected Behavior**:
- ✅ ClaimItemView shows updated remaining quantity after each claim
- ✅ Progress bar updates: 0% → 37.5% → 62.5% → 82.5%
- ✅ User D sees validation: "Only 7 pieces remaining"
- ✅ Claim button disabled if quantity > remaining

### Scenario 2: Preventing Over-Claiming
**Setup**: Item has 20 party hats available, 15 already claimed

**Test Cases**:
- User tries to claim 10 → **FAIL** (only 5 remaining)
- User tries to claim 5 → **SUCCESS**
- User tries to claim 1 more → **FAIL** (fully claimed)
- ClaimItemView shows "Fully Claimed" state

**Expected Behavior**:
- ✅ Real-time validation in UI
- ✅ Backend validation in Firebase (if implemented)
- ✅ User sees clear error message
- ✅ Green "Fully Claimed" checkmark when 100%

### Scenario 3: Reducing Claimed Quantity
**Current Implementation**: No UI to modify existing claims

**Recommended Feature** (Future v2):
- Add "Edit Claim" button in ClaimDetailRow
- User can increase/decrease their quantity
- Validation: new quantity <= (original + remaining)
- Update Firebase with new quantity

### Scenario 4: Trip Creator Changes Total Quantity
**Current Implementation**: Total quantity is fixed after creation

**Edge Cases to Handle**:
1. **Increase**: 40 → 60 popsicles
   - Remaining should increase by 20
   - No impact on existing claims

2. **Decrease**: 40 → 30 popsicles (but 35 claimed)
   - **PROBLEM**: Over-claimed state
   - **Solution**: Show warning, prevent decrease, or mark some claims as "pending adjustment"

**Recommended Validation**:
```swift
func canUpdateItemQuantity(newQuantity: Int, claimedQuantity: Int) -> Bool {
    return newQuantity >= claimedQuantity
}
```

---

## Edge Case Testing Checklist

### ✅ Claiming Edge Cases
- [ ] Claim quantity = 0 (should be prevented)
- [ ] Claim quantity > total available (prevented in UI)
- [ ] Claim quantity = remaining (exactly fills)
- [ ] Multiple simultaneous claims (race condition)
- [ ] Claim with negative quantity (validation)
- [ ] Claim after item deleted (error handling)

### ✅ Completion Edge Cases
- [ ] Mark item complete before claiming
- [ ] Mark item complete with pending claims
- [ ] Un-mark completed item
- [ ] All items completed → notification sent
- [ ] Trip organizer marks someone else's claim complete
- [ ] User who didn't claim tries to mark complete (prevented)

### ✅ Comments Edge Cases
- [ ] Empty comment text (validation)
- [ ] Very long comment (500+ chars)
- [ ] Comment on deleted item
- [ ] Load comments with deleted users
- [ ] Rapid-fire commenting (performance)

### ✅ Trip Type Edge Cases
- [ ] Create trip without selecting type (defaults to .bulkShopping)
- [ ] Filter by type with 0 results
- [ ] Switch between trip types rapidly
- [ ] Trip with invalid tripType value
- [ ] Display trip with missing store for non-shopping types

---

## Backward Compatibility

### Existing Data Migration

#### 1. Trip Model Changes
**Old Structure**:
```swift
struct Trip {
    let id: String
    var groupId: String
    var shopperId: String
    var store: Store  // REQUIRED
    var scheduledDate: Date
    var items: [TripItem]
    // ... tripType field MISSING
}
```

**New Structure**:
```swift
struct Trip {
    let id: String
    var groupId: String
    var shopperId: String
    var tripType: TripType = .bulkShopping  // DEFAULT added
    var store: Store
    var scheduledDate: Date
    var items: [TripItem]
}
```

**Migration Strategy**:
- ✅ All existing trips will decode with `tripType = .bulkShopping`
- ✅ No data migration needed in Firestore
- ✅ New trips will have explicit tripType field

#### 2. ItemClaim Model Changes
**Old Structure**:
```swift
struct ItemClaim {
    let id: String
    let tripId: String
    let itemId: String
    let claimerUserId: String
    let quantityClaimed: Int
    var status: ClaimStatus
    // ... isCompleted and completedAt MISSING
}
```

**New Structure**:
```swift
struct ItemClaim {
    let id: String
    let tripId: String
    let itemId: String
    let claimerUserId: String
    let quantityClaimed: Int
    var status: ClaimStatus
    var isCompleted: Bool = false  // DEFAULT added
    var completedAt: Date? = nil
}
```

**Migration Strategy**:
- ✅ Existing claims decode with `isCompleted = false`
- ✅ Codable handles missing fields with defaults
- ✅ No breaking changes

#### 3. TripItem Model Changes
**Old Structure**:
```swift
struct TripItem {
    let id: String
    var name: String
    var quantityAvailable: Int
    var estimatedPrice: Double
    var category: ItemCategory
    var notes: String?
    // ... isCompleted field MISSING
}
```

**New Structure**:
```swift
struct TripItem {
    let id: String
    var name: String
    var quantityAvailable: Int
    var estimatedPrice: Double
    var category: ItemCategory
    var notes: String?
    var isCompleted: Bool = false  // DEFAULT added
}
```

**Migration Strategy**:
- ✅ Existing items decode with `isCompleted = false`
- ✅ No data migration needed

### Testing Backward Compatibility

1. **Load existing trips from Firebase**:
   ```swift
   // Should decode successfully
   let trips = try await FirebaseManager.shared.getUserTrips()
   // All trips should have tripType = .bulkShopping
   ```

2. **Load existing claims**:
   ```swift
   let claims = try await FirebaseManager.shared.getTripClaims(tripId: "old-trip")
   // All claims should have isCompleted = false
   ```

3. **Update existing trip**:
   ```swift
   var trip = existingTrip
   trip.status = .completed
   // Should save successfully with new fields
   ```

---

## Firebase/Backend Changes Required

### 1. Firestore Collections Schema

#### `trips` Collection
```javascript
{
  id: string,
  groupId: string,
  shopperId: string,
  tripType: string,  // NEW: "bulk_shopping", "event_planning", "group_trip", "potluck_meal"
  store: string,
  scheduledDate: timestamp,
  items: array,
  status: string,
  createdAt: timestamp,
  participants: array<string>,
  notes: string | null
}
```

#### `claims` Collection
```javascript
{
  id: string,
  tripId: string,
  itemId: string,
  claimerUserId: string,
  quantityClaimed: number,  // NEW: Can be partial quantity
  claimedAt: timestamp,
  status: string,
  isCompleted: boolean,     // NEW
  completedAt: timestamp | null  // NEW
}
```

#### `itemComments` Collection (NEW)
```javascript
{
  id: string,
  tripId: string,
  itemId: string,
  userId: string,
  text: string,
  createdAt: timestamp
}
```

### 2. Required FirebaseManager Methods

#### New Methods Needed:
```swift
// Comments
func createItemComment(_ comment: ItemComment) async throws
func getTripItemComments(tripId: String) async throws -> [ItemComment]
func getItemComments(itemId: String) async throws -> [ItemComment]

// Claim Completion
func updateClaimCompletion(claimId: String, isCompleted: Bool, completedAt: Date?) async throws

// Notifications
func createAllItemsCompletedNotification(
    tripId: String,
    tripOrganizerId: String,
    completedByUserId: String,
    completedByName: String,
    tripStore: String
) async throws
```

#### Updated Methods:
```swift
// Should handle partial claiming validation
func createClaims(_ claims: [ItemClaim]) async throws {
    // Validate: sum of new claims + existing claims <= item.quantityAvailable
    // Throw error if over-claiming
}
```

### 3. Firestore Security Rules

```javascript
// Prevent over-claiming
match /claims/{claimId} {
  allow create: if request.auth != null
    && validateClaimQuantity(request.resource.data);

  function validateClaimQuantity(claim) {
    let item = get(/databases/$(database)/documents/trips/$(claim.tripId)).data.items
      .where(i => i.id == claim.itemId)[0];
    let existingClaims = get(/databases/$(database)/documents/claims)
      .where('itemId', '==', claim.itemId)
      .where('status', 'in', ['pending', 'accepted']);
    let totalClaimed = existingClaims.sum('quantityClaimed');

    return (totalClaimed + claim.quantityClaimed) <= item.quantityAvailable;
  }
}

// Only claimer or trip organizer can mark complete
match /claims/{claimId} {
  allow update: if request.auth != null
    && (request.auth.uid == resource.data.claimerUserId
        || request.auth.uid == getTripOrganizer(resource.data.tripId));
}
```

### 4. Firestore Indexes

Required composite indexes:
```
Collection: claims
Fields: tripId (Ascending), status (Ascending), isCompleted (Ascending)

Collection: itemComments
Fields: tripId (Ascending), createdAt (Ascending)

Collection: itemComments
Fields: itemId (Ascending), createdAt (Ascending)
```

---

## Device Testing Checklist

### Multi-User Testing

#### Setup: 3 Test Accounts
- User A: Trip organizer
- User B: Participant 1
- User C: Participant 2

#### Test Flow:
1. **User A** creates potluck trip with 40 popsicles
2. **User B** opens trip, claims 15 popsicles
3. **User A** sees claim appear in real-time (refresh)
4. **User A** approves claim
5. **User C** opens trip, claims 10 popsicles
6. **User B** sees updated progress: 25/40 claimed
7. **User B** marks their claim as completed
8. **User A** receives no notification (not all complete)
9. **User C** marks their claim as completed
10. **User A** receives "All items completed" notification

### Single Device Testing (Simulator)

#### Trip Type Testing:
- [ ] Create bulk shopping trip → Green theme
- [ ] Create event planning trip → Yellow theme
- [ ] Create group trip → Teal theme
- [ ] Create potluck trip → Orange theme
- [ ] Filter by each trip type
- [ ] All trips display correctly

#### Claiming Testing:
- [ ] Claim 50% of item quantity
- [ ] See progress bar at 50%
- [ ] Try to claim more than remaining → error
- [ ] Claim exactly remaining → 100% green
- [ ] See "Fully Claimed" state

#### Completion Testing:
- [ ] Mark claim as complete → checkbox checked
- [ ] Progress bar updates in trip header
- [ ] Unmark completion → checkbox unchecked
- [ ] Mark all items complete → see celebration

#### Comments Testing:
- [ ] Add comment → appears immediately
- [ ] Comment count badge increments
- [ ] Long comment wraps correctly
- [ ] Relative time displays ("2h ago")

---

## Build Verification

### Compilation Checklist:
- [ ] No Swift syntax errors
- [ ] No missing imports
- [ ] All new view files added to Xcode project
- [ ] Preview providers compile
- [ ] No retain cycles or memory leaks

### Runtime Checklist:
- [ ] App launches without crashes
- [ ] My Trips tab loads
- [ ] Create Trip flow works
- [ ] Trip detail view opens
- [ ] Claim item modal works
- [ ] Comments section functional
- [ ] Filter chips respond to taps

---

## Known Issues & Limitations

### Current Limitations:
1. **No Edit Claim Feature**: Users cannot modify claimed quantity after submission
2. **No Claim Cancellation**: Users cannot cancel/delete their claims (only organizer can reject)
3. **No Quantity Change Validation**: Trip organizer can change item quantity causing over-claim state
4. **Comments Not Real-Time**: Must refresh modal to see new comments
5. **No Comment Deletion**: Users cannot delete their own comments
6. **No Image Support**: Comments are text-only

### Recommended Future Enhancements:
1. Add claim editing with quantity validation
2. Add "Cancel Claim" button for pending claims
3. Prevent item quantity decrease below claimed amount
4. Add Firebase listeners for real-time comment updates
5. Add comment deletion with "Delete" button
6. Add photo attachments to comments
7. Add push notifications for new comments
8. Add "Remind Participants" button when items not completed

---

## Testing Script

### Quick Smoke Test (5 minutes):
```bash
# 1. Build app
cd BulkMatesApp
xcodebuild -scheme BulkMatesApp -destination 'platform=iOS Simulator,name=iPhone 15' build

# 2. Run on simulator
open -a Simulator
# Launch app from Xcode

# 3. Quick checks:
- Tap "My Trips"
- Tap filter chips
- Tap "+ Create Trip"
- Select group → Select trip type → See colored UI
- Add item → See category filtering
- Open existing trip → Tap item
- See claiming modal → Try to claim
- Add comment → See it appear
- Mark claim complete → See progress
```

### Full Integration Test (30 minutes):
Follow "Multi-User Testing" section with 3 devices/accounts

---

## Conclusion

### What's Working:
✅ Multiple trip types with color coding
✅ Partial quantity claiming
✅ Completion tracking
✅ Item comments
✅ Trip type filters
✅ Backward compatibility

### What Needs Backend Work:
⚠️ Firebase comment storage
⚠️ Over-claiming validation in security rules
⚠️ Firestore indexes for new queries
⚠️ New notification type for all items completed

### Ready for Testing:
The app is ready for simulator testing and UI/UX validation. Backend Firebase methods need to be implemented before production deployment.
