// DeliveryOS Services Verification Script
const net = require('net');

function checkPort(host, port, serviceName) {
  return new Promise((resolve, reject) => {
    const socket = new net.Socket();
    socket.setTimeout(3000);

    socket.on('connect', () => {
      console.log(`✅ [${serviceName}] Connected successfully to ${host}:${port}`);
      socket.destroy();
      resolve(true);
    });

    socket.on('timeout', () => {
      console.error(`❌ [${serviceName}] Connection timed out on ${host}:${port}`);
      socket.destroy();
      reject(new Error(`Timeout on ${host}:${port}`));
    });

    socket.on('error', (err) => {
      console.error(`❌ [${serviceName}] Connection error on ${host}:${port} - ${err.message}`);
      reject(err);
    });

    socket.connect(port, host);
  });
}

async function verify() {
  console.log('--- DeliveryOS Services Verification ---');
  try {
    await checkPort('localhost', 5433, 'PostgreSQL + PostGIS (Port 5433)');
    await checkPort('localhost', 6380, 'Redis Cache & PubSub (Port 6380)');
    console.log('🎉 All infrastructure services are online, accessible, and ready for Task 1.2!');
  } catch (error) {
    process.exit(1);
  }
}

verify();
