# BulkMates App Store Screenshots - Step-by-Step Guide

This folder contains everything you need to create and submit App Store screenshots.

## 📁 Folder Structure

```
images/
├── README.md              ← You are here (step-by-step instructions)
├── SCREENSHOT_CHECKLIST.md ← Track your progress
├── raw/                   ← Put simulator screenshots here
└── final/                 ← Put final screenshots with text overlays here
```

---

## 🎯 WHAT YOU NEED TO CREATE

**6 screenshots** at **1290 x 2796 pixels** (iPhone 15 Pro Max size):

1. **Hero Shot** - Groups dashboard
2. **Three Plan Types** - Plan type selection screen
3. **Plan Coordination** - Active plan with items
4. **Notifications** - Notifications list
5. **Group Details** - Group page with members
6. **My Plans View** - My Plans screen

---

## 🚀 STEP-BY-STEP PROCESS

### PHASE 1: Setup Sample Data (30 minutes)

**You need realistic demo data in your app before taking screenshots.**

#### 1. Create Demo Groups (3-4 groups)

Open your app and create these groups:

**Group 1: Oakwood Neighbors** 🏡
- Icon: 🏡
- Description: "Neighbors coordinating bulk shopping"
- Add 3-4 demo members

**Group 2: Weekend Warriors** 🏕️
- Icon: 🏕️
- Description: "Friends planning outdoor adventures"
- Add 3-4 demo members

**Group 3: Parent Squad** 👨‍👩‍👧
- Icon: 👨‍👩‍👧
- Description: "Lincoln Elementary parent group"
- Add 2-3 demo members

#### 2. Create Demo Plans (5-6 plans)

**Shopping Plans:**
- "Costco Run - This Weekend" (Costco, in 2 days)
  * Add items: Paper towels, Rice (25 lbs), Granola bars
  * Add photos if possible
  * 3-4 members joined

