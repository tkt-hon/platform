local _G = getfenv(0)
local herobot = _G.object

herobot.myName = herobot:GetName()
local debug = string.find(herobot.myName, "DropTable") ~= nil
if debug then print("Debug enabled for hero: " .. herobot.myName .. "\n") end

herobot.bRunLogic = true
herobot.bRunBehaviors = true
herobot.bUpdates = true
herobot.bUseShop = true

herobot.bRunCommands = true
herobot.bMoveCommands = true
herobot.bAttackCommands = true
herobot.bAbilityCommands = true
herobot.bOtherCommands = true

object.bDebugUtility = debug
object.bReportBehavior = debug
object.bDebugLines = debug
object.bDebugPositioning = debug

herobot.logger = {}
herobot.logger.bWriteLog = false
herobot.logger.bVerboseLog = false

herobot.core = {}
herobot.eventsLib = {}
herobot.metadata = {}
herobot.behaviorLib = {}
herobot.skills = {}

runfile "bots/builtin/core.lua"
runfile "bots/builtin/botbraincore.lua"
runfile "bots/builtin/eventslib.lua"
runfile "bots/builtin/metadata.lua"
runfile "bots/builtin/behaviorlib.lua"

object.behaviorLib.nBehaviorAssessInterval = 50 -- MORE APM!!!! default 250
object.behaviorLib.nPositionSelfAllySeparation = 250 -- Useful for team AI
object.behaviorLib.nCreepPushbackMul = 0.2 -- Stay closer to creep wave, default 1

local core = herobot.core
core.nDifficulty = core.nHARD_DIFFICULTY

object.tSkills = {
  0, 1, 0, 1, 0,
  3, 0, 1, 1, 2,
  3, 2, 2, 2, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}

function herobot:SkillBuild()
  core.VerboseLog("skillbuild()")

  local unitSelf = self.core.unitSelf
  if unitSelf:GetAbilityPointsAvailable() <= 0 then
    return
  end

  local nlev = unitSelf:GetLevel()
  local nlevpts = unitSelf:GetAbilityPointsAvailable()
  local nStartPoint = 1+nlev-nlevpts
  for i = nStartPoint, nlev do
    unitSelf:GetAbility( self.tSkills[i] ):LevelUp()
  end
end
