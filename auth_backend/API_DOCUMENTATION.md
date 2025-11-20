# WayGo Backend API Documentation

## Base URL
```
http://localhost:5000/api
```

## Authentication
Most endpoints require authentication. Include the JWT token in the Authorization header:
```
Authorization: Bearer <your_token>
```

---

## 🔐 Authentication Endpoints

### 1. Register User
**POST** `/auth/register`

**Request Body:**
```json
{
  "userType": "passenger|driver|admin",
  "userName": "John Doe",
  "phone": "+1234567890",
  "email": "john@example.com",
  "password": "password123"
}
```

**Response (201):**
```json
{
  "message": "User registered successfully",
  "user": {
    "id": "...",
    "userType": "passenger",
    "userName": "John Doe",
    "email": "john@example.com"
  }
}
```

---

### 2. Login
**POST** `/auth/login`

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "...",
    "userType": "passenger",
    "userName": "John Doe",
    "email": "john@example.com"
  },
  "redirect": "/passenger-dashboard"
}
```

---

### 3. Google Sign In
**POST** `/auth/google-signin`

**Request Body:**
```json
{
  "googleToken": "google_id_token_here",
  "userType": "passenger"
}
```

**Response (200):** Same as login response

---

### 4. Get Profile
**GET** `/auth/profile`

**Headers:** `Authorization: Bearer <token>`

**Response (200):**
```json
{
  "user": {
    "id": "...",
    "userType": "passenger",
    "userName": "John Doe",
    "email": "john@example.com",
    "phone": "+1234567890",
    "profileImage": "uploads/profiles/profile-123.jpg"
  }
}
```

---

### 5. Update Profile
**PUT** `/auth/profile`

**Headers:** `Authorization: Bearer <token>`

**Request Body (multipart/form-data):**
- `userName` (optional)
- `phone` (optional)
- `profileImage` (file, optional)

**Response (200):**
```json
{
  "message": "Profile updated successfully",
  "user": { ... }
}
```

---

## 📰 News Endpoints

### 1. Get News (Public - for passengers)
**GET** `/news`

**Response (200):**
```json
[
  {
    "_id": "...",
    "title": "WayGo App Update Released!",
    "description": "The latest update improves performance...",
    "imageUrl": "https://...",
    "type": "Info",
    "status": "Published",
    "date": "2025-01-15T10:00:00Z"
  }
]
```

---

### 2. Get All News (Admin)
**GET** `/news/admin/all`

**Headers:** `Authorization: Bearer <admin_token>`

**Response (200):** Array of all news (including drafts)

---

### 3. Create News (Admin)
**POST** `/news/admin`

**Headers:** `Authorization: Bearer <admin_token>`

**Request Body:**
```json
{
  "title": "New Route Added",
  "description": "We've added a new route from Colombo to Kandy",
  "imageUrl": "https://...",
  "type": "Info",
  "publishDate": "2025-01-20",
  "expiryDate": "2025-12-31"
}
```

---

### 4. Update News (Admin)
**PUT** `/news/admin/:id`

**Headers:** `Authorization: Bearer <admin_token>`

**Request Body:** Same as create

---

### 5. Delete News (Admin)
**DELETE** `/news/admin/:id`

**Headers:** `Authorization: Bearer <admin_token>`

---

## 🚌 Route Endpoints

### 1. Search Routes
**GET** `/routes/search?start=Colombo&destination=Kandy&date=2025-01-20`

**Response (200):**
```json
[
  {
    "_id": "...",
    "start": "Colombo",
    "destination": "Kandy",
    "departure": "08:30 AM",
    "arrival": "12:15 PM",
    "duration": "3h 45m",
    "busName": "WayGo Comfort Liner",
    "price": 500,
    "totalSeats": 40,
    "bookedSeats": [2, 5, 7],
    "availableSeats": 37
  }
]
```

---

### 2. Get All Routes
**GET** `/routes`

**Response (200):** Array of all active routes

---

### 3. Create Route (Admin)
**POST** `/routes/admin`

**Headers:** `Authorization: Bearer <admin_token>`

**Request Body:**
```json
{
  "start": "Colombo",
  "destination": "Kandy",
  "departure": "08:30 AM",
  "arrival": "12:15 PM",
  "duration": "3h 45m",
  "busId": "bus_id_here",
  "price": 500
}
```

---

### 4. Update Route (Admin)
**PUT** `/routes/admin/:id`

**Headers:** `Authorization: Bearer <admin_token>`

---

### 5. Delete Route (Admin)
**DELETE** `/routes/admin/:id`

**Headers:** `Authorization: Bearer <admin_token>`

---

## 🎫 Reservation Endpoints

### 1. Create Reservation
**POST** `/reservations`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "routeId": "route_id_here",
  "seats": [10, 11, 12],
  "date": "2025-01-20"
}
```

