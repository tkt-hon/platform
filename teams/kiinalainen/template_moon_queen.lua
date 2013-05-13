local _G = getfenv(0)
local moonqueen = _G.object
local object = _G.object

moonqueen.heroName = "Hero_Krixi"

runfile 'bots/core_herobot.lua'

-- TODO
runfile "bots/teams/kiinalainen/helpers.lua" 

-- Shoppailu ja itemHandler funktionaalisuus. ( local itemBottle = itemHandler:GetItem("Item_Bottle") etc)
runfile "bots/teams/kiinalainen/advancedShopping.lua" 

-- Bottlen käyttö
runfile "bots/teams/kiinalainen/bottle.lua" 

-- Tämä on runeja hakeva botti
runfile 'bots/lib/rune_controlling/init.lua'

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills
local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog

local itemHandler = object.itemHandler
local shopping = object.shoppingHandler

behaviorLib.StartingItems = { "Item_Bottle" }
behaviorLib.LaneItems = { "Item_EnhancedMarchers", "Item_HungrySpirit", "Item_WhisperingHelm" }
behaviorLib.MidItems = { "Item_ManaBurn2", "Item_Evasion", "Item_Immunity", "Item_Stealth" }
behaviorLib.LateItems = { "Item_LifeSteal4", "Item_Sasuke" }

--setup Shopping-Behavior
--shopping.Setup(bReserveItems, bSkipLaneWaiting, bCourierCare, bBuyConsumables, tConsumableOptions)
shopping.Setup(false, false, true, false)
-- bCourierCare määrää henkilön joka ostaa kuriirin ja upgradeaa sen. bReserveItems aiheuttaa erroreita atm..
-- http://forums.heroesofnewerth.com/showthread.php?491921-Advanced-Shopping-Library&p=15699232&viewfull=1#post15699232

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function moonqueen:SkillBuildOverride()
  moonqueen:SkillBuildOld()
end
moonqueen.SkillBuildOld = moonqueen.SkillBuild
moonqueen.SkillBuild = moonqueen.SkillBuildOverride

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
function moonqueen:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
-- override combat event trigger function.
moonqueen.oncombateventOld = moonqueen.oncombatevent
moonqueen.oncombatevent = moonqueen.oncombateventOverride

