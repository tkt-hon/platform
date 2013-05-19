local _G = getfenv(0)
local voodoo = _G.object

voodoo.heroName = "Hero_Voodoo"
runfile 'bots/core_herobot.lua'

local core, behaviorLib = voodoo.core, voodoo.behaviorLib
--------------------------------------------------------------
-- Itembuild --
--------------------------------------------------------------

behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_HealthPotion", "Item_PretendersCrown", "2 Item_ManaPotion" }
behaviorLib.LaneItems = { "Item_Strength5", "Item_Marchers", "Item_MightyBlade",  "Item_Warhammer", "Item_Immunity", "Item_Glowstone", "Item_NeophytesBook", "Item_MigthyBlade", "Item_Intelligence7" }
behaviorLib.MidItems = { }
behaviorLib.LateItems = { "Item_LifeSteal4", "Item_Sasuke", "Item_Damage9" }

---------------------------------------------------------------
-- SkillBuild override --
-- Handles hero skill building. To customize just write own --
---------------------------------------------------------------
-- @param: none
-- @return: none

voodoo.skills = {}
local skills = voodoo.skills

---------------------------------------------------------------
-- Selitys buildin takana: Stun + debuff + ulti combolla saa --
-- heron kuin heron hengiltä, stunni tärkeimpänä, koska muut --
-- herot pystyvät maksimoimaan vahinkonsa silloin. Mojo on   --
-- käytettävissä myöhemmissä tilanteissa tukevana skillinä,  --
-- mikäli siihen on tarve (esim nallen elossapitäminen).     --
---------------------------------------------------------------


voodoo.tSkills = {
  0, 2, 0, 2, 0,
  3, 0, 2, 2, 1,
  3, 1, 1, 1, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}

function voodoo:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilStun == nil then
    skills.abilStun = unitSelf:GetAbility(0)
    skills.abilMojo = unitSelf:GetAbility(1)
    skills.abilDebuff = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
voodoo.SkillBuildOld = voodoo.SkillBuild
voodoo.SkillBuild = voodoo.SkillBuildOverride

------------------------------------------------------
-- onthink override --
-- Called every bot tick, custom onthink code here --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function voodoo:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
voodoo.onthinkOld = voodoo.onthink
voodoo.onthink = voodoo.onthinkOverride

----------------------------------------------
-- oncombatevent override --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function voodoo:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
voodoo.oncombateventOld = voodoo.oncombatevent
voodoo.oncombatevent = voodoo.oncombateventOverride

local function NearbyCreepCount(botBrain, center, radius)
  local count = 0
  local unitsLocal = core.AssessLocalUnits(botBrain, center, radius)
  local enemies = unitsLocal.EnemyCreeps
  for _,unit in pairs(enemies) do
    count = count + 1
  end
  return count
end

local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0

  if skills.abilStun:CanActivate() then
    nUtil = nUtil + 5*skills.abilStun:GetLevel()
  end

  local creeps = NearbyCreepCount(voodoo, hero:GetPosition(), 700)

  if skills.abilUltimate:CanActivate() and creeps < 3 then
    nUtil = nUtil + 100
  end

  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return voodoo.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
  local nLastHarassUtility = behaviorLib.lastHarassUtil

  local bActionTaken = false

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

  local abilNuke = skills.abilStun
  if abilNuke:CanActivate() then
    local nRange = abilNuke:GetRange()
    if nTargetDistanceSq < (nRange * nRange) then
      bActionTaken = core.OrderAbilityEntity(botBrain, abilNuke, unitTarget)
    else
      bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
    end
  end

  if not bActionTaken then
    return voodoo.harassExecuteOld(botBrain)
  end
end
voodoo.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride
