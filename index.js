"use strict";


module.exports =
{
   default: function ( api )
   {
     api.registerPlatform( "BondBridge", BondBridge );
   }
}

// Platform definition
class BondBridge
{
   constructor( log, config, api )
   {
      this.log = log;
      this.api = api;
      this.config = config;
      this.log.debug("BondBridge this.config %s", this.config);
   }
}
