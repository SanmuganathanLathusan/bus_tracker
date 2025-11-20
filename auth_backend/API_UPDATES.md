# API Updates for News and Bus/Driver Assignment

## News Management Updates

### 1. Get News (Passenger) - Updated
**GET** `/api/news`

Now returns formatted data compatible with Flutter app:
- Filters by publish date and expiry date
- Returns only Published/Active news
- Includes formatted date fields

**Response:**
```json
[
  {
    "_id": "...",
    "title": "WayGo App Update Released!",
    "description": "The latest update improves...",
    "imageUrl": "https://...",
    "type": "Info",
    "status": "Published",
    "date": "2025-01-15T10:00:00Z",
    "publishDate": "2025-01-15T10:00:00Z",
    "expiryDate": "2025-12-31T23:59:59Z",
    "postedBy": "Admin"
  }
]
```

### 2. Get News by ID (Admin) - New
**GET** `/api/news/admin/:id`

**Headers:** `Authorization: Bearer <admin_token>`

Get detailed news information for admin to view/edit.

---

## Bus and Driver Assignment Updates

### 1. Get Bus and Driver Statistics - New
**GET** `/api/admin/buses-drivers/stats`

**Headers:** `Authorization: Bearer <admin_token>`

Returns comprehensive statistics and lists of buses and drivers.

**Response:**
```json
{
  "stats": {
    "totalBuses": 10,
    "activeBuses": 8,
    "totalDrivers": 12,
    "activeDrivers": 8
  },
  "buses": [
    {
      "_id": "...",
      "busNumber": "SP-1234",
      "busName": "WayGo Deluxe",
      "driverId": {
        "_id": "...",
        "userName": "John Doe",
        "email": "john@example.com",
        "phone": "+1234567890",
        "licenseNumber": "DL-12345"
      },
      "totalSeats": 40,
      "isActive": true
    }
  ],
  "drivers": [
    {
      "_id": "...",
      "userName": "John Doe",
      "email": "john@example.com",
      "phone": "+1234567890",
      "licenseNumber": "DL-12345",
      "busId": {
        "_id": "...",
        "busNumber": "SP-1234",
        "busName": "WayGo Deluxe",
        "totalSeats": 40
      }
    }
  ]
}
```

### 2. Get Available Buses - New
**GET** `/api/admin/buses/available?scheduledDate=2025-01-20`

**Headers:** `Authorization: Bearer <admin_token>`

**Query Params:**
- `scheduledDate` (optional): Check availability for specific date

**Response:**
```json
{
  "available": [
    {
      "_id": "...",
      "busNumber": "SP-1234",
      "busName": "WayGo Deluxe",
      "driverId": { ... },
      "totalSeats": 40,
      "isActive": true
    }
  ],
  "assigned": [
    {
      "_id": "...",
      "busNumber": "SP-5678",
      "busName": "WayGo Express",
      "driverId": { ... },
      "totalSeats": 40,
      "isActive": true
    }
  ],
  "total": 10
}
```

### 3. Get Available Drivers - New
**GET** `/api/admin/drivers/available?scheduledDate=2025-01-20`

**Headers:** `Authorization: Bearer <admin_token>`

**Query Params:**
- `scheduledDate` (optional): Check availability for specific date

**Response:**
```json
{
  "available": [
    {
      "_id": "...",
      "userName": "John Doe",
      "email": "john@example.com",
      "phone": "+1234567890",
      "licenseNumber": "DL-12345",
      "busId": { ... }
    }
  ],
  "assigned": [
    {
      "_id": "...",
      "userName": "Jane Smith",
      "email": "jane@example.com",
      "phone": "+1234567891",
      "licenseNumber": "DL-67890",
      "busId": { ... }
    }
  ],
  "total": 12
}
```

### 4. Create Assignment - Enhanced
**POST** `/api/admin/assignments`

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

**Enhanced Features:**
- Validates all inputs
- Checks if driver/bus/route exist and are active
- Prevents conflicting assignments (same driver or bus on same date)
- Returns populated assignment with all details

**Response:**
```json
{
  "message": "Assignment created successfully",
  "assignment": {
    "_id": "...",
    "driverId": {
      "_id": "...",
      "userName": "John Doe",
      "email": "john@example.com",
      "phone": "+1234567890"
    },
    "busId": {
      "_id": "...",
      "busNumber": "SP-1234",
      "busName": "WayGo Deluxe"
    },
    "routeId": {
      "_id": "...",
      "start": "Colombo",
      "destination": "Kandy",
      "departure": "08:30 AM",
      "arrival": "12:15 PM"
    },
    "scheduledDate": "2025-01-20T00:00:00Z",
    "scheduledTime": "08:30 AM",
    "status": "pending",
    "assignedBy": {
      "_id": "...",
      "userName": "Admin"
    },
    "createdAt": "2025-01-15T10:00:00Z"
  }
}
```

---

## Driver Assignment Flow

1. **Admin creates assignment:**
   - `POST /api/admin/assignments`
   - Assignment created with status "pending"

2. **Driver views assignments:**
   - `GET /api/driver/assignments`
   - Returns all assignments for the driver

3. **Driver accepts/rejects:**
   - `POST /api/driver/assignments/respond`
   - Body: `{ "assignmentId": "...", "response": "reason", "status": "accepted|rejected" }`
   - Status updated to "accepted" or "rejected"

4. **Driver starts trip:**
   - `POST /api/driver/trip/start`
   - Body: `{ "assignmentId": "..." }`
   - Trip created with status "started"

---

## Testing Flow

### For News:
1. Admin creates news: `POST /api/news/admin`
2. Admin views all news: `GET /api/news/admin/all`
3. Admin views specific news: `GET /api/news/admin/:id`
4. Admin updates news: `PUT /api/news/admin/:id`
5. Admin deletes news: `DELETE /api/news/admin/:id`
6. Passenger views published news: `GET /api/news`

### For Assignments:
1. Admin gets stats: `GET /api/admin/buses-drivers/stats`
2. Admin gets available buses: `GET /api/admin/buses/available?scheduledDate=2025-01-20`
3. Admin gets available drivers: `GET /api/admin/drivers/available?scheduledDate=2025-01-20`
4. Admin creates assignment: `POST /api/admin/assignments`
5. Driver views assignments: `GET /api/driver/assignments`
6. Driver responds: `POST /api/driver/assignments/respond`
7. Driver starts trip: `POST /api/driver/trip/start`

---

## Notes

- All dates should be in ISO format: `YYYY-MM-DD` or `YYYY-MM-DDTHH:mm:ssZ`
- Assignment conflicts are automatically prevented
- Available buses/drivers are filtered based on scheduled date
- News is filtered by publish date and expiry date for passengers

