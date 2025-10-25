# Firebase Backend Implementation Guide

This document outlines all Firebase backend methods and schema changes required to support the new multi-trip-type features in BulkMates.

## Overview of Changes

The following new features require backend implementation:
1. **Trip Types** - Support for 4 different trip types beyond bulk shopping
2. **Partial Claiming** - Multiple users claiming portions of the same item
3. **Completion Tracking** - Mark claimed items as purchased/prepared
4. **Item Comments** - Group coordination through item-level comments

---

## 1. Firestore Schema Changes

### Collection: `trips`

**New/Updated Fields:**
```swift
{
  "id": String,
  "groupId": String,
  "shopperId": String,
  "tripType": String,           // NEW: "bulk_shopping", "event_planning", "group_trip", "potluck_meal"
  "store": String,
  "scheduledDate": Timestamp,
  "status": String,
  "createdAt": Timestamp,
  "participants": [String],
  "notes": String?,
  "items": [{                   // Array of TripItem objects
    "id": String,
    "name": String,
    "quantityAvailable": Int,   // Total quantity needed
    "estimatedPrice": Double,
    "category": String,
    "notes": String?,
    "isCompleted": Bool         // NEW: Track item completion
  }]
}
```

**Migration Notes:**
- Existing trips without `tripType` field will default to "bulk_shopping" when loaded
- Existing items without `isCompleted` field will default to `false`
- No data migration required due to Codable default values

### Collection: `item_claims`

**New/Updated Fields:**
```swift
{
  "id": String,
  "tripId": String,
  "itemId": String,
  "claimerUserId": String,
  "quantityClaimed": Int,
  "claimedAt": Timestamp,
  "status": String,             // "pending", "accepted", "rejected", "cancelled"
  "isCompleted": Bool,          // NEW: Whether claimer marked as complete
  "completedAt": Timestamp?     // NEW: When marked complete
}
```

**Indexes Required:**
```
Collection: item_claims
- Composite: tripId (Ascending), itemId (Ascending)
- Composite: tripId (Ascending), claimerUserId (Ascending)
- Composite: tripId (Ascending), status (Ascending)
```

### Collection: `item_comments` (NEW)

**Schema:**
```swift
{
  "id": String,
  "tripId": String,
  "itemId": String,
  "userId": String,
  "text": String,
  "createdAt": Timestamp
}
```

**Indexes Required:**
```
Collection: item_comments
- Composite: tripId (Ascending), itemId (Ascending), createdAt (Descending)
```

---

## 2. FirebaseManager.swift Methods

### A. Trip Type Support

**No changes required** - The existing trip creation and fetching methods already support the new `tripType` field through Codable. Just ensure trips are saved with the field:

```swift
// Existing method should handle this automatically
func createTrip(_ trip: Trip) async throws {
    let tripData = try Firestore.Encoder().encode(trip)
    try await db.collection("trips").document(trip.id).setData(tripData)
}
```

### B. Comments Methods (NEW)

Add these methods to `FirebaseManager.swift`:

```swift
// MARK: - Item Comments

/// Create a new comment on a trip item
func createItemComment(_ comment: ItemComment) async throws {
    let commentData = try Firestore.Encoder().encode(comment)
    try await db.collection("item_comments")
        .document(comment.id)
        .setData(commentData)
}

/// Get all comments for a specific item in a trip
func getTripItemComments(tripId: String, itemId: String) async throws -> [ItemComment] {
    let snapshot = try await db.collection("item_comments")
        .whereField("tripId", isEqualTo: tripId)
        .whereField("itemId", isEqualTo: itemId)
        .order(by: "createdAt", descending: false)
        .getDocuments()

    return try snapshot.documents.compactMap { document in
        try document.data(as: ItemComment.self)
    }
}

/// Get all comments for all items in a trip (for preloading)
func getAllTripComments(tripId: String) async throws -> [ItemComment] {
    let snapshot = try await db.collection("item_comments")
        .whereField("tripId", isEqualTo: tripId)
        .order(by: "createdAt", descending: false)
        .getDocuments()

    return try snapshot.documents.compactMap { document in
        try document.data(as: ItemComment.self)
    }
}

/// Listen to real-time comment updates for an item
func listenToItemComments(tripId: String, itemId: String,
                          completion: @escaping ([ItemComment]) -> Void) -> ListenerRegistration {
    return db.collection("item_comments")
        .whereField("tripId", isEqualTo: tripId)
        .whereField("itemId", isEqualTo: itemId)
        .order(by: "createdAt", descending: false)
        .addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }

            let comments = documents.compactMap { document in
                try? document.data(as: ItemComment.self)
            }
            completion(comments)
        }
}

/// Delete a comment (for future use)
func deleteItemComment(commentId: String) async throws {
    try await db.collection("item_comments")
        .document(commentId)
        .delete()
}
```

