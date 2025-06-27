'use strict';

// These would already be initialized by index.js
let BB2_ACC_TYPE_ENUM = require( "../lib/BB2_ACC_TYPE_ENUM" ).BB2_ACC_TYPE_ENUM;

class Bb2Storage
{
   constructor( log, bb2Storage )
   {
      this.CLASS_VERSION = 1;
      this.DATA = [ ];

      if ( bb2Storage == undefined )
      {
         log.debug("Init new bb2Storage" );

         // init new
         this.DATA = new Array( BB2_ACC_TYPE_ENUM.EOL ).fill( null );

      } else if ( bb2Storage instanceof Bb2Storage )
      {
         log.debug("Class is Bb2Storage version: %s", bb2Storage.version );
         if ( bb2Storage.CLASS_VERSION == this.CLASS_VERSION )
         {
            // The same. I can just load its data
            this.loadLatestData( bb2Storage.DATA );
         } else {
            throw new Error( `Do not know how to handle Bb2_Storage Class version: ${ bb2Storage.CLASS_VERSION }` );
         }
      } else if ( Array.isArray( bb2Storage ) )
      {
         log.debug("Bb2Storage is Array" );
         // Init original unversioned
         let data = this.upgradeDataArray( 0, bb2Storage );
         this.loadLatestData( data );

      } else if ( bb2Storage.constructor === Object )
      {
         log.debug("Bb2Storage is Object version %s", bb2Storage.CLASS_VERSION );
         if ( bb2Storage.CLASS_VERSION == this.CLASS_VERSION )
         {
            // The same. I can just load its data
            this.loadLatestData( bb2Storage.DATA );
         } else {
            throw new Error( `Do not know how to handle Bb2_Storage Class version: ${ bb2Storage.CLASS_VERSION }` );
         }
      } else
      {
         // Woops init new
         log.error( "bb2Storage is %s", bb2Storage );
         console.error( "bb2Storage.constructor.name is %s", bb2Storage.constructor.name );
         throw new Error( `Do not know how to handle typeof: ${ typeof bb2Storage } Bb2_Storage parm: ${ bb2Storage }` );
      }
   }

   upgradeDataArray( fromVersion, fromData)
   {
      let data = [ ];

      if ( fromVersion != 0 )
         throw new Error( `Do not know how to handle Bb2_Storage version: ${ fromVersion }` );

      // Version 0 ACC_DATA went from 0-122
      // This version goes from 1-123 and changes to
      // Assoc array so that index changes like this will no longer
      // impact the storage schema as much
      let i=0;
      for ( i=0; i < BB2_ACC_TYPE_ENUM.ListPairings; i++ )
      {
         data[ i ] = fromData[ i ];
      }
      data[ BB2_ACC_TYPE_ENUM.ListPairing ] = null;
      for ( i = BB2_ACC_TYPE_ENUM.ListPairings +1; i < BB2_ACC_TYPE_ENUM.EOL; i++ )
      {
         data[ i ] = fromData[ i - 1 ];
      }
      return data;
   }

   loadLatestData( data )
   {
      this.DATA = data;
   }

   getStoredValueForIndex( accTypeEnumIndex )
   {
      if ( accTypeEnumIndex < 0 || accTypeEnumIndex >= BB2_ACC_TYPE_ENUM.EOL )
         throw new Error( `getStoredValue - Characteristic index: ${ accTypeEnumIndex } not between 0 and ${ BB2_ACC_TYPE_ENUM.EOL }\nCheck your config.json file for unknown characteristic.` );


      return this.DATA[ accTypeEnumIndex ];
   }

   getStoredValueForCharacteristic( characteristicString )
   {
      let accTypeEnumIndex = BB2_ACC_TYPE_ENUM.Bb2indexOfEnum( characteristicString );

      return this.getStoredValueForIndex( accTypeEnumIndex );
   }
   setStoredValueForIndex( accTypeEnumIndex, value )
   {
      if ( accTypeEnumIndex < 0 || accTypeEnumIndex >= BB2_ACC_TYPE_ENUM.EOL )
         throw new Error( `setStoredValue - Characteristic index: ${ accTypeEnumIndex } not between 0 and ${ BB2_ACC_TYPE_ENUM.EOL }\nCheck your config.json file for unknown characteristic.` );

      this.DATA[ accTypeEnumIndex  ] = value;
   }
   setStoredValueForCharacteristic( characteristicString, value )
   {
      let accTypeEnumIndex = BB2_ACC_TYPE_ENUM.Bb2indexOfEnum( characteristicString );

      this.setStoredValueForIndex( accTypeEnumIndex, value );
   }

   // Unlike get/set, testStoredValueForIndex does not call process.exit,
   // but undefined for an illegal range, in the case that rogue runtime data
   // dies not take down BB2.
   testStoredValueForIndex( accTypeEnumIndex )
   {
      if ( accTypeEnumIndex < 0 || accTypeEnumIndex > BB2_ACC_TYPE_ENUM.EOL )
         return undefined;

      return this.DATA[ accTypeEnumIndex ];
   }
   testStoredValueForCharacteristic( characteristicString )
   {
      let accTypeEnumIndex = BB2_ACC_TYPE_ENUM.Bb2indexOfEnum( characteristicString );

      return this.testStoredValueForIndex( accTypeEnumIndex );
   }
}

module.exports = Bb2Storage;
