# Firestore Security Rules for BulkMates

This document explains the required Firestore security rules for the BulkMates app.

---

## 🔒 **REQUIRED FIRESTORE RULES**

Copy and paste these rules into your Firebase Console under **Firestore Database → Rules**.

### **How to Update Firestore Rules:**

1. Go to: https://console.firebase.google.com/
2. Select your **BulkMates** project
3. Click **Firestore Database** in the left sidebar
4. Click the **Rules** tab at the top
5. Replace the existing rules with the rules below
6. Click **Publish**

---

## 📋 **Firestore Rules (Copy This)**

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // Helper function: Check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }

    // Helper function: Check if user is the document owner
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Users collection: Users can read/write their own data
    match /users/{userId} {
      // Allow users to read their own profile and other users' profiles (for displaying in groups)
      allow read: if isAuthenticated();

      // Allow users to create/update/delete only their own profile
      allow write: if isOwner(userId);
    }

    // Groups collection: Group members can read/write
    match /groups/{groupId} {
      // Allow read if user is authenticated (for browsing/joining with invite code)
      allow read: if isAuthenticated();

      // Allow create if user is authenticated (creating new groups)
      allow create: if isAuthenticated();

      // Allow update/delete if user is a group member or admin
      allow update, delete: if isAuthenticated()
                             && (request.auth.uid in resource.data.members
                                 || request.auth.uid == resource.data.adminId);
    }

    // Trips/Plans collection: Group members can read/write
    match /trips/{tripId} {
      // Allow read if user is authenticated and is in the associated group
      allow read: if isAuthenticated();

      // Allow create if user is authenticated
      allow create: if isAuthenticated();

      // Allow update/delete if user is the trip creator
      allow update, delete: if isAuthenticated()
                             && request.auth.uid == resource.data.createdBy;
    }

    // Item claims: Members can claim items
    match /trips/{tripId}/claims/{claimId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }

    // Item requests: Members can request items to be added to trips
    match /trips/{tripId}/itemRequests/{requestId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }

    // Notifications collection: Users can read their own notifications
    match /notifications/{notificationId} {
      // Users can read notifications sent to them
      allow read: if isAuthenticated()
                  && request.auth.uid == resource.data.recipientUserId;

      // Authenticated users can create notifications
      allow create: if isAuthenticated();

      // Users can update their own notifications (mark as read)
      allow update: if isAuthenticated()
                    && request.auth.uid == resource.data.recipientUserId;

      // Users can delete their own notifications
      allow delete: if isAuthenticated()
                    && request.auth.uid == resource.data.recipientUserId;
    }

    // Transactions: Users can read/write their own transactions
    match /transactions/{transactionId} {
      // Users can read transactions they're involved in
      allow read: if isAuthenticated()
                  && (request.auth.uid == resource.data.payerId
                      || request.auth.uid == resource.data.recipientId);

      // Authenticated users can create transactions
      allow create: if isAuthenticated();

      // Users can update transactions they created
      allow update: if isAuthenticated()
                    && request.auth.uid == resource.data.payerId;

      // Users can delete their own transactions
      allow delete: if isAuthenticated()
                    && request.auth.uid == resource.data.payerId;
    }

    // Deny all other access by default
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 🔍 **WHAT THESE RULES DO**

### **Users Collection (`users/{userId}`)**

✅ **Read Access:**
- Any authenticated user can view user profiles
- Needed for displaying member info in groups and trips

✅ **Write Access:**
- Users can only create/update/delete their own profile
- Security check: `request.auth.uid == userId`

---

### **Groups Collection (`groups/{groupId}`)**

✅ **Read Access:**
- Any authenticated user can read groups
- Needed for invite code system and group discovery

✅ **Write Access:**
- Create: Any authenticated user can create groups
- Update/Delete: Only group members or admin can modify

---

### **Trips/Plans Collection (`trips/{tripId}`)**

✅ **Read Access:**
- Any authenticated user can read trips
- Typically filtered by group membership in app logic

✅ **Write Access:**
- Create: Any authenticated user can create trips
- Update/Delete: Only trip creator can modify

---

### **Notifications Collection (`notifications/{notificationId}`)**

✅ **Read Access:**
- Users can ONLY read their own notifications
- Security check: `request.auth.uid == resource.data.recipientUserId`
- This prevents users from seeing others' notifications

✅ **Write Access:**
- Create: Any authenticated user can create notifications
- Update: Users can update (mark as read) their own notifications
- Delete: Users can delete their own notifications

**Key Security Feature:**
The `recipientUserId` field ensures notifications are private and only visible to the intended recipient.

---

