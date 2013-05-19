local _G = getfenv(0)
local pharaoh = _G.object

pharaoh.heroName = "Hero_Mumra"

runfile 'bots/core_herobot.lua'
runfile 'bots/lib/rune_controlling/init.lua'
runfile 'bots/teams/faulty/lib/bottle_behavior.lua'
runfile 'bots/teams/faulty/lib/sitter.lua'
runfile 'bots/teams/faulty/lib/utils.lua'

local core, behaviorLib = pharaoh.core, pharaoh.behaviorLib
local tinsert, format = _G.table.insert, _G.string.format
local BotEcho = core.BotEcho

BotEcho("loading faulty_pharaoh.lua")

local function PreGameExecuteOverride(botBrain)
  if not core.unitSelf.isSitter then
    return behaviorLib.PreGameExecute(botBrain)
  end
  return behaviorLib.PreGameSitterExecute(botBrain)
end
behaviorLib.PreGameBehavior["Execute"] = PreGameExecuteOverride

behaviorLib.StartingItems = { "Item_Bottle" }
behaviorLib.LaneItems = { "Item_Marchers", "Item_ManaRegen3", "Item_RunesOfTheBlight" }
behaviorLib.MidItems = { "Item_Shield2", "Item_BehemothsHeart", "Item_EnhancedMarchers" }
behaviorLib.LateItems = { "Item_Immunity", "Item_DaemonicBreastplate" }

-- http://honwiki.net/wiki/Pharaoh:Bringing_in_the_Harvest
-- 0 = Q(Hellfire)
-- 1 = W(Wall of mummies)
-- 2 = E(Tormented Soul)
-- 3 = R(Wrath of the pharaoh)
-- 4 = stats
pharaoh.tSkills = {
  2, 0, 0, 2, 0,
  3, 0, 1, 2, 2,
  3, 1, 1, 1, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4,
}

pharaoh.skills = {}
local skills = pharaoh.skills

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function pharaoh:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilHellfire == nil then
    skills.abilHellfire  = unitSelf:GetAbility(0)
    skills.abilWall      = unitSelf:GetAbility(1)
    skills.abilTormented = unitSelf:GetAbility(2)
    skills.abilWrath     = unitSelf:GetAbility(3)
    skills.abilStats     = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
pharaoh.SkillBuildOld = pharaoh.SkillBuild
pharaoh.SkillBuild = pharaoh.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function pharaoh:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
pharaoh.onthinkOld = pharaoh.onthink
pharaoh.onthink = pharaoh.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function pharaoh:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
pharaoh.oncombateventOld = pharaoh.oncombatevent
pharaoh.oncombatevent = pharaoh.oncombateventOverride

--------------------------------------------------------------------------------
-- CUSTOM HARASS BEHAVIORA
--
-- Utility:
--
-- Execute:
--
-- 0 = Q(Hellfire)
-- 1 = W(Wall of mummies)
-- 2 = E(Tormented Soul)
-- 3 = R(Wrath of the pharaoh)
-- 4 = stats
--
local nHellfireUp = 50
local nWallUp = 30
local nWrathUp = 40

-- hero state val values
local nNoHealth = 20
local nNoMana   = 10

-- level bonuses depending of the skill level
local nSkillLevelBonus = 4

-- Wrath range queries do not work...
local tWrathRange = { 2000, 2500, 3000 }
tWrathRange[0] = 2000

pharaoh.doHarass = {}

