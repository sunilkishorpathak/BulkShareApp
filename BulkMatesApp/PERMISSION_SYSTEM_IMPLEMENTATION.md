# Permission System Implementation Guide

**Date**: October 24, 2025
**Status**: ✅ Core Implementation Complete | ⏸️ Integration Pending

---

## Overview

This document outlines the implementation of a two-role permission system for BulkMates iOS app. The system provides **Admin** and **Viewer** roles with different capabilities.

---

## What Has Been Implemented

### 1. Data Model Updates ✅

**File**: `Models/Trip.swift`

#### Added Properties to Trip Model:
```swift
var creatorId: String // User who created the trip
var adminIds: [String] // Users with admin access
var viewerIds: [String] // Users with viewer access
```

#### Created TripRole Enum:
```swift
enum TripRole: String, Codable, CaseIterable {
    case admin = "Admin"
    case viewer = "Viewer"
    case notMember = "Not a member"

    var icon: String // 🔧 for admin, 👁️ for viewer
    var displayName: String
    var description: String
    var accentColor: Color
}
```

#### Added Permission Helper Methods to Trip:
- `userRole(userId:) -> TripRole` - Get user's role
- `canEditList(userId:) -> Bool` - Check if user can edit
- `isCreator(userId:) -> Bool` - Check if user is creator
- `isLastAdmin(userId:) -> Bool` - Check if user is last admin
- `promoteToAdmin(userId:)` - Promote user to admin
- `demoteToViewer(userId:)` - Demote user to viewer
- `adminUserIds` - Get all admin IDs
- `viewerUserIds` - Get all viewer IDs
- `totalMemberCount` - Get total members (admins + viewers)

**Backward Compatibility**: All new properties have default values ("", [], []) so existing trips will load without errors.

### 2. Role Management UI ✅

**File**: `Views/Trips/TripMembersView.swift`

Complete role management interface with:

#### Features:
- **Header Card**: Shows trip info and role summary
- **Role Sections**: Separate sections for Admins and Viewers
- **Member Rows**: Display user info with role badges
- **Role Toggle Buttons**:
  - Admins: "⬇️ Viewer" button (orange)
  - Viewers: "⬆️ Admin" button (blue)
- **Creator Badge**: Shows "Trip Creator" label under creator's name
- **Empty States**: Friendly messages when no members in a role

#### Safety Features:
- **Last Admin Protection**: Cannot demote last admin
  - Shows alert: "Cannot Remove Last Admin"
  - Message: "This trip must have at least one Admin. Promote someone else to Admin first."

- **Self-Demotion Warning**: Warns when demoting yourself
  - Alert: "Demote Yourself?"
  - Message: "You won't be able to edit the list anymore. Continue?"

- **Demote Confirmation**: Confirms when demoting another admin
  - Alert: "Remove Admin Access?"
  - Message: "User will no longer be able to edit the list. They can still claim items and comment."

#### Components Created:
- `TripMembersView` - Main view
- `TripMembersHeaderCard` - Trip info header
- `RoleSummaryBadge` - Role count badges
- `MembersRoleSection` - Role-grouped member list
- `EmptyRoleSectionCard` - Empty state for roles
- `MemberRoleRow` - Individual member row
- `RoleToggleButton` - Role change button

### 3. TripDetailView Updates ✅

**File**: `Views/Trips/TripDetailView.swift`

#### Added:
- `showingMembersView` state variable
- `currentUserId` computed property
- `currentUserRole` computed property
- `canEditList` computed property
- Members button in toolbar (shows member count)
- Sheet presentation for TripMembersView

#### Toolbar Button:
```swift
// Shows for admins only
Button with person.2.fill icon + member count
Opens TripMembersView when tapped
```

---

## What Still Needs to be Done

### 1. Update CreateTripView ⏸️ **HIGH PRIORITY**

**File**: `Views/Trips/CreateTripView.swift`

When creating a trip, set role properties:

```swift
// In trip creation function
let currentUserId = FirebaseManager.shared.currentUser?.id ?? ""

let newTrip = Trip(
    groupId: group.id,
    shopperId: currentUserId,
    tripType: selectedTripType,
    store: selectedStore,
    scheduledDate: scheduledDate,
    items: [],
    creatorId: currentUserId,           // NEW: Set creator
    adminIds: [currentUserId],          // NEW: Creator starts as admin
    viewerIds: []                       // NEW: Empty initially
)
```

### 2. Add Permission Checks to Item Operations ⏸️ **HIGH PRIORITY**

#### A. Add Item Button

**File**: `Views/Trips/TripDetailView.swift` or wherever "Add Item" button is

Current behavior: Anyone can add items
New behavior: Only admins can add items

```swift
// Add Item Button
Button(action: { showingAddItem = true }) {
    HStack {
        Image(systemName: canEditList ? "plus.circle.fill" : "lock.fill")
        Text("Add Item")
    }
}
.disabled(!canEditList)
.opacity(canEditList ? 1.0 : 0.5)
.onTapGesture {
    if !canEditList {
        // Show toast/alert
        showPermissionDeniedAlert = true
    }
}
```

Alert message:
```
"Only Admins Can Add Items"
"Ask an Admin to promote you or to add this item for you."
```

#### B. Edit Item Button

**Files**: `Views/Trips/AddTripItemView.swift` or item detail views

Wrap edit functionality:
```swift
if canEditList {
    // Show Edit button
    Button("Edit") { ... }
} else {
    // Hide Edit button or show disabled state
}
```

#### C. Delete Item Button

Same as edit - only show for admins:
```swift
if canEditList {
    Button("Delete", role: .destructive) { ... }
}
```

### 3. Update Trip Join Flow ⏸️ **MEDIUM PRIORITY**

**Files**: Views where users join trips

When user joins a trip:
```swift
func handleJoinTrip() {
    let userId = FirebaseManager.shared.currentUser?.id ?? ""

    // Add user to trip
    trip.participants.append(userId)

    // NEW: Add user as viewer by default
    trip.viewerIds.append(userId)

    // Save to Firebase
    try await FirebaseManager.shared.updateTrip(trip)

    // Optional: Show welcome message
    showWelcomeToast = true
}
```

Welcome message:
```
"You've joined as a Viewer"
"Admins can promote you to edit the trip list"
```

### 4. Add Role Selection to Invitation Flow ⏸️ **MEDIUM PRIORITY**

**File**: `Views/Groups/InviteMembersView.swift` or invitation views

Add role picker when inviting:

```swift
@State private var inviteeRole: TripRole = .viewer

// In invitation form
VStack(alignment: .leading) {
    Text("Invite as:")
        .font(.subheadline)
        .fontWeight(.medium)

    Picker("Role", selection: $inviteeRole) {
        ForEach([TripRole.viewer, TripRole.admin], id: \.self) { role in
            HStack {
                Text(role.icon)
                Text(role.displayName)
            }
            .tag(role)
        }
    }
    .pickerStyle(SegmentedPickerStyle())

    Text(inviteeRole.description)
        .font(.caption)
        .foregroundColor(.bulkShareTextMedium)
}
```

When sending invitation:
```swift
// Add invited user with selected role
if inviteeRole == .admin {
    trip.adminIds.append(invitedUserId)
} else {
    trip.viewerIds.append(invitedUserId)
}
```

### 5. Update Sample Data ⏸️ **LOW PRIORITY**

**File**: `Models/Trip.swift` - Sample data section

Update `Trip.sampleTrips` to include role properties:

```swift
static let sampleTrips: [Trip] = [
    Trip(
        groupId: "group1",
        shopperId: "user2",
        tripType: .bulkShopping,
        store: .costco,
        scheduledDate: ...,
        items: [...],
        creatorId: "user2",                    // NEW
        adminIds: ["user2", "user3"],          // NEW
        viewerIds: ["user1", "user4"]          // NEW
    ),
    // ... update other sample trips
]
```

### 6. Firebase Backend Implementation ⏸️ **HIGH PRIORITY**

**File**: `Services/FirebaseManager.swift`

No new methods needed! Just ensure existing methods save the new fields:

