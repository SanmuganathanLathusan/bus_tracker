# Postman Collection Setup Guide

## Quick Setup

### 1. Environment Variables
Create a new environment in Postman with these variables:

| Variable | Initial Value | Current Value |
|----------|--------------|---------------|
| `base_url` | `http://localhost:5000/api` | `http://localhost:5000/api` |
| `token` | (empty) | (will be set automatically) |
| `user_id` | (empty) | (will be set automatically) |
| `admin_token` | (empty) | (will be set automatically) |
| `driver_token` | (empty) | (will be set automatically) |

### 2. Pre-request Script (for Login endpoints)
Add this script to login endpoints to automatically save the token:

```javascript
pm.test("Save token", function () {
    var jsonData = pm.response.json();
    if (jsonData.token) {
        pm.environment.set("token", jsonData.token);
        pm.environment.set("user_id", jsonData.user.id);
    }
});
```

### 3. Collection Structure

```
WayGo API
├── Authentication
│   ├── Register User
│   ├── Login
│   ├── Google Sign In
│   ├── Get Profile
│   └── Update Profile
├── News
│   ├── Get News (Public)
│   ├── Get All News (Admin)
│   ├── Create News (Admin)
│   ├── Update News (Admin)
│   └── Delete News (Admin)
├── Routes
│   ├── Search Routes
│   ├── Get All Routes
│   ├── Create Route (Admin)
│   ├── Update Route (Admin)
│   └── Delete Route (Admin)
├── Reservations
│   ├── Create Reservation
│   ├── Confirm Reservation with Payment
│   ├── Get My Reservations
│   ├── Get Reservation by ID
│   └── Validate Ticket
├── Payments
│   ├── Get My Payments
│   └── Get Payment by ID
├── Bus
│   ├── Update Location (Driver)
│   ├── Toggle Location Sharing (Driver)
│   ├── Get Bus Location
│   ├── Get All Buses (Admin)
│   ├── Create Bus (Admin)
│   └── Assign Driver to Bus (Admin)
├── Driver
│   ├── Start Trip
│   ├── Pause Trip
│   ├── Resume Trip
│   ├── End Trip
│   ├── Update Trip Status
│   ├── Get Driver Trips
│   ├── Get Driver Assignments
│   ├── Respond to Assignment
│   ├── Get Trip Passengers
│   ├── Mark Passenger Status
│   └── Get Driver Performance
├── Maintenance
│   ├── Create Report
│   ├── Submit Report
│   ├── Get My Reports
│   ├── Get Report by ID
│   ├── Get All Reports (Admin)
│   └── Resolve Report (Admin)
├── Feedback
│   ├── Create Feedback
│   ├── Get My Feedback
│   ├── Get All Feedback (Admin)
│   ├── Get Feedback by ID
│   └── Review Feedback (Admin)
├── Notifications
│   ├── Get Notifications
│   ├── Mark as Read
│   ├── Mark All as Read
│   ├── Delete Notification
│   └── Create Notification (Admin)
├── Admin
│   ├── Get Overview
│   ├── Get All Users
│   ├── Update User Status
│   ├── Delete User
│   ├── Create Assignment
│   ├── Get All Assignments
│   └── Get Buses for Tracking
└── Pricing
    ├── Get All Pricings
    ├── Get Pricing Stats (Admin)
    ├── Create Pricing (Admin)
    ├── Update Pricing (Admin)
    └── Delete Pricing (Admin)
```

## Sample Request Examples

### 1. Register User
```
POST {{base_url}}/auth/register
Content-Type: application/json

{
  "userType": "passenger",
  "userName": "John Doe",
  "phone": "+1234567890",
  "email": "john@example.com",
  "password": "password123"
}
```

### 2. Login
```
POST {{base_url}}/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}
```

### 3. Search Routes
```
GET {{base_url}}/routes/search?start=Colombo&destination=Kandy&date=2025-01-20
```

### 4. Create Reservation
```
POST {{base_url}}/reservations
Authorization: Bearer {{token}}
Content-Type: application/json

{
  "routeId": "route_id_here",
  "seats": [10, 11, 12],
  "date": "2025-01-20"
}
```

### 5. Confirm Reservation with Payment
```
POST {{base_url}}/reservations/confirm
Authorization: Bearer {{token}}
Content-Type: application/json

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

### 6. Update Profile (with image)
```
PUT {{base_url}}/auth/profile
Authorization: Bearer {{token}}
Content-Type: multipart/form-data

userName: John Updated
phone: +1234567891
profileImage: (select file)
```

### 7. Create Maintenance Report
```
POST {{base_url}}/maintenance
Authorization: Bearer {{driver_token}}
Content-Type: multipart/form-data

busId: bus_id_here
issueType: engine
description: Engine making strange noise
image: (select file)
```

### 8. Get Admin Overview
```
GET {{base_url}}/admin/overview
Authorization: Bearer {{admin_token}}
```

## Testing Workflow

### For Passenger:
1. Register → Login → Save token
2. Get News
3. Search Routes
4. Create Reservation
5. Confirm with Payment
6. Get My Reservations
7. Get My Payments

### For Driver:
1. Register as driver → Login → Save driver_token
2. Get Driver Assignments
3. Respond to Assignment (accept)
4. Start Trip
5. Update Location
6. Get Trip Passengers
7. Mark Passenger Status
8. End Trip
9. Create Maintenance Report
10. Get Driver Performance

### For Admin:
1. Register as admin → Login → Save admin_token
2. Get Overview
3. Create Bus
4. Create Route
5. Create Assignment
6. Get All Users
7. Create News
8. Get All Feedback
9. Get All Maintenance Reports
10. Get Buses for Tracking

## Common Issues

1. **401 Unauthorized**: Make sure token is set and included in Authorization header
2. **403 Forbidden**: Check user type (admin/driver/passenger)
3. **404 Not Found**: Verify the resource ID exists
4. **400 Bad Request**: Check request body format and required fields
5. **File Upload Issues**: Use `multipart/form-data` for file uploads

## Tips

- Use Postman's "Tests" tab to automatically save tokens
- Use collection variables for reusable IDs
- Use environment variables for different environments (dev, staging, prod)
- Export your collection and environment for backup

