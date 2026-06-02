# 🚌 WayGo – Smart Real-Time Bus Tracking Platform

<p align="center">
  <img src="assets/logo.png" alt="WayGo Logo" width="180">
</p>

<p align="center">
  <a href="https://youtu.be/uUI3g-0C7OE">
    <img src="https://img.shields.io/badge/▶️_Demo-Watch_Now-red?style=for-the-badge&logo=youtube&logoColor=white" alt="Demo">
  </a>
  <a href="GITHUB_REPOSITORY_LINK">
    <img src="https://img.shields.io/badge/GitHub-Repository-black?style=for-the-badge&logo=github&logoColor=white" alt="Repository">
  </a>
  <img src="https://img.shields.io/badge/Flutter-Mobile_App-02569B?style=for-the-badge&logo=flutter&logoColor=white">
  <img src="https://img.shields.io/badge/Node.js-Backend-339933?style=for-the-badge&logo=nodedotjs&logoColor=white">
  <img src="https://img.shields.io/badge/MongoDB-Database-47A248?style=for-the-badge&logo=mongodb&logoColor=white">
</p>

<p align="center">
  <strong>Real-Time Bus Tracking • Smart Route Management • Better Public Transportation</strong>
</p>

---

## 📖 Overview

**WayGo** is a modern real-time bus tracking platform designed to improve public transportation experiences for passengers, drivers, and transport administrators.

The application enables users to track buses live on an interactive map, view route information, estimate arrival times, and receive accurate transportation updates. Administrators can efficiently manage buses, drivers, and routes through a centralized management system.

WayGo aims to make public transportation more reliable, transparent, and efficient through the power of GPS technology and real-time data synchronization.

---

## ✨ Key Features

### 🚌 Real-Time Bus Tracking

Track buses live using GPS-based location updates displayed on an interactive map.

### ⏱️ Estimated Arrival Time (ETA)

Receive intelligent arrival predictions based on current vehicle locations and route progress.

### 🗺️ Route & Bus Stop Information

View complete route details, bus stop locations, and transportation schedules.

### 👨‍✈️ Driver Management

Assign drivers to buses and monitor active vehicle operations.

### 🏢 Admin Dashboard

Manage routes, buses, drivers, and transportation data from a centralized panel.

### 🔐 Secure Authentication

Role-based authentication and authorization for passengers, drivers, and administrators.

### 📱 Cross-Platform Mobile Experience

Built with Flutter to provide a smooth and responsive experience across Android and iOS devices.

### ☁️ Scalable Backend Infrastructure

Powered by Node.js and MongoDB for high performance and scalability.

---

## 🎥 Demo Video

Watch the complete project demonstration here:

🔗 **Demo Video:** `ADD_YOUR_VIDEO_LINK_HERE`

---

## 📸 Screenshots

### Home Screen

![Home Screen](screenshots/home.png)

### Live Bus Tracking

![Tracking Screen](screenshots/tracking.png)

### Route Information

![Route Screen](screenshots/routes.png)

### Admin Dashboard

![Admin Dashboard](screenshots/admin.png)

---

## 🛠️ Technology Stack

### Frontend (Mobile Application)

| Technology      | Purpose                           |
| --------------- | --------------------------------- |
| Flutter         | Cross-platform mobile development |
| Dart            | Programming language              |
| Google Maps API | Interactive map integration       |
| GPS Services    | Real-time location tracking       |

### Backend

| Technology | Purpose             |
| ---------- | ------------------- |
| Node.js    | Server runtime      |
| Express.js | Backend framework   |
| MongoDB    | Database            |
| JWT        | Authentication      |
| REST API   | Communication layer |

### External Services

| Service         | Usage                  |
| --------------- | ---------------------- |
| Google Maps API | Map rendering          |
| GPS Services    | Live location tracking |
| MongoDB Atlas   | Cloud database hosting |

---

## 🚀 Getting Started

### Prerequisites

Before running the project, ensure you have installed:

