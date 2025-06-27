"use strict";
//
//                           Homebridge
// Flow                     /          \
//                         /            \
//      api.registerPlatform             api.registerAccessory
//     forEach Accessories{ }        Any { } before/after Accessories{ }
//         Bb2Platform                      Bb2Accessory
//         Bb2Accessory
//
//
//
//
//
//
//
//
//
//
// The Bb2 Classes
const Bb2Accessory = require( "./Bb2Accessory" ).Bb2Accessory;
const Bb2Platform = require( "./Bb2Platform" ).Bb2Platform;

const settings = require( "./bb2Settings" );

// Pretty colors
const chalk = require( "chalk" );

// The Library files that know all.
var CHAR_DATA = require( "./lib/BB2_CHAR_TYPE_ENUMS" );
var ACC_DATA = require( "./lib/BB2_ACC_TYPE_ENUM" );
var DEVICE_DATA = require( "./lib/BB2_DEVICE_TYPE_ENUM" );

module.exports =
{
   default: function ( api )
   {
      // Init the libraries for all to use
      let BB2_CHAR_TYPE_ENUMS = CHAR_DATA.init( api.hap.Formats, api.hap.Units, api.hap.Perms );
      let BB2_ACC_TYPE_ENUM = ACC_DATA.init( api.hap.Characteristic, api.hap.Formats, api.hap.Units, api.hap.Perms );
      let BB2_DEVICE_TYPE_ENUM = DEVICE_DATA.init(
         BB2_ACC_TYPE_ENUM, api.hap.Service, api.hap.Characteristic, api.hap.Categories );

      api.registerAccessory( settings.PLATFORM_NAME, Bb2Accessory );
      api.registerPlatform( settings.PLATFORM_NAME, Bb2Platform );

      // check for new release of this plugin
      setTimeout( checkForUpdates, 1800 );

   }
}

function checkForUpdates( )
{
   // Don't show the updates message in mocha test mode
   if ( process.argv.includes( "test/mocha-setup" ) )
      return;

   const { getLatestVersion, isVersionNewerThanPackagedVersion }  = require( "./utils/versionChecker" );
   const myPkg = require( "./package.json" );

   ( async( ) =>
   {
      // Fix for #127, constant crash loops when no internet connection
      // trying to get latest Bb2 version.
      // thx nano9g
      try
      {
         let lv = await getLatestVersion( );

         if ( isVersionNewerThanPackagedVersion( lv ) )
         {
            console.log( chalk.green( `[UPDATE AVAILABLE] ` ) + `Version ${lv} of ${myPkg.name} is available. Any release notes can be found here: ` + chalk.underline( `${myPkg.changelog}` ) );
         }

      }
      catch( error )
      {
         console.log( chalk.yellow( `[UPDATE CHECK FAILED] ` ) + `Could not check for newer versions of ${myPkg.name} due to error ${error.name}: ${error.message}`)
      }
   })( );
}
