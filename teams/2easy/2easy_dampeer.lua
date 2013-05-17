local _G = getfenv(0)
local dampeer = _G.object

dampeer.heroName = "Hero_Dampeer"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = dampeer.core, dampeer.behaviorLib

--huono buildi, paranna
behaviorLib.StartingItems  = {"Item_Marchers", "Item_RunesOfTheBlight" }
behaviorLib.LaneItems  = { "Item_Protect", "Item_EnhancedMarchers" }
behaviorLib.MidItems  = { "Item_SpellShards 3" }
behaviorLib.LateItems  = { "Item_ManaBurn2" }

local tinsert = _G.table.insert

dampeer.skills = {}
local skills = dampeer.skills

dampeer.tSkills = {
  2, 1, 2, 1, 2,
  3, 1, 1, 2, 0,
  3, 0, 0, 0, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}


function dampeer:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilScare == nil then
    skills.abilScare = unitSelf:GetAbility(0)
    skills.abilFlight = unitSelf:GetAbility(1)
    skills.abilAura = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
    self:SkillBuildOld()
end
dampeer.SkillBuildOld = dampeer.SkillBuild
dampeer.SkillBuild = dampeer.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function dampeer:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
dampeer.onthinkOld = dampeer.onthink
dampeer.onthink = dampeer.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function dampeer:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
-- override combat event trigger function.
dampeer.oncombateventOld = dampeer.oncombatevent
dampeer.oncombatevent = dampeer.oncombateventOverride

local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0

  
  local unitSelf = core.unitSelf
  local manaP = unitSelf:GetManaPercent()
  local mana = unitSelf:GetMana()

  if skills.abilFlight:CanActivate() then
    local damages = {50,90,130,170}
    if hero:GetHealth() < damages[skills.abilFlight:GetLevel()] then
      nUtil = nUtil + 20
    end
  end

  if skills.abilScare:CanActivate() then
    nUtil = nUtil + 5
    local damages = {75,125,175,225}
    if hero:GetHealth() < damages[skills.abilScare:GetLevel()] then
      nUtil = nUtil + 20
    end
  end

  if skills.abilUltimate:CanActivate() then
    nUtil = nUtil + 5
  end

  if ((manaP > 0.90) or (mana > 350)) then
    nUtil = nUtil * 3
  end

  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return dampeer.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
  local bActionTaken = false

  if core.CanSeeUnit(botBrain, unitTarget) then

    local abilScare = skills.abilScare
    if abilScare:CanActivate() then
      if nTargetDistanceSq < 250*250 then
        bActionTaken = core.OrderAbility(botBrain, abilScare)
	core.AllChat("BOOO!", 10)
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
	  core.AllChat("OM NOM", 10)
        else
          bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
        end
      end
    end

  
    local abilFlight = skills.abilFlight
    if abilFlight:CanActivate() then
      local nRange = abilFlight:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilFlight, unitTarget)
	core.AllChat("I believe I can flyyy", 10)
      else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
      end
    end
  end

  if not bActionTaken then
    return dampeer.harassExecuteOld(botBrain)
  end
end
dampeer.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

