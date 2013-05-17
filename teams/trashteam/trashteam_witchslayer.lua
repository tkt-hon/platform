local _G = getfenv(0)
local witchslayer = _G.object

witchslayer.heroName = "Hero_WitchSlayer"

runfile 'bots/core_herobot.lua'

local tinsert = _G.table.insert

local core, behaviorLib = witchslayer.core, witchslayer.behaviorLib

runfile 'bots/teams/trashteam/utils/utils.lua'
runfile 'bots/teams/trashteam/utils/attackUtils.lua'
runfile 'bots/lib/rune_controlling/init.lua'

witchslayer.bRunLogic         = true
witchslayer.bRunBehaviors    = true
witchslayer.bUpdates         = true
witchslayer.bUseShop         = true

witchslayer.bRunCommands     = true
witchslayer.bMoveCommands     = true
witchslayer.bAttackCommands     = true
witchslayer.bAbilityCommands = true
witchslayer.bOtherCommands     = true

witchslayer.bReportBehavior = false
witchslayer.bDebugUtility = false

witchslayer.logger = {}
witchslayer.logger.bWriteLog = false
witchslayer.logger.bVerboseLog = false


UNIT = 0x0000001
BUILDING = 0x0000002
HERO = 0x0000004
POWERUP = 0x0000008
GADGET = 0x0000010
ALIVE = 0x0000020
CORPSE = 0x0000040

behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_HealthPotion", "2 Item_MinorTotem", "Item_MarkOfTheNovice", "Item_PretendersCrown" }
behaviorLib.LaneItems = { "Item_Bottle", "Item_Marchers", "Item_HealthPotion", "Item_Glowstone", "Item_EnhancedMarchers" }
behaviorLib.MidItems = { "Item_Protect", "Item_Intelligence7", "Item_Nuke", "Item_Morph", "4 Item_Nuke" }
behaviorLib.LateItems = { "Item_GrimoireOfPower", "Item_PostHaste" }

witchslayer.skills = {}
local skills = witchslayer.skills

core.itemGeoBane = nil
witchslayer.DrainTarget = nil
witchslayer.UltiTarget = nil
witchslayer.comboFinisher = nil

witchslayer.tSkills = {
  0, 2, 0, 1, 0,
  3, 2, 0, 1, 1,
  3, 2, 1, 2, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}

local ultiDmg = {0, 500, 650, 850}
local ultiWithStaff =  {0, 600, 800, 1025}
local nukeDmg = {0, 60, 130, 200, 260}


---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function witchslayer:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilNuke == nil then
    skills.abilNuke = unitSelf:GetAbility(0)
    skills.abilMini = unitSelf:GetAbility(1)
    skills.abilDrain = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
    skills.taunt = unitSelf:GetAbility(8)
  end
  witchslayer:SkillBuildOld()
end
witchslayer.SkillBuildOld = witchslayer.SkillBuild
witchslayer.SkillBuild = witchslayer.SkillBuildOverride


------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function witchslayer:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)
  local unitSelf = self.core.unitSelf
  -- custom code here
end
witchslayer.onthinkOld = witchslayer.onthink
witchslayer.onthink = witchslayer.onthinkOverride

local function GetUltiDmg(core) -- witchslayer specific
  local ulti = skills.abilUltimate
  local ultiLevel = ulti:GetLevel()
  if core.ultiStaff then
    return ultiWithStaff[ultiLevel+1]
  end
  return ultiDmg[ultiLevel+1]
end

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function witchslayer:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
  local nAddBonus = 0
  --witchslayer.eventsLib.printCombatEvent(EventData)
end
witchslayer.oncombateventOld = witchslayer.oncombatevent
witchslayer.oncombatevent = witchslayer.oncombateventOverride
-- override combat event trigger function.
witchslayer.cancelChannel = false
witchslayer.cancelTime = 0

local function DontBreakChannelUtilityOverride(botBrain)
  local utility = 0
  local currentTime = HoN.GetMatchTime()

  if currentTime > botBrain.cancelTime then
    botBrain.cancelChannel = true
    botBrain.cancelTime = 9999999
  end

  if core.unitSelf:IsChanneling() and not botBrain.cancelChannel then
    utility = 100
  else
    botBrain.cancelChannel = false
  end

  if botBrain.bDebugUtility == true and utility ~= 0 then
    core.BotEcho("  DontBreakChannelUtility: ".. tostring(utility))
  end

  return utility
end
witchslayer.DontBreakChannelUtilityOld = behaviorLib.RetreatFromThreatBehavior["Utility"]
behaviorLib.DontBreakChannelBehavior["Utility"] = DontBreakChannelUtilityOverride

-- MAN UP BEHAVIOUR
witchslayer.PussyUtilityOld = behaviorLib.RetreatFromThreatBehavior["Utility"]
local function PussyUtilityOverride(BotBrain)
  local util = witchslayer.PussyUtilityOld(BotBrain)
  return core.Clamp(util, 0, 30) 
end
behaviorLib.RetreatFromThreatBehavior["Utility"] = PussyUtilityOverride

witchslayer.permissionToUseForce = false
witchslayer.PussyHarUtilityOld = behaviorLib.HarassHeroBehavior["Utility"]
local function PussyHarUtilityOverride(BotBrain)
  local util = witchslayer.PussyHarUtilityOld(BotBrain)
  if util < 5 then
    witchslayer.permissionToUseForce = true
  else
    witchslayer.permissionToUseForce = false
  end
  if witchslayer.HarassUtility > 0 then
    if util < witchslayer.HarassUtility then
      util = witchslayer.HarassUtility
    end
    witchslayer.HarassUtility = -5
  end
  return core.Clamp(util, 0, 100) 
end
behaviorLib.HarassHeroBehavior["Utility"] = PussyHarUtilityOverride


local function usefulstuff() -- misc stuff, for reminder of stuff
  local ultiCost = skills.abilUltimate:GetManaCost()
  local nukeCost = skills.abilNuke:GetManaCost()
  local myMana = unitSelf:GetMana()
  nUtil = nUtil * (unitSelf:GetHealthPercent()*0.5 + 0.4)

  local nuke = skills.abilNuke
  local ulti = skills.abilUltimate
  local ultdmg = ultiDmg[ulti:GetLevel()+1]
  local nukedmg = nukeDmg[nuke:GetLevel()+1]
  return
end

witchslayer.HarassUtility = -5
local function CustomHarassUtilityFnOverride(hero)
  local unitSelf = core.unitSelf
  local distToEneTo = closeToEnemyTowerDist(unitSelf)
  local modifier = 0
  if distToEneTo < 750 then
    core.BotEcho("WTF")
    modifier = 50
  end

  local nUtil = 0
  local nTargetDistance = Vector3.Distance2D(unitSelf:GetPosition(), hero:GetPosition())
  local attackRange = unitSelf:GetAttackRange()
  local unitsInRange = AmountOfCreepsInRange(unitSelf, unitSelf:GetPosition(), 400)
  if nTargetDistance < attackRange and unitsInRange < 4 then
    nUtil = nUtil + 50
  end


  if skills.abilNuke:CanActivate() then
    nUtil = nUtil + 7*skills.abilNuke:GetLevel()
  end
  local heroHealth = hero:GetHealth()
  local myHealth = unitSelf:GetHealth()
  local heroPHealth = hero:GetHealthPercent()
  local myPHealth = unitSelf:GetHealthPercent()
  local eHeroPos = hero:GetPosition()
  local myPos = unitSelf:GetPosition()
  local nuke = skills.abilNuke
  local ulti = skills.abilUltimate
  local mini = skills.abilMini
  if myPos.z-eHeroPos.z > 80 then
    nUtil = nUtil + 20
  end
  if eHeroPos.z-myPos.z > 80 then
    nUtil = nUtil - 20
  end
  if heroPHealth > myPHealth and not ulti:CanActivate() then
    nUtil = nUtil * 0.9
  elseif heroPHealth > myPHealth*2 and not ulti:CanActivate()then
    nUtil = nUtil * 0.7
  elseif heroPHealth <= myPHealth and heroPHealth > 0.2 then
    nUtil = nUtil * 1.3
  end
  if heroPHealth < 0.3 and not (nuke:CanActivate() or mini:CanActivate() or ulti:CanActivate()) then
    nUtil = 0
  end
  local nukedmg = nukeDmg[nuke:GetLevel()+1]
  local ultiCost = skills.abilUltimate:GetManaCost()
  local nukeCost = skills.abilNuke:GetManaCost()
  local myMana = unitSelf:GetMana()
  local nuke = skills.abilNuke
  local nukeRange = nuke:GetRange()+800
  local nTargetDistanceSq = Vector3.Distance2D(myPos, eHeroPos)
  if nTargetDistanceSq < nukeRange and nuke:CanActivate() then
    nUtil = nUtil + 20
  end

  if core.CanSeeUnit(witchslayer, hero) then
    local targetMA = GetArmorMultiplier(hero, true)
    if  heroHealth < targetMA*(GetUltiDmg(core)+(nukedmg*1.5)) and myMana > ultiCost + nukeCost and skills.abilUltimate:CanActivate() and skills.abilNuke:CanActivate() then
      nUtil = 70
    end
    if hero:IsStunned() or hero:IsPerplexed() or hero:IsSilenced() then
      nUtil = 70
      modifier = modifier*0.4 -- GO IN!?
    end
  end
  if nUtil < 0 then 
    --core.BotEcho("WTF MAN")
  end
  if unitSelf:GetLevel() < 6 then
    nUtil = nUtil * 0.5
  end
  if AmountOfCreepsInRange(unitSelf, myPos, 300, true) < 1 then
    nUtil = nUtil * 0.6
  end
  local unitsLocal, unitsSorted = HoN.GetUnitsInRadius(unitSelf:GetPosition(), 150, ALIVE + UNIT, true)
  if core.NumberElements(unitsSorted.EnemyCreeps) > 2 and unitSelf:GetLevel() < 12 then
    nUtil = nUtil * 0.4
  end

  if witchslayer.bDebugUtility == true and utility ~= 0 then
     core.BotEcho("  HarassUtility: " .. tostring(nUtil))
  end

  if unitSelf:HasState("State_PowerupDamage") or unitSelf:HasState("State_PowerupMoveSpeed") then
    nUtil = nUtil + 20
  end
  if unitSelf:HasState("State_PowerupStealth") and nUtil < 70 then 
    nUtil = 0
  end
  witchslayer.HarassUtility = core.Clamp(nUtil-modifier, 0, 70)
  return core.Clamp(nUtil-modifier, 0, 100) -- Never be more important than 70
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

witchslayer.stunTime = 0

local function CanUseCC()
  local matchTime = HoN.GetMatchTime()
  if matchTime - witchslayer.stunTime > 500 then
    return true
  end
  return false
end

