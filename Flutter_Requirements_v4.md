## **Flutter Requirements_v4.md**

### **Feature Overview**
The app should now include a new **Map Screen** that displays a map with markers for video locations. Users can navigate to this screen from the Main Screen. The map should pan and zoom automatically to fit all markers after loading. Clicking on a marker should display a bottom sheet with video information, and clicking the bottom sheet should open the YouTube app or browser for the selected video.

---

### **Requirements**

#### **Navigation to Map Screen**
1. Add a **Map Screen** button to the Main Screen.
   - Place the button in the app bar or as a floating action button (FAB) for easy access.
   - Label the button "View Map".

2. Clicking the button should navigate the user to the Map Screen.

---

#### **Map Screen**

##### **UI Requirements**
1. **Map**:
   - Use the `flutter_map` package to display an OpenStreetMap-based map.
   - Add markers for each video location retrieved from the cached video data.
   - Automatically pan and zoom the map after loading so all markers are visible.

2. **Marker Interaction**:
   - When the user clicks on a marker, display a bottom sheet at the bottom of the screen with the following video information:
     - Thumbnail.
     - Title.
     - Source channel name.
     - Publication date.
     - Tags.
     - Location (city, country, GPS coordinates).
     - Recording date.

3. **Bottom Sheet**:
   - The bottom sheet should:
     - Take up no more than 25% of the screen height.
     - Be dismissible by swiping down.
     - Include a button or clickable area that opens the YouTube app or browser for the selected video.

---

##### **Logic Requirements**
1. **Marker Data**:
   - Retrieve location data for videos from the cached database.
   - Only add markers for videos that have valid location data (e.g., GPS coordinates).

2. **Map Behavior**:
   - Automatically adjust the map view to fit all markers after loading.
   - Allow users to pan and zoom the map manually after the initial adjustment.

3. **Marker Click**:
   - When a marker is clicked:
     - Display the bottom sheet with video information.
     - Ensure the bottom sheet is interactive and allows the user to open the YouTube app or browser for the selected video.

---

#### **Code Structure**
1. **Map Screen**:
   - Create a new `MapScreen` widget.
   - Use the `flutter_map` package to display the map and markers.

2. **Bottom Sheet**:
   - Use the `showModalBottomSheet` function to display the bottom sheet when a marker is clicked.

3. **Navigation**:
   - Add navigation logic to transition from the Main Screen to the Map Screen.

---

#### **Dependencies**
1. Add the `flutter_map` package to `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter_map: ^3.0.0
   ```

2. Add the `latlong2` package for handling GPS coordinates:
   ```yaml
   dependencies:
     latlong2: ^0.8.1
   ```

---

---