# Troubleshooting Guide

## Common Issues and Solutions

### ❌ Issue: Flutter App Not Navigating

**Symptoms:**
- App opens but doesn't navigate after login/register
- No error messages shown
- Loading indicator stays forever

**Solutions:**

1. **Check Backend is Running:**
   ```bash
   # In backend folder
   npm run dev
   ```
   Should see: `🚀 Server running on port 5000`

2. **Test Backend Health:**
   ```bash
   curl http://localhost:5000/api/health
   ```
   Should return: `{"status":"OK","message":"Server is running"}`

3. **Check Flutter Console:**
   - Look for error messages
   - Check for connection errors
   - Look for API response logs (🔵 and ❌ emojis)

4. **Test API Directly:**
   Add this test in Flutter:
   ```dart
   void testConnection() async {
     try {
       final response = await http.get(
         Uri.parse('http://10.0.2.2:5000/api/health')
       );
       print('✅ Backend connected: ${response.body}');
     } catch (e) {
       print('❌ Backend error: $e');
     }
   }
   ```

5. **Check MongoDB:**
   ```bash
   # Test MongoDB connection
   npm run test-connection
   ```

---

### ❌ Issue: MongoDB Connection Failed

**Error:** `❌ MongoDB Connection Failed`

**Solutions:**

1. **Start MongoDB:**
   ```bash
   # Windows
   net start MongoDB
   
   # Mac
   brew services start mongodb-community
   
   # Linux
   sudo systemctl start mongod
   ```

2. **Check MongoDB URI in .env:**
   ```env
   MONGODB_URI=mongodb://localhost:27017/waygo
   ```

3. **Test MongoDB Connection:**
   ```bash
   mongosh
   # or
   mongo
   ```

4. **Create Database:**
   ```bash
   mongosh
   use waygo
   ```

---

### ❌ Issue: Port 5000 Already in Use

**Error:** `EADDRINUSE: address already in use :::5000`

**Solutions:**

1. **Find and Kill Process:**
   ```bash
   # Windows
   netstat -ano | findstr :5000
   taskkill /PID <PID> /F
   
   # Mac/Linux
   lsof -i :5000
   kill -9 <PID>
   ```

2. **Or Change Port:**
   Update `.env`:
   ```env
   PORT=5001
   ```
   Update Flutter `api_service.dart`:
   ```dart
   static const String baseUrl = "http://10.0.2.2:5001/api/auth";
   ```

---

### ❌ Issue: Cannot Connect to Server (Flutter)

**Error:** `Cannot connect to server` or `Connection refused`

**Solutions:**

1. **For Android Emulator:**
   - Use `10.0.2.2:5000` (already configured)
   - Make sure backend is running
   - Check backend logs for errors

2. **For Physical Device:**
   - Find your computer's IP:
     ```bash
     # Windows
     ipconfig
     
     # Mac/Linux
     ifconfig
     ```
   - Update `api_service.dart`:
     ```dart
     static const String baseUrl = "http://192.168.1.100:5000/api/auth";
     ```
   - Allow firewall:
     ```bash
     # Windows
     netsh advfirewall firewall add rule name="Node.js" dir=in action=allow protocol=TCP localport=5000
     ```

3. **Check Network:**
   - Phone and computer on same WiFi
   - No VPN blocking connection
   - Firewall not blocking port 5000

---

### ❌ Issue: Navigation Not Working After Login

**Possible Causes:**
1. API call failing silently
2. Response format incorrect
3. Route not defined in main.dart

**Solutions:**

1. **Add Debug Logging:**
   Check Flutter console for:
   - `🔵 Logging in user: ...`
   - `🔵 Response status: 200`
   - `✅ Login successful, token saved`

2. **Check Response:**
   ```dart
   print('Full response: $response');
   print('Token: ${response['token']}');
   print('User: ${response['user']}');
   ```

3. **Verify Routes:**
   Check `main.dart` has all routes defined:
   ```dart
   '/passenger-dashboard': (context) => const PassengerDashboard(),
   '/driver-dashboard': (context) => const DriverDashboard(),
   '/admin-dashboard': (context) => const AdminDashboard(),
   ```

4. **Test Navigation Manually:**
   ```dart
   Navigator.pushReplacementNamed(context, '/passenger-dashboard');
   ```

---

### ❌ Issue: Database Empty / No Data

**Solution: Initialize Database:**
```bash
npm run init-db
```

This creates:
- Admin user: `admin@waygo.com` / `admin123`
- Driver user: `driver@waygo.com` / `driver123`
- Passenger user: `passenger@waygo.com` / `passenger123`
- Sample buses and routes

---

### ❌ Issue: "Cannot read property of undefined"

**Cause:** API response format mismatch

**Solution:**
1. Check backend logs for actual response
2. Verify response structure matches Flutter expectations
3. Add null checks:
   ```dart
   if (response['token'] != null && response['user'] != null) {
     // proceed
   }
   ```

---

## Debugging Steps

### Step 1: Verify Backend
```bash
# 1. Check MongoDB
npm run test-connection

# 2. Start backend
npm run dev

# 3. Test health endpoint
curl http://localhost:5000/api/health
```

### Step 2: Verify Flutter Connection
```dart
// Add this test function
void testBackend() async {
  try {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:5000/api/health')
    );
    print('✅ Backend OK: ${response.body}');
  } catch (e) {
    print('❌ Backend Error: $e');
  }
}
```

### Step 3: Check Logs
- **Backend logs:** Check terminal running `npm run dev`
- **Flutter logs:** Check Flutter console/debug output
- **MongoDB logs:** Check MongoDB service logs

### Step 4: Test with Postman
Before testing in Flutter, test API with Postman:
1. Register user
2. Login user
3. Verify responses

---

## Quick Diagnostic Commands

```bash
# Check MongoDB
mongosh --eval "db.version()"

# Check Node.js
node --version

# Check npm
npm --version

# Test backend connection
npm run test-connection

# Initialize database
npm run init-db

# Check if port is in use
# Windows
netstat -ano | findstr :5000

# Mac/Linux
lsof -i :5000
```

---

## Still Having Issues?

1. **Check all logs:**
   - Backend terminal
   - Flutter console
   - MongoDB logs

2. **Verify setup:**
   - MongoDB running
   - .env file exists
   - Backend running
   - Port 5000 available

3. **Test step by step:**
   - Test MongoDB connection
   - Test backend health
   - Test API with Postman
   - Test Flutter connection
   - Test Flutter API calls

4. **Common mistakes:**
   - Forgot to start MongoDB
   - Wrong IP address in Flutter
   - Firewall blocking port
   - Backend not running
   - Wrong .env configuration

