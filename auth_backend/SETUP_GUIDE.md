# Complete Setup Guide for WayGo Backend

## Prerequisites
- Node.js (v14 or higher)
- MongoDB (v4.4 or higher)
- npm or yarn

---

## Step 1: Install MongoDB

### Windows:
1. Download MongoDB from: https://www.mongodb.com/try/download/community
2. Run the installer
3. Choose "Complete" installation
4. Install MongoDB as a Windows Service
5. Install MongoDB Compass (GUI tool) - optional but recommended

### Mac:
```bash
# Using Homebrew
brew tap mongodb/brew
brew install mongodb-community
brew services start mongodb-community
```

### Linux (Ubuntu/Debian):
```bash
# Import MongoDB GPG key
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -

# Add MongoDB repository
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

# Update and install
sudo apt-get update
sudo apt-get install -y mongodb-org

# Start MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod
```

### Verify MongoDB Installation:
```bash
# Check if MongoDB is running
mongosh
# or
mongo
```

If you see the MongoDB shell, it's working!

---

## Step 2: Create Database

### Option 1: Using MongoDB Shell
```bash
mongosh
```

Then in the shell:
```javascript
use waygo
db.createCollection("users")
db.createCollection("buses")
db.createCollection("routes")
// Collections will be created automatically when you insert data
```

### Option 2: Using MongoDB Compass
1. Open MongoDB Compass
2. Connect to `mongodb://localhost:27017`
3. Click "Create Database"
4. Database Name: `waygo`
5. Collection Name: `users` (or any name, collections auto-create)

---

## Step 3: Setup Backend Environment

1. **Navigate to backend folder:**
```bash
cd waygo/auth_backend
```

2. **Create `.env` file:**
```bash
# Windows
type nul > .env

# Mac/Linux
touch .env
```

3. **Add environment variables to `.env`:**
```env
# MongoDB Connection
MONGODB_URI=mongodb://localhost:27017/waygo

# JWT Secret (change this to a random string)
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production_12345

# Server Port
PORT=5000

# Google OAuth (optional - for Google Sign In)
GOOGLE_CLIENT_ID=your_google_client_id_here

# Server URL
BASE_URL=http://localhost:5000
```

**Important:** Replace `JWT_SECRET` with a strong random string!

---

## Step 4: Install Dependencies

```bash
cd waygo/auth_backend
npm install
```

---

## Step 5: Start MongoDB

### Windows:
```bash
# MongoDB should start automatically as a service
# If not, run:
net start MongoDB
```

### Mac:
```bash
brew services start mongodb-community
```

### Linux:
```bash
sudo systemctl start mongod
```

### Verify MongoDB is running:
```bash
# Check status
# Windows:
sc query MongoDB

# Mac/Linux:
sudo systemctl status mongod
```

---

## Step 6: Start Backend Server

```bash
cd waygo/auth_backend

# Development mode (with auto-restart)
npm run dev

# OR Production mode
npm start
```

You should see:
```
✅ MongoDB Connected...
🚀 Server running on port 5000
```

---

## Step 7: Test Backend

### Test Health Endpoint:
Open browser or use Postman:
```
GET http://localhost:5000/api/health
```

Expected response:
```json
{
  "status": "OK",
  "message": "Server is running"
}
```

### Test with Postman:
1. Import the collection from `POSTMAN_COLLECTION.md`
2. Test register endpoint:
   - `POST http://localhost:5000/api/auth/register`
   - Body:
   ```json
   {
     "userType": "passenger",
     "userName": "Test User",
     "phone": "+1234567890",
     "email": "test@example.com",
     "password": "password123"
   }
   ```

---

## Step 8: Flutter App Configuration

### For Android Emulator:
The API service already uses `10.0.2.2:5000` which is correct for Android emulator.

### For Physical Device:
1. Find your computer's IP address:
   - Windows: `ipconfig` (look for IPv4 Address)
   - Mac/Linux: `ifconfig` or `ip addr`

2. Update `api_service.dart`:
```dart
static const String baseUrl = "http://YOUR_IP_ADDRESS:5000/api/auth";
// Example: "http://192.168.1.100:5000/api/auth"
```

3. Make sure your phone and computer are on the same WiFi network
4. Make sure Windows Firewall allows port 5000

---

## Troubleshooting

### Issue 1: MongoDB Connection Failed

**Error:** `❌ MongoDB Connection Failed`

**Solutions:**
1. Check if MongoDB is running:
   ```bash
   # Windows
   sc query MongoDB
   
   # Mac/Linux
   sudo systemctl status mongod
   ```

2. Check MongoDB URI in `.env`:
   ```
   MONGODB_URI=mongodb://localhost:27017/waygo
   ```

3. Try connecting manually:
   ```bash
   mongosh
   ```

