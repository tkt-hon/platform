local _G = getfenv(0)
local predator = _G.object

predator.heroName = "Hero_Predator"

runfile 'bots/core_herobot.lua'

predator.bReportBehavior = true
predator.bDebugUtility = true

local tinsert = _G.table.insert

local core, behaviorLib = predator.core, predator.behaviorLib

UNIT = 0x0000001
BUILDING = 0x0000002
HERO = 0x0000004
POWERUP = 0x0000008
GADGET = 0x0000010
ALIVE = 0x0000020
CORPSE = 0x0000040

behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_HealthPotion", "Item_IronBuckler", "3 Item_MinorTotem" }
behaviorLib.LaneItems = { "Item_HealthPotion", "Item_IronShield","Item_HealthPotion", "Item_Marchers", "Item_Steamboots", "Item_Pierce" }
behaviorLib.MidItems = { "Item_ManaBurn2", "Item_Evasion", "Item_Immunity", "Item_Stealth" }
behaviorLib.LateItems = { "Item_LifeSteal4", "Item_Sasuke" }

predator.skills = {}
local skills = predator.skills

core.itemGeoBane = nil
predator.AdvTarget = nil
predator.AdvTargetHero = nil

predator.tSkills = {
  0, 2, 0, 2, 0,
  3, 0, 2, 2, 1,
  3, 1, 1, 1, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function predator:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilLeap == nil then
    skills.abilLeap = unitSelf:GetAbility(0)
    skills.abilHide = unitSelf:GetAbility(1)
    skills.abilCarni = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
    skills.taunt = unitSelf:GetAbility(8)
  end
  predator:SkillBuildOld()
end
predator.SkillBuildOld = predator.SkillBuild
predator.SkillBuild = predator.SkillBuildOverride


------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function predator:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)
  local unitSelf = self.core.unitSelf
  if predator.AdvTarget and predator.AdvTargetHero and false then
    HoN.DrawDebugLine(unitSelf:GetPosition(), predator.AdvTarget:GetPosition(), true, "red")
    HoN.DrawDebugLine(predator.AdvTarget:GetPosition(), predator.AdvTargetHero:GetPosition(), true, "blue")
  end
  -- custom code here
end
predator.onthinkOld = predator.onthink
predator.onthink = predator.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function predator:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
  local nAddBonus = 0
	if EventData.Type=="Ability" then
		if EventData.InflictorName == "Ability_Predator1" then
			nAddBonus = nAddBonus + 50
		end
		predator.eventsLib.printCombatEvent(EventData)
	end
   if nAddBonus > 0 then
        core.DecayBonus(self)
        core.nHarassBonus = core.nHarassBonus + nAddBonus
    end
end
-- override combat event trigger function.
local function IsSiege(unit)
  local unitType = unit:GetTypeName()
  return unitType == "Creep_LegionSiege" or unitType == "Creep_HellbourneSiege"
end

local function closeToEnemyTowerDist(unit)
  local unitSelf = unit
  local myPos = unitSelf:GetPosition()
  local myTeam = unitSelf:GetTeam()

  local unitsInRange = HoN.GetUnitsInRadius(myPos, 3000, ALIVE + BUILDING)
  for _,unit in pairs(unitsInRange) do
    if unit and not(myTeam == unit:GetTeam()) then
      if unit:GetTypeName() == "Building_HellbourneTower" then
        return Vector3.Distance2D(myPos, unit:GetPosition())
      end
    end
  end
  return 3000
end

local function GetHeroToLeap(botBrain, myPos, radius)
  local unitsLocal = HoN.GetUnitsInRadius(myPos, radius, ALIVE + HERO)
  local vihu = nil

  for key,unit in pairs(unitsLocal) do
    if unit ~= nil and not (botBrain:GetTeam() == unit:GetTeam()) then
      vihu = unit
    end
  end

  if not vihu then
    return nil
  end
  return vihu
end

local function IsSlowed(hero)
  if hero:HasState("State_Shaman_Ability1_Snare") or hero:IsStunned() or hero:IsPerplexed() or hero:IsSilenced() then
    return true
  end
  return false
end

local function NumberOfEnemyHeroNear(botBrain, position, range)
  local unitsLocal = HoN.GetUnitsInRadius(myPos, radius, ALIVE + HERO)
  local vihu = nil

  for key,unit in pairs(unitsLocal) do
    if unit ~= nil and not (botBrain:GetTeam() == unit:GetTeam()) then
      vihu = unit
    end
  end

  if not vihu then
    return nil
  end
  return vihu
end

local function GetArmorMultiplier(unit, magic)
  --return value of like 0.75 where armor would therefore be 25%
  --just multiply dmg with this value and you get final result
  local magicReduc = 0
  if magic then
    magicReduc = unit:GetMagicArmor()
  else
    magicReduc = unit:GetArmor()
  end
  magicReduc = 1 - (magicReduc*0.06)/(1+0.06*magicReduc)
  return magicReduc
end

local function LaneLeapBehaviorUtility(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local distToEneTo = closeToEnemyTowerDist(unitSelf)
  local modifier = 0
  if distToEneTo < 650 then
    modifier = 70
  end
  local abilLeap = unitSelf:GetAbility(0)
  local myPos = unitSelf:GetPosition()

	local unitsLocal, unitsSorted = HoN.GetUnitsInRadius(myPos, 900, ALIVE + HERO, true)
	local vihulkm = core.NumberElements(unitsSorted.EnemyHeroes)
	local omalkm = core.NumberElements(unitsSorted.AllyHeroes)
	local vihu = nil
  local hp = 100000
  for key,unit in pairs(unitsSorted.EnemyHeroes) do
    if unit ~= nil and unit:GetHealth()<hp then
      vihu = unit
			hp = unit:GetHealth()
    end
  end

  if vihu then
  	local nDist = Vector3.Distance2D(vihu:GetPosition(), unitSelf:GetPosition())
		local leapdmg = ((abilLeap:GetLevel()*50)+25)*GetArmorMultiplier(vihu, true)
		local attackdmg = (unitSelf:GetAttackDamageMin())*GetArmorMultiplier(vihu, false)
    predator.LeapTarget = vihu
    local vihuhp = vihu:GetHealth()
  
	  local vihuslow = IsSlowed(vihu)
		if attackdmg*3 > vihu:GetHealth() and nDist<250 then
			return 100-modifier
		end
		if leapdmg > vihu:GetHealth() and nDist<650 and abilLeap:CanActivate() then
			return 100
		end
	  if leapdmg > vihu:GetHealth()+100 and unitSelf:GetHealthPercent()>0.3 and (abilLeap:CanActivate() or omalkm >vihulkm) then
	    return 100-modifier
	  end
	  if leapdmg > vihu:GetHealth()+200 and unitSelf:GetHealthPercent()>0.5 then
	    return 95-modifier
	  end
	  if vihuslow and unitSelf:GetHealthPercent()>0.5 and not omalkm < vihulkm then
	    return 90-modifier
	  end
		if not (omalkm < vihulkm) and vihu:GetHealth() < unitSelf:GetHealth() then
			return 90-modifier
		end
  end
  return 0
end

local function LaneLeapBehaviorExecute(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilLeap = unitSelf:GetAbility(0)
	local targetHero = predator.LeapTarget
	if not targetHero then
		return false
	end
  local nDist = Vector3.Distance2D(targetHero:GetPosition(), unitSelf:GetPosition())
	local leapdmg = ((abilLeap:GetLevel()*50)+25)*GetArmorMultiplier(targetHero, true)
	local attackdmg = (unitSelf:GetAttackDamageMin())*GetArmorMultiplier(targetHero, false)
	if abilLeap:CanActivate() and (leapdmg > targetHero:GetHealth() or not IsSlowed(targetHero)) and nDist<650 then
		core.BotEcho("Leappi")
		return core.OrderAbilityEntity(botBrain, abilLeap, targetHero)
	elseif nDist<=128 then
		core.BotEcho("ATAAK")
		return core.OrderAttackClamp(botBrain, unitSelf, targetHero) 
	else
		core.BotEcho("LIIKU")
		return core.OrderMoveToUnitClamp(botBrain, unitSelf, targetHero, false)
	end
end

local LaneLeapBehavior = {}
LaneLeapBehavior["Utility"] = LaneLeapBehaviorUtility
LaneLeapBehavior["Execute"] = LaneLeapBehaviorExecute
LaneLeapBehavior["Name"] = "Attack or leap to slowed enemy heroes"
tinsert(behaviorLib.tBehaviors, LaneLeapBehavior)

predator.oncombateventOld = predator.oncombatevent
predator.oncombatevent = predator.oncombateventOverride


local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0
	
  local distToEneTo = closeToEnemyTowerDist(hero)
  local modifier = 0
  if distToEneTo < 650 then
    modifier = 80
  end
  return nUtil-modifier
end
--behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return predator.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistance = Vector3.Distance2D(unitSelf:GetPosition(), unitTarget:GetPosition())
  local nLastHarassUtility = behaviorLib.lastHarassUtil

  local bActionTaken = false
  if not bActionTaken then
    return predator.harassExecuteOld(botBrain)
  end
end
predator.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

predator.PussyUtilityOld = behaviorLib.RetreatFromThreatBehavior["Utility"]
local function PussyUtilityOverride(BotBrain)
  local util = predator.PussyUtilityOld(BotBrain)
  return math.min(26, util*0.5)
end
behaviorLib.RetreatFromThreatBehavior["Utility"] = PussyUtilityOverride

local function ResqueEating(func)
  return function(botBrain)
		local _, unitsSorted = HoN.GetUnitsInRadius(core.unitSelf:GetPosition(), 200, ALIVE + HERO, true)
		local vihu = nil
		local hp = nil
		for _, unit in pairs(unitsSorted.EnemyHeroes) do
			newhp = unit:GetHealth()
		  if not vihu or newhp>hp then
		    vihu = unit
				hp = newhp
		  end
		end
		if vihu then
			return core.OrderAttackClamp(botBrain, core.unitSelf, vihu) 
		end
		return func(botBrain)
	end
end

behaviorLib.UseHealthRegenBehavior["Execute"] = ResqueEating(behaviorLib.UseHealthRegenExecute)
behaviorLib.HealAtWellBehavior["Execute"] = ResqueEating(behaviorLib.HealAtWellExecute)

local function CasualEatingBehaviorUtility(botBrain)
	local _, unitsSorted = HoN.GetUnitsInRadius(core.unitSelf:GetPosition(), 128, ALIVE + HERO, true)
	local vihu = nil
	local hp = nil
	for _, unit in pairs(unitsSorted.EnemyHeroes) do
		newhp = unit:GetHealth()
	  if not vihu or newhp>hp then
	    vihu = unit
			hp = newhp
	  end
	end
	if vihu then
		predator.casualtarget=vihu
		return 99 
	end
	return 0
end

local function CasualEatingBehaviorExecute(botBrain)
	return core.OrderAttackClamp(botBrain, core.unitSelf, predator.casualtarget) 
end

local CasualEatingBehavior = {}
CasualEatingBehavior["Utility"] = CasualEatingBehaviorUtility
CasualEatingBehavior["Execute"] = CasualEatingBehaviorExecute
CasualEatingBehavior["Name"] = "Casually eating enemy heroes"
tinsert(behaviorLib.tBehaviors, CasualEatingBehavior)

