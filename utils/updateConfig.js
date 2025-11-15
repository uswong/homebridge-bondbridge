// Update myplaceConfig
const { createBondbridgeConfig } = require("./createBondbridgeConfig");
const { getBondHost } = require("./getBondHost");
const { readConfig } = require("./readConfig");

const chalk = require("chalk");

async function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function updateConfig(config, log, storagePath, pluginPath) {
  log.info(chalk.yellow('Running createBondbridgeConfig...'));

  // resolve ID for IP or use IP directly if specified
  let IPs = [];

  try {
    IPs = await getBondHost(config, log);
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
    log.info(`✅ DONE! createBondbridgeConfig completed successfully for ${noOfDevicesProcessed}/${noOfDevices} device(s)!`);
    log.debug('Updated Bondbridge config:\n' + JSON.stringify(bbConfig));
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
