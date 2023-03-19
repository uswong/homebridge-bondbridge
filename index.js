"use strict";


module.exports =
{
   default: function ( api )
   {
     api.registerPlatform( "cmd4BondBridge", Cmd4BondBridge );
   }
}

// Platform definition
class Cmd4BondBridge
{
   constructor( log, config, api )
   {
      this.log = log;
      this.api = api;
      this.config = config;
      this.log.debug("cmd4BondBridge this.config %s", this.config);
   }
}
