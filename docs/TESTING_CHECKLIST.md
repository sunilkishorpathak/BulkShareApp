# BulkMates - Comprehensive Testing Checklist

## 🎯 Pre-Submission Testing (CRITICAL)

**Test on REAL device, not just simulator!**

---

## ✅ 1. AUTHENTICATION & ONBOARDING

### Phone Number Authentication
- [ ] Enter valid US phone number
- [ ] Receive SMS verification code
- [ ] Enter verification code correctly
- [ ] Handle invalid verification code
- [ ] Resend verification code works
- [ ] Test with international number (should show proper format)

### Email Verification
- [ ] Verify email works after signup
- [ ] Email verification link opens app
- [ ] Unverified users can still use app (check logic)

### Password Reset
- [ ] Request password reset email
- [ ] Receive password reset email
- [ ] Reset link works
- [ ] Can log in with new password

### First-Time User Experience
- [ ] Onboarding screens appear
- [ ] Can skip or complete onboarding
- [ ] Profile creation flow works
- [ ] Default values set correctly

---

## ✅ 2. PROFILE MANAGEMENT

### Profile Viewing
- [ ] View own profile
- [ ] Profile picture displays (if set)
- [ ] Initials display (if no picture)
- [ ] Email shows correctly
- [ ] Account creation date shows

### Profile Editing
- [ ] Upload profile picture from camera
- [ ] Upload profile picture from library
- [ ] Remove profile picture
- [ ] Profile picture persists after app restart

### Address Management
- [ ] Add new address
- [ ] Edit existing address
- [ ] **Country picker shows USA by default**
- [ ] **Country picker shows flag + name in dropdown**
- [ ] Remove address (with confirmation)
- [ ] Address visibility settings work

### Security Settings
- [ ] Enable Face ID/Touch ID
- [ ] Disable biometric auth
- [ ] Biometric unlock works on app restart

### Account Deletion
- [ ] Delete account flow shows confirmation
- [ ] Delete account removes all data
- [ ] Cannot log in after deletion
- [ ] Data is actually removed from Firebase

---

## ✅ 3. GROUP MANAGEMENT

### Creating Groups
- [ ] Create group with emoji icon
- [ ] Create group with custom description
- [ ] Group appears in "My Groups"
- [ ] Creator is set as admin

### Inviting Members
- [ ] Invite by email works
- [ ] Multiple invitations at once
- [ ] Can't invite duplicate emails
- [ ] Invited user receives notification (if they have account)

### Viewing Groups
- [ ] Group list shows all groups
- [ ] Group details load correctly
- [ ] Member count is accurate
- [ ] Active plans count shows

### Group Settings (Admin)
- [ ] Edit group name
- [ ] Edit group description
- [ ] Change group icon
- [ ] **Delete group shows confirmation**
- [ ] **Deleting group deletes all plans**

### Leaving Groups (Non-Admin)
- [ ] **Leave group option appears**
- [ ] **Confirmation dialog shows**
- [ ] User removed from group
- [ ] Group disappears from list

---

## ✅ 4. PLAN CREATION & MANAGEMENT

### Creating Plans
- [ ] Select group for plan
- [ ] Choose plan type (Shopping, Events, Trips)
- [ ] **Only 3 plan types shown (no Hosting tab)**
- [ ] Add plan name
- [ ] Set date and time (must be future)
- [ ] Add store (for Shopping type)
- [ ] Add items with photos
- [ ] Add items without photos
- [ ] Add notes to plan
- [ ] Create plan saves to Firebase
- [ ] **Plan name displays in list (not empty)**

### My Plans View
- [ ] **Only 2 tabs: Upcoming and Past**
- [ ] **No "Hosting" tab visible**
- [ ] Plans appear in correct tab (by date)
- [ ] Filter by plan type works
- [ ] **Creator indicator shows (⭐ You badge)**
- [ ] Pull to refresh works

### Viewing Plan Details
- [ ] Plan details load completely
- [ ] Items list shows all items
- [ ] **Group badge shows at top**
- [ ] **Tapping group badge navigates to group**
- [ ] Date and time display correctly
- [ ] Notes display if present
- [ ] Participant list shows

### Editing Plans (Creator/Admin)
- [ ] **Menu button (⋮) appears for creator/admin**
- [ ] **Edit plan details option works**
- [ ] Can change plan name
- [ ] Can change date/time
- [ ] Can change plan type
- [ ] Changes save to Firebase

