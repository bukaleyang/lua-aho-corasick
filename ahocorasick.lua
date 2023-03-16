--[[
    A Lua implementation of the Aho-Corasick string matching algorithm.

    Copyright 2023 bukale2022@163.com

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
]]
--local nkeys = require "table.nkeys"
--local isarray = require "table.isarray"
--local isempty = require "table.isempty"

local newtab = table.new
local sort = table.sort
local insert = table.insert
local concat = table.concat
local remove = table.remove
local setmetatable = setmetatable
local pairs = pairs
local ipairs = ipairs
local len = string.len
local sub = string.sub
local gsub = string.gsub
local ceil = math.ceil


local _AhoCorasick = {}
_AhoCorasick.VERSION = "v0.1"

local CHILDREN_ARRAY_LIMIT = 6

local stringutf8 = {}

function stringutf8.toCharArray(str)
    local array
    if str then
        local length = len(str)
        array = newtab(length, 0)

        local byteLength = 1
        local i, j = 1, 1
        while i <= length do
            local firstByte = string.byte(str, i)
            if firstByte >=0 and firstByte < 128 then
                byteLength = 1
            elseif firstByte >191 and firstByte < 224 then
                byteLength = 2
            elseif firstByte >223 and firstByte < 240 then
                byteLength = 3
            elseif firstByte >239 and firstByte < 248 then
                byteLength = 4
            end

            j = i + byteLength
            local char = sub(str, i, j - 1)
            i = j
            insert(array, char)
        end
    end

    return array
end

function stringutf8.sub(str, i, j)
    local subStr
    if str then
        if i == nil then
            i = 1
        end

        local array = stringutf8.toCharArray(str)
        if array then
            local length = #array

            if not j then
                subStr = concat(array, "", i)
            else
                if j < 0 then
                    j = length + j + 1
                end
                subStr = concat(array, "", i, j)
            end
        end
    end

    return subStr
end

function stringutf8.trim(str)
    if str then
        str = gsub(str, "^%s*|%s*$", "")
    end

    return str
end

local arrays = {}

function arrays.binarySearch(array, fromIndex, toIndex, item)
    if not array or #array == 0 then
        return -1
    end

    if fromIndex > toIndex then
        error("out of range: " .. fromIndex .. "," .. toIndex)
    end

    local low = fromIndex
    local high = toIndex

    while low <= high do
        --local mid = rshift(low + high, 1)
        local mid = ceil((low + high) / 2)

        local midVal = array[mid]
        if midVal < item then
            low = mid + 1
        elseif midVal > item then
            high = mid - 1
        else
            return mid
        end
    end

    return -low
end

local function isarray(t)
    if not t then
        return false
    end

    if type(t) ~= "table" then
        return false
    end

    local n = #t
    for i, _ in pairs(t) do
        if type(i) ~= "number" then
            return false
        end

        if i > n then
            return false
        end
    end

    return true
end

local function nkeys(t)
    local length = 0
    if t then
        for i, _ in pairs(t) do
            length = length + 1
        end
    end
    return length
end

local _TrieNode = {}

local mt_trienode = {__index = _TrieNode,
                    __eq = function(a, b)
                        return a.word == b.word
                    end,
                    __lt = function(a, b)
                        return a.word < b.word
                    end,
                    __tostring = function (t)
                        return t.word
                    end}

function _TrieNode:new(word, depth)
    local t = {
            word = word,
            children = nil,
            isEnd = false,
            count = 1,
            fail = nil,
            depth = depth and depth or 1}

    setmetatable(t, mt_trienode)
    return t
end

local _Trie = {}
local mt_trie = {__index = _Trie}

function _Trie:new(arrayLimit)
    local t = {
            rootNode = _TrieNode:new("/"),
            childrenArrayLimit = arrayLimit and arrayLimit or CHILDREN_ARRAY_LIMIT
        }

    setmetatable(t, mt_trie)
    return t
end

function _Trie:addNodes(str)
    if not str or str == '' or type(str) ~= "string" then
        return
    end
    str = stringutf8.trim(str)

    local current = self.rootNode
    local array = stringutf8.toCharArray(str)
    for i, word in ipairs(array) do
        local children = current.children
        if not children then
            if self.childrenArrayLimit > 0 then
                children = newtab(self.childrenArrayLimit, 0)
            else
                children = newtab(0, self.childrenArrayLimit)
            end
        end

        local node

		local storedSize = nkeys(children)
        if self.childrenArrayLimit > 0 and storedSize < self.childrenArrayLimit then
            node = _TrieNode:new(word, i)
            local pos = arrays.binarySearch(children, 1, storedSize, node)
            if pos > 0 then
                node = children[pos]
                node.count = node.count + 1
            else
                children[storedSize + 1] = node
                sort(children, function(a, b)
                    return a.word < b.word
                end)
            end

            current.children = children
        else
            if storedSize > 0 and isarray(children) then
                local newChildren = newtab(0, self.childrenArrayLimit + 1)
                for _, v in ipairs(children) do
                    newChildren[v.word] = v
                end
                --current.children = newChildren
                children = newChildren
            end

            node = children[word]
            if node then
                node.count = node.count + 1
            else
                node = _TrieNode:new(word, i)
                children[word] = node
            end

            current.children = children
        end
        current = node
    end
    current.isEnd = true

    return self.rootNode
