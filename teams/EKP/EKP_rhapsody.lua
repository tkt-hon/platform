local _G = getfenv(0)
local rhapsody = _G.object

runfile 'bots/rhapsody/rhapsody_main.lua'
runfile 'bots/teams/default/utils/sitter.lua'

local core, behaviorLib = rhapsody.core, rhapsody.behaviorLib

local function PreGameExecuteOverride(botBrain)
  local unitSelf = core.unitSelf
  if not unitSelf.isSitter then
    return behaviorLib.PreGameExecute(botBrain)
  end
  return behaviorLib.PreGameSitterExecute(botBrain)
end
behaviorLib.PreGameBehavior["Execute"] = PreGameExecuteOverride