### C. Completion Tracking Methods

Add these methods to `FirebaseManager.swift`:

```swift
// MARK: - Claim Completion Tracking

/// Update completion status for a claim
func updateClaimCompletion(claimId: String, isCompleted: Bool) async throws {
    let updateData: [String: Any] = [
        "isCompleted": isCompleted,
        "completedAt": isCompleted ? Timestamp(date: Date()) : FieldValue.delete()
    ]

    try await db.collection("item_claims")
        .document(claimId)
        .updateData(updateData)
}

/// Get completion statistics for a trip
func getTripCompletionStats(tripId: String) async throws -> (completed: Int, total: Int) {
    let snapshot = try await db.collection("item_claims")
        .whereField("tripId", isEqualTo: tripId)
        .whereField("status", isEqualTo: "accepted")
        .getDocuments()

    let claims = try snapshot.documents.compactMap { document in
        try document.data(as: ItemClaim.self)
    }

    let completed = claims.filter { $0.isCompleted }.count
    return (completed, claims.count)
}

/// Check if all items in a trip are completed
func areAllItemsCompleted(tripId: String) async throws -> Bool {
    let stats = try await getTripCompletionStats(tripId: tripId)
    return stats.total > 0 && stats.completed == stats.total
}
```

### D. Claim Validation Methods

Add these methods to prevent over-claiming:

```swift
// MARK: - Claim Validation

/// Get total claimed quantity for an item
func getTotalClaimedQuantity(tripId: String, itemId: String) async throws -> Int {
    let snapshot = try await db.collection("item_claims")
        .whereField("tripId", isEqualTo: tripId)
        .whereField("itemId", isEqualTo: itemId)
        .getDocuments()

    let claims = try snapshot.documents.compactMap { document in
        try document.data(as: ItemClaim.self)
    }

    // Sum only accepted and pending claims (not rejected or cancelled)
    return claims
        .filter { $0.status != .rejected && $0.status != .cancelled }
        .reduce(0) { $0 + $1.quantityClaimed }
}

/// Validate if a claim would exceed available quantity
func validateClaimQuantity(tripId: String, itemId: String,
                          requestedQuantity: Int, trip: Trip) async throws -> (isValid: Bool, reason: String?) {
    // Find the item in the trip
    guard let item = trip.items.first(where: { $0.id == itemId }) else {
        return (false, "Item not found in trip")
    }

    // Get current claimed quantity
    let currentClaimed = try await getTotalClaimedQuantity(tripId: tripId, itemId: itemId)

    // Check if requested quantity would exceed available
    let remainingQuantity = item.quantityAvailable - currentClaimed

    if requestedQuantity > remainingQuantity {
        return (false, "Only \(remainingQuantity) remaining")
    }

    if requestedQuantity <= 0 {
        return (false, "Quantity must be greater than 0")
    }

    return (true, nil)
}

/// Create a claim with validation
func createValidatedClaim(_ claim: ItemClaim, trip: Trip) async throws {
    // Validate quantity
    let validation = try await validateClaimQuantity(
        tripId: claim.tripId,
        itemId: claim.itemId,
        requestedQuantity: claim.quantityClaimed,
        trip: trip
    )

    guard validation.isValid else {
        throw NSError(domain: "BulkMates", code: 400,
                     userInfo: [NSLocalizedDescriptionKey: validation.reason ?? "Invalid claim"])
    }

    // Create the claim
    let claimData = try Firestore.Encoder().encode(claim)
    try await db.collection("item_claims")
        .document(claim.id)
        .setData(claimData)
}
```

### E. Notification Methods

Add/update notification methods for completion tracking:

```swift
// MARK: - Completion Notifications

/// Send notification when all trip items are completed
func sendAllItemsCompletedNotification(tripId: String, tripShopperId: String,
                                       groupId: String) async throws {
    let notification = Notification(
        id: UUID().uuidString,
        userId: tripShopperId,
        type: .tripCompleted,
        title: "Trip Completed! 🎉",
        message: "All items for your trip have been marked as ready!",
        relatedId: tripId,
        groupId: groupId,
        createdAt: Date(),
        isRead: false
    )

    try await createNotification(notification)
}

/// Send notification when someone marks an item as complete
func sendItemCompletedNotification(itemName: String, claimerName: String,
                                  tripId: String, tripShopperId: String,
                                  groupId: String) async throws {
    let notification = Notification(
        id: UUID().uuidString,
        userId: tripShopperId,
        type: .itemUpdated,
        title: "Item Ready ✓",
        message: "\(claimerName) marked \(itemName) as ready",
        relatedId: tripId,
        groupId: groupId,
        createdAt: Date(),
        isRead: false
    )

    try await createNotification(notification)
}
```

---

## 3. Firestore Security Rules

Update `firestore.rules` to support new features:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }

    function getUserId() {
      return request.auth.uid;
    }

    // Trips collection
    match /trips/{tripId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn();
      allow update: if isSignedIn();
      allow delete: if isSignedIn() &&
                      resource.data.shopperId == getUserId();
    }

    // Item claims collection
    match /item_claims/{claimId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn() &&
                      request.resource.data.claimerUserId == getUserId();

      // Allow updates for completion tracking
      allow update: if isSignedIn() && (
        // Claimer can update their own claims
        resource.data.claimerUserId == getUserId() ||
        // Trip creator can update claim status
        get(/databases/$(database)/documents/trips/$(resource.data.tripId)).data.shopperId == getUserId()
      );

      allow delete: if isSignedIn() &&
                      resource.data.claimerUserId == getUserId();
    }

    // Item comments collection (NEW)
    match /item_comments/{commentId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn() &&
                      request.resource.data.userId == getUserId();
      allow update: if false; // Comments are immutable
      allow delete: if isSignedIn() &&
                      resource.data.userId == getUserId();
    }

    // Prevent over-claiming (validation rule)
    match /item_claims/{claimId} {
      allow create: if isSignedIn() &&
                      request.resource.data.claimerUserId == getUserId() &&
                      validateClaimQuantity(
                        request.resource.data.tripId,
                        request.resource.data.itemId,
                        request.resource.data.quantityClaimed
                      );
    }
  }

  // Validation function for claims (requires Firestore Functions)
  function validateClaimQuantity(tripId, itemId, requestedQty) {
    let trip = get(/databases/$(database)/documents/trips/$(tripId));
    let item = trip.data.items.filter(i => i.id == itemId)[0];
    let existingClaims = firestore.get(
      /databases/$(database)/documents/item_claims
    ).where('tripId', '==', tripId)
     .where('itemId', '==', itemId);

    let totalClaimed = existingClaims.data.sum('quantityClaimed');
    let remaining = item.quantityAvailable - totalClaimed;

    return requestedQty <= remaining && requestedQty > 0;
  }
}
```

**Note**: The `validateClaimQuantity` function in Firestore rules is complex and may require a Cloud Function for proper validation. Consider implementing server-side validation through Cloud Functions.

---

## 4. Cloud Functions (Optional but Recommended)

### Function: Validate Claims

Create a Cloud Function to validate claims before they're written:

```typescript
// functions/src/index.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

export const validateClaim = functions.firestore
  .document('item_claims/{claimId}')
  .onWrite(async (change, context) => {
    // Only validate new claims
    if (!change.after.exists) return;

    const claim = change.after.data();
    const tripRef = db.collection('trips').doc(claim.tripId);
    const tripDoc = await tripRef.get();

    if (!tripDoc.exists) {
      throw new Error('Trip not found');
    }

    const trip = tripDoc.data();
    const item = trip.items.find((i: any) => i.id === claim.itemId);

    if (!item) {
      throw new Error('Item not found');
    }

    // Get all claims for this item
    const claimsSnapshot = await db.collection('item_claims')
      .where('tripId', '==', claim.tripId)
      .where('itemId', '==', claim.itemId)
      .where('status', 'in', ['pending', 'accepted'])
      .get();

    const totalClaimed = claimsSnapshot.docs
      .reduce((sum, doc) => sum + doc.data().quantityClaimed, 0);

    // If over-claimed, reject the claim
    if (totalClaimed > item.quantityAvailable) {
      await change.after.ref.update({
        status: 'rejected',
        rejectionReason: 'Quantity exceeded'
      });
    }
  });

export const notifyAllItemsCompleted = functions.firestore
  .document('item_claims/{claimId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();

    // Check if claim was just marked as completed
    if (newData.isCompleted && !oldData.isCompleted) {
      const tripId = newData.tripId;

      // Get all claims for this trip
      const claimsSnapshot = await db.collection('item_claims')
        .where('tripId', '==', tripId)
        .where('status', '==', 'accepted')
        .get();

      // Check if all are completed
      const allCompleted = claimsSnapshot.docs.every(
        doc => doc.data().isCompleted === true
      );

      if (allCompleted && claimsSnapshot.size > 0) {
        // Get trip details
        const tripDoc = await db.collection('trips').doc(tripId).get();
        const trip = tripDoc.data();

        // Create notification
        await db.collection('notifications').add({
          userId: trip.shopperId,
          type: 'trip_completed',
          title: 'Trip Completed! 🎉',
          message: 'All items for your trip have been marked as ready!',
          relatedId: tripId,
          groupId: trip.groupId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false
        });
      }
    }
  });