### **Transactions Collection (`transactions/{transactionId}`)**

✅ **Read Access:**
- Users can read transactions where they're the payer or recipient
- Privacy protection: users can't see unrelated transactions

✅ **Write Access:**
- Create: Any authenticated user can create transactions
- Update/Delete: Only the payer can modify

---

## 🚨 **IMPORTANT SECURITY NOTES**

1. **User Authentication Required:**
   - All database access requires authentication (`request.auth != null`)
   - Unauthenticated users cannot read or write any data

2. **Notifications Privacy:**
   - Users can ONLY access notifications sent to them
   - `recipientUserId` field must match the authenticated user's ID
   - Prevents information leakage between users

3. **Ownership Validation:**
   - Users can only modify their own data
   - Group admins can modify group settings
   - Trip creators can modify their trips

4. **Default Deny:**
   - Any collection not explicitly mentioned is denied access
   - Fail-secure approach

---

## 🧪 **TESTING YOUR RULES**

After publishing the rules, test them:

### **Test 1: View Notifications**
1. Open BulkMates app
2. Sign in with your account
3. Tap Notifications tab
4. **Expected:** Notifications load successfully ✅

### **Test 2: Create a Trip**
1. Create a new shopping trip in a group
2. **Expected:** Group members receive notifications ✅

### **Test 3: Mark Notification as Read**
1. Tap on a notification
2. **Expected:** Notification updates to "read" status ✅

---

## 🔧 **TROUBLESHOOTING**

### **Error: "Missing or insufficient permissions"**

**Cause:** Firestore rules are not set correctly or not published

**Fix:**
1. Verify rules are published in Firebase Console
2. Check that `request.auth != null` is present in rules
3. Make sure user is signed in (check Auth status)
4. Wait 30-60 seconds after publishing rules (propagation delay)

### **Error: "Listen for query failed"**

**Cause:** Real-time listener doesn't have read permission

**Fix:**
- Ensure the query fields match the security rules
- For notifications: verify `recipientUserId == request.auth.uid`
- Check that indexes are created for compound queries

### **Notifications Not Appearing**

**Cause:** Either no notifications exist or permissions issue

**Fix:**
1. Check Firestore Console → notifications collection
2. Verify notifications have correct `recipientUserId` field
3. Ensure you're signed in with the correct user
4. Check app logs for permission errors

---

## 📊 **DATABASE STRUCTURE**

```
firestore/
├── users/
│   └── {userId}
│       ├── id: string
│       ├── name: string
│       ├── email: string
│       ├── profileImageURL: string?
│       └── createdAt: timestamp
│
├── groups/
│   └── {groupId}
│       ├── id: string
│       ├── name: string
│       ├── description: string
│       ├── members: array<string>
│       ├── invitedEmails: array<string>
│       ├── icon: string
│       ├── iconUrl: string?
│       ├── adminId: string
│       ├── inviteCode: string
│       └── createdAt: timestamp
│
├── trips/
│   └── {tripId}
│       ├── id: string
│       ├── groupId: string
│       ├── store: object
│       ├── items: array
│       ├── createdBy: string
│       └── createdAt: timestamp
│
├── notifications/
│   └── {notificationId}
│       ├── id: string
│       ├── type: string
│       ├── title: string
│       ├── message: string
│       ├── recipientUserId: string ← KEY FIELD FOR SECURITY
│       ├── senderUserId: string
│       ├── senderName: string
│       ├── senderProfileImageURL: string?
│       ├── relatedId: string
│       ├── createdAt: timestamp
│       ├── isRead: boolean
│       └── status: string
│
└── transactions/
    └── {transactionId}
        ├── id: string
        ├── payerId: string
        ├── recipientId: string
        ├── amount: number
        └── createdAt: timestamp
```

---

## 🔄 **RULE UPDATES LOG**

| Date | Change | Reason |
|------|--------|--------|
| Nov 15, 2025 | Initial rules created | Notifications permission fix |
| Nov 15, 2025 | Added all core collections | Complete app security setup |

---

## 📞 **NEED HELP?**

If you encounter issues:

1. **Check Firebase Console Logs:**
   - Firestore → Usage tab
   - Look for denied requests

2. **Test Rules in Firebase:**
   - Firestore → Rules tab
   - Click "Rules Playground"
   - Simulate read/write operations

3. **Verify User Authentication:**
   - Make sure user is signed in
   - Check `Auth.auth().currentUser?.uid` is not nil

4. **Check Indexes:**
   - Some queries require composite indexes
   - Firebase will show error in console with index creation link

---

**Last Updated:** November 15, 2025
**Contact:** sunilkishorpathak@gmail.com