**Response (201):**
```json
{
  "message": "Reservation created successfully",
  "reservation": {
    "_id": "...",
    "userId": "...",
    "routeId": "...",
    "seats": [10, 11, 12],
    "status": "reserved",
    "totalAmount": 1500,
    "ticketId": "TKT-1234567890-ABCD"
  }
}
```

---

### 2. Confirm Reservation with Payment
**POST** `/reservations/confirm`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "reservationId": "reservation_id_here",
  "cardDetails": {
    "cardNumber": "1234567890123456",
    "cardType": "visa",
    "name": "John Doe",
    "expiry": "12/25",
    "cvv": "123"
  }
}
```

**Response (200):**
```json
{
  "message": "Payment successful and ticket confirmed",
  "reservation": { ... },
  "payment": { ... },
  "qrCode": "data:image/png;base64,iVBORw0KGgo..."
}
```

---

### 3. Get User Reservations
**GET** `/reservations/my-reservations`

**Headers:** `Authorization: Bearer <token>`

**Response (200):** Array of user's reservations

---

### 4. Get Reservation by ID
**GET** `/reservations/:id`

**Headers:** `Authorization: Bearer <token>`

---

### 5. Validate Ticket (Driver/Admin)
**POST** `/reservations/validate`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "ticketId": "TKT-1234567890-ABCD"
}
```

**Response (200):**
```json
{
  "valid": true,
  "reservation": {
    "ticketId": "TKT-1234567890-ABCD",
    "seats": [10, 11, 12],
    "userId": { ... },
    "routeId": { ... }
  }
}
```

---

## 💳 Payment Endpoints

### 1. Get User Payments
**GET** `/payments/my-payments`

**Headers:** `Authorization: Bearer <token>`

**Response (200):** Array of user's payments

---

### 2. Get Payment by ID
**GET** `/payments/:id`

**Headers:** `Authorization: Bearer <token>`

---

## 🚍 Bus Endpoints

### 1. Update Bus Location (Driver)
**POST** `/bus/update-location`

**Headers:** `Authorization: Bearer <driver_token>`

**Request Body:**
```json
{
  "busId": "bus_id_here",
  "lat": 6.9271,
  "lng": 79.8612
}
```

---

### 2. Toggle Location Sharing (Driver)
**POST** `/bus/toggle-sharing`

**Headers:** `Authorization: Bearer <driver_token>`

**Request Body:**
```json
{
  "busId": "bus_id_here",
  "isSharing": true
}
```

---

### 3. Get Bus Location
**GET** `/bus/:busId`

**Response (200):**
```json
{
  "busId": "...",
  "busNumber": "SP-1234",
  "location": {
    "lat": 6.9271,
    "lng": 79.8612,
    "updatedAt": "2025-01-15T10:00:00Z"
  }
}
```

---

### 4. Get All Buses (Admin)
**GET** `/bus/admin/all`

**Headers:** `Authorization: Bearer <admin_token>`

---

### 5. Create Bus (Admin)
**POST** `/bus/admin`

**Headers:** `Authorization: Bearer <admin_token>`

**Request Body:**
```json
{
  "busNumber": "SP-1234",
  "busName": "WayGo Deluxe",
  "totalSeats": 40,
  "busType": "deluxe"
}
```

