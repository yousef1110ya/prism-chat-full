require('dotenv').config();
const express = require('express');
const multer = require('multer');
const path = require('path');
const http = require('http');
const socketIo = require('socket.io');
const redis = require('redis');

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

// Create Redis client
const redisClient = redis.createClient({
  url: `redis://${process.env.REDIS_HOST || 'localhost'}:${process.env.REDIS_PORT || 6379}`
});

redisClient.on('error', (err) => console.error('Redis Client Error', err));
redisClient.on('connect', () => console.log('Connected to Redis'));

// Initialize Redis connection
(async () => {
  await redisClient.connect();
})();

// Configure storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ storage });

// Serve uploaded files statically
app.use('/uploads', express.static('uploads'));

// Upload endpoint
app.post('/upload', upload.single('image'), (req, res) => {
  if (!req.file) return res.status(400).send('No file uploaded');
  
  const fileUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
  res.json({ url: fileUrl });
});

app.get('/check-presence', async (req, res) => {
  const { userId } = req.query;
  const socketId = await redisClient.get(userId);
  res.json({ presence: socketId ? 'online' : 'offline' });
});

// Socket.IO connection with user targeting
io.on('connection', async (socket) => {
  console.log('Client connected:', socket.id);

  // Register user with their socket
  socket.on('register', async (userId) => {
    try {
      await redisClient.set(userId, socket.id);
      console.log(`User ${userId} registered with socket ${socket.id}`);
      socket.emit('registered', `User ${userId} connected successfully`);
    } catch (err) {
      console.error('Redis set error:', err);
      socket.emit('error', 'Registration failed');
    }
  });

  // Private call notification to specific user
  socket.on('private-call', async (data) => {
    try {
      const targetSocketId = await redisClient.get(data.targetUserId);
      
      if (!targetSocketId) {
        return socket.emit('error', 'User not found or offline');
      }
      
      io.to(targetSocketId).emit('call', {
        caller: data.caller,
        time: new Date().toISOString(),
        message: `Incoming call from ${data.caller}`
      });
      console.log(`Call sent to ${data.targetUserId} (${targetSocketId}) from ${data.caller}`);
    } catch (err) {
      console.error('Redis get error:', err);
      socket.emit('error', 'Call failed');
    }
  });

  socket.on('disconnect', async () => {
    console.log('Client disconnected:', socket.id);
    
    // Clean up Redis
    try {
      const keys = await redisClient.keys('*');
      for (const key of keys) {
        const value = await redisClient.get(key);
        if (value === socket.id) {
          await redisClient.del(key);
          console.log(`Removed user ${key} from Redis`);
        }
      }
    } catch (err) {
      console.error('Redis cleanup error:', err);
    }
  });
});

// Test endpoint to trigger private call
app.get('/trigger-call', async (req, res) => {
  const { caller, target } = req.query;
  if (!caller || !target) {
    return res.status(400).send('Missing caller or target parameters');
  }

  try {
    const targetSocketId = await redisClient.get(target);
    if (!targetSocketId) {
      return res.status(404).send('Target user not found');
    }

    io.to(targetSocketId).emit('call', {
      caller,
      time: new Date().toISOString(),
      message: `Incoming call from ${caller}`
    });

    res.send(`Call notification sent to ${target}`);
  } catch (err) {
    console.error('Redis error:', err);
    res.status(500).send('Internal server error');
  }
});

// Serve test page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'test.html'));
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Upload test endpoint: POST http://localhost:${PORT}/upload`);
  console.log(`Call trigger: GET http://localhost:${PORT}/trigger-call?caller=Admin&target=TARGET_USER_ID`);
  console.log(`Test UI: http://localhost:${PORT}`);
});