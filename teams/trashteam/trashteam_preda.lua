local _G = getfenv(0)
local predator = _G.object

predator.heroName = "Hero_Predator"

runfile 'bots/core_herobot.lua'
runfile 'bots/teams/trashteam/utils/utils.lua'

predator.bReportBehavior = false
predator.bDebugUtility = false

local tinsert = _G.table.insert

local core, behaviorLib = predator.core, predator.behaviorLib

UNIT = 0x0000001
BUILDING = 0x0000002
HERO = 0x0000004
POWERUP = 0x0000008
GADGET = 0x0000010
ALIVE = 0x0000020
CORPSE = 0x0000040

behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_HealthPotion", "Item_CrushingClaws", "Item_CrushingClaws", "Item_MinorTotem", "Item_MinorTotem" }
behaviorLib.LaneItems = { "Item_HealthPotion","Item_HealthPotion", "Item_Marchers", "Item_Steamboots", "Item_Strength5", "Item_Strength5" }
behaviorLib.MidItems = { "Item_Strength6", "Item_StrengthAgility" }
behaviorLib.LateItems = {"Item_Dawnbringer", "Item_BehemothsHeart" }

local hide = false

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

	if EventData.ProjectileDisjointable then
		hide = true
	end

  -- custom code here
  local nAddBonus = 0
	if EventData.Type=="Ability" then
		if EventData.InflictorName == "Ability_Predator1" then
			nAddBonus = nAddBonus + 50
		end
		--predator.eventsLib.printCombatEvent(EventData) 
	end
   if nAddBonus > 0 then
        core.DecayBonus(self)
        core.nHarassBonus = core.nHarassBonus + nAddBonus
    end
end
predator.oncombateventOld = predator.oncombatevent
predator.oncombatevent = predator.oncombateventOverride
-- override combat event trigger function.
-- Threw bunch of functions to utils/utils.lua which is included in the beginning of this file
-- so removed duplicates from here making the code easier to read? kept your own special functions

predator.PussyUtilityOld = behaviorLib.RetreatFromThreatBehavior["Utility"]
local function PussyUtilityOverride(BotBrain)
  local util = predator.PussyUtilityOld(BotBrain)
  return math.min(26, util*0.5)
end
behaviorLib.RetreatFromThreatBehavior["Utility"] = PussyUtilityOverride

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

	if not bActionTaken then
			if unitTarget ~= nil and not core.unitSelf:IsChanneling() then
				bActionTaken = core.OrderAttack(botBrain, unitSelf, unitTarget)
			else
				bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)	
      end
		end

  --local bActionTaken = false
  if not bActionTaken then
    return predator.harassExecuteOld(botBrain)
  end
end
predator.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

------------------------------------------------------------------------------------------------
---                 Your own functions and behaviours after this point                       ---
------------------------------------------------------------------------------------------------
local function HideBehaviorUtility(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilHide = unitSelf:GetAbility(1)
  if hide then
		hide = false
    return 80
  end
  return 0
end

local function HideBehaviorExecute(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilHide = unitSelf:GetAbility(1)
  
	return core.OrderAbility(botBrain, abilHide, false)
end

local HideBehavior = {}
HideBehavior["Utility"] = HideBehaviorUtility
HideBehavior["Execute"] = HideBehaviorExecute
HideBehavior["Name"] = "Hide"
tinsert(behaviorLib.tBehaviors, HideBehavior)


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
    -- Hiridur, Näitä alla olevia ehtoja on liikaa. Tee yksinkertaisemmin, katoin just ku preda meni
    -- vihun kimppuun vihuntornin viereen mutta jäi sen jälkeen "en mä kuiteskaan" - tilaan ja kuoli tornin tulitukseen
    -- en kyl tätä viestiä luettaessa lukenut koko tiedostoa mutta näin huomioidakseni.
	  local vihuslow = IsSlowed(vihu)
		if attackdmg*3 > vihu:GetHealth() and nDist<250 then
			return 97-modifier
		end
		if leapdmg > vihu:GetHealth() and nDist<650 and abilLeap:CanActivate() then
			return 97
		end
	  if leapdmg > vihu:GetHealth()+100 and unitSelf:GetHealthPercent()>0.3 and (abilLeap:CanActivate() or omalkm >vihulkm) then
	    return 97-modifier
	  end
	  if leapdmg > vihu:GetHealth()+200 and unitSelf:GetHealthPercent()>0.5 then
	    return 95-modifier
	  end
	  if vihuslow and unitSelf:GetHealthPercent()>0.5 and omalkm < vihulkm then
	    return 90-modifier
	  end
		if not (omalkm < vihulkm) and vihu:GetHealth() < unitSelf:GetHealth() then
			return 90-modifier
		end
  end
  return 0
end

local function LaneLeapBehaviorExecute(botBrain) -- core.CanSeeUnit(botBrain, unitTarget) Try to use this... Cannot say how.
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
		--core.BotEcho("Leappi")
		return core.OrderAbilityEntity(botBrain, abilLeap, targetHero)
	elseif nDist<=128 then
		--core.BotEcho("ATAAK")
		return core.OrderAttackClamp(botBrain, unitSelf, targetHero) 
	else
		--core.BotEcho("LIIKU")
		return core.OrderMoveToUnitClamp(botBrain, unitSelf, targetHero, false)
	end
end

local LaneLeapBehavior = {}
LaneLeapBehavior["Utility"] = LaneLeapBehaviorUtility
LaneLeapBehavior["Execute"] = LaneLeapBehaviorExecute
LaneLeapBehavior["Name"] = "Attack or leap to slowed enemy heroes"
tinsert(behaviorLib.tBehaviors, LaneLeapBehavior)


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
		return 99  -- LANELEAP UTILITY voi saada korkeampia arvoja kuin 99, tämä ei välttämättä toimi niinkuin haluat?
	end          -- PS: kävin vaihtamassa ne luvut alemmiks kuin mitä tämä on, ehkä parempi? 
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