---

### 6. Assign Driver to Bus (Admin)
**POST** `/bus/admin/assign-driver`

**Headers:** `Authorization: Bearer <admin_token>`

**Request Body:**
```json
{
  "busId": "bus_id_here",
  "driverId": "driver_id_here"
}
```

---

## 👨‍✈️ Driver Endpoints

### 1. Start Trip
**POST** `/driver/trip/start`

**Headers:** `Authorization: Bearer <driver_token>`

**Request Body:**
```json
{
  "assignmentId": "assignment_id_here"
}
```

**Response (200):**
```json
{
  "message": "Trip started successfully",
  "trip": {
    "_id": "...",
    "status": "started",
    "startTime": "2025-01-15T10:00:00Z"
  }
}
```

---

### 2. Pause Trip
**POST** `/driver/trip/pause`

**Headers:** `Authorization: Bearer <driver_token>`

**Request Body:**
```json
{
  "tripId": "trip_id_here",
  "reason": "Traffic delay"
}
```

---

### 3. Resume Trip
**POST** `/driver/trip/resume`

**Headers:** `Authorization: Bearer <driver_token>`

**Request Body:**
```json
{
  "tripId": "trip_id_here"
}
```

---

### 4. End Trip
**POST** `/driver/trip/end`

**Headers:** `Authorization: Bearer <driver_token>`

**Request Body:**
```json
{
  "tripId": "trip_id_here"
}
```

---

### 5. Update Trip Status
**PUT** `/driver/trip/status`

**Headers:** `Authorization: Bearer <driver_token>`

**Request Body:**
```json
{
  "tripId": "trip_id_here",
  "status": "started|paused|completed",
  "delayReason": "Optional delay reason",
  "emergencyReport": "Optional emergency report"
}
```

---

### 6. Get Driver Trips
**GET** `/driver/trips`

**Headers:** `Authorization: Bearer <driver_token>`

**Response (200):** Array of driver's trips

---

### 7. Get Driver Assignments
**GET** `/driver/assignments`

**Headers:** `Authorization: Bearer <driver_token>`

**Response (200):** Array of driver's assignments

---

### 8. Respond to Assignment
**POST** `/driver/assignments/respond`

**Headers:** `Authorization: Bearer <driver_token>`

**Request Body:**
```json
{
  "assignmentId": "assignment_id_here",
  "response": "accepted",
  "status": "accepted|rejected"
}
```

---

### 9. Get Trip Passengers
**GET** `/driver/trip/:tripId/passengers`

**Headers:** `Authorization: Bearer <driver_token>`

**Response (200):** Array of passengers for the trip

---

### 10. Mark Passenger Status
**POST** `/driver/passenger/status`

**Headers:** `Authorization: Bearer <driver_token>`

**Request Body:**
```json
{
  "reservationId": "reservation_id_here",
  "status": "boarded|absent"
}
```

---

### 11. Get Driver Performance
**GET** `/driver/performance`

**Headers:** `Authorization: Bearer <driver_token>`

**Response (200):**
```json
{
  "totalTrips": 50,
  "totalPassengers": 1200,
  "averageRating": "4.7",
  "recentRatings": [ ... ]
}
```

---

## 🔧 Maintenance Endpoints

### 1. Create Maintenance Report
**POST** `/maintenance`

**Headers:** `Authorization: Bearer <driver_token>`

**Request Body (multipart/form-data):**
- `busId` (required)
- `issueType` (required): "engine|brakes|tires|ac|electrical|other"
- `description` (required)
- `image` (file, optional)

---

### 2. Submit Report to Admin
**POST** `/maintenance/:reportId/submit`

**Headers:** `Authorization: Bearer <driver_token>`

---

### 3. Get Driver Reports
**GET** `/maintenance/my-reports`

**Headers:** `Authorization: Bearer <driver_token>`

---

### 4. Get Report by ID
**GET** `/maintenance/:id`

**Headers:** `Authorization: Bearer <token>`

---

