# Quick Start Guide

## 🚀 Get Running in 5 Minutes

### Step 1: Install MongoDB (if not installed)

**Windows:**
- Download from: https://www.mongodb.com/try/download/community
- Install and start MongoDB service

**Mac:**
```bash
brew install mongodb-community
brew services start mongodb-community
```

**Linux:**
```bash
sudo apt-get install mongodb
sudo systemctl start mongod
```

### Step 2: Create .env File

```bash
cd waygo/auth_backend
```

Create `.env` file:
```env
MONGODB_URI=mongodb://localhost:27017/waygo
JWT_SECRET=my_secret_key_12345
PORT=5000
```

### Step 3: Install & Start Backend

```bash
npm install
npm run dev
```

You should see:
```
✅ MongoDB Connected...
🚀 Server running on port 5000
```

### Step 4: Test Backend

Open browser:
```
http://localhost:5000/api/health
```

Or use curl:
```bash
curl http://localhost:5000/api/health
```

### Step 5: Test Database Connection

```bash
node test-connection.js
```

### Step 6: Run Flutter App

```bash
cd waygo
flutter run
```

---

## 🔧 Troubleshooting

### Backend not starting?

1. **Check MongoDB:**
   ```bash
   mongosh
   ```
   If this works, MongoDB is running.

2. **Check .env file exists:**
   ```bash
   # Windows
   type .env
   
   # Mac/Linux
   cat .env
   ```

3. **Check port 5000:**
   ```bash
   # Windows
   netstat -ano | findstr :5000
   
   # Mac/Linux
   lsof -i :5000
   ```

### Flutter can't connect?

1. **Test backend from Flutter:**
   Add this to test:
   ```dart
   try {
     final response = await http.get(Uri.parse('http://10.0.2.2:5000/api/health'));
     print('Backend response: ${response.body}');
   } catch (e) {
     print('Connection error: $e');
   }
   ```

2. **Check Flutter console:**
   Look for error messages when trying to login/register

3. **Verify backend is running:**
   ```bash
   curl http://localhost:5000/api/health
   ```

---

## ✅ Verification Checklist

- [ ] MongoDB installed and running
- [ ] `.env` file created with correct values
- [ ] `npm install` completed
- [ ] Backend server running (`npm run dev`)
- [ ] Health check works (`http://localhost:5000/api/health`)
- [ ] Test connection script passes (`node test-connection.js`)
- [ ] Flutter app can connect to backend

---

## 📝 First Test

1. **Register a user (Postman or curl):**
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

2. **Login:**
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

3. **Test in Flutter:**
   - Open app
   - Try to register
   - Try to login
   - Check console for errors

---

## 🆘 Still Having Issues?

1. Check `SETUP_GUIDE.md` for detailed instructions
2. Check server logs for errors
3. Check Flutter console for errors
4. Verify all steps in checklist above