local function CustomHarassUtilityFnOverride(hero)
  pharaoh.doHarass = {} -- reset
  local unitSelf = core.unitSelf

  local heroPos = hero:GetPosition()
  local selfPos = unitSelf:GetPosition()

  local nMyState = HeroStateValueUtility(unitSelf, nNoMana, nNoHealth)
  local nEnemyState = HeroStateValueUtility(hero, nNoMana, nNoHealth)
  local nRet = (nEnemyState - nMyState)

  local bCanSee = core.CanSeeUnit(pharaoh, hero)

  local nHellfireVal = 0
  local nWallVal = 0
  local nWrathVal = 0

  local nTargetDistanceSq = Vector3.Distance2DSq(selfPos, heroPos)

  if skills.abilHellfire:CanActivate() and bCanSee then
    local nRange = skills.abilHellfire:GetTargetRadius()

    if nTargetDistanceSq < (nRange * nRange) then
      nHellfireVal = nHellfireUp + skills.abilHellfire:GetLevel() * nSkillLevelBonus
    end

  end

  if skills.abilWall:CanActivate() and bCanSee then
    local nRange = 250

    if nTargetDistanceSq < (nRange * nRange) then
      nWallVal = nWallUp + skills.abilWall:GetLevel() * nSkillLevelBonus
    end
  end

  if skills.abilWrath:CanActivate() then
    local nCreeps = NearbyEnemyCreepCountUtility(pharaoh, heroPos, 400)
    local nHeroes = NearbyEnemyHeroCountUtility(pharaoh, heroPos, 400)
    local nRange  = tWrathRange[skills.abilWrath:GetLevel()]

    if nCreeps < 3 and nHeroes < 2 and nTargetDistanceSq < (nRange * nRange) then
      nWrathVal = nWrathUp + skills.abilWrath:GetLevel() * nSkillLevelBonus
    end
  end

  if nHellfireVal > 0 or nWallVal > 0 or nWrathVal > 0 then
    pharaoh.doHarass["target"] = hero
    if nHellfireVal > nWallVal then
      if nHellfireVal > nWrathVal then
        pharaoh.doHarass["skill"] = skills.abilHellfire
        pharaoh.doHarass["skill_name"] = "Hellfire"
      else
        pharaoh.doHarass["skill"] = skills.abilWrath
        pharaoh.doHarass["skill_name"] = "Wrath"
      end
    else
      if nWallVal > nWrathVal then
        pharaoh.doHarass["skill"] = skills.abilWall
        pharaoh.doHarass["skill_name"] = "Wall"
      else
        pharaoh.doHarass["skill"] = skills.abilWrath
        pharaoh.doHarass["skill_name"] = "Wrath"
      end
    end

    BotEcho(format("  CustomHarass; Hellfire: %g, Wall: %g, Wrath: %g", nRet + nHellfireVal, nRet + nWallVal, nRet + nWrathVal))
  end
  nRet = nRet + math.max(nHellfireVal, math.max(nWallVal, nWrathVal))

  -- do avoid enemy towers
  if core.GetClosestEnemyTower(selfPos, 715) then
    nRet = nRet / 2
  end

  return nRet;
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)
  local unitTarget = pharaoh.doHarass["target"]
  local skill = pharaoh.doHarass["skill"]
  if unitTarget == nil or skill == nil or not skill:CanActivate() then
    return pharaoh.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local targetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
  local bActionTaken = false

  if pharaoh.doHarass["skill_name"] == "Wrath" then
    local nRange = tWrathRange[skills.abilWrath:GetLevel()]
    if targetDistanceSq < (nRange * nRange) then
      BotEcho(format("  HarassHeroExecute with %s", skill:GetName()))
      bActionTaken = core.OrderAbilityPosition(botBrain, skill, unitTarget:GetPosition())
    end
  elseif pharaoh.doHarass["skill_name"] == "Hellfire" then
    local nRange = skill:GetTargetRadius()
    if targetDistanceSq < (nRange * nRange) then
      BotEcho(format("  HarassHeroExecute with %s", skill:GetName()))
      bActionTaken = core.OrderAbility(botBrain, skill)
    end
  elseif pharaoh.doHarass["skill_name"] == "Wall" then
    BotEcho(format("  HarassHeroExecute with %s", skill:GetName()))
    bActionTaken = core.OrderAbility(botBrain, skill)
  else
    BotEcho(format("  HarassHeroExecute: INVALID SKILL %s", skill:GetName()))
  end

  if not bActionTaken then
    return pharaoh.harassExecuteOld(botBrain)
  end
end
pharaoh.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Sniper behavior. Teambot calculates the position for this.
--
local nSnipePossible = 60
local nSnipeTimeout = 2000 -- ms => 2s

-- this will contain all the info.
pharaoh.doSnipe = {}

function behaviorLib.SniperUtility(botBrain)
  teambot = core.teamBotBrain
  if teambot.snipeTargetPos then
    if skills.abilTormented:CanActivate() then
      if (teambot.snipeTimestamp + nSnipeTimeout) < HoN.GetGameTime() then
        BotEcho("SniperUtility: Dropping too old.")
      else
        return nSnipePossible
      end
    else
      BotEcho("SniperUtility: Can't activate :'(")
    end
  end

  core.teamBotBrain.snipeTargetPos = nil
  core.teamBotBrain.snipeTimestamp = nil

  return 0
end

function behaviorLib.SniperExecute(botBrain)
  teambot = core.teamBotBrain
  targetPos = teambot.snipeTargetPos
  if targetPos then
    if skills.abilTormented:CanActivate() then
      if (teambot.snipeTimestamp + nSnipeTimeout) < HoN.GetGameTime() then
        BotEcho("SniperExecute: Dropping too old.")
      else
        BotEcho(format("SNIPING! to pos { %g, %g, %g }", targetPos.x, targetPos.y, targetPos.z))
        core.OrderAbilityPosition(botBrain, skills.abilTormented, targetPos)
        core.teamBotBrain.snipeTargetPos = nil
        core.teamBotBrain.snipeTimestamp = nil
      end
    end
  else
    BotEcho("SniperExecute: INVALID TARGET!")
  end
end
behaviorLib.SniperBehavior = {}
behaviorLib.SniperBehavior["Utility"] = behaviorLib.SniperUtility
behaviorLib.SniperBehavior["Execute"] = behaviorLib.SniperExecute
behaviorLib.SniperBehavior["Name"] = "Sniping LAIKA BAAAUUUS"
tinsert(behaviorLib.tBehaviors, behaviorLib.SniperBehavior)
--------------------------------------------------------------------------------

BotEcho("finished loading faulty_pharaoh.lua")
