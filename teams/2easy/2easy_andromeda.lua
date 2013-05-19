local _G = getfenv(0)
local andromeda = _G.object

andromeda.heroName = "Hero_Andromeda"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = andromeda.core, andromeda.behaviorLib

--paska buildi
behaviorLib.StartingItems = { "Item_Marchers", "Item_RunesOfTheBlight" }
behaviorLib.LaneItems = { "Item_EnhancedMarchers", "Item_Pierce 3" }
behaviorLib.MidItems = {  "Item_DaemonicBreastplate" }
behaviorLib.LateItems = { "Item_Evasion" }

andromeda.skills = {
  2, 0, 2, 0, 2,
  3, 0, 0, 2, 1,
  3, 1, 1, 1, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}
local skills = andromeda.skills

local tinsert = _G.table.insert

core.itemWard = nil

function andromeda:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilDeny == nil then
    skills.abilStun = unitSelf:GetAbility(0)
    skills.abilDebuff = unitSelf:GetAbility(1)
    skills.abilAura = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  if unitSelf:GetAbilityPointsAvailable() <= 0 then
    return
  end
  if skills.abilUltimate:CanLevelUp() then
    skills.abilUltimate:LevelUp()
  elseif skills.abilAura:CanLevelUp() then
    skills.abilAura:LevelUp()
  elseif skills.abilStun:CanLevelUp() then
    skills.abilStun:LevelUp()
  elseif skills.abilDebuff:CanLevelUp() then
    skills.abilDebuff:LevelUp()
  else
    skills.stats:LevelUp()
  end
end
andromeda.SkillBuild = andromeda.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function andromeda:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
andromeda.onthinkOld = andromeda.onthink
andromeda.onthink = andromeda.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function andromeda:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
-- override combat event trigger function.
andromeda.oncombateventOld = andromeda.oncombatevent
andromeda.oncombatevent = andromeda.oncombateventOverride

local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0


  local unitSelf = core.unitSelf
  local manaP = unitSelf:GetManaPercent()
  local mana = unitSelf:GetMana()

  if skills.abilStun:CanActivate() and ((manaP > 0.90) or (mana > 370)) then
    nUtil = nUtil + 30
    local damages = {50,100,125,175}
    if hero:GetHealth() < damages[skills.abilStun:GetLevel()] then
      nUtil = nUtil + 30
    end
  end

  if skills.abilUltimate:CanActivate()  then
    -- and at own tower or teammates close
    nUtil = nUtil + 100
  end

  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return andromeda.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())

  local bActionTaken = false

  if core.CanSeeUnit(botBrain, unitTarget) then
    local abilStun = skills.abilStun

    if abilStun:CanActivate() then
      local nRange = abilStun:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilStun, unitTarget)
      else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
      end
    end

    local abilUltimate = skills.abilUltimate
    if not bActionTaken then
      if abilUltimate:CanActivate() then
        local nRange = abilUltimate:GetRange()
        if nTargetDistanceSq < (nRange * nRange) then
          bActionTaken = core.OrderAbilityEntity(botBrain, abilUltimate, unitTarget)
        else
          bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
        end
      end
    end
  end

  if not bActionTaken then
    return andromeda.harassExecuteOld(botBrain)
  end
end
andromeda.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride
