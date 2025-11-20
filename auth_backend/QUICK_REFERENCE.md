# Quick API Reference

## Base URL: `http://localhost:5000/api`

## 🔐 Authentication
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/auth/register` | No | Register user |
| POST | `/auth/login` | No | Login |
| POST | `/auth/google-signin` | No | Google sign in |
| GET | `/auth/profile` | Yes | Get profile |
| PUT | `/auth/profile` | Yes | Update profile |

## 📰 News
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/news` | No | Get published news |
| GET | `/news/admin/all` | Admin | Get all news |
| POST | `/news/admin` | Admin | Create news |
| PUT | `/news/admin/:id` | Admin | Update news |
| DELETE | `/news/admin/:id` | Admin | Delete news |

## 🚌 Routes
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/routes/search?start=X&destination=Y&date=Z` | No | Search routes |
| GET | `/routes` | No | Get all routes |
| POST | `/routes/admin` | Admin | Create route |
| PUT | `/routes/admin/:id` | Admin | Update route |
| DELETE | `/routes/admin/:id` | Admin | Delete route |

## 🎫 Reservations
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/reservations` | Yes | Create reservation |
| POST | `/reservations/confirm` | Yes | Confirm with payment |
| GET | `/reservations/my-reservations` | Yes | Get my reservations |
| GET | `/reservations/:id` | Yes | Get reservation |
| POST | `/reservations/validate` | Driver/Admin | Validate ticket |

## 💳 Payments
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/payments/my-payments` | Yes | Get my payments |
| GET | `/payments/:id` | Yes | Get payment |

## 🚍 Bus
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/bus/update-location` | Driver | Update location |
| POST | `/bus/toggle-sharing` | Driver | Toggle sharing |
| GET | `/bus/:busId` | No | Get location |
| GET | `/bus/admin/all` | Admin | Get all buses |
| POST | `/bus/admin` | Admin | Create bus |
| POST | `/bus/admin/assign-driver` | Admin | Assign driver |

## 👨‍✈️ Driver
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/driver/trip/start` | Driver | Start trip |
| POST | `/driver/trip/pause` | Driver | Pause trip |
| POST | `/driver/trip/resume` | Driver | Resume trip |
| POST | `/driver/trip/end` | Driver | End trip |
| PUT | `/driver/trip/status` | Driver | Update status |
| GET | `/driver/trips` | Driver | Get trips |
| GET | `/driver/assignments` | Driver | Get assignments |
| POST | `/driver/assignments/respond` | Driver | Respond |
| GET | `/driver/trip/:tripId/passengers` | Driver | Get passengers |
| POST | `/driver/passenger/status` | Driver | Mark status |
| GET | `/driver/performance` | Driver | Get performance |

## 🔧 Maintenance
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/maintenance` | Driver | Create report |
| POST | `/maintenance/:reportId/submit` | Driver | Submit report |
| GET | `/maintenance/my-reports` | Driver | Get reports |
| GET | `/maintenance/:id` | Yes | Get report |
| GET | `/maintenance/admin/all` | Admin | Get all reports |
| PUT | `/maintenance/admin/:id/resolve` | Admin | Resolve report |

## 💬 Feedback
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/feedback` | Yes | Create feedback |
| GET | `/feedback/my-feedback` | Yes | Get my feedback |
| GET | `/feedback/admin/all` | Admin | Get all feedback |
| GET | `/feedback/:id` | Yes | Get feedback |
| PUT | `/feedback/admin/:id/review` | Admin | Review feedback |

## 🔔 Notifications
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/notifications` | Yes | Get notifications |
| PUT | `/notifications/:id/read` | Yes | Mark as read |
| PUT | `/notifications/read-all` | Yes | Mark all read |
| DELETE | `/notifications/:id` | Yes | Delete notification |
| POST | `/notifications` | Admin | Create notification |

## 👨‍💼 Admin
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/admin/overview` | Admin | Get overview |
| GET | `/admin/users` | Admin | Get all users |
| PUT | `/admin/users/:id/status` | Admin | Update user status |
| DELETE | `/admin/users/:id` | Admin | Delete user |
| POST | `/admin/assignments` | Admin | Create assignment |
| GET | `/admin/assignments` | Admin | Get assignments |
| GET | `/admin/tracking/buses` | Admin | Get buses for tracking |

## 💰 Pricing
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/pricing` | No | Get all pricings |
| GET | `/pricing/admin/stats` | Admin | Get stats |
| POST | `/pricing/admin` | Admin | Create pricing |
| PUT | `/pricing/admin/:id` | Admin | Update pricing |
| DELETE | `/pricing/admin/:id` | Admin | Delete pricing |

## 📊 Dashboard
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/dashboard/passenger-dashboard` | Passenger | Passenger dashboard |
| GET | `/dashboard/driver-dashboard` | Driver | Driver dashboard |
| GET | `/dashboard/admin-dashboard` | Admin | Admin dashboard |

## 🏥 Health
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/health` | No | Health check |

---

## Authentication Header Format
```
Authorization: Bearer <your_jwt_token>
```

## Common Status Codes
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Server Error

