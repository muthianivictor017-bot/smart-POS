const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.disable('x-powered-by');
app.use(express.json());
app.use(express.static(__dirname, {
  index: 'index.html',
  extensions: ['html'],
  maxAge: process.env.NODE_ENV === 'production' ? '1h' : 0
}));

app.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    service: 'Atelier Smart POS',
    timestamp: new Date().toISOString()
  });
});

// Keep client-side routes usable when the app is deployed behind a proxy.
app.get('*', (_req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Atelier Smart POS listening on port ${PORT}`);
});
