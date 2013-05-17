local _G = getfenv(0)
local rampage = _G.object

rampage.heroName = "Hero_Rampage"

runfile 'bots/core_herobot.lua'

local core, eventsLib, behaviorLib, skills = object.core, object.eventsLib, object.behaviorLib, object.skills

local tinsert = _G.table.insert

behaviorLib.StartingItems = { "Item_CrushingClaws", "Item_IronBuckler", "Item_CrushingClaws" }
behaviorLib.LaneItems = { "Item_Marchers", "Item_MysticVestments", "Item_LoggersHatchet" }
behaviorLib.MidItems = { "Item_EnhancedMarchers", "Item_Shield2", "Item_MagicArmor2", "Item_MysticVestments" }
behaviorLib.LateItems = { "Item_BehemothsHeart", "Item_DaemonicBreastplate" }

local CHARGE_NONE, CHARGE_STARTED, CHARGE_TIMER, CHARGE_WARP = 0, 1, 2, 3

rampage.charged = CHARGE_NONE

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
rampage.skills = {}
local skills = rampage.skills

rampage.tSkills = {
  2, 0, 2, 1, 0,
  3, 2, 1, 1, 1,
  3, 0, 0, 2, 4,
  4, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}
function rampage:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilCharge == nil then
    skills.abilCharge = unitSelf:GetAbility(0)
    skills.abilSlow = unitSelf:GetAbility(1)
    skills.abilBash = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
rampage.SkillBuildOld = rampage.SkillBuild
rampage.SkillBuild = rampage.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function object:onthinkOverride(tGameVariables)
self:onthinkOld(tGameVariables)
end
object.onthinkOld = object.onthink
object.onthink   = object.onthinkOverride



----------------------------------
--	Ability use thresholds  --
--	not implemented yet	--
----------------------------------
--skilluse = {}
--skilluse.nChargeThreshold = 20
--skilluse.nSlowThreshold = 30
--skilluse.nBashThreshold = 20
--skilluse.nUltimateThreshold = 50

--skilluse.nChargeUse = 15
--skilluse.nSlowUse = 20
--skilluse.nBashUse = 15
--skilluse.nUltimateUse = 30

--skilluse.nChargeUp = 10
--SlowUp = 15
--nBashUp = 20
--skilluse.nUltimateUp = 20


----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function rampage:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

end
rampage.oncombateventOld = rampage.oncombatevent
rampage.oncombatevent = rampage.oncombateventOverride

local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0

  if skills.abilSlow:IsReady() then
   nUtil = nUtil + 30
  end

  if skills.abilCharge:CanActivate() then
   nUtil = nUtil + 20
  end

  if skills.abilUltimate:CanActivate() then
   nUtil = nUtil + 30
  end

  if skills.abilBash:CanActivate() then
   nUtil = nUtil + 30
  end
  

  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride


local function checkTower(range)
-- by ciry
	local selfPos = core.unitSelf:GetPosition()
	local torni = core.GetClosestEnemyTower(selfPos, range)
	if torni == nil then
	return false
	end
	return true

end

local function HarassHeroUtilityOverride(botBrain)
-- by ciry
	if checkTower(1200) then
		return 0
	end

	return behaviorLib.HarassHeroUtility(botBrain)

end
behaviorLib.HarassHeroBehavior["Utility"] = HarassHeroUtilityOverride

--------------------------
-- Harass Behavior	--
--------------------------

local function HarassHeroExecuteOverride(botBrain)
  local abilCharge = skills.abilCharge
  local abilUltimate = skills.abilUltimate
  local abilSlow = skills.abilSlow
  local abilBash = skills.abilBash

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return rampage.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
  local nLastHarassUtility = behaviorLib.lastHarassUtil

  local bActionTaken = false

  if core.CanSeeUnit(botBrain, unitTarget) then
    if abilUltimate:CanActivate() and nLastHarassUtility > 30 then
        local nRange = abilUltimate:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilUltimate, unitTarget)
       end
     end

    if abilCharge:CanActivate() and nLastHarassUtility > 20 then
      	bActionTaken = core.OrderAbilityEntity(botBrain, abilCharge, unitTarget)
     end

    if abilSlow:CanActivate() and nLastHarassUtility > 30 then
      local nRange = abilSlow:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        return core.OrderAbility(botBrain, abilSlow)
     end
    end	
   end

  if not bActionTaken then
    return rampage.harassExecuteOld(botBrain)
  end
end
rampage.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

local function ChargeTarget(botBrain, unitSelf, abilCharge)
  local tEnemyHeroes = HoN.GetHeroes(core.enemyTeam)
  local utility = 0
  local unitTarget = nil
  local nTarget = 0
  for nUID, unit in pairs(tEnemyHeroes) do
    if core.CanSeeUnit(botBrain, unit) and unit:IsAlive() and (not unitTarget or unit:GetHealth() < unitTarget:GetHealth()) then
      unitTarget = unit
      nTarget = nUID
    end
  end
  if unitTarget then
    local damageLevels = {100,140,180,220}
    local chargeDamage = damageLevels[abilCharge:GetLevel()]
    local estimatedHP = unitTarget:GetHealth() - chargeDamage
	if estimatedHP < 100 then
	  utility = utility + 20
	elseif estimatedHP < 200 then
      utility = utility + 10
    end
    if unitTarget:GetManaPercent() < 25 then
      utility = utility + 10
    end
    local level = unitTarget:GetLevel()
    local ownLevel = unitSelf:GetLevel()
    if level - 5 < ownLevel then
      utility = utility + 5 * (ownLevel - level)
    else
      utility = utility - 10 * (ownLevel - level)
    end
    local vecTarget = unitTarget:GetPosition()
    for nUID, unit in pairs(tEnemyHeroes) do
      if nUID ~= nTarget and core.CanSeeUnit(botBrain, unit) and Vector3.Distance2DSq(vecTarget, unit:GetPosition()) < (250 * 250) then
        utility = 5 - utility
      end
    end
  end
  return unitTarget, utility
end

local function ChargeUtility(botBrain)
  local abilCharge = skills.abilCharge
  local unitSelf = core.unitSelf
  if rampage.charged ~= CHARGE_NONE then
    return 20
  end
  if not abilCharge:CanActivate() then
    return 0
  end
  local unitTarget, utility = ChargeTarget(botBrain, unitSelf, abilCharge)
  if unitTarget then
    rampage.chargeTarget = unitTarget
    return utility
  end
  return 0
end

local function ChargeExecute(botBrain)
  local bActionTaken = false
  if botBrain.charged ~= CHARGE_NONE then
    return true
  end
  if not rampage.chargeTarget then
    return false
  end
  local abilCharge = skills.abilCharge
  if abilCharge:CanActivate() then
    bActionTaken = core.OrderAbilityEntity(botBrain, abilCharge, rampage.chargeTarget)
  end
  return bActionTaken
end

local ChargeBehavior = {}
ChargeBehavior["Utility"] = ChargeUtility
ChargeBehavior["Execute"] = ChargeExecute
ChargeBehavior["Name"] = "Charge like a boss"
tinsert(behaviorLib.tBehaviors, ChargeBehavior)

