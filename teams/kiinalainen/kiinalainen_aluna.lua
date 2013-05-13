local _G = getfenv(0)
local aluna = _G.object

aluna.heroName = "Hero_Aluna"

runfile 'bots/core_herobot.lua'
runfile "bots/teams/kiinalainen/helpers.lua" -- TODO
runfile "bots/teams/kiinalainen/advancedShopping.lua" -- Shoppailu ja itemHandler funktionaalisuus. ( local itemBottle = itemHandler:GetItem("Item_Bottle") etc)
runfile "bots/teams/kiinalainen/bottle.lua" -- Bottlen käyttö
runfile 'bots/lib/rune_controlling/init.lua'

local core, behaviorLib = aluna.core, aluna.behaviorLib

behaviorLib.StartingItems = { "Item_Punchdagger", "Item_HealthPotion"}
behaviorLib.LaneItems = { "Item_EnhancedMarchers", "Item_HungrySpirit", "Item_WhisperingHelm" }
behaviorLib.MidItems = { "Item_ManaBurn2", "Item_Evasion", "Item_Immunity", "Item_Stealth" }
behaviorLib.LateItems = { "Item_LifeSteal4", "Item_Sasuke" }

aluna.skills = {}
local skills = aluna.skills

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none

aluna.tSkills = {
  1, 0, 1, 2, 1,
  3, 1, 0, 0, 0,
  3, 2, 2, 2, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}

function aluna:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilStun == nil then
    skills.abilStun = unitSelf:GetAbility(0)
    skills.abilThrow = unitSelf:GetAbility(1)
    skills.abilSpeed = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
aluna.SkillBuildOld = aluna.SkillBuild
aluna.SkillBuild = aluna.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function aluna:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
aluna.onthinkOld = aluna.onthink
aluna.onthink = aluna.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function aluna:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end

local function HarassHeroExecuteOverride(botBrain)

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return moonqueen.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
  local nLastHarassUtility = behaviorLib.lastHarassUtil

  local bActionTaken = false

  if core.CanSeeUnit(botBrain, unitTarget) then
    local itemGeoBane = core.itemGeoBane
    if not bActionTaken then
      if itemGeoBane then
        if itemGeoBane:CanActivate() then
          bActionTaken = core.OrderItemClamp(botBrain, unitSelf, itemGeoBane)
        end
      end
    end

    local abilUltimate = skills.abilUltimate
    if not bActionTaken and nLastHarassUtility > 50 then
      if abilUltimate:CanActivate() then
        local nRange = 600
        if nTargetDistanceSq < (nRange * nRange) then
          bActionTaken = core.OrderAbility(botBrain, abilUltimate)
        else
          bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
        end
      end
    end

    local abilThrow = skills.abilThrow
    if abilThrow:CanActivate() then
      local nRange = abilThrow:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilThrow, unitTarget)
      else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
      end
    end
  end

  if not bActionTaken then
    return moonqueen.harassExecuteOld(botBrain)
  end
end
-- override combat event trigger function.
aluna.oncombateventOld = aluna.oncombatevent
aluna.oncombatevent = aluna.oncombateventOverride
