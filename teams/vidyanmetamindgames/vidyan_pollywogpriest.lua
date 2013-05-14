local _G = getfenv(0)
local pollywogpriest = _G.object

pollywogpriest.heroName = "Hero_PollywogPriest"

runfile 'bots/core_herobot.lua'
local core, behaviorLib = pollywogpriest.core, pollywogpriest.behaviorLib
local tinsert = _G.table.insert

--------------------------------------------------------------
-- Itembuild --
--------------------------------------------------------------

behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_HealthPotion", "Item_PretendersCrown", "Item_CrushingClaws", "Item_ManaPotion" }
behaviorLib.LaneItems = { "Item_Marchers", "Item_Strength5", "Item_Steamboots", "Item_Glowstone", "Item_MightyBlade", "Item_NeophytesBook", "Item_Quickblade" }
behaviorLib.MidItems = {}
behaviorLib.LateItems = { "Item_Intelligence7", "Item_Protect", "Item_Damage9" }

---------------------------------------------------------------
-- SkillBuild override --
-- Handles hero skill building. To customize just write own --
---------------------------------------------------------------
-- @param: none
-- @return: none

pollywogpriest.skills = {}
local skills = pollywogpriest.skills

---------------------------------------------------------------
-- Selitys buildin takana: Tongue ekana, jotta voidaan saada --
-- alkupäässä tehtyä damagea enemmän, ykköslevelin joltti ei --
-- tee paskaakaan damagea. Nukea kun saa lisää, niin sitten  --
-- voidaan käyttää sitä puskemisen yhteydessä. Hexiä otetaan --
-- myös sen takia, että sillä saadaan yksi cooldown lisää,   --
-- jolla voidaan selvitä taisteluista. Tärkeää saada frageja --
-- ultimatea käyttämällä suoraan heroihin trapaten ne sinne. --
---------------------------------------------------------------

pollywogpriest.tSkills = {
  2, 0, 0, 1, 0,
  3, 0, 2, 2, 2,
  3, 1, 1, 1, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}

function pollywogpriest:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilNuke == nil then
    skills.abilNuke = unitSelf:GetAbility(0)
    skills.abilHex = unitSelf:GetAbility(1)
    skills.abilTongue = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
pollywogpriest.SkillBuildOld = pollywogpriest.SkillBuild
pollywogpriest.SkillBuild = pollywogpriest.SkillBuildOverride

------------------------------------------------------
-- onthink override --
-- Called every bot tick, custom onthink code here --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function pollywogpriest:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
pollywogpriest.onthinkOld = pollywogpriest.onthink
pollywogpriest.onthink = pollywogpriest.onthinkOverride

----------------------------------------------
-- oncombatevent override --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function pollywogpriest:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
pollywogpriest.oncombateventOld = pollywogpriest.oncombatevent
pollywogpriest.oncombatevent = pollywogpriest.oncombateventOverride

----------------------------------------------
-- Ulti behavior
----------------------------------------------
local function IsStunned(unit)
    -- todo: implement
    return nil
end

local ultiTarget = nil

local function UltiBehaviorUtility(botBrain)
    if not skills.abilUltimate:CanActivate() then
        return 0
    end

    local unitSelf = core.unitSelf
    
    -- todo: check for nearby heroes
    -- if found: check if any of them are stunned
    -- if stunned: cast ulti on them
    
    
    -- else: cast it on a turret when own creeps are nearby
    local tower = core.GetClosestEnemyTower(unitSelf:GetPosition(), 1000)
    if tower ~= nil then
        local towerPos = tower:GetPosition()
        local units = core.AssessLocalUnits(botBrain, towerPos, 600)
        
        -- enough creeps, let's cast
        if #units.AllyCreeps > 0 then
            ultiTarget = tower
            core.BotEcho("found tower")
            
            return 100
        end
    end
    
    return 0
end

local function UltiBehaviorExecute(botBrain)
    if not skills.abilUltimate:CanActivate() or ultiTarget == nil then
        return false
    end
    
    local ulti = skills.abilUltimate
    local targetPos = ultiTarget:GetPosition()
    
    ultiTarget = nil
    return core.OrderAbilityPosition(botBrain, ulti, targetPos)
end

local UltiBehavior = {}
UltiBehavior["Utility"] = UltiBehaviorUtility
UltiBehavior["Execute"] = UltiBehaviorExecute
UltiBehavior["Name"] = "Casting ulti on some unlucky bastard"
tinsert(behaviorLib.tBehaviors, UltiBehavior)

