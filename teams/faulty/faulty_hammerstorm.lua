local _G = getfenv(0)
local hammerstorm = _G.object

runfile 'bots/hammerstorm/hammerstorm_main.lua'
runfile 'bots/teams/default/utils/sitter.lua'

local core, behaviorLib = hammerstorm.core, hammerstorm.behaviorLib

local function PreGameExecuteOverride(botBrain)
  local unitSelf = core.unitSelf
  if not unitSelf.isSitter then
    return behaviorLib.PreGameExecute(botBrain)
  end
  return behaviorLib.PreGameSitterExecute(botBrain)
end
behaviorLib.PreGameBehavior["Execute"] = PreGameExecuteOverride
