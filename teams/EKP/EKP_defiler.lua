local _G = getfenv(0)
local defiler = _G.object

defiler.heroName = "Hero_Defiler"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = defiler.core, defiler.behaviorLib

behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "5 Item_HealthPotion" }
behaviorLib.LaneItems = { "Item_GraveLocket", "Item_Marchers", "Item_Steamboots" }
behaviorLib.MidItems = { "Item_FrostfieldPlate", "Item_SacrificialStone"}
behaviorLib.LateItems = { "Item_Energizer", "Item_Damage9" }


defiler.skills = {}
local skills = defiler.skills

local tinsert = _G.table.insert

core.itemWard = nil

object.tSkills = {					--Q = 0
	0, 2, 0, 2, 0, 					--W = 1
	3, 0, 2, 2, 4, 					--E = 2
	3, 4, 4, 4, 4,					--R = 3
	3, 4, 4, 4, 4,					--Stat = 4
	4, 1, 1, 1, 1
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
--------------------------------------
-- Harass Utility Override          --
--------------------------------------
local function CustomHarassUtilityFnOverride(hero)
  
  local nUtil = 0
  local nLevel = core.unitSelf:GetLevel()  
  local nHpPercent = core.unitSelf:GetHealthPercent()

  if skills.Q:CanActivate() and nLevel > 4 then
	nUtil = nUtil + 25
  end

  if skills.R:CanActivate() then
	nUtil = nUtil + 50
  end

  if nHpPercent < 0.4 then
	nUtil = nUtil - 20
  end
  return nUtil
end

behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

--------------------------------------
-- Heal at well utility override    --
--------------------------------------

local function HealAtWellLogicOverride(botBrain)
  
  local nHpPercent = core.unitSelf:GetHealthPercent()
  local nManaPercent = core.unitSelf:GetManaPercent()
  local nUtility = 0

  if nManaPercent < 0.15 then 
	nUtility = 30
  end

  if nHpPercent < 0.2 then
	nUtility = 80
  end

  if nUtility = 0 then
	return defiler.HealAtWellUtilityOld(botBrain)
  end

  return nUtility

end
defiler.HealAtWellUtilityOld = behaviorLib.HealAtWellBehavior["Utility"]
behaviorLib.HealAtWellBehavior["Utility"] = HealAtWellLogicOverride

--------------------------------------
-- Hero harass execute override     --
-------------------------------------- 

local function HarassHeroExecuteOverride(botBrain)

  local unitSelf = core.unitSelf
  local unitTarget = behaviorLib.heroTarget
  local unitTargetPosition = unitTarget:GetPosition()
  local nMana = unitSelf:GetMana()
  local nLevel = unitSelf:GetLevel()
  
  if unitTarget == nil then
    return defiler.harassExecuteOld(botBrain)
  end

  
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())

  local bActionTaken = false
  

-- Ultispam
  if skills.R:CanActivate() and nMana >= skills.R:GetManaCost() then
	if nTargetDistanceSq <= (150 * 150) then	
	bActionTaken = core.OrderAbility(botBrain, skills.R)
  else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
	end
  end

-- Nukespam

  local nRange = skills.Q:GetRange()

  if skills.Q:CanActivate() and nLevel > 4 and nMana >= ( skills.Q:GetManaCost() + 200 )
     and nTargetDistanceSq < ( (skills.Q:GetRange() * skills.Q:GetRange()) - 500 ) then
	Echo("BLAAAAST")
	bActionTaken = core.OrderAbilityPosition(botBrain, skills.Q, unitTargetPosition)
  end

  if not bActionTaken then
    return defiler.harassExecuteOld(botBrain)
  end

  return bActionTaken

end
defiler.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

