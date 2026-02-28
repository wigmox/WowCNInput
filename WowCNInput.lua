--------------------------------
-- WowCNInput
-- 作者：Wigmox
--------------------------------

-- [按键绑定中文字符串] 用于 Bindings.xml 显示中文
BINDING_HEADER_WOWCNINPUT = "WowCNInput 中文输入法"
BINDING_NAME_TOGGLEWOWCNINPUT = "切换中文输入法"

-- [全局变量] 使用 g 前缀标识
local gPage = 1                    -- 当前页码
local gCurCandidates = {}          -- 当前候选词列表
local gCurrentCode = ""            -- 当前输入编码
local gPageTail = 0                -- 总页数

-- 确保词库被正确加载
local TB = Pinyin_Dict or {}
local HL_COLOR = '|cff00dddd'

-- 防止在替换文本时触发死循环的锁
local isReplacing = false
local IME_ENABLED = true
local hookedBoxes = {}

-- 候选模式状态跟踪
local isCandidateMode = false
local isEnglishConfirmed = false   -- 是否已确认输入英文（按回车后）
local confirmedEnglishLength = 0   -- 已确认文本的长度，用于跳过已确认部分


-- [目标编辑框列表] 所有可能需要输入中文的编辑框
local targetBoxes = {
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
    wciprint - 输出调试信息到聊天框
    参数: msg - 要输出的消息字符串
]]
local function wciprint(msg)
    DEFAULT_CHAT_FRAME:AddMessage("WowCNInput: "..msg, 0.0, 0.9, 0.9)
end

--[[
    ClearCandidateMode - 清除候选模式状态
]]
local function ClearCandidateMode()
    isCandidateMode = false
    isEnglishConfirmed = false
    confirmedEnglishLength = 0
    gPage = 1
    gCurCandidates = {}
    gCurrentCode = ""
    WowCNInput:Hide()
end

--[[
    ConfirmEnglishInput - 确认输入英文（按回车后）
    参数: textLen - 当前文本长度
    说明: 候选模式下按回车确认输入英文，不发送消息，可继续输入拼音
]]
local function ConfirmEnglishInput(textLen)
    isCandidateMode = false
    isEnglishConfirmed = true
    confirmedEnglishLength = textLen
    gPage = 1
    gCurCandidates = {}
    gCurrentCode = ""
    WowCNInput:Hide()
end

--[[
    GetDynamicCandidates - 获取从第一个字母开始所有可能长度的候选词
    参数: inputLetters - 输入的字母字符串
    返回: allCandidates - 候选词列表
          matchedLetters - 匹配的字母列表
          remainingLetters - 剩余字母
]]
local function GetDynamicCandidates(inputLetters)
    if not inputLetters or string.len(inputLetters) == 0 then
        return {}, {}, nil
    end
    
    local allCandidates = {}
    local matchedLetters = {}
    local seenWords = {}           -- 用于 O(1) 去重的高效哈希表
    local lastMatchedLetters = nil
    
    -- 从最长到最短尝试匹配（从第一个字母开始）
    for len = string.len(inputLetters), 1, -1 do
        local subLetters = string.sub(inputLetters, 1, len)
        local matchedCandidates = TB[subLetters]
        
        -- 检查是否有候选词
        if matchedCandidates and matchedCandidates[1] then
            -- 记录最长匹配的字母（用于计算剩余字母）
            if not lastMatchedLetters then
                lastMatchedLetters = subLetters
            end
            
            -- 高效去重并添加候选词 (O(1) 而非 O(N²))
            for i = 1, table.getn(matchedCandidates) do
                local candidateWord = matchedCandidates[i]
                if not seenWords[candidateWord] then
                    seenWords[candidateWord] = true
                    table.insert(allCandidates, candidateWord)
                    table.insert(matchedLetters, subLetters)
                end
            end
        end
    end
    
    -- 计算剩余字母（最长匹配后的剩余部分）
    local remainingLetters = nil
    if lastMatchedLetters then
        local matchedLen = string.len(lastMatchedLetters)
        if matchedLen < string.len(inputLetters) then
            remainingLetters = string.sub(inputLetters, matchedLen + 1)
        end
    end
    
    -- 如果没有任何候选词，返回空
    if table.getn(allCandidates) == 0 then
        return {}, {}, inputLetters
    end
    
    return allCandidates, matchedLetters, remainingLetters
