local CHC_utils = {}

local lower = string.lower
local tostring = tostring
local len = string.len
local sub = string.sub


CHC_utils.Deque = {}

function CHC_utils.Deque:new()
    local o = {}
    o.first = 0
    o.last = -1
    o.len = 0
    o.data = {}

    function CHC_utils.Deque:_pushl(val)
        local first = self.first - 1
        self.first = first
        self.data[first] = val
        self.len = self.len + 1
    end

    function CHC_utils.Deque:_popr()
        local last = self.last
        if self.first > last then error('deque empty') end
        local val = self.data[last]
        self.data[last] = nil
        self.last = last - 1
        self.len = self.len - 1
        return val
    end

    function CHC_utils.Deque:push(val)
        local last = self.last + 1
        self.last = last
        self.data[last] = val
        self.len = self.len + 1
    end

    function CHC_utils.Deque:pop()
        local first = self.first
        if first > self.last then error('deque empty') end
        local val = self.data[first]
        self.data[first] = nil
        self.first = first + 1
        self.len = self.len - 1
        return val
    end

    setmetatable(o, self)
    self.__index = self
    return o
end

CHC_utils.tableSize = function(table1)
    if not table1 then return 0 end
    local count = 0;
    for _, v in pairs(table1) do
        count = count + 1;
    end
    return count;
end

CHC_utils.areTablesDifferent = function(table1, table2)
    local size1 = CHC_utils.tableSize(table1)
    local size2 = CHC_utils.tableSize(table2)
    if size1 ~= size2 then return true end
    if size1 == 0 then return false end
    for k1, v1 in pairs(table1) do
        if table2[k1] ~= v1 then
            return true
        end
    end
    return false
end

---Compares "what" to "to" via string.contains.
---
---In case "what" is table, comparison is done for each element (break after first hit)
---If "~" is first symbol of "to", then negate logic is applied (i.e return true if "what" NOT in "to")
---@param what string|table left part of comparison
---@param to string right part of comparison
---@param passAll? boolean return true if true without checks
---@return boolean #result of comparison
CHC_utils.compare = function(what, to, passAll)
    local contains = string.contains
    local isNegate = sub(to, 1, 1) == "~"
    if isNegate then to = sub(to, 2) end -- remove ~ from token
    if to == "" then return true end
    if passAll then return true end
    local isList = type(what) == "table"
    to = lower(tostring(to))
    local state = false
    if not isList then
        what = lower(tostring(what))
        if isNegate then
            if not contains(what, to) then
                state = true
            end
        else
            if contains(what, to) then
                state = true
            end
        end
    else
        for i = 1, #what do
            local wh = lower(tostring(what[i]))
            if isNegate then -- this is not working atm (so '#~smth' will not work)
                if not contains(wh, to) then
                    state = true
                    break
                end
            else
                if contains(wh, to) then
                    state = true
                    break
                end
            end
        end
    end
    return state
end

---Return true if all values of "t" == "val"
--
---@param t table Table to check, numerical keys only
---@param val any Value to check
---@param start? number Starting value (optional, by default _start=1)
---@param stop? number Ending value (optional, by default _stop=#t)
---@param step? number Step (optional, by default 1)
CHC_utils.all = function(t, val, start, stop, step)
    start = start or 1
    stop = stop or #t
    step = step or 1

    for i = start, stop, step do
        if t[i] ~= val then return false end
    end
    return true
end

--- Return true if any value of "t" == "val"
--
---@param t table Table to check, numerical keys only
---@param val any Value to check
---@param start? number Starting value (by default 1)
---@param stop? number Ending value (by default #t)
---@param step? number Step (by default 1)
CHC_utils.any = function(t, val, start, stop, step)
    start = start or 1
    stop = stop or #t
    step = step or 1
    for i = start, stop, step do
        if t[i] == val then return true end
    end
    return false
end

---Checks if txt start with start
---@param txt string text to check
---@param start string string to check in text
---@return boolean #result
CHC_utils.startswith = function(txt, start)
    return sub(txt, 1, len(start)) == start
end

CHC_utils.chcprint = function(txt)
    print("[CraftHelperContinued] " .. tostring(txt))
end

local JsonUtil = require("CHC_json")

CHC_utils.jsonutil = {}
CHC_utils.jsonutil.Load = function(fname)
    if not fname then error('filename not set') end
    local res
    local fileReaderObj = getFileReader(fname, true)
    local json = ""
    local line = fileReaderObj:readLine()
    while line ~= nil do
        json = json .. line
        line = fileReaderObj:readLine()
    end
    fileReaderObj:close()

    if json and json ~= "" then
        res = JsonUtil.Decode(json)
    end
    return res
end

CHC_utils.jsonutil.Save = function(fname, data)
    if not data then return end
    local fileWriterObj = getFileWriter(fname, true, false)
    local json = JsonUtil.Encode(data)
    fileWriterObj:write(json)
    fileWriterObj:close()
end


return CHC_utils
