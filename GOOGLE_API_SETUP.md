# Google API Setup for MacMail

MacMail requires its own dedicated Google Cloud OAuth Client to securely fetch your personal emails and calendar events. Follow these steps once before signing in.

## Step 1: Create a Google Cloud Project
1. Go to the [Google Cloud Console](https://console.cloud.google.com).
2. Create a new project and name it `MacMail` (or anything you prefer).
3. Ensure your new project is selected in the top-left dropdown menu.

## Step 2: Enable the Required APIs
You must explicitly turn on the APIs that MacMail uses to function.
1. In the Google Cloud Console, go to **APIs & Services** > **Library**.
2. Search for **"Gmail API"** and click **Enable**.
3. Search for **"Google Calendar API"** and click **Enable**.
4. Search for **"Google Drive API"** and click **Enable**. *(This is used for inserting Google Drive links into the composer).*

## Step 3: Configure the OAuth Consent Screen
1. Navigate to **APIs & Services** > **OAuth consent screen**.
2. Choose **External** (unless you have a Google Workspace account and are only using it internally).
3. Fill in the required details:
    - App name: `MacMail`
    - User support email: Your email address
    - Developer contact email: Your email address
4. Click **Save and Continue** until you reach the **Scopes** section. Add the following scopes:
    - `https://www.googleapis.com/auth/gmail.modify`
    - `https://www.googleapis.com/auth/gmail.labels`
    - `https://www.googleapis.com/auth/gmail.compose`
    - `https://www.googleapis.com/auth/gmail.send`
    - `https://www.googleapis.com/auth/calendar.readonly`
    - `https://www.googleapis.com/auth/drive.readonly`
5. Click **Save and Continue** to reach the **Test Users** section.
6. **CRITICAL STEP**: Add every Google account you plan to log into MacMail with as a "Test User". Because your app is not verified by Google, only users on this explicit list will be allowed to log in.

## Step 4: Create and Download Credentials
1. Navigate to **APIs & Services** > **Credentials**.
2. Click the **+ CREATE CREDENTIALS** button at the top and choose **OAuth client ID**.
3. Set the Application type to **Desktop app**.
4. Name it `MacMail macOS` and click Create.
5. A modal will pop up with your Client ID and Client Secret. Click the **DOWNLOAD JSON** button to save the `client_secret_xyz.json` file to your computer.

## Step 5: Import Credentials into MacMail
1. Build and run the MacMail application.
2. Click the **Gear ⚙️** icon in the top right to open Settings.
3. Click **Import OAuth JSON** and select the `.json` file you just downloaded.
4. Click **Add Account...** in the top navigation dropdown to sign in.

---

## Troubleshooting

### "Error 403: access_denied" (App not verified)
If Google shows `MacMail has not completed the Google verification process`, your account is not on the Test Users list. Go back to Step 3, Section 6, and add your email address.

### "Permission denied" or "Google Calendar API is NOT enabled"
If the app throws a 403 error specifically when opening the Calendar or Drive picker:
1. Double-check that you completed **Step 2** and enabled the Calendar and Drive APIs.
2. If you enabled them *after* logging into the app, you must go to Settings, click **Remove Account**, and log in again so Google can grant your app the new permission scopes.

### Browser Spins Indefinitely After Sign In
After you click "Continue" on Google's consent screen, your browser should redirect to a local callback (e.g., `http://127.0.0.1:49152`) that says sign-in is complete. If the browser spins forever, quit MacMail entirely, relaunch it, and try signing in again. MacMail only keeps the local callback server running for 3 minutes.