end

function _Trie:contains(str)
    if not str or str == "" or type(str) ~= "string" then
        return false
    end
    local current = self.rootNode
    local children
    local array = stringutf8.toCharArray(str)
    for _, word in ipairs(array) do
        children = current.children
        if children then
            if isarray(children) then
                local storedSize = nkeys(children)
                local pos = arrays.binarySearch(children, 1, storedSize, _TrieNode:new(word))

                if pos > 0 then
                    current = children[pos]
                else
                    return false
                end
            else
                current = children[word]
            end
        else
            return false
        end
    end

    if current.isEnd then
        return true
    end

    return false
end

local mt_ac = {__index = _AhoCorasick}

function _AhoCorasick:new(arrayLimit)
    local t = {
            trie = _Trie:new(arrayLimit),
            builded = false
        }

    setmetatable(t, mt_ac)
    return t
end

local function pop(t)
    if t then
        local element = t[1]
        remove(t, 1)
        return element
    end
end

local function push(t, e)
    if t then
        insert(t, e)
    end
end

local function getFail(self, childNode, fatherFail)
    local fail
    local children = fatherFail.children
    if children then
        if isarray(children) then
            local storedSize = nkeys(children)
            local pos = arrays.binarySearch(children, 1, storedSize, childNode)
            if pos > 0 then
                fail = children[pos]
            end
        else
            local word = childNode.word
            local temp = children[word]
            if temp then
                fail = temp
            end
        end
    end


    if fail then
        return fail
    end

    if fatherFail == self.trie.rootNode then
        return fatherFail
    end

    return getFail(self, childNode, fatherFail.fail)
end

function _AhoCorasick:buildFail()
    local trie = self.trie
    local rootNode = trie.rootNode

    rootNode.fail = rootNode
    local queue = {}
    push(queue, rootNode)

    while nkeys(queue) > 0 do
        local parrent = pop(queue)
        if not parrent then
            break
        end

        local fatherFail = parrent.fail
        local children = parrent.children
        if children then
            for _, child in pairs(children) do

                if parrent == rootNode and child ~= rootNode then
                    child.fail = rootNode
                else
                    local failNode = getFail(self, child, fatherFail)
                    child.fail = failNode
                end

                push(queue, child)
            end
        end
    end

    self.builded = true
end

function _AhoCorasick:add(words)
    if not words then
        return
    end

    local trie = self.trie
    local paramType = type(words)
    if paramType == 'table' then
        if #words > 0 then
            for _, w in ipairs(words) do
                trie:addNodes(w)
            end
        end
    elseif paramType == 'string' then
        trie:addNodes(words)
    else
        error('table or string expected, got ' .. paramType)
    end

    self.builded = false
end

function _AhoCorasick:match(str, simpleMode)
    if not str or str == '' then
        return
    end

    local array = stringutf8.toCharArray(str)
    if not array or #array == 0 then
        return
    end

    if not self.builded then
        self:buildFail()
    end

    local result = {}
    local rootNode = self.trie.rootNode
    local current = rootNode

    for i, word in ipairs(array) do
        while true do
            local children = current.children
            if children then
                if isarray(children) then
                    local pos = arrays.binarySearch(children, 1, nkeys(children), _TrieNode:new(word))
                    if pos > 0 then
                        current = children[pos]
                        break
                    end
                else
                    local temp = children[word]
                    if temp then
                        current = temp
                        break
                    end
                end
            end

            if current ~= rootNode then
                current = current.fail
            else
                break
            end
        end

        if not current then
            current = rootNode
        end

        local temp = current
        while temp ~= rootNode do
            if temp.isEnd then
                if simpleMode == true then
                    insert(result, stringutf8.sub(str, i - temp.depth + 1, i))
                else
                    local from, to = i - temp.depth + 1, i
                    local words = stringutf8.sub(str, from, to)
                    insert(result, {words = words, from = from, to = to})
                end
            end
            temp = temp.fail
        end
    end

    return result
end

return _AhoCorasick