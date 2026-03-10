--------------------------------
-- WowCNInput IME 引擎
-- 功能: 词库管理 + 查询缓存 + 用户自定义词库 + 分词支持
--------------------------------

-- [词库常量]
WI_USER_DICT_NAME = "User_Dict"  -- 用户词库名称

-- [分词模式]
-- 1 = 最大候选：贪心最大化音节匹配（优先匹配更长音节）
-- 2 = 全部候选：保留所有可能，按音节长度排序
if not WI_SEG_MODE then
    WI_SEG_MODE = 1
end

-- [全局词库表]
WowCNDB = {
    _dicts = {},          -- 已加载的词库列表 {dictName = dictData}
    _dictCount = 0,       -- 已加载词库数量
    _cache = {},          -- 候选词查询缓存
    _cacheSize = 0,       -- 当前缓存大小
    _loaded = false,      -- 词库是否加载完成
}

-- 缓存最大值从 SavedVariables 读取（延迟初始化）
function WowCNDB_GetCacheMax()
    return WI_CACHE_MAX or 300
end

-- [用户自定义词库配置]
WowCNDB_UserDict = {
    _maxCount = 1000,     -- 最大词条数
    _data = {},           -- 用户词库数据 {codeKey = {word1, word2, ...}}
}

-- [有效拼音列表] 用于分词判断
WowCNDB_ValidSyllables = {
    "a", "ai", "an", "ang", "ao",
    "b","ba", "bai", "ban", "bang", "bao", "bei", "ben", "beng", "bi", "bian", "biao", "bie", "bin", "bing", "bo", "bu",
    "c", "ch", "ca", "cai", "can", "cang", "cao", "ce", "cen", "ceng", "cha", "chai", "chan", "chang", "chao", "che", "chen", "cheng", "chi", "chong", "chou", "chu", "chua", "chuai", "chuan", "chuang", "chui", "chun", "chuo", "ci", "cong", "cou", "cu", "cuan", "cui", "cun", "cuo",
    "d", "da", "dai", "dan", "dang", "dao", "de", "dei", "den", "deng", "di", "dia", "dian", "diao", "die", "ding", "diu", "dong", "dou", "du", "duan", "dui", "dun", "duo",
    "e", "ei", "en", "eng", "er",
    "f", "fa", "fan", "fang", "fei", "fen", "feng", "fo", "fou", "fu",
    "g", "ga", "gai", "gan", "gang", "gao", "ge", "gei", "gen", "geng", "gong", "gou", "gu", "gua", "guai", "guan", "guang", "gui", "gun", "guo",
    "h", "ha", "hai", "han", "hang", "hao", "he", "hei", "hen", "heng", "hm", "hng", "hong", "hou", "hu", "hua", "huai", "huan", "huang", "hui", "hun", "huo",
    "j", "ji", "jia", "jian", "jiang", "jiao", "jie", "jin", "jing", "jiong", "jiu", "ju", "juan", "jue", "jun",
    "k", "ka", "kai", "kan", "kang", "kao", "ke", "kei", "ken", "keng", "kong", "kou", "ku", "kua", "kuai", "kuan", "kuang", "kui", "kun", "kuo",
    "l", "la", "lai", "lan", "lang", "lao", "le", "lei", "leng", "li", "lia", "lian", "liang", "liao", "lie", "lin", "ling", "liu", "lo", "long", "lou", "lu", "lv", "luan", "lue", "lun", "luo",
    "m", "ma", "mai", "man", "mang", "mao", "me", "mei", "men", "meng", "mi", "mian", "miao", "mie", "min", "ming", "miu", "mo", "mou", "mu",
    "n", "na", "nai", "nan", "nang", "nao", "ne", "nei", "nen", "neng", "ni", "nian", "niang", "niao", "nie", "nin", "ning", "niu", "nong", "nu", "nv", "nuan", "nue", "nun", "nuo",
    "o", "ou",
    "p", "pa", "pai", "pan", "pang", "pao", "pei", "pen", "peng", "pi", "pian", "piao", "pie", "pin", "ping", "po", "pou", "pu",
    "q", "qi", "qia", "qian", "qiang", "qiao", "qie", "qin", "qing", "qiong", "qiu", "qu", "quan", "que", "qun",
    "r", "ran", "rang", "rao", "re", "ren", "reng", "ri", "rong", "rou", "ru", "rua", "ruan", "rui", "run", "ruo",
    "s", "sh", "sa", "sai", "san", "sang", "sao", "se", "sen", "seng", "sha", "shai", "shan", "shang", "shao", "she", "shei", "shen", "sheng", "shi", "shou", "shu", "shua", "shuai", "shuan", "shuang", "shui", "shun", "shuo", "si", "song", "sou", "su", "suan", "sui", "sun", "suo",
    "t", "ta", "tai", "tan", "tang", "tao", "te", "tei", "teng", "ti", "tian", "tiao", "tie", "ting", "tong", "tou", "tu", "tuan", "tui", "tun", "tuo",
    "w", "wa", "wai", "wan", "wang", "wei", "wen", "weng", "wo", "wu",
    "x", "xi", "xia", "xian", "xiang", "xiao", "xie", "xin", "xing", "xiong", "xiu", "xu", "xuan", "xue", "xun",
    "y", "ya", "yan", "yang", "yao", "ye", "yi", "yin", "ying", "yo", "yong", "you", "yu", "yuan", "yue", "yun",
    "z", "zh", "za", "zai", "zan", "zang", "zao", "ze", "zei", "zen", "zeng", "zha", "zhai", "zhan", "zhang", "zhao", "zhe", "zhei", "zhen", "zheng", "zhi", "zhong", "zhou", "zhu", "zhua", "zhuai", "zhuan", "zhuang", "zhui", "zhun", "zhuo", "zi", "zong", "zou", "zu", "zuan", "zui", "zun", "zuo",
}

