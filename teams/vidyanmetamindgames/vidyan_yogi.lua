local _G = getfenv(0)
local yogi = _G.object

local tinsert = _G.table.insert

yogi.heroName = "Hero_Yogi"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = yogi.core, yogi.behaviorLib

local arrowPos = nil
local booboo = nil

--------------------------------------------------------------
-- Itembuild - Loggers Hatchet, Iron Buckler, 		    -- 
-- Sword of the high, Mockki (damage10), thunderclaw ja     --
-- ekat bootsit menee nallelle, sen jälkeen loput herolle   --
--------------------------------------------------------------

behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_LoggersHatchet", "Item_IronBuckler" }
behaviorLib.LaneItems = { "Item_SwordOfTheHigh", "Item_Damage10", "Item_Marchers",  "Item_Steamboots", "Item_Marchers", "Item_Steamboots", "Item_Warhammer", "Item_Lightning1" }
behaviorLib.MidItems = {  }
behaviorLib.LateItems = { "Item_DaemonicBreastplate", "Item_LifeSteal4", "Item_Sasuke", "Item_Damage9" }

---------------------------------------------------------------
-- SkillBuild override --
-- Handles hero skill building. To customize just write own --
---------------------------------------------------------------
-- @param: none
-- @return: none

yogi.skills = {}
local skills = yogi.skills



-----------------------------------------------------------------
-- Selitys buildin takana: Nallen maksimointi alkuun, tällöin  --
-- saadaan nallesta kestävä ja damagea tekevä, sekä skillit.   --
-- Passiivinen skilli lvl 2 alkuun, jolloin Wild (buffi) pysyy --
-- jatkuvasti yllä, 30sec cd ja 30sec kestävä buffi. Ultimate  --
-- pidetään jatkuvasti toggletettuna kestävyyden lisäämiseksi  --
-----------------------------------------------------------------

yogi.tSkills = {
    0, 2, 0, 2, 0,
    3, 0, 2, 2, 1,
    3, 1, 1, 1, 4,
    3, 4, 4, 4, 4,
    4, 4, 4, 4, 4
}

function yogi:SkillBuildOverride()
    local unitSelf = self.core.unitSelf
    if skills.abilBear == nil then
        skills.abilBear = unitSelf:GetAbility(0)
        skills.abilBuff = unitSelf:GetAbility(1)
        skills.abilPassive = unitSelf:GetAbility(2)
        skills.abilUltimate = unitSelf:GetAbility(3)
        skills.stats = unitSelf:GetAbility(4)
    end
    self:SkillBuildOld()
end
yogi.SkillBuildOld = yogi.SkillBuild
yogi.SkillBuild = yogi.SkillBuildOverride


