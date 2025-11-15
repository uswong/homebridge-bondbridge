// This function to get the valid IPs and check that they are accessible
const { isIpAccessible } = require("./isIpAccessible");

async function getBondHost(config, log) {
  const dns = require("dns/promises");

  let id, ip, ipFound;
  const IPs = [];

  // --- Helpers ---
  const isValidIp = (value) => /^(?:\d{1,3}\.){3}\d{1,3}$/.test(value);
  const isValidId = (value) => /^[A-Za-z0-9]{6}$|^[A-Za-z0-9]{9}$/.test(value);
  const isValidToken = (token) =>
    /^(?:[A-Za-z0-9_-]{16}|[A-Za-z0-9_-]{43})$/.test(token);

  async function getBondIp(bondID) {
    const host = `${bondID}.local`;
    try {
      const { address } = await dns.lookup(host);
      return address;
    } catch {
      return null;
    }
  }

  const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

  const devices = config.devices || [];
  const noOfBondBridges = devices.length;

  if (noOfBondBridges === 0) {
    log.warn("⚠️ No Bond Bridge devices found in configuration.");
    return [];
  }

  // ----------------------------------------------
  // PROCESS EACH DEVICE
  // ----------------------------------------------
  for (let i = 0; i < noOfBondBridges; i++) {
    id = null;
    ip = null;

    const ipAddress = devices[i]?.ipAddress;
    const token = devices[i]?.token;

    // Determine if ipAddress is IP or ID ------------------------
    if (isValidIp(ipAddress)) {
      ip = ipAddress;
    } else if (isValidId(ipAddress)) {
      id = ipAddress;
    } else {
      log.warn(
        `⚠️ Device ${i + 1} has no valid Bond ID or IP. This device will NOT be processed`
      );
      IPs.push("undefined");
      continue;
    }

    // Validate token --------------------------------------------
    if (!isValidToken(token)) {
      log.error(
        `❌ Device ${i + 1} has invalid token "${token}". This device will NOT be processed.`
      );
      IPs.push("undefined");
      continue;
    }

    // If Bond ID provided → resolve via mDNS ---------------------
    if (id) {
      const maxRetries = 5;
      let attempt = 0;

      while (attempt < maxRetries) {
        attempt++;
        ipFound = await getBondIp(id);

        if (ipFound) {
          log.info(
            `✅ Device ${i + 1} Host: "${id}.local" resolved to IP: ${ipFound}`
          );
          break;
        }

        if (attempt < maxRetries) {
          log.warn(
            `⚠️ Device ${i + 1} Bond ID "${id}" unresolved. Retrying (${attempt}/${maxRetries}) in 5s...`
          );
          await delay(5000);
        }
      }

      if (!ipFound) {
        log.error(`❌ All 5 retries failed.`);
        log.warn(
          `⚠️ Device ${i + 1} with Bond ID "${id}" appears valid but inaccessible. This device will NOT be processed.`
        );
        IPs.push("undefined");
      } else {
        IPs.push(ipFound);
      }
    }

    // If a direct IP was provided -------------------------------
    else if (ip) {
      IPs.push(ip);
    }

    // Just in case ----------------------------------------------
    else {
      IPs.push("undefined");
    }
  }

  // ----------------------------------------------
  // CHECK FOR ALL UNDEFINED BEFORE NETWORK TEST
  // ----------------------------------------------
  if (IPs.every((el) => el === "undefined")) {
    throw new Error(`No device has a valid Bond ID or IP specified.`);
  }

  // ----------------------------------------------
  // CHECK ACCESSIBILITY
  // ----------------------------------------------
  const updatedIPs = await isIpAccessible(IPs, log);

  if (updatedIPs.every((el) => el === "undefined")) {
    throw new Error(`No device is accessible on the LAN network.`);
  }

  return updatedIPs;
}

module.exports = { getBondHost };
