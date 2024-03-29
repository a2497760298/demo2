--[[
    MsgManger.lua
    消息管理器
    描述：管理所有网络消息的发送
    编写：周星宇
    修订：李昊
    检查：张昊煜
]]
local MsgManager = {}
local TCP = require("app.network.TCP")
local EventManager = require("app.manager.EventManager")
local EventDef = require("app.def.EventDef")
local MsgDef = require("app.def.MsgDef")
local PlayerData = require("app.data.PlayerData")


--[[
    从服务器和本地文件读取完善玩家信息

    @param none

    @return none
]]
function MsgManager:recPlayerData()

    TCP.send(MsgDef.REQ_TYPE.SEND_PLAYER_DATA, {pid=PlayerData:getId(), nick=PlayerData:getName()}, MsgDef.ACK_TYPE.SYNC_SUCCEED, function(resp)
        -- 加载基本信息
        print(varDump(resp))
        PlayerData:setName(resp.data.nick)
        PlayerData:setPassword(resp.data.pwd)
        PlayerData:setId(resp.data.pid)
        PlayerData:setIntegral(resp.data.integral)
        PlayerData:setHeadPortrait(resp.data.headPortrait)
        PlayerData:setGold(resp.data.gold)
        PlayerData:setDiamond(resp.data.diamond)

        -- 加载天梯奖励
        for i = 1, 10 do --初始化天梯奖励
            local index = string.format("%d", i)
            PlayerData:getLadderAward()[i] = resp.data.ladderAward[index]
        end

        -- 加载卡组信息
        local cardGroup = resp.data.cardGroup
        for i = 1, 20 do
            local index = string.format("%d", i)
            PlayerData:getCardGroup()[i]:setNum(cardGroup[index].pieceNum)
            PlayerData:getCardGroup()[i]:setLevel(cardGroup[index].level)
            PlayerData:getCardGroup()[i]:setIntensify(cardGroup[index.intensify])
        end

        -- 加载当前卡组信息
        PlayerData:setFightCardGroupIndex(resp.data.fightGroupIndex)

        local currentGroupOne = resp.data.currentGroupOne
        local currentGroupTwo = resp.data.currentGroupTwo
        local currentGroupThree = resp.data.currentGroupThree
        for i = 1, 5 do
            local index = string.format("%d", i)
            PlayerData:getCurrentCardGroup(1)[i] = PlayerData:getCardGroup()[currentGroupOne[index]]
            PlayerData:getCurrentCardGroup(2)[i] = PlayerData:getCardGroup()[currentGroupTwo[index]]
            PlayerData:getCurrentCardGroup(3)[i] = PlayerData:getCardGroup()[currentGroupThree[index]]
        end

        EventManager:doEvent(EventDef.ID.INIT_PLAYER_DATA)

    end)
end


--[[
    向服务器发送玩家信息

    @param none

    @return none
]]
function MsgManager:sendPlayerData()

    TCP.send(MsgDef.REQ_TYPE.REC_PLAYER_DATA, {
        pid=PlayerData:getId(),
        nick=PlayerData:getName(),
        pwd=PlayerData:getPassword(),
        integral=PlayerData:getIntegral(),
        headPortrait=PlayerData:getHeadPortrait(),
        gold=PlayerData:getGold(),
        diamond=PlayerData:getDiamond(),
        fightGroupIndex=PlayerData:getFightCardGroupIndex(),
        ladderAward=PlayerData:transLadderAward(),
        cardGroup=PlayerData:transCardGroup(),
        currentGroupOne=PlayerData:transCurrentGroupOne(),
        currentGroupTwo=PlayerData:transCurrentGroupTwo(),
        currentGroupThree=PlayerData:transCurrentGroupThree(),
    }, MsgDef.ACK_TYPE.SYNC_SUCCEED, function(resp)
        print(resp)
    end)
end

--[[
    向服务器发送开赛信息

    @param none

    @return none
]]
function MsgManager:startMapping()

    local fightGroup = PlayerData:getFightCardGroup()
    local cards = {}

    for i = 1, 5 do
        cards[string.format("%d", i)] = {
            -- 卡牌Id
            cardId=fightGroup[1]:getId(),
            -- 该等级下攻击力
            atk=fightGroup[1]:getCurAtk(),
            -- 该等级下攻击间隔
            fireCd=fightGroup[1]:getCurFireCd(),
            -- 该等级下一技能参数
            skillOne=fightGroup[1]:getCurSkillOneValue(),
            -- 二技能参数
            skillTwo=fightGroup[1]:getSkillTwoValue(),
            -- 强化一级提升的攻击力增量
            atkDelta=fightGroup[1]:getAtkEnhancedDelta(),
            --强化一级提升的一技能参数增量
            skillOneDelta=fightGroup[1]:getSkillOneEnhancedDelta(),
        }
    end

    TCP.send(MsgDef.REQ_TYPE.START_MAPPING, {
        pid=PlayerData:getId(), -- 用户ID
        nick=PlayerData:getName(), -- 用户名
        integral=PlayerData:getIntegral(), -- 奖杯数
        cards=cards
    }, MsgDef.ACK_TYPE.MAPPING_SUCCEED, function(resp)
        EventManager:doEvent(EventDef.ID.MAPPING_SUCCEED) -- 匹配成功
    end)
end

--[[
    向服务器发送取消开赛的信息

    @param none

    @return none
]]
function MsgManager:endMapping()
    TCP.send(MsgDef.REQ_TYPE.END_MAPPING, {})
end

--[[
    玩家登录

    @param nick 昵称 string
    @param pwd 密码 string

    @return none
]]
function MsgManager:login(nick, pwd)

    TCP.regListener(MsgDef.ACK_TYPE.LOGIN_SUCCEED, function(resp)
        EventManager:doEvent(EventDef.ID.LOGIN_SUCCEED, resp) -- 登录成功
    end)
    TCP.regListener(MsgDef.ACK_TYPE.LOGIN_FAIL, function()
        EventManager:doEvent(EventDef.ID.LOGIN_FAIL) -- 登录失败
    end)
    TCP.send(MsgDef.REQ_TYPE.LOGIN, {nick=nick, pwd=pwd})

end

--[[
    玩家注册

    @param nick 昵称 string
    @param pwd 密码 string

    @return none
]]
function MsgManager:register(nick, pwd)

    TCP.regListener(MsgDef.ACK_TYPE.REGISTER_SUCCEED, function(resp)
        EventManager:doEvent(EventDef.ID.REGISTER_SUCCEED, resp) -- 注册成功
    end)
    TCP.regListener(MsgDef.ACK_TYPE.REGISTER_FAIL, function()
        EventManager:doEvent(EventDef.ID.REGISTER_FAIL) -- 注册失败
    end)
    TCP.send(MsgDef.REQ_TYPE.REGISTER, {nick=nick, pwd=pwd})

end

return MsgManager