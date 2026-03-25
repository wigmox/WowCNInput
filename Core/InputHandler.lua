--------------------------------
-- WowCNInput 输入处理器
-- 功能: 编辑框挂载、输入事件处理、UI显示
--------------------------------

-- [全局状态表]
WowCNState = {
    imeEnabled = true,              -- 输入法开关状态
    isReplacing = false,            -- 防止在替换文本时触发死循环的锁
    isCandidateMode = false,        -- 候选模式状态跟踪
    isEnglishConfirmed = false,     -- 是否已确认输入英文（按回车后）
    confirmedEnglishLength = 0,     -- 已确认文本的长度，用于跳过已确认部分
    confirmedText = "",             -- 已确认的英文文本
    gPage = 1,                      -- 当前页码
    gCurCandidates = {},            -- 当前候选词列表
    gCurrentCode = "",              -- 当前输入编码
    gPageTail = 0,                  -- 总页数
}

-- [用户词库学习状态]
WowCNLearnState = {
    fullInputCode = "",             -- 完整输入编码
    selectedWords = {},             -- 选中的词列表
    selectCount = 0,                -- 选词次数
}

-- [已挂载编辑框记录]
local hookedBoxes = {}

--[[
    WowCNInput_IsHooked - 检查编辑框是否已挂载
    参数: box - 编辑框对象
    返回: boolean - 是否已挂载
]]
function WowCNInput_IsHooked(box)
    return hookedBoxes[box] == true
end

--[[
    WowCNInput_ClearState - 清除输入状态
]]
function WowCNInput_ClearState()
    WowCNState.isCandidateMode = false
    WowCNState.isEnglishConfirmed = false
    WowCNState.confirmedEnglishLength = 0
    WowCNState.confirmedText = ""
    WowCNState.gPage = 1
    WowCNState.gCurCandidates = {}
    WowCNState.gCurrentCode = ""
    
    -- 清除学习状态
    WowCNLearnState.fullInputCode = ""
    WowCNLearnState.selectedWords = {}
    WowCNLearnState.selectCount = 0
end

--[[
    WowCNInput_ConfirmEnglish - 确认输入英文
    参数: textLen - 当前文本长度
]]
function WowCNUI_UpdateDisplay(box, inputCode)
    WowCNInput_Debug("WowCNUI_UpdateDisplay: " .. tostring(inputCode))
    
    local candidates, matchedCodes = WowCNDB_DynamicMatch(inputCode)
    WowCNState.gCurCandidates = candidates
    WowCNState.gCurrentCode = inputCode
    
    WowCNInput_Debug("  候选词数量: " .. table.getn(candidates))
    
    WowCNState.isCandidateMode = true
    if WowCNInput.currentBox ~= box then
        WowCNInputFrame:ClearAllPoints()
        WowCNInputFrame:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -2)
        WowCNInput.currentBox = box
    end
    
    -- 计算匹配长度（用于高亮）
    local matchedLen = 0
    if candidates and table.getn(candidates) > 0 and matchedCodes and table.getn(matchedCodes) > 0 then
        -- 找到最长的匹配编码
        for i = 1, table.getn(matchedCodes) do
            local codeLen = string.len(matchedCodes[i])
            if codeLen > matchedLen then
                matchedLen = codeLen
            end
        end
    end
    
    -- 格式化拼音并高亮匹配部分
    local formattedPinyin = WowCNDB_FormatCodeWithSeparator(inputCode)
    local pinyinDisplay
    
    if matchedLen > 0 and matchedLen < string.len(inputCode) then
        -- 部分匹配：高亮匹配部分，未匹配部分用灰色
        local matchedPart = string.sub(inputCode, 1, matchedLen)
        local unmatchedPart = string.sub(inputCode, matchedLen + 1)
        local formattedMatched = WowCNDB_FormatCodeWithSeparator(matchedPart)
        local formattedUnmatched = WowCNDB_FormatCodeWithSeparator(unmatchedPart)
        -- 移除未匹配部分开头的分隔符
        if string.sub(formattedUnmatched, 1, 1) == "'" then
            formattedUnmatched = string.sub(formattedUnmatched, 2)
        end
        pinyinDisplay = WowCNConfig:Get("hlColor") .. formattedMatched .. "|r|cffaaaaaa" .. formattedUnmatched .. "|r"
    else
        -- 完整匹配或无匹配：全部高亮
        pinyinDisplay = WowCNConfig:Get("hlColor") .. formattedPinyin .. "|r"
    end
    
    LettersArea:SetText(pinyinDisplay)
    
    local totalCount = table.getn(WowCNState.gCurCandidates)
    if totalCount == 0 then
        CanArea:SetText("...")
        InfoArea:SetText("0/0")
        WowCNInputFrame:Show()
        return
    end
    
    WowCNState.gPageTail = math.floor((totalCount + 9) / 10)
    if WowCNState.gPage > WowCNState.gPageTail then WowCNState.gPage = WowCNState.gPageTail end
    if WowCNState.gPage < 1 then WowCNState.gPage = 1 end
    
    local startIdx = (WowCNState.gPage - 1) * 10 + 1
    local cantext = ""
    
    for i = 1, 10 do
        local candidateWord = WowCNState.gCurCandidates[startIdx + i - 1]
        if candidateWord then
            local numLabel = math.mod(i, 10)
            if i == 1 then
                cantext = cantext .. WowCNConfig:Get("hlColor") .. numLabel .. "." .. candidateWord .. "|r "
            else
                cantext = cantext .. numLabel .. "." .. candidateWord .. " "
            end
        else
            break
        end
    end
    
    CanArea:SetText(cantext)
    InfoArea:SetText(WowCNState.gPage .. "/" .. WowCNState.gPageTail)
    WowCNInputFrame:Show()