### Deleting Plans (Creator/Admin)
- [ ] **Delete plan option in menu**
- [ ] **Confirmation dialog shows**
- [ ] Plan deleted from Firebase
- [ ] Plan removed from all lists

### Item Management
- [ ] Add item to plan
- [ ] Add photo to item
- [ ] Edit item details
- [ ] Delete item from plan
- [ ] Items persist after refresh

---

## ✅ 5. NOTIFICATIONS

### Receiving Notifications
- [ ] **Notifications appear in Notifications tab**
- [ ] **Badge shows unread count**
- [ ] Group invitation notification
- [ ] Trip invitation notification
- [ ] Item claim notification
- [ ] Notifications sorted by date (newest first)

### Notification Actions
- [ ] Accept group invitation
- [ ] Reject group invitation
- [ ] Tap notification navigates to related item
- [ ] Mark notification as read
- [ ] **"Mark All Read" button works**
- [ ] Unread count updates correctly

### Notification Icon
- [ ] **Bell icon shows in tab bar**
- [ ] **Badge appears when unread notifications exist**
- [ ] Badge clears when all read

---

## ✅ 6. ROLE MANAGEMENT

### Trip Member Roles
- [ ] View plan members screen
- [ ] Admins listed separately from viewers
- [ ] **Promote viewer to admin**
- [ ] **Demote admin to viewer**
- [ ] **Role changes save to Firebase**
- [ ] **Role changes persist after refresh**
- [ ] Cannot demote last admin
- [ ] Self-demotion shows warning

---

## ✅ 7. UI/UX POLISH

### Navigation
- [ ] All back buttons work
- [ ] Tab bar navigation works
- [ ] Sheet dismissal works
- [ ] Navigation titles visible
- [ ] "Done" buttons work

