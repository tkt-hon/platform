local _G = getfenv(0)
local object = _G.object

object.behaviorLib = object.behaviorLib or {}
local core, eventsLib, behaviorLib, metadata = object.core, object.eventsLib, object.behaviorLib, object.metadata

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
	= _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
	= _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local nSqrtTwo = math.sqrt(2)

behaviorLib.currentBehavior = nil
behaviorLib.lastBeahavior = nil

behaviorLib.tBehaviors = {}
behaviorLib.nNextBehaviorTime = HoN.GetGameTime()
behaviorLib.nBehaviorAssessInterval = 250

local BotEcho, VerboseLog, Clamp = core.BotEcho, core.VerboseLog, core.Clamp



---------------------------------------------------
--             Common Complex Logic              --
---------------------------------------------------

----------------------------------
--	PositionSelfLogic
----------------------------------
behaviorLib.nHeroInfluencePercent = 0.75
behaviorLib.nPositionHeroInfluenceMul = 4.0
behaviorLib.nCreepPushbackMul = 1
behaviorLib.nTargetPositioningMul = 1
behaviorLib.nTargetCriticalPositioningMul = 2

behaviorLib.nLastPositionTime = 0
behaviorLib.vecLastDesiredPosition = Vector3.Create()
behaviorLib.nPositionSelfAllySeparation = 250
behaviorLib.nAllyInfluenceMul = 1.5

behaviorLib.diveThreshold = 150