#### Existing Method Updates:
```swift
func createTrip(_ trip: Trip) async throws {
    // Firestore encoder will automatically include:
    // - creatorId
    // - adminIds
    // - viewerIds
    let tripData = try Firestore.Encoder().encode(trip)
    try await db.collection("trips").document(trip.id).setData(tripData)
}

func updateTrip(_ trip: Trip) async throws {
    // Same - encoder handles all fields automatically
    let tripData = try Firestore.Encoder().encode(trip)
    try await db.collection("trips").document(trip.id).setData(tripData)
}
```

#### Firestore Schema:
```json
{
  "trips": {
    "{tripId}": {
      "id": "string",
      "groupId": "string",
      "shopperId": "string",
      "tripType": "string",
      "creatorId": "string",        // NEW
      "adminIds": ["string"],       // NEW
      "viewerIds": ["string"],      // NEW
      ...existing fields
    }
  }
}
```

#### Security Rules Update:
```javascript
// In firestore.rules
match /trips/{tripId} {
  allow read: if isSignedIn();

  allow create: if isSignedIn();

  allow update: if isSignedIn() && (
    // Admin can update
    get(/databases/$(database)/documents/trips/$(tripId)).data.adminIds.hasAny([request.auth.uid]) ||
    // Creator can update
    resource.data.creatorId == request.auth.uid
  );

  allow delete: if isSignedIn() && (
    resource.data.creatorId == request.auth.uid ||
    resource.data.adminIds.hasAny([request.auth.uid])
  );
}
```

### 7. Add Role Change Notifications ⏸️ **LOW PRIORITY**

**File**: `Services/NotificationManager.swift`

Add new notification method:

```swift
func createRoleChangeNotification(
    tripId: String,
    userId: String,
    newRole: TripRole,
    changedByUserId: String,
    changedByName: String
) async throws {
    let notification = Notification(
        id: UUID().uuidString,
        userId: userId,
        type: .roleChanged,
        title: newRole == .admin ? "Promoted to Admin 🔧" : "Changed to Viewer 👁️",
        message: "\(changedByName) changed your role in the trip",
        relatedId: tripId,
        createdAt: Date(),
        isRead: false
    )

    try await createNotification(notification)
}
```

Call when role changes:
```swift
// In TripMembersView confirmRoleChange()
if let currentUser = FirebaseManager.shared.currentUser {
    try await NotificationManager.shared.createRoleChangeNotification(
        tripId: trip.id,
        userId: user.id,
        newRole: newRole,
        changedByUserId: currentUser.id,
        changedByName: currentUser.name
    )
}
```

### 8. Add Role Indicators to Trip Cards ⏸️ **LOW PRIORITY**

**Files**: `Views/Trips/MyTripsView.swift`, trip card components

Add role badge to trip cards:

```swift
// In trip card
HStack {
    Text(trip.tripType.icon)
    Text(trip.tripType.displayName)

    Spacer()

    // NEW: Show user's role
    if let currentUserId = FirebaseManager.shared.currentUser?.id {
        let userRole = trip.userRole(userId: currentUserId)
        if userRole != .notMember {
            HStack(spacing: 4) {
                Text(userRole.icon)
                Text(userRole.displayName)
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(userRole.accentColor.opacity(0.2))
            .cornerRadius(8)
        }
    }
}
```

### 9. Add Permission Tests ⏸️ **MEDIUM PRIORITY**

Create unit tests for permission logic:

```swift
// Tests/TripPermissionTests.swift
class TripPermissionTests: XCTestCase {
    func testAdminCanEditList() {
        var trip = Trip(...)
        trip.adminIds = ["user1"]

        XCTAssertTrue(trip.canEditList(userId: "user1"))
    }

    func testViewerCannotEditList() {
        var trip = Trip(...)
        trip.viewerIds = ["user2"]

        XCTAssertFalse(trip.canEditList(userId: "user2"))
    }

    func testPromoteToAdmin() {
        var trip = Trip(...)
        trip.viewerIds = ["user1"]

        trip.promoteToAdmin(userId: "user1")

        XCTAssertTrue(trip.adminIds.contains("user1"))
        XCTAssertFalse(trip.viewerIds.contains("user1"))
    }

    func testCannotDemoteLastAdmin() {
        var trip = Trip(...)
        trip.adminIds = ["user1"]

        XCTAssertTrue(trip.isLastAdmin(userId: "user1"))
    }
}
```

