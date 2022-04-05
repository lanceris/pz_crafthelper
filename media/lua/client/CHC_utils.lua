local CHC_utils = {}

local lower = string.lower
local tostring = tostring
local contains = string.contains
local len = string.len
local sub = string.sub

CHC_utils.tableSize = function(table1)
    if not table1 then return 0 end
    local count = 0;
    for _,v in pairs(table1) do
        count = count + 1;
    end
    return count;
end

CHC_utils.areTablesDifferent = function (table1, table2)
    local size1 = CHC_utils.tableSize(table1)
    local size2 = CHC_utils.tableSize(table2)
    if size1 ~= size2 then return true end
    if size1 == 0 then return false end
    for k1,v1 in pairs(table1) do
        if table2[k1] ~= v1 then
            return true
        end
    end
    return false
end

---Compares "what" to "to" via string.contains.
---
---In case "what" is table, comparison is done for each element (break after first hit)
---@param what string|table left part of comparison
---@param to string right part of comparison
---@param passAll? boolean return true if true without checks
---@return boolean #result of comparison
CHC_utils.compare = function (what, to, passAll)
    if passAll then return true end
    local isList = type(what) == "table"
    to = lower(tostring(to))
    local state = false
    if not isList then
        what = lower(tostring(what))
        if contains(what, to) then
            state = true
        end
    else
        for i=1, #what do
            local wh = lower(tostring(what[i]))
            if contains(wh, to) then
                state = true
                break
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

    for i=start, stop, step do
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
    for i=start, stop, step do
        if t[i] == val then return true end
    end
    return false
end

---Checks if txt start with start
---@param txt string text to check
---@param start string string to check in text
---@return boolean #result
CHC_utils.startswith = function (txt, start)
    return sub(txt, 1, len(start)) == start
end


return CHC_utils