------------------------------------------------------
-- onthink override --
-- Called every bot tick, custom onthink code here --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
local bBearForm = false
function yogi:onthinkOverride(tGameVariables)
    self:onthinkOld(tGameVariables)
    
    if arrowPos ~= nil then
        --core.BotEcho(tostring(arrowPos))
        core.DrawDebugArrow(core.unitSelf:GetPosition(), arrowPos)
    end
    
    local abilBear = skills.abilBear
    local abilUltimate = skills.abilUltimate
    local canCast = abilBear:CanActivate()

    if abilBear:CanActivate() then
        core.OrderAbility(self, abilBear)
    end
    
    if core.unitSelf:GetLevel() >= 8 then
        local abilBuff = skills.abilBuff
        core.OrderAbility(self, abilBuff)
    end
    
    if not bBearForm then
        if abilUltimate:CanActivate() then
            core.OrderAbility(self, abilUltimate)
            bBearForm = true
        end
    end
    
    booboo = getBooBoo()
    
    if booboo == nil then
        return
    end
    
    if not boobooAttack(self, booboo) then
        --core.OrderMoveToPos(self, booboo, core.unitSelf:GetPosition(), true)
        local closestTower = core.GetClosestEnemyTower(booboo:GetPosition(), 100000)
        local distanceFromPosToTowerSq = nil
        
        if arrowPos == nil then
            arrowPos = core.unitSelf:GetPosition()
        end
        
        if closestTower ~= nil then
            distanceFromPosToTowerSq = Vector3.Distance2DSq(closestTower:GetPosition(), arrowPos)
        end
        
        if distanceFromPosToTowerSq == nil then
            distanceFromPosToTowerSq = 490001
        end
        
        --core.BotEcho(distance
        
        if distanceFromPosToTowerSq > 490000 then --If wanted position isn't within enemy tower range
            core.OrderMoveToPos(self, booboo, arrowPos, true)
        end
    end    
end
yogi.onthinkOld = yogi.onthink
yogi.onthink = yogi.onthinkOverride


function boobooAttack(botBrain, booboo)
    local unitsLocal = core.AssessLocalUnits(botBrain, booboo:GetPosition(), 500000)
    local enemyHeroes = unitsLocal.EnemyHeroes
    
    local boobooPos = booboo:GetPosition()
    
    local closestDistanceSq = 99999999999
    local currentTargetHero = nil

    local closestTower = core.GetClosestEnemyTower(booboo:GetPosition(), 100000)

    if enemyHeroes ~= nil then
    
        for _, unit in pairs(enemyHeroes) do
        
            local unitPos = unit:GetPosition()
            local distanceSq = Vector3.Distance2DSq(boobooPos, unitPos)
            
            
            if  distanceSq < 1000000 then --aka closer than 1000 units (250 000 for 500 units)
            
                local distanceFromUnitToTowerSq = Vector3.Distance2DSq(unitPos, closestTower:GetPosition())
                if distanceFromUnitToTowerSq > 490000 then --aka enemy hero is not within tower range
                    if distanceSq < closestDistanceSq then
                        currentTargetHero = unit
                        closestDistanceSq = distanceSq
                        
                        local unitType = currentTargetHero:GetTypeName()
                
                        --core.BotEcho(unitType)
                    end
                end
            end
            

        end
        
        if currentTargetHero ~= nil then
            core.OrderAttack(botBrain, booboo, currentTargetHero)
        end
    end
    
    if currentTargetHero == nil then
        local enemyCreeps = unitsLocal.EnemyCreeps
        --TODO: target creeps
        return false
    end
    
    return true
end


local function OverrideMoveExecute(botBrain, vecDesiredPosition)
   


    arrowPos = vecDesiredPosition
    return behaviorLib.MoveExecuteOld(botBrain, vecDesiredPosition)
end
behaviorLib.MoveExecuteOld = behaviorLib.MoveExecute
behaviorLib.MoveExecute = OverrideMoveExecute


----------------------------------------------
-- oncombatevent override --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function yogi:oncombateventOverride(EventData)
    self:oncombateventOld(EventData)
    
      if EventData.Type == "Death" then
        bBearForm = false
      end
    
    if EventData.Type == "Ability" then

        core.BotEcho(EventData.InflictorName)

        if EventData.InflictorName == "Ability_Yogi1" then
            getBooBoo()
        end
        
        if EventData.InflictorName == "Ability_Yogi4" then
            yogi.eventsLib.printCombatEvent(EventData)
            core.BotEcho("lelelelele " .. EventData.StateLevel)
            if EventData.StateLevel == nil then
                bBearForm = true
            end
        end
    end
    -- custom code here
end
yogi.oncombateventOld = yogi.oncombatevent
yogi.oncombatevent = yogi.oncombateventOverride


function getBooBoo()
    local units = core.localUnits["AllyUnits"]    
    
    for _, unit in pairs(units) do
        
        local unitType = unit:GetTypeName()
        --core.BotEcho(unitType)
        
        if unitType == "Pet_Yogi_Ability1" then
            --core.BotEcho("success")
            return unit
        end
    end
    
end

--Stuff below this should probably be copypastable to all other heroes...
-- Should probably use runfile (like on row 8) instead of copypasting though?

local function OverrideGetCreepAttackTarget(botBrain, unitEnemyCreep, unitAllyCreep)
    if unitEnemyCreep and core.CanSeeUnit(botBrain, unitEnemyCreep) then
        local unitSelf = botBrain.core.unitSelf
        local unitsLocal = core.AssessLocalUnits(botBrain, unitSelf:GetPosition(), 550)
        local unitsAllies = unitsLocal.AllyCreeps
        
        if #unitsAllies == 1 and unitsAllies[1]:GetHealthPercent() < 0.5 then
          return nil
        end
        
        local nTargetHealth = unitEnemyCreep:GetHealth()
        local nDamageAverage = core.GetFinalAttackDamageAverage(unitSelf)
        
        local LHTweak = 50
        
        nDamageAverage = LHTweak + nDamageAverage
        
        if nDamageAverage >= nTargetHealth then
            return unitEnemyCreep
        end
        
        --If you want to fiddle in percentages:
        
        --if unitEnemyCreep:GetHealthPercent() < 0.4 then
        --    return unitEnemyCreep
        --end

        return nil
    end
    return behaviorLib.GetCreepAttackTargetOLD(botBrain, unitEnemyCreep, unitAllyCreep)
end

behaviorLib.GetCreepAttackTargetOLD = behaviorLib.GetCreepAttackTarget
behaviorLib.GetCreepAttackTarget = OverrideGetCreepAttackTarget

------- Auto Attack Harrass Behavior ----------

local heroTarget

local function AutoAttackHarrassUtility(botBrain)
    local unitSelf = core.unitSelf
    local unitSelfPos = unitSelf:GetPosition()
    --How much we add to the attack range determines how far from 
    local unitSelfAARange = unitSelf:GetAttackRange() + 100
    local closestTower = core.GetClosestEnemyTower(unitSelf:GetPosition(), 100000)
    
    local selfDistanceToTower = Vector3.Distance2DSq(unitSelfPos, closestTower:GetPosition())
    
    if selfDistanceToTower < 490000 then
        return 1 -- Don't attack when within tower range to avoid getting targeted
    end
    
    local enemyHeroes = core.localUnits["EnemyHeroes"]
    
    
    if enemyHeroes ~= nil then
        local lowestHealth = 1000000
        for _, enemy in pairs(enemyHeroes) do
            local distanceSq = Vector3.Distance2DSq(unitSelfPos, enemy:GetPosition())
            
            if distanceSq < (unitSelfAARange * unitSelfAARange) then
                local enemyHealth = enemy:GetHealth()
                --is in AA range, let's attack the one with least health
                if enemyHealth < lowestHealth then
                    lowestHealth = enemyHealth
                    heroTarget = enemy
                    return 30
                end
            end
        end
    end
    
    return 0

end

local function AutoAttackHarrassExecute(botBrain)
    core.OrderAttackClamp(botBrain, core.unitSelf, heroTarget)
end

local AutoAttackHarrassBehavior = {}
AutoAttackHarrassBehavior["Utility"] = AutoAttackHarrassUtility
AutoAttackHarrassBehavior["Execute"] = AutoAttackHarrassExecute
AutoAttackHarrassBehavior["Name"] = "AutoAttackHarrass"
tinsert(behaviorLib.tBehaviors, AutoAttackHarrassBehavior)