end

--[[
    GetCodeLengthForWord - 根据候选词获取对应的字母长度
    参数: candidateWord - 候选词
          matchedLetters - 匹配的字母列表
    返回: 对应的字母长度
]]
local function GetCodeLengthForWord(candidateWord, matchedLetters)
    if not matchedLetters or table.getn(matchedLetters) == 0 then
        return 0
    end
    
    -- 遍历所有匹配的字母，找到包含这个词的字母
    for i = 1, table.getn(matchedLetters) do
        local curMatchedLetters = matchedLetters[i]
        if TB[curMatchedLetters] then
            for j = 1, table.getn(TB[curMatchedLetters]) do
                if TB[curMatchedLetters][j] == candidateWord then
                    return string.len(curMatchedLetters)
                end
            end
        end
    end
    
    -- 如果没找到，返回第一个字母的长度
    return string.len(matchedLetters[1])
end

--[[
    HookAllKnownBoxes - 核心遍历挂载函数
    遍历所有目标编辑框并挂载输入法处理逻辑
]]
local function HookAllKnownBoxes()
    for i = 1, table.getn(targetBoxes) do
        local box = getglobal(targetBoxes[i])
        if box and not hookedBoxes[box] then
            HookNativeEditBox(box)
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
    
    wciprint("中文输入法 已加载！")
    wciprint("已适配：宏、好友、屏蔽、公会等全部输入框。")
    wciprint("输入字母自动弹出候选框。空格键选第1个字，数字键1-0可手动选取。")
    wciprint("翻页：英文模式',' 或 '-' 上一页，'.' 或 '=' 下一页。")
    wciprint("开关：输入 /wi 或在按键设置中绑定快捷键")
end

--[[
    WowCNInput_Toggle - 切换输入法开关状态
    说明: 供按键绑定和斜杠命令调用
]]
function WowCNInput_Toggle()
    IME_ENABLED = not IME_ENABLED
    if IME_ENABLED then
        -- 使用 |cff00ff00 把【开启】变成绿色，|r 恢复默认颜色
        wciprint("中文输入已|cff00ff00【开启】|r")
    else 
        -- 使用 |cffff0000 把【关闭】变成红色，|r 恢复默认颜色
        wciprint("中文输入已|cffff0000【关闭】|r")
        -- 关闭时清除所有状态并隐藏候选框
        ClearCandidateMode()
    end
end

--[[
    斜杠命令注册
]]
SlashCmdList["WCI_SWITCH"] = WowCNInput_Toggle
SLASH_WCI_SWITCH1 = "/winput"
SLASH_WCI_SWITCH2 = "/wi"

--[[
    WowCNInput_OnEvent - 事件处理函数
    参数: event - 事件名称
]]
function WowCNInput_OnEvent(event)
    if event == "VARIABLES_LOADED" then
        if Pinyin_Dict then TB = Pinyin_Dict end
        HookAllKnownBoxes()
    elseif event == "ADDON_LOADED" or event == "MAIL_SHOW" or event == "AUCTION_HOUSE_SHOW" then
        -- 当任何系统模块（如宏界面、公会界面）加载时，立刻尝试挂载所有目标编辑框
        HookAllKnownBoxes()
    end
end