local function HarassHeroExecuteOverride(botBrain)

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return witchslayer.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2D(unitSelf:GetPosition(), unitTarget:GetPosition())
  local targetDirection = Vector3.Normalize(unitTarget:GetPosition()- unitSelf:GetPosition())*100 + unitSelf:GetPosition()
  --core.DrawDebugArrow(unitSelf:GetPosition(), targetDirection, "silver")
  local nLastHarassUtility = behaviorLib.lastHarassUtil

  local bActionTaken = false

  local nuke = skills.abilNuke
  local ulti = skills.abilUltimate
  local mini = skills.abilMini
  local ultiCost = skills.abilUltimate:GetManaCost()
  local ultiLevel = ulti:GetLevel()
  if ultiLevel == 0 or not ulti:CanActivate() then
    ultiCost = 0
  end
  local nukeCost = skills.abilNuke:GetManaCost()
  local miniCost = mini:GetManaCost()
  local myMana = unitSelf:GetMana()
  local drain = skills.abilDrain
  local ultiLevel = ulti:GetLevel()
  local ultdmg = ultiDmg[ulti:GetLevel()+1]
  local nukedmg = nukeDmg[nuke:GetLevel()+1]
  local speed = botBrain.core.speedBoots
  local taunt = skills.taunt
  if speed and speed:CanActivate() then
    core.OrderItemClamp(botBrain, unitSelf, speed)
  end
  botBrain.currentStunDur = 0

	if core.CanSeeUnit(botBrain, unitTarget) then
    if drain:CanActivate() and (ultiCost-myMana > 0) or (nukeCost-myMana > 0) and (unitTarget:IsStunned()or unitTarget:IsPerplexed()) and ultiLevel > 0 then
      botBrain.cancelTime = HoN.GetMatchTime() + 1000
      local nRange = drain:GetRange()
      if nTargetDistanceSq < nRange then
        bActionTaken = core.OrderAbilityEntity(botBrain, drain, unitTarget)
      end
    end
    if mini:CanActivate() and mini:GetLevel() > 1 and myMana-miniCost > ultiCost and not (unitTarget:IsStunned() or unitTarget:IsPerplexed()) and CanUseCC() then
      local nRange = mini:GetRange()
      if nTargetDistanceSq < nRange then
        botBrain.stunTime = HoN.GetMatchTime()
        bActionTaken = core.OrderAbilityEntity(botBrain, mini, unitTarget)
      end
    end
    if core.itemCodex and core.itemCodex:CanActivate() then
      local nRange = core.itemCodex:GetRange()
      if nTargetDistanceSq < nRange then
        bActionTaken = core.OrderItemEntityClamp(botBrain, unitSelf, core.itemCodex, unitTarget)
      end
    end
    if nuke:CanActivate() and nuke:GetLevel() > 1 and myMana-nukeCost > ultiCost and not (unitTarget:IsStunned() or unitTarget:IsPerplexed()) and CanUseCC() then
      local nRange = nuke:GetRange()
      if nTargetDistanceSq < nRange then
        botBrain.stunTime = HoN.GetMatchTime()
        bActionTaken = core.OrderAbilityEntity(botBrain, nuke, unitTarget)
      elseif nTargetDistanceSq < nRange+150 then
        botBrain.stunTime = HoN.GetMatchTime()
        bActionTaken = core.OrderAbilityPosition(botBrain, nuke, targetDirection)
      end
    end
    if core.sheepStick and core.sheepStick:CanActivate() and not (unitTarget:IsStunned() or unitTarget:IsPerplexed()) and CanUseCC() then
      local nRange = core.sheepStick:GetRange()
      if nTargetDistanceSq < nRange then
        witchslayer.stunTime = HoN.GetMatchTime()
        bActionTaken = core.OrderItemEntityClamp(botBrain, unitSelf, core.sheepStick, unitTarget)
      end
    end
    if botBrain.permissionToUseForce and ulti:CanActivate() then
      local nRange = ulti:GetRange()
      if nTargetDistanceSq < nRange then
        bActionTaken = core.OrderAbilityEntity(botBrain, ulti, unitTarget)
      end
    end
  end

  if not bActionTaken then
    return botBrain.harassExecuteOld(botBrain)
  end
end
witchslayer.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

local function IllusionsAlert(botBrain, target) -- returns true if there are multiple of same targets
  return false
end

local function targetHasNullStone(botBrain, target) -- returns true if target has nullstone
  if target and core.CanSeeUnit(botBrain, target) then
    local inv = target:GetInventory()
    for i=1,#inv,1 do
      local curItem = inv[i]
      if inv[i] then
        if curItem:GetName() == "Item_Protect" then 
          return true
        end
      end
    end
  end
  return false
end

local function targetHasShrunkenActive(target) -- returns true if target has shrunken activated
  return target:HasState("State_Item3E")
end


--- MY BEHAVIOURS ONLY AFTER THIS POINT ---

