local _G = getfenv(0)
local moonqueen = _G.object

moonqueen.heroName = "Hero_Krixi"

runfile 'bots/core_herobot.lua'
runfile 'bots/teams/trashteam/utils/predictiveLasthitting.lua'
runfile 'bots/teams/trashteam/utils/EasyCourier.lua'

local courier = CourierUtils()

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

---------------------------------------------------------------
--            ShopUtility override                           --
---------------------------------------------------------------
-- @param: none
-- @return: none
function ShopUtilityOverride(botBrain)
  --BotEcho('CanAccessStash: '..tostring(core.unitSelf:CanAccessStash()))

  --just got into shop access, try buying
  if behaviorLib.buyState == behaviorLib.BuyStateUnknown then
    --Determine where in the pattern we are (mostly for reloads)
    behaviorLib.DetermineBuyState(botBrain)
  end

  local nextItemDef = behaviorLib.DetermineNextItemDef(botBrain)
  local components = core.unitSelf:GetItemComponentsRemaining(nextItemDef)
  if components[1] then
    local nextitemCost = components[1]:GetCost()
    local gold = botBrain:GetGold()
    if gold > nextitemCost and components then
    core.BotEcho("gold: " .. tostring(gold) .. ", nextitem" .. tostring(nextitemCost))
      behaviorLib.finishedBuying = false
    end
  end

  local utility = 0
  if not behaviorLib.finishedBuying then
    if not core.teamBotBrain.bPurchasedThisFrame then
      utility = 99
    end
  end

  if botBrain.bDebugUtility == true and utility ~= 0 then
    BotEcho(format("  ShopUtility: %g", utility))
  end

  return utility
end


ShopUtilityOverrideOld = behaviorLib.ShopBehavior["Utility"]
behaviorLib.ShopBehavior["Utility"] = ShopUtilityOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function moonqueen:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)
  courier.tick(self)
  core.BotEcho(courier.GetState())

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
end
-- override combat event trigger function.
moonqueen.oncombateventOld = moonqueen.oncombatevent
moonqueen.oncombatevent = moonqueen.oncombateventOverride
