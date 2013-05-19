local _G = getfenv(0)
local hammerstorm = _G.object

hammerstorm.heroName = "Hero_Hammerstorm"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = hammerstorm.core, hammerstorm.behaviorLib

behaviorLib.StartingItems = { "Item_LoggersHatchet", "Item_IronBuckler", "Item_RunesOfTheBlight"}
behaviorLib.LaneItems = { "Item_EnhancedMarchers", "Item_Brutalizer" }
behaviorLib.MidItems = { "Item_Protect" }
behaviorLib.LateItems = { "Item_BehemothsHeart" }

local tinsert = _G.table.insert

hammerstorm.skills = {}
local skills = hammerstorm.skills

hammerstorm.tSkills = {
  0, 4, 0, 4, 0,
  3, 0, 2, 4, 2,
  3, 2, 2, 4, 4,
  3, 4, 4, 4, 4,
  4, 1, 1, 1, 1
}


function hammerstorm:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilStun == nil then
    skills.abilStun = unitSelf:GetAbility(0)
    skills.abilSwing = unitSelf:GetAbility(1)
    skills.abilBuff = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
hammerstorm.SkillBuildOld = hammerstorm.SkillBuild
hammerstorm.SkillBuild = hammerstorm.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function hammerstorm:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
hammerstorm.onthinkOld = hammerstorm.onthink
hammerstorm.onthink = hammerstorm.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function hammerstorm:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
-- override combat event trigger function.
hammerstorm.oncombateventOld = hammerstorm.oncombatevent
hammerstorm.oncombatevent = hammerstorm.oncombateventOverride

local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0


  local unitSelf = core.unitSelf
  local manaP = unitSelf:GetManaPercent()
  local mana = unitSelf:GetMana()

  if skills.abilStun:CanActivate() and (mana > 250) then
    nUtil = nUtil + 30
    local damages = {100,175,250,325}
    if hero:GetHealth() < damages[skills.abilStun:GetLevel()] then
      nUtil = nUtil + 30
    end
  end

  if skills.abilUltimate:CanActivate()  then
    nUtil = nUtil + 50
  end

  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride


local function HarassHeroExecuteOverride(botBrain)

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return hammerstorm.harassExecuteOld(botBrain)
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
        core.AllChat("Hammertime!",10)
      else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
      end
    end

    local abilUltimate = skills.abilUltimate
    if not bActionTaken then
      if abilUltimate:CanActivate() then
        local nRange = 500
        if nTargetDistanceSq < (nRange*nRange) then
          bActionTaken = core.OrderAbility(botBrain, abilUltimate)
          core.AllChat("GRAAAAH!",10)
        else
          bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
        end
      end
    end
    local abilBuff = skills.abilBuff
    local mana = unitSelf:GetMana()
    if not bActionTaken then
      if abilBuff:CanActivate() and mana > 340 then
        local nRange = 500
        if nTargetDistanceSq < (nRange*nRange) then
          bActionTaken = core.OrderAbility(botBrain, abilBuff)
          core.AllChat("CHAARGE!",10)
        else
          bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
        end
      end
    end
  end

  if not bActionTaken then
    return hammerstorm.harassExecuteOld(botBrain)
  end
end

hammerstorm.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride
