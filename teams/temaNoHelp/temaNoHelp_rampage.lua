local _G = getfenv(0)
local rampage = _G.object
local stunDuration = 0
local tinsert = _G.table.insert
rampage.heroName = "Hero_Rampage"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = rampage.core, rampage.behaviorLib
behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_HealthPotion", "Item_MinorTotem", "Item_MinorTotem", "Item_MinorTotem", "Item_IronBuckler" }
--Kun 3 health potionia invussa ja rahaa tarpeeksi
--Marchersien jälkee pitäis myydä 1 minori
--Ostetaan ring of teacher
--2x punch daggeria
behaviorLib.LaneItems = { "Item_Marchers", "Item_HealthPotion" }
behaviorLib.MidItems = {}

rampage.bReportBehavior = true
rampage.bDebugUtility = true

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
rampage.skills = {}
local skills = rampage.skills

rampage.tSkills = {
  2, 1, 2, 0, 2,
  3, 2, 1, 0, 1,
  3, 1, 0, 0, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}
function rampage:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilCharge == nil then
    skills.abilCharge = unitSelf:GetAbility(0)
    skills.abilSlow = unitSelf:GetAbility(1)
    skills.abilBash = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)local tinsert = _G.table.insert
  end
  self:SkillBuildOld()
end
rampage.SkillBuildOld = rampage.SkillBuild
rampage.SkillBuild = rampage.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function rampage:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
rampage.onthinkOld = rampage.onthink
rampage.onthink = rampage.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function rampage:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
rampage.oncombateventOld = rampage.oncombatevent
rampage.oncombatevent = rampage.oncombateventOverride

local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0
  local unitTarget = behaviorLib.heroTarget
  local time = HoN.GetMatchTime()
  local creepLane = core.GetFurthestCreepWavePos(core.tMyLane, core.bTraverseForward)
  local myPos = core.unitSelf:GetPosition()
--jos potu käytössä niin ei agroilla
  if core.unitSelf:HasState(core.idefHealthPotion.stateName) then
    core.BotEcho("POTUU")
	return -10000
  end 

--jos tornin rangella ni ei mennä
  if core.GetClosestEnemyTower(hero:GetPosition(), 715) then
    return -10000
  end
  
 -- local unitsNearby = core.AssessLocalUnits(rampage, hero:GetPosition(),500)
--jos ei omia creeppejä 500 rangella, niin ei aggroa
 -- if core.NumberElements(unitsNearby.AllyCreeps) == 0 then
 --   return 0
--  end

  if unitTarget and unitTarget:GetHealth() < 250 and core.unitSelf:GetHealth() > 400 then
    return 100
  end

--timeri päälle kun vihu stunnissa, että voidaan hakata autoattack
  if unitTarget and unitTarget:IsStunned() then
   stunDuration = time
  end

  if time - stunDuration < 1 then
    return 30
  end

-- Jos bash valmis niin aggro
  if skills.abilBash:IsReady() then
    return 70
  end

  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function RetreatFromThreatUtilityOverride(botBrain)

  local selfPosition = core.unitSelf:GetPosition()

  if core.GetClosestEnemyTower(selfPosition, 715) then
    return 10000
  end

  return behaviorLib.RetreatFromThreatUtility(botBrain)
end
behaviorLib.RetreatFromThreatBehavior["Utility"] = RetreatFromThreatUtilityOverride


local function HarassHeroExecuteOverride(botBrain)
  local abilCharge = skills.abilCharge
  local abilUltimate = skills.abilUltimate
  local abilSlow = skills.abilSlow

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return rampage.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
  local nLastHarassUtility = behaviorLib.lastHarassUtil

  local bActionTaken = false
  

  if core.CanSeeUnit(botBrain, unitTarget) then

      if unitTarget and unitTarget:GetHealth() < 250 then
        --charge
        if abilCharge:CanActivate() then
          bActionTaken = core.OrderAbilityEntity(botBrain, abilCharge, unitTarget)
        end
        --slowi
        if abilSlow:CanActivate() then
        local nRange = 300
          if nTargetDistanceSq < (nRange * nRange) then
            return core.OrderAbility(botBrain, abilSlow)
          end
        end

      end
	  --ulti 
      if abilUltimate:CanActivate() and unitTarget:GetHealth() < 400 then
        local nRange = abilUltimate:GetRange()
        if nTargetDistanceSq < (nRange * nRange) then
          bActionTaken = core.OrderAbilityEntity(botBrain, abilUltimate, unitTarget)
		  rampage.ultitime = HoN.GetMatchTime()
		  rampage.ultitarget = unitTarget
        end
      end
  end

  if not bActionTaken then
    return rampage.harassExecuteOld(botBrain)
  end
end
rampage.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

local function UltimateBehaviorUtility(botBrain)
  local unitTarget = rampage.ultitarget
  local time = HoN.GetMatchTime()
  if unitTarget then
	if unitTarget:HasState("State_Rampage_Ability4") and time < rampage.ultitime + 2350 then
	  return 99999
	end 
  end
  return 0
end

local function UltimateBehaviorExecute(botBrain)
  local bActionTaken = core.OrderMoveToPosClamp(botBrain, core.unitSelf, core.GetClosestAllyTower(core.unitSelf:GetPosition(), nMaxDist):GetPosition(), false, false) 
  return bActionTaken
end

local UltimateBehavior = {}
UltimateBehavior["Utility"] = UltimateBehaviorUtility
UltimateBehavior["Execute"] = UltimateBehaviorExecute
UltimateBehavior["Name"] = "MASA DUMSERIS"
tinsert(behaviorLib.tBehaviors, UltimateBehavior)

local function ChargeBehaviorUtility(botBrain)
  local unitSelf = core.unitSelf
  if unitSelf:HasState("State_Rampage_Ability1_Sight") or unitSelf:HasState("State_Rampage_Ability1_Warp") or unitSelf:HasState("State_Rampage_Ability1_Timer") then
    return 99999
  end 
  
  return 0
end

local function ChargeBehaviorExecute(botBrain)
  return true
end

local ChargeBehavior = {}
ChargeBehavior["Utility"] = ChargeBehaviorUtility
ChargeBehavior["Execute"] = ChargeBehaviorExecute
ChargeBehavior["Name"] = "PESSI CHARGETTU"
tinsert(behaviorLib.tBehaviors, ChargeBehavior)

function behaviorLib.HealthPotUtilFn(nHealthMissing)
	--Roughly 20+ when we are down 400 hp 
	--  Fn which crosses 20 at x=400 and 40 at x=650, convex down
	if nHealthMissing > 375 then
	  return 100
	end
	return 0
end


