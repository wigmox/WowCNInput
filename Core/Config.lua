--------------------------------
-- WowCNInput 配置管理
-- 功能: 管理插件配置、常量定义、设置界面
--------------------------------

-- [全局命名空间]
WowCNInput = WowCNInput or {}

-- [按键绑定中文字符串] 用于 Bindings.xml 显示中文
BINDING_HEADER_WOWCNINPUT = "WowCNInput 中文输入"
BINDING_NAME_TOGGLEWOWCNINPUT = "切换中文输入"

-- [配置表 - 常量]
WowCNConfig = {}

-- ============================================================================
-- 默认配置值
-- ============================================================================
WowCNConfig.DEFAULTS = {
    chatTop = true,                 -- 聊天输入框位置
    segMode = 1,                    -- 分词模式 (1=最大候选, 2=全部候选)
    cacheEnabled = true,            -- 缓存启用
    cacheMax = 500,                 -- 缓存最大数量
    userDictEnabled = true,         -- 用户词库启用
    userDictMax = 5000,             -- 用户词库最大数量
    dynamicAdapt = true,            -- 全词动态调频
    debugEnabled = false,           -- 调试模式
    hlColor = '|cff00dddd',         -- 高亮颜色
    -- 候选区设置
    pinyinFontSize = 16,            -- 拼音字体大小 (16-24)
    candidateFontSize = 16,         -- 候选字字体大小 (16-24)
    candidateScale = 1.0,           -- 候选区缩放 (1.0-2.0)
    candidateWidth = 500,           -- 候选区宽度 (500-800)
    -- 小地图图标设置
    minimapPos = 180,               -- 小地图图标位置角度 (0-360)
    minimapHide = false,            -- 是否隐藏小地图图标
}

-- ============================================================================
-- 配置初始化函数
-- ============================================================================
function WowCNConfig:InitializeDB()
    -- 确保 WowCNInputDB 存在
    if not WowCNInputDB then
        WowCNInputDB = {}
    end
    
    -- 初始化默认值
    for key, defaultValue in pairs(self.DEFAULTS) do
        if WowCNInputDB[key] == nil then
            WowCNInputDB[key] = defaultValue
        end
    end
    
    -- 初始化词库启用状态（遍历已注册的词库）
    if not WowCNInputDB.dictEnabled then
        WowCNInputDB.dictEnabled = {}
    end
    if WowCNDB and WowCNDB._dicts then
        for dictName, _ in pairs(WowCNDB._dicts) do
            if WowCNInputDB.dictEnabled[dictName] == nil then
                WowCNInputDB.dictEnabled[dictName] = true
            end
        end
    end
    
    -- 初始化用户词库
    if not WowCNInputDB.userDict then
        WowCNInputDB.userDict = {}
    end
end

-- ============================================================================
-- 配置 Get/Set 函数
-- ============================================================================
function WowCNConfig:Get(key)
    if not WowCNInputDB then
        return self.DEFAULTS[key]
    end
    -- 如果 WowCNInputDB 中没有该键，返回默认值
    if WowCNInputDB[key] == nil then
        return self.DEFAULTS[key]
    end
    return WowCNInputDB[key]
end

function WowCNConfig:Set(key, value)
    if not WowCNInputDB then
        WowCNInputDB = {}
    end
    WowCNInputDB[key] = value
end

-- [Debug 输出函数]
function WowCNInput_Debug(msg)
    if WowCNConfig:Get("debugEnabled") then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[WI Debug]|r " .. tostring(msg))
    end
end

-- [设置界面常量]
local FRAME_WIDTH = 700
local FRAME_HEIGHT = 550
local PADDING = 15
local BUTTON_HEIGHT = 28
local SIDEBAR_WIDTH = 120

-- [调整按钮颜色常量]
local BUTTON_COLOR_NORMAL = {0.15, 0.15, 0.15, 1}
local BUTTON_COLOR_HOVER = {0.8, 0.6, 0.1, 1}
local BUTTON_BORDER_NORMAL = {0.4, 0.4, 0.4, 1}
local BUTTON_BORDER_HOVER = {0.8, 0.6, 0.1, 1}
local BUTTON_TEXT_NORMAL = {1, 1, 1}
local BUTTON_TEXT_HOVER = {1, 1, 0.7}

-- [设置页定义]
local SECTIONS = {
    {id = "general", name = "常规设置"},
    {id = "candidate", name = "候选区设置"},
    {id = "dict", name = "词库设置"},
    {id = "about", name = "关于"},
}

-- [当前选中的设置页]
local currentSection = "general"

-- [设置界面命名空间]
WowCNConfig.UI = {}

-- [注册确认对话框]
StaticPopupDialogs["WI_RELOAD_CONFIRM"] = {
    text = "确定要重载界面吗？",
    button1 = TEXT(ACCEPT),
    button2 = TEXT(CANCEL),
    OnAccept = function()
        ReloadUI()
    end,
    timeout = 0,
    hideOnEscape = 1,
}