-- [有效音节哈希表] 用于快速查找
WowCNDB_ValidSyllablesHash = {}

-- [立即初始化] 在文件加载时立即初始化音节哈希表，不依赖事件
for i = 1, table.getn(WowCNDB_ValidSyllables) do
    WowCNDB_ValidSyllablesHash[WowCNDB_ValidSyllables[i]] = true
end

--[[
    WowCNDB_InitValidSyllables - 初始化有效音节哈希表
    说明: 将音节列表转换为哈希表，用于 O(1) 查找
    注意: 现在在文件加载时自动初始化，此函数保留用于兼容
]]
function WowCNDB_InitValidSyllables()
    -- 已经在文件加载时初始化，这里只做兼容性保留
end

--[[
    WowCNDB_IsValidSyllable - 检查是否是有效的音节
    参数: syllable - 音节字符串
    返回: boolean - 是否有效
]]
function WowCNDB_IsValidSyllable(syllable)
    return WowCNDB_ValidSyllablesHash[syllable] == true
end

--[[
    WowCNDB_InitUserDict - 初始化用户自定义词库
    说明: 从 SavedVariables 加载用户词库并注册
]]
function WowCNDB_InitUserDict()
    WowCNDB_InitValidSyllables()
    
    WowCNInput_Debug("WowCNDB_InitUserDict 开始")
    WowCNInput_Debug("  WI_USER_DICT: " .. tostring(WI_USER_DICT))
    
    if not WI_USER_DICT then
        WI_USER_DICT = {}
    end
    
    WowCNDB_UserDict._data = WI_USER_DICT
    WowCNDB_UserDict._maxCount = WI_USER_DICT_MAX or 1000
    
    -- 迁移旧数据格式（字符串数组 -> 带时间戳的对象数组）
    WowCNDB_MigrateUserDict()
    
    -- 清理超限记录
    local currentCount = WowCNDB_GetUserDictCount()
    while currentCount > WowCNDB_UserDict._maxCount do
        WowCNDB_RemoveOldest()
        currentCount = WowCNDB_GetUserDictCount()
    end
    
    -- 获取账户信息
    local playerName = UnitName("player") or "Unknown"
    local realmName = GetRealmName() or "Unknown"
    local author = playerName .. "@" .. realmName
    
    -- 获取当前日期
    local dateInfo = date("*t")
    local currentDate = string.format("%04d-%02d-%02d", dateInfo.year, dateInfo.month, dateInfo.day)
    
    WowCNInput_Debug("  注册用户词库: " .. WI_USER_DICT_NAME)
    WowCNInput_Debug("  词条数: " .. WowCNDB_GetUserDictCount())
    
    WowCNDB_RegisterDict(WI_USER_DICT_NAME, WowCNDB_UserDict._data, {
        name = "用户自定义词库",
        desc = "用户输入学习保存的词库",
        count = tostring(WowCNDB_GetUserDictCount()),
        version = "1.0",
        date = currentDate,
        author = author,
    })
    
    WowCNInput_Debug("  WowCNDB._dicts 数量: " .. WowCNDB._dictCount)
    for name, _ in pairs(WowCNDB._dicts) do
        WowCNInput_Debug("    - " .. name)
    end
end

