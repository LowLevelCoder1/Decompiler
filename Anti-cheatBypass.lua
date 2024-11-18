--[[ 
RealBypass v1.0
Created by H4X0R 
Anti-Cheat bypass script. Reduces detection risks for executors.
Note: This script doesn't guarantee 100% safety from detection.
]]

coroutine.resume(coroutine.create(function()
    -- Wait until the game is fully loaded
    repeat wait() until game:IsLoaded()

    -- Hook garbage collection methods
    local OriginalGcInfo = gcinfo()
    local RandomOffset = 0

    game:GetService("RunService").Stepped:Connect(function()
        RandomOffset = math.random(-200, 200)
    end)

    local gcinfoHook; gcinfoHook = hookfunction(getrenv().gcinfo, function(...)
        if not checkcaller() then
            return OriginalGcInfo + RandomOffset
        end
        return gcinfoHook(...)
    end)

    local collectgarbageHook; collectgarbageHook = hookfunction(getrenv().collectgarbage, function(action, ...)
        if not checkcaller() and action == "collect" then
            return OriginalGcInfo + RandomOffset
        end
        return collectgarbageHook(action, ...)
    end)
end))

-- Anti InstanceCount detection
local function CountExploitInstances()
    local AllowedInstances = {
        "DevConsoleMaster", "BubbleChat", "ThemeProvider", "HeadsetDisconnectedDialog",
        "PurchasePrompt", "RobloxNetworkPauseNotification", "PlayerList", "RobloxLoadingGui",
        "RobloxPromptGui", "TeleportGui", "CoreScriptLocalization", "RobloxGui"
    }

    local ExploitInstanceCount = 0
    for _, child in pairs(game:GetService("CoreGui"):GetChildren()) do
        if not table.find(AllowedInstances, child.Name) then
            ExploitInstanceCount += 1 + #child:GetDescendants()
        end
    end
    return ExploitInstanceCount
end

local StatsService = game:GetService("Stats")
local InstanceCountHook; InstanceCountHook = hookmetamethod(game, "__index", function(self, key, ...)
    if not checkcaller() and self == StatsService and key == "InstanceCount" then
        return InstanceCountHook(self, key, ...) - CountExploitInstances()
    end
    return InstanceCountHook(self, key, ...)
end)

-- Anti DescendantAdded/Removing detection
local DescendantAddedEvent = Instance.new("BindableEvent")
local DescendantRemovingEvent = Instance.new("BindableEvent")

game.DescendantAdded:Connect(function(instance)
    if not instance:IsDescendantOf(game:GetService("CoreGui")) then
        DescendantAddedEvent:Fire(instance)
    end
end)

game.DescendantRemoving:Connect(function(instance)
    if not instance:IsDescendantOf(game:GetService("CoreGui")) then
        DescendantRemovingEvent:Fire(instance)
    end
end)

local DescendantHook; DescendantHook = hookmetamethod(game, "__index", function(self, key, ...)
    if not checkcaller() and self == game then
        if key == "DescendantAdded" then
            return DescendantAddedEvent.Event
        elseif key == "DescendantRemoving" then
            return DescendantRemovingEvent.Event
        end
    end
    return DescendantHook(self, key, ...)
end)

-- Anti GetFocusedTextBox detection
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local NamecallHook; NamecallHook = hookmetamethod(game, "__namecall", function(self, ...)
    if not checkcaller() and self == UIS and getnamecallmethod() == "GetFocusedTextBox" then
        local result = NamecallHook(self, ...)
        if result and result:IsDescendantOf(CoreGui) then
            return nil
        end
    end
    return NamecallHook(self, ...)
end)

-- Anti newproxy detection
local Proxies = {}
local NewProxyHook; NewProxyHook = hookfunction(getrenv().newproxy, function(...)
    local proxy = NewProxyHook(...)
    table.insert(Proxies, proxy)
    return proxy
end)

game:GetService("RunService").Stepped:Connect(function()
    for _, proxy in pairs(Proxies) do
        if proxy == nil then
            -- Bypass detection logic by ensuring newproxy objects are preserved
        end
    end
end)
