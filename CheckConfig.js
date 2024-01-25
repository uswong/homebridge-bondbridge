const fs = require('fs')
const chalk = require('chalk')
const commandExistsSync = require( "command-exists" ).sync;

// Parse the args
var args = process.argv.slice(2);
const BONDBRIDGE_SH_PATH = args[0] || "/usr/local/lib/node_modules/homebridge-bondbridge/BondBridge.sh";
const homebridgeConfigPath = args[1] || "/var/lib/homebridge/config.json";

let listOfConstants = { };
var debug = false;

consoleLog(`ADVAIR_path=${BONDBRIDGE_SH_PATH}`)
consoleLog(`configJsonPath=${homebridgeConfigPath}`)

checkInstallationButtonPressed( true )

function consoleLog( msg )
{
   if ( debug ) { 
      console.log( msg );
   }
}

function message( data )
{
   console.log( data );
}

function checkQueueTypesForQueue( queueTypes, queue )
{
   for ( let queueTypesIndex = 0; queueTypesIndex < queueTypes.length; queueTypesIndex++ )
   {
      let entry = queueTypes[ queueTypesIndex ];
      if ( entry.queue == queue )
      {
         if ( entry.queueType == "WoRm2" )
         {
            return(
            { rc: true,
              message: `passed`
            });
         }
         return(
         { rc: false,
           message: `queue ${ queue } queueType is not WoRm2. Please change to Worm2.`
         });
      }
   }

   return(
   { rc: false,
      message: `No matching queue: "${ queue }" in queueTypes`
   });
}