- "Sam's Club Grocery Haul" (Sam's Club, next week)
  * Add items: Rotisserie chicken, Bananas, Eggs
  * 2 members joined

**Event Plans:**
- "Emma's 10th Birthday Party" (in 5 days)
  * Add items: Birthday cake, Balloons, Party hats
  * Add photos if possible
  * 4-5 members joined

- "Summer BBQ Potluck" (next Saturday)
  * Add items: Burger patties, Popsicles, Paper plates
  * 3 members joined

**Trip Plans:**
- "Yosemite Camping Trip" (in 2 weeks)
  * Add items: Tent, Firewood, Trail mix
  * 4 members joined

#### 3. Create Demo Notifications

Trigger these notifications in your app:
- Group invitation notification
- Plan invitation notification
- Item claim notification
- Leave 2-3 unread

---

### PHASE 2: Take Simulator Screenshots (45 minutes)

#### Step 1: Open Xcode
```bash
cd /Users/sunilkpathak/personal/startup/bulkmates/BulkShareApp/BulkMatesApp
open BulkMatesApp.xcodeproj
```

#### Step 2: Select iPhone 15 Pro Max Simulator
1. In Xcode, click the device selector (top left)
2. Choose **iPhone 15 Pro Max**
3. Click Run (Cmd + R)

#### Step 3: Take Screenshots (Cmd + S)

Navigate to each screen and press **Cmd + S** to save screenshot to Desktop.

**Screenshot 1: Hero Shot - Groups Dashboard**
- Navigate to: My Groups tab
- Make sure: 3-4 groups visible, clean UI
- Filename: `01_groups_dashboard.png`
- Press: **Cmd + S**

**Screenshot 2: Three Plan Types**
- Navigate to: Create Plan screen → Select Plan Type
- Make sure: All 3 types visible (🛒 Shopping, 🎉 Events, 🏕️ Trips)
- Filename: `02_plan_types.png`
- Press: **Cmd + S**

**Screenshot 3: Plan Coordination**
- Navigate to: Any active plan (e.g., "Emma's Birthday Party")
- Make sure: Items visible, group badge at top, member count shown
- Filename: `03_plan_details.png`
- Press: **Cmd + S**

**Screenshot 4: Notifications**
- Navigate to: Notifications tab
- Make sure: 3-5 notifications visible, some unread
- Filename: `04_notifications.png`
- Press: **Cmd + S**

**Screenshot 5: Group Details**
- Navigate to: Any group (e.g., "Oakwood Neighbors")
- Make sure: Members shown, upcoming plans listed
- Filename: `05_group_details.png`
- Press: **Cmd + S**

**Screenshot 6: My Plans View**
- Navigate to: My Plans tab
- Make sure: Mix of plan types, ⭐ You badges visible, clean list
- Filename: `06_my_plans.png`
- Press: **Cmd + S**

#### Step 4: Move Screenshots to Repo

```bash
# Move screenshots from Desktop to raw folder
mv ~/Desktop/01_groups_dashboard.png images/raw/
mv ~/Desktop/02_plan_types.png images/raw/
mv ~/Desktop/03_plan_details.png images/raw/
mv ~/Desktop/04_notifications.png images/raw/
mv ~/Desktop/05_group_details.png images/raw/
mv ~/Desktop/06_my_plans.png images/raw/
```

---

### PHASE 3: Add Text Overlays (1-2 hours)

**Option A: Using Canva (Recommended - Free)**

#### Step 1: Sign up for Canva
- Go to: https://www.canva.com
- Sign up for free account

#### Step 2: Create Custom Size
1. Click "Create a design"
2. Select "Custom size"
3. Enter: **1290 x 2796 pixels**
4. Click "Create new design"

#### Step 3: Upload Your Screenshot
1. Click "Uploads" in left sidebar
2. Upload a screenshot from `images/raw/`
3. Drag it onto the canvas
4. Resize to fill entire canvas (1290 x 2796)

#### Step 4: Add Text Overlay

**For Screenshot 1 (Groups Dashboard):**

1. Add a semi-transparent rectangle at top:
   - Color: Black (#000000)
   - Opacity: 70%
   - Position: Top third of screen

2. Add headline text:
   - Text: "Connect. Plan. Coordinate."
   - Font: Montserrat Bold or Poppins Bold
   - Size: 70-80px
   - Color: White
   - Alignment: Center

3. Add subheadline text:
   - Text: "Plan shopping trips, events, and group outings together"
   - Font: Montserrat Regular or Poppins Regular
   - Size: 40-50px
   - Color: White
   - Alignment: Center

4. Download:
   - Click "Share" → "Download"
   - Format: PNG
   - Save as: `01_groups_dashboard_final.png`
   - Save to: `images/final/`

**Repeat for all 6 screenshots** using the text overlays from SCREENSHOT_CHECKLIST.md

---

**Option B: Using Figma (Advanced - Free)**

#### Step 1: Sign up for Figma
- Go to: https://www.figma.com
- Sign up for free account

#### Step 2: Create Frame
1. Press "F" for Frame tool
2. Select "iPhone 15 Pro Max" from right panel
3. This auto-creates 1290 x 2796 frame

#### Step 3: Import Screenshot
1. Drag screenshot from `images/raw/` into Figma
2. Place inside the frame
3. Resize to fit exactly

#### Step 4: Add Text Overlay
1. Press "T" for Text tool
2. Add headline and subheadline (see text from SCREENSHOT_CHECKLIST.md)
3. Add semi-transparent black rectangle behind text:
   - Create rectangle (R)
   - Fill: #000000
   - Opacity: 70%
   - Place behind text (Cmd + [)

#### Step 5: Export
1. Select the frame
2. Click "Export" in right panel
3. Format: PNG
4. Scale: 1x
5. Export
6. Save to: `images/final/`

---

### PHASE 4: Upload to App Store Connect (30 minutes)

#### Step 1: Log into App Store Connect
- Go to: https://appstoreconnect.apple.com
- Log in with your Apple Developer account

#### Step 2: Navigate to Your App
1. Click "My Apps"
2. Select "BulkMates"
3. Click version "1.0" (or your version)

#### Step 3: Upload Screenshots
1. Scroll to "App Store Screenshots" section
2. Click "iPhone 6.7" Display" (iPhone 15 Pro Max)
3. Click "+" to add screenshots
4. Upload in this order:
   1. `01_groups_dashboard_final.png`
   2. `02_plan_types_final.png`
   3. `03_plan_details_final.png`
   4. `04_notifications_final.png`
   5. `05_group_details_final.png`
   6. `06_my_plans_final.png`

#### Step 4: Preview
- Click "Preview on Device" to see how they look
- Make sure first 3 look good (they appear in search)

#### Step 5: Save
- Click "Save" at top right

---

## 🎨 TEXT OVERLAY REFERENCE

### Screenshot 1: Groups Dashboard
**Headline:** Connect. Plan. Coordinate.
**Subheadline:** Plan shopping trips, events, and group outings together

### Screenshot 2: Three Plan Types
**Headline:** Three Ways to Plan Together
**Subheadline:** Shopping trips, events, and group outings

### Screenshot 3: Plan Coordination
**Headline:** Coordinate Who Brings What
**Subheadline:** Everyone knows what's needed and who's claiming items

### Screenshot 4: Notifications
**Headline:** Stay Connected
**Subheadline:** Get notified about new plans and updates

### Screenshot 5: Group Details
**Headline:** Build Your Planning Community
**Subheadline:** Create groups and plan activities together

### Screenshot 6: My Plans View
**Headline:** Stay Organized
**Subheadline:** Track all your group plans in one place

---

## ✅ QUALITY CHECKLIST

Before uploading to App Store Connect:

**Technical:**
- [ ] All screenshots are 1290 x 2796 pixels
- [ ] All screenshots are PNG format
- [ ] File sizes under 8 MB each
- [ ] RGB color space (not CMYK)
- [ ] No transparency

**Content:**
- [ ] No placeholder or dummy data visible
- [ ] Realistic user names and groups
- [ ] No personal phone numbers or emails visible
- [ ] UI looks clean and polished
- [ ] Green brand color (#4CAF50) visible in app

**Text Overlays:**
- [ ] Text is readable and high contrast
- [ ] Text doesn't cover important UI elements
- [ ] Consistent font and style across all 6
- [ ] No spelling errors
- [ ] Text aligns with app's purpose

**App Store:**
- [ ] First 3 screenshots are the strongest (they appear in search)
- [ ] Screenshots show actual app features
- [ ] All 6 uploaded in correct order

---

## 🆘 TROUBLESHOOTING

**Problem: Simulator screenshot is wrong size**
- Make sure you selected "iPhone 15 Pro Max" (not other models)
- Check screenshot dimensions (should be 1290 x 2796)

**Problem: Can't take screenshot in simulator**
- Try: Cmd + S (should save to Desktop)
- Alternative: Use macOS screenshot (Cmd + Shift + 4)

**Problem: Text overlay looks blurry**
- Make sure canvas size is exactly 1290 x 2796
- Export at 100% scale (not 2x or 0.5x)
- Use PNG format (not JPEG)

**Problem: App Store Connect rejects screenshot**
- Check file format (must be PNG or JPEG)
- Check dimensions (must be exactly 1290 x 2796)
- Check file size (must be under 8 MB)

**Problem: No demo data in app**
- You need to create groups and plans manually first
- Sign up with test accounts if needed
- Use Firebase console to add demo data

---

## 📊 ESTIMATED TIME

| Phase | Time | Description |
|-------|------|-------------|
| 1. Setup Sample Data | 30 min | Create groups, plans, notifications |
| 2. Take Screenshots | 45 min | Navigate app, capture 6 screenshots |
| 3. Add Text Overlays | 1-2 hrs | Use Canva/Figma to add text |
| 4. Upload to App Store | 30 min | Upload and preview |
| **TOTAL** | **3-4 hrs** | Complete screenshot process |

---

## 🎯 QUICK REFERENCE

**Required Size:** 1290 x 2796 pixels
**Format:** PNG
**Quantity:** 6 screenshots minimum, 10 maximum
**Device:** iPhone 15 Pro Max (6.7" display)

**Brand Colors:**
- Primary Green: #4CAF50
- Background: #F8F9FA
- Text: #212529

**Font Recommendations:**
- Headline: Montserrat Bold / Poppins Bold / SF Pro Display Bold
- Subheadline: Montserrat Regular / Poppins Regular / SF Pro Text Regular

---

**Last Updated:** November 8, 2025
**Contact:** sunilkishorpathak@gmail.com
