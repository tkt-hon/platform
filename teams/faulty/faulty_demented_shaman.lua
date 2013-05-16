local _G = getfenv(0)
local shaman = _G.object

runfile 'bots/dementedshaman/dementedshaman_main.lua'
runfile 'bots/teams/default/utils/sitter.lua'
runfile 'bots/teams/faulty/utils.lua'

local core, behaviorLib = shaman.core, shaman.behaviorLib

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
	local nUtility = shaman.CustomHarassUtilityOld(hero)

	nUtility = nUtility + HeroStateValueUtility(hero, nNoMana, nNoHealth)
	nUtility = nUtility - HeroStateValueUtility(core.unitSelf, nNoMana, nNoHealth)

	if core.GetClosestEnemyTower(core.unitSelf:GetPosition(), 715) then
		nUtility = nUtility / 2
	end

	return nUtility
end
shaman.CustomHarassUtilityOld = behaviorLib.CustomHarassUtility
behaviorLib.CustomHarassUtility = CustomHarassUtilityOverride2