--[[
    WowCNConfig.UI:CreateMainFrame - 创建主设置窗口
]]
function WowCNConfig.UI:CreateMainFrame()
    if self.frame then return self.frame end
    
    local frame = CreateFrame("Frame", "WowCNInputConfigFrame", UIParent)
    frame:SetWidth(FRAME_WIDTH)
    frame:SetHeight(FRAME_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:Hide()
    
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    -- 标题栏拖动区域
    local titleRegion = CreateFrame("Frame", nil, frame)
    titleRegion:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -5)
    titleRegion:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -5)
    titleRegion:SetHeight(30)
    titleRegion:EnableMouse(true)
    titleRegion:SetScript("OnMouseDown", function() frame:StartMoving() end)
    titleRegion:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)
    
    -- 标题头部纹理
    local headerTexture = frame:CreateTexture(nil, "ARTWORK")
    headerTexture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    headerTexture:SetWidth(300)
    headerTexture:SetHeight(64)
    headerTexture:SetPoint("TOP", frame, "TOP", 0, 12)
    
    -- 标题文本
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", headerTexture, "TOP", 0, -14)
    title:SetText("WowCNInput 设置")
    
    -- 底部高度
    local footerHeight = 40
    
    -- 左侧边栏
    local sidebar = CreateFrame("Frame", nil, frame)
    sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING + 5, -45)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    sidebar:SetHeight(FRAME_HEIGHT - 45 - footerHeight - PADDING)
    sidebar:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    sidebar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    frame.sidebar = sidebar
    
    -- 右侧内容区
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", PADDING, 0)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PADDING - 5, footerHeight + PADDING)
    content:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    content:SetBackdropColor(0.05, 0.05, 0.05, 0.3)
    frame.content = content
    
    -- 关闭按钮
    local closeButton = CreateFrame("Button", "WowCNInputConfigCloseButton", frame, "GameMenuButtonTemplate")
    closeButton:SetWidth(96)
    closeButton:SetHeight(21)
    closeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PADDING - 5, PADDING)
    closeButton:SetText(CLOSE or "关闭")
    closeButton:SetScript("OnClick", function()
        PlaySound("gsTitleOptionExit")
        frame:Hide()
    end)
    frame.closeButton = closeButton
    
    -- 重载按钮
    local reloadButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    reloadButton:SetWidth(96)
    reloadButton:SetHeight(21)
    reloadButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PADDING + 5, PADDING)
    reloadButton:SetText("重载界面")
    reloadButton:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        StaticPopup_Show("WI_RELOAD_CONFIRM")
    end)
    frame.reloadButton = reloadButton
    
    -- Debug 开关按钮
    local debugButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    debugButton:SetWidth(96)
    debugButton:SetHeight(21)
    debugButton:SetPoint("LEFT", reloadButton, "RIGHT", 10, 0)
    local debugText = WowCNConfig:Get("debugEnabled") and "Debug: 开" or "Debug: 关"
    debugButton:SetText(debugText)
    debugButton:SetScript("OnClick", function()
        local enabled = not WowCNConfig:Get("debugEnabled")
        WowCNConfig:Set("debugEnabled", enabled)
        local newText = enabled and "Debug: 开" or "Debug: 关"
        this:SetText(newText)
        if enabled then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ddddWowCNInput:|r 调试模式已|cff00ff00【开启】|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ddddWowCNInput:|r 调试模式已|cffff0000【关闭】|r")
        end
    end)
    frame.debugButton = debugButton
    
    self.frame = frame
    self.sidebarButtons = {}
    self.contentSections = {}
    
    -- 创建侧边栏按钮
    self:CreateSidebarButtons()
    
    -- 创建内容区域
    self:CreateContentSections()
    
    -- 显示第一个页面
    self:ShowSection("general")
    
    -- 添加到特殊框架列表，ESC可关闭
    table.insert(UISpecialFrames, "WowCNInputConfigFrame")
    
    return frame
end

--[[
    WowCNConfig.UI:CreateSidebarButtons - 创建侧边栏按钮
]]
function WowCNConfig.UI:CreateSidebarButtons()
    local sidebar = self.frame.sidebar
    
    for i, section in ipairs(SECTIONS) do
        local button = CreateFrame("Button", nil, sidebar)
        button:SetWidth(SIDEBAR_WIDTH - 10)
        button:SetHeight(BUTTON_HEIGHT)
        button:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 5, -5 - (i-1) * (BUTTON_HEIGHT + 2))
        
        button:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        button:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
        
        local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER", button, "CENTER", 0, 0)
        text:SetText(section.name)
        button.text = text
        button.sectionId = section.id
        
        button:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOn")
            WowCNConfig.UI:ShowSection(this.sectionId)
        end)
        
        button:SetScript("OnEnter", function()
            if currentSection ~= this.sectionId then
                this:SetBackdropColor(0.3, 0.3, 0.3, 0.8)
            end
        end)
        button:SetScript("OnLeave", function()
            if currentSection ~= this.sectionId then
                this:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
            end
        end)
        
        self.sidebarButtons[section.id] = button
    end
end

--[[
    WowCNConfig.UI:CreateContentSections - 创建内容区域
]]
function WowCNConfig.UI:CreateContentSections()
    self:CreateGeneralSection()
    self:CreateCandidateSection()
    self:CreateDictSection()
    self:CreateAboutSection()
end

--[[
    WowCNConfig.UI:ShowSection - 显示指定页面
]]
function WowCNConfig.UI:ShowSection(sectionId)
    currentSection = sectionId
    
    -- 更新侧边栏按钮状态
    for id, button in pairs(self.sidebarButtons) do
        if id == sectionId then
            button:SetBackdropColor(0.3, 0.5, 0.3, 0.8)
            button.text:SetTextColor(1, 1, 1)
        else
            button:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
            button.text:SetTextColor(0.8, 0.8, 0.8)
        end
    end
    
    -- 显示对应内容
    for id, section in pairs(self.contentSections) do
        if id == sectionId then
            section:Show()
        else
            section:Hide()
        end
    end
    
    -- 如果是词库设置页，动态更新列表
    if sectionId == "dict" then
        self:UpdateDictList()
    end
end