--[[
    WowCNDB_MigrateUserDict - 迁移旧数据格式
    说明: 将旧格式 {word1, word2} 转换为新格式 {{word=word1, time=time}, ...}
]]
function WowCNDB_MigrateUserDict()
    local migrated = false
    for codeKey, words in pairs(WowCNDB_UserDict._data) do
        if type(words) == "table" and table.getn(words) > 0 then
            -- 检查是否是旧格式（第一个元素是字符串）
            if type(words[1]) == "string" then
                local newWords = {}
                for i = 1, table.getn(words) do
                    table.insert(newWords, {word = words[i], time = 0})
                end
                WowCNDB_UserDict._data[codeKey] = newWords
                migrated = true
            end
        end
    end
    return migrated
end

--[[
    WowCNDB_GetUserDictCount - 获取用户词库词条数
    返回: 词条总数
]]
function WowCNDB_GetUserDictCount()
    local count = 0
    for codeKey, words in pairs(WowCNDB_UserDict._data) do
        if type(words) == "table" then
            count = count + table.getn(words)
        end
    end
    return count
end

--[[
    WowCNDB_LearnWord - 学习新词
    参数: inputCode - 输入编码（连续格式，如 "shangtiana"）
          word - 词语
    返回: boolean - 是否成功
    说明: 将用户选择的新词添加到用户词库，使用连续格式保存，记录时间戳
]]
function WowCNDB_LearnWord(inputCode, word)
    if not inputCode or not word or string.len(inputCode) == 0 or string.len(word) == 0 then
        return false
    end
    
    -- 使用输入编码作为键（已经是连续格式）
    local contKey = inputCode
    
    local words = WowCNDB_UserDict._data[contKey]
    
    -- 如果词已存在，更新时间戳
    if words then
        for i = 1, table.getn(words) do
            if words[i].word == word then
                words[i].time = time()
                return true
            end
        end
    else
        WowCNDB_UserDict._data[contKey] = {}
        words = WowCNDB_UserDict._data[contKey]
    end
    
    -- 检查用户词库上限
    local currentCount = WowCNDB_GetUserDictCount()
    if currentCount >= WowCNDB_UserDict._maxCount then
        WowCNDB_RemoveOldest()
    end
    
    -- 添加新词（带时间戳）
    table.insert(words, {word = word, time = time()})
    
    -- 清除缓存
    if WowCNDB._cache[contKey] then
        WowCNDB._cache[contKey] = nil
        WowCNDB._cacheSize = WowCNDB._cacheSize - 1
    end
    
    return true
end

--[[
    WowCNDB_RemoveOldest - 删除最旧的词条
    说明: 根据时间戳删除最旧的词条
]]
function WowCNDB_RemoveOldest()
    local oldestTime = nil
    local oldestCodeKey = nil
    local oldestIndex = nil
    
    -- 查找最旧的词条
    for codeKey, words in pairs(WowCNDB_UserDict._data) do
        if type(words) == "table" then
            for i = 1, table.getn(words) do
                local entry = words[i]
                if entry and entry.word then
                    if oldestTime == nil or (entry.time or 0) < oldestTime then
                        oldestTime = entry.time or 0
                        oldestCodeKey = codeKey
                        oldestIndex = i
                    end
                end
            end
        end
    end
    
    -- 删除找到的最旧词条
    if oldestCodeKey and oldestIndex then
        local words = WowCNDB_UserDict._data[oldestCodeKey]
        table.remove(words, oldestIndex)
        if table.getn(words) == 0 then
            WowCNDB_UserDict._data[oldestCodeKey] = nil
        end
    end
end

--[[
    WowCNDB_ClearUserDict - 清空用户词库
]]
function WowCNDB_ClearUserDict()
    WowCNDB_UserDict._data = {}
    WI_USER_DICT = {}
    WowCNDB_ClearCache()
end

--[[
    WowCNDB_RegisterDict - 注册词库到全局表
    参数: dictName - 词库名称
          dictData - 词库数据表
          dictMeta - 词库元信息（可选）
    说明: 将词库追加到全局查找表，O(1) 查找
]]
function WowCNDB_RegisterDict(dictName, dictData, dictMeta)
    if not dictName or not dictData then 
        return 
    end
    
    WowCNDB._dicts[dictName] = dictData
    WowCNDB._dictCount = WowCNDB._dictCount + 1
    
    if dictMeta then
        if not WowCNDB._meta then WowCNDB._meta = {} end
        WowCNDB._meta[dictName] = dictMeta
    end
end

--[[
    WowCNDB_GetCandidates - 获取候选词（O(1) 快速查找）
    参数: inputCode - 输入编码字符串（如 "jingling"）
    返回: candidates - 候选词列表
          matchedCodes - 匹配的编码列表
    说明: 使用哈希表直接查找，复杂度 O(1)
]]
function WowCNDB_GetCandidates(inputCode)
    if not inputCode or string.len(inputCode) == 0 then
        return {}, {}
    end
    
    -- 缓存检查（仅在启用缓存时）
    if WI_CACHE_ENABLED and WowCNDB._cache[inputCode] then
        local cached = WowCNDB._cache[inputCode]
        return cached.candidates, cached.matchedCodes
    end
    
    local candidates = {}
    local matchedCodes = {}
    local seenWords = {}
    
    -- 直接查找 O(1) - 遍历词库列表，但每个词库只做一次哈希查找
    for dictName, dictData in pairs(WowCNDB._dicts) do
        -- 检查词库是否启用
        if WI_DICT_ENABLED[dictName] ~= false then
            local words = dictData[inputCode]
            if words then
                for i = 1, table.getn(words) do
                    -- 用户词库使用新格式 {word=..., time=...}，其他词库使用字符串
                    local word
                    if dictName == WI_USER_DICT_NAME and type(words[i]) == "table" then
                        word = words[i].word
                    else
                        word = words[i]
                    end
                    
                    if word and not seenWords[word] then
                        seenWords[word] = true
                        table.insert(candidates, word)
                        table.insert(matchedCodes, inputCode)
                    end
                end
            end
        end
    end
    
    -- 仅在启用缓存时更新缓存
    if WI_CACHE_ENABLED then
        WowCNDB_UpdateCache(inputCode, candidates, matchedCodes)
    end
    
    return candidates, matchedCodes
end

--[[
    WowCNDB_GetSegmentedCandidates - 获取分词后的候选词
    参数: inputCode - 输入编码字符串（如 "xian"）
    返回: candidates - 候选词列表
          matchedCodes - 匹配的编码列表
          segmentedCandidates - 分词后的候选词列表
          segmentedMatchedCodes - 分词后匹配的编码列表
          segmentedDisplay - 分词后的显示格式（如 "xi'an"）
]]
function WowCNDB_GetSegmentedCandidates(inputCode)
    local candidates, matchedCodes = WowCNDB_GetCandidates(inputCode)
    
    local segmentedDisplay = nil
    local segmentedCandidates = {}
    local segmentedMatchedCodes = {}
    
    local segments = WowCNDB_SegmentCode(inputCode)
    for i = 1, table.getn(segments) do
        local seg = segments[i]
        local segKey = table.concat(seg, "_")
        local contKey = table.concat(seg, "")
        
        for dictName, dictData in pairs(WowCNDB._dicts) do
            local words = dictData[segKey] or dictData[contKey]
            if words then
                for j = 1, table.getn(words) do
                    -- 用户词库使用新格式 {word=..., time=...}，其他词库使用字符串
                    local word
                    if dictName == WI_USER_DICT_NAME and type(words[j]) == "table" then
                        word = words[j].word
                    else
                        word = words[j]
                    end
                    if word then
                        table.insert(segmentedCandidates, word)
                        table.insert(segmentedMatchedCodes, inputCode)
                    end
                end
            end
        end
        
        if not segmentedDisplay and table.getn(segmentedCandidates) > 0 then
            segmentedDisplay = table.concat(seg, "'")
        end
    end
    
    return candidates, matchedCodes, segmentedCandidates, segmentedMatchedCodes, segmentedDisplay
end

--[[
    WowCNDB_SegmentCode - 对编码进行分词
    参数: inputCode - 输入编码字符串（如 "xian"）
    返回: 分词结果列表 {{xi, an}, {xian}}
]]
function WowCNDB_SegmentCode(inputCode)
    local results = {}
    WowCNDB_SegmentCodeRecursive(inputCode, 1, {}, results)
    return results
end

--[[
    WowCNDB_SegmentCodeRecursive - 递归分词
    参数: inputCode - 输入编码
          pos - 当前位置
          current - 当前分词结果
          results - 所有分词结果
]]
function WowCNDB_SegmentCodeRecursive(inputCode, pos, current, results)
    local len = string.len(inputCode)
    if pos > len then
        if table.getn(current) > 0 then
            table.insert(results, current)
        end
        return
    end
    
    for tryLen = math.min(6, len - pos + 1), 1, -1 do
        local subSyllable = string.sub(inputCode, pos, pos + tryLen - 1)
        if WowCNDB_IsValidSyllable(subSyllable) then
            local newCurrent = {}
            for i = 1, table.getn(current) do
                table.insert(newCurrent, current[i])
            end
            table.insert(newCurrent, subSyllable)
            WowCNDB_SegmentCodeRecursive(inputCode, pos + tryLen, newCurrent, results)
        end
    end
end

--[[
    WowCNDB_FormatCodeWithSeparator - 格式化编码显示
    参数: inputCode - 输入编码字符串（如 "shangtiana"）
    返回: 格式化后的编码（如 "shang'tian'a"）
]]
function WowCNDB_FormatCodeWithSeparator(inputCode)
    if not inputCode or string.len(inputCode) == 0 then
        return ""
    end
    
    local result = ""
    local pos = 1
    local len = string.len(inputCode)
    
    while pos <= len do
        local found = false
        for tryLen = math.min(6, len - pos + 1), 1, -1 do
            local subSyllable = string.sub(inputCode, pos, pos + tryLen - 1)
            if WowCNDB_IsValidSyllable(subSyllable) then
                if string.len(result) > 0 then
                    result = result .. "'"
                end
                result = result .. subSyllable
                pos = pos + tryLen
                found = true
                break
            end
        end
        
        if not found then
            if string.len(result) > 0 then
                result = result .. "'"
            end
            result = result .. string.sub(inputCode, pos, pos)
            pos = pos + 1
        end
    end
    
    return result
end

--[[
    WowCNDB_FormatCodeWithUnderscore - 将连续编码转换为下划线格式
    参数: inputCode - 输入编码字符串（如 "shangtiana"）
    返回: 下划线格式编码（如 "shang_tian_a"）
    说明: 用于保存用户词库时统一格式
]]
function WowCNDB_FormatCodeWithUnderscore(inputCode)
    if not inputCode or string.len(inputCode) == 0 then
        return ""
    end
    
    local result = ""
    local pos = 1
    local len = string.len(inputCode)
    
    while pos <= len do
        local found = false
        for tryLen = math.min(6, len - pos + 1), 1, -1 do
            local subSyllable = string.sub(inputCode, pos, pos + tryLen - 1)
            if WowCNDB_IsValidSyllable(subSyllable) then
                if string.len(result) > 0 then
                    result = result .. "_"
                end
                result = result .. subSyllable
                pos = pos + tryLen
                found = true
                break
            end
        end
        
        if not found then
            if string.len(result) > 0 then
                result = result .. "_"
            end
            result = result .. string.sub(inputCode, pos, pos)
            pos = pos + 1
        end
    end
    
    return result
end

--[[
    WowCNDB_UpdateCache - 更新查询缓存
    参数: inputCode - 输入编码
          candidates - 候选词列表
          matchedCodes - 匹配的编码列表
]]
function WowCNDB_UpdateCache(inputCode, candidates, matchedCodes)
    local cacheMax = WowCNDB_GetCacheMax()
    if WowCNDB._cacheSize >= cacheMax then
        local count = 0
        local halfMax = math.floor(cacheMax / 2)
        for k in pairs(WowCNDB._cache) do
            WowCNDB._cache[k] = nil
            WowCNDB._cacheSize = WowCNDB._cacheSize - 1
            count = count + 1
            if count >= halfMax then break end
        end
    end
    
    WowCNDB._cache[inputCode] = {
        candidates = candidates,
        matchedCodes = matchedCodes,
    }
    WowCNDB._cacheSize = WowCNDB._cacheSize + 1
end

--[[
    WowCNDB_ClearCache - 清空缓存
]]
function WowCNDB_ClearCache()
    WowCNDB._cache = {}
    WowCNDB._cacheSize = 0
end

--[[
    WowCNDB_GetDictInfo - 获取词库信息
    返回: 词库统计信息字符串
]]
function WowCNDB_GetDictInfo()
    local info = "已加载 " .. WowCNDB._dictCount .. " 个词库"
    if WowCNDB._meta then
        for name, meta in pairs(WowCNDB._meta) do
            info = info .. "\n  - " .. name .. " (" .. (meta.count or "?") .. " 词条)"
        end
    end
    local userCount = WowCNDB_GetUserDictCount()
    info = info .. "\n用户词库: " .. userCount .. "/" .. WowCNDB_UserDict._maxCount .. " 词条"
    return info
end

--[[
    WowCNDB_CanFullySegment - 检查编码是否能完全分解为有效音节
    参数: inputCode - 输入编码
    返回: boolean - 是否能完全分解
]]
function WowCNDB_CanFullySegment(inputCode)
    if not inputCode or string.len(inputCode) == 0 then
        return true
    end
    
    local len = string.len(inputCode)
    
    for tryLen = math.min(6, len), 1, -1 do
        local subSyllable = string.sub(inputCode, 1, tryLen)
        if WowCNDB_IsValidSyllable(subSyllable) then
            local remaining = string.sub(inputCode, tryLen + 1)
            if WowCNDB_CanFullySegment(remaining) then
                return true
            end
        end
    end
    
    return false
end

--[[
    WowCNDB_GetFirstSyllableBoundaries - 获取从第一个字符开始的所有有效音节边界
    参数: inputCode - 输入编码
    返回: boundaries - 音节边界位置列表 {3, 4, 6, ...}（从长到短排序）
    说明: 只返回剩余部分也能完全分解为有效音节的边界
]]
function WowCNDB_GetFirstSyllableBoundaries(inputCode)
    local boundaries = {}
    local len = string.len(inputCode)
    
    for tryLen = math.min(6, len), 1, -1 do
        local subSyllable = string.sub(inputCode, 1, tryLen)
        if WowCNDB_IsValidSyllable(subSyllable) then
            local remaining = string.sub(inputCode, tryLen + 1)
            if WowCNDB_CanFullySegment(remaining) then
                table.insert(boundaries, tryLen)
            end
        end
    end
    
    return boundaries
end

--[[
    WowCNDB_GetGreedyPrefixBoundaries - 方案A：贪心最大化音节匹配
    参数: inputCode - 输入编码
    返回: boundaries - 前缀边界位置列表（从长到短排序）
    说明: 从左到右，每次选择最长的有效音节
          例如：aliang → a + liang（liang 比 li + ang 更长）
                xian → xian 或 xi + an（都保留）
]]
function WowCNDB_GetGreedyPrefixBoundaries(inputCode)
    local boundaries = {}
    local len = string.len(inputCode)
    
    if len == 0 then
        return boundaries
    end
    
    -- 贪心算法：每次选择最长的有效音节
    local function greedySegment(code, startPos)
        if startPos > len then
            return true
        end
        
        local remaining = string.sub(code, startPos)
        local remainingLen = string.len(remaining)
        
        -- 尝试最长的音节（最多6个字符）
        for tryLen = math.min(6, remainingLen), 1, -1 do
            local subSyllable = string.sub(remaining, 1, tryLen)
            if WowCNDB_IsValidSyllable(subSyllable) then
                local afterSyllable = string.sub(remaining, tryLen + 1)
                if WowCNDB_CanFullySegment(afterSyllable) then
                    -- 找到最长的有效音节，记录边界
                    local boundary = startPos + tryLen - 1
                    -- 避免重复添加
                    local found = false
                    for i = 1, table.getn(boundaries) do
                        if boundaries[i] == boundary then
                            found = true
                            break
                        end
                    end
                    if not found then
                        table.insert(boundaries, boundary)
                    end
                    -- 继续处理剩余部分
                    greedySegment(code, startPos + tryLen)
                    break  -- 只选择最长的音节
                end
            end
        end
        
        return true
    end
    
    -- 从位置1开始贪心分解
    greedySegment(inputCode, 1)
    
    -- 同时添加所有可能的更短边界（用于候选词匹配）
    -- 例如：xian 需要同时有 xian 和 xi 的边界
    local allBoundaries = {}
    for i = 1, table.getn(boundaries) do
        allBoundaries[boundaries[i]] = true
    end
    
    -- 添加贪心分解路径上的所有边界
    local pos = 1
    while pos <= len do
        local remaining = string.sub(inputCode, pos)
        local remainingLen = string.len(remaining)
        local foundSyllable = false
        
        for tryLen = math.min(6, remainingLen), 1, -1 do
            local subSyllable = string.sub(remaining, 1, tryLen)
            if WowCNDB_IsValidSyllable(subSyllable) then
                local afterSyllable = string.sub(remaining, tryLen + 1)
                if WowCNDB_CanFullySegment(afterSyllable) then
                    local boundary = pos + tryLen - 1
                    allBoundaries[boundary] = true
                    pos = pos + tryLen
                    foundSyllable = true
                    break
                end
            end
        end
        
        if not foundSyllable then
            break
        end
    end
    
    -- 转换为数组并从长到短排序
    local result = {}
    for boundary in pairs(allBoundaries) do
        table.insert(result, boundary)
    end
    table.sort(result, function(a, b) return a > b end)
    
    return result
end

