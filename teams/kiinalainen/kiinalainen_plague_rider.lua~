local _G = getfenv(0)
local plaguerider = _G.object

plaguerider.heroName = "Hero_DiseasedRider"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = plaguerider.core, plaguerider.behaviorLib
plaguerider.skills = {}
local skills = plaguerider.skills
---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
-- table listing desired skillbuild. 0=Q(Contagion), 1=W(Cursed Shield), 2=E(Extinguish), 3=R(Plague Carrier), 4=AttributeBoost
plaguerider.tSkills = {
   0, 2, 0, 2, 0,
   3, 0, 2, 2, 1,
   3, 4, 4, 4, 4,
   3, 1, 1, 1, 4,
   4, 4, 4, 4, 4,
}

function plaguerider:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilContagion == nil then
    skills.abilContagion = unitSelf:GetAbility(0)
    skills.abilCursedShield = unitSelf:GetAbility(1)
    skills.abilExtinguish = unitSelf:GetAbility(2)
    skills.abilPlagueCarrier = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
plaguerider.SkillBuildOld = plaguerider.SkillBuild
plaguerider.SkillBuild = plaguerider.SkillBuildOverride

--items
behaviorLib.StartingItems = { "Item_TrinketOfRestoration", "Item_RunesOfTheBlight", "Item_MinorTotem", "Item_FlamingEye" }
behaviorLib.LaneItems = { "Item_Marchers", "Item_MysticVestments", "Item_EnhancedMarchers", "Item_MagicArmor2" }
behaviorLib.MidItems = { "Item_SpellShards 3", "Item_Intelligence7", "Item_Lightbrand" }
behaviorLib.LateItems = { "Item_GrimoireOfPower" }

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



-- These are bonus agression points if a skill/item is available for use
plaguerider.nContagionUp = 10
plaguerider.nPlagueCarrierUp = 35
plaguerider.nCursedShieldUp = 5
plaguerider.nExtinguishUp = 5
-- These are bonus agression points that are applied to the bot upon successfully using a skill/item
plaguerider.nExtinguishUse = 10
plaguerider.nContagionUse = 25
plaguerider.nPlagueCarrierUse = 55
 
--These are thresholds of aggression the bot must reach to use these abilities
plaguerider.nContagionThreshold = 10
plaguerider.nPlagueCarrierThreshold = 50
plaguerider.nExtinguishThreshold = 0
plaguerider.nCursedShieldThreshold = 20

------------------------------------------------------
--            CustomHarassUtility Override          --
-- Change Utility according to usable spells here   --
------------------------------------------------------
-- @param: IunitEntity hero
-- @return: number
local function CustomHarassUtilityFnOverride(hero)
    local nUtil = 0
     
    if skills.abilQ:CanActivate() then
        nUtil = nUtil + plaguerider.nContagionUp
    end
 
    if skills.abilW:CanActivate() then
        nUtil = nUtil + plaguerider.nCursedShieldUp
    end
 
    if skills.abilE:CanActivate() then
        nUtil = nUtil + plaguerider.nExtinguishUp
    end
 
    if skills.abilR:CanActivate() then
        nUtil = nUtil + plaguerider.nPlagueCarrierUp
    end
 
    return nUtil
end
-- assisgn custom Harrass function to the behaviourLib object
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function plaguerider:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

local nAddBonus = 0
 
    if EventData.Type == "Ability" then
        if EventData.InflictorName == "Ability_DiseasedRider1" then
            nAddBonus = nAddBonus + plaguerider.nContagionUse
        elseif EventData.InflictorName == "Ability_DiseasedRider3" then
            nAddBonus = nAddBonus + plaguerider.nExtinguishUse
        elseif EventData.InflictorName == "Ability_Pyromancer4" then
            nAddBonus = nAddBonus + plaguerider.nPlagueCarrierUse
        end
    end
 
   if nAddBonus > 0 then
        core.DecayBonus(self)
        core.nHarassBonus = core.nHarassBonus + nAddBonus
    end
 
end
-- override combat event trigger function.
plaguerider.oncombateventOld = plaguerider.oncombatevent
plaguerider.oncombatevent     = plaguerider.oncombateventOverride
  -- custom code here