--[[
    WowCNConfig.UI:CreateCheckbox - 创建复选框
]]
function WowCNConfig.UI:CreateCheckbox(parent, label, getFunc, setFunc, tooltipText)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetWidth(24)
    check:SetHeight(24)
    
    local text = check:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", check, "RIGHT", 5, 0)
    text:SetText(label)
    
    check.label = label
    check.tooltipText = tooltipText
    check.getFunc = getFunc
    check:SetChecked(getFunc() and 1 or 0)
    
    check:SetScript("OnClick", function()
        local checked = this:GetChecked() == 1
        setFunc(checked)
    end)
    
    -- 将控件添加到控件列表
    if self.frame then
        if not self.frame.controls then
            self.frame.controls = {}
        end
        table.insert(self.frame.controls, check)
    end
    
    return check
end

--[[
    WowCNConfig.UI:CreateEditBox - 创建输入框
]]
function WowCNConfig.UI:CreateEditBox(parent, width, getFunc, setFunc, label)
    local editBox = CreateFrame("EditBox", nil, parent)
    editBox:SetWidth(width)
    editBox:SetHeight(20)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontHighlight)
    editBox:SetJustifyH("CENTER")
    editBox:SetMaxLetters(6)
    
    editBox:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    editBox:SetBackdropColor(0, 0, 0, 0.8)
    editBox:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    editBox:SetText(tostring(getFunc() or ""))
    editBox.label = label
    
    editBox:SetScript("OnEscapePressed", function()
        this:ClearFocus()
        this:SetText(tostring(getFunc() or ""))
    end)
    
    editBox:SetScript("OnEnterPressed", function()
        this:ClearFocus()
        local val = tonumber(this:GetText())
        if val then setFunc(val) end
    end)
    
    editBox:SetScript("OnEditFocusLost", function()
        local val = tonumber(this:GetText())
        if val then setFunc(val) end
    end)
    
    return editBox
end

--[[
    WowCNConfig.UI:CreateSectionBox - 创建设置分组框
]]
function WowCNConfig.UI:CreateSectionBox(parent, title, height)
    local box = CreateFrame("Frame", nil, parent)
    box:SetWidth(FRAME_WIDTH - SIDEBAR_WIDTH - PADDING * 4)
    box:SetHeight(height or 120)
    
    box:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    box:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
    
    local titleText = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    titleText:SetPoint("TOPLEFT", box, "TOPLEFT", 10, -5)
    titleText:SetText(title)
    
    box.contentTop = -25
    box.contentLeft = 15
    
    return box
end

--[[
    WowCNConfig.UI:CreateAdjustControl - 创建带增减按钮的调整控件
    参数: parent - 父容器
          label - 标签文本
          getFunc - 获取值函数
          setFunc - 设置值函数
          minVal - 最小值
          maxVal - 最大值
          step - 步进值
    返回: 控件容器
]]
function WowCNConfig.UI:CreateAdjustControl(parent, label, getFunc, setFunc, minVal, maxVal, step)
    local container = CreateFrame("Frame", nil, parent)
    container:SetWidth(300)
    container:SetHeight(24)
    
    -- 标签
    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    labelText:SetPoint("LEFT", container, "LEFT", 0, 0)
    labelText:SetText(label)
    labelText:SetWidth(140)
    labelText:SetJustifyH("LEFT")
    
    -- 减少按钮 (WoW 1.12 兼容：使用Frame模拟按钮)
    local decButton = CreateFrame("Button", nil, container)
    decButton:SetWidth(22)
    decButton:SetHeight(22)
    decButton:SetPoint("LEFT", labelText, "RIGHT", 5, 0)
    decButton:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    decButton:SetBackdropColor(unpack(BUTTON_COLOR_NORMAL))
    decButton:SetBackdropBorderColor(unpack(BUTTON_BORDER_NORMAL))
    
    -- 按钮文本
    local decText = decButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    decText:SetPoint("CENTER", decButton, "CENTER", 0, 0)
    decText:SetText("-")
    decText:SetTextColor(unpack(BUTTON_TEXT_NORMAL))
    decButton.text = decText
    
    decButton:SetScript("OnEnter", function()
        this:SetBackdropColor(unpack(BUTTON_COLOR_HOVER))
        this:SetBackdropBorderColor(unpack(BUTTON_BORDER_HOVER))
        this.text:SetTextColor(unpack(BUTTON_TEXT_HOVER))
    end)
    decButton:SetScript("OnLeave", function()
        this:SetBackdropColor(unpack(BUTTON_COLOR_NORMAL))
        this:SetBackdropBorderColor(unpack(BUTTON_BORDER_NORMAL))
        this.text:SetTextColor(unpack(BUTTON_TEXT_NORMAL))
    end)
    decButton:SetScript("OnClick", function()
        local currentVal = tonumber(getFunc()) or minVal
        local newVal = currentVal - step
        if newVal < minVal then newVal = minVal end
        newVal = math.floor(newVal * 10 + 0.5) / 10
        setFunc(newVal)
        container.editBox:SetText(tostring(newVal))
    end)
    
    -- 输入框
    local editBox = CreateFrame("EditBox", nil, container)
    editBox:SetWidth(50)
    editBox:SetHeight(20)
    editBox:SetPoint("LEFT", decButton, "RIGHT", 2, 0)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontHighlight)
    editBox:SetJustifyH("CENTER")
    editBox:SetMaxLetters(6)
    editBox:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    editBox:SetBackdropColor(0, 0, 0, 0.8)
    editBox:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    editBox:SetText(tostring(getFunc() or ""))
    container.editBox = editBox
    
    editBox:SetScript("OnEscapePressed", function()
        this:ClearFocus()
        this:SetText(tostring(getFunc() or ""))
    end)
    
    editBox:SetScript("OnEnterPressed", function()
        this:ClearFocus()
        local val = tonumber(this:GetText())
        if val then
            if val < minVal then val = minVal end
            if val > maxVal then val = maxVal end
            setFunc(val)
            this:SetText(tostring(val))
        end
    end)
    
    editBox:SetScript("OnEditFocusLost", function()
        local val = tonumber(this:GetText())
        if val then
            if val < minVal then val = minVal end
            if val > maxVal then val = maxVal end
            setFunc(val)
            this:SetText(tostring(val))
        end
    end)
    
    -- 增加按钮 (WoW 1.12 兼容：使用Frame模拟按钮)
    local incButton = CreateFrame("Button", nil, container)
    incButton:SetWidth(22)
    incButton:SetHeight(22)
    incButton:SetPoint("LEFT", editBox, "RIGHT", 2, 0)
    incButton:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    incButton:SetBackdropColor(unpack(BUTTON_COLOR_NORMAL))
    incButton:SetBackdropBorderColor(unpack(BUTTON_BORDER_NORMAL))
    
    -- 按钮文本
    local incText = incButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    incText:SetPoint("CENTER", incButton, "CENTER", 0, 0)
    incText:SetText("+")
    incText:SetTextColor(unpack(BUTTON_TEXT_NORMAL))
    incButton.text = incText
    
    incButton:SetScript("OnEnter", function()
        this:SetBackdropColor(unpack(BUTTON_COLOR_HOVER))
        this:SetBackdropBorderColor(unpack(BUTTON_BORDER_HOVER))
        this.text:SetTextColor(unpack(BUTTON_TEXT_HOVER))
    end)
    incButton:SetScript("OnLeave", function()
        this:SetBackdropColor(unpack(BUTTON_COLOR_NORMAL))
        this:SetBackdropBorderColor(unpack(BUTTON_BORDER_NORMAL))
        this.text:SetTextColor(unpack(BUTTON_TEXT_NORMAL))
    end)
    incButton:SetScript("OnClick", function()
        local currentVal = tonumber(getFunc()) or minVal
        local newVal = currentVal + step
        if newVal > maxVal then newVal = maxVal end
        newVal = math.floor(newVal * 10 + 0.5) / 10
        setFunc(newVal)
        container.editBox:SetText(tostring(newVal))
    end)
    
    -- 范围提示
    local rangeText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rangeText:SetPoint("LEFT", incButton, "RIGHT", 8, 0)
    rangeText:SetTextColor(0.5, 0.5, 0.5)
    rangeText:SetText("(" .. minVal .. "-" .. maxVal .. ")")
    
    return container
