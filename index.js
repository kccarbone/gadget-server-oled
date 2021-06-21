const express = require('express');
const app = express();
const server = require('http').Server(app);
const log = require('node-consolog').getLogger('test');
const oled = require('pi-gadgets').oled;
const port = process.env.PORT || 7777;
let display, sleepRef;

app.use(express.json());

// Get status
app.get('/status', (req, res) => {
  res.send({ status: 'ready' });
});

app.put('/update', async (req, res) => {
  if(typeof req.body === 'object'){
    const items = Array.isArray(req.body) ? req.body : [req.body];
    display.clear();

    for(let i=0; i<items.length; i++){
      const item = items[i];
      const font = (typeof item.font === 'string') ? item.font : 'small_6x8';
      const color = (typeof item.color === 'number') ? item.color : 1;

      if(item.x && item.y && item.text){
        display.writeText(item.x, item.y, item.text, font, color);
      }
      else if(item.x && item.y && item.x2 && item.y2){
        display.writeRect(item.x, item.y, item.x2, item.y2, color);
      }
      else if(item.x && item.y){
        display.writePixel(item.x, item.y, color);
      }
      else if(item.x){
        display.writeVLine(item.x, color);
      }
      else if(item.y){
        display.writeHLine(item.y, color);
      }
      else{
        log.warn(`Invalid drawing directive: ${JSON.stringify(item)}`);
      }
    }
    await display.update();
    startSleepTimer(60);
    res.status(204).end();
  }
  else{
    res.status(400).send('Invalid request');
  }
});

function startSleepTimer(timeoutSecs){
  clearTimeout(sleepRef);
  sleepRef = setTimeout(() => {
    display.clear();
    display.update();
  }, (timeoutSecs * 1000));
}

server.listen(port, async callback => {
  display = await oled.init(128, 32);
  log.info(`Server running on port ${port}`);
});

// Termination event
process.on('SIGINT', function () {
  log.warn('Service shutting down!');
  display.clear();
  display.update().then(() => process.exit());
});
