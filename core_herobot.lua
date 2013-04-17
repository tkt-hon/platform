local _G = getfenv(0)
local herobot = _G.object

function herobot.UseOriginal()
  object.myName = object:GetName()

  object.bRunLogic         = true
  object.bRunBehaviors    = true
  object.bUpdates         = true
  object.bUseShop         = true

  object.bRunCommands     = true
  object.bMoveCommands     = true
  object.bAttackCommands     = true
  object.bAbilityCommands = true
  object.bOtherCommands     = true

  object.bReportBehavior = false
  object.bDebugUtility = false

  object.logger = {}
  object.logger.bWriteLog = false
  object.logger.bVerboseLog = false

  object.core = {}
  object.eventsLib = {}
  object.metadata = {}
  object.behaviorLib = {}
  object.skills = {}

  runfile "bots/core.lua"
  runfile "bots/botbraincore.lua"
  runfile "bots/eventsLib.lua"
  runfile "bots/metadata.lua"
  runfile "bots/behaviorLib.lua"
end