end

--[[
    WowCNInput_ConfirmEnglish - 确认输入英文
    参数: text - 当前文本
]]
local function WowCNInput_ConfirmEnglish(text)
    WowCNState.isCandidateMode = false
    WowCNState.isEnglishConfirmed = true
    WowCNState.confirmedEnglishLength = string.len(text)
    WowCNState.confirmedText = text
    WowCNState.gPage = 1
    WowCNState.gCurCandidates = {}
    WowCNState.gCurrentCode = ""
    WowCNInputFrame:Hide()
end

--[[
    WowCNInput_DoSelectWord - 执行选词操作
    参数: box - 编辑框对象
          prevText - 选词前的文本
          searchPrevText - 搜索用的前置文本
          prevLetters - 匹配的拼音
          lowerCode - 小写编码
          selectedWord - 选中的词
          matchedCodes - 匹配的编码列表
    返回: remainingCode - 剩余编码（如果有）
]]
local function WowCNInput_DoSelectWord(box, prevText, searchPrevText, prevLetters, lowerCode, selectedWord, matchedCodes)
    WowCNInput_Debug("WowCNInput_DoSelectWord")
    WowCNInput_Debug("  lowerCode: " .. tostring(lowerCode))
    WowCNInput_Debug("  selectedWord: " .. tostring(selectedWord))
    
    local codeLen, learnLetters, remainingCode = WowCNDB_SelectWord(lowerCode, selectedWord, matchedCodes)
    
    WowCNInput_Debug("  codeLen: " .. tostring(codeLen))
    WowCNInput_Debug("  remainingCode: " .. tostring(remainingCode))
    
    -- [学习逻辑] 记录完整输入和选中的词
    -- 第一次选词时记录完整输入编码
    if WowCNLearnState.selectCount == 0 then
        WowCNLearnState.fullInputCode = lowerCode
    end
    
    -- 记录选中的词
    table.insert(WowCNLearnState.selectedWords, selectedWord)
    WowCNLearnState.selectCount = WowCNLearnState.selectCount + 1
    
    local newText, newConfirmedLen = WowCNDB_BuildSelectedText(
        prevText, searchPrevText, prevLetters, selectedWord, remainingCode, WowCNState.confirmedEnglishLength
    )
    
    WowCNInput_Debug("  newText: " .. tostring(newText))
    
    WowCNState.isReplacing = true
    box:SetText(newText)
    WowCNState.isReplacing = false
    
    if remainingCode and string.len(remainingCode) > 0 then
        WowCNState.confirmedEnglishLength = newConfirmedLen
        WowCNState.gPage = 1
        return remainingCode
    else
        -- [学习逻辑] 选词完成，判断是否需要学习
        -- 只有多次选词才学习（单次选词说明词库已有该词）
        -- 且用户词库功能已启用
        if WowCNLearnState.selectCount > 1 and WowCNConfig:Get("userDictEnabled") then
            local fullWord = table.concat(WowCNLearnState.selectedWords)
            WowCNDB_LearnWord(WowCNLearnState.fullInputCode, fullWord)
        end
        
        -- 重置学习状态
        WowCNLearnState.fullInputCode = ""
        WowCNLearnState.selectedWords = {}
        WowCNLearnState.selectCount = 0
        
        WowCNState.isCandidateMode = false
        WowCNState.confirmedEnglishLength = 0
        return nil
    end