### Visual Design
- [ ] Green color scheme consistent (#4CAF50)
- [ ] Icons display correctly
- [ ] Images load properly
- [ ] Empty states show helpful messages
- [ ] Loading indicators appear during operations

### Disabled Features
- [ ] **Transactions tab is greyed out**
- [ ] **Transactions tab not tappable**
- [ ] **No Email Debug option in Profile**

---

## ✅ 8. ERROR HANDLING

### Network Errors
- [ ] Turn on Airplane mode
- [ ] Try to create plan (should show error)
- [ ] Try to load groups (should show cached or error)
- [ ] Turn off Airplane mode
- [ ] Data syncs correctly
- [ ] No app crashes

### Invalid Input
- [ ] Submit form with empty required fields
- [ ] Enter invalid email format
- [ ] Enter invalid phone number
- [ ] Try to create plan with past date
- [ ] Try to add duplicate group member

### Firebase Errors
- [ ] Simulate Firestore permission denied
- [ ] Simulate document not found
- [ ] App handles errors gracefully (no crashes)

---

## ✅ 9. PERFORMANCE

### App Launch
- [ ] Cold start < 3 seconds
- [ ] Splash screen shows
- [ ] No white screen flash

### Data Loading
- [ ] Groups list loads quickly
- [ ] Plans list loads quickly
- [ ] Notifications load immediately
- [ ] Images load without blocking UI

### Memory Usage
- [ ] No memory warnings in Console
- [ ] App doesn't crash after extended use
- [ ] Images release from memory properly

---

## ✅ 10. EDGE CASES

### Empty States
- [ ] No groups created yet
- [ ] No plans created yet
- [ ] No notifications yet
- [ ] Group with no members
- [ ] Plan with no items

### Large Data Sets
- [ ] Group with 20+ members
- [ ] Plan with 50+ items
- [ ] User in 10+ groups
- [ ] 100+ notifications

### Special Characters
- [ ] Group name with emoji
- [ ] Plan name with special characters
- [ ] Item name with quotes
- [ ] Notes with line breaks

---

## ✅ 11. ACCESSIBILITY

### VoiceOver
- [ ] Navigate app with VoiceOver enabled
- [ ] All buttons have labels
- [ ] Images have descriptions
- [ ] Form fields have labels

### Dynamic Type
- [ ] Increase text size in Settings
- [ ] App text scales appropriately
- [ ] Layout doesn't break

### Color Contrast
- [ ] Text readable on all backgrounds
- [ ] Meets WCAG AA standards

---

## ✅ 12. DEVICE TESTING

### iOS Versions
- [ ] iOS 16.0 (minimum supported)
- [ ] iOS 17.0
- [ ] iOS 18.0 (latest)

### Device Sizes
- [ ] iPhone SE (small screen)
- [ ] iPhone 15 Pro (standard)
- [ ] iPhone 15 Pro Max (large)
- [ ] iPad (if supported)

### Orientations
- [ ] Portrait mode (primary)
- [ ] Landscape mode (if supported)
- [ ] Rotation handling

---

## ✅ 13. SECURITY & PRIVACY

### Data Protection
- [ ] User data encrypted in transit
- [ ] Firestore security rules enforced
- [ ] Users can only see their groups/plans
- [ ] Profile pictures stored securely

### Privacy
- [ ] Privacy Policy accessible from app
- [ ] Terms of Service accessible from app
- [ ] User can delete their data
- [ ] No tracking without consent

---

## ✅ 14. REAL-WORLD SCENARIOS

### Scenario 1: New User Journey
1. [ ] Download app
2. [ ] Sign up with phone
3. [ ] Verify email
4. [ ] Create profile
5. [ ] Create first group
6. [ ] Invite friend
7. [ ] Create first plan
8. [ ] Add items
9. [ ] Friend accepts invitation

### Scenario 2: Existing User
1. [ ] Open app (already logged in)
2. [ ] Check notifications
3. [ ] Join new group
4. [ ] View upcoming plans
5. [ ] Claim items from plan
6. [ ] Edit profile

### Scenario 3: Group Admin
1. [ ] Create group
2. [ ] Invite 3 members
3. [ ] Create shopping plan
4. [ ] Manage member roles
5. [ ] Delete old plan
6. [ ] Edit group settings

---

## 🐛 BUG TRACKING

### How to Report Bugs Found:

**Template:**
```
**Bug:** [Short description]
**Steps to Reproduce:**
1.
2.
3.

**Expected:** [What should happen]
**Actual:** [What actually happens]
**Device:** iPhone 15 Pro, iOS 17.1
**Severity:** Critical / High / Medium / Low
**Screenshot:** [Attach if applicable]
```

### Severity Definitions:
- **Critical:** App crashes, data loss, cannot use core features
- **High:** Major feature broken, workaround exists
- **Medium:** Minor feature issue, doesn't block usage
- **Low:** Cosmetic issue, typo, minor UX improvement

---

## 📝 TESTING LOG

### Test Session Template:

```
**Date:** November 7, 2025
**Tester:** [Your name]
**Device:** iPhone 15 Pro
**iOS Version:** 17.1
**App Version:** 1.0 (Build 5)

**Tests Completed:**
- [ ] Authentication (10/10 passed)
- [ ] Profile (8/9 passed - 1 minor issue)
- [ ] Groups (12/12 passed)
- [ ] Plans (15/15 passed)
- [ ] Notifications (8/8 passed)

**Bugs Found:** 2
**Critical:** 0
**High:** 0
**Medium:** 1
**Low:** 1

**Notes:**
[Any additional observations]
```

---

## ✅ FINAL SIGN-OFF CHECKLIST

Before submitting to App Store:

- [ ] ✅ All critical tests passed
- [ ] ✅ No unresolved critical/high bugs
- [ ] ✅ Tested on at least 3 different devices
- [ ] ✅ Tested with 5-10 beta users
- [ ] ✅ Privacy Policy and Terms accessible
- [ ] ✅ All legal pages load correctly
- [ ] ✅ No debug print statements in production
- [ ] ✅ App Store screenshots prepared
- [ ] ✅ App Store description written
- [ ] ✅ Support email monitored and responsive

---

## 🎯 RECOMMENDED TESTING TIMELINE

### Week 1: Internal Testing
- Day 1-2: Developer testing (you)
- Day 3-4: Fix critical bugs
- Day 5-7: Friends & family testing

### Week 2: Beta Testing
- Day 1-3: TestFlight with 10 users
- Day 4-5: Fix reported issues
- Day 6-7: Final verification testing

### Week 3: Pre-Submission
- Day 1-2: Final device testing
- Day 3-4: Screenshot preparation
- Day 5: Submit to App Store

---

**Last Updated:** November 7, 2025
**Document Version:** 1.0
**Contact:** sunilkishorpathak@gmail.com
