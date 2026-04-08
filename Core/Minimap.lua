--------------------------------
-- WowCNInput 小地图按钮模块
-- 功能: 在小地图旁显示可交互的图标按钮
--------------------------------

-- [模块局部变量]
local gIsDragging = false
local gIsMouseDown = false
local gMinimapButton = nil
local gDragStartX = 0
local gDragStartY = 0

-- [常量]
local MINIMAP_RADIUS = 80
local DRAG_THRESHOLD = 5

--[[
    WowCNMinimap_GetPosition - 根据角度计算图标位置坐标
    参数: angle - 角度 (0-360)
    返回: x, y - 相对于小地图中心的坐标
]]
local function WowCNMinimap_GetPosition(angle)
    local radian = math.rad(angle)
    local x = MINIMAP_RADIUS * math.cos(radian)
    local y = MINIMAP_RADIUS * math.sin(radian)
    return x, y
end

--[[
    WowCNMinimap_SetPosition - 设置小地图图标位置
    参数: angle - 角度 (0-360)
]]
function WowCNMinimap_SetPosition(angle)
    if not gMinimapButton then return end
    
    angle = math.mod(angle, 360)
    if angle < 0 then angle = angle + 360 end
    
    local x, y = WowCNMinimap_GetPosition(angle)
    gMinimapButton:ClearAllPoints()
    gMinimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
    
    WowCNConfig:Set("minimapPos", angle)
end

--[[
    WowCNMinimap_UpdateIcon - 更新图标显示
    说明: 根据输入法状态切换图标
]]
function WowCNMinimap_UpdateIcon()
    if not gMinimapButton then return end
    
    local iconTexture = getglobal(gMinimapButton:GetName() .. "Icon")
    if not iconTexture then return end
    
    if WowCNState and WowCNState.imeEnabled then
        iconTexture:SetTexture("Interface\\AddOns\\WowCNInput\\Textures\\cn.blp")
    else
        iconTexture:SetTexture("Interface\\AddOns\\WowCNInput\\Textures\\en.blp")
    end
end

