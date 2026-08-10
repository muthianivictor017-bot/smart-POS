const express = require('express');
const path = require('path');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS for all origins (useful if you access from multiple devices)
app.use(cors());

// Parse JSON bodies
app.use(express.json());

// Serve static files from the current directory
app.use(express.static(path.join(__dirname)));

// Health check endpoint (Render uses this to verify the service is up)
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    service: 'Smart POS',
    timestamp: new Date().toISOString(),
    firebaseProject: 'smart-pos-d409e'
  });
});

// API endpoint to get Firebase config (optional - if you want to hide it from frontend)
app.get('/api/config', (req, res) => {
  res.json({
    firebase: {
      apiKey: process.env.FIREBASE_API_KEY || "AIzaSyA3LiTepwOdKwSb6j0ZrE0swNa7JYwyBiE",
      authDomain: process.env.FIREBASE_AUTH_DOMAIN || "smart-pos-d409e.firebaseapp.com",
      projectId: process.env.FIREBASE_PROJECT_ID || "smart-pos-d409e",
      storageBucket: process.env.FIREBASE_STORAGE_BUCKET || "smart-pos-d409e.firebasestorage.app",
      messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID || "396228952889",
      appId: process.env.FIREBASE_APP_ID || "1:396228952889:web:4bd6a009c3284c178bdee8",
      measurementId: process.env.FIREBASE_MEASUREMENT_ID || "G-Y5JPS0RJMG"
    }
  });
});

// Serve the main app for all routes (SPA support)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(PORT, () => {
  console.log(`🚀 Smart POS Server running on port ${PORT}`);
  console.log(`📱 Access the app at: http://localhost:${PORT}`);
  console.log(`🔥 Firebase Project: smart-pos-d409e`);
});
