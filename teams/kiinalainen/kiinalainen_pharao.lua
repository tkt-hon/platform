local _G = getfenv(0)
local pharao = _G.object

pharao.heroName = "Hero_Mumra"

runfile "bots/teams/kiinalainen/core_kiinalainen_herobot.lua"
runfile "bots/teams/kiinalainen/helpers.lua" -- TODO
--runfile "bots/teams/kiinalainen/advancedShopping.lua" -- Shoppailu ja itemHandler funktionaalisuus. ( local itemBottle = itemHandler:GetItem("Item_Bottle") etc)
--runfile "bots/teams/kiinalainen/bottle.lua" -- Bottlen käyttö
runfile 'bots/lib/rune_controlling/init.lua'

local core, behaviorLib = pharao.core, pharao.behaviorLib

--local itemHandler = object.itemHandler
--local shopping = object.shoppingHandler

behaviorLib.StartingItems = { "Item_LoggersHatchet", "Item_RunesOfTheBlight", "Item_IronBuckler"}
behaviorLib.LaneItems = { "Item_Marchers", "Item_Lifetube", "Item_GlovesOfHaste", "Item_BlessedArmband", "Item_Shield2", "Item_HungrySpirit" }
behaviorLib.MidItems = { "Item_Excruciator", "Item_Immunity", "Item_Stealth" }
behaviorLib.LateItems = { "Item_BehemothsHeart"}

behaviorLib.pushingStrUtilMul = 1

pharao.skills = {}
local skills = pharao.skills

--shopping.Setup(false, false, false, false)
---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none

pharao.tSkills = {
  2, 0, 2, 1, 2,
  3, 2, 1, 1, 1,
  3, 0, 0, 0, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}

function pharao:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilNuke == nil then
    skills.abilHell = unitSelf:GetAbility(0)
    skills.abilWall = unitSelf:GetAbility(1)
    skills.abilNuke = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
pharao.SkillBuildOld = pharao.SkillBuild
pharao.SkillBuild = pharao.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function pharao:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
pharao.onthinkOld = pharao.onthink
pharao.onthink = pharao.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function pharao:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end

local function CustomHarassUtilityFnOverride(hero)
  return 100
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride



local function NearbyCreepCount(botBrain, center, radius)
  local count = 0
  local unitsLocal = core.AssessLocalUnits(botBrain, center, radius)
  local enemies = unitsLocal.EnemyCreeps
  for _,unit in pairs(enemies) do
    count = count + 1
  end
  return count
end

local function isClearTarget(botBrain, hero, unitTarget)
  local startPosition = hero:GetPosition()
  --core.BotEcho(tostring(startPosition))
  local endPosition = unitTarget:GetPosition()
  local creeps = 0
  for i=1,10 do
    local j = i/10
    local position = startPosition * j + endPosition * (1-j)
    position.Z = 0
    --core.BotEcho(tostring(position))
    core.DrawXPosition(position)
    creeps = creeps + NearbyCreepCount(botBrain, position, 25)
  end

  return creeps == 0
end

local function HarassHeroExecuteOverride(botBrain)

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return pharao.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
  local nLastHarassUtility = behaviorLib.lastHarassUtil

  local bActionTaken = false

  if core.CanSeeUnit(botBrain, unitTarget) then
    local abilUltimate = skills.abilUltimate
    local nRange = abilUltimate:GetRange()
    if abilUltimate:CanActivate() and nTargetDistanceSq < (nRange * nRange) and isClearTarget(botBrain, unitSelf, unitTarget) then
      core.OrderAbilityPosition(botBrain, abilUltimate, unitTarget:GetPosition())
    end
    local abilHell = skills.abilHell
    nRange = 300
    if nTargetDistanceSq < (nRange * nRange) and abilHell:CanActivate() then
      core.OrderAbility(botBrain, abilHell)
    end
    local abilWall = skills.abilWall
    if nTargetDistanceSq < (nRange * nRange) and abilWall:CanActivate() then
      core.OrderAbility(botBrain, abilWall)
    end
    local abilNuke = skills.abilNuke
    if abilNuke:CanActivate() then
      bActionTaken = core.OrderAbilityPosition(botBrain, abilNuke, unitTarget:GetPosition())
    end
  end
  if not bActionTaken then
    return pharao.harassExecuteOld(botBrain)
  end
end


pharao.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride
-- override combat event trigger function.
pharao.oncombateventOld = pharao.oncombatevent
pharao.oncombatevent = pharao.oncombateventOverride
