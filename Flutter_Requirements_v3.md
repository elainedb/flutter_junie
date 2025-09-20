## **Flutter Requirements_v3.md**

### **Feature Overview**
The app should have two screens:
1. **Login Screen**: Allows users to log in using their Google account. Only authorized users can access the app.
2. **Main Screen**: Displays a list of videos fetched from the YouTube Data API for four given channels. The list should include additional data for each video, support local caching, and provide filter and sort functionality.

---

### **Requirements**

#### **Login Screen**
- The Login Screen remains unchanged from `Requirements_v2.md`.

---

#### **Main Screen**

##### **UI Requirements**
1. **Video List**:
   - Each video item should display:
     - Thumbnail.
     - Title.
     - Source channel name.
     - Publication date (formatted as `YYYY-MM-DD`).
     - Video ID.
     - Tags (comma-separated).
     - Location (city, country, and GPS coordinates, if available).
     - Recording date (formatted as `YYYY-MM-DD`, if available).

2. **Buttons**:
   - **Refresh Button**: Fetch new data from the YouTube Data API and update the local cache.
   - **Filter Button**: Opens a modal or dropdown with the following filter options:
     - **Source Channel**: Filter by one of the four channels.
     - **Country**: Filter by country.
   - **Sort Button**: Opens a modal or dropdown with the following sort options:
     - **Publication Date**: Sort by publication date (newest to oldest or oldest to newest).
     - **Recording Date**: Sort by recording date (newest to oldest or oldest to newest).

---

##### **Logic Requirements**

1. **Local Caching**:
   - Use a local database (e.g., `sqflite` package) to cache video data.
   - Cache the following fields for each video:
     - Thumbnail URL.
     - Title.
     - Source channel name.
     - Publication date.
     - Video ID.
     - Tags.
     - Location (city, country, GPS coordinates).
     - Recording date.
   - Check the cache before making an API call. If data exists and is not older than a predefined threshold (e.g., 24 hours), use the cached data.

2. **Refresh Button**:
   - Force an API call to fetch new data from the YouTube Data API.
   - Update the local cache with the new data.

3. **Filter Functionality**:
   - Implement filtering logic to display videos based on the selected source channel or country.

4. **Sort Functionality**:
   - Implement sorting logic to order videos by publication date or recording date.

5. **Data Fetching**:
   - Fetch the following additional fields from the YouTube Data API:
     - Tags.
     - Location (city, country, GPS coordinates).
     - Recording date.
   - Use the YouTube Data API's `videos` endpoint to fetch this information.

---

#### **Code Structure**
1. **Database Integration**:
   - Use the `sqflite` package to implement local caching.
   - Create a database table to store video data.

2. **API Integration**:
   - Use the `http` package to make API calls.
   - Fetch additional fields (tags, location, recording date) for each video.

3. **Filter and Sort Logic**:
   - Implement filtering and sorting logic in the Main Screen.
   - Use state management (e.g., `Provider` or `Riverpod`) to manage the filtered and sorted list.

---