end

--[[
    WowCNInput_DoPageTurn - 执行翻页操作
    参数: box - 编辑框对象
          prevText - 翻页前的文本
          lowerCode - 当前编码
          totalCount - 候选词总数
          direction - 翻页方向 ("next" 或 "prev")
]]
local function WowCNInput_DoPageTurn(box, prevText, lowerCode, totalCount, direction)
    if direction == "next" then
        if (WowCNState.gPage * 10) < totalCount then
            WowCNState.gPage = WowCNState.gPage + 1
        end
    else
        if WowCNState.gPage > 1 then
            WowCNState.gPage = WowCNState.gPage - 1
        end
    end
    
    WowCNState.isReplacing = true
    box:SetText(prevText)
    WowCNState.isReplacing = false
    WowCNUI_UpdateDisplay(box, lowerCode)
end

--[[
    WowCNInput_HookEditBox - 核心挂载函数
    参数: box - 要挂载的编辑框对象
]]
function WowCNInput_HookEditBox(box)
    if not box then return end
    if hookedBoxes[box] then return end
    hookedBoxes[box] = true
    
    local origOnTextChanged = box:GetScript("OnTextChanged")
    local origOnEditFocusGained = box:GetScript("OnEditFocusGained")
    local origOnEditFocusLost = box:GetScript("OnEditFocusLost")
    local origOnEnterPressed = box:GetScript("OnEnterPressed")
    
    box:SetScript("OnEditFocusGained", function()
        if origOnEditFocusGained then origOnEditFocusGained() end
        
        -- 聊天输入框移至顶部（根据配置）
        if this == ChatFrameEditBox and WowCNConfig:Get("chatTop") then
            this:ClearAllPoints()
            this:SetPoint("TOP", UIParent, "TOP", 0, -50)
            this:SetWidth(500)
            this:SetHeight(30)
        end
    end)

    box:SetScript("OnEditFocusLost", function()
        if not WowCNState.isEnglishConfirmed then
            WowCNInput_ClearState()
            WowCNInputFrame:Hide()
        else
            WowCNInputFrame:Hide()
        end
        if origOnEditFocusLost then origOnEditFocusLost() end
    end)

    box:SetScript("OnEnterPressed", function()
        -- 如果处于候选模式，阻止默认行为
        if WowCNState.imeEnabled and WowCNState.isCandidateMode then
            WowCNState.blockEnterNewline = true  -- 设置标志阻止换行
            local text = this:GetText()
            WowCNInput_ConfirmEnglish(text)
            return
        end
        
        -- 清除标志
        WowCNState.blockEnterNewline = false
        
        if origOnEnterPressed then origOnEnterPressed() end
    end)

    box:SetScript("OnTextChanged", function()
        if origOnTextChanged then origOnTextChanged() end
        if not WowCNState.imeEnabled or WowCNState.isReplacing then return end
        
        local text = this:GetText()
        local textLen = string.len(text)
        
        if textLen == 0 then
            WowCNInput_ClearState()
            WowCNInputFrame:Hide()
            return
        end

        local lastChar = string.sub(text, textLen, textLen)
        local isLetter = (lastChar >= "a" and lastChar <= "z") or (lastChar >= "A" and lastChar <= "Z")
        
        -- [核心] 多行编辑框回车处理
        -- 如果处于候选模式且检测到换行符，说明用户按了回车
        if WowCNState.isCandidateMode and lastChar == "\n" then
            -- 移除换行符
            local prevText = string.sub(text, 1, textLen - 1)
            WowCNState.isReplacing = true
            this:SetText(prevText)
            WowCNState.isReplacing = false
            -- 确认英文
            WowCNInput_ConfirmEnglish(prevText)
            return
        end
        
        -- [核心] 已确认英文状态处理
        if WowCNState.isEnglishConfirmed then
            local confirmedText = WowCNState.confirmedText
            
            -- 检查当前文本是否以已确认文本开头
            if string.len(confirmedText) > 0 and string.find(text, "^" .. confirmedText) then
                -- 当前文本以已确认文本开头，检查后面是否有新输入
                local afterConfirmed = string.sub(text, string.len(confirmedText) + 1)
                
                if string.len(afterConfirmed) == 0 then
                    -- 没有新输入，隐藏候选框
                    WowCNInputFrame:Hide()
                    return
                end
                
                -- 检查新输入部分是否包含换行符
                local hasNewline = string.find(afterConfirmed, "\n")
                if hasNewline then
                    -- 新输入包含换行符，更新 confirmedText（包含换行符）
                    WowCNState.confirmedText = text
                    WowCNInputFrame:Hide()
                    return
                end
                
                -- 检查新输入部分是否是字母
                local startPos, endPos, newLetters = string.find(afterConfirmed, "([a-zA-Z]+)$")
                if newLetters then
                    -- 有新字母输入，进入候选模式
                    WowCNState.isCandidateMode = true
                    local lowerCode = string.lower(newLetters)
                    if WowCNState.gCurrentCode ~= lowerCode then
                        WowCNState.gPage = 1
                    end
                    WowCNUI_UpdateDisplay(this, lowerCode)
                else
                    -- 新输入不是字母，检查是否是选词操作
                    local prevLetters = nil
                    local beforeLastChar = nil
                    
                    -- 如果是空格选词，去掉空格后检查
                    if lastChar == " " then
                        beforeLastChar = string.sub(afterConfirmed, 1, string.len(afterConfirmed) - 1)
                        startPos, endPos, prevLetters = string.find(beforeLastChar, "([a-zA-Z]+)$")
                    else
                        -- 数字选词，去掉最后一个数字字符
                        beforeLastChar = string.sub(afterConfirmed, 1, string.len(afterConfirmed) - 1)
                        startPos, endPos, prevLetters = string.find(beforeLastChar, "([a-zA-Z]+)$")
                    end
                    
                    if prevLetters then
                        local lowerCode = string.lower(prevLetters)
                        local candidates, matchedCodes = WowCNDB_DynamicMatch(lowerCode)
                        
                        if candidates and table.getn(candidates) > 0 then
                            local num = tonumber(lastChar)
                            local selectedIdx = nil
                            
                            if num then
                                local idx = (num == 0) and 10 or num
                                selectedIdx = (WowCNState.gPage - 1) * 10 + idx
                            elseif lastChar == " " then
                                selectedIdx = (WowCNState.gPage - 1) * 10 + 1
                            end
                            
                            if selectedIdx and candidates[selectedIdx] then
                                local selectedWord = candidates[selectedIdx]
                                local codeLen, learnLetters, remainingCode = WowCNDB_SelectWord(lowerCode, selectedWord, matchedCodes)
                                
                                local replaceStart = string.len(confirmedText) + string.len(beforeLastChar) - string.len(prevLetters) + 1
                                local newText = string.sub(text, 1, replaceStart - 1) .. selectedWord
                                
                                if remainingCode and string.len(remainingCode) > 0 then
                                    newText = newText .. remainingCode
                                end
                                
                                WowCNState.isReplacing = true
                                this:SetText(newText)
                                WowCNState.isReplacing = false
                                
                                if remainingCode and string.len(remainingCode) > 0 then
                                    WowCNState.confirmedText = string.sub(newText, 1, replaceStart - 1 + string.len(selectedWord))
                                    WowCNState.isCandidateMode = true
                                    WowCNState.gPage = 1
                                    WowCNUI_UpdateDisplay(this, remainingCode)
                                else
                                    WowCNState.confirmedText = newText
                                    WowCNState.isCandidateMode = false
                                    WowCNInputFrame:Hide()
                                end
                                return
                            end
                        end
                    end
                    
                    -- 不是选词操作，隐藏候选框
                    WowCNInputFrame:Hide()
                end
            else
                -- 当前文本不以已确认文本开头（用户删除了已确认的部分）
                -- 重置状态，重新开始候选检测
                WowCNInput_ClearState()
                -- 重新检测当前文本
                local startPos, endPos, currentLetters = string.find(text, "([a-zA-Z]+)$")
                if currentLetters then
                    local lowerCode = string.lower(currentLetters)
                    if WowCNState.gCurrentCode ~= lowerCode then
                        WowCNState.gPage = 1
                    end
                    WowCNUI_UpdateDisplay(this, lowerCode)
                else
                    WowCNInputFrame:Hide()
                end
            end
            return
        end
        
        local prevText = string.sub(text, 1, textLen - 1)
        
        local searchPrevText = prevText
        if WowCNState.confirmedEnglishLength > 0 then
            searchPrevText = string.sub(prevText, WowCNState.confirmedEnglishLength + 1)
        end
        
        local startPos, endPos, prevLetters = string.find(searchPrevText, "([a-zA-Z]+)$")
        
        if prevLetters and not isLetter then
            local lowerCode = string.lower(prevLetters)
            
            local candidates, matchedCodes = WowCNDB_DynamicMatch(lowerCode)
            WowCNState.gCurCandidates = candidates
            WowCNState.gCurrentCode = lowerCode
            
            if WowCNState.gCurCandidates and table.getn(WowCNState.gCurCandidates) > 0 then
                local totalCount = table.getn(WowCNState.gCurCandidates)
                
                local num = tonumber(lastChar)
                if num then
                    local idx = (num == 0) and 10 or num
                    local absIdx = (WowCNState.gPage - 1) * 10 + idx
                    if WowCNState.gCurCandidates[absIdx] then
                        local selectedWord = WowCNState.gCurCandidates[absIdx]
                        local remaining = WowCNInput_DoSelectWord(this, prevText, searchPrevText, prevLetters, lowerCode, selectedWord, matchedCodes)
                        
                        if remaining then
                            WowCNUI_UpdateDisplay(this, remaining)
                        else
                            WowCNInputFrame:Hide()
                        end
                        return
                    end
                end
                
                if lastChar == " " then
                    local absIdx = (WowCNState.gPage - 1) * 10 + 1 
                    if WowCNState.gCurCandidates[absIdx] then
                        local selectedWord = WowCNState.gCurCandidates[absIdx]
                        local remaining = WowCNInput_DoSelectWord(this, prevText, searchPrevText, prevLetters, lowerCode, selectedWord, matchedCodes)
                        
                        if remaining then
                            WowCNUI_UpdateDisplay(this, remaining)
                        else
                            WowCNInputFrame:Hide()
                        end
                        return
                    end
                end
                
                if lastChar == "=" or lastChar == "." then
                    WowCNInput_DoPageTurn(this, prevText, lowerCode, totalCount, "next")
                    return
                elseif lastChar == "-" or lastChar == "," then
                    WowCNInput_DoPageTurn(this, prevText, lowerCode, totalCount, "prev")
                    return
                end
            end
        end
        
        if not prevLetters and not isLetter then
            local punct = WowCNDB_GetPunctuation(lastChar)
            if punct then
                WowCNState.isReplacing = true
                this:SetText(prevText .. punct)
                WowCNState.isReplacing = false
                WowCNInputFrame:Hide()
                return
            end
        end

        local startPos, endPos, currentLetters = string.find(text, "([a-zA-Z]+)$")
        if currentLetters then
            local searchLetters = currentLetters
            if WowCNState.confirmedEnglishLength > 0 then
                local afterConfirmed = string.sub(text, WowCNState.confirmedEnglishLength + 1)
                local startPos, endPos, newLetters = string.find(afterConfirmed, "([a-zA-Z]+)$")
                if newLetters then
                    searchLetters = newLetters
                else
                    WowCNInputFrame:Hide()
                    return
                end
            end
            
            local lowerCode = string.lower(searchLetters)
            
            if WowCNState.confirmedEnglishLength > 0 and string.len(text) < WowCNState.confirmedEnglishLength then
                WowCNState.confirmedEnglishLength = 0
            end

            if WowCNState.gCurrentCode ~= lowerCode then
                WowCNState.gPage = 1 
            end
            WowCNUI_UpdateDisplay(this, lowerCode)
        else
            WowCNInput_ClearState()
            WowCNInputFrame:Hide()
        end
    end)
end