// MyPlace platform has the ability to allow constants which could be used for the IP
function processConstants( constantsArgArray )
{
   //
   // Check #8A
   // Constants must be an Array
   //
   consoleLog( `Check #8A` );
   if ( ! Array.isArray ( constantsArgArray ) )
   {
      message( chalk.red( `ERROR: Constants must be an array of { "key": "\${SomeKey}", "value": "some replacement string" }` ) )
      return false;
   }
   // Iterate over the groups of key/value constants in the array.
   // Note: DO NOT USE: forEach as javascript continues after a return!
   for ( let argIndex = 0; argIndex < constantsArgArray.length; argIndex++ )
   {
      let argEntry = constantsArgArray[ argIndex ];

      if ( argEntry.key == undefined )
      {
         //
         // Check #8B
         // key must be defined
         //
         consoleLog( `Check #8B` );
         message( chalk.red( `ERROR: Constant definition at index: "${ argIndex }" has no "key":` ) )
         return false;
      }

      if ( argEntry.value == undefined )
      {
         //
         // Check #8c
         // value must be defined
         //
         consoleLog( `Check #8C` );
         message( chalk.red( `ERROR: Constant definition at index: "${ argIndex }" has no "value":` ) )
         return false;
      }

      let keyToAdd = argEntry.key;
      let valueToAdd = argEntry.value;
      if ( ! keyToAdd.startsWith( "${" ) )
      {
         //
         // Check #8D
         // key must start with ${
         //
         consoleLog( `Check #8D` );
         message( chalk.red( `ERROR: Constant definition for: "${ keyToAdd }" must start with "\${" for clarity.` ) )
         return false;
      }

      if ( ! keyToAdd.endsWith( "}" ) )
      {
         //
         // Check #8E
         // key must end with }
         //
         consoleLog( `Check #8E` );
         message( chalk.red( `ERROR: Constant definition for: "${ keyToAdd }" must end with "}" for clarity.` ) )
         return false;
      }

      // remove any leading and trailing single quotes
      // so that using it for replacement will be easier.
      valueToAdd.replace(/^'/, "")
      valueToAdd.replace(/'$/, "")

      if ( debug )
         console.log( chalk.cyan( `CheckConfig keyToAdd:${keyToAdd} valueToAdd:${valueToAdd}` ) );

      listOfConstants[ keyToAdd ] = valueToAdd;
   }

   return true;
}

function replaceConstantsInString( orig )
{
   let finalAns = orig;

   for ( let key in listOfConstants )
   {
      let replacementConstant = listOfConstants[ key ];

      if ( debug )
         console.log( chalk.cyan( `INFO: replacing key: ${ key } with: ${ replacementConstant }` ) );

      finalAns = finalAns.replace( key, replacementConstant );
   }
   return finalAns;
}

function updateConfigFirstTime( firstTime )
{
   //
   // Check #1
   // See if the config.json file exists
   //
   consoleLog( `Check #1` );
   let configFile = homebridgeConfigPath;

   if ( configFile == undefined )
   {
      message( chalk.red( `ERROR: No config.json found or specified` ) )
      return false;
   }

   if ( ! fs.existsSync( configFile ) )
   {
      if ( ! firstTime )
      {
         message( chalk.red( `ERROR: No ${ configFile } found or specified` ) )
      }

      return false;
   }

   // Open the config.json file for reading
   let config_in = fs.readFileSync( configFile, 'utf8' );

   //
   // Check #2
   // Convert the config.json into a json type
   // This can throw an Error so catch it.
   consoleLog( `Check #2` );
   try {
      this.config = JSON.parse( config_in );
   } catch ( e )
   {
      if ( ! firstTime )
      {
         message( chalk.red( `ERROR: Parse config.json failed: ${ e }` ) )
      }
      return false;
   }

   let myPlaceBondBridgeConfig = this.config.platforms.find( platform => platform[ "BondBridge" ] !== null );

   if ( myPlaceBondBridgeConfig && myPlaceBondBridgeConfig.debug )
   {
      console.log( `Setting debug for BondBridge` );
      debug = myPlaceBondBridgeConfig.debug;
   }

   return true;
}


// There is nothing really to differentiate a regular Accessory for that of
// an Bond Bridge
//
function isAccessoryAbondBridge( accessory )
{
   if ( accessory.manufacturer && accessory.manufacturer.match( /Bond Bridge/ ) )
      return true;

   // Trigger off of the state_cmd, if it exists
   if ( accessory.state_cmd != undefined )
   {
      // The new BondBridge 
      if ( accessory.state_cmd.match( /BondBridge.sh/ ) )
         return true;
   }

   return false;
}

function checkInstallationButtonPressed( )
{
   // The read in config.json in JSON format

   if ( debug )
      console.log( chalk.cyan( `INFO: CheckConfig is now in the process of checking the config.json` ) );

   // Update the config, this is not the first time
   // return if it fails. As this is not the First time, it will
   // error if need be.
   if ( updateConfigFirstTime( false ) == false )
      return;

   //
   // Check #3
   // Check that jq is installed.
   consoleLog( `Check #3` );
   if ( ! commandExistsSync( "jq" ) )
   {
      message( chalk.red( `ERROR: jq is required globally and not installed.` ) )
      return;
   }

   //
   // Check #4
   // Check that curl is installed.
   consoleLog( `Check #4` );
   if ( ! commandExistsSync( "curl" ) )
   {
      message( chalk.red( `ERROR: curl is required globally and not installed.` ) )
      return;
   }

   //
   // Check #5 is already done before calling this CheckConfig.js    
   // Check #5A
   // Find Node modules
   //
   // console.log( `Check #5A` );
   // let node_modules = getGlobalNodeModulesPathForFile( "" );
   // if ( node_modules == null )
   // {
   //    message( chalk.red( `ERROR: Could not determine where node_modules is installed globally.` ) )
   //    return;
   // }
   //
   // Check #5B
   // See if MyPlace is installed from node_modules
   //
   // fileToFind = "/homebridge-myplace/index.js";
   // let myPlaceIndex = getGlobalNodeModulesPathForFile( fileToFind )
   // if ( myPlaceIndex == null )
   // {
   //    message( chalk.red( `ERROR: MyPlace Plugin not installed` ) )
   //    return;
   // }

   //
   // Check #6
   // See if our BondBridge.sh script is present
   //
   // Create the path to the BondBridge.sh from node_modules
   consoleLog( `Check #6` );
   let ourScript =  BONDBRIDGE_SH_PATH
   if ( ourScript == null )
   {
      message( chalk.red( `ERROR: No BondBridge.sh script present. Looking for: <Your Global node_modules Path>${ this.BONDBRIDGE_SH }` ) )
      return;
   }

   let myPlaceAccessoriesFound = false;
   let bondbridgeAccessoriesFound = [];
   let myPlaceQueueTypesFound = [];
   let retVal = { };
   // Iterate over the elements in the array.
   // Note: DO NOT USE: forEach as javascript continues after a return!
   for ( let entryIndex = 0; entryIndex < this.config.platforms.length; entryIndex++ )
   {
      let entry = this.config.platforms[ entryIndex];

      if ( debug )
         console.log( chalk.cyan( `INFO: CheckConfig is checking Platform entry ${ entry.platform }` ) );

      //
      // Check #7
      // See if any MyPlace accessories are defined in config.json
      //
      consoleLog( `Check #7` );
      if ( entry.platform != "MyPlace" )
         continue;

      myPlaceAccessoriesFound = true;

      //
      // Check #18
      // See if there are any accessory queues defined
      //
      consoleLog( `Check #18` );
      if ( entry.queueTypes != undefined )
      {
         //
         // Check #19
         // queueTypes must be an array
         //
         consoleLog( `Check #19` );
         if ( ! Array.isArray( entry.queueTypes ) )
         {
            message( chalk.red( `ERROR: queueTypes is not an Array` ) )
            return;
         }

         // Iterate over the elements in the array.
         // Note: DO NOT USE: forEach as javascript continues after a return!
         for ( let queueTypesIndex = 0; queueTypesIndex < entry.queueTypes.length; queueTypesIndex++ )
         {
            let queueTypeEntry = entry.queueTypes[ queueTypesIndex ];

            // Need to append each one
            retVal =  checkQueueTypesForQueue( myPlaceQueueTypesFound, queueTypeEntry.queue );
            if ( retVal.rc == true )
            // if ( myPlaceQueueTypesFound.find( queueTypeEntry ) )
            {
               //
               // Check #20
               // Duplicate queue
               //
               consoleLog( `Check #20` );
               message( chalk.red( `ERROR: Duplicate queue found: ${ queueTypeEntry.queue }` ) )
               return;
            }
            myPlaceQueueTypesFound.push( queueTypeEntry );
         }
      }

      //
      // Check #8
      // Process Constants
      //
      consoleLog( `Check #8` );
      if ( entry.constants != undefined )
         if ( processConstants( entry.constants ) == false )
            return;

      // Iterate over the elements in the array.
      // Note: DO NOT USE: forEach as javascript continues after a return!
      for ( let accessoryIndex = 0; accessoryIndex < entry.accessories.length; accessoryIndex++ )
      {
         let accessory = entry.accessories[ accessoryIndex ];

         if ( debug )
            console.log(  chalk.cyan( `INFO: CheckConfig is checking accessory ${ accessory.name }` ) );

         //
         // Check #9
         // See if any Bond Bridge accessories are defined in config.json
         //
         consoleLog( `Check #9` );
         if ( ! isAccessoryAbondBridge( accessory ) )
            continue;

         //
         // Check #10
         // See if any Bond Bridge accessory has a defined name
         //
         consoleLog( `Check #10` );

         if ( debug )
            console.log( chalk.cyan( `INFO: CheckConfig is checking accessory ${ accessory.name }` ) );

         if ( accessory.name == undefined )
         {
            message( chalk.red( `ERROR: Accessory at index: ${ entryIndex } accessory.name is undefined` ) )
            return;
         }

         //
         // Check #11
         // See if any Bond Bridge accessory has a defined displayName
         //
         consoleLog( `Check #11` );

         if ( debug )
            console.log( chalk.cyan( `INFO: CheckConfig is checking accessory ${ accessory.name } for displayName` ) );

         if ( accessory.displayName == undefined )
         {
            message( chalk.red( `ERROR: Accessory at index: ${ entryIndex } "${ accessory.name }" has no displayName` ) )
            return;
         }

         //
         // Check #12
         // Polling is done by displayName, It cannot already exist.
         //
         consoleLog( `Check #12` );

         if ( debug )
            console.log( chalk.cyan( `INFO: CheckConfig is Checking accessory ${ accessory.displayName } for duplicate displayName` ) );

         if ( bondbridgeAccessoriesFound.find( ( displayName ) => displayName == accessory.displayName ) )
         {
            message( chalk.red( `ERROR: Accessory: "${ accessory.displayName }"'s displayName is defined twice` ) )
            return;
         }


         // Add it to the Array
         bondbridgeAccessoriesFound.push( accessory.displayName );

         if ( debug )
            console.log( chalk.cyan( `INFO: CheckConfig is Checking Bond Bridge accessory ${ accessory.displayName }` ) );

         //
         // Check #13
         // The state_cmd must be defined for the Air accessory
         //
         consoleLog( `Check #13` );
         if ( accessory.state_cmd == undefined )
         {
            message( chalk.red( `ERROR: No state_cmd for: "${ accessory.displayName }"` ) )
            return;
         }

         //
         // Check #14
         // See if the state_cmd does not match the BondBridge.sh
         //
         consoleLog( `Check #14` );
         if ( ! accessory.state_cmd.match( ourScript ) )
         {
            message( chalk.red( `ERROR: Invalid state_cmd for: "${ accessory.displayName }". It should be:\n${ ourScript }` ) )
            return;
         }

         //
         // Check #15
         // See if the state_cmd_suffix is defined for the Air accessory
         // It must have at least an IP
         consoleLog( `Check #15` );
         if ( accessory.state_cmd_suffix == undefined )
         {
            message( chalk.red( `ERROR: No state_cmd_suffix for: "${ accessory.displayName }". It must at least contain an IP.` ) )
            return;
         }

         if ( debug )
            console.log( chalk.cyan( `INFO: Calling replaceConstantsInString` ) );

         let state_cmd_suffix = replaceConstantsInString(  accessory.state_cmd_suffix );

         if ( debug )
            console.log( chalk.cyan( `INFO: after replaceConstantsInString state_cmd_suffix=${ state_cmd_suffix }` ) );

         //
         // Check #16A
         // The state_cmd_suffix must have an IP for the BondBridge accessory
         //
         if ( ! state_cmd_suffix.match( /[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/ ) )
         {
            this.advError(
            { "rc": false,
              "message": `state_cmd_suffix has no IP for: "${ accessory.displayName }" state_cmd_suffix: ${ state_cmd_suffix }`
            });
            return;
         }

         //
         // Check #16B
         // The state_cmd_suffix must have a 'token: for the BondBridge accessory
         //
         if ( ! state_cmd_suffix.match( /'token:[a-f0-9]*'/ ) )
         {
            this.advError(
            { "rc": false,
              "message": `state_cmd_suffix has no 'token' defined for: "${ accessory.displayName }" state_cmd_suffix: ${ state_cmd_suffix }`
            });
            return;
         }

         //
         // Check #16C
         // The state_cmd_suffix must have a 'device: for the BondBridge accessory
         //
         if ( ! state_cmd_suffix.match( /'device:[a-f0-9]*'/ ) )
         {
            this.advError(
            { "rc": false,
              "message": `state_cmd_suffix has no 'device' defined for: "${ accessory.displayName }" state_cmd_suffix: ${ state_cmd_suffix }`
            });
            return;
         }

         //
         // Check #17A
         // The state_cmd_suffix must have a fanSwitch or a lightSwitch for a BondBridge Switch accessory
         //
         if ( accessory.type.match( /^Switch/ ) )
         {
            if ( ! ( state_cmd_suffix.match( /fanSwitch/ ) ||
                 state_cmd_suffix.match( /lightSwitch/ ) ) )
            {
               this.advError(
               { "rc": false,
                 "message": `The state_cmd_suffix for: "${ accessory.displayName }" requires a 'fanSwitch' or a key word 'lightSwitch'.`
               });
               return;
            }
         }

         //
         // Check #17B
         // The state_cmd_suffix must have a 'fan ' for a Fan accessory
         //
         if ( accessory.type.match( /^Fan/ ) )
         {
            if ( ! state_cmd_suffix.match( /fan / ) )
            {
                this.advError(
                { "rc": false,
                  "message": `The state_cmd_suffix for: "${ accessory.displayName }" requires a key word 'fan'.`
                });
                return;
            }
         }

         //
         // Check #17C
         // The state_cmd_suffix must have a 'light ', 'lightTimer', 'lightDevice', 'fanDevice' or 'fanTimer' for a Lightbulb accessory
         //
         if ( accessory.type.match( /^Lightbulb/ ) )
         {
            if ( ! ( state_cmd_suffix.match( /light / ) ||
               state_cmd_suffix.match( /dimmer / )   ||
               state_cmd_suffix.match( /lightTimer/ )   ||
               state_cmd_suffix.match( /fanTimer/ ) ) )
            {
               this.advError(
               { "rc": false,
                 "message": `The state_cmd_suffix for: "${ accessory.displayName }" requires a keyword 'light ' or 'lightTimer' or 'fanTimer'.`
               });
               return;
            }

            //
            // Check #17C1
            // if state_cmd_suffix has lightTimer, then it must also has lightDevice
            //
            if ( state_cmd_suffix.match( /lightTimer/ ) )
            {
               if ( ! state_cmd_suffix.match( /'lightDevice:[a-f0-9]*'/ ) )
               {
                  this.advError(
                  { "rc": false,
                    "message": `The state_cmd_suffix for: "${ accessory.displayName }" requires a keyword 'lightDevice'.`
                  });
                  return;
               }
            }

            //
            // Check #17C2
            // if state_cmd_suffix has fanTimer, then it must also has fanDecive
            //
            if ( state_cmd_suffix.match( /fanTimer/ ) )
            {
               if ( ! state_cmd_suffix.match( /'fanDevice:[a-f0-9]*'/ ) )
               {
                  this.advError(
                  { "rc": false,
                    "message": `The state_cmd_suffix for: "${ accessory.displayName }" requires a keyword 'fanDevice'.`
                  });
                  return;
               }
            }
         }

         //
         // Check #21
         // See if there is a queue defined
         //
         consoleLog( `Check #21`);
         if ( accessory.queue == undefined )
         {
            message( chalk.red( `ERROR: No queue defined for: "${ accessory.displayName }"` ) )
            return;
         }

         //
         // Check #22
         // queue name must be an string
         //
         consoleLog( `Check #22`);
         if ( typeof accessory.queue != "string" )
         {
            message( chalk.red( `ERROR: queue for: "${ accessory.displayName }" is not a string` ) )
            return;
         }

         retVal = checkQueueTypesForQueue( myPlaceQueueTypesFound, accessory.queue );
         // Check #23
         // queue must be defined in queueTypes
         consoleLog( `Check #23`);
         if ( retVal.rc == false )
         {
            message( chalk.red( `ERROR: For: "${ accessory.displayName }" ${ retVal.message }` ) )
            return;
         }

         // Check #24 Polling must be defined for BondBridge accessories
         consoleLog( `Check #24`);
         if ( ! accessory.polling ||
              ( typeof accessory.polling == "boolean" && accessory.polling != true &&
              ! Array.isArray( accessory.polling) ) )
         {
            message( chalk.red( `ERROR: Polling for: "${ accessory.displayName }" is not an Array or Boolean` ) )
            return;
         }
      }
   }

   //
   // Check #32
   // See if any MyPlace accessories are defined in config.json
   //
   consoleLog( `Check #32`);
   if ( myPlaceAccessoriesFound == false )
   {
      message( chalk.red( `ERROR: No MyPlace Accessories found` ) )
      return;
   }

   //
   // Check #33
   // See if any Bond Bridge accessories are defined in config.json
   //
   consoleLog( `Check #33`);
   if ( bondbridgeAccessoriesFound.length == 0 )
   {
      message( chalk.red( `ERROR: No Bond Bridge Accessories found` ) )
      return;
   }

   //
   // Check #34
   // See if any queueTypes were defined
   // ( Most likely an earlier failure will succeed this one )
   //
   consoleLog( `Check #34`);
   if ( myPlaceQueueTypesFound == null )
   {
      message( chalk.red( `ERROR: No MyPlace Queue Types were defined for Bond Bridge Accessories` ) )
      return;
   }

   // PASS !
   message( chalk.green( chalk.bold ( `PASSED` ) ) )
}
