-------------------------------------------------------------------
-------------------------------------------------------------------
--   ____     __               ___    ____             __        --
--  /\  _`\  /\ \             /\_ \  /\  _`\          /\ \__     --
--  \ \,\L\_\\ \ \/'\       __\//\ \ \ \ \L\ \    ___ \ \ ,_\    --
--   \/_\__ \ \ \ , <     /'__`\\ \ \ \ \  _ <'  / __`\\ \ \/    --
--     /\ \L\ \\ \ \\`\  /\  __/ \_\ \_\ \ \L\ \/\ \L\ \\ \ \_   --
--     \ `\____\\ \_\ \_\\ \____\/\____\\ \____/\ \____/ \ \__\  --
--      \/_____/ \/_/\/_/ \/____/\/____/ \/___/  \/___/   \/__/  --
-------------------------------------------------------------------
-------------------------------------------------------------------
-- Skelbot v0.0000008
-- This bot represent the BARE minimum required for HoN to spawn a bot
-- and contains some very basic overrides you can fill in
--

--####################################################################
--####################################################################
--#                                                                 ##
--#                       Bot Initiation                            ##
--#                                                                 ##
--####################################################################
--####################################################################

local _G = getfenv(0)
local object = _G.object

object.myName = object:GetName()

object.bRunLogic         = true
object.bRunBehaviors    = true
object.bUpdates         = true
object.bUseShop         = true

object.bRunCommands     = true 
object.bMoveCommands     = true
object.bAttackCommands     = true
object.bAbilityCommands = true
object.bOtherCommands     = true

object.bReportBehavior = true
object.bDebugUtility = true

object.logger = {}
object.logger.bWriteLog = false
object.logger.bVerboseLog = false

object.core         = {}
object.eventsLib     = {}
object.metadata     = {}
object.behaviorLib     = {}
object.skills         = {}

runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventsLib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorLib.lua"

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
    = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
    = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp


BotEcho(object:GetName()..' loading pyromancer_main...')




--####################################################################
--####################################################################
--#                                                                 ##
--#                  bot constant definitions                       ##
--#                                                                 ##
--####################################################################
--####################################################################

-- hero_<hero>  to reference the internal hon name of a hero, Hero_Yogi ==wildsoul
object.heroName = 'Hero_Pyromancer'


--   item buy order. internal names  
behaviorLib.StartingItems  = {"Item_MinorTotem", "Item_MinorTotem", "Item_MinorTotem", "Item_MinorTotem", "Item_HealthPotion", "Item_HealthPotion", "Item_PretendersCrown"}
behaviorLib.LaneItems  = {"Item_Marchers", "Item_Replenish", "Item_Steamboots", }
behaviorLib.MidItems  = {"Item_Protect", "Item_Nuke"}
behaviorLib.LateItems  = {"Item_Silence"}


-- skillbuild table, 0=q, 1=w, 2=e, 3=r, 4=attri
object.tSkills = {
    1, 0, 0, 1, 0,
    3, 0, 1, 1, 2, 
    3, 2, 2, 2, 4,
    3, 4, 4, 4, 4,
    4, 4, 4, 4, 4,
}

-- These are bonus agression points if a skill/item is available for use
object.nPhoenixUp = 100
object.nDragonUp = 100
object.nBlazingUp = 100


-- These are bonus agression points that are applied to the bot upon successfully using a skill/item
object.nPhoenixUse = 100
object.nDragonUse = 100
object.nBlazingUse = 100



--These are thresholds of aggression the bot must reach to use these abilities
object.nPhoenixThreshold = 1
object.nDragonThreshold = 1
object.nBlazingThreshold = 1

local function AbilitiesUpUtility(hero)
	local bDebugLines = false
	local bDebugEchos = false

	local nUtility = 0

	if skills.abilDragon:CanActivate() then
		nUtility = nUtility + object.nDragonUp
	end

	if skills.abilPhoenix:CanActivate() then
		nUtility = nUtility + object.nPhoenixUp
	end

	if skills.abilBlazing:CanActivate() then
		nUtility = nUtility + object.nBlazingUp
	end

	if bDebugEchos then BotEcho(" HARASS - abilitiesUp: "..nUtility) end
	if bDebugLines then
		local lineLen = 150
		local myPos = core.unitSelf:GetPosition()
		local vTowards = Vector3.Normalize(hero:GetPosition() - myPos)
		local vOrtho = Vector3.Create(-vTowards.y, vTowards.x) --quick 90 rotate z
		core.DrawDebugArrow(myPos - vOrtho * lineLen * 1.4, (myPos - vOrtho * lineLen * 1.4 ) + vTowards * nUtility * (lineLen/100), 'cyan')
	end

	return nUtility
end






--####################################################################
--####################################################################
--#                                                                 ##
--#   bot function overrides                                        ##
--#                                                                 ##
--####################################################################
--####################################################################

------------------------------
--     skills               --
------------------------------
-- @param: none
-- @return: none
function object:SkillBuild()
    core.VerboseLog("skillbuild()")

-- takes care at load/reload, <name_#> to be replaced by some convinient name.
    local unitSelf = self.core.unitSelf
    if  skills.abilQ == nil then
        skills.abilQ = unitSelf:GetAbility(0)
        skills.abilW = unitSelf:GetAbility(1)
        skills.abilE = unitSelf:GetAbility(2)
        skills.abilR = unitSelf:GetAbility(3)
        skills.abilAttributeBoost = unitSelf:GetAbility(4)
    end
    if unitSelf:GetAbilityPointsAvailable() <= 0 then
        return
    end
    
   
    local nlev = unitSelf:GetLevel()
    local nlevpts = unitSelf:GetAbilityPointsAvailable()
    for i = nlev, nlev+nlevpts do
        unitSelf:GetAbility( object.tSkills[i] ):LevelUp()
    end
end

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function object:onthinkOverride(tGameVariables)
    self:onthinkOld(tGameVariables)


    -- custom code here

		if core.unitSelf:GetManaPercent() < 90 then
		core.FindItems(self)	
		local itemRing = core.itemRing
		if itemRing and itemRing:CanActivate() then
			object.bRunCommands = true
			core.OrderItemClamp(self, unitSelf, itemRing)
		end
	end

	core.nRange = 99999 * 99999

end
object.onthinkOld = object.onthink
object.onthink 	= object.onthinkOverride




----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none

object.nDragonUseTime = 0
function object:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)

	if core.unitSelf:GetLevel() < 3 then
		core.nHarassBonus = 0

	elseif IsTowerThreateningUnit(core.unitSelf) then
		core.nHarrasBonus = 0

	elseif core.unitSelf:GetLevel() < 6 and core.unitSelf:GetLevel() >= 3 then
		core.nHarassBonus = 40

	elseif core.unitSelf:GetMana() < 240 then
		core.nHarrasBonus = 10

	elseif core.unitSelf:GetLevel() > 11 then
		core.nHarrasBonus = 100		
	else 
		core.nHarassBonus = 100
	end

local function GetWaveTarget(botBrain, myPos, radius)
  local vihu = core.AssessLocalUnits(botBrain, myPos, radius).EnemyCreeps
  local target = nil

  for key,unit in pairs(vihu) do
    if unit ~= nil then
      target = unit
    end
  end

  if not target then
    return nil
  end
  return target
end

local function CanSeeEnemyHero(botBrain, myPos, radius)
  local vihu = core.AssessLocalUnits(botBrain, myPos, radius).EnemyHeroes
  local target = nil

  for key,unit in pairs(vihu) do
    if unit ~= nil then
      target = unit
    end
  end

  if not target then
    return nil
  end
  return target
end


local function WaveBehaviorUtility(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilWave = unitSelf:GetAbility(0)
  local myPos = unitSelf:GetPosition()
  local vihu = GetWaveTarget(botBrain, myPos, abilWave:GetRange())
  core.FindItems(botBrain)	
	local itemRing = core.itemRing
  if not vihu then
    return 0
  end
  if abilWave:CanActivate() and vihu:GetHealth() < 180 and abilWave:GetLevel() > 2 and unitSelf:GetMana() > 400 then
    return 100
  end
	if CanSeeEnemyHero(botBrain, myPos, radius) == nil and abilWave:CanActivate() and abilWave:GetLevel() > 2 and itemRing ~= nil and unitSelf:GetMana() > 400 then
		return 100
	end
  return 0
end

local function WaveBehaviorExecute(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilWave = unitSelf:GetAbility(0)
  local target = GetWaveTarget(botBrain, myPos, radius)
  if target ~= nil then
    return core.OrderAbilityEntity(botBrain, abilWave, target, false)
  end
  return false
end

local WaveBehavior = {}
WaveBehavior["Utility"] = WaveBehaviorUtility
WaveBehavior["Execute"] = WaveBehaviorExecute
WaveBehavior["Name"] = "Using ultimate properly"
tinsert(behaviorLib.tBehaviors, WaveBehavior)

local function ManaRingBehaviorUtility(botBrain)
  local unitSelf = botBrain.core.unitSelf
  core.FindItems(botBrain)
	local util = 0	
	local itemRing = core.itemRing

 	if botBrain.bDebugUtility == true and utility ~= 0 then
     core.BotEcho("  ManaRingBehaviorUtility: " .. tostring(util))
  end
  if itemRing and itemRing:CanActivate() and unitSelf:GetManaPercent() < 0.9 then
    util = 50
  end
  	return util
end

local function ManaRingExecute(botBrain)
  local unitSelf = botBrain.core.unitSelf
	core.FindItems(botBrain)	
	local itemRing = core.itemRing
		object.bRunCommands = true
		return core.OrderItemClamp(botBrain, unitSelf, itemRing)
end

local ManaRingBehavior = {}
ManaRingBehavior["Utility"] = ManaRingBehaviorUtility
ManaRingBehavior["Execute"] = ManaRingExecute
ManaRingBehavior["Name"] = "ManaRing"
tinsert(behaviorLib.tBehaviors, ManaRingBehavior)

end

object.PussyUtilityOld = behaviorLib.RetreatFromThreatBehavior["Utility"]
local function PussyUtilityOverride(BotBrain)
  local util = object.PussyUtilityOld(BotBrain)
  return math.min(util*0.5,21)
end
behaviorLib.RetreatFromThreatBehavior["Utility"] = PussyUtilityOverride

object.oncombateventOld = object.oncombatevent
object.oncombatevent 	= object.oncombateventOverride



------------------------------------------------------
--            customharassutility override          --
-- change utility according to usable spells here   --
------------------------------------------------------
-- @param: iunitentity hero
-- @return: number
local function CustomHarassUtilityFnOverride(hero)
    local nUtil = -20
    
	if hero:IsStunned() then 
		nUtil = nUtil + 100
	end

	if hero:GetHealth() < 450 and core.unitSelf:GetLevel() > 4 then
		nUtil = nUtil + 100
	end

	if core.unitSelf:GetLevel() > 11 then
		nUtil = nUtil + 100
	end

    if skills.abilQ:CanActivate() then
        nUtil = nUtil + object.nPhoenixUp
    end

    if skills.abilW:CanActivate() then
        nUtil = nUtil + object.nDragonUp
    end

    if skills.abilR:CanActivate() then
        nUtil = nUtil + object.nStrikeUp
    end

    return nUtil
end
-- assisgn custom Harrass function to the behaviourLib object
behaviorLib.CustomHarassUtilityFn = CustomHarassUtilityFnOverride   


	function IsTowerThreateningUnit(unit)
	vecPosition = unit:GetPosition()
	--TODO: switch to just iterate through the enemy towers instead of calling GetUnitsInRadius

	local nTowerRange = 821.6 --700 + (86 * sqrtTwo)
	nTowerRange = nTowerRange
	local tBuildings = HoN.GetUnitsInRadius(vecPosition, nTowerRange, core.UNIT_MASK_ALIVE + core.UNIT_MASK_BUILDING)
	for key, unitBuilding in pairs(tBuildings) do
		if unitBuilding:IsTower() and unitBuilding:GetCanAttack() and (unitBuilding:GetTeam()==unit:GetTeam())==false then
			return true
		end
	end

	return false
end

--------------------------------------------------------------
--                    Harass Behavior                       --
-- All code how to use abilities against enemies goes here  --
--------------------------------------------------------------
-- @param botBrain: CBotBrain
-- @return: none
--

object.nDragonRangeBuffer = -100

local function HarassHeroExecuteOverride(botBrain)
    
	BotEcho("VITTUUU")

    local unitTarget = behaviorLib.heroTarget
    if unitTarget == nil then
        return object.harassExecuteOld(botBrain) --Target is invalid, move on to the next behavior
    end
    
    
    local unitSelf = core.unitSelf
    local vecMyPosition = unitSelf:GetPosition() 
    local nAttackRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)
    local nMyExtraRange = core.GetExtraRange(unitSelf)
    

	local vektori = unitSelf:GetPosition() - unitTarget:GetPosition()
	local normalisoitu = Vector3.Normalize(vektori)
	local kerrottu =  normalisoitu * 80

	local stunnivektori = kerrottu + unitTarget:GetPosition()
    local vecTargetPosition = unitTarget:GetPosition()
    local nTargetExtraRange = core.GetExtraRange(unitTarget)
    local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition)
    
    local nLastHarassUtility = behaviorLib.lastHarassUtil
    local bCanSee = core.CanSeeUnit(botBrain, unitTarget)    
    local bActionTaken = false
    
    HoN.DrawDebugLine(vecMyPosition, stunnivektori, true, "Red")
    --- Insert abilities code here, set bActionTaken to true 
    --- if an ability command has been given successfully

	if core.unitSelf:GetMana() < 100 and unitTarget:GetHealth() > 250 then
		core.nHarassBonus = 0
	end

	if IsTowerThreateningUnit(unitSelf) and core.unitSelf:GetLevel() < 6 then
		core.nHarrasBonus = 0
	end

	if core.CanSeeUnit(botBrain, unitTarget) then
		if bDebugEchos then BotEcho("  No action yet, checking dragon") end
		local abilDragon = skills.abilW
		if abilDragon:CanActivate() and (unitTarget:GetHealth() > 50) then
			local nRange = abilDragon:GetRange()
			if nTargetDistanceSq < (nRange * nRange) then
				--calculate a target since our range doesn't match the ability effective range
				local vecToward = Vector3.Normalize(vecTargetPosition)
				bActionTaken = core.OrderAbilityPosition(botBrain, abilDragon, stunnivektori)
			end
		end
	end


	if not bActionTaken then
		if bDebugEchos then BotEcho("  No action yet, checking phoenix") end
		local abilPhoenix = skills.abilQ
		if abilPhoenix:CanActivate() then
			local nRange = abilPhoenix:GetRange()
			if nTargetDistanceSq < (nRange * nRange) then
				--calculate a target since our range doesn't match the ability effective range
				local vecToward = Vector3.Normalize(vecTargetPosition)
				local vecAbilityTarget = vecTargetPosition
				bActionTaken = core.OrderAbilityPosition(botBrain, abilPhoenix, vecAbilityTarget)
			end
		end
	end


	if not bActionTaken and unitTarget:GetHealth() > 200 then
		if bDebugEchos then BotEcho("  No action yet, checking blaze") end
		local abilBlaze = skills.abilR
		if abilBlaze:CanActivate() then
			local nRange = abilBlaze:GetRange()
			if nTargetDistanceSq < (nRange *nRange) then
				--calculate a target since our range doesn't match the ability effective range
				bActionTaken = core.OrderAbilityEntity(botBrain, abilBlaze, unitTarget)
			end
		end
	end

	if not bActionTaken then
		local itemCodex = core.itemCodex
		if itemCodex and itemCodex:CanActivate() then
			local nRange = itemCodex:GetRange()
			if nTargetDistanceSq < (nRange * nRange) then
				bActionTaken = core.OrderItemEntityClamp(botBrain, unitSelf, itemCodex, unitTarget)
			end
		end
	end
    
    if not bActionTaken then
        return object.harassExecuteOld(botBrain)
    end 




end
-- overload the behaviour stock function with custom 
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

----------------------------------
--  FindItems Override
----------------------------------
local function funcFindItemsOverride(botBrain)
	local bUpdated = object.FindItemsOld(botBrain)

	if core.itemRing ~= nil and not core.itemRing:IsValid() then
		core.itemRing = nil
	end
	if core.itemCodex ~= nil and not core.itemCodex:IsValid() then
		core.itemCodex = nil
	end

	if bUpdated then
		--only update if we need to
		if core.itemRing and core.itemCodex then
			return
		end

		local inventory = core.unitSelf:GetInventory(true)
		for slot = 1, 12, 1 do
			local curItem = inventory[slot]
			if curItem then
				if core.itemRing == nil and curItem:GetName() == "Item_Replenish" then
					core.itemRing = core.WrapInTable(curItem)
					--Echo("Saving astrolabe")
				elseif core.itemCodex == nil and curItem:GetName() == "Item_Nuke" then
					core.itemCodex = core.WrapInTable(curItem)
				end
			end
		end
	end
end
object.FindItemsOld = core.FindItems
core.FindItems = funcFindItemsOverride