* Flutter SDK
* Dart SDK
* Node.js (v18 or later)
* MongoDB Atlas Account or Local MongoDB
* Google Maps API Key
* Git

---

## 📥 Installation

### Clone Repository

```bash
git clone YOUR_REPOSITORY_LINK
cd WayGo
```

---

## Backend Setup

Navigate to backend folder:

```bash
cd backend
```

Install dependencies:

```bash
npm install
```

Create a `.env` file:

```env
PORT=

MONGODB_URI=

JWT_SECRET=

GOOGLE_MAPS_API_KEY=
```

Run backend server:

```bash
npm run dev
```

Backend will start on:

```bash
http://localhost:5000
```

---

## Mobile Application Setup

Navigate to frontend folder:

```bash
cd frontend
```

Install Flutter dependencies:

```bash
flutter pub get
```

Run application:

```bash
flutter run
```

---

## 📂 Project Structure

```text
WayGo/
│
├── frontend/
│   ├── lib/
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── services/
│   │   ├── models/
│   │   └── main.dart
│   │
│   ├── assets/
│   └── pubspec.yaml
│
├── backend/
│   ├── src/
│   │   ├── controllers/
│   │   ├── middleware/
│   │   ├── models/
│   │   ├── routes/
│   │   ├── services/
│   │   └── config/
│   │
│   ├── server.js
│   └── .env
│
├── screenshots/
├── README.md
└── package.json
```

---

## ⚙️ System Workflow

### Driver Side

1. Driver logs into the mobile application.
2. GPS location is captured continuously.
3. Location updates are sent to the backend server.

### Backend Processing

1. Server receives GPS coordinates.
2. Location data is stored in MongoDB.
3. Route information is processed.
4. ETA calculations are generated.

### Passenger Side

1. Passenger opens the application.
2. Live bus locations are fetched.
3. Google Maps displays real-time movement.
4. ETA and route information are shown instantly.

---

## 🎯 Benefits

* Reduced passenger waiting time
* Improved transportation efficiency
* Accurate live tracking
* Better route planning
* Enhanced commuter experience
* Easy fleet management
* Real-time operational visibility

---

## 🔮 Future Enhancements

* 🔔 Push Notification Alerts
* 💳 Online Ticket Booking
* 📶 Offline Route Support
* 🤖 AI-Based Traffic Prediction
* 📊 Advanced Analytics Dashboard
* 🌍 Multi-Language Support
* ⭐ Passenger Feedback System
* 📈 Route Optimization Engine

---

## 👨‍💻 Development Team

| Team Member   | Role                 | GitHub              |
| ------------- | -------------------- | ------------------- |
| Lathusan Shanmuganathan | Software Engineer    | [GitHub Profile Link](https://github.com/SanmuganathanLathusan) |
| M.N.M.Rukshan| Software Engineer    | [GitHub Profile Link ](https://github.com/mnmrukshan)|
| TharukaThennakoon| Software Engineer    | [GitHub Profile Link(https://github.com/TharukaThennakoon) |

---

## 🤝 Contributing

Contributions are welcome and appreciated.

1. Fork the repository
2. Create a feature branch

```bash
git checkout -b feature-name
```

3. Commit your changes

```bash
git commit -m "Add new feature"
```

4. Push to GitHub

```bash
git push origin feature-name
```

5. Open a Pull Request

---

## 📬 Contact

For inquiries, suggestions, or collaboration opportunities:

📧 Email: [lathusanlathusan40@gmail.com](mailto:lathusanlathusan40@gmail.com)

🔗 GitHub Repository: https://github.com/SanmuganathanLathusan/bus_tracker


---

## 📄 License

This project is licensed under the MIT License.

See the LICENSE file for additional information.

---

## ⭐ Support

If you found this project useful, please consider giving it a star on GitHub.

Your support helps improve and maintain the project.

---

<p align="center">
  <strong>🚌 WayGo – Transforming Public Transportation Through Technology</strong>
</p>

<p align="center">
  Built with ❤️ by the WayGo Development Team
</p>
