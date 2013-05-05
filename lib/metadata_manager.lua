local _G = getfenv(0)
local object = _G.object

local metadata = object.metadata

local M = {}

local layerCache = {}

local function ReturnDefaultData()
  local defaultFile = "/bots/test.botmetadata"
  BotMetaData.RegisterLayer(defaultFile)
  BotMetaData.SetActiveLayer(defaultFile)
end

local function GetActiveNodes()
  local nodes = {}
  for x=0, 15800, 200 do
    for y=0, 15800, 200 do
      local node = BotMetaData.GetClosestNode(Vector3.Create(x,y))
      nodes[node] = node
    end
  end
  return nodes
end

local function CreateMapData(path)
  local data = {}
  BotMetaData.RegisterLayer(path)
  BotMetaData.SetActiveLayer(path)
  data.nodes = GetActiveNodes()

  data.GetNodes = function(self)
    return self.nodes
  end
  data.QueryNodes = function(self, matcher)
    local nodes = {}
    for _, node in pairs(self:GetNodes()) do
      if matcher(node) then
        nodes[node] = node
      end
    end
    return nodes
  end
  data.QueryNode = function(self, matcher)
    for _, node in pairs(self:GetNodes()) do
      if matcher(node) then
        return node
      end
    end
  end
  data.FindByName = function(self, name)
    return self:QueryNode(function(node)
      return node:GetName() == name
    end)
  end
  data.FindAllByProperty = function(self, property, value)
    return self:QueryNodes(function(node)
      return node:GetProperty(property) == value
    end)
  end

  layerCache[path] = data
  ReturnDefaultData()
  return data
end

local function GetMapData(path)
  return layerCache[path] or CreateMapData(path)
end
M.GetMapData = GetMapData

metadata.manager = M
