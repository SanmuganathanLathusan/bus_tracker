# WayGo Backend API

Complete backend API for WayGo bus reservation system built with Node.js and Express.

## 🚀 Quick Start

**New to this project?** Start here:
1. Read [QUICK_START.md](./QUICK_START.md) for 5-minute setup
2. Read [SETUP_GUIDE.md](./SETUP_GUIDE.md) for detailed instructions
3. Read [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) if you have issues

## Features

- ✅ User Authentication (Email/Password & Google Sign In)
- ✅ News Feed Management
- ✅ Route & Bus Management
- ✅ Seat Reservation System
- ✅ Payment Processing with QR Code Generation
- ✅ Live Location Tracking
- ✅ Driver Trip Management
- ✅ Maintenance Reports
- ✅ Feedback System
- ✅ Notifications
- ✅ Admin Dashboard & Management
- ✅ Ticket Pricing Management

## Setup Instructions

> **⚠️ Important:** Make sure MongoDB is installed and running before starting the backend!

### 1. Install MongoDB

See [SETUP_GUIDE.md](./SETUP_GUIDE.md) for MongoDB installation instructions.

### 2. Install Dependencies

```bash
npm install
```

### 3. Environment Variables

Create a `.env` file in the root directory (copy from `.env.example` if available):

```env
# MongoDB Connection
MONGODB_URI=mongodb://localhost:27017/waygo

# JWT Secret
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production

# Server Port
PORT=5000

# Google OAuth (for Google Sign In)
GOOGLE_CLIENT_ID=your_google_client_id_here

# Server URL (for file serving)
BASE_URL=http://localhost:5000
```

### 4. Test Database Connection

```bash
npm run test-connection
```

### 5. Initialize Database (Optional - creates test users)

```bash
npm run init-db
```

This creates:
- Admin: `admin@waygo.com` / `admin123`
- Driver: `driver@waygo.com` / `driver123`
- Passenger: `passenger@waygo.com` / `passenger123`

### 6. Start the Server

```bash
# Development mode (with nodemon)
npm run dev

# Production mode
npm start
```

The server will start on `http://localhost:5000`

## API Documentation

See [API_DOCUMENTATION.md](./API_DOCUMENTATION.md) for complete API reference.

## Postman Testing

See [POSTMAN_COLLECTION.md](./POSTMAN_COLLECTION.md) for Postman setup guide.

## Project Structure

```
auth_backend/
├── config/
│   └── db.js              # MongoDB connection
├── controllers/
│   ├── adminController.js
│   ├── authController.js
│   ├── busController.js
│   ├── driverController.js
│   ├── feedbackController.js
│   ├── maintenanceController.js
│   ├── newsController.js
│   ├── notificationController.js
│   ├── paymentController.js
│   ├── pricingController.js
│   ├── reservationController.js
│   └── routeController.js
├── middleware/
│   └── authMiddleware.js  # JWT authentication
├── models/
│   ├── Assignment.js
│   ├── Bus.js
│   ├── Feedback.js
│   ├── Maintenance.js
│   ├── News.js
│   ├── Notification.js
│   ├── Payment.js
│   ├── Pricing.js
│   ├── Rating.js
│   ├── Reservation.js
│   ├── Route.js
│   ├── Trip.js
│   └── User.js
├── routes/
│   ├── adminRoutes.js
│   ├── auth.js
│   ├── bus.js
│   ├── driverRoutes.js
│   ├── feedbackRoutes.js
│   ├── maintenanceRoutes.js
│   ├── newsRoutes.js
│   ├── notificationRoutes.js
│   ├── paymentRoutes.js
│   ├── pricingRoutes.js
│   ├── reservationRoutes.js
│   └── routeRoutes.js
├── uploads/               # File uploads (auto-created)
│   ├── profiles/
│   └── maintenance/
├── server.js              # Main server file
└── package.json
```

## API Endpoints Summary

### Authentication
- `POST /api/auth/register` - Register user
- `POST /api/auth/login` - Login
- `POST /api/auth/google-signin` - Google sign in
- `GET /api/auth/profile` - Get profile
- `PUT /api/auth/profile` - Update profile

### News
- `GET /api/news` - Get published news (public)
- `GET /api/news/admin/all` - Get all news (admin)
- `POST /api/news/admin` - Create news (admin)
- `PUT /api/news/admin/:id` - Update news (admin)
- `DELETE /api/news/admin/:id` - Delete news (admin)

### Routes
- `GET /api/routes/search` - Search routes
- `GET /api/routes` - Get all routes
- `POST /api/routes/admin` - Create route (admin)
- `PUT /api/routes/admin/:id` - Update route (admin)
- `DELETE /api/routes/admin/:id` - Delete route (admin)