--[[
    WowCNDB_GetAllPrefixBoundaries - 方案B：保留所有可能的前缀边界
    参数: inputCode - 输入编码
    返回: boundaries - 前缀边界位置列表 {11, 10, 8, 5, 2}（从长到短排序）
    说明: 返回所有可能的前缀边界，剩余部分必须能完全分解为有效音节
          用于匹配如 nihao, nihaoshi 等多音节前缀
          从长到短排序，确保更长的匹配优先显示
]]
function WowCNDB_GetAllPrefixBoundaries(inputCode)
    local boundaries = {}
    local len = string.len(inputCode)
    
    -- 从第一个字符开始，尝试所有可能的前缀长度（包含单音节）
    for prefixLen = len, 1, -1 do
        local prefix = string.sub(inputCode, 1, prefixLen)
        local remaining = string.sub(inputCode, prefixLen + 1)
        
        -- 检查前缀是否能完全分解为音节
        if WowCNDB_CanFullySegment(prefix) then
            -- 检查剩余部分是否也能完全分解（或为空）
            if WowCNDB_CanFullySegment(remaining) then
                table.insert(boundaries, prefixLen)
            end
        end
    end
    
    return boundaries
end

--[[
    WowCNDB_GetAllSegmentations - 获取所有可能的分词方案
    参数: inputCode - 输入编码
    返回: segmentations - 分词方案列表 {{{"jing", "ling"}, "jing_ling"}, ...}
    说明: 返回所有从第一个字符开始的完整分词方案
]]
function WowCNDB_GetAllSegmentations(inputCode)
    local results = {}
    WowCNDB_SegmentCodeRecursive(inputCode, 1, {}, results)
    
    local segmentations = {}
    for i = 1, table.getn(results) do
        local seg = results[i]
        local segKey = table.concat(seg, "_")
        local contKey = table.concat(seg, "")
        table.insert(segmentations, {segments = seg, underKey = segKey, contKey = contKey})
    end
    
    return segmentations
end

--[[
    WowCNDB_DynamicMatch - 从第一个字符开始的最大化匹配
    参数: inputLetters - 输入的字母字符串
    返回: allCandidates - 候选词列表
          matchedLetters - 匹配的编码列表
          remainingLetters - 剩余字母
    
    匹配规则:
    1. 完整匹配优先（nihaoshijie → 你好世界，如果有）
    2. 分词匹配（ni_hao_shi_jie → 你好世界）
    3. 前缀匹配（nihao → 你好，ni → 你）
    不再进行任意子串匹配
]]
function WowCNDB_DynamicMatch(inputLetters)
    if not inputLetters or string.len(inputLetters) == 0 then
        return {}, {}, nil
    end
    
    local allCandidates = {}
    local matchedLetters = {}
    local seenWords = {}
    local shortestMatchLen = nil
    
    -- 1. 完整匹配（最高优先级）
    local fullCandidates, fullCodes = WowCNDB_GetCandidates(inputLetters)
    if fullCandidates and table.getn(fullCandidates) > 0 then
        for i = 1, table.getn(fullCandidates) do
            local word = fullCandidates[i]
            if not seenWords[word] then
                seenWords[word] = true
                table.insert(allCandidates, word)
                table.insert(matchedLetters, inputLetters)
            end
        end
    end
    
    -- 2. 分词匹配（从第一个字符开始，在音节边界切分）
    local segmentations = WowCNDB_GetAllSegmentations(inputLetters)
    for i = 1, table.getn(segmentations) do
        local segInfo = segmentations[i]
        local segKey = segInfo.underKey
        local contKey = segInfo.contKey
        
        -- 只处理分词格式（包含下划线的）
        if string.find(segKey, "_") then
            local segCandidates, segCodes = WowCNDB_GetCandidates(segKey)
            if segCandidates and table.getn(segCandidates) > 0 then
                for j = 1, table.getn(segCandidates) do
                    local word = segCandidates[j]
                    if not seenWords[word] then
                        seenWords[word] = true
                        table.insert(allCandidates, word)
                        table.insert(matchedLetters, contKey)
                    end
                end
            end
        end
    end
    
    -- 3. 前缀匹配（从第一个字符开始，在音节边界切分）
    --    匹配所有可能的前缀：ni, nihao, nihaoshi 等
    --    根据设置选择方案A（贪心）或方案B（全部）
    local prefixBoundaries
    if WI_SEG_MODE == 1 then
        prefixBoundaries = WowCNDB_GetGreedyPrefixBoundaries(inputLetters)
    else
        prefixBoundaries = WowCNDB_GetAllPrefixBoundaries(inputLetters)
    end
    for i = 1, table.getn(prefixBoundaries) do
        local prefixLen = prefixBoundaries[i]
        local prefix = string.sub(inputLetters, 1, prefixLen)
        local prefixCandidates, prefixCodes = WowCNDB_GetCandidates(prefix)
        if prefixCandidates and table.getn(prefixCandidates) > 0 then
            -- 记录最短匹配长度
            if not shortestMatchLen or prefixLen < shortestMatchLen then
                shortestMatchLen = prefixLen
            end
            for j = 1, table.getn(prefixCandidates) do
                local word = prefixCandidates[j]
                if not seenWords[word] then
                    seenWords[word] = true
                    table.insert(allCandidates, word)
                    table.insert(matchedLetters, prefix)
                end
            end
        end
    end
    
    -- 计算剩余字母（基于最短匹配长度）
    local remainingLetters = nil
    if shortestMatchLen and shortestMatchLen < string.len(inputLetters) then
        remainingLetters = string.sub(inputLetters, shortestMatchLen + 1)
    end
    
    if table.getn(allCandidates) == 0 then
        return {}, {}, inputLetters
    end
    
    return allCandidates, matchedLetters, remainingLetters
