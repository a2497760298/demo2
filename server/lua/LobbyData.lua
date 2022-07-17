--[[
    LobbyData.lua
    大厅数据
    描述：大厅数据
    编写：周星宇
    修订：李昊
    检查：张昊煜
]]

local Queue = require("lua.Queue")

local LobbyData = {}


LobbyData.mappingQueue = Queue:new(2) -- 匹配队列

return LobbyData