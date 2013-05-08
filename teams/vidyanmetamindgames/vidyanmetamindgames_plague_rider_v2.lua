local _G = getfenv(0)
local plaguerider = _G.object

plaguerider.heroName = "Hero_DiseasedRider"

runfile 'bots/core_herobot.lua'
runfile 'bots/teams/vidyanmetamindgames/shoppinglib.lua'

local core, behaviorLib = plaguerider.core, plaguerider.behaviorLib

behaviorLib.StartingItems = { "Item_HealthPotion", "Item_ManaRegen3" }
behaviorLib.LaneItems = { "Item_MysticPotpourri", "Item_MysticVestments", "Item_Marchers", "Item_EnhancedMarchers", "Item_MagicArmor2" }
behaviorLib.MidItems = { "Item_SpellShards 3", "Item_Intelligence7", "Item_Lightbrand" }
behaviorLib.LateItems = { "Item_GrimoireOfPower" }

shopping.Setup(true, true, false, false, true, false)

plaguerider.skills = {}
local skills = plaguerider.skills

plaguerider.tSkills = {
    1, 4, 1, 4, 1,
    3, 1, 4, 4, 4,
    3, 0, 0, 0, 0,
    3, 4, 4, 4, 4,
    4, 2, 2, 2, 2
}

local tinsert = _G.table.insert

function plaguerider:SkillBuildOverride()
    local unitSelf = self.core.unitSelf
    if skills.abilDeny == nil then
        skills.abilNuke = unitSelf:GetAbility(0)
        skills.abilShield = unitSelf:GetAbility(1)
        skills.abilDeny = unitSelf:GetAbility(2)
        skills.abilUltimate = unitSelf:GetAbility(3)
        skills.stats = unitSelf:GetAbility(4)
    end
    self:SkillBuildOld()
end
plaguerider.SkillBuildOld = plaguerider.SkillBuild
plaguerider.SkillBuild = plaguerider.SkillBuildOverride

plaguerider.ShieldTarget = nil

local function ShieldBehaviorExecute(botBrain)
    local unitSelf = botBrain.core.unitSelf
    local abilShield = skills.abilShield
    local unitsLocal = core.AssessLocalUnits(botBrain, unitSelf:GetPosition(), skills.abilShield:GetRange())

    local target = GetShieldTarget(unitsLocal)  

    if target ~= nil and abilShield:CanActivate() then
        core.BotEcho("Casting shield on "..target:GetTypeName().." with hp="..target:GetHealth())
        return core.OrderAbilityEntity(botBrain, abilShield, target, false)
    end

    return false
end

local ShieldBehavior = {}
ShieldBehavior["Utility"] = ShieldBehaviorUtility
ShieldBehavior["Execute"] = ShieldBehaviorExecute
ShieldBehavior["Name"] = "Casting shield spell on a creep"
tinsert(behaviorLib.tBehaviors, ShieldBehavior)

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function plaguerider:SkillBuildOverride()
  plaguerider:SkillBuildOld()
end
plaguerider.SkillBuildOld = plaguerider.SkillBuild
plaguerider.SkillBuild = plaguerider.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function plaguerider:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
plaguerider.onthinkOld = plaguerider.onthink
plaguerider.onthink = plaguerider.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function plaguerider:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
-- override combat event trigger function.
plaguerider.oncombateventOld = plaguerider.oncombatevent
plaguerider.oncombatevent = plaguerider.oncombateventOverride