---

## Implementation Checklist

Use this checklist to track implementation progress:

### Core Implementation ✅
- [x] Add creatorId, adminIds, viewerIds to Trip model
- [x] Create TripRole enum with icon, displayName, description
- [x] Add permission helper methods to Trip
- [x] Create TripMembersView with role management UI
- [x] Add role toggle buttons with confirmations
- [x] Implement last admin protection
- [x] Add self-demotion warning
- [x] Add members button to TripDetailView toolbar
- [x] Add sheet for TripMembersView

### Integration Tasks ⏸️
- [ ] Update CreateTripView to set creator as admin
- [ ] Add permission checks to Add Item button
- [ ] Add permission checks to Edit Item button
- [ ] Add permission checks to Delete Item button
- [ ] Update trip join flow to add user as viewer
- [ ] Add role selection to invitation flow
- [ ] Update sample data with role properties
- [ ] Update Firebase methods (already compatible)
- [ ] Update Firestore security rules
- [ ] Add role change notifications (optional)
- [ ] Add role indicators to trip cards (optional)
- [ ] Create permission unit tests (optional)

### Testing Tasks ⏸️
- [ ] Test trip creation with admin role
- [ ] Test new members join as viewers
- [ ] Test viewers cannot see Add/Edit/Delete buttons
- [ ] Test admins can add/edit/delete any item
- [ ] Test admin can promote viewer to admin
- [ ] Test admin can demote admin to viewer
- [ ] Test cannot demote last admin
- [ ] Test self-demotion warning works
- [ ] Test role changes save to Firebase
- [ ] Test role badges display correctly
- [ ] Test multiple admins have equal permissions

---

## Role Capabilities Summary

### Admin Role 🔧
**Can Do:**
- ✅ Add items to trip list
- ✅ Edit any item in trip list
- ✅ Delete any item from trip list
- ✅ Claim items (full or partial)
- ✅ Add comments to items
- ✅ View all trip details
- ✅ Promote viewers to admin
- ✅ Demote admins to viewer
- ✅ Manage trip members

**Cannot Do:**
- ❌ Demote themselves if they're the last admin

### Viewer Role 👁️
**Can Do:**
- ✅ View all items
- ✅ Claim items (full or partial)
- ✅ Add comments to items
- ✅ View trip details
- ✅ See who claimed what

**Cannot Do:**
- ❌ Add items to list
- ❌ Edit items
- ❌ Delete items
- ❌ Change member roles

### Not a Member ❌
**Can Do:**
- ✅ View trip if invited
- ✅ Join trip (becomes Viewer)

**Cannot Do:**
- ❌ Everything else

---

## Edge Cases Handled

### 1. Last Admin Protection ✅
**Scenario**: Admin tries to demote the last admin
**Behavior**: Show alert, prevent action
**Alert**: "Cannot Remove Last Admin - This trip must have at least one Admin"

### 2. Self-Demotion Warning ✅
**Scenario**: Admin demotes themselves
**Behavior**: Show confirmation warning
**Alert**: "You won't be able to edit the list anymore. Continue?"

### 3. Demote Other Admin ✅
**Scenario**: Admin demotes another admin
**Behavior**: Show confirmation
**Alert**: "User will no longer be able to edit the list"

### 4. Promote Viewer ✅
**Scenario**: Admin promotes viewer
**Behavior**: Immediate action, no confirmation needed

### 5. Backward Compatibility ✅
**Scenario**: Load existing trip without role data
**Behavior**: Default values used (empty strings/arrays)
**Result**: Trip loads successfully, needs role assignment

---

## Visual Design

### Color Scheme
- **Admin**: Blue (`Color.bulkShareInfo`)
- **Viewer**: Green (`Color.bulkShareSuccess`)
- **Disabled**: Gray (`Color.bulkShareTextLight`)

### Icons
- **Admin**: 🔧 (wrench)
- **Viewer**: 👁️ (eye)
- **Not Member**: ❌ (cross mark)
- **Promote**: ⬆️ (up arrow)
- **Demote**: ⬇️ (down arrow)
- **Members**: 👥 (people)

