local _G = getfenv(0)
local defiler = _G.object

defiler.heroName = "Hero_Defiler"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = defiler.core, defiler.behaviorLib

behaviorLib.StartingItems = { "Item_ManaRegen3", "Item_HealthPotion" }
behaviorLib.LaneItems = { "Item_Strength5", "Item_Astrolabe", "Item_MysticVestments", "Item_Marchers" }
behaviorLib.MidItems = { "Item_SpellShards 3", "Item_Intelligence7", "Item_Lightbrand" }
behaviorLib.LateItems = { "Item_GrimoireOfPower" }

defiler.skills = {}
local skills = defiler.skills

local tinsert = _G.table.insert

core.itemWard = nil

object.tSkills = {					--Q = 0
	0, 2, 0, 1, 0, 					--W = 1
	3, 0, 1, 2, 2, 					--E = 2
	3, 1, 2, 2, 4,					--R = 3
	3, 4, 4, 4, 4,					--Stat = 4
	4, 4, 4, 4, 4
}

function object:SkillBuild()
	local unitSelf = self.core.unitSelf
	
	if  skills.Q == nil then
		skills.Q = unitSelf:GetAbility(0)
		skills.W = unitSelf:GetAbility(1)
		skills.E = unitSelf:GetAbility(2)
		skills.R = unitSelf:GetAbility(3)
		skills.Stat = unitSelf:GetAbility(4)
	end
	
	local nPoints = unitSelf:GetAbilityPointsAvailable()
	if nPoints <= 0 then
		return
	end
	
	local nLevel = unitSelf:GetLevel()
	for i = nLevel, (nLevel + nPoints) do
		unitSelf:GetAbility( self.tSkills[i] ):LevelUp()
	end
end

local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0

  if skills.Q:CanActivate() and nLevel > 4 then
	nUtil = nUtil + 20
  end

  if skills.R:CanActivate() then
	nUtil = nUtil + 50
  end

  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)

  local unitTarget = behaviorLib.heroTarget
  local nMana = unitself:GetMana()
  
  if unitTarget == nil then
    return defiler.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())

  local bActionTaken = false
  
  -- Ultispam
  if skills.R:CanActivate() and nMana >= skills.R:GetManaCost() then
	if nTargetDistanceSq <= 600 then	
	Echo("oigeajioaegjoieagj")
	bActionTaken = core.OrderAbility(botBrain, skills.R)
  else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
	end
  end

  -- Nukespam
 if skills.Q:CanActivate() and nLevel > 4 and 
  

  if not bActionTaken then
    return defiler.harassExecuteOld(botBrain)
  end

  return bActionTaken

end
defiler.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