--[[
    WowCNMinimap_OnEnter - 鼠标进入事件处理
    说明: 显示提示文字
]]
local function WowCNMinimap_OnEnter()
    if not gMinimapButton then return end
    
    GameTooltip:SetOwner(gMinimapButton, "ANCHOR_LEFT")
    GameTooltip:SetText("WowCNInput 中文输入", 0.8, 0.8, 0.2)
    
    local status = "关闭"
    if WowCNState and WowCNState.imeEnabled then
        status = "开启"
    end
    GameTooltip:AddLine("状态: " .. status, 1, 1, 1)
    GameTooltip:AddLine(" ", 1, 1, 1)
    GameTooltip:AddLine("左键: 切换输入法", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("Shift+拖动: 移动图标", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("右键: 菜单", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

--[[
    WowCNMinimap_OnLeave - 鼠标离开事件处理
]]
local function WowCNMinimap_OnLeave()
    GameTooltip:Hide()
end

--[[
    WowCNMinimap_OnMouseDown - 鼠标按下事件处理
    说明: 记录起始位置，准备可能的拖动
]]
local function WowCNMinimap_OnMouseDown()
    if not gMinimapButton then return end
    
    if arg1 == "LeftButton" then
        gIsDragging = false
        gIsMouseDown = true
        local x, y = GetCursorPosition()
        gDragStartX = x
        gDragStartY = y
        gMinimapButton:LockHighlight()
    end
end

--[[
    WowCNMinimap_OnMouseUp - 鼠标释放事件处理
    说明: 结束拖动状态
]]
local function WowCNMinimap_OnMouseUp()
    if not gMinimapButton then return end
    
    if arg1 == "LeftButton" then
        gMinimapButton:UnlockHighlight()
    end
    
    gIsDragging = false
    gIsMouseDown = false
end

--[[
    WowCNMinimap_OnUpdate - 更新事件处理
    说明: 处理Shift+拖动时的位置更新
]]
local function WowCNMinimap_OnUpdate()
    if not gMinimapButton then return end
    
    if gIsMouseDown and IsShiftKeyDown() then
        local x, y = GetCursorPosition()
        local dx = x - gDragStartX
        local dy = y - gDragStartY
        local distance = math.sqrt(dx * dx + dy * dy)
        
        if distance > DRAG_THRESHOLD then
            gIsDragging = true
            local mx, my = Minimap:GetCenter()
            local scale = UIParent:GetEffectiveScale()
            
            local px = x / scale
            local py = y / scale
            
            local angle = math.deg(math.atan2(py - my, px - mx))
            WowCNMinimap_SetPosition(angle)
        end
    end
end

--[[
    WowCNMinimap_OnClick - 点击事件处理
    说明: 左键切换输入法，右键显示菜单
]]
local function WowCNMinimap_OnClick()
    if not gMinimapButton then return end
    
    if arg1 == "LeftButton" and not gIsDragging then
        WowCNInput_Toggle()
    elseif arg1 == "RightButton" then
        local menu = {
            { text = "WowCNInput 中文输入", isTitle = true },
            { text = "开关输入法", func = WowCNInput_Toggle },
            { text = "打开设置", func = function() WowCNConfig.UI:Toggle() end },
            { text = "隐藏图标", func = WowCNMinimap_Hide },
        }
        
        local dropdown = getglobal("WowCNMinimapDropdown")
        if not dropdown then
            dropdown = CreateFrame("Frame", "WowCNMinimapDropdown", UIParent, "UIDropDownMenuTemplate")
        end
        
        UIDropDownMenu_Initialize(dropdown, function()
            for i = 1, table.getn(menu) do
                local info = {}
                info.text = menu[i].text
                info.isTitle = menu[i].isTitle or false
                if menu[i].func then
                    info.func = menu[i].func
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        
        ToggleDropDownMenu(1, nil, dropdown, "cursor")
    end
end

--[[
    WowCNMinimap_Hide - 隐藏小地图图标
]]
function WowCNMinimap_Hide()
    if gMinimapButton then
        gMinimapButton:Hide()
        WowCNConfig:Set("minimapHide", true)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ddddWowCNInput:|r 小地图图标已隐藏，使用 /wi minimap 可重新显示")
        -- 更新设置界面
        if WowCNConfig and WowCNConfig.UI then
            WowCNConfig.UI:Update()
        end
    end
end

--[[
    WowCNMinimap_Show - 显示小地图图标
]]
function WowCNMinimap_Show()
    if gMinimapButton then
        gMinimapButton:Show()
        WowCNConfig:Set("minimapHide", false)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ddddWowCNInput:|r 小地图图标已显示")
        -- 更新设置界面
        if WowCNConfig and WowCNConfig.UI then
            WowCNConfig.UI:Update()
        end
    end
end

--[[
    WowCNMinimap_Toggle - 切换小地图图标显示/隐藏
]]
function WowCNMinimap_Toggle()
    if WowCNConfig:Get("minimapHide") then
        WowCNMinimap_Show()
    else
        WowCNMinimap_Hide()
    end
end

--[[
    WowCNMinimap_Init - 初始化小地图按钮
    说明: 创建按钮并设置初始状态
]]
function WowCNMinimap_Init()
    if gMinimapButton then return end
    
    local button = CreateFrame("Button", "WowCNMinimapButton", Minimap)
    button:SetWidth(32)
    button:SetHeight(32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    
    local icon = button:CreateTexture(button:GetName() .. "Icon", "BACKGROUND")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    icon:SetTexture("Interface\\AddOns\\WowCNInput\\Textures\\cn.blp")
    
    local highlight = button:CreateTexture(button:GetName() .. "Highlight", "HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetAllPoints(button)
    highlight:SetBlendMode("ADD")
    
    local overlay = button:CreateTexture(button:GetName() .. "Overlay", "OVERLAY")
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetWidth(56)
    overlay:SetHeight(56)
    overlay:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    
    button:SetScript("OnEnter", WowCNMinimap_OnEnter)
    button:SetScript("OnLeave", WowCNMinimap_OnLeave)
    button:SetScript("OnMouseDown", WowCNMinimap_OnMouseDown)
    button:SetScript("OnMouseUp", WowCNMinimap_OnMouseUp)
    button:SetScript("OnUpdate", WowCNMinimap_OnUpdate)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", WowCNMinimap_OnClick)
    
    button:RegisterForDrag("LeftButton")
    button:SetMovable(true)
    
    gMinimapButton = button
    
    local savedPos = WowCNConfig:Get("minimapPos")
    if savedPos then
        WowCNMinimap_SetPosition(savedPos)
    else
        WowCNMinimap_SetPosition(180)
    end
    
    if WowCNConfig:Get("minimapHide") then
        button:Hide()
    end
    
    WowCNMinimap_UpdateIcon()
    
    WowCNInput_Debug("小地图按钮初始化完成")
end
