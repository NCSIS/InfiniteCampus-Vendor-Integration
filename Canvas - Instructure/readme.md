Please contact your CANVAS rep for set up.  Here are the instructions they have provided.

CANVAS CONTACT INFO: ncsisconversions@instructure.com


Project Discovery:
Current Integration Method: Powerschool
New Integration Method: Infinite Campus
Authentication Method: NCEdCloud (let us know if your authentication method or login_ids will be changing)
First day of school: Aug 6, 2025

What to expect for your SIS Conversion:
Default mappings for Infinite Campus will be used for the conversion.
Instructure will need credentials and full data set access to your SIS at least 3 weeks before the Go Live Date (first day of school).
A Technical Consultant (TC) will remap your new integration to match user and account IDs in Canvas.
Updates to terms should be done manually through the user interface once the conversion is complete.

Your Action Items:

Upload your OneRoster API URL, Auth URL, key, and secret as a .txt file using this ShareFile link. For security reasons, please do not email this file directly. Note: Please contact your Infinite Campus if you need assistance with generating your credentials.
Be sure to include the name of your institution on the file.
OneRoster 1.2 (NOT 1.1) credentials are required (see URL examples below)
API URL: …/campus/api/ims/oneroster/rostering/v1p2
Auth URL: …/campus/oauth2/token?appName=<name>
Reply to this email with your preferences for the following settings. Note: More information about these settings can be found here. If no preferences are specified, then the default settings will be used.
Course and Section Mapping: 1:1 or 1:many
Terms Organization: per school or unified
Enrollment Drop Behavior: inactive, deleted, deleted_last_completed, or concluded
Grade Passback: enabled or disabled
Avoid creating any new data objects during the SIS Conversion.

HOWTO OneRoster API (Jeremiah Jackson)

Login to Infinite Campus 

Click on Instruction

Digital Learning Application Configuration

Click the + Add Application

Choose Instructure - Data Sync

Click + next toe OneRoster Connections

Click +Generate New OneRoster Connection
Click Generate (OneRoster 1.2)

This Screen will have the ClientID ClientSecret etc

