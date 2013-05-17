local _G = getfenv(0)
local object = _G.object

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills
local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
    = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, asin, min, max, random
    = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.asin, _G.math.min, _G.math.max, _G.math.random

local Clamp = core.Clamp

BotEcho("Loading bottle logic...")

------------------------------------
--          Bottle Logic          --
------------------------------------

local itemHandler = object.itemHandler

local function HarassHeroExecuteOverride(botBrain)
    local unitSelf = core.unitSelf
    local unitTarget = behaviorLib.heroTarget
    if unitTarget == nil then
        return object.harassExecuteOldBottle(botBrain) --Target is invalid, move on to the next behavior
    end

    -- Bottle
    if not bActionTaken then
        local itemBottle = itemHandler:GetItem("Item_Bottle")
        if itemBottle then
            -- Use if the bot has an offensive rune bottled
            if useBottlePowerup(itemBottle, nTargetDistanceSq) then
                bActionTaken = core.OrderItemClamp(botBrain, unitSelf, itemBottle)
            elseif getBottleCharges(itemBottle) > 0 and not unitSelf:HasState("State_Bottle") then
                -- Use if we need mana and it is safe to drink
                local nCurTimeMS = HoN.GetGameTime()
                if unitSelf:GetManaPercent() < .2 and (not (eventsLib.recentDotTime > nCurTimeMS) or not (#eventsLib.incomingProjectiles["all"] > 0)) then
                    bActionTaken = core.OrderItemClamp(botBrain, unitSelf, itemBottle)
                end
            end
        end
    end
    if not bActionTaken then
        behaviorLib.harassExecuteOldBottle()
    end
end
behaviorLib.harassExecuteOldBottle = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

 
-- Returns whether or not to use the powerup
local function useBottlePowerup(itemBottle, nDistanceTargetSq)
    local sPowerup = itemBottle:GetActiveModifierKey()
 
    if sPowerup == "bottle_damage" then
        return true
    elseif sPowerup == "bottle_illusion" then
        return true
    elseif sPowerup == "bottle_movespeed" then
        return true
    elseif sPowerup == "bottle_regen" then
        return false
    elseif sPowerup == "bottle_stealth" then
        if nDistanceTargetSq > (700 * 700) then
            return true
        end
    end
     
    return false
end
 
 
-- Returns the number of charges in the bottle
local function getBottleCharges(itemBottle)
    local sModifierKey = itemBottle:GetActiveModifierKey()
 
    if sModifierKey == "bottle_empty" then
        return 0
    elseif sModifierKey == "bottle_1" then
        return 1
    elseif sModifierKey == "bottle_2" then
        return 2
    elseif sModifierKey == "" then
        return 3
    -- Bottle has a rune in it
    else
        return 4
    end
end
 
 
----------------------------------------------
--          UseHealthRegen Overide          --
----------------------------------------------
 
behaviorLib.nBottleUtility = 0
 
-- Modify UseHealthRegen to work with Bottle
local function UseHealthRegenUtilityOveride(botBrain)
    local itemBottle = itemHandler:GetItem("Item_Bottle")
    if itemBottle then
        if getBottleCharges(itemBottle) > 0 then
            local unitSelf = core.unitSelf
            local nHealthMissing = unitSelf:GetMaxHealth() - unitSelf:GetHealth()
         
            local nHealAmount = 135
            local nUtilityThreshold = 20
             
            local vecPoint = Vector3.Create(nHealAmount, nUtilityThreshold)
            local vecOrigin = Vector3.Create(100, -15)
            behaviorLib.nBottleUtility = core.ATanFn(nHealthMissing, vecPoint, vecOrigin, 100)
        else
            behaviorLib.nBottleUtility = 0
        end
    end
     
    nUtility = object.UseHealthRegenUtilityOldBottle(botBrain)
     
    nUtility = max(behaviorLib.nBottleUtility, nUtility)
    nUtility = Clamp(nUtility, 0, 100)
     
    return nUtility
end
 
 local function UseHealthRegenExecuteOveride(botBrain)
    local bActionTaken = false
    local unitSelf = core.unitSelf
    local vecSelfPos = unitSelf:GetPosition()
 
    if unitSelf:HasState("State_Bottle") or unitSelf:HasState("State_PowerupRegen") or unitSelf:HasState("State_Fade_Ability4_Stealth") then
        bActionTaken = true
    end
     
    if not bActionTaken then
        if behaviorLib.nBottleUtility > behaviorLib.nBlightsUtility and behaviorLib.nBottleUtility > behaviorLib.nHealthPotUtility then
            core.FindItems()
            local itemBottle = itemHandler:GetItem("Item_Bottle")
            if itemBottle then
                if getBottleCharges(itemBottle) > 0 then
                    --assess local units to see if they are in nRange, retreat until out of nRange * 1.15
                    --also don't use if we are taking DOT damage
                    local threateningUnits = {}
                    local curTimeMS = HoN.GetGameTime()
 
 
                    for id, unit in pairs(core.localUnits["EnemyUnits"]) do
                        local absRange = core.GetAbsoluteAttackRangeToUnit(unit, unitSelf)
                        local nDist = Vector3.Distance2D(vecSelfPos, unit:GetPosition())
                        if nDist < absRange * 1.15 then
                            local unitPair = {}
                            unitPair[1] = unit
                            unitPair[2] = (absRange * 1.15 - nDist)
                            tinsert(threateningUnits, unitPair)
                        end
                    end
 
                    if core.NumberElements(threateningUnits) > 0 or eventsLib.recentDotTime > curTimeMS or #eventsLib.incomingProjectiles["all"] > 0 then
                        --retreat.  determine best "away from threat" vector
                        local awayVec = Vector3.Create()
                        local totalExcessRange = 0
                        for key, unitPair in pairs(threateningUnits) do
                            local unitAwayVec = Vector3.Normalize(vecSelfPos - unitPair[1]:GetPosition())
                            awayVec = awayVec + unitAwayVec * unitPair[2]
                        end
 
 
                        if core.NumberElements(threateningUnits) > 0 then
                            awayVec = Vector3.Normalize(awayVec)
                        end
 
 
                        --average awayVec with "retreat" vector
                        local retreatVec = Vector3.Normalize(behaviorLib.PositionSelfBackUp() - vecSelfPos)
                        local moveVec = Vector3.Normalize(awayVec + retreatVec)
 
 
                        bActionTaken = core.OrderMoveToPosClamp(botBrain, unitSelf, vecSelfPos + moveVec * core.moveVecMultiplier, false)
                    else
                        bActionTaken = core.OrderItemClamp(botBrain, unitSelf, itemBottle)
                    end
                end
            end
        end
    end
     
    if not bActionTaken then
        return object.useHealthRegenExecuteOldBottle(botBrain)
    end
end
object.UseHealthRegenUtilityOldBottle = behaviorLib.UseHealthRegenBehavior["Utility"]
behaviorLib.UseHealthRegenBehavior["Utility"] = UseHealthRegenUtilityOveride
object.useHealthRegenExecuteOldBottle = behaviorLib.UseHealthRegenBehavior["Execute"]
behaviorLib.UseHealthRegenBehavior["Execute"] = UseHealthRegenExecuteOveride

-------------------------------------------------
--          HealAtWellExecute Overide          --
-------------------------------------------------
 
local function HealAtWellOveride(botBrain)
    local bActionTaken = false
    local unitSelf = core.unitSelf
  
    -- Use Bottle at well
     if not bActionTaken then
        local itemBottle = itemHandler:GetItem("Item_Bottle")
        if itemBottle then
            if not unitSelf:HasState("State_Bottle") then
                if getBottleCharges(itemBottle) > 0 then
                    local unitAllyWell = core.allyWell
                    if unitAllyWell then
                        local nWellDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitAllyWell:GetPosition())
                        if nWellDistanceSq < (400 * 400) then
                            bActionTaken = core.OrderItemClamp(botBrain, unitSelf, itemBottle)
                        end
                    end
                end
            end
        end
    end
  
    if not bActionTaken then
        return object.HealAtWellBehaviorOldBottle(botBrain)
    end
end
object.HealAtWellBehaviorOldBottle = behaviorLib.HealAtWellBehavior["Execute"]
behaviorLib.HealAtWellBehavior["Execute"] = HealAtWellOveride

BotEcho("Loaded.")
