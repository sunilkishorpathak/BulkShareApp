# Firebase Storage Rules for BulkMates

This document explains the required Firebase Storage security rules for the BulkMates app.

---

## 🔒 **REQUIRED STORAGE RULES**

Copy and paste these rules into your Firebase Console under **Storage → Rules**.

### **How to Update Firebase Storage Rules:**

1. Go to: https://console.firebase.google.com/
2. Select your **BulkMates** project
3. Click **Storage** in the left sidebar
4. Click the **Rules** tab at the top
5. Replace the existing rules with the rules below
6. Click **Publish**

---

## 📋 **Storage Rules (Copy This)**

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {

    // Profile images: Users can read/write their own profile picture
    match /profile_images/{userId}.jpg {
      // Allow read if:
      // - User is authenticated
      allow read: if request.auth != null;

      // Allow write if:
      // - User is authenticated
      // - User is uploading their own profile picture (userId matches auth uid)
      // - File is an image (JPEG or PNG)
      // - File size is under 5MB
      allow write: if request.auth != null
                   && request.auth.uid == userId
                   && request.resource.contentType.matches('image/(jpeg|png)')
                   && request.resource.size < 5 * 1024 * 1024;
    }

    // Trip/Plan item images: Users can upload if they're authenticated
    match /trip_images/{tripId}/{itemId}.jpg {
      // Allow read if user is authenticated
      allow read: if request.auth != null;

      // Allow write if:
      // - User is authenticated
      // - File is an image
      // - File size is under 5MB
      allow write: if request.auth != null
                   && request.resource.contentType.matches('image/(jpeg|png)')
                   && request.resource.size < 5 * 1024 * 1024;
    }

    // Activity images: Users can upload if they're authenticated
    match /activity_images/{activityId}.jpg {
      // Allow read if user is authenticated
      allow read: if request.auth != null;

      // Allow write if:
      // - User is authenticated
      // - File is an image
      // - File size is under 5MB
      allow write: if request.auth != null
                   && request.resource.contentType.matches('image/(jpeg|png)')
                   && request.resource.size < 5 * 1024 * 1024;
    }

    // Deny all other access by default
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 🔍 **WHAT THESE RULES DO**

### **Profile Images (`profile_images/{userId}.jpg`)**

✅ **Read Access:**
- Any authenticated user can view profile pictures
- Public access for displaying user avatars in groups

✅ **Write Access:**
- Users can **only** upload their own profile picture
- Security check: `request.auth.uid == userId`
- Only JPEG or PNG images allowed
- Maximum file size: 5MB

### **Trip/Plan Item Images (`trip_images/{tripId}/{itemId}.jpg`)**

✅ **Read Access:**
- Any authenticated user can view trip item images

✅ **Write Access:**
- Any authenticated user can upload trip item images
- Useful for adding photos to shared shopping lists
- Only JPEG or PNG images allowed
- Maximum file size: 5MB

### **Activity Images (`activity_images/{activityId}.jpg`)**

✅ **Read Access:**
- Any authenticated user can view activity images

✅ **Write Access:**
- Any authenticated user can upload activity images
- Only JPEG or PNG images allowed
- Maximum file size: 5MB

---

## 🚨 **IMPORTANT SECURITY NOTES**

1. **User Authentication Required:**
   - All storage access requires authentication (`request.auth != null`)
   - Unauthenticated users cannot read or write any files

2. **File Type Validation:**
   - Only JPEG and PNG images are allowed
   - Prevents users from uploading malicious files

3. **File Size Limits:**
   - Maximum 5MB per file
   - Prevents abuse and excessive storage costs

4. **User-Specific Access:**
   - Users can only upload/delete their own profile pictures
   - Prevents users from overwriting other users' data

---

## 🧪 **TESTING YOUR RULES**

After publishing the rules, test them:

### **Test 1: Upload Profile Picture**
1. Open BulkMates app
2. Go to Profile
3. Tap camera icon
4. Select a photo
5. **Expected:** Upload succeeds ✅

### **Test 2: View Others' Profile Pictures**
1. Open a group
2. View member profiles
3. **Expected:** You can see their profile pictures ✅

### **Test 3: Unauthenticated Access**
1. Sign out of the app
2. Try to access a profile picture URL directly
3. **Expected:** Access denied ❌

---

## 🔧 **TROUBLESHOOTING**

### **Error: "User does not have permission to access"**

**Cause:** Storage rules are not set correctly

**Fix:**
1. Check rules are published in Firebase Console
2. Verify `request.auth != null` is present
3. Make sure user is signed in

### **Error: "Object does not exist"**

**Cause:** File upload failed or timing issue

**Fix:**
- This is now fixed in the code (removed arbitrary delays)
- Upload completes before getting download URL

### **Error: "File size exceeds maximum"**

**Cause:** Image is over 5MB

**Fix:**
- App now automatically compresses images to under 2MB
- Resizes to max 1024px dimension

---

## 📊 **STORAGE PATH STRUCTURE**

```
gs://your-project-bucket/
├── profile_images/
│   ├── userId1.jpg
│   ├── userId2.jpg
│   └── userId3.jpg
├── trip_images/
│   ├── tripId1/
│   │   ├── itemId1.jpg
│   │   └── itemId2.jpg
│   └── tripId2/
│       └── itemId1.jpg
└── activity_images/
    ├── activityId1.jpg
    └── activityId2.jpg
```

---

## 🔄 **RULE UPDATES LOG**

| Date | Change | Reason |
|------|--------|--------|
| Nov 8, 2025 | Initial rules created | Profile picture upload fix |
| Nov 8, 2025 | Added file size limits | Prevent storage abuse |
| Nov 8, 2025 | Added content type validation | Security improvement |

---

## 📞 **NEED HELP?**

If you encounter issues:

1. **Check Firebase Console Logs:**
   - Storage → Usage tab
   - Look for denied requests

2. **Test Rules in Firebase:**
   - Storage → Rules tab
   - Click "Rules Playground"
   - Simulate read/write operations

3. **Verify User Authentication:**
   - Make sure user is signed in
   - Check `Auth.auth().currentUser?.uid` is not nil

---

**Last Updated:** November 8, 2025
**Contact:** sunilkishorpathak@gmail.com
