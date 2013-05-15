local _G = getfenv(0)
local tempest = _G.object

tempest.heroName = "Hero_Tempest"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = tempest.core, tempest.behaviorLib
local tinsert = _G.table.insert

--------------------------------------------------------------
-- Itembuild --
--------------------------------------------------------------

behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_HealthPotion", "Item_PretendersCrown", "2 Item_ManaPotion" }
behaviorLib.LaneItems = { "Item_Strength5", "Item_Marchers", "Item_MightyBlade", "Item_Warhammer" }
behaviorLib.MidItems = {"Item_Immunity"}
behaviorLib.LateItems = { "Item_LifeSteal4", "Item_Sasuke", "Item_Damage9" }

tempest.denyTarget = nil

---------------------------------------------------------------
-- SkillBuild override --
-- Handles hero skill building. To customize just write own --
---------------------------------------------------------------
-- @param: none
-- @return: none

tempest.skills = {}
local skills = tempest.skills

---------------------------------------------------------------
-- Selitys buildin takana: Stun + minion autoattack tuhoaa,  --
-- mutta tärkeimpänä on aluksi maksimoida autoattack damage  --
-- minioneilta, jolloin lanen puskeminen + CC:n hyödyntämi-  --
-- nen on parhaimmillaan. Aoe spelli on semiturha omasta     --
-- mielestä, sillä korkea manacost yhdistettynä taistelun    --
-- mukana olevaan ketjustunnailuun on liikaa.                --
---------------------------------------------------------------


tempest.tSkills = {
  0, 1, 1, 0, 1,
  3, 1, 0, 0, 4,
  3, 4, 4, 4, 4,
  3, 4, 4, 4, 4,
  4, 2, 2, 2, 2
}

function tempest:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilStun == nil then
    skills.abilStun = unitSelf:GetAbility(0)
    skills.abilMinions = unitSelf:GetAbility(1)
    skills.abilAoe = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
tempest.SkillBuildOld = tempest.SkillBuild
tempest.SkillBuild = tempest.SkillBuildOverride

------------------------------------------------------
-- onthink override --
-- Called every bot tick, custom onthink code here --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function tempest:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
tempest.onthinkOld = tempest.onthink
tempest.onthink = tempest.onthinkOverride

----------------------------------------------
-- oncombatevent override --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function tempest:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
tempest.oncombateventOld = tempest.oncombatevent
tempest.oncombatevent = tempest.oncombateventOverride

----------------------------------------------
-- Denying stuff --
----------------------------------------------

local function IsSiege(unit)
    local unitType = unit:GetTypeName()
    return unitType == "Creep_LegionSiege" or unitType == "Creep_HellbourneSiege"
end

local function ShouldDenyByHP(unit)
    local hpp = unit:GetHealthPercent()

    if hpp < 0.05 then
        core.BotEcho('denying unit with health at '..hpp..'%')
        return true
    end

    return false
end

local function GetUnitToDenyWithSpell(botBrain, myPos, radius)
    local unitsLocal = core.AssessLocalUnits(botBrain, myPos, radius)
    local allies = unitsLocal.AllyCreeps
    local enemies = unitsLocal.EnemyCreeps
    local unitTarget = nil
    local nDistance = 0
    
    for _,unit in pairs(allies) do
        local nNewDistance = Vector3.Distance2DSq(myPos, unit:GetPosition())

        if not IsSiege(unit) and (not unitTarget or nNewDistance < nDistance) then
            unitTarget = unit
            nDistance = nNewDistance
        end
    end
    
    local allyTargetHealth = 0.0
    if unitTarget then
        allyTargetHealth = unitTarget:GetHealthPercent()
    end
    
    for _,unit in pairs(enemies) do
        local nNewDistance = Vector3.Distance2DSq(myPos, unit:GetPosition())

        if not IsSiege(unit) and (not unitTarget or nNewDistance < nDistance) 
           and unit:GetHealthPercent() <= allyTargetHealth then
            unitTarget = unit
            nDistance = nNewDistance
        end
    end
    
    return unitTarget
end

local function IsUnitCloserThanEnemies(botBrain, myPos, unit)
    local unitsLocal = core.AssessLocalUnits(botBrain, myPos, Vector3.Distance2DSq(myPos, unit:GetPosition()))
    return core.NumberElements(unitsLocal.EnemyHeroes) <= 0
end

local function DenyBehaviorUtility(botBrain)
    local unitSelf = botBrain.core.unitSelf
    local abilDeny = skills.abilMinions
    local myPos = unitSelf:GetPosition()
    local unit = GetUnitToDenyWithSpell(botBrain, myPos, abilDeny:GetRange())
    
    if abilDeny:CanActivate() and unit and IsUnitCloserThanEnemies(botBrain, myPos, unit) then
        tempest.denyTarget = unit
        return 100
    end
    
    return 0
end

local function DenyBehaviorExecute(botBrain)
    local unitSelf = botBrain.core.unitSelf
    local abilDeny = skills.abilMinions
    local target = tempest.denyTarget
    
    -- for some reason this check needs to be done, wtf
    if target and target:GetTypeName() == "Gadget_HomecomingStone" then
        tempest.denyTarget = nil
        return false
    end
    
    if target then
        core.BotEcho("denying unit "..target:GetTypeName())
        tempest.denyTarget = nil
        return core.OrderAbilityEntity(botBrain, abilDeny, target)
    end
    return false
end

local DenyBehavior = {}
DenyBehavior["Utility"] = DenyBehaviorUtility
DenyBehavior["Execute"] = DenyBehaviorExecute
DenyBehavior["Name"] = "Denying creep with spell"
tinsert(behaviorLib.tBehaviors, DenyBehavior)
