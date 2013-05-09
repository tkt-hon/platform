local _G = getfenv(0)
local plaguerider = _G.object
local nuketime = HoN.GetMatchTime()

plaguerider.heroName = "Hero_DiseasedRider"

runfile 'bots/core_herobot.lua'
runfile 'bots/teams/temaNoHelp/plague_lasthit.lua'


local core, behaviorLib = plaguerider.core, plaguerider.behaviorLib

behaviorLib.StartingItems = { "Item_HealthPotion", "Item_RunesOfTheBlight", "Item_MinorTotem",  "Item_TrinketOfRestoration"}
behaviorLib.LaneItems = { "Item_Marchers", "Item_MysticVestments", "Item_EnhancedMarchers", "Item_MagicArmor2" }
behaviorLib.MidItems = { "Item_SpellShards 3", "Item_Intelligence7", "Item_Lightbrand" }

plaguerider.bReportBehavior = true
plaguerider.bDebugUtility = true

plaguerider.skills = {}
local skills = plaguerider.skills

local tinsert = _G.table.insert

plaguerider.skills = {}
local skills = plaguerider.skills

plaguerider.tSkills = {
  2, 0, 2, 0, 0,
  3, 0, 2, 2, 1,
  3, 1, 1, 1, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}

function plaguerider:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilDeny == nil then
    skills.abilNuke = unitSelf:GetAbility(0)
    skills.abilShield = unitSelf:GetAbility(1)
    skills.abilDeny = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
plaguerider.SkillBuildOld = plaguerider.SkillBuild
plaguerider.SkillBuild = plaguerider.SkillBuildOverride


local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0
  local unitTarget = behaviorLib.heroTarget
  --jos potu käytössä niin ei agroilla
  if core.unitSelf:HasState(core.idefHealthPotion.stateName) then
    core.BotEcho("POTUU")
	return -10000
  end 

--jos tornin rangella ni ei mennä
  if core.GetClosestEnemyTower(hero:GetPosition(), 715) then
    return -10000
  end
  
  if skills.abilNuke:CanActivate() then
    nUtil = nUtil + 30
    local damages = {50,100,125,175}
    if hero:GetHealth() < damages[skills.abilNuke:GetLevel()] then
      return 40
    end
  end

  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

------------------------------DENY SKILL START----------------------------------------------------------


local function IsSiege(unit)
  local unitType = unit:GetTypeName()
  return unitType == "Creep_LegionSiege" or unitType == "Creep_HellbourneSiege"
end

local function GetUnitToDenyWithSpell(botBrain, myPos, radius)
  local unitsLocal = core.AssessLocalUnits(botBrain, myPos, radius)
  local allies = unitsLocal.AllyCreeps
  local unitTarget = nil
  local nDistance = 0

  for _,unit in pairs(allies) do
    local nNewDistance = Vector3.Distance2DSq(myPos, unit:GetPosition())
    if not IsSiege(unit) and (not unitTarget or nNewDistance < nDistance) and unit:GetHealth() > 435 then
      unitTarget = unit
      nDistance = nNewDistance
    end
  end
  return unitTarget
end

local function IsUnitCloserThanEnemies(botBrain, myPos, unit)
  local unitsLocal = core.AssessLocalUnits(botBrain, myPos, Vector3.Distance2DSq(myPos, unit:GetPosition()))
  return core.NumberElements(unitsLocal.EnemyHeroes) <= 0
end

local function DenyBehaviorUtility(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilDeny = skills.abilDeny
  local myPos = unitSelf:GetPosition()
  local unit = GetUnitToDenyWithSpell(botBrain, myPos, abilDeny:GetRange())

--jos tornin rangella ni ei mennä
  if core.GetClosestEnemyTower(core.unitSelf:GetPosition(), 715) then
    return -10000
  end
  if core.unitSelf:GetLevel() > 1 and core.unitSelf:GetManaPercent() > 95 then
    return -10000
  end


  if abilDeny:CanActivate() and unit and IsUnitCloserThanEnemies(botBrain, myPos, unit) then
    plaguerider.denyTarget = unit
    return 30
  end
  return 0
end

local function DenyBehaviorExecute(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilDeny = skills.abilDeny
  local target = plaguerider.denyTarget
  if target then
    return core.OrderAbilityEntity(botBrain, abilDeny, target, false)
  end
  return false
end

local DenyBehavior = {}
DenyBehavior["Utility"] = DenyBehaviorUtility
DenyBehavior["Execute"] = DenyBehaviorExecute
DenyBehavior["Name"] = "Denying creep with spell"
tinsert(behaviorLib.tBehaviors, DenyBehavior)
------------------------------DENY SKILL END----------------------------------------------------------

------------------------------NUKE & ULT SKILL START----------------------------------------------------------



local function UltiBehaviorUtility(botBrain)
  if core.unitSelf:GetLevel() < 6 then
    return 0
  end
  --jos tornin rangella ni ei mennä
  if core.GetClosestEnemyTower(core.unitSelf:GetPosition(), 715) then
    return -10000
  end

  local unitsLocal = core.AssessLocalUnits(botBrain)
  local enemies = unitsLocal.EnemyCreeps
  if core.NumberElements(enemies) == 1 then
    return 70
  end
  return 0
end

local function UltiBehaviorExecute(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local ulti = skills.abilUltimate
  local unitsLocal = core.AssessLocalUnits(botBrain)
  local enemies = unitsLocal.EnemyHeroes
  local target = nil
  for _, unit in pairs(enemies) do
    target = unit
  end
  if target then
    return core.OrderAbilityEntity(botBrain, ulti, target)
  end
  return false
end

local UltiBehavior = {}
UltiBehavior["Utility"] = UltiBehaviorUtility
UltiBehavior["Execute"] = UltiBehaviorExecute
UltiBehavior["Name"] = "Ulti to the creeps like a baus"
tinsert(behaviorLib.tBehaviors, UltiBehavior)


local function HarassHeroExecuteOverride(botBrain)  
  local time = HoN.GetMatchTime()
  core.BotEcho("time: "..tostring(time))
  core.BotEcho("nuketime: "..tostring(nuketime))
  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return plaguerider.harassExecuteOld(botBrain)
  end


  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())

  local bActionTaken = false

  if core.CanSeeUnit(botBrain, unitTarget) then
    local abilNuke = skills.abilNuke
    if skills.abilUltimate:CanActivate() and unitTarget:GetHealth() < 200 then
	  local nRange = skills.abilUltimate:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, skills.abilUltimate, unitTarget)
      else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
      end
    end
  
--mätetään nukeja ennen nelosleveliä koko ajan 
    if abilNuke:CanActivate() and not core.GetClosestEnemyTower(unitSelf:GetPosition(), 701) and core.unitSelf:GetLevel() < 4 then
      local nRange = abilNuke:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilNuke, unitTarget)
        nuketime = HoN.GetMatchTime()
      else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
      end
    end
--pyritään säästelemään manaa kolmoslevelin jälkeen kuitenkin jos tappoon mahollisuus niin go
    

    if abilNuke:CanActivate() and not core.GetClosestEnemyTower(unitSelf:GetPosition(), 701) and core.unitSelf:GetMana() > 150 and core.unitSelf:GetLevel() > 3 then
      local nRange = abilNuke:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilNuke, unitTarget)
	    nuketime = HoN.GetMatchTime()
      else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
      end
    end
	if time > nuketime + 15000 then
      local nuke = skills.abilNuke
  	  local unitsLocal = core.AssessLocalUnits(botBrain, unitSelf:GetPosition(), 1000)
	  if unitsLocal ~= nil then
  	    local enemies = unitsLocal.EnemyCreeps
        local target = nil
        for _, unit in pairs(enemies) do
          target = unit
		  if target:GetHealth() > 200 then
            nuketime = HoN.GetMatchTime()
            return core.OrderAbilityEntity(botBrain, nuke, target)
          end
        end        
	  end
    end

  end

  if not bActionTaken then
    return plaguerider.harassExecuteOld(botBrain)
  end
end
plaguerider.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride
------------------------------NUKE & ULT SKILL END----------------------------------------------------------

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function plaguerider:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

local nAddBonus = 0

    if EventData.Type == "Ability" then
        if EventData.InflictorName == "Ability_DiseasedRider4" then
            nAddBonus = nAddBonus + 100
        end
	end

   if nAddBonus > 0 then
        core.DecayBonus(self)
        core.nHarassBonus = core.nHarassBonus + nAddBonus
    end
  -- custom code here
end
-- override combat event trigger function.
plaguerider.oncombateventOld = plaguerider.oncombatevent
plaguerider.oncombatevent = plaguerider.oncombateventOverride

local function RetreatFromThreatUtilityOverride(botBrain)
  local unitTarget = behaviorLib.heroTarget
  local selfPosition = core.unitSelf:GetPosition()
  if unitTarget ~= nil then
    if core.unitSelf:GetHealth() + 50 < unitTarget:GetHealth() then
      return 10000
    end 
  end

  if core.GetClosestEnemyTower(selfPosition, 715) then
    return 10000
  end

  return behaviorLib.RetreatFromThreatUtility(botBrain)
end
behaviorLib.RetreatFromThreatBehavior["Utility"] = RetreatFromThreatUtilityOverride



