// Update myplaceConfig
const { createBondbridgeConfig } = require("./createBondbridgeConfig");
const chalk = require("chalk");

async function updateConfig(config, log, pluginPath) {

  // Run ConfigCreator to update the BondBridge config
  log.info(chalk.yellow('Running createBondbridgeConfig...'));
  try {
    const bbConfig = await createBondbridgeConfig(config, pluginPath);
    log.info("✅ DONE! createBondbridgeConfig completed successfully!");
    log.debug('Updated Bondbridge config:\n' + JSON.stringify(bbConfig));
    return bbConfig;
  } catch (err) {
    log.error(`❌ ${err.message}`);
    log.warn('⚠️  Proceed with original config — no accessories will be created and cached accessories will be removed.');
    return config;
  }
}

module.exports = { updateConfig };