end

--[[
    WowCNConfig.UI:CreateGeneralSection - 创建常规设置页
]]
function WowCNConfig.UI:CreateGeneralSection()
    local content = self.frame.content
    local section = CreateFrame("Frame", nil, content)
    section:SetPoint("TOPLEFT", content, "TOPLEFT", 5, 0)
    section:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -5, 5)
    section:Hide()
    self.contentSections["general"] = section
    
    -- 常规设置分组
    local generalBox = self:CreateSectionBox(section, "常规设置", 200)
    generalBox:SetPoint("TOP", section, "TOP", 0, 0)
    
    -- 启用中文输入
    local enabledCheck = self:CreateCheckbox(generalBox, "启用中文输入",
        function() return WowCNState.imeEnabled end,
        function(checked)
            -- 如果状态不同才切换
            if WowCNState.imeEnabled ~= checked then
                WowCNInput_Toggle()
            end
        end)
    enabledCheck:SetPoint("TOPLEFT", generalBox, "TOPLEFT", generalBox.contentLeft, generalBox.contentTop)
    
    -- 启用缓存
    local cacheEnabledCheck = self:CreateCheckbox(generalBox, "启用缓存",
        function() return WowCNConfig:Get("cacheEnabled") end,
        function(checked) 
            WowCNConfig:Set("cacheEnabled", checked)
        end)
    cacheEnabledCheck:SetPoint("TOPLEFT", enabledCheck, "BOTTOMLEFT", 0, -5)
    
    local cacheLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cacheLabel:SetPoint("LEFT", cacheEnabledCheck, "RIGHT", 100, 0)
    cacheLabel:SetText("缓存大小:")
    
    local cacheEdit = self:CreateEditBox(generalBox, 60,
        function() return WowCNConfig:Get("cacheMax") end,
        function(val)
            WowCNConfig:Set("cacheMax", val)
            -- 立即生效：清理超限缓存
            while WowCNDB._cacheSize > val do
                local count = 0
                local halfRemove = math.ceil((WowCNDB._cacheSize - val) / 2)
                for k in pairs(WowCNDB._cache) do
                    WowCNDB._cache[k] = nil
                    WowCNDB._cacheSize = WowCNDB._cacheSize - 1
                    count = count + 1
                    if count >= halfRemove then break end
                end
            end
        end)
    cacheEdit:SetPoint("LEFT", cacheLabel, "RIGHT", 5, 0)
    
    -- 启用用户词库
    local userDictEnabledCheck = self:CreateCheckbox(generalBox, "启用用户词库",
        function() return WowCNConfig:Get("userDictEnabled") end,
        function(checked) 
            WowCNConfig:Set("userDictEnabled", checked)
        end)
    userDictEnabledCheck:SetPoint("TOPLEFT", cacheEnabledCheck, "BOTTOMLEFT", 0, -5)
    
    local userDictLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    userDictLabel:SetPoint("LEFT", userDictEnabledCheck, "RIGHT", 140, 0)
    userDictLabel:SetText("词库上限:")
    
    local userDictEdit = self:CreateEditBox(generalBox, 60,
        function() return WowCNConfig:Get("userDictMax") end,
        function(val)
            WowCNConfig:Set("userDictMax", val)
            WowCNDB_UserDict._maxCount = val
            -- 立即生效：清理超限词条
            local currentCount = WowCNDB_GetUserDictCount()
            while currentCount > val do
                WowCNDB_RemoveOldest()
                currentCount = WowCNDB_GetUserDictCount()
            end
        end)
    userDictEdit:SetPoint("LEFT", userDictLabel, "RIGHT", 5, 0)
    
    -- 全词动态调频开关
    local dynamicAdaptCheck = self:CreateCheckbox(generalBox, "全词动态调频",
        function() return WowCNConfig:Get("dynamicAdapt") end,
        function(checked)
            WowCNConfig:Set("dynamicAdapt", checked)
        end)
    dynamicAdaptCheck:SetPoint("TOPLEFT", userDictEnabledCheck, "BOTTOMLEFT", 0, -5)
    
    -- 聊天输入框位置开关
    local chatTopCheck = self:CreateCheckbox(generalBox, "聊天输入框移至顶部",
        function() return WowCNConfig:Get("chatTop") end,
        function(checked)
            WowCNConfig:Set("chatTop", checked)
            -- 立即生效
            if ChatFrameEditBox then
                if checked then
                    -- 保存原始位置（仅第一次保存）
                    if not WowCNInput.chatEditBoxOriginalPoint then
                        WowCNInput.chatEditBoxOriginalPoint = {ChatFrameEditBox:GetPoint()}
                    end
                    -- 移至顶部
                    ChatFrameEditBox:ClearAllPoints()
                    ChatFrameEditBox:SetPoint("TOP", UIParent, "TOP", 0, -50)
                    ChatFrameEditBox:SetWidth(500)
                    ChatFrameEditBox:SetHeight(30)
                else
                    -- 恢复原始位置
                    if WowCNInput.chatEditBoxOriginalPoint then
                        ChatFrameEditBox:ClearAllPoints()
                        ChatFrameEditBox:SetPoint(unpack(WowCNInput.chatEditBoxOriginalPoint))
                    end
                end
            end
        end)
    chatTopCheck:SetPoint("TOPLEFT", dynamicAdaptCheck, "BOTTOMLEFT", 0, -5)
    
    -- 显示小地图图标开关
    local minimapShowCheck = self:CreateCheckbox(generalBox, "显示小地图图标",
        function() return not WowCNConfig:Get("minimapHide") end,
        function(checked)
            WowCNConfig:Set("minimapHide", not checked)
            if checked then
                WowCNMinimap_Show()
            else
                WowCNMinimap_Hide()
            end
        end)
    minimapShowCheck:SetPoint("TOPLEFT", chatTopCheck, "BOTTOMLEFT", 0, -5)
    
    -- 分词模式分组
    local segModeBox = self:CreateSectionBox(section, "分词模式", 100)
    segModeBox:SetPoint("TOP", generalBox, "BOTTOM", 0, -10)
    
    -- 分词模式文本常量
    local SEG_MODE_GREEDY_TEXT = "最大候选"
    local SEG_MODE_AII_TEXT = "全部候选"
    local SEG_MODE_GREEDY_DESC = "最大候选(更精准)"
    local SEG_MODE_AII_DESC = "全部候选(更全面)"
    
    local segModeLabel = segModeBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    segModeLabel:SetPoint("TOPLEFT", segModeBox, "TOPLEFT", segModeBox.contentLeft, segModeBox.contentTop)
    segModeLabel:SetText("选择分词方案:")
    
    local segModeDesc = segModeBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    segModeDesc:SetPoint("TOPLEFT", segModeLabel, "BOTTOMLEFT", 0, -15)
    segModeDesc:SetTextColor(0.6, 0.6, 0.6)
    segModeDesc:SetText(SEG_MODE_GREEDY_DESC .. "  " .. SEG_MODE_AII_DESC)
    
    -- 分词模式下拉菜单（参考 ConsoleExperienceClassic）
    local segModeDropdown = CreateFrame("Frame", "WowCNInputSegModeDropdown", segModeBox, "UIDropDownMenuTemplate")
    segModeDropdown:SetPoint("LEFT", segModeLabel, "RIGHT", -15, -3)
    
    local function InitializeSegModeDropdown()
        local selectedValue = UIDropDownMenu_GetSelectedValue(segModeDropdown) or (WowCNConfig:Get("segMode") or 1)
        local info
        
        -- Mode: Greedy
        info = {}
        info.text = SEG_MODE_GREEDY_TEXT
        info.value = 1
        info.func = function()
            UIDropDownMenu_SetSelectedValue(segModeDropdown, 1)
            UIDropDownMenu_SetText(SEG_MODE_GREEDY_TEXT, segModeDropdown)
            WowCNConfig:Set("segMode", 1)
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ddddWowCNInput:|r 分词模式已切换为 " .. SEG_MODE_GREEDY_TEXT)
        end
        if info.value == selectedValue then
            info.checked = 1
        end
        UIDropDownMenu_AddButton(info)
        
        -- Mode: All Candidates
        info = {}
        info.text = SEG_MODE_AII_TEXT
        info.value = 2
        info.func = function()
            UIDropDownMenu_SetSelectedValue(segModeDropdown, 2)
            UIDropDownMenu_SetText(SEG_MODE_AII_TEXT, segModeDropdown)
            WowCNConfig:Set("segMode", 2)
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ddddWowCNInput:|r 分词模式已切换为 " .. SEG_MODE_AII_TEXT)
        end
        if info.value == selectedValue then
            info.checked = 1
        end
        UIDropDownMenu_AddButton(info)
    end
    
    segModeDropdown.initialize = InitializeSegModeDropdown
    UIDropDownMenu_Initialize(segModeDropdown, InitializeSegModeDropdown)
    UIDropDownMenu_SetWidth(150, segModeDropdown)
    local currentSegMode = WowCNConfig:Get("segMode") or 1
    UIDropDownMenu_SetSelectedValue(segModeDropdown, currentSegMode)
    UIDropDownMenu_SetText(currentSegMode == 1 and SEG_MODE_GREEDY_TEXT or SEG_MODE_AII_TEXT, segModeDropdown)
