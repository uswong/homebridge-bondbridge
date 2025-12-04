### Homebridges-Bondbridge - An independent plugin for Homebridge bringing Hunter Pacific Ceiling Fan LOGIC Remote Control to Homekit via Bond Bridge

##### v2.3.5 (04-12-2025)
##### (1) Enhancement: Added automatic Bond device discovery when no valid Bond device is found in the input configuration. If discovery fails, the system will fall back to the cached configuration.
##### (2) Bug fix: Fixed an issue of timers' state shown as ON on homebridge restart.

##### v2.3.4 (15-11-2025)
##### (1) Improvement 1: Added support for identifying Bond Bridge devices by either Bond ID or IP address.
##### (2) Improvement 2: Implemented rety logic for temporarily unreachable devices up to 5 retries at 5-seconds interval.
##### (3) Enhancement: Added fallback to cached configuration when no devices is accessible on the local network.

##### v2.3.3 (22-10-2025)
###### (1) Stability improvements: Bug fixes and under-the-hood enhancements for improved reliability and robustness.

##### v2.3.2 (11-09-2025)
###### (1) Increased maxBuffer for spawnSyn to 5 MB
###### (2) Added debugging switch for the plugin

##### v2.3.1 (23-07-2025)
###### (1) Minor bug fix                 
###### (2) Homebridge verified

##### v2.3.0 (27-06-2025)
###### (1) Simplified the setup procedure
###### (2) Made it independent of other plugins

##### v2.2.8 (30-12-2024)
###### (1) Updated compatibility in the package json file for node 22
###### (2) Minor under the hood code changes for more efficient running of the plugin

##### v2.2.7 (27-09-2024)
###### (1) Bug fixes to ConfigCreator.sh and CheckConfig.sh
###### (2) Minor update to README.md

##### v2.2.6 (25-09-2024)
###### (1) Re-coded ConfigCreator to use jq throughout

##### v2.2.5 (15-02-2024)
###### (1) Minor update to README.md

##### v2.2.4 (08-02-2024)
###### (1) Bug fixes in "index.html" for Mac users.

##### v2.2.3 (08-02-2024)
###### (1) Added more Ceiling Fan setup options.
