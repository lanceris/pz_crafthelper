local CHC_utils = {}

local lower = string.lower
local tostring = tostring
local format = string.format
local len = string.len
local sub = string.sub
local insert = table.insert
local contains = string.contains

CHC_utils.configDir = "CraftHelperContinued" .. getFileSeparator()

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

---Compares 'what' to 'to' via string.contains.
---
---In case 'what' is table, comparison is done for each element (break after first hit)
---If '~' is first symbol of 'to', then negate logic is applied (i.e return true if 'what' NOT in 'to')
---@param what string|table left part of comparison
---@param to string right part of comparison
---@param passAll? boolean return true if true without checks
---@return boolean #result of comparison
CHC_utils.compare = function(what, to, passAll)
    if not what then return false end
    local isNegate = sub(to, 1, 1) == '~'
    if isNegate then to = sub(to, 2) end -- remove ~ from token
    if to == '' then return true end
    if passAll then return true end
    local isList = type(what) == 'table'
    local isOperand = CHC_utils.any({ '>', '<', '=' }, sub(to, 1, 1))
    local operand
    if isOperand then
        operand = sub(to, 1, 1)
        to = sub(to, 2)
    end

    local state = false

    if not isList then
        what = lower(what)
    end
    to = lower(to)

    if isOperand then
        if not what or not to or to == '' then return true end
        if type(what) == 'string' and tonumber(what) then what = tonumber(what) end
        if type(to) == 'string' and tonumber(to) then to = tonumber(to) end

        if type(what) == 'string' and type(to) ~= 'string' then return false end
        if type(what) ~= 'string' and type(to) == 'string' then return false end

        if operand == '=' then
            if isNegate then
                state = not contains(what, to)
            else
                state = contains(what, to)
            end
        elseif operand == '>' then
            state = what > to
        elseif operand == '<' then
            state = what < to
        end
    else
        to = lower(tostring(to))
        if not isList then
            what = lower(tostring(what))
            if isNegate then
                state = not contains(what, to)
            else
                state = contains(what, to)
            end
        else
            local _states = {}
            for i = 1, #what do
                local wh = lower(tostring(what[i]))
                if isNegate then
                    insert(_states, contains(wh, to))
                else
                    if contains(wh, to) then
                        state = true
                        break
                    end
                end
            end
            if isNegate and not CHC_utils.empty(_states) then
                state = CHC_utils.all(_states, false)
            end
        end
    end
    return state
end

---Return true if all values of 't' == 'val'
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

--- Return true if any value of 't' == 'val'
--
---@param t table Table to check
---@param val any Value to check, numerical keys only (if table)
---@param start? number Starting value (by default 1)
---@param stop? number Ending value (by default #t)
---@param step? number Step (by default 1)
CHC_utils.any = function(t, val, start, stop, step, nonNum)
    start = start or 1
    stop = stop or #t
    step = step or 1
    nonNum = nonNum or false
    if type(val) == 'table' then
        for j = 1, #val do
            if nonNum then
                for _, value in pairs(t) do
                    if value == val[j] then
                        return true
                    end
                end
            else
                for i = start, stop, step do
                    if t[i] == val[j] then
                        return true
                    end
                end
            end
        end
    else
        if nonNum then
            for _, value in pairs(t) do
                if value == val then
                    return true
                end
            end
        else
            for i = start, stop, step do
                if t[i] == val then
                    return true
                end
            end
        end
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
    print('[CraftHelperContinued] ' .. tostring(txt))
end

function CHC_utils.empty(tab)
    for _, _ in pairs(tab) do return false; end
    return true
end

local JsonUtil = require('CHC_json')

CHC_utils.jsonutil = {}
CHC_utils.jsonutil.Load = function(fname)
    if not fname then error('filename not set') end
    local res
    local fileReaderObj = getFileReader(fname, true)
    if not fileReaderObj then error(format('File not found and cannot be created (%s)', fname)) end
    local json = ''
    local line = fileReaderObj:readLine()
    while line ~= nil do
        json = json .. line
        line = fileReaderObj:readLine()
    end
    fileReaderObj:close()

    if json and json ~= '' then
        local status = true
        status, res = pcall(JsonUtil.Decode, json)
        if not status then
            error(format('Cannot decode json (%s)', res))
        end
    end
    return res
end

CHC_utils.jsonutil.Save = function(fname, data)
    if not data then return end
    local fileWriterObj = getFileWriter(fname, true, false)
    if not fileWriterObj then
        error(format('Cannot write to %s', fname))
    end
    local status, json = pcall(JsonUtil.Encode, data)
    if not status then
        error(format('Cannot encode json (%s)', json))
    end
    fileWriterObj:write(json)
    fileWriterObj:close()
end


return CHC_utils
