local _G = getfenv(0)
local aluna = _G.object

aluna.heroName = "Hero_Aluna"

runfile "bots/teams/kiinalainen/core_kiinalainen_herobot.lua"
runfile "bots/teams/kiinalainen/helpers.lua" -- TODO
--runfile "bots/teams/kiinalainen/advancedShopping.lua" -- Shoppailu ja itemHandler funktionaalisuus. ( local itemBottle = itemHandler:GetItem("Item_Bottle") etc)
--runfile "bots/teams/kiinalainen/bottle.lua" -- Bottlen käyttö
runfile 'bots/lib/rune_controlling/init.lua'

local core, behaviorLib = aluna.core, aluna.behaviorLib

--local itemHandler = object.itemHandler
--local shopping = object.shoppingHandler

behaviorLib.StartingItems = { "Item_HealthPotion", "2 Item_MinorTotem", "Item_RunesOfTheBlight"}
behaviorLib.LaneItems = { "Item_Bottle", "Item_PowerSupply", "Item_Weapon1"}
behaviorLib.MidItems = { "Item_Weapon1" }
behaviorLib.LateItems = { "Item_Silence", "Item_Nuke" }

aluna.skills = {}
local skills = aluna.skills

--shopping.Setup(false, false, true, false)

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

local function CustomHarassUtilityFnOverride(hero)
  return 100
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function RetreatFromThreatExecuteOverride(botBrain)
    local abilWall = skills.abilSpeed

    return abilWall:CanActivate() and core.OrderAbility(botBrain, abilWall) or behaviorLib.RetreatFromThreatExecute
end
    
behaviorLib.RetreatFromThreatBehavior["Execute"] = RetreatFromThreatExecuteOverride



local function HarassHeroExecuteOverride(botBrain)

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return aluna.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
  local nLastHarassUtility = behaviorLib.lastHarassUtil

  local bActionTaken = false

  core.BotEcho(tostring(unitTarget))
  if core.CanSeeUnit(botBrain, unitTarget) then
    core.BotEcho("FOOO!")

    local abilUltimate = skills.abilUltimate
    local nRange = skills.abilStun:GetRange()
    if abilUltimate:CanActivate() and nTargetDistanceSq < (nRange * nRange) then
      bActionTaken = core.OrderAbility(botBrain, abilUltimate)
    end
    local abilHell = skills.abilStun
    nRange = abilHell:GetRange()
    if nTargetDistanceSq < (nRange * nRange) and abilHell:CanActivate() then
      bActionTaken = core.OrderAbilityEntity(botBrain, abilHell, unitTarget)
    end
    local abilNuke = skills.abilThrow
    if abilNuke:CanActivate() then
      bActionTaken = core.OrderAbilityPosition(botBrain, abilNuke, unitTarget:GetPosition())
    end
  end
  if not bActionTaken then
    return aluna.harassExecuteOld(botBrain)
  end
end


aluna.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride
-- override combat event trigger function.
aluna.oncombateventOld = aluna.oncombatevent
aluna.oncombatevent = aluna.oncombateventOverride

