// Check if IPs is accessible, if not, set it to "undefined"
async function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function isIpAccessible(IPs, log) {
  const noOfIPs = IPs.length;

  for (let i = 0; i < noOfIPs; i++) {
    const ip = IPs[i];
    const maxRetries = 5;
    let attempt = 0;

    if (ip === "undefined") continue;

    while (attempt <= maxRetries) {

      try {
        const res = await fetch(`http://${ip}/v2/sys/version`, { timeout: 1000 });
        const version = await res.json();
        break;
      } catch (err) {
        attempt++;

        // skip this device
        if (attempt > maxRetries) {
          log.warn(`⚠️ Device ${i + 1} with IP ${ip} is inaccessible. This device will NOT be processed.`);
          IPs[i] = "undefined";
        } else {
          log.warn(`⚠️ Device ${i + 1} with IP ${ip} is inaccessible. Retrying (${attempt}/${maxRetries}) in 5s...`);
          await delay(4000);
        }
      }
    }
  }
  return IPs;
}

module.exports = { isIpAccessible };
