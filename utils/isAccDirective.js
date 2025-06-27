'use strict';

let BB2_ACC_TYPE_ENUM = require( "../lib/BB2_ACC_TYPE_ENUM" ).BB2_ACC_TYPE_ENUM;


// Description:
//    Determine if parameter is a Bb2 accessory characteristic
//
// @param type - The characteristic type to check. i.e. "On"
// @param allowUpper - if upper case allowed to be checked.
// @returns: { type: The CORRECT characteristic type
//             accTypeEnumIndex: The index of the characteristic
//           } or null
//

function isAccDirective( type, allowUpper = false )
{
   // For backward compatability of testStoredValueForIndex of FakeGato
   // we must return a null accTypeIndex, which should be checked instead
   // of just rc.
   let defaultRc = { "type": type,
                     "accTypeEnumIndex": null
                   };

   if ( ! type )
   {
      console.warn( "No parameter passed to isBb2Directive" );
      return defaultRc;
   }

   let accTypeEnumIndex;

   // We want lower case to be correct
   accTypeEnumIndex = BB2_ACC_TYPE_ENUM.properties.Bb2indexOfEnum( i => i.sche === type )
   if ( accTypeEnumIndex >= 0 )
      return { "type": type,
               "accTypeEnumIndex": accTypeEnumIndex };

   // Note: There are othes like WiFi ... but nobody uses them thankfully !
   if ( allowUpper == true )
   {
       accTypeEnumIndex = BB2_ACC_TYPE_ENUM.properties.Bb2indexOfEnum( i => i.type === type );

      // We return the correct lower case
      if ( accTypeEnumIndex >= 0 )
         return { "type": BB2_ACC_TYPE_ENUM.properties[ accTypeEnumIndex ].sche,
                  "accTypeEnumIndex": accTypeEnumIndex };
   }

   return defaultRc;
}


module.exports = isAccDirective;
