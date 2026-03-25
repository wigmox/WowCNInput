--------------------------------
-- WowCNInput 事件处理
-- 功能: 处理插件事件、按键绑定和斜杠命令
--------------------------------

-- [模块局部变量]
local welcomeShown = false

-- [目标编辑框列表] 所有可能需要输入中文的编辑框
local TargetBoxes = {
    "ChatFrameEditBox",           -- 聊天框架编辑框
    "MacroFrameText",             -- 宏命令大输入框
    "MacroPopupEditBox",          -- 宏新建起名框
    "GuildInfoEditBox",           -- 公会信息框
    "GuildMOTDEditBox",           -- 公会公告框
    "AddFriendNameEditBox",       -- 好友面板：添加好友
    "AddIgnoreNameEditBox",       -- 好友面板：屏蔽玩家
    "SendMailNameEditBox",        -- 邮件：收件人
    "SendMailSubjectEditBox",     -- 邮件：主题
    "SendMailBodyEditBox",        -- 邮件：正文
    "BrowseName",                 -- 拍卖行搜索
    "ChannelFrameDaughterFrameChannelName",
    "StaticPopup1EditBox",        -- 各种系统弹窗输入框（如公会邀请、改名等）
    "StaticPopup2EditBox",
    "StaticPopup3EditBox",
    "StaticPopup4EditBox",
    "StaticPopup5EditBox"
}

--[[
    Print - 输出调试信息到聊天框
    参数: msg - 要输出的消息字符串
]]
local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ddddWowCNInput:|r "..msg)
end

--[[
    WowCNEvent_ShowWelcomeMessage - 显示欢迎信息
    说明: 显示插件加载成功的提示信息
]]
local function WowCNEvent_ShowWelcomeMessage()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00dddd中文输入插件|r |cff00ff00【已加载】|r！")
    DEFAULT_CHAT_FRAME:AddMessage("适配：聊天、宏、好友、屏蔽、公会等输入框。")
    DEFAULT_CHAT_FRAME:AddMessage("操作：输入自动弹出候选框。空格选第1个字，1-0手动选字。")
    DEFAULT_CHAT_FRAME:AddMessage("翻页：'|cff00ff00,|r' 或 '|cff00ff00-|r' 上一页，'|cff00ff00.|r' 或 '|cff00ff00=|r' 下一页。")
    DEFAULT_CHAT_FRAME:AddMessage("开关：|cff00ff00/wi|r 。设置：|cff00ff00/wi config|r")
end

--[[
    WowCNEvent_InitWelcomeTimer - 初始化欢迎信息计时器
    说明: 创建独立计时器，延迟显示欢迎信息
]]
local function WowCNEvent_InitWelcomeTimer()
    local timer = CreateFrame("Frame")
    timer.elapsed = 0
    timer:SetScript("OnUpdate", function()
        timer.elapsed = timer.elapsed + arg1
        if timer.elapsed > 2 then
            if not welcomeShown then
                welcomeShown = true
                WowCNEvent_ShowWelcomeMessage()
            end
            timer:SetScript("OnUpdate", nil)
        end
    end)
end

--[[
    WowCNEvent_HookAllKnownBoxes - 核心遍历挂载函数
    遍历所有目标编辑框并挂载输入法处理逻辑
]]
function WowCNEvent_HookAllKnownBoxes()
    for i = 1, table.getn(TargetBoxes) do
        local box = getglobal(TargetBoxes[i])
        if box and not WowCNInput_IsHooked(box) then
            WowCNInput_HookEditBox(box)
        end
    end
end

--[[
    WowCNInput_OnLoad - 插件加载入口函数
    注册事件和斜杠命令
]]
function WowCNInput_OnLoad()
    this:RegisterEvent("VARIABLES_LOADED")
    this:RegisterEvent("ADDON_LOADED")
    this:RegisterEvent("MAIL_SHOW")
    this:RegisterEvent("AUCTION_HOUSE_SHOW")
end

--[[
    WowCNInput_Toggle - 切换输入法开关状态
    说明: 供按键绑定和斜杠命令调用
]]
function WowCNInput_Toggle()
    WowCNState.imeEnabled = not WowCNState.imeEnabled
    if WowCNState.imeEnabled then
        Print("中文输入插件已|cff00ff00【开启】|r")
    else 
        Print("中文输入插件已|cffff0000【关闭】|r")
        WowCNInput_ClearState()
        WowCNInputFrame:Hide()
    end
end

--[[
    斜杠命令注册
]]
SlashCmdList["WCI_SWITCH"] = function(msg)
    if msg == "config" or msg == "setup" or msg == "ui" then
        WowCNConfig.UI:Toggle()
    else
        WowCNInput_Toggle()
    end
end
SLASH_WCI_SWITCH1 = "/winput"
SLASH_WCI_SWITCH2 = "/wi"

--[[
    WowCNInput_OnEvent - 事件处理函数
    参数: event - 事件名称
]]
function WowCNInput_OnEvent(event)
    WowCNInput_Debug("事件触发: " .. tostring(event))
    
    if event == "VARIABLES_LOADED" then
        WowCNInput_Debug("VARIABLES_LOADED 事件处理")
        -- 初始化配置数据库
        WowCNConfig:InitializeDB()
        WowCNDB_InitUserDict()
        WowCNEvent_HookAllKnownBoxes()
    elseif event == "ADDON_LOADED" then
        -- 在 ADDON_LOADED 事件中也初始化用户词库（以防 VARIABLES_LOADED 未触发）
        if arg1 == "WowCNInput" then
            WowCNInput_Debug("ADDON_LOADED WowCNInput 事件处理")
            -- 初始化配置数据库
            WowCNConfig:InitializeDB()
            WowCNDB_InitUserDict()
            if not welcomeShown then
                WowCNEvent_InitWelcomeTimer()
            end
        end
        WowCNEvent_HookAllKnownBoxes()
    elseif event == "MAIL_SHOW" or event == "AUCTION_HOUSE_SHOW" then
        WowCNEvent_HookAllKnownBoxes()
    end
end