### Reservations
- `POST /api/reservations` - Create reservation
- `POST /api/reservations/confirm` - Confirm with payment
- `GET /api/reservations/my-reservations` - Get user reservations
- `GET /api/reservations/:id` - Get reservation by ID
- `POST /api/reservations/validate` - Validate ticket

### Payments
- `GET /api/payments/my-payments` - Get user payments
- `GET /api/payments/:id` - Get payment by ID

### Bus
- `POST /api/bus/update-location` - Update location (driver)
- `POST /api/bus/toggle-sharing` - Toggle location sharing (driver)
- `GET /api/bus/:busId` - Get bus location
- `GET /api/bus/admin/all` - Get all buses (admin)
- `POST /api/bus/admin` - Create bus (admin)
- `POST /api/bus/admin/assign-driver` - Assign driver (admin)

### Driver
- `POST /api/driver/trip/start` - Start trip
- `POST /api/driver/trip/pause` - Pause trip
- `POST /api/driver/trip/resume` - Resume trip
- `POST /api/driver/trip/end` - End trip
- `PUT /api/driver/trip/status` - Update trip status
- `GET /api/driver/trips` - Get driver trips
- `GET /api/driver/assignments` - Get assignments
- `POST /api/driver/assignments/respond` - Respond to assignment
- `GET /api/driver/trip/:tripId/passengers` - Get trip passengers
- `POST /api/driver/passenger/status` - Mark passenger status
- `GET /api/driver/performance` - Get performance

### Maintenance
- `POST /api/maintenance` - Create report
- `POST /api/maintenance/:reportId/submit` - Submit report
- `GET /api/maintenance/my-reports` - Get driver reports
- `GET /api/maintenance/:id` - Get report by ID
- `GET /api/maintenance/admin/all` - Get all reports (admin)
- `PUT /api/maintenance/admin/:id/resolve` - Resolve report (admin)

### Feedback
- `POST /api/feedback` - Create feedback
- `GET /api/feedback/my-feedback` - Get user feedback
- `GET /api/feedback/admin/all` - Get all feedback (admin)
- `GET /api/feedback/:id` - Get feedback by ID
- `PUT /api/feedback/admin/:id/review` - Review feedback (admin)

### Notifications
- `GET /api/notifications` - Get notifications
- `PUT /api/notifications/:id/read` - Mark as read
- `PUT /api/notifications/read-all` - Mark all as read
- `DELETE /api/notifications/:id` - Delete notification
- `POST /api/notifications` - Create notification (admin)

### Admin
- `GET /api/admin/overview` - Get overview stats
- `GET /api/admin/users` - Get all users
- `PUT /api/admin/users/:id/status` - Update user status
- `DELETE /api/admin/users/:id` - Delete user
- `POST /api/admin/assignments` - Create assignment
- `GET /api/admin/assignments` - Get all assignments
- `GET /api/admin/tracking/buses` - Get buses for tracking

### Pricing
- `GET /api/pricing` - Get all pricings
- `GET /api/pricing/admin/stats` - Get pricing stats (admin)
- `POST /api/pricing/admin` - Create pricing (admin)
- `PUT /api/pricing/admin/:id` - Update pricing (admin)
- `DELETE /api/pricing/admin/:id` - Delete pricing (admin)

## Testing

### Health Check
```bash
curl http://localhost:5000/api/health
```

Or open in browser: `http://localhost:5000/api/health`

### Quick Test Flow

1. **Initialize database (creates test users):**
```bash
npm run init-db
```

2. **Test login with created user:**
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"passenger@waygo.com","password":"passenger123"}'
```

3. **Or register a new user:**
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "userType": "passenger",
    "userName": "Test User",
    "phone": "+1234567890",
    "email": "test@example.com",
    "password": "password123"
  }'
```

4. **Get profile (with token):**
```bash
GET http://localhost:5000/api/auth/profile
Headers: Authorization: Bearer <token>
```

## Troubleshooting

Having issues? Check:
1. [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Common issues and solutions
2. [SETUP_GUIDE.md](./SETUP_GUIDE.md) - Detailed setup instructions
3. [QUICK_START.md](./QUICK_START.md) - Quick setup guide

### Common Issues:
- **MongoDB not running:** Start MongoDB service
- **Port 5000 in use:** Change PORT in .env or kill process
- **Flutter can't connect:** Check IP address and firewall
- **Navigation not working:** Check Flutter console for errors

## Notes

- All dates should be in ISO format: `YYYY-MM-DD` or `YYYY-MM-DDTHH:mm:ssZ`
- File uploads use `multipart/form-data`
- QR codes are returned as base64 data URLs
- Location coordinates are in decimal degrees (lat, lng)
- JWT tokens expire after 24 hours

## License

ISC