end

--[[
    WowCNConfig.UI:CreateCandidateSection - 创建候选区设置页
]]
function WowCNConfig.UI:CreateCandidateSection()
    local content = self.frame.content
    local section = CreateFrame("Frame", nil, content)
    section:SetPoint("TOPLEFT", content, "TOPLEFT", 5, 0)
    section:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -5, 5)
    section:Hide()
    self.contentSections["candidate"] = section
    
    -- 候选区设置分组
    local candidateBox = self:CreateSectionBox(section, "候选区设置", 200)
    candidateBox:SetPoint("TOP", section, "TOP", 0, 0)
    
    local yPos = candidateBox.contentTop
    local leftColX = candidateBox.contentLeft
    
    -- 拼音字体大小 (步进1)
    local pinyinControl = self:CreateAdjustControl(candidateBox, "拼音字体大小:",
        function() return WowCNConfig:Get("pinyinFontSize") end,
        function(val)
            WowCNConfig:Set("pinyinFontSize", val)
            WowCNInput_ApplyUISettings()
        end,
        16, 24, 1)
    pinyinControl:SetPoint("TOPLEFT", candidateBox, "TOPLEFT", leftColX, yPos)
    yPos = yPos - 35
    
    -- 候选字字体大小 (步进1)
    local candControl = self:CreateAdjustControl(candidateBox, "候选字字体大小:",
        function() return WowCNConfig:Get("candidateFontSize") end,
        function(val)
            WowCNConfig:Set("candidateFontSize", val)
            WowCNInput_ApplyUISettings()
        end,
        16, 24, 1)
    candControl:SetPoint("TOPLEFT", candidateBox, "TOPLEFT", leftColX, yPos)
    yPos = yPos - 35
    
    -- 候选区缩放 (步进0.1)
    local scaleControl = self:CreateAdjustControl(candidateBox, "候选区缩放:",
        function() return WowCNConfig:Get("candidateScale") end,
        function(val)
            WowCNConfig:Set("candidateScale", val)
            WowCNInput_ApplyUISettings()
        end,
        1.0, 2.0, 0.1)
    scaleControl:SetPoint("TOPLEFT", candidateBox, "TOPLEFT", leftColX, yPos)
    yPos = yPos - 35
    
    -- 候选区宽度 (步进5)
    local widthControl = self:CreateAdjustControl(candidateBox, "候选区宽度:",
        function() return WowCNConfig:Get("candidateWidth") end,
        function(val)
            WowCNConfig:Set("candidateWidth", val)
            WowCNInput_ApplyUISettings()
        end,
        500, 800, 5)
    widthControl:SetPoint("TOPLEFT", candidateBox, "TOPLEFT", leftColX, yPos)
    
    yPos = yPos - 35
    
    -- 说明文本
    local descLabel = candidateBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    descLabel:SetPoint("TOPLEFT", candidateBox, "TOPLEFT", leftColX, yPos)
    descLabel:SetTextColor(0.6, 0.6, 0.6)
    descLabel:SetText("提示: 如果字体过大可能无法显示完整，可适当调整候选框长度。")
