local _G = getfenv(0)
local hammerstorm = _G.object

runfile 'bots/hammerstorm/hammerstorm_main.lua'
runfile 'bots/teams/faulty/lib/sitter.lua'
runfile 'bots/teams/faulty/lib/utils.lua'

local core, behaviorLib = hammerstorm.core, hammerstorm.behaviorLib

local function PreGameExecuteOverride(botBrain)
  local unitSelf = core.unitSelf
  if not unitSelf.isSitter then
    return behaviorLib.PreGameExecute(botBrain)
  end
  return behaviorLib.PreGameSitterExecute(botBrain)
end
behaviorLib.PreGameBehavior["Execute"] = PreGameExecuteOverride

--------------------------------------------------------------------------------
-- CUSTOM HARASS UTILITY to default custom harass utility
--
-- Don't be nearly as agressive when close to enemy towers

local nNoHealth = 20
local nNoMana   = 10

local function CustomHarassUtilityOverride2(hero)
	local nUtility = hammerstorm.CustomHarassUtilityOld(hero)

	nUtility = nUtility + HeroStateValueUtility(hero, nNoMana, nNoHealth)
	nUtility = nUtility - HeroStateValueUtility(core.unitSelf, nNoMana, nNoHealth)

	if core.GetClosestEnemyTower(core.unitSelf:GetPosition(), 715) and core.unitSelf:GetLevel() < 7 then
		nUtility = nUtility / 2
	end

	return nUtility
end
hammerstorm.CustomHarassUtilityOld = behaviorLib.CustomHarassUtility
behaviorLib.CustomHarassUtility = CustomHarassUtilityOverride2