### 5. Get All Reports (Admin)
**GET** `/maintenance/admin/all?status=pending`

**Headers:** `Authorization: Bearer <admin_token>`

**Query Params:**
- `status` (optional): "pending|resolved|unsent"

---

### 6. Resolve Report (Admin)
**PUT** `/maintenance/admin/:id/resolve`

**Headers:** `Authorization: Bearer <admin_token>`

---

## 💬 Feedback Endpoints

### 1. Create Feedback
**POST** `/feedback`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "type": "delay|emergency|general|complaint|suggestion",
  "subject": "Service Delay",
  "message": "The bus was delayed by 30 minutes"
}
```

---

### 2. Get User Feedback
**GET** `/feedback/my-feedback`

**Headers:** `Authorization: Bearer <token>`

---

### 3. Get All Feedback (Admin)
**GET** `/feedback/admin/all?userType=passenger&status=pending`

**Headers:** `Authorization: Bearer <admin_token>`

**Query Params:**
- `userType` (optional): "passenger|driver"
- `status` (optional): "pending|reviewed|resolved"
- `type` (optional): "delay|emergency|general|complaint|suggestion"

---

### 4. Get Feedback by ID
**GET** `/feedback/:id`

**Headers:** `Authorization: Bearer <token>`

---

### 5. Review Feedback (Admin)
**PUT** `/feedback/admin/:id/review`

**Headers:** `Authorization: Bearer <admin_token>`

**Request Body:**
```json
{
  "status": "reviewed|resolved"
}
```

---

## 🔔 Notification Endpoints

### 1. Get User Notifications
**GET** `/notifications?type=Alert&isRead=false`

**Headers:** `Authorization: Bearer <token>`

**Query Params:**
- `type` (optional): "Alert|Update|Info"
- `isRead` (optional): "true|false"

**Response (200):**
```json
{
  "notifications": [ ... ],
  "unreadCount": 5
}
```

---

### 2. Mark as Read
**PUT** `/notifications/:id/read`

**Headers:** `Authorization: Bearer <token>`

---

### 3. Mark All as Read
**PUT** `/notifications/read-all`

**Headers:** `Authorization: Bearer <token>`

---

### 4. Delete Notification
**DELETE** `/notifications/:id`

**Headers:** `Authorization: Bearer <token>`

---

### 5. Create Notification (Admin)
**POST** `/notifications`

**Headers:** `Authorization: Bearer <admin_token>`

**Request Body:**
```json
{
  "userId": "user_id_here (optional)",
  "userType": "passenger|driver|admin|all",
  "type": "Alert",
  "title": "Traffic Alert",
  "message": "Traffic ahead on Route 5",
  "icon": "warning",
  "iconColor": "orange"
}
```

---

## 👨‍💼 Admin Endpoints

### 1. Get Overview
**GET** `/admin/overview`

**Headers:** `Authorization: Bearer <admin_token>`

**Response (200):**
```json
{
  "totalUsers": 150,
  "totalPassengers": 120,
  "totalDrivers": 25,
  "totalBuses": 30,
  "activeTrips": 5,
  "totalReservations": 500,
  "totalRevenue": 250000
}
```

---

### 2. Get All Users
**GET** `/admin/users?userType=passenger&isActive=true`

**Headers:** `Authorization: Bearer <admin_token>`

**Query Params:**
- `userType` (optional): "passenger|driver|admin"
- `isActive` (optional): "true|false"

---

### 3. Update User Status
**PUT** `/admin/users/:id/status`

**Headers:** `Authorization: Bearer <admin_token>`

**Request Body:**
```json
{
  "isActive": false
}
```

---

### 4. Delete User
**DELETE** `/admin/users/:id`

**Headers:** `Authorization: Bearer <admin_token>`

---

### 5. Create Assignment
**POST** `/admin/assignments`

**Headers:** `Authorization: Bearer <admin_token>`

**Request Body:**
```json
{
  "driverId": "driver_id_here",
  "busId": "bus_id_here",
  "routeId": "route_id_here",
  "scheduledDate": "2025-01-20",
  "scheduledTime": "08:30 AM"
}
```

---

### 6. Get All Assignments
**GET** `/admin/assignments`

**Headers:** `Authorization: Bearer <admin_token>`

---

### 7. Get Buses for Tracking
**GET** `/admin/tracking/buses?busId=SP-1234`

**Headers:** `Authorization: Bearer <admin_token>`

**Response (200):**
```json
[
  {
    "_id": "...",
    "busNumber": "SP-1234",
    "busName": "WayGo Deluxe",
    "driverId": { ... },
    "currentLocation": { ... },
    "isLocationSharing": true,
    "trip": {
      "status": "started",
      "routeId": { ... }
    },
    "status": "started"
  }
]
```

---

## 💰 Pricing Endpoints

### 1. Get All Pricings
**GET** `/pricing`

**Response (200):** Array of all active pricings

---

### 2. Get Pricing Statistics (Admin)
**GET** `/pricing/admin/stats`

**Headers:** `Authorization: Bearer <admin_token>`

**Response (200):**
```json
{
  "totalRoutes": 25,
  "totalPricings": 25,
  "averagePrice": 450.50
}
```

---

### 3. Create Pricing (Admin)
**POST** `/pricing/admin`

**Headers:** `Authorization: Bearer <admin_token>`

**Request Body:**
```json
{
  "routeId": "route_id_here",
  "start": "Colombo",
  "destination": "Kandy",
  "price": 500
}
```

---

### 4. Update Pricing (Admin)
**PUT** `/pricing/admin/:id`

**Headers:** `Authorization: Bearer <admin_token>`

**Request Body:**
```json
{
  "price": 550
}
```

---

### 5. Delete Pricing (Admin)
**DELETE** `/pricing/admin/:id`

**Headers:** `Authorization: Bearer <admin_token>`

---

## 📊 Dashboard Endpoints

### 1. Passenger Dashboard
**GET** `/dashboard/passenger-dashboard`

**Headers:** `Authorization: Bearer <passenger_token>`

---

### 2. Driver Dashboard
**GET** `/dashboard/driver-dashboard`

**Headers:** `Authorization: Bearer <driver_token>`

---

### 3. Admin Dashboard
**GET** `/dashboard/admin-dashboard`

**Headers:** `Authorization: Bearer <admin_token>`

---

## 🏥 Health Check

### Health Check
**GET** `/health`

**Response (200):**
```json
{
  "status": "OK",
  "message": "Server is running"
}
```

---

## Error Responses

### 400 Bad Request
```json
{
  "error": "Error message here"
}
```

### 401 Unauthorized
```json
{
  "error": "Access denied. No token provided."
}
```

### 403 Forbidden
```json
{
  "error": "Access denied. Admin access required."
}
```

### 404 Not Found
```json
{
  "error": "Resource not found"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error message"
}
```

---

## Testing with Postman

### Setup:
1. Import the environment variables:
   - `base_url`: `http://localhost:5000/api`
   - `token`: (will be set after login)

2. Create a collection with these folders:
   - Authentication
   - News
   - Routes
   - Reservations
   - Payments
   - Bus
   - Driver
   - Maintenance
   - Feedback
   - Notifications
   - Admin
   - Pricing

3. For authenticated requests:
   - Add header: `Authorization: Bearer {{token}}`
   - Set token variable after login

### Example Flow:
1. Register a user: `POST /auth/register`
2. Login: `POST /auth/login` → Save token
3. Get profile: `GET /auth/profile` (with token)
4. Search routes: `GET /routes/search?start=Colombo&destination=Kandy&date=2025-01-20`
5. Create reservation: `POST /reservations`
6. Confirm with payment: `POST /reservations/confirm`

---

## Notes:
- All dates should be in ISO format: `YYYY-MM-DD` or `YYYY-MM-DDTHH:mm:ssZ`
- File uploads use `multipart/form-data`
- QR codes are returned as base64 data URLs
- Location coordinates are in decimal degrees (lat, lng)