end

--[[
    WowCNConfig.UI:CreateDictSection - 创建词库设置页
]]
function WowCNConfig.UI:CreateDictSection()
    local content = self.frame.content
    local section = CreateFrame("Frame", nil, content)
    section:SetPoint("TOPLEFT", content, "TOPLEFT", 5, 0)
    section:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -5, 5)
    section:Hide()
    self.contentSections["dict"] = section
    
    -- 词库列表分组（增大高度以容纳更多词库）
    local dictListBox = self:CreateSectionBox(section, "词库设置", 350)
    dictListBox:SetPoint("TOP", section, "TOP", 0, 0)
    
    -- 计算可用宽度
    local availableWidth = dictListBox:GetWidth() - 35
    
    -- 列宽定义（删除说明列，重新分配宽度）
    -- 启用(40) + 名称(140) + 词条(55) + 版本(40) + 日期(100) + 作者(100) 
    local widths = {40, 140, 55, 40, 100, 100}
    
    -- 创建滚动框架
    local scrollFrame = CreateFrame("ScrollFrame", "WowCNInputDictScrollFrame", dictListBox, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", dictListBox, "TOPLEFT", 5, -45)
    scrollFrame:SetPoint("BOTTOMRIGHT", dictListBox, "BOTTOMRIGHT", -25, 5)
    
    -- 滚动内容
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(availableWidth)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- 表头（固定在顶部，不滚动）
    local headers = {"启用", "词库名称", "词条", "版本", "日期", "作者"}
    local xPos = 5
    
    for i, header in ipairs(headers) do
        local headerText = dictListBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        headerText:SetPoint("TOPLEFT", dictListBox, "TOPLEFT", xPos + 5, -25)
        headerText:SetText(header)
        headerText:SetTextColor(0.8, 0.8, 0.8)
        xPos = xPos + widths[i]
    end
    
    -- 保存引用
    dictListBox.scrollFrame = scrollFrame
    dictListBox.scrollChild = scrollChild
    dictListBox.widths = widths
    
    -- 重置按钮
    local clearBtn = CreateFrame("Button", nil, section, "GameMenuButtonTemplate")
    clearBtn:SetWidth(120)
    clearBtn:SetHeight(21)
    clearBtn:SetPoint("TOPLEFT", dictListBox, "BOTTOMLEFT", 10, -15)
    clearBtn:SetText("重置用户词库")
    clearBtn:SetScript("OnClick", function()
        WowCNDB_ClearUserDict()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ddddWowCNInput:|r 用户词库已重置")
    end)
    
    self.dictListBox = dictListBox
    self.dictScrollChild = scrollChild
    self.dictItems = {}
end

--[[
    WowCNConfig.UI:UpdateDictList - 更新词库列表
]]
function WowCNConfig.UI:UpdateDictList()
    if not self.dictScrollChild then return end
    
    -- 清空现有列表
    for i = 1, table.getn(self.dictItems) do
        local item = self.dictItems[i]
        if item.check then item.check:Hide() end
        if item.name then item.name:Hide() end
        if item.count then item.count:Hide() end
        if item.version then item.version:Hide() end
        if item.date then item.date:Hide() end
        if item.author then item.author:Hide() end
    end
    self.dictItems = {}
    
    -- 检查词库是否已加载
    if not WowCNDB or not WowCNDB._dicts then
        local noDictText = self.dictScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        noDictText:SetPoint("TOPLEFT", self.dictScrollChild, "TOPLEFT", 11, 0)
        noDictText:SetText("词库未加载，请重载界面")
        noDictText:SetTextColor(0.8, 0.8, 0.8)
        table.insert(self.dictItems, {name = noDictText})
        return
    end
    
    local yPos = -10

--[[
    WowCNConfig.UI:CreateDictItem - 创建词库列表项
    参数: dictName - 词库名称
          meta - 词库元信息
          yPos - Y坐标位置
    返回: item - 创建的项对象
]]
function WowCNConfig.UI:CreateDictItem(dictName, meta, yPos)
    local widths = self.dictListBox.widths

    -- 初始化启用状态
    local dictEnabled = WowCNInputDB.dictEnabled or {}
    if dictEnabled[dictName] == nil then
        dictEnabled[dictName] = true
        WowCNInputDB.dictEnabled = dictEnabled
    end
    
    local item = {}
    local xPos = 5
    
    -- 启用复选框
    local enableCheck = CreateFrame("CheckButton", nil, self.dictScrollChild, "UICheckButtonTemplate")
    enableCheck:SetWidth(20)
    enableCheck:SetHeight(20)
    enableCheck:SetPoint("TOPLEFT", self.dictScrollChild, "TOPLEFT", xPos, yPos)
    enableCheck:SetChecked(dictEnabled[dictName] and 1 or 0)
    enableCheck.dictName = dictName  -- 保存词库名称
    enableCheck:SetScript("OnClick", function()
        local de = WowCNInputDB.dictEnabled or {}
        de[this.dictName] = (this:GetChecked() == 1)
        WowCNInputDB.dictEnabled = de
        -- 清除缓存，使设置立即生效
        WowCNDB._cache = {}
        WowCNDB._cacheSize = 0
    end)
    item.check = enableCheck
    
    xPos = xPos + widths[1]
    
    -- 词库名称
    local nameText = self.dictScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("TOPLEFT", self.dictScrollChild, "TOPLEFT", xPos, yPos + 3)
    local name = meta.name or dictName or "?"
    if string.len(name) > 24 then
        name = string.sub(name, 1, 20) .. "..."
    end
    nameText:SetText(name)
    item.name = nameText
    
    xPos = xPos + widths[2]
    
    -- 词条数
    local countText = self.dictScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countText:SetPoint("TOPLEFT", self.dictScrollChild, "TOPLEFT", xPos, yPos + 3)
    countText:SetText(meta.count or "?")
    item.count = countText
    
    xPos = xPos + widths[3]
    
    -- 版本
    local versionText = self.dictScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    versionText:SetPoint("TOPLEFT", self.dictScrollChild, "TOPLEFT", xPos, yPos + 3)
    versionText:SetText(meta.version or "1.0")
    item.version = versionText
    
    xPos = xPos + widths[4]
    
    -- 日期
    local dateText = self.dictScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dateText:SetPoint("TOPLEFT", self.dictScrollChild, "TOPLEFT", xPos, yPos + 3)
    dateText:SetText(meta.date or "?")
    item.date = dateText
    
    xPos = xPos + widths[5]
    
    -- 作者
    local authorText = self.dictScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    authorText:SetPoint("TOPLEFT", self.dictScrollChild, "TOPLEFT", xPos, yPos + 3)
    local author = meta.author or "?"
    if string.len(author) > 24 then
        author = string.sub(author, 1, 20) .. "..."
    end
    authorText:SetText(author)
    item.author = authorText
    
    return item
end

    
    -- 普通词库
    for dictName, dictData in pairs(WowCNDB._dicts) do
        local meta = WowCNDB._meta and WowCNDB._meta[dictName] or {}
        local item = self:CreateDictItem(dictName, meta, yPos)
        table.insert(self.dictItems, item)
        yPos = yPos - 22
    end
    
    -- 用户词库
    if WowCNDB._userDict then
        local userMeta = WowCNDB._meta and WowCNDB._meta[WI_USER_DICT_NAME] or {}
        userMeta.count = WowCNDB_GetUserDictCount() .. "/" .. WowCNDB_UserDict._maxCount
        local item = self:CreateDictItem(WI_USER_DICT_NAME, userMeta, yPos)
        -- 用户词库名称高亮显示
        if item.name then
            item.name:SetTextColor(0.2, 1.0, 0.2)
        end
        table.insert(self.dictItems, item)
        yPos = yPos - 22
    end
    
    -- 更新滚动区域高度
    local totalHeight = math.abs(yPos) + 10
    self.dictScrollChild:SetHeight(math.max(totalHeight, 50))
end

--[[
    WowCNConfig.UI:CreateAboutSection - 创建关于页
]]
function WowCNConfig.UI:CreateAboutSection()
    local content = self.frame.content
    local section = CreateFrame("Frame", nil, content)
    section:SetPoint("TOPLEFT", content, "TOPLEFT", 5, 0)
    section:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -5, 5)
    section:Hide()
    self.contentSections["about"] = section
    
    -- [顶部区域] 关于信息分组
    local aboutBox = self:CreateSectionBox(section, "关于 WowCNInput 中文输入插件", 80)
    aboutBox:SetPoint("TOP", section, "TOP", 0, 0)
    
    local yPos = aboutBox.contentTop
    local leftPos = aboutBox.contentLeft
    
    -- 标题
    local titleText = aboutBox:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", aboutBox, "TOPLEFT", leftPos, yPos)
    titleText:SetText("|cff00ddddWowCNInput|r")
    
    -- 版本
    local versionText = aboutBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    versionText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -5)
    local version = GetAddOnMetadata("WowCNInput", "Version") or "未知"
    versionText:SetText("版本: " .. version)
    
    -- 作者
    local authorText = aboutBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    authorText:SetPoint("LEFT", versionText, "RIGHT", 30, 0)
    local author = GetAddOnMetadata("WowCNInput", "Author") or "未知"
    authorText:SetText("作者: " .. author)
    
    -- [中间区域] 功能说明分组
    local featureBox = self:CreateSectionBox(section, "功能说明", 100)
    featureBox:SetPoint("TOP", aboutBox, "BOTTOM", 0, -10)
    
    local features = {
        "• 支持拼音输入，自动匹配候选词",
        "• 支持用户自定义词库",
        "• 支持多种分词模式",
        "• 支持 WoW 1.12 (Turtle WoW)",
    }
    
    local featureY = featureBox.contentTop
    for i, feature in ipairs(features) do
        local featureText = featureBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        featureText:SetPoint("TOPLEFT", featureBox, "TOPLEFT", featureBox.contentLeft, featureY)
        featureText:SetText(feature)
        featureY = featureY - 18
    end
    
    -- [底部区域] 使用方法分组
    local usageBox = self:CreateSectionBox(section, "使用方法", 100)
    usageBox:SetPoint("TOP", featureBox, "BOTTOM", 0, -10)
    
    local usages = {
        "• 输入拼音后，按空格或数字选择候选词",
        "• 按 ESC 取消输入",
        "• 按 Enter 确认英文输入",
    }
    
    local usageY = usageBox.contentTop
    for i, usage in ipairs(usages) do
        local usageText = usageBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        usageText:SetPoint("TOPLEFT", usageBox, "TOPLEFT", usageBox.contentLeft, usageY)
        usageText:SetText(usage)
        usageY = usageY - 18
    end
    
    -- [最底部] 快捷键分组
    local keyBox = self:CreateSectionBox(section, "快捷键", 100)
    keyBox:SetPoint("TOP", usageBox, "BOTTOM", 0, -10)
    
    local keys = {
        {cmd = "/wi", desc = "切换中文输入"},
        {cmd = "/wi config", desc = "打开设置界面"},
        {cmd = "/wi help", desc = "显示帮助信息"},
    }
    
    local keyY = keyBox.contentTop
    for i, key in ipairs(keys) do
        local cmdText = keyBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cmdText:SetPoint("TOPLEFT", keyBox, "TOPLEFT", keyBox.contentLeft, keyY)
        cmdText:SetText("|cff00dddd" .. key.cmd .. "|r")
        
        local descText = keyBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        descText:SetPoint("LEFT", cmdText, "RIGHT", 10, 0)
        descText:SetText(key.desc)
        
        keyY = keyY - 18
    end
end

--[[
    WowCNConfig.UI:Show - 显示设置窗口
]]
function WowCNConfig.UI:Show()
    if not self.frame then
        self:CreateMainFrame()
    end
    self.frame:Show()
    -- 显示时更新所有控件状态
    self:Update()
end

--[[
    WowCNConfig.UI:Hide - 隐藏设置窗口
]]
function WowCNConfig.UI:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

--[[
    WowCNConfig.UI:Toggle - 切换设置窗口显示
]]
function WowCNConfig.UI:Toggle()
    if self.frame and self.frame:IsVisible() then
        self:Hide()
    else
        self:Show()
    end
end

--[[
    WowCNConfig.UI:Update - 更新设置界面所有控件状态
    说明: 当外部修改配置时调用，确保界面状态与配置同步
]]
function WowCNConfig.UI:Update()
    if not self.frame then return end
    
    -- 遍历所有控件并更新状态
    for _, control in pairs(self.frame.controls or {}) do
        if control.getFunc then
            control:SetChecked(control.getFunc() and 1 or 0)
        end
    end
end