4. If using MongoDB Atlas (cloud), update URI:
   ```
   MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/waygo
   ```

---

### Issue 2: Port Already in Use

**Error:** `EADDRINUSE: address already in use :::5000`

**Solutions:**
1. Find process using port 5000:
   ```bash
   # Windows
   netstat -ano | findstr :5000
   
   # Mac/Linux
   lsof -i :5000
   ```

2. Kill the process or change PORT in `.env`:
   ```
   PORT=5001
   ```

---

### Issue 3: Flutter App Can't Connect

**Error:** Connection timeout or no response

**Solutions:**

1. **Check if backend is running:**
   ```bash
   curl http://localhost:5000/api/health
   ```

2. **For Android Emulator:**
   - Use `10.0.2.2:5000` (already configured)
   - Make sure backend is running on `0.0.0.0` (already configured)

3. **For Physical Device:**
   - Update IP address in `api_service.dart`
   - Check Windows Firewall:
     ```bash
     # Allow port 5000
     netsh advfirewall firewall add rule name="Node.js Server" dir=in action=allow protocol=TCP localport=5000
     ```

4. **Check Flutter console for errors:**
   - Look for network errors
   - Check if API calls are being made

5. **Test API directly from Flutter:**
   Add this to test connection:
   ```dart
   try {
     final response = await http.get(Uri.parse('http://10.0.2.2:5000/api/health'));
     print('Response: ${response.body}');
   } catch (e) {
     print('Error: $e');
   }
   ```

---

### Issue 4: Navigation Not Working

**Possible Causes:**
1. API call failing silently
2. Error in response handling
3. Navigation route not defined

**Solutions:**

1. **Add error handling in API service:**
   ```dart
   Future<Map<String, dynamic>> login(String email, String password) async {
     try {
       final response = await http.post(
         Uri.parse("$baseUrl/login"),
         headers: {"Content-Type": "application/json"},
         body: jsonEncode({"email": email, "password": password}),
       );
       
       print('Response status: ${response.statusCode}');
       print('Response body: ${response.body}');
       
       final data = jsonDecode(response.body);
       
       if (response.statusCode == 200 && data['token'] != null) {
         // ... rest of code
       } else {
         throw Exception(data['error'] ?? 'Login failed');
       }
       
       return data;
     } catch (e) {
       print('Login error: $e');
       rethrow;
     }
   }
   ```

2. **Add try-catch in login function:**
   ```dart
   void _login() async {
     try {
       // ... existing code
       final response = await AuthService().login(email, password);
       
       if (response['token'] != null) {
         // Navigate
       } else {
         // Show error
       }
     } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Error: ${e.toString()}')),
       );
     }
   }
   ```

---

## Quick Start Checklist

- [ ] MongoDB installed and running
- [ ] Database `waygo` created
- [ ] `.env` file created with correct values
- [ ] Dependencies installed (`npm install`)
- [ ] Backend server running (`npm run dev`)
- [ ] Health check works (`http://localhost:5000/api/health`)
- [ ] Test registration works (Postman or curl)
- [ ] Flutter app configured with correct IP
- [ ] Windows Firewall allows port 5000 (if using physical device)

---

## Testing the Complete Flow

1. **Start MongoDB:**
   ```bash
   # Windows
   net start MongoDB
   
   # Mac/Linux
   sudo systemctl start mongod
   ```

2. **Start Backend:**
   ```bash
   cd waygo/auth_backend
   npm run dev
   ```

3. **Test Registration (Postman):**
   ```
   POST http://localhost:5000/api/auth/register
   Content-Type: application/json
   
   {
     "userType": "passenger",
     "userName": "John Doe",
     "phone": "+1234567890",
     "email": "john@example.com",
     "password": "password123"
   }
   ```

4. **Test Login (Postman):**
   ```
   POST http://localhost:5000/api/auth/login
   Content-Type: application/json
   
   {
     "email": "john@example.com",
     "password": "password123"
   }
   ```

5. **Run Flutter App:**
   ```bash
   cd waygo
   flutter run
   ```

6. **Test in Flutter:**
   - Open app
   - Try to register a new user
   - Try to login
   - Check if navigation works

---

## Common MongoDB Commands

```bash
# Connect to MongoDB
mongosh

# Show databases
show dbs

# Use database
use waygo

# Show collections
show collections

# View users
db.users.find().pretty()

# Count documents
db.users.countDocuments()

# Delete all users (for testing)
db.users.deleteMany({})
```

---

## Need Help?

1. Check server logs for errors
2. Check Flutter console for errors
3. Test API endpoints with Postman first
4. Verify MongoDB is running
5. Check network connectivity
6. Review error messages carefully

---

## Next Steps

After setup is complete:
1. Create test users (passenger, driver, admin)
2. Test all API endpoints
3. Integrate with Flutter app
4. Test complete user flows

