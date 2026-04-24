// Update myplaceConfig
const { createBondbridgeConfig } = require("./createBondbridgeConfig");
const { getBondHost } = require("./getBondHost");
const { readConfig } = require("./readConfig");

async function updateConfig(config, log, storagePath, pluginPath) {
  log.warn('*** Running createBondbridgeConfig...');

  // resolve ID for IP or use IP directly if specified
  let IPs = [];
  let devicesAutoDiscovered = false;

  try {
    ({ IPs, devicesAutoDiscovered } = await getBondHost(config, log));
  } catch (err) {
    log.error(`❌ ${err.message}`);
    const existingConfig = readConfig( storagePath, log );
    if (existingConfig) {
      log.warn('⚠️ Proceed with existing config from cache — all existing accessories will be restored.');
      return existingConfig;
    }
    log.warn('⚠️ Proceed with original config — no accessories will be created and cached accessories will be removed.');
    return config;
  }
  let noOfDevices = IPs.length;
  let noOfDevicesProcessed = IPs.filter(ip => ip !== "undefined").length;;

  try {
    const bbConfig = await createBondbridgeConfig(config, IPs, log, pluginPath);
    if (devicesAutoDiscovered) {
      log.info(`✅ DONE! createBondbridgeConfig completed successfully for ${noOfDevicesProcessed}/${noOfDevices} "auto-discovered" device(s)!`);
    } else {
      log.info(`✅ DONE! createBondbridgeConfig completed successfully for ${noOfDevicesProcessed}/${noOfDevices} device(s)!`);
    }
    log.debug('Updated Bondbridge config:\n' + JSON.stringify(bbConfig));

    // give a warning if there is no accessories created in the config.
    if (Array.isArray(bbConfig.accessories) && bbConfig.accessories.length === 0) {
      log.warn(
        '⚠️ No accessories will be created because the accessories array in the config is empty! Make sure Devices are properly defined in your Bond Bridge.'
      );
    }
    return bbConfig;
  } catch (err) {
    log.error(`❌ ${err.message}`);
    const existingConfig = readConfig( storagePath, log );

    if (existingConfig && Array.isArray(existingConfig.accessories)) {
      log.warn('⚠️ Proceed with existing config from cache — all existing accessories will be restored.');
      return existingConfig;
    }
    log.warn('⚠️ Proceed with original config — no accessories will be created and any cached accessories will be removed.');
    return config;
  }
}

module.exports = { updateConfig };
