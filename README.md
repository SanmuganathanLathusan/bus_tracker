# <span style="color:#3B82F6; font-weight:700;">WayGo</span> — <span style="color:#10B981;">Real-Time Bus Tracking App</span>

WayGo is a real-time bus tracking application that helps passengers and transport operators monitor buses live, plan trips efficiently, and ensure timely travel experiences.

This system uses:
- **<span style="color:#EAB308;">Flutter</span>** for the mobile app
- **<span style="color:#F97316;">Node.js + Express.js</span>** for backend services
- **<span style="color:#4ADE80;">MongoDB</span>** for database operations

---

## <span style="color:#3B82F6;">🚍 Key Features</span>

| Feature | Description |
|--------|-------------|
| **<span style="color:#10B981;">Live Bus Tracking</span>** | Real-time bus location updates on map |
| **<span style="color:#9333EA;">Estimated Arrival Times</span>** | Accurate ETA predictions based on live movement |
| **<span style="color:#E11D48;">Route & Stop Information</span>** | Displays complete route path & bus stops |
| **<span style="color:#2563EB;">Admin / Driver Panel</span>** | Assign drivers, manage buses, update status |
| **<span style="color:#EA580C;">Secure Backend API</span>** | Built for speed and scalability |

---

## <span style="color:#10B981;">🛠️ Tech Stack</span>

| Layer | Technology |
|------|------------|
| **Frontend** | Flutter, Dart |
| **Backend API** | Node.js, Express.js |
| **Database** | MongoDB |
| **Live Location Updates** | Google Maps API / GPS Services |

---

## <span style="color:#9333EA;">📂 Project Structure</span>

WayGo
│
├── mobile-app (Flutter)
│ ├── lib
│ ├── assets
│ └── pubspec.yaml
│
├── server (Node.js Backend)
│ ├── src
│ ├── models
│ ├── routes
│ └── .env
│
└── database (MongoDB Collections)

---

## <span style="color:#F97316;">▶️ How It Works</span>

1. Driver app/device sends **GPS coordinates** to backend.
2. Backend stores and updates location in **MongoDB**.
3. Passenger app polls or subscribes to location updates in real-time.
4. Map markers refresh to show bus movement continuously.

---

## <span style="color:#3B82F6;">🚀 Getting Started</span>

### 1. Clone the Repository

git clone https://github.com/your-repo/waygo.git
cd waygo