--[[
    HookNativeEditBox - 核心劫持函数
    参数: box - 要挂载的编辑框对象
    功能: 劫持编辑框的文本变化、获取焦点、失去焦点事件
]]
function HookNativeEditBox(box)
    if not box then return end
    if hookedBoxes[box] then return end
    hookedBoxes[box] = true
    
    local origOnTextChanged = box:GetScript("OnTextChanged")
    local origOnEditFocusGained = box:GetScript("OnEditFocusGained")
    local origOnEditFocusLost = box:GetScript("OnEditFocusLost")
    local origOnEnterPressed = box:GetScript("OnEnterPressed")
    
    box:SetScript("OnEditFocusGained", function()
        if origOnEditFocusGained then origOnEditFocusGained() end
        
        -- 主聊天框防遮挡逻辑
        if this == ChatFrameEditBox and not isChatMoved then
            this:ClearAllPoints()
            this:SetPoint("TOP", UIParent, "TOP", 0, -50)
            this:SetWidth(500)
            this:SetHeight(30)
        end
    end)

    box:SetScript("OnEditFocusLost", function()
        -- [核心] 只有在非英文确认状态下才清除候选模式
        -- 保留 confirmedEnglishLength 用于后续拼音匹配
        if not isEnglishConfirmed then
            ClearCandidateMode()
        else
            -- 英文确认状态只隐藏候选框，不清除状态
            WowCNInput:Hide()
        end
        if origOnEditFocusLost then origOnEditFocusLost() end
    end)

    -- [核心] 回车键拦截：候选模式下按回车确认输入英文，不发送消息
    box:SetScript("OnEnterPressed", function()
        -- 全局开关判断
        if IME_ENABLED and isCandidateMode then
            -- 确认输入英文，记录当前整个文本的长度
            local text = this:GetText()
            local textLen = string.len(text)
            ConfirmEnglishInput(textLen)
            -- 不调用原始函数，阻止发送消息
            return
        end
        
        -- 非候选模式，调用原始函数发送消息
        if origOnEnterPressed then origOnEnterPressed() end
    end)

    box:SetScript("OnTextChanged", function()
        if origOnTextChanged then origOnTextChanged() end
        if not IME_ENABLED or isReplacing then return end
        
        local text = this:GetText()
        local textLen = string.len(text)
        
        if textLen == 0 then
            ClearCandidateMode()
            return
        end

        -- 确保词库指针正常
        if not TB or not next(TB) then
            TB = Pinyin_Dict or {}
        end

        -- 区分字母与符号
        local lastChar = string.sub(text, textLen, textLen)
        local isLetter = (lastChar >= "a" and lastChar <= "z") or (lastChar >= "A" and lastChar <= "Z")
        
        -- [核心] 如果用户已确认输入英文，后续非字母输入不触发选词
        if isEnglishConfirmed then
            if isLetter then
                -- 用户开始输入新的字母，检查是否需要重置状态
                -- 只有当新输入的字母在已确认英文之后时，才开始新的候选模式
                if textLen > confirmedEnglishLength then
                    -- 重置候选模式状态，但保留 confirmedEnglishLength 用于拼音匹配
                    isEnglishConfirmed = false
                    isCandidateMode = true
                else
                    -- 用户删除了部分内容，重置状态
                    ClearCandidateMode()
                    return
                end
            else
                -- 非字母输入（空格、数字等），不选词，直接返回
                return
            end
        end
        
        -- 获取去掉最后一个字符后的文本
        local prevText = string.sub(text, 1, textLen - 1)
        
        -- [核心] 如果有已确认的英文，只匹配其后新输入的部分
        local searchPrevText = prevText
        if confirmedEnglishLength > 0 then
            searchPrevText = string.sub(prevText, confirmedEnglishLength + 1)
        end
        
        local s1, e1, prevLetters = string.find(searchPrevText, "([a-zA-Z]+)$")
        
        -- 1：输入拼音，并且输入了非字母（数字选词、空格、或翻页符）
        if prevLetters and not isLetter then
            local lowerCode = string.lower(prevLetters)
            
            -- 使用动态分段匹配，更新全局候选词
            local candidates, matchedCodes, remaining = GetDynamicCandidates(lowerCode)
            gCurCandidates = candidates
            gCurrentCode = lowerCode
            
            if gCurCandidates and table.getn(gCurCandidates) > 0 then
                local totalCount = table.getn(gCurCandidates)
                
                -- [数字键选词]
                local num = tonumber(lastChar)
                if num then
                    local idx = (num == 0) and 10 or num
                    local absIdx = (gPage - 1) * 10 + idx
                    if gCurCandidates[absIdx] then
                        isReplacing = true
                        local selectedWord = gCurCandidates[absIdx]
                        local codeLen = GetCodeLengthForWord(selectedWord, matchedCodes)
                        
                        -- 保留已确认英文部分 + 替换匹配的拼音为候选词
                        local prefix = string.sub(prevText, 1, confirmedEnglishLength)
                        local beforeCode = string.sub(searchPrevText, 1, string.len(searchPrevText) - string.len(prevLetters))
                        local newText = prefix .. beforeCode .. selectedWord
                        
                        local actualRemainingCode = ""
                        if codeLen > 0 and codeLen < string.len(lowerCode) then
                            actualRemainingCode = string.sub(lowerCode, codeLen + 1)
                        end
                        
                        if actualRemainingCode and string.len(actualRemainingCode) > 0 then
                            newText = newText .. actualRemainingCode
                        end
                        
                        this:SetText(newText)
                        isReplacing = false
                        
                        if actualRemainingCode and string.len(actualRemainingCode) > 0 then
                            confirmedEnglishLength = string.len(prefix) + string.len(beforeCode) + string.len(selectedWord)
                            gPage = 1
                            UpdateCandidateDisplay(this, actualRemainingCode)
                        else
                            isCandidateMode = false
                            confirmedEnglishLength = 0
                            WowCNInput:Hide()
                        end
                        return
                    end
                end
                
                -- [空格键选第一个词]
                if lastChar == " " then
                    local absIdx = (gPage - 1) * 10 + 1 
                    if gCurCandidates[absIdx] then
                        isReplacing = true
                        -- 获取选中词对应的拼音长度
                        local selectedWord = gCurCandidates[absIdx]
                        local codeLen = GetCodeLengthForWord(selectedWord, matchedCodes)
                        
                        -- 保留已确认英文部分 + 替换匹配的拼音为候选词
                        local prefix = string.sub(prevText, 1, confirmedEnglishLength)
                        local beforeCode = string.sub(searchPrevText, 1, string.len(searchPrevText) - string.len(prevLetters))
                        local newText = prefix .. beforeCode .. selectedWord
                        
                        -- 计算剩余拼音（完整拼音 - 已选拼音）
                        local actualRemainingCode = ""
                        if codeLen > 0 and codeLen < string.len(lowerCode) then
                            actualRemainingCode = string.sub(lowerCode, codeLen + 1)
                        end
                        
                        -- 如果有剩余拼音，追加到输入框
                        if actualRemainingCode and string.len(actualRemainingCode) > 0 then
                            newText = newText .. actualRemainingCode
                        end
                        
                        this:SetText(newText)
                        isReplacing = false
                        
                        -- 如果有剩余拼音，继续显示候选词
                        if actualRemainingCode and string.len(actualRemainingCode) > 0 then
                            -- 更新已确认长度（选中词的长度）
                            confirmedEnglishLength = string.len(prefix) + string.len(beforeCode) + string.len(selectedWord)
                            -- 继续显示剩余拼音的候选词
                            gPage = 1
                            UpdateCandidateDisplay(this, actualRemainingCode)
                        else
                            isCandidateMode = false
                            confirmedEnglishLength = 0
                            WowCNInput:Hide()
                        end
                        return
                    end
                end
                
                -- [翻页键处理]
                if lastChar == "=" or lastChar == "." then
                    if (gPage * 10) < totalCount then gPage = gPage + 1 end
                    isReplacing = true
                    this:SetText(prevText)
                    isReplacing = false
                    UpdateCandidateDisplay(this, lowerCode)
                    return
                elseif lastChar == "-" or lastChar == "," then
                    if gPage > 1 then gPage = gPage - 1 end
                    isReplacing = true
                    this:SetText(prevText)
                    isReplacing = false
                    UpdateCandidateDisplay(this, lowerCode)
                    return
                end
            end
        end
        
        -- 2：直接输入标点符号（如输入逗号，变成全角逗号）
        if not prevLetters and not isLetter and TB[lastChar] then
            isReplacing = true
            this:SetText(prevText .. TB[lastChar][1])
            isReplacing = false
            WowCNInput:Hide()
            return
        end

        -- 3：正常输入字母，匹配并显示候选框
        local s2, e2, currentLetters = string.find(text, "([a-zA-Z]+)$")
        if currentLetters then
            -- [核心] 如果有已确认的英文，只匹配其后新输入的字母部分
            local searchLetters = currentLetters
            if confirmedEnglishLength > 0 then
                local afterConfirmed = string.sub(text, confirmedEnglishLength + 1)
                local s3, e3, newLetters = string.find(afterConfirmed, "([a-zA-Z]+)$")
                if newLetters then
                    searchLetters = newLetters
                else
                    -- 已确认英文后面没有字母，不显示候选框
                    WowCNInput:Hide()
                    return
                end
            end
            
            local lowerCode = string.lower(searchLetters)
            
            -- 用户删除了部分内容，重置状态
            if confirmedEnglishLength > 0 and string.len(text) < confirmedEnglishLength then
                confirmedEnglishLength = 0
            end

            if gCurrentCode ~= lowerCode then
                gPage = 1 
            end
            UpdateCandidateDisplay(this, lowerCode)
        else
            isCandidateMode = false
            confirmedEnglishLength = 0
            WowCNInput:Hide()
        end
    end)
