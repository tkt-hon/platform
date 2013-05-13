local _G = getfenv(0)
local shaman = _G.object

runfile 'bots/dementedshaman/dementedshaman_main.lua'
runfile 'bots/teams/default/utils/sitter.lua'

local core, behaviorLib = shaman.core, shaman.behaviorLib

local function PreGameExecuteOverride(botBrain)
  local unitSelf = core.unitSelf
  if not unitSelf.isSitter then
    return behaviorLib.PreGameExecute(botBrain)
  end
  return behaviorLib.PreGameSitterExecute(botBrain)
end
behaviorLib.PreGameBehavior["Execute"] = PreGameExecuteOverride
