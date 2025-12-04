async function bondAutoDiscovery(log, maxDevices) {
  return new Promise((resolve) => {
    const bonjour = require("bonjour")();
    const browser = bonjour.find({ type: "bond" });

    const found = [];

    const timeoutMs = 2000;
    const timeout = setTimeout(() => {
      browser.stop();
      bonjour.destroy();
      resolve(found);
    }, timeoutMs);

    browser.on("up", (service) => {
      const ipv4 = service.addresses.find((addr) => addr.includes(".")) || null;

      found.push({
        id: service.name,
        ip: ipv4,
      });

      log.info(
        `💡 Found Bond device #${found.length}: ID=${service.name}, IP=${ipv4}`
      );

      // 🔥 Stop early if we reached the limit
      if (found.length >= maxDevices) {
        clearTimeout(timeout);
        browser.stop();
        bonjour.destroy();
        resolve(found);
      }
    });

    browser.on("error", (err) => {
      clearTimeout(timeout);
      browser.stop();
      bonjour.destroy();
      resolve(found);
    });
  });
}

module.exports = { bondAutoDiscovery };