end

--[[
    WowCNDB_GetCodeLength - 根据候选词获取对应的编码长度
    参数: candidateWord - 候选词
          matchedLetters - 匹配的字母列表
    返回: 对应的编码长度
]]
function WowCNDB_GetCodeLength(candidateWord, matchedLetters)
    if not matchedLetters or table.getn(matchedLetters) == 0 then
        return 0
    end
    
    for i = 1, table.getn(matchedLetters) do
        local curLetters = matchedLetters[i]
        local candidates, matchedCodes = WowCNDB_GetCandidates(curLetters)
        if candidates then
            for j = 1, table.getn(candidates) do
                if candidates[j] == candidateWord then
                    return string.len(curLetters)
                end
            end
        end
    end
    
    return string.len(matchedLetters[1])
end

--[[
    WowCNDB_SelectWord - 选词处理
    参数: lowerCode - 小写编码
          selectedWord - 选中的词
          matchedCodes - 匹配的编码列表
    返回: codeLen - 编码长度
          learnLetters - 用于学习的拼音
          remainingCode - 剩余编码（如果有）
    说明: 仅计算编码长度和剩余编码，学习逻辑已移至 InputHandler
]]
function WowCNDB_SelectWord(lowerCode, selectedWord, matchedCodes)
    local codeLen = WowCNDB_GetCodeLength(selectedWord, matchedCodes)
    local learnLetters = string.sub(lowerCode, 1, codeLen)
    
    -- 学习逻辑已移至 InputHandler.lua 的 WowCNInput_DoSelectWord 函数
    -- 只有多次选词才需要学习完整词组
    
    local remainingCode = nil
    if codeLen > 0 and codeLen < string.len(lowerCode) then
        remainingCode = string.sub(lowerCode, codeLen + 1)
    end
    
    return codeLen, learnLetters, remainingCode
end

--[[
    WowCNDB_BuildSelectedText - 构建选词后的文本
    参数: prevText - 选词前的文本
          searchPrevText - 搜索用的前置文本
          prevLetters - 匹配的拼音
          selectedWord - 选中的词
          remainingCode - 剩余编码
          confirmedLen - 已确认文本长度
    返回: newText - 新文本
          newConfirmedLen - 新的已确认长度
]]
function WowCNDB_BuildSelectedText(prevText, searchPrevText, prevLetters, selectedWord, remainingCode, confirmedLen)
    local prefix = string.sub(prevText, 1, confirmedLen)
    local beforeCode = string.sub(searchPrevText, 1, string.len(searchPrevText) - string.len(prevLetters))
    local newText = prefix .. beforeCode .. selectedWord
    
    if remainingCode and string.len(remainingCode) > 0 then
        newText = newText .. remainingCode
    end
    
    local newConfirmedLen = 0
    if remainingCode and string.len(remainingCode) > 0 then
        newConfirmedLen = string.len(prefix) + string.len(beforeCode) + string.len(selectedWord)
    end
    
    return newText, newConfirmedLen
end

--[[
    WowCNDB_GetPunctuation - 获取标点符号候选
    参数: char - 输入的字符
    返回: candidate - 候选标点（如果没有返回 nil）
]]
function WowCNDB_GetPunctuation(char)
    local candidates = WowCNDB_GetCandidates(char)
    if candidates and table.getn(candidates) > 0 then
        return candidates[1]
    end
    return nil
end
