// This script is to generate a complete configuration file needed for the bondbridge plugin
// This script can handle up to 3 independent BondBridge (BB) systems
//
// This script is invoked from the plugin when homebridge restart

async function createBondbridgeConfig(config, IPs, log, pluginPath) {

  const path = require("path");

  let BONDBRIDGE_SH_PATH = path.join(pluginPath, "BondBridge.sh");

  // Globals for config parts
  let bondbridgeModelQueue = {};
  let bondbridgeConstants = { constants: [] };
  let bondbridgeQueueTypes = { queueTypes: [] };
  let bondbridgeAccessories = { accessories: [] };

  const noOfBondBridges = config.devices?.length;

  // --- Helpers ---
  const isValidIp = (ip) => /^(?:\d{1,3}\.){3}\d{1,3}$/.test(ip);

  // Functions creating config parts

  function createModelQueue(model, bondid, queue) {
    bondbridgeModelQueue = {
      manufacturer: "OLIBRA",
      model,
      serialNumber: bondid,
      queue
    };
  }

  function createConstants(IPA, ip, debug) {
    const debugA = debug === "true" ? "-debug" : "";
    const constant = {
      key: IPA,
      value: `${ip}${debugA}`
    };
    bondbridgeConstants.constants.push(constant);
  }

  function createQueueTypes(queue) {
    const queueType = {
      queue: queue,
      queueType: "WoRm2"
    };
    bondbridgeQueueTypes.queueTypes.push(queueType);
  }

  function createFan(name, minStep, modelQueue, bondToken, device, IPA) {
    const fan = {
      type: "Fan",
      displayName: name,
      on: false,
      rotationSpeed: 25,
      name,
      ...modelQueue,
      polling: [
        { characteristic: "on" },
        { characteristic: "rotationSpeed" }
      ],
      props: {
        rotationSpeed: { minStep }
      },
      state_cmd: `'${BONDBRIDGE_SH_PATH}'`,
      state_cmd_suffix: `fan 'token:${bondToken}' 'device:${device}' ${IPA}`
    };
    bondbridgeAccessories.accessories.push(fan);
  }

  function createLightbulbNoDimmer(name, accType, modelQueue, bondToken, device, IPA) {
    const lightbulb = {
      type: "Lightbulb",
      displayName: name,
      on: false,
      name,
      ...modelQueue,
      polling: [{ characteristic: "on" }],
      state_cmd: `'${BONDBRIDGE_SH_PATH}'`,
      state_cmd_suffix: `${accType} 'token:${bondToken}' 'device:${device}' ${IPA}`
    };
    bondbridgeAccessories.accessories.push(lightbulb);
  }

  function createLightbulbWithDimmer(name, accType, minStep, modelQueue, bondToken, device, IPA) {
    const lightbulb = {
      type: "Lightbulb",
      displayName: name,
      on: false,
      brightness: 80,
      name,
      ...modelQueue,
      polling: [
        { characteristic: "on" },
        { characteristic: "brightness" }
      ],
      props: {
        brightness: { minStep }
      },
      state_cmd: `'${BONDBRIDGE_SH_PATH}'`,
      state_cmd_suffix: `${accType} 'token:${bondToken}' 'device:${device}' ${IPA}`
    };
    bondbridgeAccessories.accessories.push(lightbulb);
  }

  function createTimerLightbulb(name, accType, deviceType, modelQueue, bondToken, timerDevice, device, IPA) {
    const timerLightbulb = {
      type: "Lightbulb",
      displayName: name,
      on: false,
      brightness: 0,
      name,
      ...modelQueue,
      polling: [
        { characteristic: "on" },
        { characteristic: "brightness" }
      ],
      props: { brightness: { minStep: 1 } },
      state_cmd: `'${BONDBRIDGE_SH_PATH}'`,
      state_cmd_suffix: `${accType} 'token:${bondToken}' 'device:${timerDevice}' '${deviceType}:${device}' ${IPA}`
    };
    bondbridgeAccessories.accessories.push(timerLightbulb);
  }

  function assembleBondBridgeConfig() {
    return {
      name: "BondBridge",
      ...bondbridgeConstants,
      ...bondbridgeQueueTypes,
      ...bondbridgeAccessories,
      platform: "BondBridge"
    };
  }

  // The main logic starts here

  for (let n = 0; n < noOfBondBridges; n++) {
    const IPA = `\${BBIP${n + 1}}`;
    const ip = IPs[n];
    const bondToken = config.devices[n]?.token;
    const CFsetupOption = config.devices[n]?.CFsettings.setupOption;
    const CFtimerSetup = config.devices[n]?.CFsettings.timerSetup;
    const debug = config.devices[n]?.debug;
    const queue = ['BBA', 'BBB', 'BBC'][n];

    if (!ip || ip === "undefined" || !isValidIp(ip)) continue;

    // Fetch version info
    let version;
    try {
      const res = await fetch(`http://${ip}/v2/sys/version`, { timeout: 5000 });
      version = await res.json();
    } catch (err) {
      throw new Error(`ERROR: BondBridge device ${n + 1} at IP ${ip} is inaccessible. Reason: ${err.message}`);
    }

    const bondid = version.bondid;
    if (!bondid) {
      throw new Error("ERROR: Missing bondid!");
    }

    const model = version.model || "";

    // Create config parts
    createModelQueue(model, bondid, queue);

    if (CFsetupOption !== "doNotConfigure") {
      createConstants(IPA, ip, debug);
      createQueueTypes(queue);
    }

    // Fetch devices
    let devicesData;
    try {
      const devRes = await fetch(`http://${ip}/v2/devices`, {
        headers: { "BOND-Token": bondToken }
      });
      if (!devRes.ok) throw new Error(`HTTP error ${devRes.status}`);
      devicesData = await devRes.json();
    } catch (err) {
      throw new Error(`ERROR: Failed to fetch devices from ${ip}`, err);
    }

    const deviceKeys = Object.keys(devicesData);

    for (const device of deviceKeys) {
      if (!/^[a-f0-9]+$/.test(device)) continue;

      const timerDevice = device.split('').reverse().join('');

      // Get max_speed
      let maxSpeed = 0;
      try {
        const propRes = await fetch(`http://${ip}/v2/devices/${device}/properties`, {
          headers: { "BOND-Token": bondToken }
        });
        if (!propRes.ok) throw new Error(`HTTP error ${propRes.status}`);
        const propJson = await propRes.json();
        maxSpeed = propJson.max_speed || 0;
      } catch (err) {
        throw new Error(`ERROR: Failed to fetch device's properties from ${ip}`, err);
      }

      const speedInterval = maxSpeed ? Math.floor(100 / maxSpeed) : 0;

      // Get device name
      let name = "";
      try {
        const nameRes = await fetch(`http://${ip}/v2/devices/${device}`, {
          headers: { "BOND-Token": bondToken }
        });
        if (!nameRes.ok) throw new Error(`HTTP error ${nameRes.status}`);
        const nameJson = await nameRes.json();
        name = nameJson.name || "";
      } catch (err) {
        throw new Error(`ERROR: Failed to fetch device name from ${ip}`, err);
      }

      if (CFsetupOption !== "doNotConfigure") {
        if (/^[a-zA-Z0-9 ]*Fan$/.test(name)) {
          if (CFsetupOption !== "lightDimmer") {
            createFan(name, speedInterval, bondbridgeModelQueue, bondToken, device, IPA);
          }
          if (CFtimerSetup) {
            createTimerLightbulb(`${name} Timer`, "fanTimer", "fanDevice", bondbridgeModelQueue, bondToken, timerDevice, device, IPA);
          }
        }
        if (/^[a-zA-Z0-9 ]*Light$/.test(name)) {
          if (CFsetupOption === "fanLight") {
            createLightbulbNoDimmer(name, "light", bondbridgeModelQueue, bondToken, device, IPA);
          } else if (CFsetupOption === "fanLightDimmer") {
            createLightbulbWithDimmer(name, "light", speedInterval, bondbridgeModelQueue, bondToken, device, IPA);
          } else if (CFsetupOption === "lightDimmer") {
            createLightbulbWithDimmer(`${name} Dimmer`, "dimmer", speedInterval, bondbridgeModelQueue, bondToken, device, IPA);
          }
          if (CFtimerSetup && CFsetupOption !== "fan") {
            createTimerLightbulb(`${name} Timer`, "lightTimer", "lightDevice", bondbridgeModelQueue, bondToken, timerDevice, device, IPA);
          }
        }
      }
    }
  }

  //Assemble the final config
  const bondbridgeConfig = assembleBondBridgeConfig();
  return bondbridgeConfig;
}

module.exports = { createBondbridgeConfig };
