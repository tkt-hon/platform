local _G = getfenv(0)
local moonqueen = _G.object

moonqueen.heroName = "Hero_Krixi"

runfile 'bots/core_herobot.lua'
runfile 'bots/libhon/utils.lua'

local core, behaviorLib = moonqueen.core, moonqueen.behaviorLib

-- empty spaces filled with Minor Totems
-- game adds Homecoming Stones to list at some point
behaviorLib.StartingItems = { "6 Item_MinorTotem", "Item_Fleetfeet", "Item_Quickblade", "Item_Sicarius", "Item_BrainOfMaliken", "Item_ApprenticesRobe" }
-- {Fleetfeet} -> {Fleetfeet, Quickblade} -> {Firebrand} -> {Firebrand, Pickled Brain} -> {Firebrand, Apprentice's Robe, Pickled Brain}
behaviorLib.LaneItems = { "Item_ApprenticesRobe", "Item_NeophytesBook", "Item_Searinglight", "Item_Manatube" }
-- {Firebrand, Apprentice's Robe, Neophyte's Book, Pickled Brain} -> {Searing Light, Pickled Brain} -> {Searing Light, Manatube, Pickled Brain}
behaviorLib.MidItems = { "Item_BlessedArmband", "Item_MightyBlade", "Item_Dawnbringer", "Item_Regen", "Item_Confluence" }
-- {Searing Light, Bolstering Armband, Manatube, Pickled Brain} -> {Searing Light, Bolstering Armband, Mighty Blade, Manatube, Pickled Brain}
-- {Dawnbringer, Manatube, Pickled Brain} -> {Dawnbringer, Sustainer, Pickled Brain} -> {Dawnbringer, Sustainer, Blessed Orb, Pickled Brain}
behaviorLib.LateItems = { "Item_Protect", "Item_Quickblade", "Item_Glowstone", "Item_MightyBlade", "Item_Intelligence7" }
-- {Dawnbringer, Null Stone, Pickled Brain} -> {Dawnbringer, Null Stone, Quickblade, Pickled Brain} -> {Dawnbringer, Null Stone, Quickblade, Glowstone, Pickled Brain}
-- {Dawnbringer, Null Stone, Quickblade, Mighty Blade, Glowstone, Pickled Brain} -> {Dawnbringer, Null Stone, Staff of the Master, Pickled Brain}

behaviorLib.pushingStrUtilMul = 1

moonqueen.skills = {}
local skills = moonqueen.skills

core.itemGeoBane = nil

moonqueen.tSkills = {
  1, 0, 0, 1, 4,
  3, 0, 1, 1, 4,
  3, 2, 2, 4, 4,
  3, 4, 0, 4, 4,
  2, 2, 4, 4, 4
}

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
-- default
function moonqueen:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilNuke == nil then
    skills.abilNuke = unitSelf:GetAbility(0)
    skills.abilBounce = unitSelf:GetAbility(1)
    skills.abilAura = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
moonqueen.SkillBuildOld = moonqueen.SkillBuild
moonqueen.SkillBuild = moonqueen.SkillBuildOverride

---------------------------------------------------------------
--            Harass utility override                        --
---------------------------------------------------------------
-- @param: hero
-- @return: utility
function behaviorLib.CustomHarassUtility(hero)
    return 100 -- ???
end

--------------------------------------------------------------
--                    Harass Behavior                       --
-- All code how to use abilities against enemies goes here  --
--------------------------------------------------------------
-- @param: botbrain
-- @return: none
local oldExecute = behaviorLib.HarassHeroBehavior["Execute"]
local function executeBehavior(botBrain)
    p("Behaviour: Execute")
    return oldExecute(botBrain)
end
behaviorLib.HarassHeroBehavior["Execute"] = executeBehavior

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function moonqueen:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
moonqueen.onthinkOld = moonqueen.onthink
moonqueen.onthink = moonqueen.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function moonqueen:oncombateventOverride(eventData)
    self:oncombateventOld(eventData)

    -- Uncomment this to print the combat events
    p(eventData)
end
-- override combat event trigger function.
moonqueen.oncombateventOld = moonqueen.oncombatevent
moonqueen.oncombatevent = moonqueen.oncombateventOverride
