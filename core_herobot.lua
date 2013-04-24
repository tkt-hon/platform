local _G = getfenv(0)
local herobot = _G.object

herobot.myName = herobot:GetName()

herobot.bRunLogic = true
herobot.bRunBehaviors = true
herobot.bUpdates = true
herobot.bUseShop = true

herobot.bRunCommands = true
herobot.bMoveCommands = true
herobot.bAttackCommands = true
herobot.bAbilityCommands = true
herobot.bOtherCommands = true

herobot.bReportBehavior = false
herobot.bDebugUtility = false

herobot.logger = {}
herobot.logger.bWriteLog = false
herobot.logger.bVerboseLog = false

herobot.core = {}
herobot.eventsLib = {}
herobot.metadata = {}
herobot.behaviorLib = {}
herobot.skills = {}

runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventsLib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorLib.lua"

local core = herobot.core

function herobot:SkillBuild()
  core.VerboseLog("skillbuild()")

  local unitSelf = self.core.unitSelf
  if unitSelf:GetAbilityPointsAvailable() <= 0 then
    return
  end

  local tSkills = {
    0, 1, 0, 1, 0,
    3, 0, 1, 1, 2,
    3, 2, 2, 2, 4,
    3, 4, 4, 4, 4,
    4, 4, 4, 4, 4
  }

  local nlev = unitSelf:GetLevel()
  local nlevpts = unitSelf:GetAbilityPointsAvailable()
  local nStartPoint = 1+nlev-nlevpts
  for i = nStartPoint, nlev do
    unitSelf:GetAbility( tSkills[i] ):LevelUp()
  end
end