end

--[[
    UpdateCandidateDisplay - 更新候选框显示
    参数: box - 当前编辑框对象
          inputCode - 输入的编码
]]
function UpdateCandidateDisplay(box, inputCode)
    -- 使用动态分段匹配获取候选词
    local candidates, matchedCodes, remaining = GetDynamicCandidates(inputCode)
    gCurCandidates = candidates
    gCurrentCode = inputCode
    
    -- 设置候选模式状态
    isCandidateMode = true
    if WowCNInput.currentBox ~= box then
        WowCNInput:ClearAllPoints()
        -- 候选框贴在输入框的"左下角"
        WowCNInput:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -2)
        WowCNInput.currentBox = box
    end
    
    LettersArea:SetText(HL_COLOR .. inputCode .. "|r")
    
    local totalCount = table.getn(gCurCandidates)
    if totalCount == 0 then
        -- 显示原始拼音，提示无匹配
        CanArea:SetText("...")
        InfoArea:SetText("0/0")
        WowCNInput:Show()
        return
    end
    
    gPageTail = math.floor((totalCount + 9) / 10)
    if gPage > gPageTail then gPage = gPageTail end
    if gPage < 1 then gPage = 1 end
    
    local startIdx = (gPage - 1) * 10 + 1
    local cantext = ""
    
    -- 组装候选词字符串（不包含拼音）
    for i = 1, 10 do
        local candidateWord = gCurCandidates[startIdx + i - 1]
        if candidateWord then
            local numLabel = math.mod(i, 10)
            if i == 1 then
                -- 第一个候选词高亮显示
                cantext = cantext .. HL_COLOR .. numLabel .. "." .. candidateWord .. "|r "
            else
                cantext = cantext .. numLabel .. "." .. candidateWord .. " "
            end
        else
            break
        end
    end
    
    -- 第二行：显示候选词
    CanArea:SetText(cantext)
    InfoArea:SetText(gPage .. "/" .. gPageTail)
    WowCNInput:Show()
end
