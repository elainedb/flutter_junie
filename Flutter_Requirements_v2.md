## **Flutter Requirements_v2.md**

### **Feature Overview**
The app should have two screens:
1. **Login Screen**: Allows users to log in using their Google account. Only authorized users can access the app.
2. **Main Screen**: Displays a list of videos fetched from the YouTube Data API for four given channels. Clicking on a video opens it in the YouTube app or browser.

---

### **Requirements**

#### **Login Screen**
1. The Login Screen should:
   - Display a title: "Login with Google".
   - Include a button labeled "Sign in with Google".
   - Show an error message if the user's email is not authorized.
   - Navigate to the Main Screen upon successful login.

2. Use the same logic for authorized emails as described in `Requirements_v0.md`.

---

#### **Main Screen**
1. The Main Screen should:
   - Display a list of videos fetched from the YouTube Data API.
   - Each item in the list should show:
     - The video thumbnail.
     - The video title.
     - The name of the source channel.
     - The publication date (formatted as `YYYY-MM-DD`).
   - Sort the list by publication date (newest to oldest).
   - Open the YouTube app or browser when a video item is clicked, using the video ID.

2. The list should include videos from the following channels:
   - `UCynoa1DjwnvHAowA_jiMEAQ`
   - `UCK0KOjX3beyB9nzonls0cuw`
   - `UCACkIrvrGAQ7kuc0hMVwvmA`
   - `UCtWRAKKvOEA0CXOue9BG8ZA`

---

#### **YouTube Data API Integration**
1. Use the YouTube Data API to fetch videos from the specified channels.
2. Fetch the following information for each video:
   - Thumbnail URL
   - Title
   - Channel name
   - Publication date
   - Video ID

3. Store the YouTube API key in a configuration file (`config.dart`) that is excluded from version control:
   ```dart
   const String youtubeApiKey = "YOUR_YOUTUBE_API_KEY";
   ```

4. Use the `config.dart` file to access the API key in the code.

---

#### **Code Structure**
1. **Login Screen**:
   - Implement Google Sign-In using the `google_sign_in` package.
   - Navigate to the Main Screen after successful login.

2. **Main Screen**:
   - Fetch video data using the YouTube Data API.
   - Display the video list using a `ListView` widget.
   - Open the YouTube app or browser using the `url_launcher` package when a video is clicked.

3. **API Logic**:
   - Use the `http` package to make API calls to the YouTube Data API.
   - Combine videos from all channels into a single list and sort them by publication date.

---

---