local function GetManaUtility(botBrain)
  -- use only if no heroes nearby
  --core.BotEcho("ManaUtility calc")
  local unitSelf = botBrain.core.unitSelf
  local drainMana = skills.abilDrain
  local util = 0
  local modifier = 0
  local myPos = unitSelf:GetPosition()
  local _,lol = HoN.GetUnitsInRadius(myPos, 1000, ALIVE + HERO, true)
  local enemyHeros = core.NumberElements(lol.EnemyHeroes)
  if drainMana:CanActivate() and enemyHeros < 1 then
    local myMana = unitSelf:GetMana()
    local ultiCost = skills.abilUltimate:GetManaCost()
    local nukeCost = skills.abilNuke:GetManaCost()
    local miniCost = skills.abilMini:GetManaCost()
    local manaAfterSkills = myMana - ultiCost - nukeCost - miniCost
    if not (manaAfterSkills > 0)  then
      local distToEneTo = closeToEnemyTowerDist(unitSelf)
      if distToEneTo < 850 then
        modifier = 80
      end

      local drainRange = skills.abilDrain:GetRange()
      local allUnitsMax = HoN.GetUnitsInRadius(myPos, drainRange, ALIVE + UNIT)
      local potentialCreep = nil
      for _,unit in pairs(allUnitsMax) do
        if unit and not (botBrain:GetTeam() == unit:GetTeam()) then
          if unit:GetMana() > 200 then
            potentialCreep = unit
          end
        end
      end
      if potentialCreep then
        botBrain.DrainTarget = potentialCreep
        util = 25
      end
    end
  end
  util = util - modifier
  if botBrain.bDebugUtility == true and utility ~= 0 then
     core.BotEcho("  GetManaUtility: " .. tostring(util))
  end
  return util
end

