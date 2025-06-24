# 🏠 Home Rental UITM - Flutter App  

📱 **A full-featured mobile application for UITM students to discover, list, and manage rental properties seamlessly.**  


---

## ✨ Key Features  

### **For Students/Tenants**  
🔍 **Browse Listings**  
- Filter by location, price range, and property type  
- View property details with high-quality images  

📱 **User Profiles**  
- Manage personal information  
- View rental history  and notification from admin or from new listing

📝 **List Properties**  
- Add property details, photos, and pricing  
- Edit or remove listings anytime  

🔔 **Notifications**  
- Get alerts for new inquiries  
- Application status updates  

### **For Admins**  
🛡️ **Moderation Dashboard**  
- Manage user accounts
- Manage listings 
- Generate reports  

📊 **Analytics**  
- View rental trends  
- Export data to PDF  


## 🛠️ Installation Guide  

### **Prerequisites**  
- Flutter SDK (version 3.0.0 or higher)  
- Android Studio/Xcode (for emulators)  
- Firebase account (if using Firebase services)  

### **Setup Instructions**  

1. **Clone the Repository**  
   ```bash
   git clone https://github.com/mengucop/homerental_uitm.git
   cd homerental_uitm
   ```

2. **Install Dependencies**  
   ```bash
   flutter pub get
   ```

3. **Configure Firebase (If Applicable)**  
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)  
   - Enable Firebase Auth and Firestore in Firebase console  

4. **Run the App**  
   ```bash
   flutter run
   ```

---

## 📂 Project Structure  

```
lib/
├── main.dart          # App entry point
├── models/            # Data models
├── services/          # API/Firebase services
├── utils/             # Helper functions
├── widgets/           # Reusable components
└── screens/           # All application screens
    ├── auth/          # Authentication flows
    ├── admin/         # Admin features
    └── user/          # User features
```

---

## 🤝 Contributing  

We welcome contributions! Please follow these steps:  

1. Fork the project  
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)  
3. Commit your changes (`git commit -m 'Add some amazing feature'`)  
4. Push to the branch (`git push origin feature/AmazingFeature`)  
5. Open a Pull Request  

---

## 📜 License  

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.  

---

## 📞 Contact  me if you have any questions