### Button States
- **Enabled**: Full opacity, bright colors
- **Disabled**: 50% opacity, gray
- **Disabled with Lock**: 🔒 icon visible

---

## Migration Strategy

### For Existing Trips in Firebase

#### Option 1: Automatic Migration (Recommended)
1. **No action needed** - Codable will use default values
2. When user opens trip:
   - creatorId will be ""
   - adminIds will be []
   - viewerIds will be []
3. First time admin assigns roles, trip is updated
4. Users can manually assign roles through UI

#### Option 2: Manual Data Migration
Run once to backfill existing trips:

```swift
func migrateExistingTrips() async throws {
    let snapshot = try await db.collection("trips").getDocuments()

    for document in snapshot.documents {
        var trip = try document.data(as: Trip.self)

        // Set creator as admin if not set
        if trip.creatorId.isEmpty {
            trip.creatorId = trip.shopperId
            trip.adminIds = [trip.shopperId]
        }

        // Move participants to viewers if empty
        if trip.viewerIds.isEmpty && !trip.participants.isEmpty {
            trip.viewerIds = trip.participants.filter { !trip.adminIds.contains($0) }
        }

        // Save updated trip
        let tripData = try Firestore.Encoder().encode(trip)
        try await document.reference.setData(tripData)
    }

    print("Migration complete: \(snapshot.documents.count) trips updated")
}
```

---

## Performance Considerations

### Efficient Member Loading
```swift
// In TripMembersView
// Load admins and viewers in parallel
async let admins = loadUsers(trip.adminIds)
async let viewers = loadUsers(trip.viewerIds)

let (adminUsers, viewerUsers) = await (admins, viewers)
```

### Caching User Data
Consider caching user objects to avoid repeated Firebase reads:
```swift
// In FirebaseManager
private var userCache: [String: User] = [:]

func getUser(uid: String) async throws -> User {
    if let cached = userCache[uid] {
        return cached
    }

    let user = try await fetchUserFromFirebase(uid: uid)
    userCache[uid] = user
    return user
}
```

---

## Future Enhancements (v2)

### 1. Custom Roles
Allow groups to create custom roles:
- "Organizer"
- "Shopper"
- "Helper"

### 2. Granular Permissions
More fine-grained control:
- Can add items but not delete
- Can edit only own items
- Can approve claims

### 3. Role Templates
Pre-defined role sets:
- "Event Planning" roles
- "Shopping Trip" roles
- "Potluck" roles

### 4. Role History
Track role changes:
- Who changed what
- When it changed
- Audit log

### 5. Bulk Role Changes
Change multiple users at once:
- "Make all participants viewers"
- "Promote all active users"

---

## Troubleshooting

### Issue: Existing trips don't show roles
**Solution**: Trips will have empty role arrays. First admin to open the trip should assign roles through Manage Members.

### Issue: Can't demote last admin
**Solution**: This is intentional. Promote someone else to admin first.

### Issue: Role changes don't persist
**Solution**: Ensure FirebaseManager.updateTrip() is being called after role changes. Check the TODO comment in TripMembersView.confirmRoleChange().

### Issue: New members don't become viewers
**Solution**: Update the trip join flow to add userId to trip.viewerIds array.

---

## Summary

### Completed ✅
- Data model with full role support
- Beautiful role management UI
- Permission helper methods
- Safety features (last admin, self-demotion)
- Role badges and indicators
- Integration with TripDetailView

### Remaining ⏸️
- CreateTripView updates (5 minutes)
- Add/Edit/Delete permission checks (10 minutes)
- Join flow updates (5 minutes)
- Sample data updates (2 minutes)
- Invitation role selection (10 minutes)
- Firebase security rules (5 minutes)

### Total Estimated Time to Complete
**~40 minutes** for all remaining tasks.

---

## Contact & Support

For questions or issues with this implementation, refer to:
- This document for specifications
- `Models/Trip.swift` for data model
- `Views/Trips/TripMembersView.swift` for UI reference
- `FIREBASE_BACKEND_IMPLEMENTATION.md` for backend details

All code follows existing BulkMates patterns and styling conventions.
