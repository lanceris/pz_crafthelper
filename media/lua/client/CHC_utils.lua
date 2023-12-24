local CHC_utils = {}

local lower = string.lower
local tostring = tostring
local format = string.format
local len = string.len
local sub = string.sub
local insert = table.insert
local contains = string.contains

CHC_utils.configDir = "CraftHelperContinued" .. getFileSeparator()

CHC_utils.chcprint = function(txt, debugOnly)
    if debugOnly == nil then debugOnly = false end
    if not debugOnly or (debugOnly and getDebug()) then
        print('[CraftHelperContinued] ' .. tostring(txt))
    end
end

---@param txt string error message
---@param loc string? location of error
---@param line number? line number of error
CHC_utils.chcerror = function(txt, loc, line, raise)
    local msg = txt
    if loc then
        msg = msg .. format(' at %s', loc)
    end
    if line then
        msg = msg .. format(':%d', line)
    end
    if raise then
        msg = '[CraftHelperContinued] ' .. msg
        error(msg)
    else
        CHC_utils.chcprint(msg, false)
    end
end

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
        if self.first > last then CHC_utils.chcerror('Deque empty', 'CHC_utils.Deque:_popr') end
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
        if first > self.last then CHC_utils.chcerror('Deque empty', 'CHC_utils.Deque:pop') end
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

---Checks if txt end with end
---@param txt string text to check
---@param _end string string to check in text
---@return boolean #result
CHC_utils.endswith = function(txt, _end)
    return sub(txt, - #_end) == _end
end

function CHC_utils.empty(tab)
    for _, _ in pairs(tab) do return false; end
    return true
end

function CHC_utils.concat(t1, t2)
    local result = {}
    for i = 1, #t1 do
        result[i] = t1[i]
    end
    local s = #result
    for i = 1, #t2 do
        result[s + i] = t2[i]
    end
    return result
end

---measure string width for specified font
---@param str string
---@param font UIFont
---@return number width width in pixels
function CHC_utils.strWidth(font, str)
    return getTextManager():MeasureStringX(font, str)
end

---measure string height for specified font
---@param str string
---@param font UIFont
---@return number height height in pixels
function CHC_utils.strHeight(font, str)
    return getTextManager():MeasureStringY(font, str)
end

CHC_utils.configDir = "CraftHelperContinued" .. getFileSeparator()
-- CHC_utils.cacheDir = CHC_utils.configDir .. "cache" .. getFileSeparator()

local JsonUtil = require('CHC_json')

CHC_utils.jsonutil = {}
CHC_utils.jsonutil.Load = function(fname)
    local func = 'CHC_utils.jsonutil.Load'
    if not fname then CHC_utils.chcerror('Filename not set', func) end
    local res
    local fileReaderObj = getFileReader(fname, true)
    if not fileReaderObj then
        CHC_utils.chcerror(format('File not found and cannot be created (%s)', fname), func)
    end
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
            CHC_utils.chcerror(format('Cannot decode json (%s)', res), func)
        end
    end
    return res
end

CHC_utils.jsonutil.Save = function(fname, data)
    if not data then return end
    local fileWriterObj = getFileWriter(fname, true, false)
    if not fileWriterObj then
        CHC_utils.chcerror(format('Cannot write to %s', fname), 'CHC_utils.jsonutil.Save')
    end
    local status, json = pcall(JsonUtil.Encode, data)
    if not status then
        CHC_utils.chcerror(format('Cannot encode json (%s)', json), 'CHC_utils.jsonutil.Save')
    end
    fileWriterObj:write(json)
    fileWriterObj:close()
end

CHC_utils.tableutil = {}

---@param o number|boolean|string|table object to serialize
---@return string str result string
CHC_utils.tableutil.serialize = function(o, res, _nested, _comma)
    res = res or {}
    _nested = _nested or 0
    local comma
    if _comma then
        comma = ",\n"
    else
        comma = ""
    end
    if type(o) == "number" then
        insert(res, o .. comma)
    elseif type(o) == "boolean" then
        insert(res, tostring(o) .. comma)
    elseif type(o) == "string" then
        insert(res, string.format("%q" .. comma, o))
    elseif type(o) == "table" then
        insert(res, "{\n")
        _nested = _nested + 1
        local spaces = string.rep(" ", _nested * 4)
        for k, v in pairs(o) do
            if type(k) ~= "string" then
                insert(res, spaces .. "[")
                CHC_utils.tableutil.serialize(k, res, _nested, false)
                insert(res, "] = ")
            else
                insert(res, spaces .. k .. " = ")
            end

            CHC_utils.tableutil.serialize(v, res, _nested, true)
        end
        _nested = _nested - 1
        insert(res, string.rep(" ", _nested * 4) .. "}" .. comma)
    else
        print("cannot serialize a " .. type(o))
    end
    return table.concat(res)
end



---comment
---@param fname string Filename to load data from
---@return string|nil res Loaded data
CHC_utils.tableutil.load = function(fname, isBinary)
    local res
    local data = {}
    local fileReaderObj = getFileReader(fname, true)
    local line = fileReaderObj:readLine()
    while line do
        insert(data, line)
        line = fileReaderObj:readLine()
    end
    fileReaderObj:close()
    res = table.concat(data, "\n")
    if not isBinary then
        res = loadstring("return" .. res)()
    end
    return res
end

---comment
---@param fname string Filename to save data to
---@param data table Data to save
CHC_utils.tableutil.save = function(fname, data)
    if not data then return end
    local fileWriterObj = getFileWriter(fname, true, false)
    fileWriterObj:write(CHC_utils.tableutil.serialize(data))
    fileWriterObj:close()
end

return CHC_utils
