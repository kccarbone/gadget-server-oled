const express = require('express');
const app = express();
const server = require('http').Server(app);
const log = require('node-consolog').getLogger('test');
const oled = require('pi-gadgets').oled;
const port = process.env.PORT || 7777;
let display;

app.use(express.json());

// Get status
app.get('/status', (req, res) => {
  res.send({ status: 'ready' });
});

app.put('/update', async (req, res) => {
  display.buffer.fill(0);

  if(typeof req.body === 'object'){
    const items = Array.isArray(req.body) ? req.body : [req.body];
    for(let i=0; i<items.length; i++){
      const item = items[i];
      display.writeText(item.x, item.y, item.text);
    }
  }

  await display.update();
  res.status(201).end();
});

server.listen(port, async callback => {
  display = await oled.init(128, 32);
  display.writeText(0, 0, 'Ready', oled.fonts.small_8x12);
  await display.update();
  log.info(`Server running on port ${port}`);
});

// Termination event
process.on('SIGINT', function () {
  log.warn('Service shutting down!');

  setTimeout(() => process.exit(), 100);
});
