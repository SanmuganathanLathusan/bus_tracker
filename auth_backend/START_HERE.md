# 🚀 START HERE - Complete Setup Checklist

Follow these steps in order to get your backend running.

## ✅ Step-by-Step Setup

### Step 1: Install MongoDB
- [ ] Download MongoDB from https://www.mongodb.com/try/download/community
- [ ] Install MongoDB
- [ ] Start MongoDB service
  ```bash
  # Windows
  net start MongoDB
  
  # Mac
  brew services start mongodb-community
  
  # Linux
  sudo systemctl start mongod
  ```
- [ ] Verify MongoDB is running:
  ```bash
  mongosh
  ```
  (Type `exit` to leave MongoDB shell)

### Step 2: Setup Backend
- [ ] Navigate to backend folder:
  ```bash
  cd waygo/auth_backend
  ```
- [ ] Install dependencies:
  ```bash
  npm install
  ```
- [ ] Create `.env` file:
  ```bash
  # Windows
  type nul > .env
  
  # Mac/Linux
  touch .env
  ```
- [ ] Add this to `.env`:
  ```env
  MONGODB_URI=mongodb://localhost:27017/waygo
  JWT_SECRET=my_secret_key_12345_change_this
  PORT=5000
  ```

### Step 3: Test Database Connection
- [ ] Run test:
  ```bash
  npm run test-connection
  ```
- [ ] Should see: `✅ MongoDB Connected Successfully!`

### Step 4: Initialize Database (Optional)
- [ ] Create test users:
  ```bash
  npm run init-db
  ```
- [ ] This creates:
  - Admin: `admin@waygo.com` / `admin123`
  - Driver: `driver@waygo.com` / `driver123`
  - Passenger: `passenger@waygo.com` / `passenger123`

### Step 5: Start Backend Server
- [ ] Start server:
  ```bash
  npm run dev
  ```
- [ ] Should see:
  ```
  ✅ MongoDB Connected...
  🚀 Server running on port 5000
  ```

### Step 6: Test Backend
- [ ] Open browser: `http://localhost:5000/api/health`
- [ ] Should see: `{"status":"OK","message":"Server is running"}`

### Step 7: Test with Flutter
- [ ] Open Flutter app in emulator
- [ ] Try to login with: `passenger@waygo.com` / `passenger123`
- [ ] Check Flutter console for logs (🔵 and ❌ emojis)
- [ ] Should navigate to passenger dashboard

---

## 🔍 If Something Doesn't Work

### Backend Not Starting?
1. Check MongoDB is running: `mongosh`
2. Check `.env` file exists and has correct values
3. Check port 5000 is not in use
4. See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

### Flutter Can't Connect?
1. Check backend is running (Step 5)
2. Check health endpoint works (Step 6)
3. Check Flutter console for error messages
4. For Android emulator, use `10.0.2.2:5000` (already configured)
5. See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

### Navigation Not Working?
1. Check Flutter console for errors
2. Check if API call succeeded (look for ✅ in logs)
3. Verify routes are defined in `main.dart`
4. See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

---

## 📚 Documentation

- [QUICK_START.md](./QUICK_START.md) - 5-minute quick setup
- [SETUP_GUIDE.md](./SETUP_GUIDE.md) - Detailed setup instructions
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Common issues and solutions
- [API_DOCUMENTATION.md](./API_DOCUMENTATION.md) - Complete API reference
- [POSTMAN_COLLECTION.md](./POSTMAN_COLLECTION.md) - Postman setup guide

---

## 🎯 Quick Commands Reference

```bash
# Test MongoDB connection
npm run test-connection

# Initialize database with test users
npm run init-db

# Start backend (development)
npm run dev

# Start backend (production)
npm start

# Test health endpoint
curl http://localhost:5000/api/health
```

---

## ✅ Verification Checklist

Before testing Flutter app, verify:

- [ ] MongoDB is running
- [ ] `.env` file exists with correct values
- [ ] `npm install` completed successfully
- [ ] `npm run test-connection` passes
- [ ] `npm run dev` shows server running
- [ ] Health endpoint returns OK
- [ ] Test users created (if you ran `npm run init-db`)

---

## 🎉 You're Ready!

Once all steps are complete:
1. Backend should be running on port 5000
2. Database should be connected
3. Test users should be available (if initialized)
4. Flutter app should be able to connect

**Test it:**
- Login with: `passenger@waygo.com` / `passenger123`
- Or register a new user
- Check Flutter console for connection logs

