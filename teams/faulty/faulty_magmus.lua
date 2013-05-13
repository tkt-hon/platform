local _G = getfenv(0)
local magmus = _G.object

runfile 'bots/magmus/magmus_main.lua'
runfile 'bots/teams/default/utils/sitter.lua'

local core, behaviorLib = magmus.core, magmus.behaviorLib

local function PreGameExecuteOverride(botBrain)
  local unitSelf = core.unitSelf
  if not unitSelf.isSitter then
    return behaviorLib.PreGameExecute(botBrain)
  end
  return behaviorLib.PreGameSitterExecute(botBrain)
end
behaviorLib.PreGameBehavior["Execute"] = PreGameExecuteOverride
