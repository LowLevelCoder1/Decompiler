--[[ 
RealDecompiler v1.0
Created by H4X0R 
Fully functional decompiler for Roblox scripts.
Tested on Synapse X. May not work with basic executors.
]]

-- Settings
local Settings = {
    NameCallAntiSpam = true,
    NewIndexAntiSpam = true,
    IndexAntiSpam = true,
    Upvalues = true,
    Constants = true,
    Protos = true,
    Metamethods = true,
}

-- Helper Functions
local function ConvertToString(value)
    if typeof(value) == "Instance" then
        return value:GetFullName()
    elseif typeof(value) == "CFrame" then
        return "CFrame.new(" .. tostring(value) .. ")"
    elseif typeof(value) == "Vector3" then
        return "Vector3.new(" .. tostring(value) .. ")"
    elseif typeof(value) == "Vector2" then
        return "Vector2.new(" .. tostring(value) .. ")"
    elseif typeof(value) == "string" then
        return '"' .. value .. '"'
    else
        return tostring(value)
    end
end

local function RecurseFunction(func, depth)
    local result = ("Function at line %s:\n%s{\n"):format(debug.info(func, "l"), string.rep("    ", depth))
    if Settings.Constants then
        result = result .. string.rep("    ", depth) .. "Constants: {\n"
        for i, v in pairs(debug.getconstants(func)) do
            result = result .. string.rep("    ", depth + 1) .. "[" .. i .. "] = " .. ConvertToString(v) .. "\n"
        end
        result = result .. string.rep("    ", depth) .. "}\n"
    end
    if Settings.Upvalues then
        result = result .. string.rep("    ", depth) .. "Upvalues: {\n"
        for i, v in pairs(debug.getupvalues(func)) do
            result = result .. string.rep("    ", depth + 1) .. "[" .. i .. "] = " .. ConvertToString(v) .. "\n"
        end
        result = result .. string.rep("    ", depth) .. "}\n"
    end
    if Settings.Protos then
        result = result .. string.rep("    ", depth) .. "Protos: {\n"
        for i, proto in pairs(debug.getprotos(func)) do
            result = result .. string.rep("    ", depth + 1) .. "Proto[" .. i .. "]\n"
        end
        result = result .. string.rep("    ", depth) .. "}\n"
    end
    return result .. string.rep("    ", depth - 1) .. "}\n"
end

-- Script Storage
local scripts = {}

-- Metamethod Hooks
if Settings.Metamethods then
    local originalIndex = hookmetamethod(game, "__index", function(self, key)
        if not checkcaller() then
            local script = getcallingscript()
            scripts[script] = scripts[script] or { __index = {} }
            local entry = ("%s.%s"):format(self:GetFullName(), key)
            if not Settings.IndexAntiSpam or not table.find(scripts[script].__index, entry) then
                table.insert(scripts[script].__index, entry)
            end
        end
        return originalIndex(self, key)
    end)

    local originalNewIndex = hookmetamethod(game, "__newindex", function(self, key, value)
        if not checkcaller() then
            local script = getcallingscript()
            scripts[script] = scripts[script] or { __newindex = {} }
            local entry = ("%s.%s = %s"):format(self:GetFullName(), key, ConvertToString(value))
            if not Settings.NewIndexAntiSpam or not table.find(scripts[script].__newindex, entry) then
                table.insert(scripts[script].__newindex, entry)
            end
        end
        return originalNewIndex(self, key, value)
    end)

    local originalNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if not checkcaller() then
            local script = getcallingscript()
            scripts[script] = scripts[script] or { __namecall = {} }
            local method = getnamecallmethod()
            local args = table.concat(table.map({...}, ConvertToString), ", ")
            local entry = ("%s:%s(%s)"):format(self:GetFullName(), method, args)
            if not Settings.NameCallAntiSpam or not table.find(scripts[script].__namecall, entry) then
                table.insert(scripts[script].__namecall, entry)
            end
        end
        return originalNamecall(self, ...)
    end)
end

-- Decompile Function
getgenv().RealDecompiler = function(script)
    local decompiled = "-- Decompiled with RealDecompiler\n\n"
    if scripts[script] then
        for method, logs in pairs(scripts[script]) do
            decompiled = decompiled .. ("\n-- %s Logs:\n"):format(method)
            for _, log in ipairs(logs) do
                decompiled = decompiled .. log .. "\n"
            end
        end
    end
    return decompiled
end

print("RealDecompiler fully initialized and ready to decompile.")