local function GetManaExecute(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local targetCreep = botBrain.DrainTarget
  local manaDrain = skills.abilDrain
  botBrain.cancelTime = HoN.GetMatchTime() + 5000
  return core.OrderAbilityEntity(botBrain, manaDrain, targetCreep)
end

local GetManaBehavior = {}
GetManaBehavior["Utility"] = GetManaUtility
GetManaBehavior["Execute"] = GetManaExecute
GetManaBehavior["Name"] = "DrainMana"
tinsert(behaviorLib.tBehaviors, GetManaBehavior)

local function EiMihinkaanUtility(botBrain)
  --core.BotEcho("ManaUtility calc")
  local unitSelf = botBrain.core.unitSelf
  local ulti = skills.abilUltimate
  local ultiLevel = ulti:GetLevel()
  if ultiLevel < 1 then
    return 0
  end
  local range = ulti:GetRange()
  local util = 0
  local ultdmg = GetUltiDmg(botBrain.core)
  local ownTeam = botBrain:GetTeam()
  local ownMoveSpeed = unitSelf:GetMoveSpeed()
  local myPos = unitSelf:GetPosition()
  if ulti:CanActivate() then
    local unitsInRange = HoN.GetUnitsInRadius(myPos, range+200, ALIVE + HERO)
    for _,unit in pairs(unitsInRange) do
      if unit and not (ownTeam == unit:GetTeam()) and core.CanSeeUnit(botBrain, unit) and not targetHasShrunkenActive(unit) then
        local nTargetDistance = Vector3.Distance2D(myPos, unit:GetPosition())
        local targetArmor = GetArmorMultiplier(unit,true)
        local targetHealth = unit:GetHealth()
        if targetHealth < ultdmg*targetArmor then
          if nTargetDistance < range then
            util = 100
            botBrain.UltiTarget = unit
            break
          elseif nTargetDistance > range and ownMoveSpeed > unit:GetMoveSpeed() then
            util = 100
            botBrain.UltiTarget = unit
          end
        end
      end
    end
  end
  if targetHasNullStone(botBrain, botBrain.UltiTarget) and HoN.GetMatchTime()>botBrain.removedNullValidTill and  not (botBrain.nullDrainTarget == botBrain.UltiTarget)  then
    botBrain.useDrainToRemoveNullstone = true
    botBrain.nullDrainTarget = botBrain.UltiTarget
    return 0
  end
  if targetHasNullStone(botBrain, botBrain.UltiTarget) and HoN.GetMatchTime()<botBrain.removedNullValidTill and  botBrain.nullDrainTarget == botBrain.UltiTarget then 
    if not ulti:canActivate() then
      botBrain.removingNull = false
      botBrain.couldActivateDrain = false
      botBrain.removedNullValidTill = -1
      botBrain.nullDrainTarget = nil
      return 0
    end
    return 100
  end
  if botBrain.comboFinisher then
    util = 100
    botBrain.comboFinisher = false
  end
  if botBrain.bDebugUtility == true and utility ~= 0 then
     core.BotEcho("  EiMihinkäänUtility: " .. tostring(util))
  end
  return util
end

local function EiMihinkaanExecute(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local targetHero = botBrain.UltiTarget
  local ulti = skills.abilUltimate
  local speed = botBrain.core.speedBoots
  core.AllChat("EI MIHINKÄÄN")
  if speed and speed:CanActivate() then
    core.OrderItemClamp(botBrain, unitSelf, speed)
  end
  return core.OrderAbilityEntity(botBrain, ulti, targetHero)
end

local EiMihinkaanBehavior = {}
EiMihinkaanBehavior["Utility"] = EiMihinkaanUtility
EiMihinkaanBehavior["Execute"] = EiMihinkaanExecute
EiMihinkaanBehavior["Name"] = "EiMihinkaan"
tinsert(behaviorLib.tBehaviors, EiMihinkaanBehavior)

witchslayer.removingNull = false
witchslayer.couldActivateDrain = false
witchslayer.removedNullValidTill = -1
local function removeNullUtility(botBrain)
  local drain = skills.abilDrain
  if botBrain.useDrainToRemoveNullstone and botBrain.nullDrainTarget and drain:CanActivate() then
    botBrain.couldActivateDrain = true
    return 100
  elseif botBrain.removingNull and not drain:CanActivate() and botBrain.couldActivateDrain then
    botBrain.removingNull = false
    botBrain.couldActivateDrain = false
    botBrain.useDrainToRemoveNullstone = false
    botBrain.removedNullValidTill = HoN.GetMatchTime() + 20000
    return 0
  end
  return 0
end
local function removeNullExecute(botBrain)
  botBrain.removingNull = true
  local drain = skills.abilDrain
  local target = botBrain.nullDrainTarget
  botBrain.cancelTime = HoN.GetMatchTime() + 100
  return core.OrderAbilityEntity(botBrain, manaDrain, targetCreep)
end
local removeNullBehavior = {}
removeNullBehavior["Utility"] = removeNullUtility
removeNullBehavior["Execute"] = removeNullExecute
removeNullBehavior["Name"] = "removeNull"
tinsert(behaviorLib.tBehaviors, removeNullBehavior)

GANKINTERVAL = 1000*160
witchslayer.nextGankAt = 0
witchslayer.ganking = false
witchslayer.gankTarget = nil
witchslayer.lastGankTarget = nil
witchslayer.gankLocation = nil
witchslayer.GankTimeLimit = -1
local function GankUtility(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local myLevel = unitSelf:GetLevel()
  if myLevel < 5 then
    return 0
  end
  local matchTime = HoN.GetMatchTime()
  if botBrain.ganking and (not skills.abilUltimate:CanActivate() or (matchTime > botBrain.GankTimeLimit and botBrain.GankTimeLimit > 0) or not botBrain.gankTarget:IsValid() or not botBrain.gankTarget:IsAlive()) then
    botBrain.ganking = false
    botBrain.lastGankTarget = botBrain.gankTarget
    botBrain.nextGankAt = matchTime + GANKINTERVAL
    botBrain.GankTimeLimit = -1
    return 0
  elseif botBrain.ganking and skills.abilUltimate:CanActivate() then
    if botBrain.GankTimeLimit < 0 then
      botBrain.GankTimeLimit = matchTime + GANKINTERVAL
    end
    if botBrain.gankTarget and core.CanSeeUnit(botBrain, botBrain.gankTarget) then
      botBrain.gankLocation = botBrain.gankTarget:GetPosition()
    end
    return 55
  end
  --core.BotEcho("wtf lets gank?")
  local tEnemyHeroes = HoN.GetHeroes(core.enemyTeam)
  local util = 0
  local unitTarget = nil
  local nTarget = 0
  if matchTime < botBrain.nextGankAt then
    return 0
  end
  for nUID, unit in pairs(tEnemyHeroes) do
    if unit and core.CanSeeUnit(botBrain, unit) and unit:IsAlive() and myLevel > unit:GetLevel()+1 and skills.abilUltimate:CanActivate() and not (unit == witchslayer.lastGankTarget) then
      unitTarget = unit
      nTarget = nUID

    end
  end
  if unitTarget then
    botBrain.gankLocation = unitTarget:GetPosition()
    botBrain.gankTarget = unitTarget
    botBrain.ganking = true
    util = 55
  end
  botBrain.lastGankTarget = nil
  if botBrain.bDebugUtility == true and utility ~= 0 then
     core.BotEcho("  GankUtility: " .. tostring(util))
  end
  return util
end

local function GankExecute(botBrain)
  botBrain.ganking = true
  local unitSelf = botBrain.core.unitSelf
  local targetHero = botBrain.UltiTarget
  local ulti = skills.abilUltimate
  local targetPos = botBrain.gankLocation
  return core.OrderMoveToPosClamp(botBrain, unitSelf, targetPos)
end

local GankBehavior = {}
GankBehavior["Utility"] = GankUtility
GankBehavior["Execute"] = GankExecute
GankBehavior["Name"] = "GankTime"
tinsert(behaviorLib.tBehaviors, GankBehavior)

DRINKINTERVAL = 3000
witchslayer.canDrink = 0
witchslayer.hpot = false
local function DrinkingUtility(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local matchTime = HoN.GetMatchTime()
  if not core.bottle then 
    return 0
  end
  if botBrain.canDrink > matchTime or unitSelf:HasState("State_PowerupRegen") or unitSelf:HasState("State_PowerupStealth") then
    return 0
  end
  local _, unitsSorted = HoN.GetUnitsInRadius(unitSelf:GetPosition(), 900, ALIVE + HERO, true)
  if core.hpotion and unitSelf:GetHealthPercent() < 0.4 and  core.hpotion:GetCharges() > 0 then
    botBrain.hpot = true
    return 50
  end
  if core.bottle then
    local modifierKey = core.bottle:GetActiveModifierKey()
    if modifierKey == "bottle_stealth" and unitSelf:GetHealthPercent() < 0.30 then
      return 100
    end
    if (modifierKey == "bottle_regen") and unitSelf:GetHealthPercent() < 0.60 and unitSelf:GetManaPercent() < 0.60 and core.NumberElements(unitsSorted.EnemyHeroes) < 1 then
      return 80
    end
    if not (modifierKey == "bottle_empty" or modifierKey == "bottle_regen" or modifierKey == "bottle_stealth") and  (unitSelf:GetHealthPercent() < 0.90 or unitSelf:GetManaPercent() < 0.90) then
      if unitSelf:GetHealthPercent() < 0.4 then
        return 50
      end
      return 30
    end
  end
  return 0
end

local function DrinkingExecute(botBrain)
  if not core.bottle then
    return
  end
  local matchTime = HoN.GetMatchTime()
  local unitSelf = botBrain.core.unitSelf
  local modifierKey = core.bottle:GetActiveModifierKey()
  if botBrain.hpot then 
    botBrain.hpot = false
    botBrain.canDrink = matchTime + 10000
    return core.OrderItemEntityClamp(botBrain, unitSelf, core.hpotion,unitSelf)
  end
  if not ( modifierKey == "bottle_stealth" ) then 
    botBrain.canDrink = matchTime + DRINKINTERVAL
  end
  return core.OrderItemClamp(botBrain, unitSelf, core.bottle)
end

local DrinkingBehavior = {}
DrinkingBehavior["Utility"] = DrinkingUtility
DrinkingBehavior["Execute"] = DrinkingExecute
DrinkingBehavior["Name"] = "Taking a drink"
tinsert(behaviorLib.tBehaviors, DrinkingBehavior)

RUNEINTERVAL = 1000 * 60 * 2
witchslayer.runeCD = 0
local CanPickRuneFn = RuneControlling_Utils_Hero.CanPickRune
local GetRuneLocationFn = RuneControlling_Utils_Hero.GetRuneLocation
local GetRuneEntityFn = RuneControlling_Utils_Hero.GetRuneEntity
local function RuneTakingUtilityOverride(botBrain)
  local teambot = core.teamBotBrain
  local matchTime = HoN.GetMatchTime()
  local unitSelf = botBrain.core.unitSelf
  --core.BotEcho("RuneCD: " .. tostring(botBrain.runeCD) .. ", Matchtime: " .. tostring(matchTime))

  local _, unitsSorted = HoN.GetUnitsInRadius(unitSelf:GetPosition(), 900, ALIVE + HERO, true)
  local heroesAround = core.NumberElements(unitsSorted.EnemyHeroes)
  if botBrain.runeCD < matchTime and (unitSelf:GetHealthPercent() < 0.7 or heroesAround < 1) and CanPickRuneFn(teambot) then
    --core.BotEcho("canPickRune")
    return 30
  end
  return 0
end
witchslayer.RuneTakingUtilityOld = behaviorLib.RuneTakingBehavior["Utility"]
behaviorLib.RuneTakingBehavior["Utility"] = RuneTakingUtilityOverride
local function GetRuneEntity(vecSelf, entities)
  local target = nil
  for _, rune in ipairs(entities) do
    if not target or Vector3.Distance2DSq(vecSelf, rune:GetPosition()) < Vector3.Distance2DSq(vecSelf, target:GetPosition()) then
      target = rune
    end
  end
  return target
end
witchslayer.RuneTakingExecuteOld = behaviorLib.RuneTakingBehavior["Execute"]
local function RuneTakingExecuteOverride(botBrain)
  local matchTime = HoN.GetMatchTime()
  local bActionTaken = false
  local unitPicker = behaviorLib.RuneControlling.GetRunePicker(botBrain)
  local vecPicker = unitPicker:GetPosition()
  local teambot = core.teamBotBrain
  local runeLocation = behaviorLib.RuneControlling.GetRuneLocation(botBrain, GetRuneLocationFn(teambot))
  local nTargetDistanceSq = Vector3.Distance2DSq(vecPicker, runeLocation)

  local nRange = 100
  if nTargetDistanceSq < (nRange * nRange) then
    local runeEntity = GetRuneEntity(vecPicker, GetRuneEntityFn(teambot))
    if runeEntity then
      bActionTaken = behaviorLib.RuneControlling.GetRuneAction(botBrain, unitPicker, runeEntity)

      botBrain.runeCD = matchTime + RUNEINTERVAL
    end
  else
    bActionTaken = core.OrderMoveToPosClamp(botBrain, unitPicker, runeLocation)
  end
  return bActionTaken
end
behaviorLib.RuneTakingBehavior["Execute"] = RuneTakingExecuteOverride

--find items from inventory and puts them in core.xxxx location, check function for more
local function funcFindItemsOverride(botBrain)
  local bUpdated = botBrain.FindItemsOld(botBrain)

  if core.itemRing ~= nil and not core.itemRing:IsValid() then
    core.itemRing = nil
  end
  if core.itemCodex ~= nil and not core.itemCodex:IsValid() then
    core.itemCodex = nil
  end
  if core.sheepStick ~= nil and not core.sheepStick:IsValid() then
    core.sheepStick = nil
  end
  if core.speedBoots ~= nil and not core.speedBoots:IsValid() then
    core.speedBoots = nil
  end
  if core.ultiStaff ~= nil and not core.ultiStaff:IsValid() then
    core.ultiStaff = nil
  end
  if core.bottle ~= nil and not core.bottle:IsValid() then
    core.bottle = nil
  end
  if core.hpotion ~= nil and not core.hpotion:IsValid() then
    core.hpotion = nil
  end

  if bUpdated then
    --only update if we need to
    if core.itemRing and core.itemCodex and core.sheepStick and core.ultiStaff and core.speedBoots and core.bottle and core.hpotion then
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
        elseif core.sheepStick == nil and curItem:GetName() == "Item_Morph" then
          core.sheepStick = core.WrapInTable(curItem)
        elseif core.speedBoots == nil and curItem:GetName() == "Item_EnhancedMarchers" then
          core.speedBoots = core.WrapInTable(curItem)
        elseif core.ultiStaff == nil and curItem:GetName() == "Item_Intelligence7" then
          core.ultiStaff = core.WrapInTable(curItem)
        elseif core.bottle == nil and curItem:GetName() == "Item_Bottle" then
          core.bottle = core.WrapInTable(curItem)
        elseif core.hpotion == nil and curItem:GetName() == "Item_HealthPotion" then
          core.hpotion = core.WrapInTable(curItem)
        end
      end
    end
  end
end
witchslayer.FindItemsOld = core.FindItems
core.FindItems = funcFindItemsOverride

