# RenalPal - Your trusted kidney health companion.

**RenalPal** is a mobile health app built with Flutter that helps people living with kidney disease (renal failure) manage daily health routines. It centralises tracking for dialysis sessions, blood pressure, fluid intake, medications, and includes a chat/doctor role system. Data is stored in Firebase under the user's account.

---

## Repository
https://github.com/Kellan1211/RenalPal

---

## Project overview

RenalPal aims to make self-care easier for renal patients by providing:

- Dialysis session tracker (add and view upcoming sessions)
- Blood pressure tracker with averages and latest readings
- Fluid intake tracker displayed in litres
- Medication tracker (medications per day shown on home)
- Diet, facts and settings pages
- User-to-Doctor Chats
- Community/Direct Chats
- Authentication (Login / Register)

---

## Commit history

0)	Initial commit: RenalPal v1.0
Created Login, Register, Home and Chat pages. Added basic versions of Diet, Facts, Settings, Dialysis, Blood Pressure Tracker, Fluid Intake and Medication pages.

1)	RenalPal v1.1.0
Completed the Diet, Facts and Settings pages. Updated the Homepage to Dynamically accept data and correctly fill the four blocks.

2)	RenalPal v1.2.0
Implemented the Dialysis feature. Users can now add new dialysis sessions, which are saved in Firebase under their account. The next session appears correctly on the Homepage.

3)	RenalPal v1.3.0
Created the Blood Pressure Tracker. User can add their systolic and diastolic readings, with the latest and average blood pressure correctly displaying on the Homepage.

4)	RenalPal v1.4.0
Created the Fluid Intake Page. Users can log their daily water consumption, which is displayed on the Homepage in litres.

5)	RenalPal v1.5.0
Made the Medications page, which now allows users to record their medication. The Homepage now shows the total number of medications taken daily. 
The Doctor Chat System was also updated to a doctor-patient role system. User can now message a doctor privately without a user  role being able to view it.

---

## Features

- User Authentication (Firebase)
- Dialysis session
- Blood Pressure tracking (systolic & diastolic) with averages
- Fluid intake tracking (litres)
- Medication management
- User-to-Doctor Chats
- Community/Direct Chats
- Simple, accessible UI tailored for patients

---

## Screenshots
<img width="322" height="685" alt="Login Page" src="https://github.com/user-attachments/assets/8206c6e0-ed3c-43ea-b341-db611a3df44b" />
<img width="321" height="686" alt="Registration Page" src="https://github.com/user-attachments/assets/bcabbafe-67c7-4fb3-8015-35eef7e8ea50" />
<img width="322" height="688" alt="Home Page" src="https://github.com/user-attachments/assets/e33b941c-3443-4407-a66b-318e140eed5b" />
<img width="322" height="685" alt="" src="https://github.com/user-attachments/assets/8f1ba170-1282-4d6f-8ac7-6b0af343b69a" />
<img width="321" height="686" alt="" src="https://github.com/user-attachments/assets/7f1ce9ae-eddd-4375-81b8-34a89d6cb7c5" />
<img width="321" height="687" alt="" src="https://github.com/user-attachments/assets/5e854af1-5158-4c1e-b7ff-2b22ba319e14" />
<img width="321" height="687" alt="" src="https://github.com/user-attachments/assets/02bcb8a3-5afe-4923-80c0-372b7d261991" />
<img width="318" height="686" alt="" src="https://github.com/user-attachments/assets/417e7d78-a375-4138-8a3a-d406e7f7265c" />
<img width="321" height="687" alt="" src="https://github.com/user-attachments/assets/5f3d805e-e744-4928-b4bd-049a4d247583" />
<img width="321" height="686" alt="" src="https://github.com/user-attachments/assets/29f24b0e-91b2-46be-9c25-1dfc4194b6d7" />
<img width="321" height="686" alt="" src="https://github.com/user-attachments/assets/ee051243-d06b-4afd-ae11-4433d8cc9b8d" />




---

## Technical details

- Framework: Flutter
- Backend: Firebase (Auth + Firestore / Realtime DB / Storage as applicable)
- Languages: Dart
- Supported: Android (APK)
- Data stored per-user in Firebase under the user's UID

---

## Prerequisites

- Flutter SDK
- Android Studio
- An Android device / emulator
- Firebase project configured
