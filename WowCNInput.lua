--------------------------------
-- WowCNInput
-- 作者：Wigmox
--------------------------------

local G_PAGE = 1
local cur_can = {}
local currentCode = ""
local page_tail = 0


local TB = Pinyin_Dict or {}
local HL_COLOR = '|cff00dddd'


local isReplacing = false
local IME_ENABLED = true
local hookedBoxes = {}


local isChatMoved = false
local editBoxOrigPoints = {}
local editBoxOrigWidth = 0
local chatFrame1OrigPoints = {}
local chatFrame1OrigWidth = 0
local chatFrame1OrigHeight = 0

local function wciprint(msg)
    DEFAULT_CHAT_FRAME:AddMessage("WowCNInput: "..msg, 0.0, 0.9, 0.9)
end


local targetBoxes = {
    "ChatFrameEditBox",
    "SendMailNameEditBox",
    "SendMailSubjectEditBox",
    "SendMailBodyEditBox",
}


local function HookAllKnownBoxes()
    for i = 1, table.getn(targetBoxes) do
        local box = getglobal(targetBoxes[i])
        if box and not hookedBoxes[box] then
            HookNativeEditBox(box)
        end
    end
end

function WowCNInput_OnLoad()
    this:RegisterEvent("VARIABLES_LOADED")
    this:RegisterEvent("ADDON_LOADED")
    this:RegisterEvent("MAIL_SHOW")
    this:RegisterEvent("AUCTION_HOUSE_SHOW")
    
    wciprint("中文输入法 已加载！")

    wciprint("输入字母自动弹出候选框。空格键选第1个字，数字键1-0可手动选取。")
    wciprint("翻页：英文模式',' 或 '-' 上一页，'.' 或 '=' 下一页。")
    wciprint("开关：输入 /wi 关闭/开启中文输入。")
    
    SlashCmdList["WCI_SWITCH"] = function()
        IME_ENABLED = not IME_ENABLED
        if IME_ENABLED then 
            wciprint("输入法已【开启】") 
        else 
            wciprint("输入法已【关闭】") 
            WowCNInput:Hide() 
        end
    end
    SLASH_WCI_SWITCH1 = "/winput"
    SLASH_WCI_SWITCH2 = "/wi"
end

function WowCNInput_OnEvent(event)
    if event == "VARIABLES_LOADED" then
        if Pinyin then TB = Pinyin_Dict end
        HookAllKnownBoxes()
    elseif event == "ADDON_LOADED" or event == "MAIL_SHOW" or event == "AUCTION_HOUSE_SHOW" then

        HookAllKnownBoxes()
    end
end


function HookNativeEditBox(box)
    if not box then return end
    if hookedBoxes[box] then return end
    hookedBoxes[box] = true
    
    local orig_OnTextChanged = box:GetScript("OnTextChanged")
    local orig_OnEditFocusGained = box:GetScript("OnEditFocusGained")
    local orig_OnEditFocusLost = box:GetScript("OnEditFocusLost")
    
    box:SetScript("OnEditFocusGained", function()
        if orig_OnEditFocusGained then orig_OnEditFocusGained() end
        
    end)

    box:SetScript("OnEditFocusLost", function()
        WowCNInput:Hide()
        
        if orig_OnEditFocusLost then orig_OnEditFocusLost() end
    end)

    box:SetScript("OnTextChanged", function()
        if orig_OnTextChanged then orig_OnTextChanged() end
        if not IME_ENABLED or isReplacing then return end
        
        local text = this:GetText()
        local len = string.len(text)
        
        if len == 0 then
            WowCNInput:Hide()
            return
        end


        if not TB or not next(TB) then
            TB = Pinyin_Dict or {}
        end


        local lastChar = string.sub(text, len, len)
        local isLetter = (lastChar >= "a" and lastChar <= "z") or (lastChar >= "A" and lastChar <= "Z")
        

        local prevText = string.sub(text, 1, len - 1)
        local s1, e1, prevLetters = string.find(prevText, "([a-zA-Z]+)$")
        

        if prevLetters and not isLetter then
            local lowerCode = string.lower(prevLetters)
            if TB[lowerCode] then
                cur_can = TB[lowerCode]
		-- local cur_can = TB[lowerCode]
                local total_count = table.getn(cur_can)
                

                local num = tonumber(lastChar)
                if num then
                    local idx = (num == 0) and 10 or num
                    local absIdx = (G_PAGE - 1) * 10 + idx
                    if cur_can[absIdx] then
                        isReplacing = true
                        this:SetText(string.sub(prevText, 1, string.len(prevText) - string.len(prevLetters)) .. cur_can[absIdx])
                        isReplacing = false
                        WowCNInput:Hide()
                        return
                    end
                end
                

                if lastChar == " " then
                    local absIdx = (G_PAGE - 1) * 10 + 1 
                    if cur_can[absIdx] then
                        isReplacing = true
                        this:SetText(string.sub(prevText, 1, string.len(prevText) - string.len(prevLetters)) .. cur_can[absIdx])
                        isReplacing = false
                        WowCNInput:Hide()
                        return
                    end
                end
                

                if lastChar == "=" or lastChar == "." then
                    if (G_PAGE * 10) < total_count then G_PAGE = G_PAGE + 1 end
                    isReplacing = true
                    this:SetText(prevText)
                    isReplacing = false
                    UpdateCandidateDisplay(this, lowerCode)
                    return
                elseif lastChar == "-" or lastChar == "," then
                    if G_PAGE > 1 then G_PAGE = G_PAGE - 1 end
                    isReplacing = true
                    this:SetText(prevText)
                    isReplacing = false
                    UpdateCandidateDisplay(this, lowerCode)
                    return
                end
            end
        end
        

        if not prevLetters and not isLetter and TB[lastChar] then
            isReplacing = true
            this:SetText(prevText .. TB[lastChar][1])
            isReplacing = false
            WowCNInput:Hide()
            return
        end


        local s2, e2, currentLetters = string.find(text, "([a-zA-Z]+)$")
        if currentLetters then
            local lowerCode = string.lower(currentLetters)

            if currentCode ~= lowerCode then
                G_PAGE = 1 
            end
            UpdateCandidateDisplay(this, lowerCode)
        else
            WowCNInput:Hide()
        end
    end)
end

function UpdateCandidateDisplay(box, inputCode)
    cur_can = TB[inputCode] or {}
    currentCode = inputCode
    
    if WowCNInput.currentBox ~= box then
        WowCNInput:ClearAllPoints()

        WowCNInput:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -2)
        WowCNInput.currentBox = box
    end
    
    local total_count = table.getn(cur_can)
    if total_count == 0 then
        CanArea:SetText(HL_COLOR .. inputCode .. "|r: ...")
        InfoArea:SetText("0/0")
        WowCNInput:Show()
        return
    end
    
    page_tail = math.floor((total_count + 9) / 10)
    if G_PAGE > page_tail then G_PAGE = page_tail end
    if G_PAGE < 1 then G_PAGE = 1 end
    
    local startIdx = (G_PAGE - 1) * 10 + 1
    local cantext = HL_COLOR .. inputCode .. "|r: "
    

    for i = 1, 10 do
        local word = cur_can[startIdx + i - 1]
        if word then
            local numLabel = math.mod(i, 10)
            if i == 1 then

                cantext = cantext .. HL_COLOR .. numLabel .. "." .. word .. "|r "
            else
                cantext = cantext .. numLabel .. "." .. word .. " "
            end
        else
            break
        end
    end
    
    CanArea:SetText(cantext)
    InfoArea:SetText(G_PAGE .. "/" .. page_tail)
    WowCNInput:Show()
end