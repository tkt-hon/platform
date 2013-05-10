local _G = getfenv(0)
local rampage = _G.object

rampage.heroName = "Hero_Rampage"

runfile 'bots/core_herobot.lua'
runfile 'bots/teams/trashteam/utils/predictiveLasthittingRampage.lua'
local core, behaviorLib = rampage.core, rampage.behaviorLib

local tinsert = _G.table.insert


behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_IronBuckler", "Item_LoggersHatchet" }
behaviorLib.LaneItems = { "2 Item_RunesOfTheBlight","Item_Marchers", "Item_Lifetube", "Item_ManaBattery" }
behaviorLib.MidItems = { "Item_EnhancedMarchers", "Item_Shield2", "Item_PowerSupply", "Item_MysticVestments" }
behaviorLib.LateItems = { "Item_Immunity", "Item_DaemonicBreastplate" }

local CHARGE_NONE, CHARGE_STARTED, CHARGE_TIMER, CHARGE_WARP = 0, 1, 2, 3

rampage.charged = CHARGE_NONE

rampage.skills = {}
local skills = rampage.skills

rampage.tSkills = {
  2, 0, 2, 0, 2,
  3, 2, 0, 1, 0,
  3, 1, 1, 1, 4,
  3, 4, 4, 4, 4,
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
function rampage:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
rampage.onthinkOld = rampage.onthink
rampage.onthink = rampage.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function rampage:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  if EventData.Type == "Ability" and EventData.InflictorName == "Ability_Rampage1" then
    self.charged = CHARGE_STARTED
  elseif EventData.Type == "State_End" and EventData.StateName == "State_Rampage_Ability1_Timer" then
    if self.charged == CHARGE_STARTED then
      self.charged = CHARGE_NONE
    end
  elseif EventData.Type == "State" and EventData.StateName == "State_Rampage_Ability1_Warp" then
    self.charged = CHARGE_WARP
  elseif EventData.Type == "State_End" and EventData.StateName == "State_Rampage_Ability1_Warp" then
    self.charged = CHARGE_NONE
  elseif EventData.Type == "Death" then
    self.charged = CHARGE_NONE
  end
end
rampage.oncombateventOld = rampage.oncombatevent
rampage.oncombatevent = rampage.oncombateventOverride

local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0

  if skills.abilBash:IsReady() then
    nUtil = nUtil + 30
  end

  if skills.abilCharge:CanActivate() then
    nUtil = nUtil + 10
  end

  if skills.abilUltimate:CanActivate() then
    nUtil = nUtil
  end

  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)
  local abilCharge = skills.abilCharge
  local abilUltimate = skills.abilUltimate
  local abilSlow = skills.abilSlow

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return rampage.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
  local nLastHarassUtility = behaviorLib.lastHarassUtil

  local bActionTaken = false

  if core.CanSeeUnit(botBrain, unitTarget) then

    if abilUltimate:CanActivate() then
      local nRange = abilUltimate:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilUltimate, unitTarget)
      end
    end

    if abilCharge:CanActivate() then
      bActionTaken = core.OrderAbilityEntity(botBrain, abilCharge, unitTarget)
    end

    if abilSlow:CanActivate() then
      local nRange = 300
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
