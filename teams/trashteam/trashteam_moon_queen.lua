local _G = getfenv(0)
local moonqueen = _G.object

moonqueen.heroName = "Hero_Krixi"

runfile 'bots/core_herobot.lua'

local tinsert = _G.table.insert
runfile 'bots/teams/trashteam/utils/predictiveLasthittingMQ.lua'

local core, behaviorLib = moonqueen.core, moonqueen.behaviorLib


behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_HealthPotion", "Item_DuckBoots", "Item_MinorTotem", "Item_PretendersCrown" }
behaviorLib.LaneItems = { "Item_IronShield", "Item_Marchers", "Item_Steamboots", "Item_WhisperingHelm" }
behaviorLib.MidItems = { "Item_ManaBurn2", "Item_Evasion", "Item_Immunity", "Item_Stealth" }
behaviorLib.LateItems = { "Item_LifeSteal4", "Item_Sasuke" }

moonqueen.skills = {}
local skills = moonqueen.skills

core.itemGeoBane = nil

moonqueen.tSkills = {
  2, 1, 2, 1, 1,
  3, 1, 2, 2, 0,
  3, 0, 0, 0, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function moonqueen:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilNuke == nil then
    skills.abilNuke = unitSelf:GetAbility(0)
    skills.abilBounce = unitSelf:GetAbility(1)
    skills.abilAura = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
    skills.taunt = unitSelf:GetAbility(8)
  end
  moonqueen:SkillBuildOld()
end
moonqueen.SkillBuildOld = moonqueen.SkillBuild
moonqueen.SkillBuild = moonqueen.SkillBuildOverride


------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function moonqueen:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
moonqueen.onthinkOld = moonqueen.onthink
moonqueen.onthink = moonqueen.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function moonqueen:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
local nAddBonus = 0

    if EventData.Type == "Ability" then
        if EventData.InflictorName == "Ability_Krixi4" then
            nAddBonus = nAddBonus + 75
        end
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

local function GetHeroToUlti(botBrain, myPos, radius)
  local vihu = core.AssessLocalUnits(botBrain, myPos, radius).EnemyHeroes
  local vihunmq = nil

  for key,unit in pairs(vihu) do
    if unit ~= nil then
      vihunmq = unit
    end
  end

  if not vihunmq then
    return nil
  end
  return vihunmq
end

local function AreThereMaxTwoEnemyUnitsClose(botBrain, myPos, range)
  local unitsLocal = core.AssessLocalUnits(botBrain, myPos, range).EnemyCreeps

  for _,unit in pairs(unitsLocal) do
    if IsSiege(unit) then
      return core.NumberElements(unitsLocal) <= 3
    end
  end

  return core.NumberElements(unitsLocal) <= 2
end

local function UltimateBehaviorUtility(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilUlti = unitSelf:GetAbility(3)
  local myPos = unitSelf:GetPosition()
  local vihu = GetHeroToUlti(botBrain, myPos, abilUlti:GetRange())
  if vihu then
    local canUlti = AreThereMaxTwoEnemyUnitsClose(botBrain, vihu:GetPosition(), abilUlti:GetRange())
    if abilUlti:CanActivate() and vihu and canUlti  then
      return 90
    end
    if abilUlti:CanActivate() and vihu and vihu:GetHealth() < 200 then
      return 95
    end
  end
  return 0
end

local function UltimateBehaviorExecute(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilUlti = unitSelf:GetAbility(3)
  return core.OrderAbility(botBrain, abilUlti, false)
end

local UltimateBehavior = {}
UltimateBehavior["Utility"] = UltimateBehaviorUtility
UltimateBehavior["Execute"] = UltimateBehaviorExecute
UltimateBehavior["Name"] = "Using ultimate properly"
tinsert(behaviorLib.tBehaviors, UltimateBehavior)

moonqueen.oncombateventOld = moonqueen.oncombatevent
moonqueen.oncombatevent = moonqueen.oncombateventOverride