```

---

## 5. Implementation Checklist

Use this checklist when implementing the backend changes:

### Phase 1: Data Model Updates
- [ ] Verify Trip model includes `tripType` field with default value
- [ ] Verify TripItem model includes `isCompleted` field with default value
- [ ] Verify ItemClaim model includes `isCompleted` and `completedAt` fields
- [ ] Create ItemComment model if not exists
- [ ] Test Codable encoding/decoding for all models

### Phase 2: Firebase Methods
- [ ] Add `createItemComment` method
- [ ] Add `getTripItemComments` method
- [ ] Add `getAllTripComments` method
- [ ] Add `listenToItemComments` method (optional)
- [ ] Add `updateClaimCompletion` method
- [ ] Add `getTripCompletionStats` method
- [ ] Add `areAllItemsCompleted` method
- [ ] Add `getTotalClaimedQuantity` method
- [ ] Add `validateClaimQuantity` method
- [ ] Add `createValidatedClaim` method
- [ ] Update notification methods for completion tracking

### Phase 3: Firestore Configuration
- [ ] Create `item_comments` collection in Firestore console
- [ ] Add composite index: `item_comments` → tripId (Asc), itemId (Asc), createdAt (Desc)
- [ ] Add composite index: `item_claims` → tripId (Asc), itemId (Asc)
- [ ] Add composite index: `item_claims` → tripId (Asc), claimerUserId (Asc)
- [ ] Add composite index: `item_claims` → tripId (Asc), status (Asc)
- [ ] Update Firestore security rules with new rules for item_comments
- [ ] Test security rules in Firestore emulator

### Phase 4: Cloud Functions (Optional)
- [ ] Set up Firebase Cloud Functions project
- [ ] Implement `validateClaim` function
- [ ] Implement `notifyAllItemsCompleted` function
- [ ] Deploy functions to Firebase
- [ ] Test functions with test data

### Phase 5: Testing
- [ ] Test creating trips with different tripType values
- [ ] Test creating and fetching comments
- [ ] Test marking claims as completed
- [ ] Test completion notifications
- [ ] Test claim validation (prevent over-claiming)
- [ ] Test with multiple users simultaneously
- [ ] Verify backward compatibility with existing data

---

## 6. Migration Strategy

### For Existing Production Data

If you have existing trips in production:

1. **No migration required** for basic tripType support
   - Codable will use default value "bulk_shopping"
   - App will handle gracefully

2. **Optional: Backfill tripType** for cleaner data
   ```swift
   // Run once to update existing trips
   func backfillTripTypes() async throws {
       let snapshot = try await db.collection("trips").getDocuments()

       for document in snapshot.documents {
           try await document.reference.updateData([
               "tripType": "bulk_shopping"
           ])
       }
   }
   ```

3. **Optional: Backfill isCompleted** for items
   ```swift
   // Run once to add isCompleted to existing items
   func backfillItemCompletion() async throws {
       let snapshot = try await db.collection("trips").getDocuments()

       for document in snapshot.documents {
           var trip = try document.data(as: Trip.self)

           // Update all items with isCompleted = false
           trip.items = trip.items.map { item in
               var updatedItem = item
               updatedItem.isCompleted = false
               return updatedItem
           }

           let tripData = try Firestore.Encoder().encode(trip)
           try await document.reference.setData(tripData)
       }
   }
   ```

---

## 7. Performance Considerations

### Indexes
Firestore will prompt you to create indexes when you first run queries. Watch for these in the console and create them.

### Batch Reads
When loading trip details, consider batching:
```swift
// Instead of loading comments one-by-one
let comments = try await getAllTripComments(tripId: tripId)

// Then group in memory
let commentsByItem = Dictionary(grouping: comments, by: { $0.itemId })
```

### Real-time Listeners
Use listeners sparingly to avoid excessive reads:
```swift
// Only listen to comments when ClaimItemView is open
// Cancel listener when view closes
```

---

## 8. Testing with Firebase Emulator

Use the Firebase Local Emulator Suite for testing:

```bash
# Install Firebase tools
npm install -g firebase-tools

# Initialize emulators
firebase init emulators

# Select: Firestore, Functions, Auth

# Start emulators
firebase emulators:start
```

Update FirebaseManager to use emulator in debug mode:
```swift
#if DEBUG
if ProcessInfo.processInfo.environment["USE_FIREBASE_EMULATOR"] == "true" {
    let settings = Firestore.firestore().settings
    settings.host = "localhost:8080"
    settings.isSSLEnabled = false
    Firestore.firestore().settings = settings
}
#endif
```

---

## Summary

This implementation adds comprehensive backend support for:
- Multiple trip types
- Partial quantity claiming with validation
- Item completion tracking with notifications
- Group coordination through comments

All changes maintain backward compatibility with existing data through Codable defaults.
