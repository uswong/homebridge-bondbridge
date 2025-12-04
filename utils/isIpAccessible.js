// Check if IPs is accessible, if not, set it to "undefined"
async function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function isIpAccessible( ip, i, log ) {

  const maxRetries = 5;
  let attempt = 0;

  while (attempt <= maxRetries) {

    try {
      const res = await fetch(`http://${ip}/v2/sys/version`);
      const version = await res.json();
      break;
    } catch (err) {
      attempt++;

      // skip this device
      if (attempt > maxRetries) {
        log.warn(`⚠️ All 5 retry attempts to access Device ${i + 1} with IP ${ip} failed! This device will NOT be processed.`);
        ip = "undefined";
      } else {
        log.warn(`⏳ Device ${i + 1} with IP ${ip} is inaccessible. Retrying (${attempt}/${maxRetries}) in ~5s...`);
        await delay(5000);
      }
    }
  }
  return ip;
}

module.exports = { isIpAccessible };
