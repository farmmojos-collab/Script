
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local TextService = game:GetService("TextService")
local plr = Players.LocalPlayer
function isTouchMobileDevice()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end
Settings = Settings
Window = Window
local ReplicatedStorage = game:GetService("ReplicatedStorage")

function getAsterEnv()
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then
            return env
        end 
    end
    error("[ASTER] getgenv() is required")
end

local __ASTER_RUNTIME = getAsterEnv().__ASTER_RUNTIME
if type(__ASTER_RUNTIME) ~= "table" then
    __ASTER_RUNTIME = { connections = {} }
    getAsterEnv().__ASTER_RUNTIME = __ASTER_RUNTIME
elseif type(__ASTER_RUNTIME.connections) ~= "table" then
    __ASTER_RUNTIME.connections = {}
end
__ASTER_RUNTIME.sessionId = (__ASTER_RUNTIME.sessionId or 0) + 1
local CURRENT_SESSION = __ASTER_RUNTIME.sessionId
__ASTER_RUNTIME.tribeCacheLoopStarted = false
__ASTER_RUNTIME.autoDropLoopStarted = false
__ASTER_RUNTIME.waypointDropdownLoopStarted = false
__ASTER_RUNTIME.combatTargetLoopStarted = false
__ASTER_RUNTIME.targetHighlightLoopStarted = false
__ASTER_RUNTIME.pathFinderRefreshStarted = false
__ASTER_RUNTIME.silentAimEngineReady = false
__ASTER_RUNTIME.autoShootLoopStarted = false
__ASTER_RUNTIME.packetIdAutoSyncStarted = false

local _guiAlias = {
    ASTERHub = "Camera",
    AsterStaffAlertGui = "Lighting",
    ASTER_FOV_Overlay = "NetworkClient",
    AsterKeybindsOverlay = "InsertService",
    AsterHealGui = "TimerService",
    AsterAutoChestGui = "CookieService",
}
local _folderAlias = {
    AsterCustomPlacementPreview = "Accoutrements",
    AsterCustomPlacementLocations = "WrapDeformer",
    AsterPreviewContainer = "Geometry",
}

function getAsterHiddenUI()
    if typeof(__ASTER_RUNTIME.hiddenUI) == "Instance" then
        return __ASTER_RUNTIME.hiddenUI
    end
    local ui
    if type(gethui) == "function" then
        pcall(function() ui = gethui() end)
    end
    if typeof(ui) ~= "Instance" then
        pcall(function() ui = game:GetService("CoreGui") end)
    end
    if typeof(ui) ~= "Instance" then
        local lp = game:GetService("Players").LocalPlayer
        ui = lp and (lp:FindFirstChild("PlayerGui") or lp:WaitForChild("PlayerGui", 2))
    end
    __ASTER_RUNTIME.hiddenUI = ui
    return ui
end

function getAsterHiddenWorkspace()
    if __ASTER_RUNTIME.hiddenWorkspace ~= nil then
        return __ASTER_RUNTIME.hiddenWorkspace
    end
    local ws = workspace
    if type(cloneref) == "function" then
        local ok, ref = pcall(cloneref, workspace)
        if ok and ref ~= nil then ws = ref end
    end
    __ASTER_RUNTIME.hiddenWorkspace = ws
    return ws
end

function asterGuiCoverName(key)
    __ASTER_RUNTIME.guiCoverNames = __ASTER_RUNTIME.guiCoverNames or {}
    local hit = __ASTER_RUNTIME.guiCoverNames[key]
    if hit then return hit end
    hit = _guiAlias[key] or "Camera"
    __ASTER_RUNTIME.guiCoverNames[key] = hit
    return hit
end

function asterWipeStaleGuis()
    local kill = {
        Camera = true, Overlay = true, Lighting = true, NetworkClient = true,
        InsertService = true, TimerService = true, CookieService = true,
    }
    if type(__ASTER_RUNTIME.guiCoverNames) == "table" then
        for _, n in pairs(__ASTER_RUNTIME.guiCoverNames) do
            kill[n] = true
        end
    end
    local function wipe(parent)
        if typeof(parent) ~= "Instance" then return end
        for _, gui in ipairs(parent:GetChildren()) do
            if gui:IsA("ScreenGui") then
                local n = gui.Name
                if kill[n] or string.find(n, "Aster", 1, true) or string.find(n, "ASTER", 1, true) then
                    pcall(function() gui:Destroy() end)
                end
            end
        end
    end
    pcall(function() wipe(game:GetService("CoreGui")) end)
    wipe(getAsterHiddenUI())
    local lp = game:GetService("Players").LocalPlayer
    if lp then wipe(lp:FindFirstChild("PlayerGui")) end
end

function asterParentGui(gui, key)
    if typeof(gui) ~= "Instance" then return end
    __ASTER_RUNTIME.hiddenGuis = __ASTER_RUNTIME.hiddenGuis or {}
    if type(key) == "string" and key ~= "" then
        pcall(function() gui.Name = asterGuiCoverName(key) end)
        __ASTER_RUNTIME.hiddenGuis[key] = gui
    end
    local ui = getAsterHiddenUI()
    if typeof(ui) == "Instance" then
        pcall(function() gui.Parent = ui end)
    else
        pcall(function() gui.Parent = game:GetService("CoreGui") end)
    end
end

function asterFindGui(key)
    local stored = __ASTER_RUNTIME.hiddenGuis and __ASTER_RUNTIME.hiddenGuis[key]
    if typeof(stored) == "Instance" and stored.Parent then return stored end
    local cover = asterGuiCoverName(key)
    local function look(parent)
        if typeof(parent) ~= "Instance" then return nil end
        local a = parent:FindFirstChild(cover)
        if a and a:IsA("ScreenGui") then return a end
        local b = parent:FindFirstChild(key)
        if b and b:IsA("ScreenGui") then return b end
        return nil
    end
    return look(getAsterHiddenUI()) or look(game:GetService("CoreGui"))
end

function asterEnsureWorldFolder(key)
    __ASTER_RUNTIME.hiddenWorldFolders = __ASTER_RUNTIME.hiddenWorldFolders or {}
    local folder = __ASTER_RUNTIME.hiddenWorldFolders[key]
    if typeof(folder) == "Instance" and folder.Parent then return folder end

    local cover = _folderAlias[key] or "Geometry"
    local hiddenWs = getAsterHiddenWorkspace()
    local function pick(parent)
        if typeof(parent) ~= "Instance" then return nil end
        local found = parent:FindFirstChild(cover) or parent:FindFirstChild(key)
        if found and found:IsA("Folder") then return found end
        return nil
    end
    folder = pick(hiddenWs) or pick(workspace)
    if not folder then folder = Instance.new("Folder") end
    pcall(function()
        folder.Name = cover
        folder.Archivable = false
        folder.Parent = hiddenWs or workspace
    end)
    for _, parent in ipairs({ workspace, hiddenWs }) do
        if typeof(parent) == "Instance" then
            local old = parent:FindFirstChild(key)
            if old and old ~= folder and old:IsA("Folder") then
                for _, ch in ipairs(old:GetChildren()) do
                    pcall(function() ch.Parent = folder end)
                end
                pcall(function() old:Destroy() end)
            end
        end
    end
    __ASTER_RUNTIME.hiddenWorldFolderShadow = __ASTER_RUNTIME.hiddenWorldFolderShadow or {}
    if not __ASTER_RUNTIME.hiddenWorldFolderShadow[key] then
        __ASTER_RUNTIME.hiddenWorldFolderShadow[key] = true
        folder.DescendantAdded:Connect(function(desc)
            if desc:IsA("BasePart") then desc.CastShadow = false end
        end)
    end
    __ASTER_RUNTIME.hiddenWorldFolders[key] = folder
    return folder
end

do
    local conns = __ASTER_RUNTIME.connections
    if type(conns) == "table" then
        for _, key in ipairs({ "masterFrame", "masterHeartbeat" }) do
            local old = conns[key]
            if old then
                pcall(function()
                    if old.Disconnect then old:Disconnect() end
                end)
                conns[key] = nil
            end
        end
    end
end
__ASTER_RUNTIME.masterFrameStarted = false
__ASTER_RUNTIME.masterHeartbeatStarted = false
__ASTER_RUNTIME.frameUpdates = {}
__ASTER_RUNTIME.heartbeatUpdates = {}
__ASTER_RUNTIME.webhookStats = __ASTER_RUNTIME.webhookStats or {
    planted = 0,
    harvested = 0,
    broken = {},
}
__ASTER_RUNTIME.webhookResourceEids = __ASTER_RUNTIME.webhookResourceEids or {}
__ASTER_RUNTIME.recordGrindGain = __ASTER_RUNTIME.recordGrindGain or function() end
__ASTER_RUNTIME.recordGrindLoss = __ASTER_RUNTIME.recordGrindLoss or function() end
__ASTER_RUNTIME.recordChestTeleport = __ASTER_RUNTIME.recordChestTeleport or function() end

function getWorkspaceResources()
    local f = workspace:FindFirstChild("Resources")
    if f then return f end
    return nil
end
function getWorkspaceDeployables()
    local cached = __ASTER_RUNTIME.deployablesFolder
    if cached and cached.Parent then
        return cached
    end
    local f = workspace:FindFirstChild("Deployables")
    if f then
        __ASTER_RUNTIME.deployablesFolder = f
        return f
    end
    return nil
end

function isPlantBoxDeployable(inst)
    if not inst then return false end
    if not (inst:IsA("Model") or inst:IsA("BasePart")) then return false end
    local n = inst.Name
    if n == "Plant Box" or n == "PlantBox" then return true end
    local lower = string.lower(tostring(n))
    if string.find(lower, "plant", 1, true) and string.find(lower, "box", 1, true) then
        return true
    end
    local attrId = inst:GetAttribute("ItemID") or inst:GetAttribute("itemID") or inst:GetAttribute("ID") or inst:GetAttribute("StructureID")
    if attrId ~= nil then
        local plantId = getPlantBoxItemId()
        local num = tonumber(attrId)
        if plantId and num and num == plantId then
            return true
        end
        if type(craftItemIDs) == "table" then
            local mapped = craftItemIDs[num or attrId] or craftItemIDs[tostring(attrId)]
            if type(mapped) == "string" then
                local mappedLower = string.lower(mapped)
                if string.find(mappedLower, "plant", 1, true) and string.find(mappedLower, "box", 1, true) then
                    return true
                end
            end
        end
    end
    return false
end

function getPlantBoxPartCheap(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model end
    local pp = model.PrimaryPart
    if pp then return pp end
    return model:FindFirstChildWhichIsA("BasePart")
end

_plantBoxItemId = nil
_plantBoxItemIdAt = 0
function getPlantBoxItemId()
    local now = tick()
    if _plantBoxItemId and (now - _plantBoxItemIdAt) < 15 then
        return _plantBoxItemId
    end
    local id = nil
    if type(craftNameToID) == "table" then
        id = craftNameToID["Plant Box"] or craftNameToID["PlantBox"] or craftNameToID["Plant box"]
    end
    if not id and type(autoDiscoverItemID) == "function" then
        id = autoDiscoverItemID("Plant Box") or autoDiscoverItemID("PlantBox")
    end
    id = tonumber(id)
    if id then
        _plantBoxItemId = id
        _plantBoxItemIdAt = now
    end
    return _plantBoxItemId
end

local function liveIndexDisconnect(prefix)
    local rt = __ASTER_RUNTIME
    if type(rt) ~= "table" then return end
    for _, suffix in ipairs({ "Add", "Rem" }) do
        local key = prefix .. suffix
        local conn = rt[key]
        if conn then
            pcall(function()
                if conn.Disconnect then conn:Disconnect() end
            end)
            rt[key] = nil
        end
    end
end

local function liveIndexAdd(prefix, inst)
    local rt = __ASTER_RUNTIME
    local index, list = rt[prefix .. "Index"], rt[prefix .. "List"]
    if type(index) ~= "table" or type(list) ~= "table" or not inst or index[inst] then return end
    local n = #list + 1
    list[n] = inst
    index[inst] = n
    rt[prefix .. "Gen"] = (rt[prefix .. "Gen"] or 0) + 1
end

local function liveIndexRemove(prefix, inst)
    local rt = __ASTER_RUNTIME
    local index, list = rt[prefix .. "Index"], rt[prefix .. "List"]
    if type(index) ~= "table" or type(list) ~= "table" or not inst then return end
    local i = index[inst]
    if not i then return end
    local n = #list
    local last = list[n]
    list[i] = last
    if last then index[last] = i end
    list[n] = nil
    index[inst] = nil
    rt[prefix .. "Gen"] = (rt[prefix .. "Gen"] or 0) + 1
end

local function ensureLiveFolderIndex(folder, prefix, matchFn)
    local rt = __ASTER_RUNTIME
    if not folder then return nil end
    if rt[prefix .. "Folder"] == folder and type(rt[prefix .. "List"]) == "table" then
        return rt[prefix .. "List"]
    end
    liveIndexDisconnect(prefix)
    rt[prefix .. "Folder"] = folder
    rt[prefix .. "List"] = {}
    rt[prefix .. "Index"] = {}
    rt[prefix .. "Gen"] = (rt[prefix .. "Gen"] or 0) + 1
    rt[prefix .. "Add"] = folder.ChildAdded:Connect(function(ch)
        if matchFn(ch) then liveIndexAdd(prefix, ch) end
    end)
    rt[prefix .. "Rem"] = folder.ChildRemoved:Connect(function(ch)
        liveIndexRemove(prefix, ch)
    end)
    task.spawn(function()
        local kids = folder:GetChildren()
        local i = 1
        local n = #kids
        while i <= n and rt[prefix .. "Folder"] == folder do
            local step = 0
            while step < 50 and i <= n do
                local ch = kids[i]
                if matchFn(ch) then liveIndexAdd(prefix, ch) end
                i = i + 1
                step = step + 1
            end
            task.wait()
        end
        table.clear(kids)
    end)
    return rt[prefix .. "List"]
end

function isPlantBoxNameFast(inst)
    if not inst then return false end
    local n = inst.Name
    return n == "Plant Box" or n == "PlantBox"
end

function getPlantBoxModelsCached()
    local dep = getWorkspaceDeployables()
    if not dep then return nil end
    return ensureLiveFolderIndex(dep, "plantBox", isPlantBoxNameFast)
end

function getFruitCropModelsCached(fruitFilter)
    local crops = getWorkspaceCrops()
    if not crops then return nil end
    return ensureLiveFolderIndex(crops, "cropLive", function(inst)
        return inst and (inst:IsA("Model") or inst:IsA("BasePart"))
    end)
end
function getWorkspaceCritters()
    local cached = __ASTER_RUNTIME.crittersFolder
    if cached and cached.Parent then
        return cached
    end
    local f = workspace:FindFirstChild("Critters")
    if not f then
        f = workspace:WaitForChild("Critters", 2)
    end
    if f then
        __ASTER_RUNTIME.crittersFolder = f
    end
    return f
end

function isWorkspaceCritterInstance(inst)
    return inst and (inst:IsA("Model") or inst:IsA("BasePart"))
end

function getWorkspaceCritterModel(inst)
    if not inst then return nil end
    if inst:IsA("Model") then return inst end
    if inst:IsA("BasePart") then
        local parent = inst.Parent
        if parent and parent:IsA("Model") then return parent end
    end
    return nil
end

function getWorkspaceCritterName(inst)
    local model = getWorkspaceCritterModel(inst)
    if model then return model.Name end
    return inst and inst.Name or ""
end

function getWorkspaceCritterPart(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then
        return inst.PrimaryPart
            or inst:FindFirstChild("HumanoidRootPart")
            or inst:FindFirstChild("Head")
            or inst:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

function isWorkspaceCritterAlive(inst)
    if not inst or not inst.Parent then return false end
    local folder = getWorkspaceCritters()
    if folder and not inst:IsDescendantOf(folder) then return false end
    local model = getWorkspaceCritterModel(inst) or (inst:IsA("Model") and inst or nil)
    if model then
        local hum = model:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then return false end
    end
    local part = getWorkspaceCritterPart(inst)
    if not part or not part.Parent then return false end
    if part.Size.Magnitude < 0.01 then return false end
    return true
end

function critterNameMatchesFilter(modelName, filterText, allToken)
    if not modelName then return false end
    filterText = tostring(filterText or allToken or "")
    local f = string.lower(string.gsub(filterText, "^%s+", ""))
    f = string.gsub(f, "%s+$", "")
    if f == "" or f == "all" then return true end
    local token = string.lower(tostring(allToken or ""))
    if token ~= "" and f == token then return true end
    if string.sub(f, 1, 3) == "all" then return true end
    local nameLower = string.lower(modelName)
    if nameLower == f then return true end
    if string.find(nameLower, f, 1, true) then return true end
    return false
end

function forEachWorkspaceCritter(folder, fn)
    if not folder or type(fn) ~= "function" then return end
    local function walk(node)
        for _, child in ipairs(node:GetChildren()) do
            if isWorkspaceCritterInstance(child) then
                fn(child)
            elseif child:IsA("Folder") then
                walk(child)
            end
        end
    end
    walk(folder)
end

function collectWorkspaceCritters(folder)
    folder = folder or getWorkspaceCritters()
    local out = {}
    if not folder then return out end
    forEachWorkspaceCritter(folder, function(critter)
        table.insert(out, critter)
    end)
    return out
end

function getWorkspaceCritterNameList(opts)
    opts = opts or {}
    local names = {}
    local seen = {}
    if opts.includeAll ~= false then
        table.insert(names, "All")
        seen.All = true
    end
    local folder = getWorkspaceCritters()
    if folder then
        forEachWorkspaceCritter(folder, function(critter)
            local n = getWorkspaceCritterName(critter)
            if n and n ~= "" and not seen[n] then
                seen[n] = true
                table.insert(names, n)
            end
        end)
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("Folder") then
                local n = child.Name
                if n and n ~= "" and not seen[n] then
                    seen[n] = true
                    table.insert(names, n)
                end
            end
        end
    end
    table.sort(names, function(a, b)
        if a == "All" then return true end
        if b == "All" then return false end
        return a < b
    end)
    return names
end
function getWorkspaceCrops()
    local cached = __ASTER_RUNTIME.cropsFolder
    if cached and cached.Parent then
        return cached
    end
    local f = workspace:FindFirstChild("Crops")
    if f then
        __ASTER_RUNTIME.cropsFolder = f
        return f
    end
    return nil
end

function getWorkspaceCropModel(inst)
    if not inst then return nil end
    if inst:IsA("Model") then return inst end
    return inst:FindFirstAncestorOfClass("Model")
end

function getWorkspaceCropPart(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then
        return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

function forEachWorkspaceCrop(fn)
    local folder = getWorkspaceCrops()
    if not folder or type(fn) ~= "function" then return end
    local function walk(node)
        for _, child in ipairs(node:GetChildren()) do
            if child:IsA("Model") or child:IsA("BasePart") then
                fn(child)
            elseif child:IsA("Folder") then
                walk(child)
            end
        end
    end
    walk(folder)
end


function isRuntimeSessionActive(session)
    local rt = getAsterEnv().__ASTER_RUNTIME
    if type(rt) ~= "table" then return false end
    return session == rt.sessionId
end

function trackConnection(key, conn)
    local rt = getAsterEnv().__ASTER_RUNTIME
    if type(rt) ~= "table" then
        return conn
    end
    if type(rt.connections) ~= "table" then
        rt.connections = {}
    end
    local old = rt.connections[key]
    if old and old.Disconnect then
        pcall(function() old:Disconnect() end)
    end
    rt.connections[key] = conn
    return conn
end

if not (getAsterEnv().__ASTER_RUNTIME and getAsterEnv().__ASTER_RUNTIME.crittersFolderWatcher) then
    local rt = getAsterEnv().__ASTER_RUNTIME
    if type(rt) == "table" then
        rt.crittersFolderWatcher = true
        trackConnection("crittersFolder_ChildAdded", workspace.ChildAdded:Connect(function(child)
            local runtime = getAsterEnv().__ASTER_RUNTIME
            if type(runtime) ~= "table" then return end
            if child.Name == "Critters" then
                runtime.crittersFolder = child
            elseif child.Name == "Crops" then
                runtime.cropsFolder = child
            elseif child.Name == "Deployables" then
                runtime.deployablesFolder = child
            end
        end))
    end
end

function registerFrameUpdate(key, fn)
    local rt = getAsterEnv().__ASTER_RUNTIME
    if type(rt) ~= "table" then return end
    if type(rt.frameUpdates) ~= "table" then rt.frameUpdates = {} end
    rt.frameUpdates[key] = fn
end

function unregisterFrameUpdate(key)
    local rt = getAsterEnv().__ASTER_RUNTIME
    if type(rt) ~= "table" or type(rt.frameUpdates) ~= "table" then return end
    rt.frameUpdates[key] = nil
end

function registerHeartbeatUpdate(key, fn)
    local rt = getAsterEnv().__ASTER_RUNTIME
    if type(rt) ~= "table" then return end
    if type(rt.heartbeatUpdates) ~= "table" then rt.heartbeatUpdates = {} end
    rt.heartbeatUpdates[key] = fn
end

function unregisterHeartbeatUpdate(key)
    local rt = getAsterEnv().__ASTER_RUNTIME
    if type(rt) ~= "table" or type(rt.heartbeatUpdates) ~= "table" then return end
    rt.heartbeatUpdates[key] = nil
end

function ensureMasterFrameLoop()
    local rt = getAsterEnv().__ASTER_RUNTIME
    if type(rt) ~= "table" then return end
    if type(rt.frameUpdates) ~= "table" then rt.frameUpdates = {} end
    if rt.masterFrameStarted then return end
    rt.masterFrameStarted = true
    local RunService = game:GetService("RunService")
    trackConnection("masterFrame", RunService.RenderStepped:Connect(function(dt)
        local runtime = getAsterEnv().__ASTER_RUNTIME
        local updates = runtime and runtime.frameUpdates
        if type(updates) ~= "table" then return end
        for _, fn in pairs(updates) do
            if fn then
                pcall(fn, dt)
            end
        end
    end))
end

function ensureMasterHeartbeatLoop()
    local rt = getAsterEnv().__ASTER_RUNTIME
    if type(rt) ~= "table" then return end
    if type(rt.heartbeatUpdates) ~= "table" then rt.heartbeatUpdates = {} end
    if rt.masterHeartbeatStarted then return end
    rt.masterHeartbeatStarted = true
    local RunService = game:GetService("RunService")
    trackConnection("masterHeartbeat", RunService.Heartbeat:Connect(function(dt)
        local runtime = getAsterEnv().__ASTER_RUNTIME
        local updates = runtime and runtime.heartbeatUpdates
        if type(updates) ~= "table" then return end
        for _, fn in pairs(updates) do
            if fn then
                pcall(fn, dt)
            end
        end
    end))
end

-- Allow multiple instances: re-running creates a new UI.

local ByteNetReliable = ReplicatedStorage:FindFirstChild("ByteNetReliable")
if not ByteNetReliable then
    ByteNetReliable = ReplicatedStorage:WaitForChild("ByteNetReliable", 2)
end
if not ByteNetReliable then
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == "ByteNetReliable" and v:IsA("RemoteEvent") then
            ByteNetReliable = v
            break
        end
    end
end
if not ByteNetReliable then
    task.spawn(function()
        local deadline = tick() + 20
        while not ByteNetReliable and tick() < deadline do
            local found = ReplicatedStorage:FindFirstChild("ByteNetReliable")
            if found then
                ByteNetReliable = found
                break
            end
            task.wait(0.1)
        end
        if ByteNetReliable then return end
        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v.Name == "ByteNetReliable" and v:IsA("RemoteEvent") then
                ByteNetReliable = v
                break
            end
        end
    end)
end

function autoDiscoverItemID(itemName)
    if not itemName or itemName == "" then return nil end

    -- 1) Fast path: use existing cache if present
    if type(craftNameToID) == "table" then
        local cached = craftNameToID[itemName]
        if cached ~= nil then return cached end
    end

    -- 2) Module lookup (if available in this game)
    do
        local Modules = ReplicatedStorage:FindFirstChild("Modules")
        if Modules then
            local ItemIDS = Modules:FindFirstChild("ItemIDS")
            if ItemIDS and ItemIDS:FindFirstChild(itemName) then
                local v = ItemIDS[itemName].Value
                if type(craftNameToID) == "table" then craftNameToID[itemName] = v end
                if type(craftItemIDs) == "table" then craftItemIDs[v] = itemName end
                return v
            end
        end
    end

    -- 3) UI scan fallback (only if helper functions exist later in the script)
    local inventoryScan = (type(scanInventoryForItemID) == "function") and scanInventoryForItemID or nil
    local craftScan = (type(scanCraftMenuForItemID) == "function") and scanCraftMenuForItemID or nil

    if inventoryScan then
        local inventoryID = inventoryScan(itemName)
        if inventoryID then
            if type(craftNameToID) == "table" then craftNameToID[itemName] = inventoryID end
            if type(craftItemIDs) == "table" then craftItemIDs[inventoryID] = itemName end
            return inventoryID
        end
    end

    if craftScan then
        local craftMenuID = craftScan(itemName)
        if craftMenuID then
            if type(craftNameToID) == "table" then craftNameToID[itemName] = craftMenuID end
            if type(craftItemIDs) == "table" then craftItemIDs[craftMenuID] = itemName end
            return craftMenuID
        end
    end

    return nil
end

-- Packet IDs: live Modules.Packets lookup + hidden obfuscated disk cache.
-- No static fallback table — IDs are discovered in-game and persisted on change.
PACKET_IDS = {}

_packetDataStatic = { packets = PACKET_IDS }

function packetData()
    return _packetDataStatic
end

function getPacketId(packetName)
    if not packetName or packetName == "" then return nil end
    local ids = PACKET_IDS or (_packetDataStatic and _packetDataStatic.packets)
    return ids and ids[packetName] or nil
end

function resolvePacketId(...)
    for i = 1, select("#", ...) do
        local id = getPacketId(select(i, ...))
        if id then return id end
    end
    return nil
end

function getPlaceStructureId()
    return getPacketId("PlaceStructure")
end

-- Convenience: send a no-payload C→S packet by name.
function firePacket(packetName)
    if not ByteNetReliable then return false end
    local id = getPacketId(packetName)
    if not id then return false end
    local b = buffer.create(2)
    buffer.writeu8(b, 0, 0)
    buffer.writeu8(b, 1, id)
    ByteNetReliable:FireServer(b)
    return true
end

-- Live Packets lookup → obscured disk cache → auto-rewrite when any ID differs.
-- Priority: live game modules > obfuscated cache file
-- Note: Wave workspace often ignores/blocks leading-dot folders, so avoid ".folder" paths.
local PACKET_IDS_CACHE_PATH = "ASTER/sys/c7/f2a91b.dat"
local PACKET_IDS_CACHE_LEGACY_PATH = "ASTER/Booga/packet_ids.json"
local PACKET_IDS_CACHE_OBFUSCATE_KEY = "A$t3rPk7_v2"
local PACKET_IDS_CACHE_META = {
    lastSync = 0,
    lastSave = 0,
    source = "none",
    changedCount = 0,
}

local function ensurePacketCacheFolder()
    if type(makefolder) ~= "function" then return end
    pcall(function()
        if type(isfolder) == "function" then
            if not isfolder("ASTER") then makefolder("ASTER") end
            if not isfolder("ASTER/sys") then makefolder("ASTER/sys") end
            if not isfolder("ASTER/sys/c7") then makefolder("ASTER/sys/c7") end
        else
            makefolder("ASTER")
            makefolder("ASTER/sys")
            makefolder("ASTER/sys/c7")
        end
    end)
end

local function getPacketHttp()
    return game:GetService("HttpService")
end

local function xorObfuscateString(text, key)
    if type(text) ~= "string" or text == "" then return "" end
    key = key or PACKET_IDS_CACHE_OBFUSCATE_KEY
    local keyLen = #key
    if keyLen < 1 then return text end
    local out = table.create(#text)
    for i = 1, #text do
        out[i] = string.char(bit32.bxor(string.byte(text, i), string.byte(key, ((i - 1) % keyLen) + 1)))
    end
    return table.concat(out)
end

local function encodePacketCacheBlob(jsonText)
    local http = getPacketHttp()
    local xored = xorObfuscateString(jsonText, PACKET_IDS_CACHE_OBFUSCATE_KEY)
    local ok, b64 = pcall(function()
        return http:Base64Encode(xored)
    end)
    if ok and type(b64) == "string" then
        return "AX1:" .. b64
    end
    -- Fallback if Base64Encode is unavailable: still XOR, mark format.
    return "AX0:" .. xored
end

local function decodePacketCacheBlob(raw)
    if type(raw) ~= "string" or raw == "" then return nil end
    local http = getPacketHttp()

    -- New obfuscated formats
    if string.sub(raw, 1, 4) == "AX1:" then
        local b64 = string.sub(raw, 5)
        local ok, decoded = pcall(function()
            return http:Base64Decode(b64)
        end)
        if not ok or type(decoded) ~= "string" then return nil end
        return xorObfuscateString(decoded, PACKET_IDS_CACHE_OBFUSCATE_KEY)
    end
    if string.sub(raw, 1, 4) == "AX0:" then
        return xorObfuscateString(string.sub(raw, 5), PACKET_IDS_CACHE_OBFUSCATE_KEY)
    end

    -- Legacy plain JSON
    if string.sub(raw, 1, 1) == "{" then
        return raw
    end
    return nil
end

local function tryHidePacketCacheFile(path)
    -- Best-effort OS hide. Most executors cannot truly lock workspace files.
    pcall(function()
        if type(sethiddenfile) == "function" then
            sethiddenfile(path, true)
            return
        end
        if type(isfilehidden) == "function" and type(sethidden) == "function" then
            sethidden(path, true)
            return
        end
    end)
end

local function deleteLegacyPacketCache()
    if type(delfile) ~= "function" or type(isfile) ~= "function" then return end
    pcall(function()
        if isfile(PACKET_IDS_CACHE_LEGACY_PATH) then
            delfile(PACKET_IDS_CACHE_LEGACY_PATH)
        end
    end)
end

local function shallowCopyPacketMap(src)
    local out = {}
    if type(src) ~= "table" then return out end
    for k, v in pairs(src) do
        if type(k) == "string" and type(v) == "number" and v == v and v > 0 then
            out[k] = v
        end
    end
    return out
end

local function packetMapsEqual(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    for k, v in pairs(a) do
        if b[k] ~= v then return false end
    end
    for k, v in pairs(b) do
        if a[k] ~= v then return false end
    end
    return true
end

local function diffPacketMaps(oldMap, newMap)
    local changes = {}
    oldMap = oldMap or {}
    newMap = newMap or {}
    for name, newId in pairs(newMap) do
        local oldId = oldMap[name]
        if oldId ~= newId then
            changes[#changes + 1] = {
                name = name,
                oldId = oldId,
                newId = newId,
            }
        end
    end
    for name, oldId in pairs(oldMap) do
        if newMap[name] == nil then
            changes[#changes + 1] = {
                name = name,
                oldId = oldId,
                newId = nil,
            }
        end
    end
    return changes
end

local function decodePacketCacheTable(raw)
    local jsonText = decodePacketCacheBlob(raw)
    if not jsonText then return nil end
    local ok, decoded = pcall(function()
        return getPacketHttp():JSONDecode(jsonText)
    end)
    if not ok or type(decoded) ~= "table" then
        return nil
    end
    local packets = decoded.packets
    if type(packets) ~= "table" then
        packets = decoded
    end
    local cleaned = shallowCopyPacketMap(packets)
    if next(cleaned) == nil then
        return nil
    end
    return cleaned, decoded
end

function loadPacketIdCache()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then
        return nil
    end

    local function tryPath(path)
        if not isfile(path) then return nil end
        local ok, raw = pcall(readfile, path)
        if not ok or type(raw) ~= "string" then return nil end
        return decodePacketCacheTable(raw)
    end

    local cleaned, decoded = tryPath(PACKET_IDS_CACHE_PATH)
    if cleaned then
        -- Always scrub the old obvious path if it still exists.
        deleteLegacyPacketCache()
        return cleaned, decoded
    end

    -- One-time migrate from old plain path, then delete it.
    cleaned, decoded = tryPath(PACKET_IDS_CACHE_LEGACY_PATH)
    if cleaned then
        deleteLegacyPacketCache()
        return cleaned, decoded
    end

    deleteLegacyPacketCache()
    return nil
end

function savePacketIdCache(packetMap, meta)
    if type(writefile) ~= "function" then
        return false
    end
    ensurePacketCacheFolder()
    local payload = {
        version = 2,
        savedAt = os.time(),
        source = (meta and meta.source) or PACKET_IDS_CACHE_META.source or "live",
        packets = shallowCopyPacketMap(packetMap or PACKET_IDS),
    }
    local ok, jsonText = pcall(function()
        return getPacketHttp():JSONEncode(payload)
    end)
    if not ok or type(jsonText) ~= "string" then
        return false
    end
    local blob = encodePacketCacheBlob(jsonText)
    local writeOk = pcall(function()
        writefile(PACKET_IDS_CACHE_PATH, blob)
    end)
    if writeOk then
        PACKET_IDS_CACHE_META.lastSave = os.clock()
        PACKET_IDS_CACHE_META.source = payload.source
        tryHidePacketCacheFile(PACKET_IDS_CACHE_PATH)
        deleteLegacyPacketCache()
    end
    return writeOk
end

local function applyPacketMap(packetMap, source)
    if type(packetMap) ~= "table" then return 0 end
    local applied = 0
    for name, id in pairs(packetMap) do
        if type(name) == "string" and type(id) == "number" and id == id and id > 0 then
            if PACKET_IDS[name] ~= id then
                PACKET_IDS[name] = id
                applied = applied + 1
            elseif PACKET_IDS[name] == nil then
                PACKET_IDS[name] = id
                applied = applied + 1
            end
        end
    end
    if source then
        PACKET_IDS_CACHE_META.source = source
    end
    return applied
end

local function readPacketObjectId(packetObj)
    if type(packetObj) ~= "table" then return nil end
    for _, key in ipairs({ "id", "Id", "_id", "packetId", "packetID", "ID" }) do
        local v = packetObj[key]
        if type(v) == "number" and v == v and v > 0 then
            return v
        end
    end
    return nil
end

local function tryRequirePacketIDs(modulesFolder)
    local candidates = {}
    local function add(inst)
        if inst then
            table.insert(candidates, inst)
        end
    end

    local byteNet = modulesFolder:FindFirstChild("ByteNet")
    if byteNet then
        local packetsFolder = byteNet:FindFirstChild("packets")
        if packetsFolder then
            add(packetsFolder:FindFirstChild("packetIDs"))
            add(packetsFolder:FindFirstChild("packetIds"))
            add(packetsFolder:FindFirstChild("PacketIDs"))
        end
        add(byteNet:FindFirstChild("packetIDs"))
        add(byteNet:FindFirstChild("packetIds"))
    end
    add(modulesFolder:FindFirstChild("packetIDs"))
    add(modulesFolder:FindFirstChild("packetIds"))

    for _, inst in ipairs(candidates) do
        local ok, result = pcall(require, inst)
        if ok and type(result) == "table" then
            return result, inst:GetFullName()
        end
    end
    return nil, nil
end

local function discoverLivePacketMap()
    local modulesFolder = ReplicatedStorage:FindFirstChild("Modules")
        or ReplicatedStorage:WaitForChild("Modules", 10)
    if not modulesFolder then
        return nil, "Modules missing"
    end

    local packetsInst = modulesFolder:FindFirstChild("Packets")
        or modulesFolder:WaitForChild("Packets", 10)
    if not packetsInst then
        return nil, "Packets missing"
    end

    local okPackets, gamePackets = pcall(require, packetsInst)
    if not okPackets or type(gamePackets) ~= "table" then
        return nil, "Packets require failed"
    end

    local live = {}
    local packetIDs = tryRequirePacketIDs(modulesFolder)
    local resolved = {}

    local function applyId(name, id)
        if type(name) ~= "string" or name == "" then return end
        if type(id) ~= "number" or id ~= id or id <= 0 then return end
        if resolved[name] then return end
        resolved[name] = true
        live[name] = id
    end

    for name, packetObj in pairs(gamePackets) do
        local id = readPacketObjectId(packetObj)
        if id then
            applyId(name, id)
        end
    end

    if type(packetIDs) == "table" then
        for name, packetObj in pairs(gamePackets) do
            if type(packetObj) == "table" and not resolved[name] then
                for id, registeredPacket in pairs(packetIDs) do
                    if type(id) == "number" and registeredPacket == packetObj then
                        applyId(name, id)
                        break
                    end
                end
            end
        end
        for id, registeredPacket in ipairs(packetIDs) do
            if type(registeredPacket) == "table" then
                for name, packetObj in pairs(gamePackets) do
                    if packetObj == registeredPacket then
                        applyId(name, id)
                        break
                    end
                end
            end
        end
    end

    if next(live) == nil then
        return nil, "No live packet IDs resolved"
    end
    return live, nil
end

-- Returns true when live sync succeeded. Always keeps memory map usable.
function syncPacketIDs(opts)
    opts = opts or {}
    local silent = opts.silent == true
    local forceSave = opts.forceSave == true

    local before = shallowCopyPacketMap(PACKET_IDS)
    local cacheMap = loadPacketIdCache()

    -- Boot path: apply disk cache first for fast reinject.
    if opts.loadCache ~= false and cacheMap then
        applyPacketMap(cacheMap, "cache")
    end

    local liveMap, liveErr = discoverLivePacketMap()
    PACKET_IDS_CACHE_META.lastSync = os.clock()

    if not liveMap then
        if not silent then
            warn("[ASTER Packets] Live lookup failed:", liveErr or "unknown", "- using cache only")
        end
        if forceSave or (not cacheMap and next(PACKET_IDS) ~= nil) then
            savePacketIdCache(PACKET_IDS, { source = cacheMap and "cache" or "partial" })
        end
        return false, liveErr
    end

    local changes = diffPacketMaps(before, liveMap)
    -- Also detect cache drift even if memory already matched live from a prior sync.
    local cacheChanges = diffPacketMaps(cacheMap or {}, liveMap)
    applyPacketMap(liveMap, "live")

    local shouldSave = forceSave or not cacheMap or not packetMapsEqual(cacheMap, liveMap)
    if shouldSave then
        savePacketIdCache(liveMap, { source = "live" })
        PACKET_IDS_CACHE_META.changedCount = #cacheChanges
    end

    return true, changes
end

-- Background watcher: re-check live Packets and rewrite cache when IDs drift.
function startPacketIdAutoSync(intervalSec)
    intervalSec = tonumber(intervalSec) or 30
    if intervalSec < 5 then intervalSec = 5 end
    local runtime = getAsterEnv and getAsterEnv().__ASTER_RUNTIME
    if type(runtime) == "table" then
        if runtime.packetIdAutoSyncStarted then return end
        runtime.packetIdAutoSyncStarted = true
    end
    task.spawn(function()
        local session = CURRENT_SESSION
        -- Initial sync (cache → live → save-on-diff)
        pcall(function()
            syncPacketIDs({ loadCache = true, silent = false })
        end)
        while true do
            if CURRENT_SESSION ~= session then
                break
            end
            task.wait(intervalSec)
            if CURRENT_SESSION ~= session then
                break
            end
            pcall(function()
                syncPacketIDs({ loadCache = false, silent = true })
            end)
        end
        if type(runtime) == "table" and CURRENT_SESSION ~= session then
            runtime.packetIdAutoSyncStarted = false
        end
    end)
end

task.spawn(function()
    startPacketIdAutoSync(30)
end)

function writeByteNetCFrame(b, offset, cf)
    local pos = cf.Position
    
    local _, _, _, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:GetComponents()
    local qx, qy, qz, qw
    local tr = R00 + R11 + R22
    if tr > 0 then
        local S = math.sqrt(tr + 1.0) * 2
        qw = 0.25 * S
        qx = (R21 - R12) / S
        qy = (R02 - R20) / S
        qz = (R10 - R01) / S
    elseif (R00 > R11) and (R00 > R22) then
        local S = math.sqrt(1.0 + R00 - R11 - R22) * 2
        qw = (R21 - R12) / S
        qx = 0.25 * S
        qy = (R01 + R10) / S
        qz = (R02 + R20) / S
    elseif R11 > R22 then
        local S = math.sqrt(1.0 + R11 - R00 - R22) * 2
        qw = (R02 - R20) / S
        qx = (R01 + R10) / S
        qy = 0.25 * S
        qz = (R12 + R21) / S
    else
        local S = math.sqrt(1.0 + R22 - R00 - R11) * 2
        qw = (R10 - R01) / S
        qx = (R02 + R20) / S
        qy = (R12 + R21) / S
        qz = 0.25 * S
    end
    
    local len = math.sqrt(qx*qx + qy*qy + qz*qz + qw*qw)
    qx, qy, qz, qw = qx/len, qy/len, qz/len, qw/len
    
    buffer.writeu8(b, offset, qw >= 0 and 0 or 1)
    buffer.writef32(b, offset + 1, pos.X)
    buffer.writef32(b, offset + 5, pos.Y)
    buffer.writef32(b, offset + 9, pos.Z)
    buffer.writei16(b, offset + 13, math.clamp(qx * 32767, -32768, 32767))
    buffer.writei16(b, offset + 15, math.clamp(qy * 32767, -32768, 32767))
    buffer.writei16(b, offset + 17, math.clamp(qz * 32767, -32768, 32767))
end

function write18ByteCFrame(b, offset, cf)
    local pos = cf.Position
    
    local _, _, _, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:GetComponents()
    local qx, qy, qz, qw
    local tr = R00 + R11 + R22
    if tr > 0 then
        local S = math.sqrt(tr + 1.0) * 2
        qw = 0.25 * S
        qx = (R21 - R12) / S
        qy = (R02 - R20) / S
        qz = (R10 - R01) / S
    elseif (R00 > R11) and (R00 > R22) then
        local S = math.sqrt(1.0 + R00 - R11 - R22) * 2
        qw = (R21 - R12) / S
        qx = 0.25 * S
        qy = (R01 + R10) / S
        qz = (R02 + R20) / S
    elseif R11 > R22 then
        local S = math.sqrt(1.0 + R11 - R00 - R22) * 2
        qw = (R02 - R20) / S
        qx = (R01 + R10) / S
        qy = 0.25 * S
        qz = (R12 + R21) / S
    else
        local S = math.sqrt(1.0 + R22 - R00 - R11) * 2
        qw = (R10 - R01) / S
        qx = (R02 + R20) / S
        qy = (R12 + R21) / S
        qz = 0.25 * S
    end
    
    local len = math.sqrt(qx*qx + qy*qy + qz*qz + qw*qw)
    qx, qy, qz, qw = qx/len, qy/len, qz/len, qw/len
    
    if qw < 0 then
        qx, qy, qz, qw = -qx, -qy, -qz, -qw
    end
    
    buffer.writef32(b, offset, pos.X)
    buffer.writef32(b, offset + 4, pos.Y)
    buffer.writef32(b, offset + 8, pos.Z)
    buffer.writei16(b, offset + 12, math.clamp(qx * 32767, -32768, 32767))
    buffer.writei16(b, offset + 14, math.clamp(qy * 32767, -32768, 32767))
    buffer.writei16(b, offset + 16, math.clamp(qz * 32767, -32768, 32767))
end

local function getBoogaPlayerCharacter(player)
    if not player then return nil end
    local playersFolder = workspace:FindFirstChild("Players")
    if playersFolder then
        local customChar = playersFolder:FindFirstChild(player.Name)
        if customChar then return customChar end
    end
    return player.Character
end

local function getBoogaPlayerHRP(player)
    local char = getBoogaPlayerCharacter(player)
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then return hrp end
    local hitbox = char:FindFirstChild("Hitbox")
    if hitbox and hitbox:IsA("BasePart") then return hitbox end
    return char:FindFirstChildWhichIsA("BasePart")
end

local function getVoodooCFrame(subject)
    if typeof(subject) == "CFrame" then
        return subject
    end
    if typeof(subject) == "Vector3" then
        return CFrame.new(subject)
    end
    if typeof(subject) ~= "Instance" then
        return nil
    end
    if subject:IsA("BasePart") then
        return subject.CFrame
    end
    if subject:IsA("Model") then
        local hrp = subject:FindFirstChild("HumanoidRootPart")
        if hrp then
            return hrp.CFrame
        end
        local ok, pivot = pcall(function()
            return subject:GetPivot()
        end)
        if ok and typeof(pivot) == "CFrame" then
            return pivot
        end
    end
    if subject:IsA("Player") then
        local hrp = getBoogaPlayerHRP(subject)
        if hrp then return hrp.CFrame end
        return nil
    end
    if subject.Character then
        return getVoodooCFrame(subject.Character)
    end
    return nil
end

function sendVoodooPacket(targetRef, originRef)
    if not ByteNetReliable then return end

    local voodooId = getPacketId("VoodooSpell")
    if not voodooId then return end

    local targetCFrame = getVoodooCFrame(targetRef)
    if not targetCFrame then return end

    local originCFrame = getVoodooCFrame(originRef)
    if not originCFrame then
        local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        originCFrame = hrp and hrp.CFrame or nil
    end
    if not originCFrame then return end

    local hitPos = targetCFrame.Position
    local fromPos = originCFrame.Position
    local flatDir = Vector3.new(hitPos.X - fromPos.X, 0, hitPos.Z - fromPos.Z)
    if flatDir.Magnitude > 0.001 then
        flatDir = flatDir.Unit
    else
        flatDir = Vector3.new(originCFrame.LookVector.X, 0, originCFrame.LookVector.Z)
        if flatDir.Magnitude > 0.001 then
            flatDir = flatDir.Unit
        else
            flatDir = Vector3.new(0, 0, -1)
        end
    end

    local b = buffer.create(26)
    buffer.writeu8(b, 0, 0)
    buffer.writeu8(b, 1, voodooId)
    buffer.writef32(b, 2, flatDir.X)
    buffer.writef32(b, 6, 0)
    buffer.writef32(b, 10, flatDir.Z)
    buffer.writef32(b, 14, hitPos.X)
    buffer.writef32(b, 18, hitPos.Y)
    buffer.writef32(b, 22, hitPos.Z)

    ByteNetReliable:FireServer(b)
end

-- // Theme Definitions // --
Themes = {
    Nebula = {
        Main = Color3.fromRGB(170, 0, 255), 
        Gradient = true,
        Colors = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(96, 31, 158)), 
            ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 0, 255))
        }),
        Background = Color3.fromRGB(10, 5, 20)  -- Deep purple-black
    },
    Midnight = {
        Main = Color3.fromRGB(0, 220, 255), 
        Gradient = true,
        Colors = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)), 
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 139, 139))
        }),
        Background = Color3.fromRGB(5, 10, 20)  -- Deep blue-black
    },
    Acid = {
        Main = Color3.fromRGB(200, 255, 0), 
        Gradient = true,
        Colors = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 255, 0)),   
            ColorSequenceKeypoint.new(1, Color3.fromRGB(98, 146, 1))
        }),
        Background = Color3.fromRGB(15, 20, 5)  -- Deep green-black
    },
    Sunset = {
        Main = Color3.fromRGB(255, 30, 160), 
        Gradient = true,
        Colors = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 150)), 
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 60))
        }),
        Background = Color3.fromRGB(20, 10, 5)  -- Deep red-black
    },
    
    Starfield = {
        Main = Color3.fromRGB(220, 220, 255),
        Gradient = true,
        Colors = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 220, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 180, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 220))
        }),
        Background = Color3.fromRGB(0, 0, 0),
        Stars = true
    },
    Premium = {
        Main = Color3.fromRGB(186, 140, 255),
        Gradient = true,
        Colors = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 80, 200)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(186, 140, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 230))
        }),
        Background = Color3.fromRGB(10, 8, 16),
        AccentGlow = Color3.fromRGB(186, 140, 255),
    }
}

-- Premium UI design tokens (spacing, motion, surfaces)
UI = {
    FontTitle = Enum.Font.GothamBold,
    FontBody = Enum.Font.GothamMedium,
    FontLabel = Enum.Font.Gotham,
    Radius = { sm = 6, md = 10, lg = 14, xl = 18 },
    Space = { xs = 4, sm = 8, md = 12, lg = 16, xl = 20 },
    Ease = {
        Fast = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        Med = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        Smooth = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        Spring = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    },
    Surface = {
        Deep = Color3.fromRGB(12, 12, 12),
        Panel = Color3.fromRGB(20, 20, 20),
        Card = Color3.fromRGB(20, 20, 20),
        CardHover = Color3.fromRGB(35, 35, 35),
        Control = Color3.fromRGB(25, 25, 25),
        ControlHover = Color3.fromRGB(32, 32, 32),
        Stroke = Color3.fromRGB(50, 50, 50),
        Muted = Color3.fromRGB(170, 170, 170),
        Text = Color3.new(1, 1, 1),
        Danger = Color3.fromRGB(255, 95, 110),
        Warn = Color3.fromRGB(255, 195, 90),
    },
}

UISettings = {
    CompactMode = false,
    GlobalSearch = "",
    ShowAmbience = false,
}

function uiCorner(parent, r)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, r or UI.Radius.md)
    return c
end

function uiStroke(parent, thickness, transparency, color)
    local s = Instance.new("UIStroke", parent)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.35
    s.Color = color or UI.Surface.Stroke
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s
end

function uiPadding(parent, t, r, b, l)
    local p = Instance.new("UIPadding", parent)
    p.PaddingTop = UDim.new(0, t or UI.Space.sm)
    p.PaddingRight = UDim.new(0, r or UI.Space.sm)
    p.PaddingBottom = UDim.new(0, b or UI.Space.sm)
    p.PaddingLeft = UDim.new(0, l or UI.Space.sm)
    return p
end

function tweenProp(inst, props, info)
    if inst and inst:IsDescendantOf(game) then
        local ease = info
        if not ease and type(UI) == "table" and UI.Ease then
            ease = UI.Ease.Fast
        end
        if not ease then
            ease = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
        game:GetService("TweenService"):Create(inst, ease, props):Play()
    end
end

function addHoverScale(btn, scaleUp)
    if not btn or not btn:IsA("GuiButton") then return end
    local base = btn.Size
    btn.MouseEnter:Connect(function()
        tweenProp(btn, { BackgroundTransparency = math.max(0, (btn.BackgroundTransparency or 0) - 0.08) }, UI.Ease.Fast)
    end)
    btn.MouseLeave:Connect(function()
        tweenProp(btn, { BackgroundTransparency = btn.BackgroundTransparency }, UI.Ease.Fast)
    end)
end

function rippleClick(btn, color)
    if not btn then return end
    btn.MouseButton1Click:Connect(function()
        local rip = Instance.new("Frame", btn)
        rip.AnchorPoint = Vector2.new(0.5, 0.5)
        rip.Position = UDim2.fromScale(0.5, 0.5)
        rip.Size = UDim2.fromOffset(4, 4)
        rip.BackgroundColor3 = color or (CurrentTheme and CurrentTheme.Main) or UI.Surface.Text
        rip.BackgroundTransparency = 0.5
        rip.ZIndex = (btn.ZIndex or 1) + 2
        rip.BorderSizePixel = 0
        Instance.new("UICorner", rip).CornerRadius = UDim.new(1, 0)
        tweenProp(rip, { Size = UDim2.fromOffset(math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2, 2), BackgroundTransparency = 1 }, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        task.delay(0.5, function() if rip then rip:Destroy() end end)
    end)
end

function registerSearchable(name, frame, tabTitle)
    if not Window.SearchIndex then Window.SearchIndex = {} end
    table.insert(Window.SearchIndex, {
        key = string.lower(tostring(name)),
        frame = frame,
        tab = tabTitle,
    })
end

function controlRowHeight()
    if isTouchMobileDevice() then
        return 48
    end
    return UISettings.CompactMode and 34 or 42
end

function getMobileDropdownMetrics()
    local mobile = isTouchMobileDevice()
    local screenH = 800
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then screenH = cam.ViewportSize.Y end
    end)
    return {
        optionHeight = mobile and 44 or 30,
        searchHeight = mobile and 36 or 28,
        maxHeight = mobile and math.clamp(math.floor(screenH * 0.42), 220, 360) or 160,
    }
end

function positionDropdownPop(popContainer, anchorFrame, popHeight)
    if not popContainer or not anchorFrame then return end
    local absPos = anchorFrame.AbsolutePosition
    local absSize = anchorFrame.AbsoluteSize
    local x = absPos.X
    local belowY = absPos.Y + absSize.Y + 5
    local aboveY = absPos.Y - popHeight - 5
    local screenH = 800
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then screenH = cam.ViewportSize.Y end
    end)
    local useAbove = isTouchMobileDevice() and (belowY + popHeight > screenH - 12) and (aboveY > 8)
    popContainer.Position = UDim2.fromOffset(x, useAbove and aboveY or belowY)
    if popContainer.Size.X.Offset ~= absSize.X or popContainer.Size.Y.Offset ~= popHeight then
        popContainer.Size = UDim2.fromOffset(absSize.X, popHeight)
    end
end

function markSearchable(row, text)
    row.Name = "ControlRow"
    row:SetAttribute("Searchable", true)
    row:SetAttribute("SearchKey", string.lower(tostring(text)))
end

function sectionTone(titleText)
    local t = string.lower(tostring(titleText or ""))
    if string.find(t, "killaura") or string.find(t, "combat /") then
        return "normal"
    end
    if string.find(t, "%[danger%]") or string.find(t, "%[!%]") or string.find(t, "dangerous")
        or string.find(t, "nuke graphics") or string.find(t, "delete all") then
        return "danger"
    end
    if string.find(t, "%[warn%]") or string.find(t, "caution") then
        return "warn"
    end
    return "normal"
end

function lerpColor(a, b, t)
    return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

function refreshThemeSurfaces()
    UI.Surface.Panel = Color3.fromRGB(20, 20, 20)
    UI.Surface.Card = Color3.fromRGB(20, 20, 20)
    UI.Surface.CardHover = Color3.fromRGB(35, 35, 35)
    UI.Surface.Control = Color3.fromRGB(25, 25, 25)
    UI.Surface.ControlHover = Color3.fromRGB(32, 32, 32)
    UI.Surface.Stroke = Color3.fromRGB(50, 50, 50)
    UI.Surface.Muted = Color3.fromRGB(170, 170, 170)
    UI.Surface.Text = Color3.new(1, 1, 1)
    local theme = CurrentTheme or Themes.Starfield
    UI.Surface.Deep = theme.Background or Color3.fromRGB(12, 12, 12)
end

function styleTextBox(box, placeholder)
    box.BackgroundTransparency = 1
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.TextColor3 = Color3.new(1, 1, 1)
    box.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
    if placeholder then box.PlaceholderText = placeholder end
    box:SetAttribute("IsTextBox", true)
end

function styleInputBackground(frame)
    frame.BackgroundColor3 = UI.Surface.ControlHover
    frame.BackgroundTransparency = GlobalTransparency
    frame.BorderSizePixel = 0
    uiCorner(frame, UI.Radius.sm)
    frame:SetAttribute("PremiumChrome", true)
    frame:SetAttribute("ChromeRole", "InputBg")
end

function applyControlChrome(frame, role)
    frame.BackgroundColor3 = UI.Surface.Control
    frame.BackgroundTransparency = GlobalTransparency
    frame.BorderSizePixel = 0
    uiCorner(frame, UI.Radius.md)
    local s = uiStroke(frame, 1, 0.7)
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    frame:SetAttribute("PremiumChrome", true)
    frame:SetAttribute("ChromeRole", role or "Control")
end

function setBreadcrumb(text)
    if Window.BreadcrumbLabel then
        Window.BreadcrumbLabel.Text = text or ""
        applyHollowEffect(Window.BreadcrumbLabel, 1.1, true)
    end
end

function refreshThemeAmbience()
    if not CurrentTheme or not Window.AmbienceOrbs then return end
    local main = CurrentTheme.Main
    local bg = CurrentTheme.Background or Color3.fromRGB(12, 12, 12)
    for i, orb in ipairs(Window.AmbienceOrbs) do
        if orb and orb.Parent then
            local blend = 0.15 + ((i - 1) % 5) * 0.08
            orb.BackgroundColor3 = lerpColor(bg, main, blend)
        end
    end
end

function Window_ApplyMobileLayout()
    if not isTouchMobileDevice() then return end
    UISettings.CompactMode = false
    local vp = Vector2.new(720, 520)
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then vp = cam.ViewportSize end
    end)
    local w = math.clamp(math.floor(vp.X * 0.94), 340, 720)
    local h = math.clamp(math.floor(vp.Y * 0.82), 420, 640)
    if mainFrame then
        mainFrame.Size = UDim2.fromOffset(w, h)
        mainFrame.Position = UDim2.new(0.5, -math.floor(w / 2), 0.5, -math.floor(h / 2))
    end
end

function Window_ApplyCompactMode()
    if not Window or not Window.Tabs then return end
    local compact = UISettings.CompactMode

    if mainFrame and Window.BaseGuiSize and Window.CompactGuiSize then
        local sz = compact and Window.CompactGuiSize or Window.BaseGuiSize
        mainFrame.Size = UDim2.fromOffset(sz.X, sz.Y)
        mainFrame.Position = UDim2.new(0.5, -math.floor(sz.X / 2), 0.5, -math.floor(sz.Y / 2))
    end
    local listPad = compact and 4 or 8
    local sectionPad = compact and 4 or 6
    local tabH = compact and 30 or 36
    local headerH = compact and 40 or 48
    local bodyTop = headerH + 8
    local rowH = controlRowHeight()
    local sliderH = isTouchMobileDevice() and 72 or (compact and 48 or 62)

    if contentHeader then
        contentHeader.Size = UDim2.new(1, 0, 0, headerH)
    end
    if contentBody then
        contentBody.Position = UDim2.fromOffset(0, bodyTop)
        contentBody.Size = UDim2.new(1, 0, 1, -bodyTop)
    end

    for _, t in pairs(Window.Tabs or {}) do
        if t.Btn then
            t.Btn.Size = UDim2.new(1, -4, 0, tabH)
        end
        if not t.PageScroll then
            -- skip tab without scroll
        else
        local leftCol = t.PageScroll:FindFirstChild("LeftColumn")
        local rightCol = t.PageScroll:FindFirstChild("RightColumn")
        if leftCol then
            local ll = leftCol:FindFirstChildOfClass("UIListLayout")
            if ll then ll.Padding = UDim.new(0, listPad) end
        end
        if rightCol then
            local rl = rightCol:FindFirstChildOfClass("UIListLayout")
            if rl then rl.Padding = UDim.new(0, listPad) end
        end
        for _, d in ipairs(t.PageScroll:GetDescendants()) do
            if d:GetAttribute("SectionListLayout") then
                d.Padding = UDim.new(0, sectionPad)
            elseif d.Name == "ControlRow" then
                local ct = d:GetAttribute("ControlType")
                if ct == "Slider" then
                    d.Size = UDim2.new(1, -2, 0, sliderH)
                elseif ct == "Input" then
                    d.Size = UDim2.new(1, -2, 0, rowH + 2)
                elseif ct == "Toggle" then
                    local lbl = d:FindFirstChildWhichIsA("TextLabel")
                    if lbl then lbl.TextSize = compact and 13 or 15 end
                    d.Size = UDim2.new(1, -2, 0, rowH)
                elseif ct == "Dropdown" or ct == "MultiDropdown" then
                    d.Size = UDim2.new(1, -2, 0, rowH)
                elseif ct == "Button" then
                    d.Size = UDim2.new(1, -2, 0, rowH - 4)
                end
            end
        end
        end
    end
end

function Window_ApplyGlobalSearch(query)
    if not Window or not Window.Tabs then return end
    query = string.lower(query or "")
    local activeTab = nil
    for _, t in pairs(Window.Tabs) do
        if t.Page and t.Page.Visible then activeTab = t break end
    end
    if not activeTab or not activeTab.PageScroll then return end

    local sections = {}
    for _, desc in ipairs(activeTab.PageScroll:GetDescendants()) do
        if desc:GetAttribute("IsSectionCard") then
            table.insert(sections, desc)
        elseif desc:GetAttribute("Searchable") and desc.Name == "ControlRow" then
            local key = desc:GetAttribute("SearchKey") or ""
            local visible = query == "" or string.find(key, query, 1, true) ~= nil
            desc.Visible = visible
        end
    end

    for _, card in ipairs(sections) do
        local sectionKey = card:GetAttribute("SearchKey") or ""
        local titleMatch = query ~= "" and string.find(sectionKey, query, 1, true) ~= nil
        if query == "" then
            card.Visible = true
        else
            local anyVisible = titleMatch
            if not anyVisible then
                for _, ch in ipairs(card:GetDescendants()) do
                    if ch:GetAttribute("Searchable") and ch.Name == "ControlRow" and ch.Visible then
                        anyVisible = true
                        break
                    end
                end
            end
            card.Visible = anyVisible
        end
    end
end

do -- UI Scope Block
CurrentTheme = Themes.Premium
GlobalTransparency = 0
GradientsEnabled = false
refreshThemeSurfaces()


function initializeCircuit()
    local pathFolder = "ASTERTween"
    local fileName = "GoldCircuit.json"
    local filePath = pathFolder .. "/" .. fileName
    -- 1. ONLY run this if the folder doesn't exist yet
    if not isfolder(pathFolder) then

        makefolder(pathFolder)

        -- 2. Your coordinate string (Paste inside the [[ ]])
        local rawData = [[
            
        ]] 

        if rawData ~= " " and rawData ~= "" then
            local success, decoded = pcall(function() 
                return httpservice:JSONDecode(rawData) 
            end)
            
            if success and decoded then
                writefile(filePath, rawData) -- Save it so we skip the string next time
                Settings.recordedPositions = decoded.positions

            else

            end
        end
    else
        -- 3. If folder exists, we skip the long string and just load the file
        if isfile(filePath) then

            local success, data = pcall(function() 
                return httpservice:JSONDecode(readfile(filePath)) 
            end)
            if success and data then
                Settings.recordedPositions = data.positions
            end
        end
    end
end
local quickHealToggle = nil
-- // Helpers // --
function ApplyGradient(parent)
    if not parent then return end

    if not CurrentTheme and Themes and Themes.Starfield then
        CurrentTheme = Themes.Starfield
    end

    local existing = parent:FindFirstChild("ThemeGradient")
    
    if GradientsEnabled and CurrentTheme and CurrentTheme.Gradient then
        if not existing then
            local grad = Instance.new("UIGradient")
            grad.Name = "ThemeGradient"; grad.Color = CurrentTheme.Colors; grad.Parent = parent
        else
            existing.Color = CurrentTheme.Colors
        end
        
        -- Base for gradients
        if parent:IsA("UIStroke") then parent.Color = Color3.new(1,1,1)
        elseif parent:IsA("ImageLabel") then parent.ImageColor3 = Color3.new(1,1,1)
        elseif parent:IsA("TextLabel") then parent.TextColor3 = Color3.new(1,1,1)
        elseif parent:IsA("TextBox") and not parent:GetAttribute("IsTextBox") then parent.TextColor3 = Color3.new(1,1,1)
        elseif parent:IsA("GuiObject") and not parent:IsA("TextButton") then parent.BackgroundColor3 = Color3.new(1,1,1) end
    else
        -- Clean up gradient objects
        if existing then existing:Destroy() end
        
        -- APPLY FLAT THEME COLOR (No more white)
        if CurrentTheme then
            local flat = CurrentTheme.Main
            if parent:IsA("UIStroke") then 
                parent.Color = flat
            elseif parent:IsA("ImageLabel") then 
                parent.ImageColor3 = flat
            elseif parent:IsA("TextLabel") then 
                parent.TextColor3 = flat
            elseif parent:IsA("TextBox") and not parent:GetAttribute("IsTextBox") then
                parent.TextColor3 = flat
            elseif parent:IsA("GuiObject") and not parent:IsA("TextButton") then 
                parent.BackgroundColor3 = flat 
            end
        end
    end
end

function applyHollowEffect(label, thickness, enabled)
    local stroke = label:FindFirstChild("UIStroke") or Instance.new("UIStroke", label)
    stroke.Thickness = thickness or 1.2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    stroke.Color = Color3.new(1,1,1)
    
    if enabled then
        label.TextColor3 = Color3.new(0, 0, 0) 
        stroke.Enabled = true
        ApplyGradient(stroke)
    else
        label.TextColor3 = Color3.new(1, 1, 1) 
        stroke.Enabled = false
        ApplyGradient(label)
    end
end

function makeDraggable(obj, handle)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        -- Fixed: Added back the correct UserInputType check
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = obj.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then 
                    dragging = false 
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function makeMobileDraggable(frame, button, clickCallback)
    local dragging, dragStart, startPos
    local clickStartPos = nil

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            clickStartPos = input.Position
            -- Check lock setting
            if Settings.LockMobileButtons then
                dragging = false
                return
            end
            
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then 
                    dragging = false 
                end
            end)
        end
    end)

    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            if clickStartPos and (input.Position - clickStartPos).Magnitude < 22 then
                if clickCallback then clickCallback() end
            end
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            -- Double check lock setting during drag
            if Settings.LockMobileButtons then
                dragging = false
                return
            end
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    if frame then
        local screenGui = frame:FindFirstAncestorOfClass("ScreenGui")
        if screenGui and screenGui.Name and screenGui.Name ~= "" and Window and Window.MobileButtons then
            Window.MobileButtons[screenGui.Name] = frame
        end
    end
end

-- // Framework Engine Setup // --
-- We define this EARLY so the ScrollFrames table exists before we try to add to it.

-- // Logic Functions (Moved Global) // --
function updateTabVisuals(tabObj, isActive)
    if not tabObj or not tabObj.Btn then return end
    local tabText = tabObj.TextLabel
    if isActive then
        tabObj.Btn.BackgroundTransparency = GlobalTransparency
        tabObj.Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        local bgGrad = tabObj.Btn:FindFirstChild("ThemeGradient")
        if bgGrad then bgGrad:Destroy() end
        if tabObj.Indicator then
            tabObj.Indicator.BackgroundTransparency = GlobalTransparency
            ApplyGradient(tabObj.Indicator)
        end
        if tabText then
            applyHollowEffect(tabText, 1.1, true)
        end
    else
        tabObj.Btn.BackgroundTransparency = 1
        if tabObj.Indicator then
            tabObj.Indicator.BackgroundTransparency = 1
        end
        if tabText then
            applyHollowEffect(tabText, 1.1, false)
            ApplyGradient(tabText)
        end
    end
    if tabObj.Icon and tabObj.Icon.Image ~= "" then
        tabObj.Icon.ImageTransparency = isActive and 0 or 0.25
        tabObj.Icon.ImageColor3 = Color3.new(1, 1, 1)
        ApplyGradient(tabObj.Icon)
    end
end

do
    Window = {Tabs = {}, AllElements = {}, ThemedElements = {}, TextElements = {}, ScrollFrames = {}, ActiveToggles = {}, ElementRegistry = {}, MobileButtons = {}, SearchIndex = {}, AmbienceOrbs = {}}
    Window.BaseGuiSize = Vector2.new(720, 520)
    Window.CompactGuiSize = Vector2.new(600, 440)
    Window.ApplyCompactMode = Window_ApplyCompactMode
    getAsterEnv().__ASTER_WINDOW = Window
-- // UI Root // --
asterWipeStaleGuis()
screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
asterParentGui(screenGui, "ASTERHub")

mainFrame = Instance.new("Frame", screenGui)
mainFrame.Name = "Main"
mainFrame.Size = UDim2.fromOffset(720, 520)
mainFrame.Position = UDim2.new(0.5, -360, 0.5, -260)
mainFrame.BackgroundColor3 = CurrentTheme.Background or UI.Surface.Deep
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
uiCorner(mainFrame, UI.Radius.lg)

local shellGlass = Instance.new("Frame", mainFrame)
shellGlass.Name = "ShellGlass"
shellGlass.Size = UDim2.fromScale(1, 1)
shellGlass.BackgroundColor3 = UI.Surface.Panel
shellGlass.BackgroundTransparency = 0.5
shellGlass.BorderSizePixel = 0
shellGlass.ZIndex = 0
uiCorner(shellGlass, UI.Radius.lg)

frameStroke = Instance.new("UIStroke", mainFrame)
frameStroke.Thickness = 1.5
frameStroke.Transparency = 0.25
frameStroke.Color = Color3.new(1, 1, 1)
ApplyGradient(frameStroke)

dragHandle = Instance.new("Frame", mainFrame)
dragHandle.Size = UDim2.new(1, 0, 0, 56)
dragHandle.BackgroundTransparency = 1
dragHandle.ZIndex = 10
makeDraggable(mainFrame, dragHandle)

sidebar = Instance.new("Frame", mainFrame)
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 168, 1, 0)
sidebar.BackgroundColor3 = UI.Surface.Panel
sidebar.BackgroundTransparency = 0.05
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 2
uiCorner(sidebar, UI.Radius.lg)
uiStroke(sidebar, 1, 0.65)

sidebarTitle = Instance.new("TextLabel", sidebar)
sidebarTitle.Text = "ASSTER HUB CRACKED"
sidebarTitle.Size = UDim2.new(1, -16, 0, 22)
sidebarTitle.Position = UDim2.fromOffset(14, 12)
sidebarTitle.Font = UI.FontTitle
sidebarTitle.TextSize = 18
sidebarTitle.BackgroundTransparency = 1
sidebarTitle.TextXAlignment = Enum.TextXAlignment.Left
applyHollowEffect(sidebarTitle, 1.2, true)

sidebarSub = Instance.new("TextLabel", sidebar)
sidebarSub.Text = "BY BLOOMWARE"
sidebarSub.Size = UDim2.new(1, -16, 0, 14)
sidebarSub.Position = UDim2.fromOffset(14, 34)
sidebarSub.Font = UI.FontLabel
sidebarSub.TextSize = 11
sidebarSub.TextColor3 = UI.Surface.Muted
sidebarSub.BackgroundTransparency = 1
sidebarSub.TextXAlignment = Enum.TextXAlignment.Left

sidebarLine = Instance.new("Frame", sidebar)
sidebarLine.Size = UDim2.new(1, -24, 0, 1)
sidebarLine.Position = UDim2.new(0, 12, 0, 54)
sidebarLine.BackgroundColor3 = Color3.new(1, 1, 1)
sidebarLine.BackgroundTransparency = 0.5
sidebarLine.BorderSizePixel = 0
ApplyGradient(sidebarLine)

toggleBtn = Instance.new("TextButton", screenGui)
toggleBtn.Size = UDim2.fromOffset(56, 56)
toggleBtn.Position = UDim2.new(0, 14, 0.5, -28)
toggleBtn.BackgroundColor3 = UI.Surface.Card
toggleBtn.Text = "A"
toggleBtn.Font = UI.FontTitle
toggleBtn.TextSize = 20
toggleBtn.ZIndex = 100
uiCorner(toggleBtn, UI.Radius.lg)
uiStroke(toggleBtn, 1.5, 0.4)
applyHollowEffect(toggleBtn, 1.1, true)
toggleBtn.MouseButton1Click:Connect(function()
    if Window.ToggleGUI then Window.ToggleGUI() end
end)
makeDraggable(toggleBtn, toggleBtn)
rippleClick(toggleBtn)

Window.SetMainUIVisible = function(visible, hideLauncher)
    if not mainFrame or not toggleBtn then return end
    local show = visible == true
    mainFrame.Visible = show
    -- A-button minimize: keep launcher visible so it can reopen the menu.
    -- UI keybind: hide launcher too for a fully clean screen.
    if hideLauncher then
        toggleBtn.Visible = show
    else
        toggleBtn.Visible = true
    end
    if screenGui then
        screenGui.Enabled = true
    end
    -- Only the full-clean-screen UI keybind (hideLauncher) also hides the keybinds
    -- overlay and mobile widgets. The A-button / minimize hides just the main window.
    if hideLauncher then
        if ASTER.SyncKeybindsOverlayWithMainUI then
            ASTER.SyncKeybindsOverlayWithMainUI(show)
        end
        if ASTER.SyncMobileWidgetsWithMainUI then
            ASTER.SyncMobileWidgetsWithMainUI(show)
        end
    end
end

Window.ToggleGUI = function(hideLauncher)
    if not mainFrame then return end
    Window.SetMainUIVisible(not mainFrame.Visible, hideLauncher == true)
end

tabScroll = Instance.new("ScrollingFrame", sidebar)
table.insert(Window.ScrollFrames, tabScroll)
tabScroll.Size = UDim2.new(1, 0, 1, -76)
tabScroll.Position = UDim2.fromOffset(0, 62)
tabScroll.BackgroundTransparency = 1
tabScroll.BorderSizePixel = 0
tabScroll.ScrollBarThickness = 3
tabScroll.ScrollBarImageColor3 = CurrentTheme.Main
tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
tabScroll.ScrollingDirection = Enum.ScrollingDirection.Y

local layout = Instance.new("UIListLayout", tabScroll)
layout.Padding = UDim.new(0, 4)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiPadding(tabScroll, 4, 8, 8, 8)

local content = Instance.new("Frame", mainFrame)
content.Name = "Content"
content.Size = UDim2.new(1, -180, 1, -16)
content.Position = UDim2.fromOffset(172, 10)
content.BackgroundTransparency = 1
content.ZIndex = 2

contentHeader = Instance.new("Frame", content)
contentHeader.Name = "Header"
contentHeader.Size = UDim2.new(1, 0, 0, 48)
contentHeader.BackgroundColor3 = UI.Surface.Card
contentHeader.BackgroundTransparency = GlobalTransparency
contentHeader.BorderSizePixel = 0
uiCorner(contentHeader, UI.Radius.md)
uiStroke(contentHeader, 1, 0.6)
local headerPad = Instance.new("UIPadding", contentHeader)
headerPad.PaddingLeft = UDim.new(0, 12)
headerPad.PaddingRight = UDim.new(0, 8)

Window.BreadcrumbLabel = Instance.new("TextLabel", contentHeader)
Window.BreadcrumbLabel.Size = UDim2.new(0.34, -8, 1, 0)
Window.BreadcrumbLabel.Position = UDim2.fromOffset(0, 0)
Window.BreadcrumbLabel.BackgroundTransparency = 1
Window.BreadcrumbLabel.Font = UI.FontTitle
Window.BreadcrumbLabel.TextSize = 15
Window.BreadcrumbLabel.TextXAlignment = Enum.TextXAlignment.Left
Window.BreadcrumbLabel.TextColor3 = UI.Surface.Text
Window.BreadcrumbLabel.Text = "Main"
applyHollowEffect(Window.BreadcrumbLabel, 1, true)

local headerRight = Instance.new("Frame", contentHeader)
headerRight.Name = "HeaderRight"
headerRight.AnchorPoint = Vector2.new(1, 0.5)
headerRight.Position = UDim2.new(1, -4, 0.5, 0)
headerRight.Size = UDim2.new(0.64, 0, 0, 36)
headerRight.BackgroundTransparency = 1
headerRight.ZIndex = 5

searchWrap = Instance.new("Frame", headerRight)
searchWrap.Name = "SearchWrap"
searchWrap.AnchorPoint = Vector2.new(0, 0.5)
searchWrap.Position = UDim2.new(0, 0, 0.5, 0)
searchWrap.Size = UDim2.new(1, -64, 0, 32)
searchWrap.BackgroundColor3 = UI.Surface.Control
searchWrap.BackgroundTransparency = 0.2
searchWrap.BorderSizePixel = 0
uiCorner(searchWrap, UI.Radius.sm)
uiStroke(searchWrap, 1, 0.55)

minBtn = Instance.new("TextButton", headerRight)
minBtn.Name = "Minimize"
minBtn.AnchorPoint = Vector2.new(1, 0.5)
minBtn.Position = UDim2.new(1, -34, 0.5, 0)
minBtn.Size = UDim2.fromOffset(26, 26)
minBtn.BackgroundColor3 = UI.Surface.Control
minBtn.BackgroundTransparency = 0.25
minBtn.Text = ""
minBtn.ZIndex = 6
uiCorner(minBtn, UI.Radius.sm)
minBtn.MouseButton1Click:Connect(function()
    if Window.SetMainUIVisible then Window.SetMainUIVisible(false) else mainFrame.Visible = false end
end)
rippleClick(minBtn)
minLine = Instance.new("Frame", minBtn)
minLine.Name = "MinLine"
minLine.Size = UDim2.new(0, 14, 0, 3)
minLine.Position = UDim2.new(0.5, -7, 0.5, -1.5)
minLine.BackgroundTransparency = 1
minLine.BorderSizePixel = 0
Instance.new("UICorner", minLine).CornerRadius = UDim.new(1, 0)
minStroke = Instance.new("UIStroke", minLine)
minStroke.Thickness = 1.5
minStroke.Color = Color3.new(1, 1, 1)
ApplyGradient(minStroke)

killX = Instance.new("TextButton", headerRight)
killX.Name = "Close"
killX.AnchorPoint = Vector2.new(1, 0.5)
killX.Position = UDim2.new(1, -2, 0.5, 0)
killX.Size = UDim2.fromOffset(26, 26)
killX.BackgroundColor3 = UI.Surface.Control
killX.BackgroundTransparency = 0.25
killX.Text = "x"
killX.Font = Enum.Font.GothamBold
killX.TextSize = 18
killX.ZIndex = 6
uiCorner(killX, UI.Radius.sm)
applyHollowEffect(killX, 1.2, true)
killX.MouseButton1Click:Connect(function()
    Settings.ShowKeybindsOverlay = false
    if Window.ElementRegistry and Window.ElementRegistry["Show Keybinds Overlay"] and Window.ElementRegistry["Show Keybinds Overlay"].SetValue then
        pcall(function() Window.ElementRegistry["Show Keybinds Overlay"].SetValue(false) end)
    end
    if ASTER.DestroyKeybindsOverlay then
        ASTER.DestroyKeybindsOverlay()
    end
    if ASTER.DestroyAllMobileWidgets then
        ASTER.DestroyAllMobileWidgets()
    end
    pcall(function() screenGui:Destroy() end)
end)
screenGui.AncestryChanged:Connect(function(_, parent)
    if parent then return end
    Settings.ShowKeybindsOverlay = false
    if ASTER.DestroyKeybindsOverlay then
        ASTER.DestroyKeybindsOverlay()
    end
    if ASTER.DestroyAllMobileWidgets then
        ASTER.DestroyAllMobileWidgets()
    end
end)
rippleClick(killX)

Window.GlobalSearchBox = Instance.new("TextBox", searchWrap)
Window.GlobalSearchBox.Size = UDim2.new(1, -12, 1, 0)
Window.GlobalSearchBox.Position = UDim2.fromOffset(8, 0)
Window.GlobalSearchBox.BackgroundTransparency = 1
Window.GlobalSearchBox.Text = ""
Window.GlobalSearchBox.ClearTextOnFocus = false
styleTextBox(Window.GlobalSearchBox, "Search settings...")
Window.GlobalSearchBox.TextXAlignment = Enum.TextXAlignment.Left

Window.GlobalSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    UISettings.GlobalSearch = Window.GlobalSearchBox.Text
    Window_ApplyGlobalSearch(UISettings.GlobalSearch)
end)

contentBody = Instance.new("Frame", content)
contentBody.Name = "Body"
contentBody.Size = UDim2.new(1, 0, 1, -56)
contentBody.Position = UDim2.fromOffset(0, 56)
contentBody.BackgroundTransparency = 1

if UISettings.ShowAmbience then
    task.spawn(function()
        local ambLayer = Instance.new("Frame", mainFrame)
        ambLayer.Name = "Ambience"
        ambLayer.Size = UDim2.fromScale(1, 1)
        ambLayer.BackgroundTransparency = 1
        ambLayer.ZIndex = 1
        ambLayer.ClipsDescendants = false
        for i = 1, 5 do
            local orb = Instance.new("Frame", ambLayer)
            orb.Size = UDim2.fromOffset(math.random(80, 160), math.random(80, 160))
            orb.Position = UDim2.new(math.random(), 0, math.random(), 0)
            orb.BackgroundTransparency = 0.92
            orb.BorderSizePixel = 0
            Instance.new("UICorner", orb).CornerRadius = UDim.new(1, 0)
            table.insert(Window.AmbienceOrbs, orb)
            task.spawn(function()
                while orb.Parent do
                    tweenProp(orb, {
                        Position = UDim2.new(math.random(), 0, math.random(), 0),
                        BackgroundTransparency = 0.9 + math.random() * 0.08,
                    }, TweenInfo.new(4 + math.random() * 3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
                    task.wait(4 + math.random() * 2)
                end
            end)
        end
        refreshThemeAmbience()
    end)
end

function Window:UpdateTransparency(val)
    GlobalTransparency = val
    mainFrame.BackgroundTransparency = val
    local glass = mainFrame and mainFrame:FindFirstChild("ShellGlass")
    if glass then glass.BackgroundTransparency = math.clamp(0.12 + val * 0.65, 0, 0.95) end
    sidebar.BackgroundTransparency = math.clamp(0.05 + val * 0.9, 0, 0.95)
    if contentHeader then contentHeader.BackgroundTransparency = math.clamp(0.35 + val * 0.6, 0, 0.95) end
    if searchWrap then searchWrap.BackgroundTransparency = math.clamp(0.2 + val * 0.8, 0, 0.95) end
    for _, el in pairs(Window.AllElements) do
        if el:GetAttribute("PremiumChrome") or el.Name == "ControlRow" then
            el.BackgroundTransparency = val
        end
    end
    for _, t in pairs(Window.Tabs) do updateTabVisuals(t, t.Page and t.Page.Visible) end
    if ASTER.ApplyKeybindsOverlayTheme then
        ASTER.ApplyKeybindsOverlayTheme()
    end
end

function Window:UpdateTheme(NewTheme)
    if not NewTheme then return end
    CurrentTheme = NewTheme
    refreshThemeSurfaces()
    if mainFrame then
        mainFrame.BackgroundColor3 = NewTheme.Background or Color3.fromRGB(12, 12, 12)
        local glass = mainFrame:FindFirstChild("ShellGlass")
        if glass then glass.BackgroundColor3 = UI.Surface.Panel end
    end
    if sidebar then sidebar.BackgroundColor3 = UI.Surface.Panel end
    if contentHeader then contentHeader.BackgroundColor3 = UI.Surface.Card end
    if searchWrap then searchWrap.BackgroundColor3 = UI.Surface.Control end

    for _, el in pairs(Window.AllElements) do
        if el:GetAttribute("PremiumChrome") then
            local role = el:GetAttribute("ChromeRole")
            if role == "SectionCard" then
                el.BackgroundColor3 = UI.Surface.Card
            elseif role == "InputBg" then
                el.BackgroundColor3 = UI.Surface.ControlHover
            else
                el.BackgroundColor3 = UI.Surface.Control
            end
            local stroke = el:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = UI.Surface.Stroke end
        end
    end
    if mainFrame then
        for _, desc in ipairs(mainFrame:GetDescendants()) do
            if desc:GetAttribute("IsTextBox") then
                desc.TextColor3 = Color3.new(1, 1, 1)
                desc.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
            end
        end
    end
    if screenGui then
        for _, desc in ipairs(screenGui:GetDescendants()) do
            if desc.Name == "DropdownSearchFrame" and desc:IsA("Frame") then
                desc.BackgroundColor3 = UI.Surface.Control
            end
        end
    end
    
    ApplyGradient(frameStroke)
    ApplyGradient(sidebarLine)
    
    refreshThemeAmbience()

    -- Update Titles and Buttons
    applyHollowEffect(sidebarTitle, 1.4, true)
    if killX then
        applyHollowEffect(killX, 1.2, true)
    end
    local minLine = minBtn and minBtn:FindFirstChild("MinLine")
    if minLine then
        local ms = minLine:FindFirstChild("UIStroke")
        if ms then ApplyGradient(ms) end
    end
    applyHollowEffect(toggleBtn, 1.2, true)
    if Window.BreadcrumbLabel then
        applyHollowEffect(Window.BreadcrumbLabel, 1.1, true)
    end
    
    -- Refresh all tabs
    for _, t in pairs(Window.Tabs) do
        ApplyGradient(t.Line)
        ApplyGradient(t.pTitle)
        if t.Indicator then
            t.Indicator.BackgroundColor3 = NewTheme.Main
            ApplyGradient(t.Indicator)
        end
        updateTabVisuals(t, t.Page.Visible)
    end
    
    -- Refresh list elements
    for _, txt in pairs(Window.TextElements) do
        ApplyGradient(txt)
    end

    for _, el in pairs(Window.ThemedElements) do
        ApplyGradient(el)
    end

    for _, sf in pairs(Window.ScrollFrames) do
        sf.ScrollBarImageColor3 = CurrentTheme.Main
    end

-- This is the part that fixes your toggle color lag:
    for sw, state in pairs(Window.ActiveToggles) do
        if state then 
            ApplyGradient(sw) 
        end
    end

    if ASTER.ApplyKeybindsOverlayTheme then
        ASTER.ApplyKeybindsOverlayTheme()
    end
    if ASTER.ToggleBind and ASTER.ToggleBind.keyCaptureRows then
        for _, cap in pairs(ASTER.ToggleBind.keyCaptureRows) do
            if cap.label then ApplyGradient(cap.label) end
            if cap.refresh then cap.refresh() end
        end
    end
    if ASTER.ApplyAllMobileWidgetThemes then
        ASTER.ApplyAllMobileWidgetThemes()
    end
end

function Window:AddTab(Config)
    local tabBtn = Instance.new("TextButton", tabScroll)
    tabBtn.Size = UDim2.new(1, -4, 0, 36)
    tabBtn.BackgroundTransparency = 1
    tabBtn.Text = ""
    tabBtn.AutoButtonColor = false
    uiCorner(tabBtn, UI.Radius.sm)

    local tabIndicator = Instance.new("Frame", tabBtn)
    tabIndicator.Name = "Indicator"
    tabIndicator.Size = UDim2.new(0, 3, 0.55, 0)
    tabIndicator.Position = UDim2.new(0, 6, 0.225, 0)
    tabIndicator.BackgroundColor3 = CurrentTheme.Main
    tabIndicator.BackgroundTransparency = 1
    tabIndicator.BorderSizePixel = 0
    Instance.new("UICorner", tabIndicator).CornerRadius = UDim.new(1, 0)
    ApplyGradient(tabIndicator)

    local iconImg = Instance.new("ImageLabel", tabBtn)
    iconImg.Name = "TabIcon"
    iconImg.Size = UDim2.fromOffset(18, 18)
    iconImg.Position = UDim2.new(0, 12, 0.5, -9)
    iconImg.BackgroundTransparency = 1
    iconImg.Image = Config.Icon or ""
    iconImg.ImageTransparency = 0.4
    iconImg.ZIndex = 3

    local tabText = Instance.new("TextLabel", tabBtn)
    tabText.Name = "TabTitle"
    tabText.Size = UDim2.new(1, -44, 1, 0)
    tabText.Position = UDim2.fromOffset(36, 0)
    tabText.BackgroundTransparency = 1
    tabText.Text = Config.Title
    tabText.Font = Enum.Font.SourceSansBold
    tabText.TextSize = 14
    tabText.TextXAlignment = Enum.TextXAlignment.Left
    tabText.TextTruncate = Enum.TextTruncate.AtEnd
    tabText.ZIndex = 2
    applyHollowEffect(tabText, 1.1, false)
    ApplyGradient(tabText)

    local container = Instance.new("Frame", contentBody)
    container.Size = UDim2.fromScale(1, 1)
    container.BackgroundTransparency = 1
    container.Visible = false

    local header = Instance.new("Frame", container)
    header.Size = UDim2.new(1, 0, 0, 28)
    header.BackgroundTransparency = 1
    header.Visible = false

    local pTitle = Instance.new("TextLabel", header)
    pTitle.Text = Config.Title
    pTitle.Size = UDim2.new(1, 0, 0, 24)
    pTitle.Font = UI.FontTitle
    pTitle.TextSize = 16
    pTitle.TextColor3 = UI.Surface.Text
    pTitle.TextXAlignment = Enum.TextXAlignment.Left
    pTitle.BackgroundTransparency = 1

    local line = Instance.new("Frame", header)
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 0, 26)
    line.BackgroundColor3 = Color3.new(1, 1, 1)
    line.BackgroundTransparency = 0.55
    line.BorderSizePixel = 0
    ApplyGradient(line)

    local page = Instance.new("ScrollingFrame", container)
    table.insert(Window.ScrollFrames, page)
    page.Size = UDim2.fromScale(1, 1)
    page.Position = UDim2.fromOffset(0, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = CurrentTheme.Main
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.BorderSizePixel = 0
    page.ScrollingDirection = Enum.ScrollingDirection.Y
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ClipsDescendants = true

    local pagePad = Instance.new("UIPadding", page)
    pagePad.PaddingLeft = UDim.new(0, 6)
    pagePad.PaddingRight = UDim.new(0, 10)
    pagePad.PaddingTop = UDim.new(0, 4)
    pagePad.PaddingBottom = UDim.new(0, 12)

    local leftColumn = Instance.new("Frame", page)
    leftColumn.Name = "LeftColumn"
    leftColumn.Size = UDim2.new(0.5, -7, 0, 0)
    leftColumn.Position = UDim2.new(0, 0, 0, 0)
    leftColumn.BackgroundTransparency = 1
    leftColumn.AutomaticSize = Enum.AutomaticSize.Y

    local rightColumn = Instance.new("Frame", page)
    rightColumn.Name = "RightColumn"
    rightColumn.Size = UDim2.new(0.5, -7, 0, 0)
    rightColumn.Position = UDim2.new(0.5, 7, 0, 0)
    rightColumn.BackgroundTransparency = 1
    rightColumn.AutomaticSize = Enum.AutomaticSize.Y

    local leftList = Instance.new("UIListLayout", leftColumn)
    leftList.Padding = UDim.new(0, UISettings.CompactMode and 4 or 8)
    leftList.SortOrder = Enum.SortOrder.LayoutOrder

    local rightList = Instance.new("UIListLayout", rightColumn)
    rightList.Padding = UDim.new(0, UISettings.CompactMode and 4 or 8)
    rightList.SortOrder = Enum.SortOrder.LayoutOrder

    local TabObj = {
        Page = container,
        PageScroll = page,
        Line = line,
        pTitle = pTitle,
        Btn = tabBtn,
        Icon = iconImg,
        TextLabel = tabText,
        Indicator = tabIndicator,
        Title = Config.Title,
    }
    local leftLayoutOrder = 0
    local rightLayoutOrder = 0
    local currentSectionOrder = 0
    local currentSectionContent = nil

    local function refreshPageCanvas()
        local leftHeight = math.max(leftList.AbsoluteContentSize.Y, leftColumn.AbsoluteSize.Y)
        local rightHeight = math.max(rightList.AbsoluteContentSize.Y, rightColumn.AbsoluteSize.Y)
        if leftHeight < 1 or rightHeight < 1 then
            for _, col in ipairs({ leftColumn, rightColumn }) do
                local sum, count = 0, 0
                local layout = col:FindFirstChildOfClass("UIListLayout")
                local pad = layout and layout.Padding.Offset or 0
                for _, ch in ipairs(col:GetChildren()) do
                    if ch:IsA("GuiObject") and ch.Visible and not ch:IsA("UILayout") then
                        local h = ch.AbsoluteSize.Y
                        if h < 1 then h = ch.Size.Y.Offset end
                        if h > 0 then
                            sum = sum + h
                            count = count + 1
                        end
                    end
                end
                if count > 0 then
                    local h = sum + pad * math.max(count - 1, 0)
                    if col == leftColumn then leftHeight = math.max(leftHeight, h) end
                    if col == rightColumn then rightHeight = math.max(rightHeight, h) end
                end
            end
        end
        local tallest = math.max(leftHeight, rightHeight)
        if tallest > 0 then
            page.CanvasSize = UDim2.new(0, 0, 0, tallest + 24)
        end
    end

    leftList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshPageCanvas)
    rightList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshPageCanvas)

    local function getSectionContainer()
        local leftHeight = leftList.AbsoluteContentSize.Y
        local rightHeight = rightList.AbsoluteContentSize.Y
        local balanceThreshold = 90
        if leftHeight > rightHeight + balanceThreshold then
            rightLayoutOrder = rightLayoutOrder + 1
            return rightColumn, rightLayoutOrder
        elseif rightHeight > leftHeight + balanceThreshold then
            leftLayoutOrder = leftLayoutOrder + 1
            return leftColumn, leftLayoutOrder
        elseif leftHeight <= rightHeight then
            leftLayoutOrder = leftLayoutOrder + 1
            return leftColumn, leftLayoutOrder
        end
        rightLayoutOrder = rightLayoutOrder + 1
        return rightColumn, rightLayoutOrder
    end

    local function createSectionCard(titleText)
        local sectionColumn, sectionOrder = getSectionContainer()

        local sectionCard = Instance.new("Frame", sectionColumn)
        sectionCard.LayoutOrder = sectionOrder
        sectionCard.Size = UDim2.new(1, -6, 0, 0)
        sectionCard.BackgroundColor3 = UI.Surface.Card
        sectionCard.BackgroundTransparency = GlobalTransparency
        sectionCard.BorderSizePixel = 0
        sectionCard.ClipsDescendants = false
        sectionCard.AutomaticSize = Enum.AutomaticSize.Y
        uiCorner(sectionCard, UI.Radius.md)
        sectionCard:SetAttribute("IsSectionCard", true)
        sectionCard:SetAttribute("SearchKey", string.lower(tostring(titleText or "")))
        sectionCard:SetAttribute("PremiumChrome", true)
        sectionCard:SetAttribute("ChromeRole", "SectionCard")
        local tone = sectionTone(titleText)
        local cardStroke = uiStroke(sectionCard, 1, tone == "danger" and 0.25 or 0.5)
        if tone == "danger" then
            cardStroke.Color = UI.Surface.Danger
        elseif tone == "warn" then
            cardStroke.Color = UI.Surface.Warn
        end
        table.insert(Window.AllElements, sectionCard)

        local cardPadX = UI.Space.md
        local cardPadTop = UI.Space.md
        local cardPadBottom = UI.Space.md
        local headerHeight = (titleText and titleText ~= "") and 22 or 0
        local headerSpacing = headerHeight > 0 and UI.Space.xs or 0
        local collapsed = false
        local sectionContentHolder
        local sectionList
        local refreshSectionSize

        local sectionTitleLabel = nil
        if titleText and titleText ~= "" then
            sectionTitleLabel = Instance.new("TextLabel", sectionCard)
            sectionTitleLabel.Size = UDim2.new(1, -(cardPadX * 2 + 16), 0, 20)
            sectionTitleLabel.Position = UDim2.fromOffset(cardPadX, cardPadTop)
            sectionTitleLabel.BackgroundTransparency = 1
            sectionTitleLabel.Text = titleText
            sectionTitleLabel.Font = UI.FontTitle
            sectionTitleLabel.TextSize = 14
            sectionTitleLabel.TextColor3 = tone == "danger" and UI.Surface.Danger or (tone == "warn" and UI.Surface.Warn or UI.Surface.Text)
            sectionTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            if tone == "normal" then ApplyGradient(sectionTitleLabel) end
            table.insert(Window.TextElements, sectionTitleLabel)

            local collapseBtn = Instance.new("TextButton", sectionCard)
            collapseBtn.Size = UDim2.fromOffset(16, 16)
            collapseBtn.Position = UDim2.new(1, -(cardPadX + 16), 0, cardPadTop + 2)
            collapseBtn.BackgroundTransparency = 1
            collapseBtn.Text = ""
            collapseBtn.AutoButtonColor = false

            local collapseArrow = Instance.new("TextLabel", collapseBtn)
            collapseArrow.Size = UDim2.fromScale(1, 1)
            collapseArrow.BackgroundTransparency = 1
            collapseArrow.Text = ">"
            collapseArrow.Font = Enum.Font.GothamBold
            collapseArrow.TextSize = 12
            collapseArrow.TextColor3 = Color3.new(1, 1, 1)
            collapseArrow.Rotation = 90
            collapseArrow.TextXAlignment = Enum.TextXAlignment.Center
            collapseArrow.TextYAlignment = Enum.TextYAlignment.Center
            ApplyGradient(collapseArrow)
            table.insert(Window.TextElements, collapseArrow)

            collapseBtn.MouseButton1Click:Connect(function()
                collapsed = not collapsed
                if refreshSectionSize then
                    refreshSectionSize(true)
                end
                TweenService:Create(collapseArrow, UI.Ease.Fast, {
                    Rotation = collapsed and 0 or 90
                }):Play()
            end)
        end

        sectionContentHolder = Instance.new("Frame", sectionCard)
        sectionContentHolder.Size = UDim2.new(1, -(cardPadX * 2), 0, 0)
        sectionContentHolder.Position = UDim2.fromOffset(cardPadX, cardPadTop + headerHeight + headerSpacing)
        sectionContentHolder.BackgroundTransparency = 1
        sectionContentHolder.ClipsDescendants = false
        sectionContentHolder.AutomaticSize = Enum.AutomaticSize.Y

        local sectionContent = Instance.new("Frame", sectionContentHolder)
        sectionContent.Size = UDim2.new(1, 0, 0, 0)
        sectionContent.BackgroundTransparency = 1
        sectionContent.AutomaticSize = Enum.AutomaticSize.Y

        sectionList = Instance.new("UIListLayout", sectionContent)
        sectionList.Padding = UDim.new(0, UISettings.CompactMode and 4 or 6)
        sectionList.SortOrder = Enum.SortOrder.LayoutOrder
        sectionList:SetAttribute("SectionListLayout", true)

        refreshSectionSize = function(animate)
            local contentHeight = sectionList.AbsoluteContentSize.Y
            -- Break zero-height deadlock: AbsoluteSize stays 0 while clipped parent height is 0.
            if contentHeight < 1 then
                local pad = sectionList.Padding.Offset
                local sum, count = 0, 0
                for _, ch in ipairs(sectionContent:GetChildren()) do
                    if ch:IsA("GuiObject") and ch.Visible and not ch:IsA("UILayout") then
                        local h = ch.AbsoluteSize.Y
                        if h < 1 then h = ch.Size.Y.Offset end
                        if h > 0 then
                            sum = sum + h
                            count = count + 1
                        end
                    end
                end
                if count > 0 then
                    contentHeight = sum + pad * math.max(count - 1, 0)
                end
            end
            local targetHolderHeight = collapsed and 0 or contentHeight
            local targetCardHeight = cardPadTop + headerHeight + headerSpacing + targetHolderHeight + cardPadBottom
            if targetCardHeight < (headerHeight > 0 and (cardPadTop + headerHeight + cardPadBottom) or 36) then
                targetCardHeight = headerHeight > 0 and (cardPadTop + headerHeight + cardPadBottom) or 36
            end
            if animate then
                TweenService:Create(sectionContentHolder, UI.Ease.Med, {
                    Size = UDim2.new(1, -(cardPadX * 2), 0, targetHolderHeight)
                }):Play()
                TweenService:Create(sectionCard, UI.Ease.Med, {
                    Size = UDim2.new(1, -6, 0, targetCardHeight)
                }):Play()
            else
                sectionContentHolder.Size = UDim2.new(1, -(cardPadX * 2), 0, targetHolderHeight)
                sectionCard.Size = UDim2.new(1, -6, 0, targetCardHeight)
            end
            task.defer(refreshPageCanvas)
        end

        sectionList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            refreshSectionSize(false)
            task.defer(refreshPageCanvas)
        end)
        sectionContent.ChildAdded:Connect(function()
            task.defer(function()
                refreshSectionSize(false)
                refreshPageCanvas()
            end)
        end)
        refreshSectionSize(false)

        currentSectionContent = sectionContent
        currentSectionOrder = 0

        return sectionContent, sectionTitleLabel
    end

    local function getElementContainer()
        if not currentSectionContent then
            createSectionCard(nil)
        end
        currentSectionOrder = currentSectionOrder + 1
        return currentSectionContent, currentSectionOrder
    end

    tabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(Window.Tabs) do
            t.Page.Visible = false
            updateTabVisuals(t, false)
        end
        container.Visible = true
        updateTabVisuals(TabObj, true)
        setBreadcrumb(Config.Title)
        local q = UISettings.GlobalSearch
        if Window.GlobalSearchBox and Window.GlobalSearchBox.Text ~= "" then
            q = Window.GlobalSearchBox.Text
        end
        if q and q ~= "" then
            Window_ApplyGlobalSearch(q)
        end
        task.defer(refreshPageCanvas)
    end)

    function TabObj:AddToggle(text, arg2, arg3)
        local default = type(arg2) == "boolean" and arg2 or false
        local callback = type(arg2) == "function" and arg2 or arg3
        local parentColumn, order = getElementContainer()

        local tgl = Instance.new("TextButton", parentColumn)
        tgl.LayoutOrder = order
        tgl.Size = UDim2.new(1, 0, 0, controlRowHeight())
        tgl.Text = ""
        tgl.AutoButtonColor = false
        applyControlChrome(tgl)
        markSearchable(tgl, text)
        tgl:SetAttribute("ControlType", "Toggle")
        registerSearchable(text, tgl, Config.Title)
        table.insert(Window.AllElements, tgl)
        rippleClick(tgl)

        local label = Instance.new("TextLabel", tgl)
        label.Size = UDim2.new(1, -62, 1, 0)
        label.Position = UDim2.fromOffset(10, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = UISettings.CompactMode and 14 or 15
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextWrapped = true
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.TextColor3 = Color3.new(1, 1, 1)
        ApplyGradient(label)
        table.insert(Window.TextElements, label)

        local mobileUI = isTouchMobileDevice()
        local swW, swH = mobileUI and 52 or 40, mobileUI and 26 or 20
        local dotSz = mobileUI and 18 or 14
        local swPad = mobileUI and 56 or 48

        local sw = Instance.new("Frame", tgl)
        sw.Size = UDim2.fromOffset(swW, swH)
        sw.Position = UDim2.new(1, -(swPad + 4), 0.5, -swH / 2)
        sw.BackgroundColor3 = UI.Surface.ControlHover
        sw.BorderSizePixel = 0
        Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)
        uiStroke(sw, 1, 0.6)

        local dot = Instance.new("Frame", sw)
        dot.Size = UDim2.fromOffset(dotSz, dotSz)
        dot.Position = UDim2.new(0, 3, 0.5, -dotSz / 2)
        dot.BackgroundColor3 = UI.Surface.Text
        dot.BorderSizePixel = 0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

        local function updateToggleLayout()
            local availableWidth = math.max(tgl.AbsoluteSize.X - (swPad + 16), 80)
            local measured = TextService:GetTextSize(text, label.TextSize, label.Font, Vector2.new(availableWidth, 1000))
            local targetHeight = math.clamp(measured.Y + 14, mobileUI and 48 or 40, mobileUI and 84 or 76)
            tgl.Size = UDim2.new(1, -2, 0, targetHeight)
            label.Size = UDim2.new(1, -(swPad + 12), 1, 0)
        end
        updateToggleLayout()
        tgl:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateToggleLayout)

        local state = default
        
        local function SetState(val)
            state = val
            Window.ActiveToggles[sw] = state 
            
            local onOffset = swW - dotSz - 3
            local targetPos = state and UDim2.new(0, onOffset, 0.5, -dotSz / 2) or UDim2.new(0, 3, 0.5, -dotSz / 2)
            tweenProp(dot, { Position = targetPos }, UI.Ease.Spring)
            
            if state then
                sw.BackgroundColor3 = Color3.new(1, 1, 1)
                ApplyGradient(sw)
                tweenProp(sw, { BackgroundTransparency = GlobalTransparency }, UI.Ease.Fast)
            else
                if sw:FindFirstChild("ThemeGradient") then sw.ThemeGradient:Destroy() end
                sw.BackgroundColor3 = UI.Surface.ControlHover
                sw.BackgroundTransparency = GlobalTransparency
            end
            if callback then callback(state) end
        end

        if state then
            Window.ActiveToggles[sw] = true
            dot.Position = UDim2.new(0, swW - dotSz - 3, 0.5, -dotSz / 2)
            ApplyGradient(sw)
        end

        tgl.MouseEnter:Connect(function()
            if tgl:GetAttribute("PremiumChrome") then
                tweenProp(tgl, { BackgroundColor3 = UI.Surface.ControlHover }, UI.Ease.Fast)
            end
        end)
        tgl.MouseLeave:Connect(function()
            if tgl:GetAttribute("PremiumChrome") then
                tweenProp(tgl, { BackgroundColor3 = UI.Surface.Control }, UI.Ease.Fast)
            end
        end)

        tgl.MouseButton1Click:Connect(function()
            SetState(not state)
        end)
        
        Window.ElementRegistry[text] = {
            Type = "Toggle",
            Frame = tgl,
            SetValue = function(v) if v ~= state then SetState(v) end end,
            GetValue = function() return state end,
            SetVisible = function(v) tgl.Visible = v end,
            Label = label
        }
    end

    function TabObj:AddLabel(text)
        local sectionContent, sectionTitleLabel = createSectionCard(text)
        Window.SectionAnchors = Window.SectionAnchors or {}
        if sectionContent and text and text ~= "" then
            Window.SectionAnchors[text] = sectionContent
        end
        local labelObj = {
            Instance = sectionTitleLabel,
            SetText = function(self, newText)
                if sectionTitleLabel then
                    sectionTitleLabel.Text = newText
                end
            end,
            TextLabel = sectionTitleLabel
        }
        return labelObj
    end

    function TabObj:AddButton(text, callback)
        local parentColumn, order = getElementContainer()
        local btn = Instance.new("TextButton", parentColumn)
        btn.LayoutOrder = order
        btn.Size = UDim2.new(1, 0, 0, controlRowHeight() - 4)
        btn.Text = ""
        btn.AutoButtonColor = false
        applyControlChrome(btn)
        markSearchable(btn, text)
        btn:SetAttribute("ControlType", "Button")
        registerSearchable(text, btn, Config.Title)
        table.insert(Window.AllElements, btn)
        rippleClick(btn)
        
        local label = Instance.new("TextLabel", btn)
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Text = text
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 14
        label.TextColor3 = UI.Surface.Text
        ApplyGradient(label)
        table.insert(Window.TextElements, label)
        btn.MouseEnter:Connect(function()
            tweenProp(btn, { BackgroundColor3 = UI.Surface.ControlHover }, UI.Ease.Fast)
        end)
        btn.MouseLeave:Connect(function()
            tweenProp(btn, { BackgroundColor3 = UI.Surface.Control }, UI.Ease.Fast)
        end)
        btn.MouseButton1Click:Connect(callback)
        return label
    end
    
    function TabObj:AddSlider(text, min, max, default, arg5, arg6)
        local step = 0.01
        local callback
        if type(arg5) == "number" then
            step = arg5
            callback = arg6
        else
            callback = arg5
        end
        local decimals = 0
        local s = tostring(step)
        local dot = string.find(s, ".", 1, true)
        if dot then
            decimals = #s - dot
        end
        local parentColumn, order = getElementContainer()
        local sFrame = Instance.new("Frame", parentColumn)
        sFrame.Size = UDim2.new(1, -2, 0, isTouchMobileDevice() and 72 or (UISettings.CompactMode and 54 or 62))
        sFrame.LayoutOrder = order
        applyControlChrome(sFrame)
        markSearchable(sFrame, text)
        sFrame:SetAttribute("ControlType", "Slider")
        registerSearchable(text, sFrame, Config.Title)
        table.insert(Window.AllElements, sFrame)

        local label = Instance.new("TextLabel", sFrame)
        label.Text = text
        label.Size = UDim2.new(1, -68, 0, 22)
        label.Position = UDim2.fromOffset(12, 8)
        label.Font = UI.FontBody
        label.TextSize = 13
        label.TextColor3 = UI.Surface.Text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.BackgroundTransparency = 1
        table.insert(Window.TextElements, label)

        local valBg = Instance.new("Frame", sFrame)
        valBg.Size = UDim2.new(0, 56, 0, 24)
        valBg.Position = UDim2.new(1, -64, 0, 7)
        styleInputBackground(valBg)
        table.insert(Window.AllElements, valBg)

        local val = Instance.new("TextBox", valBg)
        val.Size = UDim2.new(1, -8, 1, -4)
        val.Position = UDim2.new(0, 4, 0, 2)
        val.Font = UI.FontTitle
        val.TextSize = 13
        val.TextColor3 = UI.Surface.Muted
        val.TextXAlignment = Enum.TextXAlignment.Right
        val.ClearTextOnFocus = false
        styleTextBox(val)
        val:SetAttribute("IsTextBox", true)
        table.insert(Window.TextElements, val)

        local barH = isTouchMobileDevice() and 12 or 8
        local grabSz = isTouchMobileDevice() and 22 or 16
        local barBg = Instance.new("Frame", sFrame)
        barBg.Size = UDim2.new(1, -28, 0, barH)
        barBg.Position = UDim2.new(0, 12, 1, -(barH + 10))
        barBg.BackgroundColor3 = UI.Surface.ControlHover
        barBg.BorderSizePixel = 0
        Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame", barBg)
        fill.BackgroundColor3 = Color3.new(1, 1, 1)
        fill.BorderSizePixel = 0
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
        ApplyGradient(fill)
        table.insert(Window.ThemedElements, fill)

        local grab = Instance.new("Frame", fill)
        grab.AnchorPoint = Vector2.new(0.5, 0.5)
        grab.Position = UDim2.new(1, 0, 0.5, 0)
        grab.Size = UDim2.fromOffset(grabSz, grabSz)
        grab.BackgroundColor3 = Color3.new(1, 1, 1)
        grab.BorderSizePixel = 0
        Instance.new("UICorner", grab).CornerRadius = UDim.new(1, 0)
        uiStroke(grab, 1.5, 0.2)
        ApplyGradient(grab)
        table.insert(Window.ThemedElements, grab)
        local currentVal = default or min
        if currentVal < min then
            currentVal = min
        elseif currentVal > max then
            currentVal = max
        end
        local function snap(value)
            if max == min then
                return min
            end
            local scaled = (value - min) / step
            scaled = math.floor(scaled + 0.5)
            return min + scaled * step
        end
        local function formatValue(v)
            if decimals <= 0 then
                return tostring(math.floor(v + 0.5))
            end
            local fmt = "%." .. tostring(decimals) .. "f"
            return string.format(fmt, v)
        end
        local syncingValue = false
        local function setDisplayValue(v)
            syncingValue = true
            val.Text = formatValue(v)
            syncingValue = false
        end
        local function applyValue(rawValue, fireCallback)
            currentVal = snap(math.clamp(rawValue, min, max))
            local pos
            if max == min then
                pos = 0
            else
                pos = (currentVal - min) / (max - min)
            end
            TweenService:Create(fill, UI.Ease.Fast, { Size = UDim2.fromScale(pos, 1) }):Play()
            setDisplayValue(currentVal)
            if fireCallback and callback then
                callback(currentVal)
            end
        end
        local function update(input)
            local pos
            if input then
                pos = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
            else
                if max == min then
                    pos = 0
                else
                    pos = (currentVal - min) / (max - min)
                end
            end
            local raw = min + (max - min) * pos
            applyValue(raw, true)
        end
        val.FocusLost:Connect(function()
            if syncingValue then return end
            local parsed = tonumber(val.Text)
            if parsed == nil then
                setDisplayValue(currentVal)
                return
            end
            applyValue(parsed, true)
        end)
        local active = false
        barBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then active = true; update(input) end end)
        UserInputService.InputChanged:Connect(function(input) if active and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input) end end)
        UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then active = false end end)
        update()

        Window.ElementRegistry[text] = {
            Type = "Slider",
            SetValue = function(v) 
                applyValue(v, true)
            end,
            GetValue = function() return currentVal end
        }
    end

    function TabObj:AddDropdown(text, arg2, arg3, arg4)
        local title, list, default, cb
        
        if type(arg2) == "table" and (arg2.Values or arg2.Title or arg2.Callback) then
            title = arg2.Title or text
            list = arg2.Values or {}
            default = arg2.Default or "None"
            cb = arg2.Callback or arg3
        else
            title = text
            list = arg2 or {}
            default = arg3 or "None"
            cb = arg4
        end

        local allValues = {}
        for i, v in ipairs(list) do
            allValues[i] = v
        end
        
        local dropped = false
        local dropdownMetrics = getMobileDropdownMetrics()
        local parentColumn, order = getElementContainer()
        local dFrame = Instance.new("Frame", parentColumn)
        dFrame.LayoutOrder = order
        dFrame.Size = UDim2.new(1, 0, 0, controlRowHeight())
        applyControlChrome(dFrame)
        markSearchable(dFrame, title or text)
        dFrame:SetAttribute("ControlType", "Dropdown")
        registerSearchable(title or text, dFrame, Config.Title)
        table.insert(Window.AllElements, dFrame)

        local btn = Instance.new("TextButton", dFrame)
        btn.Size = UDim2.fromScale(1, 1)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.AutoButtonColor = false
        rippleClick(btn)
        
        local label = Instance.new("TextLabel", btn)
        label.Size = UDim2.new(1, -40, 1, 0)
        label.Position = UDim2.fromOffset(12, 0)
        label.Text = title .. ": " .. tostring(default)
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 14
        label.TextColor3 = UI.Surface.Text
        label.TextXAlignment = "Left"; label.BackgroundTransparency = 1
        label.TextWrapped = true
        label.TextYAlignment = Enum.TextYAlignment.Center
        ApplyGradient(label); table.insert(Window.TextElements, label)

        local arrow = Instance.new("TextLabel", dFrame)
        arrow.Size = UDim2.fromOffset(32, 24); arrow.AnchorPoint = Vector2.new(0, 0.5); arrow.Position = UDim2.new(1, -36, 0.5, 0)
        arrow.Text = "v"; arrow.Font = "GothamBold"; arrow.TextSize = 12; arrow.TextColor3 = Color3.new(1,1,1); arrow.BackgroundTransparency = 1
        arrow.ZIndex = 101
        ApplyGradient(arrow); table.insert(Window.TextElements, arrow)

        local function updateDropdownLayout()
            local availableWidth = math.max(dFrame.AbsoluteSize.X - 54, 90)
            local measured = TextService:GetTextSize(label.Text, label.TextSize, label.Font, Vector2.new(availableWidth, 1000))
            local targetHeight = math.clamp(measured.Y + 14, 40, 72)
            dFrame.Size = UDim2.new(1, 0, 0, targetHeight)
            label.Size = UDim2.new(1, -50, 1, 0)
        end
        updateDropdownLayout()
        dFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateDropdownLayout)

        local popContainer = Instance.new("Frame", screenGui)
        popContainer.Name = "DropdownHolder"
        popContainer.Size = UDim2.new(0, 0, 0, 0)
        popContainer.BackgroundTransparency = 1
        popContainer.BorderSizePixel = 0
        popContainer.ZIndex = 300
        popContainer.Visible = false
        popContainer.ClipsDescendants = false

        local popBackground = Instance.new("Frame", popContainer)
        popBackground.Size = UDim2.new(1, 0, 1, 0)
        popBackground.Position = UDim2.new(0, 0, 0, 0)
        popBackground.BackgroundColor3 = UI.Surface.Card
        popBackground.BorderSizePixel = 0
        popBackground.ZIndex = 300
        popBackground.ClipsDescendants = true

        local popCorner = Instance.new("UICorner", popBackground)
        popCorner.CornerRadius = UDim.new(0, 10)

        local popStroke = Instance.new("UIStroke", popBackground)
        popStroke.Thickness = 1
        popStroke.Color = Color3.new(1,1,1)
        ApplyGradient(popStroke)
        table.insert(Window.ThemedElements, popStroke)

        local popOut = Instance.new("ScrollingFrame", popBackground)
        popOut.Name = "DropdownList"
        popOut.Size = UDim2.new(1, 0, 1, 0)
        popOut.BackgroundTransparency = 1
        popOut.BorderSizePixel = 0
        popOut.ZIndex = 301
        popOut.ClipsDescendants = false
        popOut.ScrollBarThickness = 0
        popOut.CanvasSize = UDim2.new(0,0,0, 0)
        popOut.ScrollBarImageColor3 = CurrentTheme.Main
        popOut.Active = true
        table.insert(Window.ScrollFrames, popOut)

        local dropdownTopPadding = 1
        local dropdownPadding = Instance.new("UIPadding", popOut)
        dropdownPadding.PaddingTop = UDim.new(0, dropdownTopPadding)

        local listLayout = Instance.new("UIListLayout", popOut)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local searchFrame = Instance.new("Frame", popOut)
        searchFrame.Name = "DropdownSearchFrame"
        searchFrame.Size = UDim2.new(1, 0, 0, dropdownMetrics.searchHeight)
        searchFrame.BackgroundColor3 = UI.Surface.Control
        searchFrame.BackgroundTransparency = GlobalTransparency
        searchFrame.BorderSizePixel = 0
        searchFrame.LayoutOrder = 0
        searchFrame.ZIndex = 304
        searchFrame:SetAttribute("PremiumChrome", true)
        searchFrame:SetAttribute("ChromeRole", "InputBg")
        uiCorner(searchFrame, UI.Radius.sm)

        local searchBox = Instance.new("TextBox", searchFrame)
        searchBox.Size = UDim2.new(1, -10, 1, 0)
        searchBox.Position = UDim2.new(0, 5, 0, 0)
        searchBox.Text = ""
        searchBox.ClearTextOnFocus = false
        searchBox.TextXAlignment = "Left"
        searchBox.ZIndex = 305
        styleTextBox(searchBox, "Search...")
        table.insert(Window.AllElements, searchFrame)

        local function closeDropdown()
            dropped = false
            local targetSize = UDim2.new(0, dFrame.AbsoluteSize.X, 0, 0)
            if popContainer:IsDescendantOf(game) then
                popContainer:TweenSize(targetSize, "Out", "Quad", 0.2, true, function()
                    if not dropped then popContainer.Visible = false end
                end)
            else
                popContainer.Size = targetSize
                popContainer.Visible = false
            end

            if arrow:IsDescendantOf(game) then
                TweenService:Create(arrow, TweenInfo.new(0.3), {Rotation = 0}):Play()
            else
                arrow.Rotation = 0
            end
        end

        local options = {}

        local function buildAllOptions()
            for _, entry in ipairs(options) do
                if entry.Button then
                    entry.Button:Destroy()
                end
            end
            options = {}
            
            -- Removed the hard limit of 150.
            -- Using a simpler loop to support larger lists (like waypoints).
            
            for i, v in ipairs(allValues) do
                local opt = Instance.new("TextButton", popOut)
                opt.Size = UDim2.new(1, 0, 0, dropdownMetrics.optionHeight)
                opt.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                opt.BackgroundTransparency = 1
                opt.Text = ""
                opt.BorderSizePixel = 0
                opt.ZIndex = 305
                opt.LayoutOrder = i

                local optLabel = Instance.new("TextLabel", opt)
                optLabel.Size = UDim2.new(1, -10, 1, 0)
                optLabel.Position = UDim2.new(0, 10, 0, 0)
                optLabel.BackgroundTransparency = 1
                optLabel.Text = tostring(v)
                optLabel.Font = "SourceSansBold"
                optLabel.TextSize = 13
                optLabel.TextXAlignment = "Left"
                optLabel.TextColor3 = Color3.new(1,1,1)
                optLabel.ZIndex = 306
                ApplyGradient(optLabel)
                table.insert(Window.TextElements, optLabel)

                opt.MouseButton1Click:Connect(function()
                    closeDropdown()
                    label.Text = title .. ": " .. tostring(v)
                    updateDropdownLayout()
                    default = v
                    if cb then cb(v) end
                end)

                table.insert(options, {Value = v, Button = opt, Label = optLabel})
            end
        end

        local function applySearchFilter()
            local query = string.lower(searchBox.Text or "")
            local visibleCount = 0
            for _, entry in ipairs(options) do
                local v = entry.Value
                local btn = entry.Button
                local s = string.lower(tostring(v))
                local match = (query == "" or string.find(s, query, 1, true) ~= nil)
                btn.Visible = match
                if match then
                    visibleCount = visibleCount + 1
                    btn.LayoutOrder = visibleCount
                else
                    btn.LayoutOrder = 9999
                end
            end
            local contentHeight = dropdownTopPadding + dropdownMetrics.searchHeight + visibleCount * dropdownMetrics.optionHeight
            popOut.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
            if dropped then
                local maxHeight = math.min(contentHeight, dropdownMetrics.maxHeight)
                positionDropdownPop(popContainer, dFrame, maxHeight)
            end
        end

        buildAllOptions()
        applySearchFilter()

        searchBox:GetPropertyChangedSignal("Text"):Connect(applySearchFilter)

        UserInputService.InputBegan:Connect(function(input, gpe)
            if not dropped then return end
            local t = input.UserInputType
            if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.MouseButton2 or t == Enum.UserInputType.Touch then
                local pos = input.Position
                local x, y = pos.X, pos.Y

                local btnPos, btnSize = dFrame.AbsolutePosition, dFrame.AbsoluteSize
                local insideButton = x >= btnPos.X and x <= btnPos.X + btnSize.X
                    and y >= btnPos.Y and y <= btnPos.Y + btnSize.Y

                local dropPos, dropSize = popContainer.AbsolutePosition, popContainer.AbsoluteSize
                local insideDropdown = x >= dropPos.X and x <= dropPos.X + dropSize.X
                    and y >= dropPos.Y and y <= dropPos.Y + dropSize.Y

                if not insideButton and not insideDropdown then
                    closeDropdown()
                end
            end
        end)

        local updateConnection
        local function updatePosition()
            if not dropped or not dFrame.Parent then 
                if updateConnection then updateConnection:Disconnect() end
                popContainer.Visible = false
                return 
            end
            positionDropdownPop(popContainer, dFrame, popContainer.Size.Y.Offset)
        end
        
        btn.MouseButton1Click:Connect(function()
            if dropped then
                closeDropdown()
                if updateConnection then updateConnection:Disconnect() end
                return
            end
            dropped = true
            popContainer.Visible = true
            updateConnection = game:GetService("RunService").RenderStepped:Connect(updatePosition)
            
            local contentHeight = dropdownTopPadding + dropdownMetrics.searchHeight + #allValues * dropdownMetrics.optionHeight
            local maxHeight = math.min(contentHeight, dropdownMetrics.maxHeight)
            updatePosition()
            
            local targetSize = UDim2.new(0, dFrame.AbsoluteSize.X, 0, maxHeight)
            if popContainer:IsDescendantOf(game) then
                popContainer:TweenSize(targetSize, "Out", "Quad", 0.2, true)
            else
                popContainer.Size = targetSize
            end
            
            if arrow:IsDescendantOf(game) then
                TweenService:Create(arrow, TweenInfo.new(0.3), {Rotation = 180}):Play()
            else
                arrow.Rotation = 180
            end
        end)
        
        dFrame.AncestryChanged:Connect(function()
            if not dFrame.Parent then 
                popContainer:Destroy() 
                if updateConnection then updateConnection:Disconnect() end
            end
        end)

        container:GetPropertyChangedSignal("Visible"):Connect(function()
            if not container.Visible and dropped then
                closeDropdown()
            end
        end)

        local dropdownObj = {}

        function dropdownObj:SetValue(v)
            label.Text = title .. ": " .. tostring(v)
            updateDropdownLayout()
            default = v
            if cb then cb(v) end
        end

        function dropdownObj:GetValue()
            return default
        end

        Window.ElementRegistry[text] = {
            Type = "Dropdown",
            Frame = dFrame,
            SetValue = function(v) dropdownObj:SetValue(v) end,
            GetValue = function() return default end,
            SetVisible = function(v) dFrame.Visible = v end,
        }

        function dropdownObj:SetValues(values)
            list = values or {}
            allValues = list
            buildAllOptions()
            applySearchFilter()
        end

        return dropdownObj
    end

    function TabObj:AddMultiDropdown(text, list, default, cb)
        local title = text
        local selected = {}
        local ALL_OPTIONS_KEY = "AllOptions"
        local hasAllOptions = false
        local realOptions = {}

        for _, v in ipairs(list) do
            -- Treat both "AllOptions" and "All" as the select-all master entry
            if v == ALL_OPTIONS_KEY or v == "All" then
                hasAllOptions = true
                ALL_OPTIONS_KEY = v
            else
                table.insert(realOptions, v)
            end
        end

        local function clearEveryOption()
            for k in pairs(selected) do
                selected[k] = nil
            end
        end

        local function selectEveryOption()
            if hasAllOptions then
                selected[ALL_OPTIONS_KEY] = true
            end
            for _, v in ipairs(realOptions) do
                selected[v] = true
            end
        end

        local function syncAllOptionsMaster()
            if not hasAllOptions then return end
            local allOn = #realOptions > 0
            for _, v in ipairs(realOptions) do
                if not selected[v] then
                    allOn = false
                    break
                end
            end
            if allOn then
                selected[ALL_OPTIONS_KEY] = true
            else
                selected[ALL_OPTIONS_KEY] = nil
            end
        end

        -- Initialize default values (array {"Option"} or map {["Option"]=true})
        if type(default) == "table" then
            local wantAll = false
            local isArray = #default > 0
            if isArray then
                for _, name in ipairs(default) do
                    if name == ALL_OPTIONS_KEY then
                        wantAll = true
                        break
                    end
                end
                if wantAll and hasAllOptions then
                    selectEveryOption()
                else
                    for _, name in ipairs(default) do
                        if name ~= ALL_OPTIONS_KEY then
                            selected[name] = true
                        end
                    end
                    syncAllOptionsMaster()
                end
            else
                for name, sel in pairs(default) do
                    if name == ALL_OPTIONS_KEY and sel then
                        wantAll = true
                    elseif sel then
                        selected[name] = true
                    end
                end
                if wantAll and hasAllOptions then
                    selectEveryOption()
                else
                    syncAllOptionsMaster()
                end
            end
        end
        
        -- Helper to get label text
        local function getLabelText()
            if hasAllOptions and selected[ALL_OPTIONS_KEY] then
                return title .. ": AllOptions"
            end

            local count = 0
            for _, v in ipairs(realOptions) do
                if selected[v] then
                    count = count + 1
                end
            end
            if count == 0 then return title .. ": None" end
            if count == #realOptions then return title .. ": All" end
            
            -- Try to list them if few
            local s = {}
            for _, v in ipairs(realOptions) do
                if selected[v] then table.insert(s, v) end
            end
            table.sort(s)
            if #s <= 2 then
                return title .. ": " .. table.concat(s, ", ")
            end
            return title .. ": " .. tostring(count) .. " Selected"
        end

        local dropped = false
        local dropdownMetrics = getMobileDropdownMetrics()
        local parentColumn, order = getElementContainer()
        local dFrame = Instance.new("Frame", parentColumn)
        dFrame.LayoutOrder = order
        dFrame.Size = UDim2.new(1, 0, 0, controlRowHeight())
        applyControlChrome(dFrame)
        markSearchable(dFrame, text)
        dFrame:SetAttribute("ControlType", "MultiDropdown")
        registerSearchable(text, dFrame, Config.Title)
        table.insert(Window.AllElements, dFrame)

        local btn = Instance.new("TextButton", dFrame)
        btn.Size = UDim2.fromScale(1, 1)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.AutoButtonColor = false
        rippleClick(btn)
        
        local label = Instance.new("TextLabel", btn)
        label.Size = UDim2.new(1, -40, 1, 0)
        label.Position = UDim2.fromOffset(12, 0)
        label.Text = getLabelText()
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 14
        label.TextColor3 = UI.Surface.Text
        label.TextXAlignment = "Left"; label.BackgroundTransparency = 1
        label.TextWrapped = true
        label.TextYAlignment = Enum.TextYAlignment.Center
        ApplyGradient(label); table.insert(Window.TextElements, label)

        local arrow = Instance.new("TextLabel", dFrame)
        arrow.Size = UDim2.fromOffset(32, 24); arrow.AnchorPoint = Vector2.new(0, 0.5); arrow.Position = UDim2.new(1, -36, 0.5, 0)
        arrow.Text = "v"; arrow.Font = "GothamBold"; arrow.TextSize = 12; arrow.TextColor3 = Color3.new(1,1,1); arrow.BackgroundTransparency = 1
        arrow.ZIndex = 101
        ApplyGradient(arrow); table.insert(Window.TextElements, arrow)

        local function updateMultiDropdownLayout()
            local availableWidth = math.max(dFrame.AbsoluteSize.X - 54, 90)
            local measured = TextService:GetTextSize(label.Text, label.TextSize, label.Font, Vector2.new(availableWidth, 1000))
            local minH = isTouchMobileDevice() and 48 or 40
            local targetHeight = math.clamp(measured.Y + 14, minH, isTouchMobileDevice() and 84 or 72)
            dFrame.Size = UDim2.new(1, 0, 0, targetHeight)
            label.Size = UDim2.new(1, -50, 1, 0)
        end
        updateMultiDropdownLayout()
        dFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateMultiDropdownLayout)

        local popContainer = Instance.new("Frame", screenGui)
        popContainer.Name = "DropdownHolder"
        popContainer.Size = UDim2.new(0, 0, 0, 0)
        popContainer.BackgroundTransparency = 1
        popContainer.BorderSizePixel = 0
        popContainer.ZIndex = 300
        popContainer.Visible = false
        popContainer.ClipsDescendants = false

        local popBackground = Instance.new("Frame", popContainer)
        popBackground.Size = UDim2.new(1, 0, 1, 0)
        popBackground.Position = UDim2.new(0, 0, 0, 0)
        popBackground.BackgroundColor3 = UI.Surface.Card
        popBackground.BorderSizePixel = 0
        popBackground.ZIndex = 300
        popBackground.ClipsDescendants = true

        local popCorner = Instance.new("UICorner", popBackground)
        popCorner.CornerRadius = UDim.new(0, 10)

        local popStroke = Instance.new("UIStroke", popBackground)
        popStroke.Thickness = 1
        popStroke.Color = Color3.new(1,1,1)
        ApplyGradient(popStroke)
        table.insert(Window.ThemedElements, popStroke)

        local popOut = Instance.new("ScrollingFrame", popBackground)
        popOut.Name = "DropdownList"
        popOut.Size = UDim2.new(1, 0, 1, 0)
        popOut.BackgroundTransparency = 1
        popOut.BorderSizePixel = 0
        popOut.ZIndex = 301
        popOut.ClipsDescendants = false
        popOut.ScrollBarThickness = isTouchMobileDevice() and 6 or 0
        popOut.CanvasSize = UDim2.new(0,0,0, 0)
        popOut.ScrollBarImageColor3 = CurrentTheme.Main
        popOut.Active = true
        table.insert(Window.ScrollFrames, popOut)

        local dropdownTopPadding = 1
        local dropdownPadding = Instance.new("UIPadding", popOut)
        dropdownPadding.PaddingTop = UDim.new(0, dropdownTopPadding)

        local listLayout = Instance.new("UIListLayout", popOut)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local searchFrame = Instance.new("Frame", popOut)
        searchFrame.Name = "DropdownSearchFrame"
        searchFrame.Size = UDim2.new(1, 0, 0, dropdownMetrics.searchHeight)
        searchFrame.BackgroundColor3 = UI.Surface.Control
        searchFrame.BackgroundTransparency = GlobalTransparency
        searchFrame.BorderSizePixel = 0
        searchFrame.LayoutOrder = 0
        searchFrame.ZIndex = 304
        searchFrame:SetAttribute("PremiumChrome", true)
        searchFrame:SetAttribute("ChromeRole", "InputBg")
        uiCorner(searchFrame, UI.Radius.sm)

        local searchBox = Instance.new("TextBox", searchFrame)
        searchBox.Size = UDim2.new(1, -10, 1, 0)
        searchBox.Position = UDim2.new(0, 5, 0, 0)
        searchBox.Text = ""
        searchBox.ClearTextOnFocus = false
        searchBox.TextXAlignment = "Left"
        searchBox.ZIndex = 305
        styleTextBox(searchBox, "Search...")
        table.insert(Window.AllElements, searchFrame)

        local function closeDropdown()
            dropped = false
            local targetSize = UDim2.new(0, dFrame.AbsoluteSize.X, 0, 0)
            if popContainer:IsDescendantOf(game) then
                popContainer:TweenSize(targetSize, "Out", "Quad", 0.2, true, function()
                    if not dropped then popContainer.Visible = false end
                end)
            else
                popContainer.Size = targetSize
                popContainer.Visible = false
            end

            if arrow:IsDescendantOf(game) then
                TweenService:Create(arrow, TweenInfo.new(0.3), {Rotation = 0}):Play()
            else
                arrow.Rotation = 0
            end
        end

        local options = {}

        local function styleMultiOptionLabel(optLabel, optionValue)
            optLabel.Text = tostring(optionValue)
            optLabel.TextColor3 = Color3.new(1, 1, 1)
            if selected[optionValue] then
                ApplyGradient(optLabel)
            else
                local grad = optLabel:FindFirstChild("ThemeGradient")
                if grad then grad:Destroy() end
                optLabel.TextColor3 = UI.Surface.Muted
            end
        end

        local function buildAllOptions()
            for _, entry in ipairs(options) do
                if entry.Button then
                    entry.Button:Destroy()
                end
            end
            options = {}
            
            for i, v in ipairs(list) do
                local opt = Instance.new("TextButton", popOut)
                opt.Size = UDim2.new(1, 0, 0, dropdownMetrics.optionHeight)
                opt.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                opt.BackgroundTransparency = 1
                opt.Text = ""
                opt.BorderSizePixel = 0
                opt.ZIndex = 305
                opt.LayoutOrder = i

                local optLabel = Instance.new("TextLabel", opt)
                optLabel.Size = UDim2.new(1, -10, 1, 0)
                optLabel.Position = UDim2.new(0, 10, 0, 0)
                optLabel.BackgroundTransparency = 1
                optLabel.Font = Enum.Font.SourceSansBold
                optLabel.TextSize = isTouchMobileDevice() and 14 or 13
                optLabel.TextXAlignment = Enum.TextXAlignment.Left
                optLabel.ZIndex = 306
                table.insert(Window.TextElements, optLabel)

                local function updateVisual()
                    styleMultiOptionLabel(optLabel, v)
                end
                updateVisual()

                opt.MouseButton1Click:Connect(function()
                    if v == ALL_OPTIONS_KEY then
                        if selected[v] then
                            clearEveryOption()
                        else
                            selectEveryOption()
                        end
                    else
                        selected[v] = not selected[v]
                        if not selected[v] then selected[v] = nil end
                        syncAllOptionsMaster()
                    end

                    for _, entry in ipairs(options) do
                        styleMultiOptionLabel(entry.Label, entry.Value)
                    end
                    
                    label.Text = getLabelText()
                    updateMultiDropdownLayout()
                    if cb then cb(selected) end
                end)

                table.insert(options, {Value = v, Button = opt, Label = optLabel})
            end
        end

        local function applySearchFilter()
            local query = string.lower(searchBox.Text or "")
            local visibleCount = 0
            for _, entry in ipairs(options) do
                local v = entry.Value
                local btn = entry.Button
                local s = string.lower(tostring(v))
                local match = (query == "" or string.find(s, query, 1, true) ~= nil)
                btn.Visible = match
                if match then
                    visibleCount = visibleCount + 1
                    btn.LayoutOrder = visibleCount
                else
                    btn.LayoutOrder = 9999
                end
            end
            local contentHeight = dropdownTopPadding + dropdownMetrics.searchHeight + visibleCount * dropdownMetrics.optionHeight
            popOut.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
            if dropped then
                local maxHeight = math.min(contentHeight, dropdownMetrics.maxHeight)
                positionDropdownPop(popContainer, dFrame, maxHeight)
            end
        end

        buildAllOptions()
        applySearchFilter()

        searchBox:GetPropertyChangedSignal("Text"):Connect(applySearchFilter)

        UserInputService.InputBegan:Connect(function(input, gpe)
            if not dropped then return end
            local t = input.UserInputType
            if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.MouseButton2 or t == Enum.UserInputType.Touch then
                local pos = input.Position
                local x, y = pos.X, pos.Y

                local btnPos, btnSize = dFrame.AbsolutePosition, dFrame.AbsoluteSize
                local insideButton = x >= btnPos.X and x <= btnPos.X + btnSize.X
                    and y >= btnPos.Y and y <= btnPos.Y + btnSize.Y

                local dropPos, dropSize = popContainer.AbsolutePosition, popContainer.AbsoluteSize
                local insideDropdown = x >= dropPos.X and x <= dropPos.X + dropSize.X
                    and y >= dropPos.Y and y <= dropPos.Y + dropSize.Y

                if not insideButton and not insideDropdown then
                    closeDropdown()
                end
            end
        end)

        local updateConnection
        local function updatePosition()
            if not dropped or not dFrame.Parent then 
                if updateConnection then updateConnection:Disconnect() end
                popContainer.Visible = false
                return 
            end
            positionDropdownPop(popContainer, dFrame, popContainer.Size.Y.Offset)
        end
        
        btn.MouseButton1Click:Connect(function()
            if dropped then
                closeDropdown()
                if updateConnection then updateConnection:Disconnect() end
                return
            end
            dropped = true
            popContainer.Visible = true
            updateConnection = game:GetService("RunService").RenderStepped:Connect(updatePosition)
            
            local contentHeight = dropdownTopPadding + dropdownMetrics.searchHeight + #list * dropdownMetrics.optionHeight
            local maxHeight = math.min(contentHeight, dropdownMetrics.maxHeight)
            updatePosition()
            
            local targetSize = UDim2.new(0, dFrame.AbsoluteSize.X, 0, maxHeight)
            if popContainer:IsDescendantOf(game) then
                popContainer:TweenSize(targetSize, "Out", "Quad", 0.2, true)
            else
                popContainer.Size = targetSize
            end
            
            if arrow:IsDescendantOf(game) then
                TweenService:Create(arrow, TweenInfo.new(0.3), {Rotation = 180}):Play()
            else
                arrow.Rotation = 180
            end
        end)
        
        dFrame.AncestryChanged:Connect(function()
            if not dFrame.Parent then 
                popContainer:Destroy() 
                if updateConnection then updateConnection:Disconnect() end
            end
        end)

        container:GetPropertyChangedSignal("Visible"):Connect(function()
            if not container.Visible and dropped then
                closeDropdown()
            end
        end)
        
        local function applySelectionTable(v)
            clearEveryOption()
            if type(v) ~= "table" then return end
            local isArray = #v > 0
            if isArray then
                for _, name in ipairs(v) do
                    if type(name) == "string" and name ~= "" then
                        selected[name] = true
                    end
                end
            else
                for name, sel in pairs(v) do
                    if sel then selected[name] = true end
                end
            end
            if hasAllOptions and selected[ALL_OPTIONS_KEY] then
                selectEveryOption()
            else
                syncAllOptionsMaster()
            end
        end

        local function syncSelectedToUI()
            for _, entry in ipairs(options) do
                local v = entry.Value
                if selected[v] then
                    entry.Label.TextColor3 = CurrentTheme.Main
                else
                    entry.Label.TextColor3 = Color3.new(1, 1, 1)
                end
            end
            label.Text = getLabelText()
            updateMultiDropdownLayout()
        end

        Window.ElementRegistry[text] = {
            Type = "MultiDropdown",
            SetValue = function(a, b)
                -- Support both .SetValue(v) and :SetValue(v)
                local v = a
                if type(a) == "table" and a.Type == "MultiDropdown" then
                    v = b
                end
                applySelectionTable(v)
                syncSelectedToUI()
                if cb then cb(selected) end
            end,
            GetValue = function()
                return selected
            end,
            SetValues = function(a, b)
                -- Support both .SetValues(list) and :SetValues(list)
                local newList = a
                if type(a) == "table" and a.Type == "MultiDropdown" then
                    newList = b
                end
                if type(newList) ~= "table" then
                    newList = {}
                end
                list = newList
                hasAllOptions = false
                realOptions = {}
                for _, v in ipairs(list) do
                    if v == "AllOptions" or v == "All" then
                        hasAllOptions = true
                        ALL_OPTIONS_KEY = v
                    else
                        table.insert(realOptions, v)
                    end
                end
                buildAllOptions()
                applySearchFilter()
                syncSelectedToUI()
            end,
        }

        if cb then cb(selected) end

        return Window.ElementRegistry[text]
    end

    function TabObj:AddInput(text, default, callback)
        local parentColumn, order = getElementContainer()
        local iFrame = Instance.new("Frame", parentColumn)
        iFrame.LayoutOrder = order
        iFrame.Size = UDim2.new(1, 0, 0, controlRowHeight() + 4)
        applyControlChrome(iFrame)
        markSearchable(iFrame, text)
        iFrame:SetAttribute("ControlType", "Input")
        registerSearchable(text, iFrame, Config.Title)
        table.insert(Window.AllElements, iFrame)

        local label = Instance.new("TextLabel", iFrame)
        label.Text = "  " .. text
        label.Size = UDim2.new(0, 120, 1, 0)
        label.Font = "SourceSansBold"
        label.TextSize = 15
        label.TextColor3 = Color3.new(1,1,1)
        label.TextXAlignment = "Left"
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.TextWrapped = false
        label.ClipsDescendants = true
        label.BackgroundTransparency = 1
        ApplyGradient(label)
        table.insert(Window.TextElements, label)

        local boxHeight = 30
        local boxBg = Instance.new("Frame", iFrame)
        boxBg.Size = UDim2.new(1, -130, 0, boxHeight)
        boxBg.Position = UDim2.new(0, 125, 0.5, -(boxHeight/2))
        boxBg.ClipsDescendants = true
        styleInputBackground(boxBg)
        table.insert(Window.AllElements, boxBg)

        local function updateInputLayout()
            local rowHeight = 44
            iFrame.Size = UDim2.new(1, 0, 0, rowHeight)

            local pad = 8 -- symmetric spacing around the input box
            local minLabelWidth = 72
            local minInputWidth = 90

            -- Measure the label (single-line) and reserve as much as we can,
            -- but always leave room for the input box.
            local measuredLabel = math.ceil(label.TextBounds.X) + 14
            local maxLabelWidth = math.max(minLabelWidth, iFrame.AbsoluteSize.X - (minInputWidth + pad * 2))
            local labelWidth = math.clamp(measuredLabel, minLabelWidth, maxLabelWidth)

            label.Size = UDim2.new(0, labelWidth, 1, 0)

            local boxX = labelWidth + pad
            local boxW = math.max(minInputWidth, iFrame.AbsoluteSize.X - (labelWidth + pad * 2))
            boxBg.Position = UDim2.new(0, boxX, 0.5, -(boxHeight / 2))
            boxBg.Size = UDim2.new(0, boxW, 0, boxHeight)
        end
        updateInputLayout()
        label:GetPropertyChangedSignal("Text"):Connect(updateInputLayout)
        iFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateInputLayout)

        local box = Instance.new("TextBox", boxBg)
        box.Size = UDim2.new(1, -12, 1, -2)
        box.Position = UDim2.new(0, 6, 0, 1)
        box.BackgroundTransparency = 1
        box.Text = default or ""
        box.ClearTextOnFocus = false
        box.Font = "SourceSans"
        box.TextSize = 14
        box.TextColor3 = Color3.new(1,1,1)
        box.TextXAlignment = "Left"
        box.TextTruncate = Enum.TextTruncate.None
        styleTextBox(box, "Enter...")
        
        box.FocusLost:Connect(function(enterPressed)
            callback(box.Text)
        end)

        local inputObj = {}
        function inputObj:SetValue(val)
            box.Text = tostring(val)
            callback(box.Text)
        end

        Window.ElementRegistry[text] = {
            Type = "Input",
            Frame = iFrame,
            SetValue = function(v) inputObj:SetValue(v) end,
            GetValue = function() return box.Text end,
            SetVisible = function(v) iFrame.Visible = v end,
        }

        return inputObj
    end

    function TabObj:AddInputInSection(sectionKey, text, default, callback)
        local sectionContent = Window.SectionAnchors and Window.SectionAnchors[sectionKey]
        if not sectionContent then
            return self:AddInput(text, default, callback)
        end
        local savedContent = currentSectionContent
        local savedOrder = currentSectionOrder
        currentSectionContent = sectionContent
        currentSectionOrder = sectionContent:GetAttribute("DynLayoutOrder") or 500
        local result = self:AddInput(text, default, callback)
        sectionContent:SetAttribute("DynLayoutOrder", currentSectionOrder)
        currentSectionContent = savedContent
        currentSectionOrder = savedOrder
        return result
    end

    function TabObj:AddToggleInSection(sectionKey, text, arg2, arg3)
        local sectionContent = Window.SectionAnchors and Window.SectionAnchors[sectionKey]
        if not sectionContent then
            return self:AddToggle(text, arg2, arg3)
        end
        local savedContent = currentSectionContent
        local savedOrder = currentSectionOrder
        currentSectionContent = sectionContent
        currentSectionOrder = sectionContent:GetAttribute("DynLayoutOrder") or 500
        self:AddToggle(text, arg2, arg3)
        sectionContent:SetAttribute("DynLayoutOrder", currentSectionOrder)
        currentSectionContent = savedContent
        currentSectionOrder = savedOrder
    end

    function TabObj:AddSliderInSection(sectionKey, text, min, max, default, arg5, arg6)
        local sectionContent = Window.SectionAnchors and Window.SectionAnchors[sectionKey]
        if not sectionContent then
            return self:AddSlider(text, min, max, default, arg5, arg6)
        end
        local savedContent = currentSectionContent
        local savedOrder = currentSectionOrder
        currentSectionContent = sectionContent
        currentSectionOrder = sectionContent:GetAttribute("DynLayoutOrder") or 500
        self:AddSlider(text, min, max, default, arg5, arg6)
        sectionContent:SetAttribute("DynLayoutOrder", currentSectionOrder)
        currentSectionContent = savedContent
        currentSectionOrder = savedOrder
    end

    function TabObj:AddDropdownInSection(sectionKey, text, arg2, arg3, arg4)
        local sectionContent = Window.SectionAnchors and Window.SectionAnchors[sectionKey]
        if not sectionContent then
            return self:AddDropdown(text, arg2, arg3, arg4)
        end
        local savedContent = currentSectionContent
        local savedOrder = currentSectionOrder
        currentSectionContent = sectionContent
        currentSectionOrder = sectionContent:GetAttribute("DynLayoutOrder") or 500
        self:AddDropdown(text, arg2, arg3, arg4)
        sectionContent:SetAttribute("DynLayoutOrder", currentSectionOrder)
        currentSectionContent = savedContent
        currentSectionOrder = savedOrder
    end

    function TabObj:AddMultiDropdownInSection(sectionKey, text, list, default, cb)
        local sectionContent = Window.SectionAnchors and Window.SectionAnchors[sectionKey]
        if not sectionContent then
            return self:AddMultiDropdown(text, list, default, cb)
        end
        local savedContent = currentSectionContent
        local savedOrder = currentSectionOrder
        currentSectionContent = sectionContent
        currentSectionOrder = sectionContent:GetAttribute("DynLayoutOrder") or 500
        self:AddMultiDropdown(text, list, default, cb)
        sectionContent:SetAttribute("DynLayoutOrder", currentSectionOrder)
        currentSectionContent = savedContent
        currentSectionOrder = savedOrder
    end

    function TabObj:AddLabel(text)
        local sectionContent, sectionTitleLabel = createSectionCard(text)
        Window.SectionAnchors = Window.SectionAnchors or {}
        if sectionContent and text and text ~= "" then
            Window.SectionAnchors[text] = sectionContent
        end
        local labelObj = {
            Instance = sectionTitleLabel,
            SetText = function(self, newText)
                if sectionTitleLabel then
                    sectionTitleLabel.Text = newText
                end
            end,
            TextLabel = sectionTitleLabel
        }
        return labelObj
    end

    table.insert(Window.Tabs, TabObj)
    return TabObj
end
end

Window.UIHelpers = {
    styleInputBackground = styleInputBackground,
    applyControlChrome = applyControlChrome,
    controlRowHeight = controlRowHeight,
    uiCorner = uiCorner,
    uiStroke = uiStroke,
    tweenProp = tweenProp,
}
end -- End of UI Scope

do -- AsterPostUI
-- // COMPATIBILITY SHIM // --
ASTER = { Options = {} }

-- // Dynamic Toggle Keybinds & Mobile Buttons // --
ASTER.ToggleBind = ASTER.ToggleBind or {}
ToggleBind = ASTER.ToggleBind
ToggleBind.keybindInputsCreated = ToggleBind.keybindInputsCreated or {}
ToggleBind.mobileTogglesCreated = ToggleBind.mobileTogglesCreated or {}
ToggleBind.mobileGuis = ToggleBind.mobileGuis or {}

ASTER.MobileWidgets = ASTER.MobileWidgets or {}

function ASTER.mobileWidgetPosition(slot, side)
    slot = slot or 0
    if side == "right" then
        return UDim2.new(0.5, 8, 0.12 + slot * 0.058, 0)
    end
    if side == "center" then
        return UDim2.new(0.5, -58, 0.12 + slot * 0.058, 0)
    end
    return UDim2.new(0, 10, 0.12 + slot * 0.058, 0)
end

function ASTER.CreateMobileWidget(config)
    config = config or {}
    local H = Window and Window.UIHelpers or {}
    local uiCornerFn = H.uiCorner
    local uiStrokeFn = H.uiStroke

    local guiName = config.guiName or "AsterMobileWidget"
    local shortLabel = config.label or "Toggle"
    local mode = config.mode or "toggle"
    local position = config.position or ASTER.mobileWidgetPosition(0)

    local widget = { label = shortLabel, mode = mode, destroyed = false, _isOn = false }

    local gui = Instance.new("ScreenGui")
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    if game:GetService("RunService"):IsStudio() then
        gui.Name = asterGuiCoverName(guiName)
        gui.Parent = plr:WaitForChild("PlayerGui")
    else
        asterParentGui(gui, guiName)
    end

    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.fromOffset(92, 38)
    frame.Position = position
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = gui

    local shell = Instance.new("Frame")
    shell.Name = "Shell"
    shell.Size = UDim2.fromScale(1, 1)
    shell.BackgroundColor3 = UI.Surface.Card
    shell.BackgroundTransparency = math.clamp((GlobalTransparency or 0) + 0.1, 0, 0.85)
    shell.BorderSizePixel = 0
    shell.Parent = frame
    if uiCornerFn then
        uiCornerFn(shell, UI.Radius.sm)
    else
        Instance.new("UICorner", shell).CornerRadius = UDim.new(0, 6)
    end

    local stroke = uiStrokeFn and uiStrokeFn(shell, 1, 0.45, UI.Surface.Stroke) or Instance.new("UIStroke", shell)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    ApplyGradient(stroke)

    local btn = Instance.new("TextButton")
    btn.Name = "ToggleBtn"
    btn.Size = UDim2.new(1, -4, 1, -4)
    btn.Position = UDim2.fromOffset(2, 2)
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextTruncate = Enum.TextTruncate.AtEnd
    btn.Parent = shell
    if uiCornerFn then
        uiCornerFn(btn, UI.Radius.sm)
    else
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    end

    local function clearBtnGradient()
        local grad = btn:FindFirstChild("ThemeGradient")
        if grad then grad:Destroy() end
    end

    function widget.setToggleState(isOn, name)
        name = name or shortLabel
        shortLabel = name
        widget.label = name
        widget._isOn = isOn == true
        btn:SetAttribute("IsOn", widget._isOn)
        btn.Text = name
        btn.TextColor3 = Color3.new(1, 1, 1)
        clearBtnGradient()
        btn.BackgroundTransparency = 0
        if widget._isOn then
            btn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        else
            btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        end
    end

    function widget.setActionLabel(text)
        widget.mode = "action"
        shortLabel = text or shortLabel
        widget.label = shortLabel
        btn.Text = shortLabel
        btn.TextColor3 = Color3.new(1, 1, 1)
        clearBtnGradient()
        btn.BackgroundTransparency = 0
        btn.BackgroundColor3 = (CurrentTheme and CurrentTheme.Main) or Color3.fromRGB(186, 140, 255)
    end

    function widget.flash()
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        task.delay(0.12, function()
            if widget.destroyed then return end
            if widget.mode == "action" then
                widget.setActionLabel(shortLabel)
            else
                widget.setToggleState(widget._isOn, shortLabel)
            end
        end)
    end

    function widget.applyTheme()
        if widget.destroyed then return end
        if shell then
            shell.BackgroundColor3 = UI.Surface.Card
            shell.BackgroundTransparency = math.clamp((GlobalTransparency or 0) + 0.1, 0, 0.85)
        end
        if stroke then
            stroke.Color = UI.Surface.Stroke
            ApplyGradient(stroke)
        end
        if widget.mode == "action" then
            widget.setActionLabel(shortLabel)
        else
            widget.setToggleState(widget._isOn, shortLabel)
        end
        ASTER.ApplyMobileWidgetSize(widget)
    end

    function widget.destroy()
        if widget.destroyed then return end
        widget.destroyed = true
        for i, w in ipairs(ASTER.MobileWidgets) do
            if w == widget then
                table.remove(ASTER.MobileWidgets, i)
                break
            end
        end
        if gui then
            pcall(function() gui:Destroy() end)
        end
    end

    makeMobileDraggable(frame, btn, config.onClick)

    widget.gui = gui
    widget.frame = frame
    widget.shell = shell
    widget.stroke = stroke
    widget.btn = btn

    table.insert(ASTER.MobileWidgets, widget)

    if mode == "action" then
        widget.setActionLabel(shortLabel)
    elseif config.initialOn ~= nil then
        widget.setToggleState(config.initialOn, shortLabel)
    else
        widget.setToggleState(false, shortLabel)
    end

    ASTER.ApplyMobileWidgetSize(widget)
    if mainFrame then
        gui.Enabled = mainFrame.Visible
    end
    return widget
end

function ASTER.ApplyMobileWidgetSize(singleWidget)
    local sizeVal = math.clamp(tonumber(Settings.MobileMenuSize) or 5, 0, 10)
    local scale = 0.5 + (sizeVal / 10) * 1.0
    local function applyOne(widget)
        if not widget or widget.destroyed or not widget.frame then return end
        if not widget.uiScale then
            widget.uiScale = Instance.new("UIScale")
            widget.uiScale.Parent = widget.frame
        end
        widget.uiScale.Scale = scale
    end
    if singleWidget then
        applyOne(singleWidget)
        return
    end
    for _, widget in ipairs(ASTER.MobileWidgets or {}) do
        applyOne(widget)
    end
end

function ASTER.ApplyAllMobileWidgetThemes()
    for _, widget in ipairs(ASTER.MobileWidgets or {}) do
        if widget and widget.applyTheme then
            widget.applyTheme()
        end
    end
    ASTER.ApplyMobileWidgetSize()
end

function ASTER.GetMobileWidgetByGuiName(guiName)
    for _, widget in ipairs(ASTER.MobileWidgets or {}) do
        if widget and not widget.destroyed and widget.gui and widget.gui.Name == guiName then
            return widget
        end
    end
    return nil
end

function ASTER.SyncMobileWidgetsWithMainUI(mainUiVisible)
    for _, widget in ipairs(ASTER.MobileWidgets or {}) do
        if widget and not widget.destroyed and widget.gui then
            widget.gui.Enabled = mainUiVisible == true
        end
    end
end

function ASTER.DestroyAllMobileWidgets()
    local widgets = ASTER.MobileWidgets or {}
    for i = #widgets, 1, -1 do
        local widget = widgets[i]
        if widget and widget.destroy then
            widget.destroy()
        end
    end
    ASTER.MobileWidgets = {}
    if ASTER.ToggleBind then
        ASTER.ToggleBind.mobileGuis = {}
    end
end

function ToggleBind.getKeybindInputName(toggleName)
    return toggleName .. " Keybind"
end

function ToggleBind.getMobileToggleName(toggleName)
    return "Mobile " .. toggleName .. " Button"
end

function ToggleBind.getMobileSlot(toggleName)
    local sel = Settings.SelectedToggleMobileButtons or {}
    local slot = 0
    for _, name in ipairs(ToggleBind.getBindableToggles()) do
        if sel[name] then
            if name == toggleName then return slot end
            slot = slot + 1
        end
    end
    return slot
end

local TOGGLE_BIND_EXCLUDE = {
    ["Show Keybinds Overlay"] = true,
    ["Lock Mobile Buttons"] = true,
    ["Add Toggle Keybind"] = true,
    ["SelectToggleMobileButton"] = true,
    ["Add Mobile Toggle"] = true,
    ["Mobile Auto Heal Button"] = true,
    ["AutoChest Button"] = true,
    ["Mobile AutoHit Button"] = true,
    ["Mobile Auto Hut Button"] = true,
    ["Mobile Voodoo Button"] = true,
    ["Mobile Follow Button (Doesnt jump/turn)"] = true,
    ["Mobile Pinch Button"] = true,
    ["Mobile Auto Pickup Button"] = true,
}

local function isBindableToggle(name)
    if not name or TOGGLE_BIND_EXCLUDE[name] then return false end
    if string.sub(name, 1, 7) == "Mobile " and string.find(name, "Button", 1, true) then
        return false
    end
    if string.sub(name, -8) == " Keybind" then
        return false
    end
    local reg = Window and Window.ElementRegistry and Window.ElementRegistry[name]
    return reg and reg.Type == "Toggle"
end

function ToggleBind.getBindableToggles()
    local names = {}
    if not Window or not Window.ElementRegistry then return names end
    for name, reg in pairs(Window.ElementRegistry) do
        if reg.Type == "Toggle" and isBindableToggle(name) then
            table.insert(names, name)
        end
    end
    table.sort(names)
    return names
end

function ToggleBind.normalizeKey(input)
    if not input or input.UserInputType ~= Enum.UserInputType.Keyboard then return nil end
    local inputKeyName = input.KeyCode.Name
    if input.KeyCode.Value >= 48 and input.KeyCode.Value <= 57 then
        inputKeyName = string.char(input.KeyCode.Value)
    end
    local digitMap = {
        One = "1", Two = "2", Three = "3", Four = "4", Five = "5",
        Six = "6", Seven = "7", Eight = "8", Nine = "9", Zero = "0",
    }
    if digitMap[inputKeyName] then
        inputKeyName = digitMap[inputKeyName]
    end
    return string.upper(inputKeyName)
end

function ToggleBind.flipToggle(toggleName)
    local reg = Window and Window.ElementRegistry and Window.ElementRegistry[toggleName]
    if reg and reg.GetValue and reg.SetValue then
        reg.SetValue(not reg.GetValue())
        return true
    end
    return false
end

function ToggleBind.shortLabel(toggleName)
    local label = tostring(toggleName or "Toggle")
    if #label > 14 then
        return label:sub(1, 13) .. "."
    end
    return label
end

function ToggleBind.refreshMobileButton(toggleName)
    local widget = ToggleBind.mobileGuis[toggleName]
    if not widget or widget.destroyed then return end
    local reg = Window and Window.ElementRegistry and Window.ElementRegistry[toggleName]
    local isOn = reg and reg.GetValue and reg.GetValue() or false
    widget.setToggleState(isOn, ToggleBind.shortLabel(toggleName))
end

function ToggleBind.destroyMobileButton(toggleName)
    local widget = ToggleBind.mobileGuis[toggleName]
    if widget then
        widget.destroy()
        ToggleBind.mobileGuis[toggleName] = nil
    end
    local guiKey = "AsterToggleBtn_" .. toggleName:gsub("[^%w]", "")
    if Window and Window.MobileButtons then
        Window.MobileButtons[guiKey] = nil
    end
end

function ToggleBind.ensureMobileButton(toggleName, slotIndex)
    local existing = ToggleBind.mobileGuis[toggleName]
    if existing and not existing.destroyed then
        ToggleBind.refreshMobileButton(toggleName)
        return
    end
    pcall(function()
        local widget = ASTER.CreateMobileWidget({
            guiName = "AsterToggleBtn_" .. toggleName:gsub("[^%w]", ""),
            label = ToggleBind.shortLabel(toggleName),
            position = ASTER.mobileWidgetPosition(slotIndex or 0),
            mode = "toggle",
            onClick = function()
                ToggleBind.flipToggle(toggleName)
                ToggleBind.refreshMobileButton(toggleName)
            end,
        })
        ToggleBind.mobileGuis[toggleName] = widget
        ToggleBind.refreshMobileButton(toggleName)
    end)
end

function ToggleBind.copySelection(sel)
    local out = {}
    for k, v in pairs(sel or {}) do
        if v then out[k] = true end
    end
    return out
end

ToggleBind.keyCaptureRows = ToggleBind.keyCaptureRows or {}
ToggleBind.activeCapture = nil
ToggleBind.captureHooked = false
ToggleBind.builtinRowsCreated = false
ToggleBind.BUILTIN_BINDS = nil

function ToggleBind.refreshCaptureButton(btn, key)
    if not btn then return end
    local themeMain = (CurrentTheme and CurrentTheme.Main) or Color3.fromRGB(186, 140, 255)
    if key and key ~= "" then
        btn.Text = tostring(key)
        btn.TextColor3 = themeMain
        ApplyGradient(btn)
    else
        btn.Text = "Click to bind"
        btn.TextColor3 = UI.Surface.Muted
        local grad = btn:FindFirstChild("ThemeGradient")
        if grad then grad:Destroy() end
    end
end

function ToggleBind.ensureCaptureHook()
    if ToggleBind.captureHooked then return end
    ToggleBind.captureHooked = true
    trackConnection("keyCapture_InputBegan", game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
        local cap = ToggleBind.activeCapture
        if not cap then return end
        if gpe then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if input.KeyCode == Enum.KeyCode.Escape then
            ToggleBind.activeCapture = nil
            cap.refresh()
            return
        end
        if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
            cap.setKey(nil)
        else
            cap.setKey(ToggleBind.normalizeKey(input))
        end
        ToggleBind.activeCapture = nil
        cap.refresh()
        if ASTER.RefreshKeybindsOverlayRows then ASTER.RefreshKeybindsOverlayRows() end
    end))
end

function ToggleBind.createCaptureRow(parent, layoutOrder, id, labelText, getKey, setKey, opts)
    opts = opts or {}
    ToggleBind.ensureCaptureHook()
    local H = Window and Window.UIHelpers or {}
    local rowHeight = (H.controlRowHeight and H.controlRowHeight()) or 44
    local applyControlChrome = H.applyControlChrome
    local styleInputBackground = H.styleInputBackground
    local tweenProp = H.tweenProp

    local row = Instance.new("Frame")
    row.Name = "KeyCapture_" .. tostring(id):gsub("[^%w]", "")
    row.Size = UDim2.new(1, -2, 0, rowHeight)
    row.LayoutOrder = layoutOrder
    row.BorderSizePixel = 0
    row.Parent = parent
    if applyControlChrome then
        applyControlChrome(row)
    else
        row.BackgroundTransparency = 1
    end
    if Window and Window.AllElements then
        table.insert(Window.AllElements, row)
    end

    local nameLabel = Instance.new("TextLabel", row)
    nameLabel.Size = UDim2.new(1, -(opts.removable and 118 or 98), 1, 0)
    nameLabel.Position = UDim2.fromOffset(10, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = UISettings and UISettings.CompactMode and 14 or 15
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextYAlignment = Enum.TextYAlignment.Center
    nameLabel.TextWrapped = true
    nameLabel.Text = labelText
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    ApplyGradient(nameLabel)
    if Window and Window.TextElements then
        table.insert(Window.TextElements, nameLabel)
    end

    local keyBg = Instance.new("Frame", row)
    keyBg.Size = UDim2.fromOffset(86, 28)
    keyBg.AnchorPoint = Vector2.new(1, 0.5)
    keyBg.Position = UDim2.new(1, opts.removable and -22 or -2, 0.5, 0)
    if styleInputBackground then
        styleInputBackground(keyBg)
    end
    if Window and Window.AllElements then
        table.insert(Window.AllElements, keyBg)
    end

    if applyControlChrome and tweenProp then
        row.MouseEnter:Connect(function()
            if row:GetAttribute("PremiumChrome") then
                tweenProp(row, { BackgroundColor3 = UI.Surface.ControlHover }, UI.Ease.Fast)
            end
        end)
        row.MouseLeave:Connect(function()
            if row:GetAttribute("PremiumChrome") then
                tweenProp(row, { BackgroundColor3 = UI.Surface.Control }, UI.Ease.Fast)
            end
        end)
    end

    local keyBtn = Instance.new("TextButton", keyBg)
    keyBtn.Size = UDim2.new(1, -4, 1, -4)
    keyBtn.Position = UDim2.fromOffset(2, 2)
    keyBtn.BackgroundTransparency = 1
    keyBtn.BorderSizePixel = 0
    keyBtn.AutoButtonColor = false
    keyBtn.Font = Enum.Font.SourceSansBold
    keyBtn.TextSize = 13
    keyBtn.TextTruncate = Enum.TextTruncate.AtEnd

    local function refresh()
        ToggleBind.refreshCaptureButton(keyBtn, getKey())
    end
    refresh()

    keyBtn.MouseButton1Click:Connect(function()
        ToggleBind.activeCapture = { setKey = setKey, refresh = refresh }
        keyBtn.Text = "Press key..."
        keyBtn.TextColor3 = (CurrentTheme and CurrentTheme.Main) or UI.Surface.Text
    end)

    if opts.removable and opts.toggleName then
        local removeBtn = Instance.new("TextButton", row)
        removeBtn.Size = UDim2.fromOffset(18, 18)
        removeBtn.AnchorPoint = Vector2.new(1, 0.5)
        removeBtn.Position = UDim2.new(1, -2, 0.5, 0)
        removeBtn.BackgroundTransparency = 1
        removeBtn.BorderSizePixel = 0
        removeBtn.AutoButtonColor = false
        removeBtn.Font = UI.FontTitle
        removeBtn.TextSize = 12
        removeBtn.Text = "x"
        removeBtn.TextColor3 = UI.Surface.Muted
        removeBtn.MouseButton1Click:Connect(function()
            Settings.SelectedToggleKeybinds = Settings.SelectedToggleKeybinds or {}
            Settings.SelectedToggleKeybinds[opts.toggleName] = nil
            if Settings.ToggleKeybinds then Settings.ToggleKeybinds[opts.toggleName] = nil end
            ToggleBind.keybindInputsCreated[opts.toggleName] = nil
            row:Destroy()
            ToggleBind.refreshAddKeybindDropdown()
            if ASTER.RefreshKeybindsOverlayRows then ASTER.RefreshKeybindsOverlayRows() end
        end)
    end

    ToggleBind.keyCaptureRows[id] = { row = row, label = nameLabel, refresh = refresh }
    return row
end

function ToggleBind.clearKeybindByName(name)
    if not name or name == "" then return end
    ToggleBind.ensureBuiltinBinds()
    for _, bind in ipairs(ToggleBind.BUILTIN_BINDS or {}) do
        if bind.id == name and bind.set then
            bind.set(nil)
        end
    end
    if Settings.ToggleKeybinds then
        Settings.ToggleKeybinds[name] = nil
    end
    local cap = ToggleBind.keyCaptureRows[name] or ToggleBind.keyCaptureRows["toggle_" .. name]
    if cap and cap.refresh then
        cap.refresh()
    end
    if Settings.KeybindOverlaySelection then
        Settings.KeybindOverlaySelection[name] = nil
    end
    if ASTER.RefreshKeybindsOverlayRows then
        ASTER.RefreshKeybindsOverlayRows()
    end
end

function ToggleBind.getAvailableToggleKeybindOptions()
    local opts = { "None" }
    local selected = Settings.SelectedToggleKeybinds or {}
    for _, name in ipairs(ToggleBind.getBindableToggles()) do
        if not selected[name] then
            table.insert(opts, name)
        end
    end
    return opts
end

function ToggleBind.refreshAddKeybindDropdown()
    local reg = Window and Window.ElementRegistry and Window.ElementRegistry["Add Toggle Keybind"]
    if reg and reg.SetValues then
        reg.SetValues(ToggleBind.getAvailableToggleKeybindOptions())
    end
end

function ToggleBind.rebuildToggleKeybindRows()
    if not ToggleBind.dynamicHost then return end
    ToggleBind.dynamicHost:ClearAllChildren()
    local layout = Instance.new("UIListLayout", ToggleBind.dynamicHost)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)

    local order = 0
    for _, name in ipairs(ToggleBind.getBindableToggles()) do
        if Settings.SelectedToggleKeybinds and Settings.SelectedToggleKeybinds[name] then
            order = order + 1
            ToggleBind.createCaptureRow(
                ToggleBind.dynamicHost,
                order,
                "toggle_" .. name,
                name,
                function() return Settings.ToggleKeybinds and Settings.ToggleKeybinds[name] end,
                function(k)
                    Settings.ToggleKeybinds = Settings.ToggleKeybinds or {}
                    Settings.ToggleKeybinds[name] = k
                end,
                { removable = true, toggleName = name }
            )
        end
    end
end

function ToggleBind.initKeybindManager()
    ToggleBind.ensureBuiltinBinds()
    local section = Window and Window.SectionAnchors and Window.SectionAnchors["Keybind Manager"]
    if not section then return end

    local bindOrder = tonumber(section:GetAttribute("DynLayoutOrder")) or 0
    bindOrder = bindOrder + 1

    if not ToggleBind.managerHost then
        ToggleBind.managerHost = Instance.new("Frame")
        ToggleBind.managerHost.Name = "KeybindManagerHost"
        ToggleBind.managerHost.Size = UDim2.new(1, 0, 0, 0)
        ToggleBind.managerHost.AutomaticSize = Enum.AutomaticSize.Y
        ToggleBind.managerHost.BackgroundTransparency = 1
        ToggleBind.managerHost.LayoutOrder = bindOrder
        ToggleBind.managerHost.Parent = section
        local list = Instance.new("UIListLayout", ToggleBind.managerHost)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 4)
    else
        ToggleBind.managerHost.LayoutOrder = bindOrder
    end
    section:SetAttribute("DynLayoutOrder", bindOrder)

    if not ToggleBind.builtinHost then
        ToggleBind.builtinHost = Instance.new("Frame")
        ToggleBind.builtinHost.Name = "BuiltinKeybindHost"
        ToggleBind.builtinHost.Size = UDim2.new(1, 0, 0, 0)
        ToggleBind.builtinHost.AutomaticSize = Enum.AutomaticSize.Y
        ToggleBind.builtinHost.BackgroundTransparency = 1
        ToggleBind.builtinHost.LayoutOrder = 1
        ToggleBind.builtinHost.Parent = ToggleBind.managerHost
        local list = Instance.new("UIListLayout", ToggleBind.builtinHost)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 4)
    end

    if not ToggleBind.dynamicHost then
        ToggleBind.dynamicHost = Instance.new("Frame")
        ToggleBind.dynamicHost.Name = "DynamicKeybindHost"
        ToggleBind.dynamicHost.Size = UDim2.new(1, 0, 0, 0)
        ToggleBind.dynamicHost.AutomaticSize = Enum.AutomaticSize.Y
        ToggleBind.dynamicHost.BackgroundTransparency = 1
        ToggleBind.dynamicHost.LayoutOrder = 2
        ToggleBind.dynamicHost.Parent = ToggleBind.managerHost
    end

    if not ToggleBind.builtinRowsCreated then
        ToggleBind.builtinRowsCreated = true
        local order = 0
        for _, bind in ipairs(ToggleBind.BUILTIN_BINDS) do
            order = order + 1
            ToggleBind.createCaptureRow(ToggleBind.builtinHost, order, bind.id, bind.label, bind.get, bind.set)
        end
    end

    ToggleBind.rebuildToggleKeybindRows()
    ToggleBind.refreshAddKeybindDropdown()
end

function ToggleBind.addToggleKeybind(toggleName)
    if not toggleName or toggleName == "None" then return end
    Settings.SelectedToggleKeybinds = Settings.SelectedToggleKeybinds or {}
    Settings.SelectedToggleKeybinds[toggleName] = true
    ToggleBind.keybindInputsCreated[toggleName] = true
    ToggleBind.rebuildToggleKeybindRows()
    ToggleBind.refreshAddKeybindDropdown()
end

function ToggleBind.syncKeybindBindings(sel)
    Settings.SelectedToggleKeybinds = ToggleBind.copySelection(sel)
    for name in pairs(ToggleBind.keybindInputsCreated) do
        if not sel[name] and Settings.ToggleKeybinds then
            Settings.ToggleKeybinds[name] = nil
        end
    end
    ToggleBind.rebuildToggleKeybindRows()
    ToggleBind.refreshAddKeybindDropdown()
end

function ToggleBind.syncMobileButtons(sel)
    Settings.SelectedToggleMobileButtons = ToggleBind.copySelection(sel)
    local combatTab = ASTER.Tabs and ASTER.Tabs.Combat

    for name in pairs(ToggleBind.mobileTogglesCreated) do
        if not sel[name] then
            local mobName = ToggleBind.getMobileToggleName(name)
            local reg = Window and Window.ElementRegistry and Window.ElementRegistry[mobName]
            if reg and reg.SetVisible then reg.SetVisible(false) end
            ToggleBind.destroyMobileButton(name)
            Settings.CustomMobileToggleEnabled = Settings.CustomMobileToggleEnabled or {}
            Settings.CustomMobileToggleEnabled[name] = false
        end
    end

    for name, on in pairs(sel) do
        if on then
            local mobName = ToggleBind.getMobileToggleName(name)
            if not ToggleBind.mobileTogglesCreated[name] then
                ToggleBind.mobileTogglesCreated[name] = true
                TOGGLE_BIND_EXCLUDE[mobName] = true
                local defaultOn = Settings.CustomMobileToggleEnabled and Settings.CustomMobileToggleEnabled[name] == true
                local function onMobileToggle(v)
                    Settings.CustomMobileToggleEnabled = Settings.CustomMobileToggleEnabled or {}
                    Settings.CustomMobileToggleEnabled[name] = v
                    if v then
                        ToggleBind.ensureMobileButton(name, ToggleBind.getMobileSlot(name))
                    else
                        ToggleBind.destroyMobileButton(name)
                    end
                end
                if combatTab then
                    if combatTab.AddToggleInSection then
                        combatTab:AddToggleInSection("Mobile Buttons", mobName, defaultOn, onMobileToggle)
                    else
                        combatTab:AddToggle(mobName, defaultOn, onMobileToggle)
                    end
                end
                if defaultOn then
                    ToggleBind.ensureMobileButton(name, ToggleBind.getMobileSlot(name))
                end
            else
                local reg = Window and Window.ElementRegistry and Window.ElementRegistry[mobName]
                if reg and reg.SetVisible then reg.SetVisible(true) end
                if Settings.CustomMobileToggleEnabled and Settings.CustomMobileToggleEnabled[name] then
                    ToggleBind.ensureMobileButton(name, ToggleBind.getMobileSlot(name))
                end
            end
        end
    end

    local mobReg = Window and Window.ElementRegistry and (Window.ElementRegistry["Add Mobile Toggle"] or Window.ElementRegistry["SelectToggleMobileButton"])
    if mobReg and mobReg.SetValues then
        mobReg.SetValues(ToggleBind.getBindableToggles())
    end
end

function ToggleBind.finishInit()
    ToggleBind.hookInput()
    if not Window or not Window.ElementRegistry then return end
    local options = ToggleBind.getBindableToggles()
    local mobReg = Window.ElementRegistry["Add Mobile Toggle"] or Window.ElementRegistry["SelectToggleMobileButton"]
    if mobReg and mobReg.SetValues then mobReg.SetValues(options) end
    ToggleBind.initKeybindManager()
    ToggleBind.refreshAddKeybindDropdown()

    local kbSel = {}
    if type(Settings.SelectedToggleKeybinds) == "table" then
        for k, v in pairs(Settings.SelectedToggleKeybinds) do
            if v then kbSel[k] = true end
        end
    end
    -- Legacy config: migrate old multi-dropdown saves
    local legacyKbReg = Window.ElementRegistry["SelectToggleToKeyBind"]
    if legacyKbReg and legacyKbReg.GetValue then
        for name, on in pairs(legacyKbReg.GetValue()) do
            if on then kbSel[name] = true end
        end
    end
    Settings.SelectedToggleKeybinds = kbSel
    ToggleBind.syncKeybindBindings(kbSel)

    local mobSel = {}
    if type(Settings.SelectedToggleMobileButtons) == "table" then
        for k, v in pairs(Settings.SelectedToggleMobileButtons) do
            if v then mobSel[k] = true end
        end
    end
    if mobReg and mobReg.SetValue and next(mobSel) then
        mobReg.SetValue(mobSel)
    else
        ToggleBind.syncMobileButtons(mobSel)
    end
end

function ToggleBind.hookInput()
    if ToggleBind.inputHooked then return end
    ToggleBind.inputHooked = true
    trackConnection("toggleBind_InputBegan", game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local key = ToggleBind.normalizeKey(input)
        if not key then return end
        for toggleName, bindKey in pairs(Settings.ToggleKeybinds or {}) do
            if bindKey and bindKey ~= "" and string.upper(tostring(bindKey)) == key then
                ToggleBind.flipToggle(toggleName)
                ToggleBind.refreshMobileButton(toggleName)
                break
            end
        end
    end))
end

function ASTER:Notify(config) end
local loadingSteps = {
    "Initializing services...",
    "Loading logic engine...",
    "Setting up configurations...",
    "Creating interface...",
    "Finalizing..."
}
local currentStep = 1
function updateLoadingStep(msg)
    if msg then
    else
        local stepMsg = loadingSteps[currentStep]
        if stepMsg then

        end
    end
    currentStep = currentStep + 1
end
updateLoadingStep() 
-- Initial step
-- // LOGIC ENGINES (Ported from GoldFarming UG) // --

function NukeGraphics()
    task.spawn(function()
        local smoothPlastic = Enum.Material.SmoothPlastic
        local lighting = game:GetService("Lighting")
        local terrain = workspace.Terrain
        
        pcall(function()
            lighting.GlobalShadows = false
            lighting.FogEnd = 9e9
            lighting.Brightness = 0
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            
            for _, v in pairs(lighting:GetChildren()) do
                pcall(function()
                    if v:IsA("PostEffect") then
                        v.Enabled = false
                    elseif v:IsA("Sky") or v:IsA("Atmosphere") then
                        v:Destroy()
                    end
                end)
            end
            
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 0
        end)

        local items = workspace:GetDescendants()
        local clock = os.clock
        local wait = task.wait
        local lastYield = clock()
        
        for i, v in ipairs(items) do
            if i % 100 == 0 then 
                if clock() - lastYield > 0.015 then
                    wait()
                    lastYield = clock()
                end
            end
            
            if v:IsA("BasePart") then
                pcall(function()
                    if v.Parent and not v.Parent:FindFirstChild("Humanoid") then
                        v.Material = smoothPlastic
                        v.Reflectance = 0
                        v.CastShadow = false
                    end
                end)
            elseif v:IsA("Decal") or v:IsA("Texture") then
                pcall(function() v.Transparency = 1 end)
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                pcall(function() v.Enabled = false end)
            elseif v.Name == "Rain" or v.Name == "RainEmitter" then
                pcall(function() v.Enabled = false end)
            end
        end
    end)
end

rs = ReplicatedStorage
char = plr.Character
root = char and char:FindFirstChild("HumanoidRootPart")
hum = char and char:FindFirstChild("Humanoid")
runs = game:GetService("RunService")
httpservice = game:GetService("HttpService")

updateLoadingStep()
originalCollision = originalCollision or {}
function captureCollisionState()
    originalCollision = {}
    if plr.Character then
        for _, part in pairs(plr.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                originalCollision[part] = part.CanCollide
            end
        end
    end
end

function resetCharacterPhysics()
    local character = plr.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local cbv = hrp:FindFirstChild("CircuitBodyVelocity")
        if cbv then cbv:Destroy() end
        local pbg = hrp:FindFirstChild("CircuitBodyGyro")
        if pbg then pbg:Destroy() end
        local pbv = hrp:FindFirstChild("PlantBodyVelocity")
        if pbv then pbv:Destroy() end
        local pgy = hrp:FindFirstChild("PlantBodyGyro")
        if pgy then pgy:Destroy() end
        hrp.Velocity = Vector3.new(0,0,0)
        hrp.RotVelocity = Vector3.new(0,0,0)
    end
end

if char then
    resetCharacterPhysics()
    captureCollisionState()
end
end -- AsterPostUI
do -- AsterGameCore
craftItemIDs = craftItemIDs or {}

craftNameToID = craftNameToID or {}


do
    local itemIdModuleObj = ReplicatedStorage:FindFirstChild("Modules")
        and ReplicatedStorage.Modules:FindFirstChild("ItemIDS")

    local ok, ItemIDSModule = pcall(function()
        if itemIdModuleObj then
            return require(itemIdModuleObj)
        end
        return require(ReplicatedStorage:WaitForChild("Modules", 2):WaitForChild("ItemIDS", 2))
    end)

    if not ok or type(ItemIDSModule) ~= "table" then
        ItemIDSModule = {}
    end

    local isNameToID = false
    for k, v in pairs(ItemIDSModule) do
        if type(k) == "string" and type(v) == "number" then
            isNameToID = true
            break
        end
    end

    if isNameToID then
        for name, id in pairs(ItemIDSModule) do
            craftNameToID[name] = id
            craftItemIDs[id] = name
        end
    else
        for id, name in pairs(ItemIDSModule) do
            craftItemIDs[id] = name
            craftNameToID[name] = id
        end
    end
end


Settings = {
    -- Keybind
    Keybind = nil,
    TargetMode = "Auto Target Mode",
    
    -- AutoChest (automation)
    AutoChestEnabled = false,
    AutoChestFallThreshold = 0.6,
    AutoChestPredictionTime = 0.2,
    AutoChestPlaceCooldown = 0.02,
    AutoChestJumpPrediction = false,
    AutoChestForwardOffset = 0,
    AutoChestSelectedChest = "Chest", -- default; option: "Reinforced Chest"
    AutoChestKey = nil,
    ShowKeybindsOverlay = false,
    OverlayMenuSize = 5,
    MobileMenuSize = 5,
    KeybindOverlaySelection = {},
    ToggleKeybinds = {},
    SelectedToggleKeybinds = {},
    SelectedToggleMobileButtons = {},
    CustomMobileToggleEnabled = {},
    -- Gold Farm
    LockMobileButtons = false, -- Mobile UI Lock
    GoldCircuitEnabled = false,
    GoldAutoEquip = false, -- New Setting
    GoldHoeType = "Wood Hoe", -- New Setting
    recordedPositions = {},
    recordingPath = false,
    recordInterval = 1.0,
    GoldNoclip = false,
    OpenSkinCrate = false,
    AutoSkipCrate = false,
    GoldVisual = false,
    GoldSpeed = 20.9,
    GoldDelay = 0.25,
    MaxSlopeEnabled = false,
    SpectatePlayersEnabled = false,
    WaterTweenEnabled = false,
    
    -- Quick Hut
    QuickHutHutOption = "Big Ol' Hut",

    -- Visuals
    WanderingTraderESPEnabled = false,
    MeteorCoreESPEnabled = false,
    GodBossESPEnabled = false,
    SelectedGodBosses = {},
    PlayerESPEnabled = false,
    HideTeams = false,
    ESPColors = {
        ["PlayerESP"] = Color3.fromRGB(255, 0, 255),
        ["GodESP"] = Color3.fromRGB(255, 255, 0),
        ["Wandering Trader ESP"] = Color3.fromRGB(255, 200, 0),
        ["Big Chests"] = Color3.fromRGB(255, 255, 255),
        ["Meteor Core ESP"] = Color3.fromRGB(170, 85, 255),
        ["God Boss ESP"] = Color3.fromRGB(255, 0, 0),
        ["Critter ESP"] = Color3.fromRGB(255, 150, 50),
        ["Item ESP"] = Color3.fromRGB(0, 255, 140)
    },
    ESPOptionDistances = {
        ["AllOptions"] = 500,
        ["Show Names"] = 500,
        ["Show Distance"] = 500,
        ["Show PlayersHealth"] = 500,
        ["Show Highlight"] = 500,
        ["Show Hitbox"] = 500,
        ["Use Team Color"] = 500,
        ["GodPlayer Esp"] = 500,
        ["GodArmor Pieces"] = 500,
    },
    
    -- Configs
    SelectedConfig = "None",
    ConfigName = "",

    -- Potato Mode
    PotatoMode = false,
    StaffDetectionsEnabled = false,
    LeaveOnStaff = false,
    RecordingMode = false,
    BlackScreenMode = false,
    ZoomDistance = 100,
    
    -- Visuals (Theme)
    CurrentThemeName = "Starfield",
    
    -- Resource Aura
    ResourceAuraEnabled = false,
    StructureAuraEnabled = false,
    TurnOnAura = false,
    AuraLegitSwing = false,
    AuraTypeSelection = {},
    ResourceType = "AllResource",
    StructureType = "AllStructure",
    ResourceRange = 20,
    ResourceTargetCount = 2,
    ResourceCooldown = 0.03,
    ResourceSwingPackedMultiHit = false,
    GoldNodeAuraEnabled = false,
    IceAuraEnabled = false,
    
    -- Crystal Guardian Farm
    CrystalGuardianSpeed = 17,

    -- Auto Heal (Optimized)
    AutoHealEnabled = false,
    QuickHealEnabled = true, -- Default ON if AutoHeal is active
    HealCPS = 80, 
    HealHeartbeat = false,
    SmartHealEnabled = false,
    HealBurstDuration = 1.2,
    HealDoubleHitWindow = 0.65,
    HealThreshold = 99,
    HealFruit = "Bloodfruit",
    AutoHealType = "AutoHeal",
    AutoEatEnabled = false,
    EatThreshold = 99,
    EatFruit = "Bloodfruit",
    WasteFruit = "Bloodfruit",
    FruitsCapAmount = 100,
    WasteFruitsEnabled = false,
    EatCap = 100,
    EatCapEnabled = false,
    -- KillAura & Combat: multi-select for "Auto Craft & Equip" (must be a table)
    SelectedCraftEquipItems = {},
    AutoCraftEquipEnabled = false,

    -- Auto armor set switch (low-health backup set)
    AutoSwitchSetsEnabled = false,
    AutoSwitchBack = false,
    SelectedSwitchSet = "",
    SelectSwitchHealth = 30,
    
    -- Pickup & Drop
    AutoPickupEnabled = false,
    ChestPickupEnabled = false,
    CustomPickupFilter = "",
    FilterModeOn = false,
    AutoDropEnabled = false,
    DropItem = "",
    DropAmount = "Infinite",
    PickupBatchSize = 150,
    PickupRange = 50,
    PickupDelay = 0.01,
    PickupPerTick = 20,
    PickupRetryDelay = 0.15,
    PickupLoopDelay = 0.045,

    -- Auto Fish
    AutoFishEnabled = false,
    FishDistance = 10,
    AutoSaddleEnabled = false,

    -- Campfire Fuel
    AutoFuelEnabled = false,
    FuelType = "All (Wood/Log/Leaves)",
    FuelThreshold = 200,

    -- Chests
    BigChests = false,
    ShowChestDistance = false,
    TeleportGoldToChest = false,
    TeleportEssenceToChest = false,
    
    -- Plant & Harvest
    PlantEnabled = false,
    PlantRange = 20,
    PlantDelay = 0.01,
    PlantFruit = { Bloodfruit = true },
    HarvestEnabled = false,
    HarvestRange = 30,
    TweenToPlantBox = false,
    TweenToBush = false,
    TweenToBushAndBox = false,
    PlantingTweenMode = "SmoothWalk",
    PlantingTweenSpeed = 19,
    TweenRange = 500,
    FarmingTweenSpeed = 20,
    CacheAmount = 20,
    CacheTimer = 3,
    CachePlantBoxes = false,
    CacheWalk = false,
    -- Cache tuning (higher = more aggressive/faster, but heavier)
    CacheScanMultiplier = 1.75, -- scan radius = PlantRange * this (clamped)
    CacheScanMaxRange = 120, -- absolute cap for cache scan radius
    CacheMoveRefreshMin = 2, -- studs moved to force refresh (minimum)
    CacheMoveRefreshFactor = 0.1, -- studs moved to force refresh (PlantRange * this)
    
    -- Placement
    AutoPlaceMaster = false,
    PlantMode = "MultiPlantBoxPlacement",
    MultiplyPlantBox = false,
    LegitNormalPlantBox = false,
    SoloPatternPlantBoxes = false,
    PlantBoxRotation = 0,
    PlantBoxSpacingX = 5.1,
    PlantBoxSpacingZ = 5.1,
    AutoPlaceUnderMeWalking = false,
    PlaceWalkingDelay = 0.1,
    PlaceWalkingSpacing = 7,

    -- Custom Building / Placement
    SelectedPlacementType = "",
    ShowPlacementPreview = false,
    ShowCollisionPart = false,
    PreviewSnap = false, 
    PreviewPresetSave = false,
    PreviewCenter = false,
    LockPreviewPreset = false,
    PreviewPlacement = false,
    LockPreviewPlacements = false,
    StartPlacement = false,
    TweenPlacement = false,
    AutoStartPlacement = false,
    PlacementSpeed = 16,
    PlacementOffsetX = 0,
    PlacementOffsetY = 0,
    PlacementOffsetZ = 0,
    PlacementSpacingX = 13,
    PlacementSpacingZ = 13,
    PlacementAmount = 9,
    PlacementAmountX = 3,
    PlacementAmountY = 3,
    SelectPlacementLocations = false,
    FillLocations = false,
    LockLocations = false,

    -- Item Deletion
    ItemDeletionEnabled = false,
    ItemDeletion = "",

    -- Auto Rebirth & Spawn
    AutoRebirthEnabled = false,
    RebirthLevel = 101,
    AutoRespawnEnabled = false,

    -- Critter Aura
    CritterAuraEnabled = false,
    CritterRange = 20,
    CritterTargetCount = 3,
    BehindQueenAnt = false,
    BehindQueenAntStuds = 3,
    CritterCooldown = 0.08,
    CritterSwingPackedMultiHit = true,
    CritterType = "All",

    
    -- Critter ESP
    CritterESPEnabled = false,
    SelectedCritters = {},

    -- Auto Hit (integrated with PlayerReach)
    AutoHitStartEnabled = false,
    FaceEnemyEnabled = false,
    PlayerReachEnabled = false,
    PlayerReachRange = 8,
    PlayerReachVisualEnabled = false,
    PlayerTargetCount = 3,
    AutoHitCooldown = 0.05,
    MobileAutoHitButton = false,
    MobileAutoHealButton = false,
    MobileAutoChestButton = false,
    PlayerSwingPackedMultiHit = true,

    -- Bow Silent Aim
    SilentAimbot = false,
    SilentAimLeadMult = 1.0,
    SilentAimFlatCap = 4,
    SilentAimHighArcCap = 1.5,
    SilentAimTargetPart = "HumanoidRootPart",
    AutoShoot = false,
    AutoShootCritter = false,
    SelectedBowCritters = {},
    ShowFOVCircle = false,
    HitboxFOVSize = 120,
    MoveFOV = false,
    SelectedBowTool = "All",
    HitboxEnabled = false,
    HitboxBowOnly = false,
    HitboxSize = 7,
    HitboxVisuals = false,

    -- Auto Trace (follow enemy within range when at/below selected health)
    AutoTraceEnabled = false,
    AutoTraceHealth = 10,
    TraceRange = 8,

    -- Sand Farmer
    AutoSandEnabled = false,
    SandFarmSpeed = 0.4,
    SandHeight = 1,
    SandAmount = 1,
    SandFarmDigCount = 0,
    SandFarmSpot = nil,
    SandFarmAllowBreak = false,
    SandFarmPhase = "dig",


    -- PathFinder
    PathFinderEnabled = false,
    PathFinderItem = "Iron Node",
    PathFinderSpeed = 18,

    -- Potions
    SelectedPotion = "Swiftness Potion",
    PotionCraftItemID = nil,
    AutoCraftPotionEnabled = false,
    PotionCraftDelay = 0.5,
    PotionRange = 15,

    -- Automation
    CoinPresserEnabled = false,
    MultiCoinPresserEnabled = false,
    AutoCraftEnabled = false,
    CraftItemName = "",
    CraftItemID = nil,
    CraftDelay = 0.5,
    FarmingSelectedItem = "Adurite",
    FarmingAmount = 1,


    WanderingTraderESPEnabled = false,
    
    -- Configs
    recordInterval = 1.0,
    TWEEN_DURATION_PER_STUD = 0.09,
    maxWalkAttemptTime = 2,
    WalkSpeedEnabled = false,
    WalkSpeed = 16,
    HipHeightEnabled = false,
    HipHeight = 2,
    JumpBoostEnabled = false,
    JumpBoost = 50,
    ChestSlots = {},
    
    OreESPEnabled = false,
    SelectedOres = {},

    ItemESPEnabled = false,
    ItemESPQuery = "",

    -- Gold Circuit Defaults
    GoldNoclip = false,
    GoldCircuitEnabled = false,
    GoldVisual = false,
    GoldDelay = 0.25,
    WaterTweenEnabled = false,
    recordedPositions = {},
    GoldSpeed = 21,
    FarmingTweenSpeed = 20
}

-- [ Pinch Logic ] --

ConfigPinch = ConfigPinch or {
    Enabled = false,
    TargetPlayer = nil,
    TargetName = "",
    ItemName = "Crystal Gate",
    StructureID = nil,
    X_Offset = 1.60,
    Z_Offset = 0,
    Shift_X = 0,
    Shift_Z = -11.70,
    Y_Offset = -3.5,
    FixedRotation = 90,
    PredictTime = 1,
    RePinchDelay = 0.35,
    LastTrap = 0,
    TrapCF1 = nil,
    TrapCF2 = nil,
    Keybind = nil
}

function ToggleBind.ensureBuiltinBinds()
    if ToggleBind.BUILTIN_BINDS then return end
    ASTER.Options = ASTER.Options or {}
    ASTER.Options.VoodooSpell = ASTER.Options.VoodooSpell or {}
    ToggleBind.BUILTIN_BINDS = {
        { id = "AutoHit", label = "AutoHit", get = function() return Settings.AutoHitKey end, set = function(k) Settings.AutoHitKey = k end },
        { id = "Auto Heal", label = "Auto Heal", get = function() return Settings.QuickHealKey end, set = function(k) Settings.QuickHealKey = k end },
        { id = "Chest", label = "Chest", get = function() return Settings.AutoChestKey end, set = function(k) Settings.AutoChestKey = k end },
        { id = "Pinch", label = "Pinch", get = function() return ConfigPinch and ConfigPinch.Keybind end, set = function(k)
            if ConfigPinch then ConfigPinch.Keybind = k end
        end },
        { id = "Quick Hut", label = "Quick Hut", get = function() return Settings.QuickHutKey end, set = function(k) Settings.QuickHutKey = k end },
        { id = "Follow", label = "Follow", get = function() return Settings.FollowKey end, set = function(k) Settings.FollowKey = k end },
        { id = "Voodoo", label = "Voodoo", get = function() return ASTER.Options.VoodooSpell.Keybind end, set = function(k)
            ASTER.Options.VoodooSpell.Keybind = k
        end },
    }
end

-- Store gate-specific offsets so they change dynamically when selecting a new gate

function scanInventoryForItemID(itemName)
    local mainGui = plr.PlayerGui:FindFirstChild("MainGui")
    if not mainGui then return nil end
    local rightPanel = mainGui:FindFirstChild("RightPanel")
    if not rightPanel then return nil end
    local invFrame = rightPanel:FindFirstChild("Inventory")
    if not invFrame then return nil end
    local inventory = invFrame:FindFirstChild("List")
    if not inventory then return nil end
    for _, item in ipairs(inventory:GetChildren()) do
        if item:IsA("ImageLabel") and item.Name == itemName then
            local itemID = item:GetAttribute("ItemID") or item:GetAttribute("itemID")
            if not itemID then
                for _, child in ipairs(item:GetChildren()) do
                    if child:IsA("IntValue") or child:IsA("NumberValue") then
                        itemID = child.Value
                        break
                    end
                end
            end
            return itemID
        end
    end
    return nil
end


function scanCraftMenuForItemID(itemName)
    local mainGui = plr.PlayerGui:FindFirstChild("MainGui")
    if not mainGui then return nil end
    local leftPanel = mainGui:FindFirstChild("LeftPanel")
    local craftMenuPaths = {
        mainGui:FindFirstChild("CraftingMenu"),
        mainGui:FindFirstChild("Crafting"),
        mainGui:FindFirstChild("Craft"),
        leftPanel and leftPanel:FindFirstChild("Crafting") or nil,
    }
    for _, menu in ipairs(craftMenuPaths) do
        if menu then
            for _, item in ipairs(menu:GetDescendants()) do
                if item:IsA("TextLabel") or item:IsA("TextButton") then
                    if item.Text == itemName or item.Name == itemName then
                        local parent = item.Parent
                        local itemID = parent and (parent:GetAttribute("ItemID") or parent:GetAttribute("itemID") or parent:GetAttribute("ID")) or nil
                        if itemID then return itemID end
                    end
                end
            end
        end
    end
    return nil
end

-- `autoDiscoverItemID` is defined once near the top of the script.
-- Luau removes table keys whose value is nil. A startup-only table literal like
-- { ["Bloodfruit"] = autoDiscoverItemID("Bloodfruit") } can end up empty if every
-- discovery returns nil (UI/ItemIDS not ready yet), which makes the Heal Fruit
-- dropdown list blank. Build from explicit names so keys always exist; resolve IDs later.

ALL_HEAL_FRUIT_NAMES = ALL_HEAL_FRUIT_NAMES or {
    "Apple", "Banana", "Barley", "Berry", "Bloodfruit", "Bluefruit", "Blossom",
    "Carrot", "Cloudberry", "Coconut", "Corn", "Cooked Meat", "Frostfruit",
    "Jelly", "Lemon", "Mango", "Oddberry", "Orange", "Prickly Pear", "Pumpkin",
    "Strangefruit", "Strawberry", "Sunfruit", "Watermelon",
}


fruittoitemid = {}

for _, fruitName in ipairs(ALL_HEAL_FRUIT_NAMES) do
    local id = autoDiscoverItemID(fruitName)
    if id == nil and craftNameToID then
        id = craftNameToID[fruitName]
    end
    fruittoitemid[fruitName] = (id ~= nil) and id or false
end
-- Dynamic ID Update

if craftNameToID then
    for name, _ in pairs(fruittoitemid) do
        if craftNameToID[name] then
            fruittoitemid[name] = craftNameToID[name]
        end
    end
end


do
    local _fuelMap = {
        ["Wood"] = autoDiscoverItemID("Wood"),
        ["Log"] = autoDiscoverItemID("Log"),
        ["Leaves"] = autoDiscoverItemID("Leaves"),
        ["Coal"] = autoDiscoverItemID("Coal"),
    }

    -- Ensure all expected global spellings point to the same table.
    -- This prevents nil lookups if some parts of the script use a different identifier.
    getAsterEnv()["fueltoitemid"] = _fuelMap
    fueltoitemid = _fuelMap
    fueltoitemid = _fuelMap

    if craftNameToID then
        for name, _ in pairs(_fuelMap) do
            if craftNameToID[name] then
                _fuelMap[name] = craftNameToID[name]
            end
        end
    end
end

healFruitData = fruittoitemid

TweenService = game:GetService("TweenService")

function onCharacterAdded(newChar)
    char = newChar
    root = char:WaitForChild("HumanoidRootPart")
    hum = char:WaitForChild("Humanoid")
    if hum then hum.MaxSlopeAngle = Settings.MaxSlopeEnabled and 89 or 50 end
    captureCollisionState()
    if Settings.AutoHealEnabled then
        bindSmartHealHealthWatch(newChar)
    end
    if type(getAsterEnv().AsterRestorePlayerReach) == "function" then
        pcall(getAsterEnv().AsterRestorePlayerReach)
    end
end

plr.CharacterAdded:Connect(onCharacterAdded)


function getCritterNames()
    return getWorkspaceCritterNameList({ includeAll = true })
end


function getToolSlot(name)
    local toolbar = require(rs.Modules.GameUtil).Data.toolbar
    if not toolbar then return nil end
    for i=1,6 do if toolbar[i] and toolbar[i].name == name then return i end end
    return nil
end


-- SwingTool (captured): u8 0, u8 actionId, 18-byte CFrame, u16 LE hitCount,
-- hitCount * (u8 0 + u32 LE eid), f64 timestamp.

local function trackWebhookResourceBreaks(batch)
    local ws = __ASTER_RUNTIME.webhookStats
    if not ws then return end
    ws.broken = ws.broken or {}
    local eidNames = __ASTER_RUNTIME.webhookResourceEids
    for _, t in ipairs(batch) do
        local name = t.resourceName
        if not name and t.eid and eidNames then
            name = eidNames[t.eid]
        end
        if name and name ~= "" then
            ws.broken[name] = (ws.broken[name] or 0) + 1
        end
    end
end


function fireByteNetSwingTool(targetEntries, hrp, opts)
    opts = opts or {}
    if not targetEntries or #targetEntries == 0 or not ByteNetReliable or not hrp then return end

    local clean = {}
    for _, t in ipairs(targetEntries) do
        local id = math.floor(tonumber(t and t.eid) or 0)
        if id > 0 then
            table.insert(clean, { eid = id, pos = t.pos, resourceName = t.resourceName })
        end
    end
    if #clean == 0 then return end
    targetEntries = clean

    local swingId = getPacketId("SwingTool")
    if not swingId then return end

    local function computeFromPos()
        local fromPos = hrp.Position
        if opts.fromPos then
            fromPos = opts.fromPos
        end
        if not opts.skipLead then
            local vel = hrp.AssemblyLinearVelocity or Vector3.zero
            local horizontalVel = Vector3.new(vel.X, 0, vel.Z)
            local tweening = opts.tweening
            if tweening == nil then
                tweening = (isTweening == true) or (horizontalVel.Magnitude > 18)
            end
            local leadTime = tweening and (opts.leadTime ~= nil and opts.leadTime or 0.12) or (opts.leadTime or 0)
            fromPos = fromPos + (horizontalVel * leadTime)
        end
        return fromPos
    end

    local function cframeForBatch(batch, fromPos)
        if #batch == 1 then
            local tp = batch[1].pos
            if typeof(tp) == "Vector3" and (tp - fromPos).Magnitude > 0.01 then
                return CFrame.lookAt(fromPos, tp)
            end
            return hrp.CFrame
        end
        local sum = Vector3.zero
        local n = 0
        for _, t in ipairs(batch) do
            if typeof(t.pos) == "Vector3" then
                sum = sum + t.pos
                n = n + 1
            end
        end
        if n > 0 then
            local center = sum / n
            if (center - fromPos).Magnitude > 0.01 then
                return CFrame.lookAt(fromPos, center)
            end
        end
        return hrp.CFrame
    end

    local maxPerPacket = math.clamp(opts.maxPerPacket or 32, 1, 64)
    local timeStep = opts.timeStep or 0.01
    local baseTime = opts.baseTime or (time() - timeStep)
    local run = game:GetService("RunService")
    local pktIdx = 0

    for startIdx = 1, #targetEntries, maxPerPacket do
        if pktIdx > 0 then
            run.Heartbeat:Wait()
        end
        pktIdx = pktIdx + 1

        local batch = {}
        for i = startIdx, math.min(startIdx + maxPerPacket - 1, #targetEntries) do
            table.insert(batch, targetEntries[i])
        end
        local n = #batch
        local fromPos = computeFromPos()
        local cf = opts.cframe or cframeForBatch(batch, fromPos)
        -- 2 header + 18 cframe + 2 count + 5*n hits + 8 time
        local b = buffer.create(30 + 5 * n)
        buffer.writeu8(b, 0, 0)
        buffer.writeu8(b, 1, swingId)
        write18ByteCFrame(b, 2, cf)
        buffer.writeu16(b, 20, n)
        local o = 22
        for _, t in ipairs(batch) do
            buffer.writeu8(b, o, 0)
            buffer.writeu32(b, o + 1, math.floor(tonumber(t.eid) or 0))
            o = o + 5
        end
        buffer.writef64(b, o, baseTime + (pktIdx * timeStep))
        trackWebhookResourceBreaks(batch)
        ByteNetReliable:FireServer(b)
    end
end


local _auraLegitSwingAnimTrack = nil

local _auraLegitSwingLastChar = nil

local _auraLegitSwingLastPlay = 0

-- Same local swing feel as Combat SwingHit: ClientSwing + slash anim (+ tool Activate).

function playAuraLegitSwing()
    if not ByteNetReliable then return end
    pcall(function()
        local swingId = getPacketId("ClientSwing")
        if swingId then
            local swingBuf = buffer.create(2)
            buffer.writeu8(swingBuf, 0, 0)
            buffer.writeu8(swingBuf, 1, swingId)
            ByteNetReliable:FireServer(swingBuf)
        end
    end)
    pcall(function()
        if os.clock() - _auraLegitSwingLastPlay < 0.4 then return end
        _auraLegitSwingLastPlay = os.clock()
        local char = plr.Character
        if not char then return end
        if char ~= _auraLegitSwingLastChar then
            _auraLegitSwingLastChar = char
            _auraLegitSwingAnimTrack = nil
        end
        if not _auraLegitSwingAnimTrack then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local animator = hum and (hum:FindFirstChildOfClass("Animator") or hum:FindFirstChild("Animator"))
            if animator then
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://10761451679"
                _auraLegitSwingAnimTrack = animator:LoadAnimation(anim)
            end
        end
        if _auraLegitSwingAnimTrack then
            _auraLegitSwingAnimTrack:Play()
        end
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") then
                pcall(function() child:Activate() end)
                break
            end
        end
    end)
end

-- Same current SwingTool wire as fireByteNetSwingTool (kept for older call sites).

function fireByteNetSwingToolPackedMultiHit(targetEntries, hrp, opts)
    opts = opts or {}
    if not targetEntries or #targetEntries == 0 or not hrp then return end

    local seen = {}
    local clean = {}
    local maxN = math.clamp(opts.maxTargets or 9, 1, 9)
    for _, t in ipairs(targetEntries) do
        local id = math.floor(tonumber(t and t.eid) or 0)
        if id > 0 and not seen[id] then
            seen[id] = true
            table.insert(clean, t)
            if #clean >= maxN then break end
        end
    end
    if #clean == 0 then return end

    fireByteNetSwingTool(clean, hrp, {
        maxPerPacket = maxN,
        fromPos = opts.fromPos,
        cframe = opts.cframe,
        skipLead = opts.skipLead,
        tweening = opts.tweening,
        leadTime = opts.leadTime,
        timeStep = opts.timeStep,
        baseTime = opts.baseTime,
    })
end


function getlayout(name)
    if not name or name == "" then return nil end
    local mainGui = plr.PlayerGui:FindFirstChild("MainGui")
    if not mainGui then return nil end
    local right = mainGui:FindFirstChild("RightPanel")
    local inv = right and right:FindFirstChild("Inventory")
    local list = inv and inv:FindFirstChild("List")
    if not list then return nil end
    local lowerTarget = string.lower((tostring(name):match("^%s*(.-)%s*$") or ""))
    if lowerTarget == "" then return nil end
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("GuiObject") then
            local cn = string.lower((tostring(child.Name):match("^%s*(.-)%s*$") or ""))
            if cn == lowerTarget then
                return child.LayoutOrder
            end
        end
    end
    return nil
end


isTweening = false

rayParams = RaycastParams.new()

function updateRayParams()
    if plr.Character then rayParams.FilterDescendantsInstances = {plr.Character} end
end

plr.CharacterAdded:Connect(updateRayParams)

if plr.Character then updateRayParams() end


maxWalkAttemptTime = 3

end -- AsterGameCore
do -- AsterGameCoreMovement
function getToolSlot(toolName)
    local GameUtil = nil
    pcall(function() GameUtil = require(game:GetService("ReplicatedStorage").Modules.GameUtil) end)
    if not GameUtil then return nil end
    local toolbar = GameUtil.Data.toolbar
    if not toolbar then return nil end
    for i = 1, 6 do
        if toolbar[i] and toolbar[i].name == toolName then
            return i
        end
    end
    return nil
end


function equipItemPacket(name)
     if ByteNetReliable then
         local slot = getToolSlot(name)
         if slot then
             local equipPacketId = getPacketId("EquipTool")
             if not equipPacketId then return end
             local b = buffer.create(4)
             buffer.writeu8(b, 0, 0)
             buffer.writeu8(b, 1, equipPacketId)
             buffer.writeu16(b, 2, slot)
             ByteNetReliable:FireServer(b)
         else
             if plr.Character then
                 local tool = plr.Backpack:FindFirstChild(name)
                 if tool then plr.Character.Humanoid:EquipTool(tool) end
             end
         end
     else
         if plr.Character then
             local tool = plr.Backpack:FindFirstChild(name)
             if tool then plr.Character.Humanoid:EquipTool(tool) end
         end
     end
end


function isToolEquipped(toolName)
    local playersFolder = workspace:FindFirstChild("Players")
    if playersFolder then
        local plrFolder = playersFolder:FindFirstChild(plr.Name)
        if plrFolder then
            local toolsFolder = plrFolder:FindFirstChild("Tools")
            if toolsFolder and toolsFolder:FindFirstChild(toolName) then
                return true
            end
        end
    end
    if plr.Character and plr.Character:FindFirstChild(toolName) then
        return true
    end
    return false
end


local healSwingExcludedTools = {"bow", "potion", "sling", "saddle", "fishing rod", "horn", "shovel"}


function hasHealSwingTool()
    local function isSwingableToolName(name)
        if not name or name == "" then return false end
        local lowerName = string.lower(name)
        for _, kw in ipairs(healSwingExcludedTools) do
            if string.find(lowerName, kw, 1, true) then
                return false
            end
        end
        return true
    end

    local playersFolder = workspace:FindFirstChild("Players")
    if playersFolder then
        local plrFolder = playersFolder:FindFirstChild(plr.Name)
        local toolsFolder = plrFolder and plrFolder:FindFirstChild("Tools")
        if toolsFolder then
            for _, tool in ipairs(toolsFolder:GetChildren()) do
                if isSwingableToolName(tool.Name) then
                    return true
                end
            end
        end
    end

    local char = plr.Character
    if char then
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") and isSwingableToolName(child.Name) then
                return true
            end
        end
    end
    return false
end


local goldEquipActive = false


local function findNearbyPlantBox(hrp, range)
    range = range or 25
    if not hrp then return false end
    local rangeSq = range * range
    local hrpPos = hrp.Position
    local boxes = getPlantBoxModelsCached()
    if boxes then
        for i = 1, #boxes do
            local model = boxes[i]
            if model and model.Parent then
                local part = getPlantBoxPartCheap(model)
                if part then
                    local d = hrpPos - part.Position
                    if (d.X * d.X + d.Y * d.Y + d.Z * d.Z) <= rangeSq then
                        return true
                    end
                end
            end
        end
    end
    return false
end


function startGoldEquipManager()
    if goldEquipActive then return end
    if not Settings.GoldAutoEquip then return end
    goldEquipActive = true
    task.spawn(function()
        local HOE_RANGE = 30
        while Settings.GoldAutoEquip and not ScriptKilled do
            pcall(function()
                local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local nearby = findNearbyPlantBox(hrp, HOE_RANGE)
                if nearby then
                    local hoeName = Settings.GoldHoeType or "Wood Hoe"
                    if not isToolEquipped(hoeName) then
                        equipItemPacket(hoeName)
                        task.wait(0.35)
                    end
                else
                    local pickName = "God Pick"
                    if not isToolEquipped(pickName) then
                        equipItemPacket(pickName)
                        task.wait(0.35)
                    end
                end
            end)
            task.wait(0.4)
        end
        goldEquipActive = false
    end)
end


end -- AsterGameCoreMovement
do -- AsterPathFinder
function pathFinderGetMatchSubject(item)
    if not item or not item.Parent then return nil end
    if item:IsA("Model") then return item end
    if item:IsA("BasePart") then
        local parent = item.Parent
        if parent and parent:IsA("Model") then
            return parent
        end
        return item
    end
    return nil
end


function resolvePathFinderItemId(itemName)
    if not itemName or itemName == "" then
        return 0
    end
    local id = (type(autoDiscoverItemID) == "function") and autoDiscoverItemID(itemName) or nil
    if id == nil and type(craftNameToID) == "table" then
        id = craftNameToID[itemName]
    end
    return tonumber(id) or 0
end


function getPathFinderEntityId(item)
    if not item then return nil end
    local eid = item:GetAttribute("EntityID") or item:GetAttribute("ID")
    if type(eid) == "number" then return eid end
    return tonumber(eid)
end


function pathFinderMatchesOre(item, itemName)
    if not item or not itemName or itemName == "" then
        return false
    end
    local subject = pathFinderGetMatchSubject(item)
    if not subject or not subject.Parent then
        return false
    end
    local eid = getPathFinderEntityId(subject) or getPathFinderEntityId(item)
    local wantEid = resolvePathFinderItemId(itemName)
    if wantEid ~= 0 and eid == wantEid then
        return true
    end
    local name = subject.Name
    if name == itemName then
        return true
    end
    local base = itemName:gsub(" Node", ""):gsub(" Lode", "")
    if base ~= itemName and name:find(base, 1, true) then
        return true
    end
    return false
end


end -- AsterPathFinder
do -- AsterAuras
local ResourceIDCache = setmetatable({}, {__mode = "k"})

-- [[ Critter Whitelist & ID Cache ]] --

local CritterNames = {
    "Baby Sand Mammoth", "Bantae", "Banto", "Barbarian", "Big Stone Shelly", "Black Ant",
    "Crystal Bantae", "Fire Ant", "Giant", "Giant Shelly", "Gold Shelly", "Golden Banto",
    "Goldy Boi", "Goober", "Huge Ant", "Iron Shelly", "Lil Banto", "Lurky Boi",
    "Peeper", "Penguin", "Queen Ant", "Queen Ant's Servant", "Rentae", "Rento",
    "Sand Mammoth", "Scavenger Ant", "Shelbert", "Shelby", "Sheldon", "Shellington",
    "Shelly Spirit", "Snow Mammoth", "Stone Shelly", "Turtle", "White Ant"
}

local ValidCritters = {}

for _, name in ipairs(CritterNames) do ValidCritters[name] = true end

local CritterIDCache = setmetatable({}, {__mode = "k"})


local function matchesAuraTypeName(modelName, filterText, allToken)
    if not modelName then return false end
    filterText = tostring(filterText or allToken or "")
    local f = string.lower(string.gsub(filterText, "^%s+", ""))
    f = string.gsub(f, "%s+$", "")
    if f == "" or f == "all" then return true end
    local token = string.lower(tostring(allToken or ""))
    if token ~= "" and f == token then return true end
    if string.sub(f, 1, 3) == "all" then return true end
    local nameLower = string.lower(modelName)
    if nameLower == f then return true end
    if string.find(nameLower, f, 1, true) then return true end
    return false
end


local AURA_TYPES = { "Resource Aura", "Critter Aura", "Structure Aura" }

local AURA_UI = {
    ["Resource Aura"] = { field = "ResourceType", kind = "input", setting = "ResourceType", default = "AllResource" },
    ["Critter Aura"] = { field = "Critter Type", kind = "dropdown", setting = "CritterType", default = "All", options = getCritterNames },
    ["Structure Aura"] = { field = "StructureType", kind = "input", setting = "StructureType", default = "AllStructure" },
}

local AURA_ENABLED_KEYS = {
    ["Resource Aura"] = "ResourceAuraEnabled",
    ["Critter Aura"] = "CritterAuraEnabled",
    ["Structure Aura"] = "StructureAuraEnabled",
}


local function copyAuraSelection(sel)
    local out = {}
    for k, v in pairs(sel or {}) do
        if v then out[k] = true end
    end
    return out
end


local function getAuraTypeDefault()
    return copyAuraSelection(Settings.AuraTypeSelection)
end


function syncAuraTypeInputVisibility(sel)
    for _, auraName in ipairs(AURA_TYPES) do
        local ui = AURA_UI[auraName]
        local reg = Window.ElementRegistry[ui.field]
        if reg and reg.SetVisible then
            reg.SetVisible(sel[auraName] == true)
        end
    end
end


local function anyAuraEnabled()
    return Settings.ResourceAuraEnabled or Settings.StructureAuraEnabled or Settings.CritterAuraEnabled
end


function syncAuraRuntimeState()
    local turnOn = Settings.TurnOnAura == true
    local sel = Settings.AuraTypeSelection or {}
    local auraReg = Window and Window.ElementRegistry and Window.ElementRegistry["SelectAuraType"]
    if auraReg and auraReg.GetValue then
        sel = copyAuraSelection(auraReg.GetValue())
        Settings.AuraTypeSelection = sel
    end
    for _, auraName in ipairs(AURA_TYPES) do
        Settings[AURA_ENABLED_KEYS[auraName]] = turnOn and sel[auraName] == true
    end
    if anyAuraEnabled() then
        startUnifiedAura()
    end
end


function applyAuraTypeSelection(sel)
    Settings.AuraTypeSelection = copyAuraSelection(sel)
    syncAuraTypeInputVisibility(sel)
    syncAuraRuntimeState()
end


function setupToolsAuraUI(tab)
    local auraDefault = getAuraTypeDefault()
    tab:AddMultiDropdown("SelectAuraType", AURA_TYPES, auraDefault, applyAuraTypeSelection)
    for _, auraName in ipairs(AURA_TYPES) do
        local ui = AURA_UI[auraName]
        local value = Settings[ui.setting] or ui.default
        if ui.kind == "input" then
            tab:AddInput(ui.field, value, function(v)
                Settings[ui.setting] = (v ~= "" and v) or ui.default
            end)
        else
            local opts = ui.options()
            local listed = false
            for _, name in ipairs(opts) do
                if name == value then listed = true break end
            end
            tab:AddDropdown(ui.field, opts, listed and value or ui.default, function(v)
                Settings[ui.setting] = v
            end)
        end
    end
    syncAuraTypeInputVisibility(auraDefault)
    tab:AddToggle("TurnOnAura", Settings.TurnOnAura or false, function(v)
        Settings.TurnOnAura = v
        syncAuraRuntimeState()
    end)
    tab:AddToggle("LegitSwing", Settings.AuraLegitSwing == true, function(v)
        Settings.AuraLegitSwing = v == true
    end)
    tab:AddSlider("Target Count", 1, 50, Settings.ResourceTargetCount or 2, 1, function(v)
        local n = math.floor(v + 0.5)
        Settings.ResourceTargetCount = n
        Settings.CritterTargetCount = n
    end)

    local auraReg = Window.ElementRegistry["SelectAuraType"]
    if auraReg and auraReg.GetValue then
        applyAuraTypeSelection(auraReg.GetValue())
    else
        syncAuraRuntimeState()
    end
end


ASTER.Options = ASTER.Options or {}

ASTER.Options.AuraRuntimeShared = ASTER.Options.AuraRuntimeShared or {}

ASTER.Options.AuraRuntimeShared.matchesAuraTypeName = matchesAuraTypeName

ASTER.Options.AuraRuntimeShared.ResourceIDCache = ResourceIDCache

ASTER.Options.AuraRuntimeShared.CritterIDCache = CritterIDCache

ASTER.Options.AuraRuntimeShared.ValidCritters = ValidCritters

ASTER.Options.AuraRuntimeShared.anyAuraEnabled = anyAuraEnabled
-- aura loop flag

__ASTER_RUNTIME.unifiedAuraActive = __ASTER_RUNTIME.unifiedAuraActive == true


end -- AsterAuras UI
do -- AsterAurasRuntime
local __AuraUIShared = ASTER.Options and ASTER.Options.AuraRuntimeShared or {}

local ResourceIDCache = __AuraUIShared.ResourceIDCache or setmetatable({}, { __mode = "k" })

local CritterIDCache = __AuraUIShared.CritterIDCache or setmetatable({}, { __mode = "k" })

local ValidCritters = __AuraUIShared.ValidCritters or {}

local matchesAuraTypeName = __AuraUIShared.matchesAuraTypeName or critterNameMatchesFilter
-- Inline check only Ã¢â‚¬â€ never call through AuraRuntimeShared (that caused recursion).

local function anyAuraEnabled()
    return Settings.ResourceAuraEnabled == true
        or Settings.StructureAuraEnabled == true
        or Settings.CritterAuraEnabled == true
end


local UnifiedAuraState = {
    resourceCache = {},
    resourceScanAt = 0,
    structureCache = {},
    structureScanAt = 0,
    critterCache = {},
    critterFolder = nil,
    critterConn = nil,
    critterRemConn = nil,
    critterScanAt = 0,
}


local function getAuraEntityID(inst, cache, minId)
    if not inst then return nil end
    if cache[inst] then return cache[inst] end
    minId = tonumber(minId) or 0

    local keys = { "EntityID", "NetworkId", "networkId", "NetworkID", "ID", "Id", "Eid", "EntityId" }
    for _, key in ipairs(keys) do
        local v = inst:GetAttribute(key)
        if v ~= nil then
            local n = math.floor(tonumber(v) or 0)
            if n > 0 then
                cache[inst] = n
                return n
            end
        end
    end

    for name, value in pairs(inst:GetAttributes()) do
        if typeof(value) == "number" then
            local ln = string.lower(tostring(name))
            if value > minId and (ln:find("network", 1, true) or ln == "id" or ln:find("entity", 1, true) or ln == "eid") then
                local n = math.floor(value)
                if n > 0 then
                    cache[inst] = n
                    return n
                end
            end
        end
    end

    for _, childName in ipairs(keys) do
        local val = inst:FindFirstChild(childName)
        if val and (val:IsA("IntValue") or val:IsA("NumberValue")) then
            local n = math.floor(tonumber(val.Value) or 0)
            if n > minId then
                cache[inst] = n
                return n
            end
        end
    end

    local val = inst:FindFirstChildWhichIsA("IntValue") or inst:FindFirstChildWhichIsA("NumberValue")
    if val and typeof(val.Value) == "number" and val.Value > minId then
        local n = math.floor(val.Value)
        cache[inst] = n
        return n
    end
    return nil
end


local function getCritterAuraID(model)
    if CritterIDCache[model] then return CritterIDCache[model] end
    if not ValidCritters[model.Name] then return nil end
    return getAuraEntityID(model, CritterIDCache, 1000)
end


local function getAuraTargetCount()
    return math.clamp(tonumber(Settings.ResourceTargetCount) or tonumber(Settings.CritterTargetCount) or 1, 1, 9)
end


local function getAuraConfirmRange(hrp, baseRange)
    local range = baseRange or 15
    local vel = hrp.AssemblyLinearVelocity or Vector3.zero
    local horizontalVel = Vector3.new(vel.X, 0, vel.Z)
    local tweening = (isTweening == true) or (horizontalVel.Magnitude > 18)
    local confirmRange = tweening and (range + 4) or range
    return confirmRange, confirmRange * confirmRange
end


local function getAuraTargetResourceName(t)
    local resources = getWorkspaceResources()
    if not resources or not t or not t.model then return nil end
    local m = t.model
    if m:IsA("BasePart") then m = m.Parent end
    while m and m.Parent and m.Parent ~= resources do
        m = m.Parent
    end
    if m and m.Parent == resources then
        return m.Name
    end
    return nil
end


local function pickAuraTargets(targets, rangeSq, maxPick, opts)
    opts = opts or {}
    table.sort(targets, function(a, b) return a.distSq < b.distSq end)
    local picked = {}
    local seenEid = {}
    for i = 1, #targets do
        if #picked >= maxPick then break end
        local t = targets[i]
        if t.distSq <= rangeSq then
            if not (opts.skipTarget and opts.skipTarget(t)) then
                if opts.dedupeEid then
                    local id = math.floor(tonumber(t.eid) or 0)
                    if id > 0 and not seenEid[id] then
                        seenEid[id] = true
                        table.insert(picked, { eid = t.eid, pos = t.pos, resourceName = getAuraTargetResourceName(t) })
                    end
                else
                    table.insert(picked, { eid = t.eid, pos = t.pos, resourceName = getAuraTargetResourceName(t) })
                end
            end
        end
    end
    return picked
end


local function mergeAuraSwingRows(...)
    local combined, seen = {}, {}
    for i = 1, select("#", ...) do
        for _, row in ipairs(select(i, ...)) do
            local id = math.floor(tonumber(row and row.eid) or 0)
            if id > 0 and not seen[id] then
                seen[id] = true
                table.insert(combined, { eid = row.eid, pos = row.pos, resourceName = row.resourceName })
            end
        end
    end
    return combined
end



local function rescanResourceCache(st, hrpPos, scanRange)
    table.clear(st.resourceCache)
    local resources = getWorkspaceResources()
    st.resourceFolder = resources
    if not resources or not hrpPos then return end

    scanRange = math.max(tonumber(scanRange) or 60, 30)
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = { resources }
    local parts = workspace:GetPartBoundsInRadius(hrpPos, scanRange, params)
    local seen = {}
    local maxParts = 300
    local n = math.min(#parts, maxParts)
    for i = 1, n do
        local part = parts[i]
        if part and part.Parent then
            local model = part.Parent
            if not model:IsA("Model") then
                model = part:FindFirstAncestorOfClass("Model")
            end
            if model and not seen[model] then
                local eid = getAuraEntityID(model, ResourceIDCache, 1)
                local ppart = model.PrimaryPart or part
                if eid and ppart then
                    seen[model] = true
                    __ASTER_RUNTIME.webhookResourceEids[eid] = model.Name
                    table.insert(st.resourceCache, { model = model, part = ppart, eid = eid })
                end
            end
        end
    end
end


local function rescanStructureCache(st, hrpPos, scanRange)
    table.clear(st.structureCache)
    local deployables = getWorkspaceDeployables()
    if not deployables or not hrpPos then return end

    scanRange = math.max(tonumber(scanRange) or 60, 30)
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = { deployables }
    local parts = workspace:GetPartBoundsInRadius(hrpPos, scanRange, params)
    local seen = {}
    local maxParts = 250
    local n = math.min(#parts, maxParts)
    for i = 1, n do
        local part = parts[i]
        if part and part.Parent then
            local model = part:FindFirstAncestorOfClass("Model")
            if model then
                while model.Parent and model.Parent ~= deployables and model.Parent:IsA("Model") do
                    model = model.Parent
                end
                if not seen[model] then
                    seen[model] = true
                    local eid = getAuraEntityID(model, ResourceIDCache, 1)
                    local ppart = model.PrimaryPart or part
                    if eid and ppart then
                        table.insert(st.structureCache, { model = model, part = ppart, eid = eid })
                    end
                end
            end
        end
    end
end


local function auraSandSkipTarget(t)
    if not Settings.AutoSandEnabled or Settings.SandFarmPhase == "break" then return false end
    local sandSpot = Settings.SandFarmSpot
    if not sandSpot then return false end
    local model = t.model
    if model and (model.Name == "Sand Mound" or model.Name == "_MOUND") then
        local p = model:GetPivot().Position
        if math.abs(p.X - sandSpot.x) < 3 and math.abs(p.Z - sandSpot.z) < 3 then
            return true
        end
    end
    return false
end


local function collectResourceAuraTargets(st, hrpPos, now, rangeSq)
    local resources = getWorkspaceResources()
    local scanRange = math.sqrt(rangeSq) + 25
    local interval = (#(st.resourceCache or {}) == 0) and 1.25 or 5
    if resources ~= st.resourceFolder or now - (st.resourceScanAt or 0) > interval then
        st.resourceScanAt = now
        rescanResourceCache(st, hrpPos, scanRange)
    end

    local resourceFilter = Settings.ResourceType or "AllResource"
    local targets, newCache = {}, {}
    for i = 1, #st.resourceCache do
        local resData = st.resourceCache[i]
        if resData.model and resData.model.Parent and resData.part and resData.part.Parent then
            table.insert(newCache, resData)
            local distSq = (resData.part.Position - hrpPos):Dot(resData.part.Position - hrpPos)
            if distSq <= (rangeSq + 100) then
                if Settings.PathFinderEnabled and Settings.PathFinderItem then
                    if not pathFinderMatchesOre(resData.model, Settings.PathFinderItem) then continue end
                end
                if matchesAuraTypeName(resData.model.Name, resourceFilter, "AllResource") then
                    table.insert(targets, { eid = resData.eid, distSq = distSq, pos = resData.part.Position, model = resData.model })
                end
            end
        end
    end
    st.resourceCache = newCache
    return targets
end


local function collectStructureAuraTargets(st, hrpPos, now, rangeSq)
    local interval = (#(st.structureCache or {}) == 0) and 1.25 or 5
    if now - (st.structureScanAt or 0) > interval then
        st.structureScanAt = now
        rescanStructureCache(st, hrpPos, math.sqrt(rangeSq) + 25)
    end

    local structureFilter = Settings.StructureType or "AllStructure"
    local targets, newCache = {}, {}
    for i = 1, #st.structureCache do
        local resData = st.structureCache[i]
        if resData.model and resData.model.Parent then
            table.insert(newCache, resData)
            local distSq = (resData.part.Position - hrpPos):Dot(resData.part.Position - hrpPos)
            if distSq <= (rangeSq + 100) and matchesAuraTypeName(resData.model.Name, structureFilter, "AllStructure") then
                table.insert(targets, { eid = resData.eid, distSq = distSq, pos = resData.part.Position, model = resData.model })
            end
        end
    end
    st.structureCache = newCache
    return targets
end


local function ensureCritterWatcher(st)
    local folder = getWorkspaceCritters()
    if folder == st.critterFolder then return end
    if st.critterConn then st.critterConn:Disconnect() st.critterConn = nil end
    if st.critterRemConn then st.critterRemConn:Disconnect() st.critterRemConn = nil end
    st.critterFolder = folder
    table.clear(st.critterCache)
    if folder then
        for _, critter in ipairs(collectWorkspaceCritters(folder)) do
            table.insert(st.critterCache, critter)
        end
        st.critterConn = folder.ChildAdded:Connect(function(child)
            if isWorkspaceCritterInstance(child) then
                table.insert(st.critterCache, child)
            elseif child:IsA("Folder") then
                for _, critter in ipairs(collectWorkspaceCritters(child)) do
                    table.insert(st.critterCache, critter)
                end
            end
        end)
        st.critterRemConn = folder.ChildRemoved:Connect(function(child)
            for i = #st.critterCache, 1, -1 do
                if st.critterCache[i] == child then
                    table.remove(st.critterCache, i)
                end
            end
        end)
    end
    st.critterScanAt = tick()
end


local function collectCritterAuraTargets(st, hrpPos, now)
    ensureCritterWatcher(st)
    if st.critterFolder and now - st.critterScanAt > 10 then
        st.critterScanAt = now
        table.clear(st.critterCache)
        for _, critter in ipairs(collectWorkspaceCritters(st.critterFolder)) do
            table.insert(st.critterCache, critter)
        end
    end

    local range = Settings.CritterRange or 15
    local rangeSq = range * range
    local detectionRangeSq = (range + 10) * (range + 10)
    local critterFilter = Settings.CritterType or "All"
    local targets, newCache = {}, {}
    for i = 1, #st.critterCache do
        local critter = st.critterCache[i]
        if critter and critter.Parent and st.critterFolder and critter:IsDescendantOf(st.critterFolder)
            and isWorkspaceCritterAlive(critter) then
            table.insert(newCache, critter)
            local eid = getCritterAuraID(critter)
            if eid and critterNameMatchesFilter(getWorkspaceCritterName(critter), critterFilter, "All") then
                local ppart = getWorkspaceCritterPart(critter)
                if ppart then
                    local distSq = (ppart.Position - hrpPos):Dot(ppart.Position - hrpPos)
                    if distSq <= detectionRangeSq then
                        table.insert(targets, { eid = eid, distSq = distSq, pos = ppart.Position })
                    end
                end
            end
        end
    end
    st.critterCache = newCache
    return targets, rangeSq
end


local function tickUnifiedAuras(st, hrp, hrpPos, now)
    local maxPick = getAuraTargetCount()
    local resPicked, structPicked, critPicked = {}, {}, {}
    local enabledCount = 0

    if Settings.ResourceAuraEnabled then
        enabledCount = enabledCount + 1
        local _, rangeSq = getAuraConfirmRange(hrp, Settings.ResourceRange or 15)
        resPicked = pickAuraTargets(
            collectResourceAuraTargets(st, hrpPos, now, rangeSq),
            rangeSq,
            maxPick,
            { skipTarget = auraSandSkipTarget }
        )
    end

    if Settings.StructureAuraEnabled then
        enabledCount = enabledCount + 1
        local _, rangeSq = getAuraConfirmRange(hrp, Settings.ResourceRange or 15)
        structPicked = pickAuraTargets(
            collectStructureAuraTargets(st, hrpPos, now, rangeSq),
            rangeSq,
            maxPick,
            { dedupeEid = true }
        )
    end

    if Settings.CritterAuraEnabled then
        enabledCount = enabledCount + 1
        local critterTargets, critterRangeSq = collectCritterAuraTargets(st, hrpPos, now)
        critPicked = pickAuraTargets(critterTargets, critterRangeSq, maxPick)
    end

    if enabledCount == 0 then return end

    local combined = mergeAuraSwingRows(resPicked, structPicked, critPicked)
    if #combined == 0 then return end

    -- Prefer CFrame SwingTool. Packed trailer bytes break easily after game updates.
    local usePacked = Settings.ResourceSwingPackedMultiHit == true
        and Settings.CritterSwingPackedMultiHit == true
    if usePacked then
        fireByteNetSwingToolPackedMultiHit(combined, hrp, { maxTargets = math.min(9, maxPick * enabledCount) })
    else
        fireByteNetSwingTool(combined, hrp, { maxPerPacket = math.min(9, maxPick * enabledCount) })
    end
    if Settings.AuraLegitSwing then
        playAuraLegitSwing()
    end
end


function startUnifiedAura()
    if __ASTER_RUNTIME.unifiedAuraActive then return end
    if not anyAuraEnabled() then return end
    __ASTER_RUNTIME.unifiedAuraActive = true
    -- Packed SwingTool trailer is stale after recent game updates; use CFrame packets.
    if Settings.ResourceSwingPackedMultiHit ~= false then
        Settings.ResourceSwingPackedMultiHit = false
    end
    local st = UnifiedAuraState
    st.resourceScanAt = 0
    st.structureScanAt = 0
    st.critterScanAt = 0
    st.resourceFolder = nil
    table.clear(st.resourceCache)
    pcall(function() require(game:GetService("ReplicatedStorage").Modules.ItemIDS) end)
    task.spawn(function()
        while anyAuraEnabled() do
            pcall(function()
                if not getPacketId("SwingTool") then return end
                local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local hrpPos = hrp.Position
                local now = tick()
                tickUnifiedAuras(st, hrp, hrpPos, now)
            end)
            local waitTime = Settings.ResourceCooldown or 0.03
            if Settings.CritterAuraEnabled and not Settings.ResourceAuraEnabled and not Settings.StructureAuraEnabled then
                waitTime = Settings.CritterCooldown or 0.03
            end
            task.wait(math.max(tonumber(waitTime) or 0.05, 0.05))
        end
        if st.critterConn then st.critterConn:Disconnect() st.critterConn = nil end
        if st.critterRemConn then st.critterRemConn:Disconnect() st.critterRemConn = nil end
        st.critterFolder = nil
        __ASTER_RUNTIME.unifiedAuraActive = false
    end)
end


ASTER.Options.AuraRuntimeShared = ASTER.Options.AuraRuntimeShared or {}

ASTER.Options.AuraRuntimeShared.ResourceIDCache = ResourceIDCache

ASTER.Options.AuraRuntimeShared.CritterIDCache = CritterIDCache

ASTER.Options.AuraRuntimeShared.ValidCritters = ValidCritters

ASTER.Options.AuraRuntimeShared.matchesAuraTypeName = matchesAuraTypeName

end -- AsterAurasCoreRuntime
do -- AsterAurasSpecialRuntime
local __AuraRuntimeShared = ASTER.Options and ASTER.Options.AuraRuntimeShared or {}

local ResourceIDCache = __AuraRuntimeShared.ResourceIDCache or setmetatable({}, {__mode = "k"})

local CritterIDCache = __AuraRuntimeShared.CritterIDCache or setmetatable({}, {__mode = "k"})

local getAuraConfirmRange = __AuraRuntimeShared.getAuraConfirmRange

local pickAuraTargets = __AuraRuntimeShared.pickAuraTargets

local getAuraEntityID = __AuraRuntimeShared.getAuraEntityID

local matchesAuraTypeName = __AuraRuntimeShared.matchesAuraTypeName



end -- AsterAuras
do -- AsterCombatReach
autoHitSelection = "SwingHit"

end -- AsterCombatReach
do -- AsterHeal
local healLastTrackedHealth = nil

local healLastDamageTime = 0

local healDamageBurstHits = 0

local healAdaptiveDelay = 0

local healNoGainStreak = 0

local healHealthConn = nil

local healRecentHitTimes = {}

-- CMethod (SmartHeal): wait until HP hits the 60-65% zone, then run
-- heal 7s -> pause 0.30s -> heal 7s -> pause 0.30s... until topped back up.

local SMARTHEAL_RECOVER_PERCENT = 98

local SMARTHEAL_ACTIVE_SEC = 7

local SMARTHEAL_PAUSE_SEC = 0.30

local healSmartBursting = false

local healSmartCycleStart = 0

-- Ping/FPS adaptive heal: slider = max CPS when connection is healthy.
-- Soft throttle only Ã¢â‚¬â€ never punish normal mid-fight ping/FPS into a death spiral.

local RunService = game:GetService("RunService")

local healLastHealthChangeClock = 0

local healLagPauseUntil = 0

local healCachedFruitName = nil

local healCachedFruitId = nil

local healCachedSlotId = nil

local healCacheRefreshAt = 0

function invalidateHealFruitCache()
    healCachedFruitName = nil
    healCachedFruitId = nil
    healCachedSlotId = nil
    healCacheRefreshAt = 0
end


local function pruneHealHitTimes(now)
    local window = tonumber(Settings.HealDoubleHitWindow) or 0.65
    for i = #healRecentHitTimes, 1, -1 do
        if now - healRecentHitTimes[i] > window then
            table.remove(healRecentHitTimes, i)
        end
    end
    healDamageBurstHits = #healRecentHitTimes
end


local function registerHealDamageHit()
    local now = os.clock()
    table.insert(healRecentHitTimes, now)
    pruneHealHitTimes(now)
    healLastDamageTime = now
    healAdaptiveDelay = math.max(0, healAdaptiveDelay * 0.45)
    healNoGainStreak = 0
    return healDamageBurstHits
end

-- Ping refresh from heal tick (FPS comes only from Heartbeat sampler).

function isSmartHealOn()
    -- Strict gate: SmartHeal/CMethod never runs unless the Combat toggle is ON.
    return Settings.AutoHealEnabled == true and Settings.SmartHealEnabled == true
end


local function getSmartHealDutyCycle(now)
    now = now or os.clock()
    if healSmartCycleStart <= 0 then
        healSmartCycleStart = now
    end
    local period = SMARTHEAL_ACTIVE_SEC + SMARTHEAL_PAUSE_SEC
    local elapsed = (now - healSmartCycleStart) % period
    if elapsed < SMARTHEAL_ACTIVE_SEC then
        return true, SMARTHEAL_ACTIVE_SEC - elapsed
    end
    return false, period - elapsed
end


local function triggerDoubleHitBurst()
    if not isSmartHealOn() or not healSmartBursting then return end
    local active = getSmartHealDutyCycle()
    if not active then return end
    task.spawn(function()
        local burstCount = 8
        for _ = 1, burstCount do
            if not isSmartHealOn() or not healSmartBursting then break end
            local stillActive = getSmartHealDutyCycle()
            if not stillActive then break end
            local hum = plr.Character and plr.Character:FindFirstChild("Humanoid")
            if not hum or hum.Health <= 0 then break end
            local hpPercent = (hum.Health / hum.MaxHealth) * 100
            if hpPercent >= SMARTHEAL_RECOVER_PERCENT then break end
            executeHeal(true)
            task.wait(0.03)
        end
    end)
end


local function bindSmartHealHealthWatch(character)
    if healHealthConn then
        healHealthConn:Disconnect()
        healHealthConn = nil
    end
    local hum = character and character:FindFirstChild("Humanoid")
    if not hum then return end
    healLastTrackedHealth = hum.Health
    healLastHealthChangeClock = os.clock()
    healHealthConn = hum.HealthChanged:Connect(function(newHealth)
        healLastHealthChangeClock = os.clock()
        -- Fresh health means replication is alive again.
        if healLagPauseUntil > 0 then
            healLagPauseUntil = 0
        end
        if not isSmartHealOn() then
            healLastTrackedHealth = newHealth
            healSmartBursting = false
            return
        end
        if healLastTrackedHealth and newHealth < healLastTrackedHealth - 0.01 then
            local hitCount = registerHealDamageHit()
            if hitCount == 2 then
                triggerDoubleHitBurst()
            end
        elseif healLastTrackedHealth and newHealth > healLastTrackedHealth + 0.75 then
            healNoGainStreak = 0
            healAdaptiveDelay = math.max(0, healAdaptiveDelay - 0.012)
        end
        healLastTrackedHealth = newHealth
    end)
    trackConnection("smartHealHealth", healHealthConn)
end


function resolveHealFruitItemId(fruitName)
    if not fruitName or fruitName == "" then return nil end
    local cached = healFruitData[fruitName]
    if cached == false then cached = nil end
    if type(cached) == "number" and cached > 0 then return cached end
    local id = autoDiscoverItemID(fruitName)
    if id == nil and craftNameToID then
        id = craftNameToID[fruitName]
    end
    if type(id) == "number" and id > 0 then
        healFruitData[fruitName] = id
        return id
    end
    return nil
end


local healSwingAnimTrack = nil

local healSwingLastAnim = 0

local healSwingLastChar = nil


local function playHealSwingAnimation()
    if os.clock() - healSwingLastAnim < 0.3 then return end
    healSwingLastAnim = os.clock()
    pcall(function()
        local char = plr.Character
        if not char then return end
        if char ~= healSwingLastChar then
            healSwingLastChar = char
            healSwingAnimTrack = nil
        end
        local animator = char:FindFirstChild("Humanoid") and char.Humanoid:FindFirstChild("Animator")
        if animator and not healSwingAnimTrack then
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://10761451679"
            healSwingAnimTrack = animator:LoadAnimation(anim)
        end
        if healSwingAnimTrack then
            healSwingAnimTrack:Play()
        end
    end)
end


local function fireHealEquippedToolSwing()
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not ByteNetReliable then return end
    if not hasHealSwingTool() then return end

    pcall(function()
        local swingId = getPacketId("ClientSwing")
        if swingId then
            local swingBuf = buffer.create(2)
            buffer.writeu8(swingBuf, 0, 0)
            buffer.writeu8(swingBuf, 1, swingId)
            ByteNetReliable:FireServer(swingBuf)
        end
        playHealSwingAnimation()
        local char = plr.Character
        if char then
            for _, child in ipairs(char:GetChildren()) do
                if child:IsA("Tool") then
                    pcall(function() child:Activate() end)
                    break
                end
            end
        end
    end)
end


function getAutoHealType()
    local healType = Settings.AutoHealType or "AutoHeal"
    if healType == "SwingTool" then
        healType = "SwingHeal AnimationOnly"
        Settings.AutoHealType = healType
    end
    return healType
end


function isCombatSwingHitActive()
    return Settings.AutoHitStartEnabled == true and autoHitSelection == "SwingHit"
end


local function executeHealFruit()
    local fruitName = Settings.HealFruit
    if not fruitName or fruitName == "" or not ByteNetReliable then return end

    local now = os.clock()
    local fruitID = healCachedFruitId
    local slotID = healCachedSlotId
    local cacheFresh = healCachedFruitName == fruitName and now < healCacheRefreshAt

    if not cacheFresh or not fruitID or not slotID then
        fruitID = resolveHealFruitItemId(fruitName)
        slotID = fruitID and getlayout(fruitName) or nil
        if fruitID and slotID then
            healCachedFruitName = fruitName
            healCachedFruitId = fruitID
            healCachedSlotId = slotID
            -- Refresh often enough for bag reshuffles, not every packet.
            healCacheRefreshAt = now + 0.75
        else
            invalidateHealFruitCache()
            return
        end
    end

    local actionId = getPacketId("UseBagItem")
    if not actionId then return end
    local b = buffer.create(8)
    buffer.writeu8(b, 0, 0)
    buffer.writeu8(b, 1, actionId)
    buffer.writeu32(b, 2, slotID)
    buffer.writeu16(b, 6, fruitID)
    ByteNetReliable:FireServer(b)
end


function executeHeal(forceSmartBurst)
    local now = os.clock()
    if now < healLagPauseUntil then
        local hum = plr.Character and plr.Character:FindFirstChild("Humanoid")
        local critical = hum and hum.MaxHealth > 0 and (hum.Health / hum.MaxHealth) <= 0.45
        if not critical then
            return
        end
    end
    pcall(function()
        local character = plr.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 then
            local hpPercent = (humanoid.Health / humanoid.MaxHealth) * 100
            -- forceSmartBurst only valid while CMethod/SmartHeal toggle is ON.
            local allowHeal = (forceSmartBurst == true) and isSmartHealOn()
            if not allowHeal then
                local threshold = tonumber(Settings.HealThreshold) or 70
                allowHeal = hpPercent <= threshold
            end
            if allowHeal then
                local healType = getAutoHealType()
                if healType == "AutoHeal" or healType == "SwingHeal AnimationOnly" then
                    executeHealFruit()
                end
                if healType == "SwingHeal AnimationOnly" and not isCombatSwingHitActive() then
                    fireHealEquippedToolSwing()
                end
            end
        end
    end)
end


end -- AsterHeal
do -- AsterEatFuelPlantHarvest
local fuelActive = false

function startAutoFuel()
    if fuelActive then return end
    fuelActive = true
    task.spawn(function()
        local ItemIDS = nil
        pcall(function() ItemIDS = require(game:GetService("ReplicatedStorage").Modules.ItemIDS) end)
        
        while Settings.AutoFuelEnabled do
            pcall(function()
                local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                
                local fuelTypes = {}
                if Settings.FuelType == "All (Wood/Log/Leaves)" then
                    for _, fName in ipairs({"Wood", "Log", "Leaves"}) do 
                        if getlayout(fName) then 
                            local id = (ItemIDS and ItemIDS[fName]) or fueltoitemid[fName]
                            if id then table.insert(fuelTypes, {id = id}) end
                        end 
                    end
                else
                    if getlayout(Settings.FuelType) then 
                        local id = (ItemIDS and ItemIDS[Settings.FuelType]) or fueltoitemid[Settings.FuelType]
                        if id then table.insert(fuelTypes, {id = id}) end
                    end
                end

                if #fuelTypes > 0 then
                    local deployables = getWorkspaceDeployables()
                    if deployables then
                        for _, v in ipairs(deployables:GetChildren()) do
                            if v.Name == "Campfire" then
                                local textLabel = v:FindFirstChild("Board") and v.Board:FindFirstChild("Billboard") and v.Board.Billboard:FindFirstChild("Backdrop") and v.Board.Billboard.Backdrop:FindFirstChild("TextLabel")
                                if textLabel then
                                    local currentFuel = tonumber(textLabel.Text) or 0
                                    local threshold = Settings.FuelThreshold or 10
                                    if currentFuel < threshold then
                                        local dist = (v.Board.Position - hrp.Position).Magnitude
                                        if dist <= 35 then
                                            local eID = v:GetAttribute("EntityID")
                                            if eID and ByteNetReliable then
                                                local b = buffer.create(8)
                                                buffer.writeu8(b, 0, 0)
                                                buffer.writeu8(b, 1, getPacketId("InteractStructure"))
                                                buffer.writeu32(b, 2, eID)
                                                buffer.writeu16(b, 6, fuelTypes[1].id)
                                                ByteNetReliable:FireServer(b)
                                                task.wait(0.1)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            task.wait(0.5)
        end
        fuelActive = false
    end)
end

-- [[ QUICK HUT LOGIC ]] --

end -- AsterFuelQuickHut
do -- AsterSandFarm
local sandSpot = nil

end -- AsterSandFarm
do
function getInventorySlotAndCount(itemName)
    local mainGui = plr.PlayerGui:FindFirstChild("MainGui")
    if not mainGui then return nil, nil end
    local inventory = mainGui.RightPanel and mainGui.RightPanel.Inventory and mainGui.RightPanel.Inventory.List
    if not inventory then return nil, nil end
    local item = inventory:FindFirstChild(itemName)
    if item then
        local slotID = item.LayoutOrder
        local count = 0
        local qtyImage = item:FindFirstChild("QuantityImage")
        if qtyImage then
            local qtyText = qtyImage:FindFirstChild("QuantityText")
            if qtyText and qtyText.Text ~= "" then
                local clean = qtyText.Text:gsub("%D", "")
                count = tonumber(clean) or 0
            end
        end
        if count == 0 then
             local attrCount = item:GetAttribute("Count") or item:GetAttribute("Amount")
             if attrCount then count = attrCount end
        end
        return slotID, count
    end
    return nil, nil
end


function eatDownToCap(fruitName, cap)
    local fruitID = resolveHealFruitItemId(fruitName)
    if not fruitID then return end
    cap = tonumber(cap) or 0
    local slotID, count = getInventorySlotAndCount(fruitName)
    
    if slotID and count then
        if count > cap then
            local toEat = count - cap
            if toEat > 20 then toEat = 20 end 
            for i = 1, toEat do
                if not (Settings.WasteFruitsEnabled or Settings.EatCapEnabled) then break end
                pcall(function() 
                    local actionId = getPacketId("UseBagItem")
                    local b = buffer.create(8)
                    buffer.writeu8(b, 0, 0)
                    buffer.writeu8(b, 1, actionId)
                    buffer.writeu32(b, 2, slotID)
                    buffer.writeu16(b, 6, fruitID)
                    if ByteNetReliable then ByteNetReliable:FireServer(b) end
                end)
                task.wait(0.25) 
            end
        end
    end
end


function startEatCap()
    task.spawn(function()
        while Settings.WasteFruitsEnabled or Settings.EatCapEnabled do
            local wasteFruit = Settings.WasteFruit or "Bloodfruit"
            local cap = tonumber(Settings.FruitsCapAmount) or tonumber(Settings.EatCap) or 100
            if wasteFruit and cap then eatDownToCap(wasteFruit, cap) end
            task.wait(1)
        end
    end)
end

end -- AsterRebirthEatCap
do -- AsterPreTabInit
autoEatActive = false

function startAutoEat()
    if autoEatActive then return end
    autoEatActive = true
    task.spawn(function()
        while Settings.AutoEatEnabled do
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                -- Get Hunger from GUI
                local mainGui = plr.PlayerGui:FindFirstChild("MainGui")
                local hungerVal = 100 -- Default safe value
                if mainGui then
                    local bars = mainGui:FindFirstChild("Panels") and mainGui.Panels:FindFirstChild("Stats") and mainGui.Panels.Stats:FindFirstChild("Bars")
                    if bars then
                        local hungerLabel = bars:FindFirstChild("Hunger") and bars.Hunger:FindFirstChild("ValueLabel")
                        if hungerLabel and hungerLabel:IsA("TextLabel") then
                            local num = tonumber(hungerLabel.Text)
                            if num then hungerVal = num end
                        end
                    end
                end

                if hungerVal <= (Settings.EatThreshold or 70) then
                     -- Use Heal settings for food and speed
                     local fruitName = Settings.EatFruit or "Bloodfruit"
                     local fruitID = resolveHealFruitItemId(fruitName)
                     
                     if fruitID and mainGui then
                         local rightPanel = mainGui:FindFirstChild("RightPanel")
                         local inventory = rightPanel and rightPanel:FindFirstChild("Inventory")
                         local list = inventory and inventory:FindFirstChild("List")
                         
                         local slotID = nil
                         if list then
                             for _, item in ipairs(list:GetChildren()) do
                                 if item:IsA("ImageLabel") and item.Name == fruitName then
                                     slotID = item.LayoutOrder
                                     break
                                 end
                             end
                         end
                         
                         if slotID then 
                             pcall(function()
                                 local actionId = getPacketId("UseBagItem")
                                 local b = buffer.create(8)
                                 buffer.writeu8(b, 0, 0)
                                 buffer.writeu8(b, 1, actionId)
                                 buffer.writeu32(b, 2, slotID)
                                 buffer.writeu16(b, 6, fruitID)
                                 if ByteNetReliable then ByteNetReliable:FireServer(b) end
                             end)
                             local delayTime = 1 / (Settings.HealCPS or 1)
                             task.wait(delayTime)
                         else
                             -- Item not found in bag
                             task.wait(1)
                         end
                     else
                         task.wait(1)
                     end
                else
                     task.wait(0.5)
                end
            else
                task.wait(1)
            end
        end
        autoEatActive = false
    end)
end

-- // CHEST SLOTS PERSISTENCE (workspace/Paid.txt) // --

end -- AsterPreTabInit

-- ============================================================
-- TABS + FUNCIONES (Auto Eat / Waste Fruits / Auto Fuel / Tools & Aura)
-- ============================================================
do -- ASTER_MyTabs

-- [[ AUTO FUEL (version por menu): toca los botones del menu de la fogata ]] --
local _fuelGuiActive = false
local function _fuelGuiVisible(o)
    local pg = plr:FindFirstChild("PlayerGui")
    local p = o
    while p and p ~= pg do
        if p:IsA("GuiObject") and not p.Visible then return false end
        if p:IsA("ScreenGui") and not p.Enabled then return false end
        p = p.Parent
    end
    return p == pg
end
local function _fuelClick(btn)
    local fired = false
    for _, sig in ipairs({"Activated", "MouseButton1Click", "MouseButton1Down", "MouseButton1Up"}) do
        if getconnections then
            local ok, conns = pcall(getconnections, btn[sig])
            if ok and type(conns) == "table" and #conns > 0 then
                for _, c in ipairs(conns) do pcall(function() c:Fire() end) end
                fired = true
                break
            end
        end
    end
    if not fired and firesignal then
        pcall(function() firesignal(btn.Activated) end)
        pcall(function() firesignal(btn.MouseButton1Click) end)
    end
end
local function _nearestCampfire(maxDist)
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    local dep = getWorkspaceDeployables()
    if not hrp or not dep then return nil end
    local best, bd
    for _, v in ipairs(dep:GetChildren()) do
        if v.Name == "Campfire" then
            local p = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
            if p then
                local d = (p.Position - hrp.Position).Magnitude
                if not bd or d < bd then best, bd = v, d end
            end
        end
    end
    if not best or bd > (maxDist or 40) then return nil end
    return best, bd
end
local function _campfireFuel(fire)
    if not fire then return nil end
    for _, d in ipairs(fire:GetDescendants()) do
        if d:IsA("TextLabel") then
            local n = tonumber(d.Text)
            if n then return n end
        end
    end
    return nil
end
local function _aviso(t)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = "AutoFuel", Text = tostring(t):sub(1, 200), Duration = 12})
    end)
end
local _fuelInfoShown = false
-- Abre el menu de la fogata mandando el mismo paquete corto que manda el juego al tocarla
-- (InteractStructure con solo el ID de la fogata). NO simula toques en pantalla.
local function _openCampfireMenu(fire)
    local cd
    for _, d in ipairs(fire:GetDescendants()) do
        if d:IsA("ClickDetector") then cd = d break end
    end
    if cd and fireclickdetector then
        pcall(fireclickdetector, cd)
        return
    end
    local eid = fire:GetAttribute("EntityID")
    local pid = getPacketId("InteractStructure")
    if not _fuelInfoShown then
        _fuelInfoShown = true
        _aviso("Abriendo fogata: EntityID=" .. tostring(eid) .. " paquete=" .. tostring(pid))
    end
    if eid and pid and ByteNetReliable then
        local b = buffer.create(6)
        buffer.writeu8(b, 0, 0)
        buffer.writeu8(b, 1, pid)
        buffer.writeu32(b, 2, eid)
        ByteNetReliable:FireServer(b)
    end
end
local function _pickFuelItem()
    local want = Settings.FuelType or "All (Wood/Log/Leaves)"
    local names = (want:sub(1, 3) == "All") and {"Wood", "Log", "Leaves"} or {want}
    for _, n in ipairs(names) do
        if getlayout(n) then
            local id = resolveHealFruitItemId(n) or (fueltoitemid and fueltoitemid[n])
            if id then return id, n end
        end
    end
    return nil
end
function startAutoFuel()
    if _fuelGuiActive then return end
    _fuelGuiActive = true
    task.spawn(function()
        local lastOpen = 0
        local sessionFire, sessionStart = nil, 0
        local directBad = 0
        local handlers, handlerBad, handlerInfo = {}, 0, false
        while Settings.AutoFuelEnabled do
            pcall(function()
                local gui = plr.PlayerGui:FindFirstChild("Campfire")
                local frame = gui and gui:FindFirstChild("Frame")
                local list = frame and frame:FindFirstChild("List")
                local fire, dist = _nearestCampfire(40)
                local fuel = _campfireFuel(fire)
                local threshold = Settings.FuelThreshold or 200
                local needsFuel = (fuel == nil) or (fuel < threshold)
                local visibleNow = list and _fuelGuiVisible(list)

                -- memorizar la funcion de cada boton mientras el menu esta visible
                if visibleNow and list then
                    for _, b in ipairs(list:GetChildren()) do
                        if b:IsA("GuiButton") and b.Name ~= "Exit" and not handlers[b.Name] then
                            pcall(function()
                                local conns = getconnections(b.Activated)
                                local f = conns[1] and conns[1].Function
                                if not f then return end
                                local st
                                for _, v in pairs(debug.getupvalues(f)) do
                                    if type(v) == "table" and rawget(v, "selectionTarget") ~= nil then st = v break end
                                end
                                if st then
                                    handlers[b.Name] = {f = f, st = st, kind = typeof(st.selectionTarget) == "Instance" and st.selectionTarget.ClassName or "?"}
                                    if not handlerInfo then
                                        handlerInfo = true
                                        _aviso("Memorizado boton " .. b.Name .. " (target: " .. handlers[b.Name].kind .. ")")
                                    end
                                end
                            end)
                        end
                    end
                end

                -- MODO FUNCION: usa la funcion memorizada del boton, sin abrir el menu
                if Settings.AutoFuelDirect and handlerBad < 3 and fire and dist <= 33 and needsFuel and fuel ~= nil and not visibleNow then
                    local want = Settings.FuelType or "All (Wood/Log/Leaves)"
                    local names = (want:sub(1, 3) == "All") and {"Wood", "Log", "Leaves"} or {want}
                    for _, n in ipairs(names) do
                        local h = handlers[n]
                        if h and getlayout(n) then
                            local target = fire
                            if h.kind ~= "Model" and h.kind ~= "Folder" then
                                target = fire.PrimaryPart or fire:FindFirstChildWhichIsA("BasePart") or fire
                            end
                            h.st.selectionTarget = target
                            pcall(h.f)
                            task.wait(0.45)
                            local after = _campfireFuel(fire)
                            if after and after > fuel then
                                handlerBad = 0
                            else
                                handlerBad = handlerBad + 1
                                if handlerBad >= 3 then _aviso("Modo funcion no sube el combustible: pruebo otros metodos") end
                            end
                            return
                        end
                    end
                end

                -- MODO DIRECTO: paquete InteractStructure(entityID, itemID), sin abrir el menu
                if Settings.AutoFuelDirect and directBad < 3 and fire and dist <= 33 and needsFuel and fuel ~= nil and not visibleNow then
                    local eid = fire:GetAttribute("EntityID")
                    local itemId = _pickFuelItem()
                    local pid = getPacketId("InteractStructure")
                    if eid and itemId and pid and ByteNetReliable then
                        local b = buffer.create(8)
                        buffer.writeu8(b, 0, 0)
                        buffer.writeu8(b, 1, pid)
                        buffer.writeu32(b, 2, eid)
                        buffer.writeu16(b, 6, itemId)
                        ByteNetReliable:FireServer(b)
                        task.wait(0.45)
                        local after = _campfireFuel(fire)
                        if after and after > fuel then
                            directBad = 0
                        else
                            directBad = directBad + 1
                            if directBad >= 3 then _aviso("Modo directo no sube el combustible: uso el menu") end
                        end
                        return
                    end
                end

                -- el menu se abrio (por nosotros o a mano): esconderlo si corresponde
                if visibleNow and gui and Settings.AutoFuelOpenMenu then
                    sessionFire, sessionStart = fire, os.clock()
                    if Settings.AutoFuelHideMenu then pcall(function() gui.Enabled = false end) end
                end

                local hiddenSession = (not visibleNow) and list and sessionFire ~= nil
                    and sessionFire == fire and (os.clock() - sessionStart) < 25
                local menuReady = visibleNow or hiddenSession

                if not menuReady then
                    if Settings.AutoFuelOpenMenu and fire and dist <= 14 and needsFuel and os.clock() - lastOpen > 1.5 then
                        lastOpen = os.clock()
                        _openCampfireMenu(fire)
                    end
                    return
                end

                if not needsFuel then
                    local exit = list.Parent:FindFirstChild("Exit") or list:FindFirstChild("Exit")
                    if exit and Settings.AutoFuelOpenMenu then _fuelClick(exit) end
                    sessionFire = nil
                    if gui and Settings.AutoFuelHideMenu then pcall(function() gui.Enabled = false end) end
                    return
                end
                local want = Settings.FuelType or "All (Wood/Log/Leaves)"
                for _, b in ipairs(list:GetChildren()) do
                    if b:IsA("GuiButton") and b.Name ~= "Exit" then
                        if want:sub(1, 3) == "All" or b.Name:lower() == want:lower() then
                            _fuelClick(b)
                        end
                    end
                end
            end)
            task.wait(0.15)
        end
        _fuelGuiActive = false
    end)
end

updateLoadingStep()
ASTER.Tabs = {}
ASTER.Tabs.Combat = Window:AddTab({Title = "Combat / PvP", Icon = "rbxassetid://10734975692"})
ASTER.Tabs.Automation = Window:AddTab({Title = "Automation", Icon = "rbxassetid://98315335875448"})

-- Listas de frutas para los dropdowns
ASTER.Options.HealList = {}
for n, _ in pairs(healFruitData) do
    table.insert(ASTER.Options.HealList, n)
end
table.sort(ASTER.Options.HealList)

ASTER.Options.AllFruitList = {}
for _, name in ipairs(ALL_HEAL_FRUIT_NAMES or {}) do
    table.insert(ASTER.Options.AllFruitList, name)
end
table.sort(ASTER.Options.AllFruitList)

-- [[ COMBAT TAB: Auto Eat + Waste Fruits ]] --
-- Valores por defecto: Auto Eat y Waste Fruits activados
Settings.AutoEatEnabled = true
Settings.EatFruit = "Bluefruit"
Settings.EatThreshold = 1
Settings.WasteFruitsEnabled = true
Settings.EatCapEnabled = true
Settings.WasteFruit = "Bluefruit"
Settings.FruitsCapAmount = 100
Settings.EatCap = 100
local _wasteLoopOn = false
local function _startWasteOnce()
    if _wasteLoopOn then return end
    _wasteLoopOn = true
    startEatCap()
end

ASTER.Tabs.Combat:AddLabel("Auto Eat")
ASTER.Tabs.Combat:AddToggle("Auto Eat", true, function(v)
    Settings.AutoEatEnabled = v
    if v then startAutoEat() end
end)
ASTER.Tabs.Combat:AddDropdown("Eat Fruit", ASTER.Options.HealList, "Bluefruit", function(v)
    Settings.EatFruit = v
end)
ASTER.Tabs.Combat:AddSlider("Eat Threshold %", 1, 99, 1, 1, function(v)
    Settings.EatThreshold = v
end)

ASTER.Tabs.Combat:AddLabel("Waste Fruits")
ASTER.Tabs.Combat:AddToggle("Waste Fruits", true, function(v)
    Settings.WasteFruitsEnabled = v
    Settings.EatCapEnabled = v
    if v then _startWasteOnce() else _wasteLoopOn = false end
end)
ASTER.Tabs.Combat:AddDropdown("Waste Fruit", ASTER.Options.AllFruitList, "Bluefruit", function(v)
    Settings.WasteFruit = v
end)
ASTER.Tabs.Combat:AddInput("FruitsCap Amount", "100", function(v)
    local n = tonumber(v) or 100
    Settings.FruitsCapAmount = n
    Settings.EatCap = n
end)

-- [[ AUTOMATION TAB: Tools & Aura + Fuel ]] --
ASTER.Tabs.Automation:AddLabel("Tools & Aura")
ASTER.Tabs.Automation:AddToggle("Gold AutoTool Equip", false, function(v)
    Settings.GoldAutoEquip = v == true
    if v then
        startGoldEquipManager()
    end
end)
local hoeOptions = { "Wood Hoe", "God Hoe", "Crystal Hoe" }
local hoeDefault = Settings.GoldHoeType or "Wood Hoe"
local hoeListed = false
for _, h in ipairs(hoeOptions) do
    if h == hoeDefault then hoeListed = true break end
end
if not hoeListed then hoeDefault = "Wood Hoe" end
ASTER.Tabs.Automation:AddDropdown("Select Hoe", hoeOptions, hoeDefault, function(v)
    Settings.GoldHoeType = v
end)
setupToolsAuraUI(ASTER.Tabs.Automation)

ASTER.Tabs.Automation:AddLabel("Fuel / Utilities")
Settings.AutoFuelOpenMenu = true
Settings.AutoFuelHideMenu = true
Settings.AutoFuelDirect = true
ASTER.Tabs.Automation:AddToggle("Fuel Direct (sin menu)", true, function(v)
    Settings.AutoFuelDirect = v
end)
ASTER.Tabs.Automation:AddToggle("Auto Open Campfire Menu", true, function(v)
    Settings.AutoFuelOpenMenu = v
end)
ASTER.Tabs.Automation:AddToggle("Hide Campfire Menu", true, function(v)
    Settings.AutoFuelHideMenu = v
end)
ASTER.Tabs.Automation:AddToggle("Auto Fuel Campfire", false, function(v)
    Settings.AutoFuelEnabled = v
    if v then startAutoFuel() end
end)
ASTER.Tabs.Automation:AddDropdown("Fuel Type", {"Wood", "Log", "Leaves", "Coal", "All (Wood/Log/Leaves)"}, "All (Wood/Log/Leaves)", function(v)
    Settings.FuelType = v
end)
ASTER.Tabs.Automation:AddSlider("Fuel Threshold", 0, 250, 200, 1, function(v)
    Settings.FuelThreshold = v
end)

-- [[ DIAGNOSTICO ]] --
ASTER.Tabs.Combat:AddLabel("Diagnostico")
ASTER.Tabs.Combat:AddButton("Probar Eat / Fuel / Waste", function()
    local function aviso(t)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Diag", Text = tostring(t):sub(1, 200), Duration = 25})
        end)
    end
    local ok, e = pcall(function()
        aviso("UseBagItem id: " .. tostring(getPacketId("UseBagItem")))
        aviso("InteractStructure id: " .. tostring(getPacketId("InteractStructure")))
        aviso("EquipItem id: " .. tostring(getPacketId("EquipItem")))
        aviso("Bloodfruit item id: " .. tostring(resolveHealFruitItemId("Bloodfruit")))
        aviso("Wood item id: " .. tostring(fueltoitemid and fueltoitemid["Wood"]))
        aviso("Wood en inventario (slot): " .. tostring(getlayout("Wood")))
        local mg = plr.PlayerGui:FindFirstChild("MainGui")
        aviso("MainGui existe: " .. tostring(mg ~= nil))
        local bars = mg and mg:FindFirstChild("Panels") and mg.Panels:FindFirstChild("Stats") and mg.Panels.Stats:FindFirstChild("Bars")
        local h = bars and bars:FindFirstChild("Hunger") and bars.Hunger:FindFirstChild("ValueLabel")
        aviso("Hambre leida: " .. tostring(h and h.Text))
        local dep = getWorkspaceDeployables()
        local n = 0
        if dep then
            for _, v in ipairs(dep:GetChildren()) do
                if v.Name == "Campfire" then n = n + 1 end
            end
        end
        aviso("Fogatas en el mapa: " .. n)
        aviso("ByteNetReliable: " .. tostring(ByteNetReliable ~= nil))
    end)
    if not ok then aviso("ERROR: " .. tostring(e)) end
end)

ASTER.Tabs.Combat:AddButton("Diagnostico 2: fogata y paquetes", function()
    local function aviso(t)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Diag2", Text = tostring(t):sub(1, 200), Duration = 30})
        end)
    end
    local ok, e = pcall(function()
        aviso("IDs: Use=" .. tostring(getPacketId("UseBagItem")) .. " Drop=" .. tostring(getPacketId("DropBagItem")) .. " Interact=" .. tostring(getPacketId("InteractStructure")) .. " EquipTool=" .. tostring(getPacketId("EquipTool")))
        -- guardar lista completa de paquetes en un archivo
        local lines = {}
        for name, id in pairs(PACKET_IDS or {}) do lines[#lines + 1] = tostring(id) .. " = " .. tostring(name) end
        table.sort(lines)
        pcall(function() writefile("ASTER_packets.txt", table.concat(lines, "\n")) end)
        aviso("Paquetes conocidos: " .. #lines .. " (guardados en ASTER_packets.txt)")
        aviso("Auto: Eat=" .. tostring(Settings.AutoEatEnabled) .. " Waste=" .. tostring(Settings.WasteFruitsEnabled) .. " Fuel=" .. tostring(Settings.AutoFuelEnabled) .. " Aura=" .. tostring(Settings.TurnOnAura))
        local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        local dep = getWorkspaceDeployables()
        local best, bd
        if dep and hrp then
            for _, v in ipairs(dep:GetChildren()) do
                if v.Name == "Campfire" then
                    local p = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
                    if p then
                        local d = (p.Position - hrp.Position).Magnitude
                        if not bd or d < bd then best, bd = v, d end
                    end
                end
            end
        end
        if not best then aviso("No encontre ninguna fogata cerca") return end
        local names = {}
        for _, c in ipairs(best:GetChildren()) do names[#names + 1] = c.Name end
        aviso("Fogata mas cercana a " .. math.floor(bd) .. " studs. Partes: " .. table.concat(names, ","))
        local board = best:FindFirstChild("Board")
        local bb = board and board:FindFirstChild("Billboard")
        local bk = bb and bb:FindFirstChild("Backdrop")
        local tl = bk and bk:FindFirstChild("TextLabel")
        aviso("Board=" .. tostring(board ~= nil) .. " Billboard=" .. tostring(bb ~= nil) .. " Backdrop=" .. tostring(bk ~= nil) .. " TextLabel=" .. tostring(tl and tl.Text))
        aviso("EntityID de la fogata: " .. tostring(best:GetAttribute("EntityID")))
    end)
    if not ok then aviso("ERROR: " .. tostring(e)) end
end)

ASTER.Tabs.Combat:AddButton("Grabar paquetes (20s)", function()
    local function aviso(t)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Grab", Text = tostring(t):sub(1, 200), Duration = 45})
        end)
    end
    local names = {}
    for name, id in pairs(PACKET_IDS or {}) do names[id] = name end
    local seen, total, recording = {}, 0, true
    local function log(self, a)
        if not recording then return end
        if typeof(self) ~= "Instance" then return end
        local nm = self.Name
        if nm:find("Position") or nm:find("Replication") then return end
        total = total + 1
        local key, d
        if typeof(a) == "buffer" then
            local bytes = {}
            for i = 0, math.min(buffer.len(a), 12) - 1 do bytes[#bytes + 1] = buffer.readu8(a, i) end
            local pn = names[bytes[2] or -1] or "?"
            key = nm .. "/" .. pn .. "/" .. buffer.len(a)
            d = pn .. " [" .. nm .. "] len " .. buffer.len(a) .. ": " .. table.concat(bytes, ",")
        else
            key = nm .. "/" .. typeof(a)
            d = nm .. " " .. typeof(a) .. " " .. tostring(a)
        end
        if seen[key] then seen[key].n = seen[key].n + 1 else seen[key] = {n = 1, d = d} end
    end
    local hooked = false
    pcall(function()
        local re = Instance.new("RemoteEvent")
        local old
        old = hookfunction(re.FireServer, function(self, ...)
            pcall(log, self, ...)
            return old(self, ...)
        end)
        hooked = true
    end)
    pcall(function()
        local rf = Instance.new("RemoteFunction")
        local old2
        old2 = hookfunction(rf.InvokeServer, function(self, ...)
            pcall(log, self, ...)
            return old2(self, ...)
        end)
    end)
    pcall(function()
        local ur = Instance.new("UnreliableRemoteEvent")
        local old3
        old3 = hookfunction(ur.FireServer, function(self, ...)
            pcall(log, self, ...)
            return old3(self, ...)
        end)
    end)
    if not hooked and hookmetamethod then
        pcall(function()
            local old
            old = hookmetamethod(game, "__namecall", function(self, ...)
                if getnamecallmethod() == "FireServer" then pcall(log, self, ...) end
                return old(self, ...)
            end)
            hooked = true
        end)
    end
    aviso("Grabando 20s (hook=" .. tostring(hooked) .. "). Toca la fogata y dale madera 2 veces.")
    task.delay(20, function()
        recording = false
        aviso("Total capturado: " .. total)
        local list = {}
        for _, e in pairs(seen) do list[#list + 1] = e end
        table.sort(list, function(x, y) return x.n < y.n end)
        for i = 1, math.min(#list, 10) do aviso("x" .. list[i].n .. " " .. list[i].d) end
        aviso("Fin. Tipos distintos: " .. #list)
    end)
end)

ASTER.Tabs.Combat:AddButton("Inspeccionar botones fogata", function()
    local function aviso(t)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Insp", Text = tostring(t):sub(1, 200), Duration = 60})
        end)
    end
    local function chunks(prefix, text)
        local i = 1
        while i <= #text do
            aviso(prefix .. text:sub(i, i + 150))
            i = i + 151
        end
    end
    local ok, e = pcall(function()
        local gui = plr.PlayerGui:FindFirstChild("Campfire")
        local list = gui and gui:FindFirstChild("Frame") and gui.Frame:FindFirstChild("List")
        if not list then aviso("No encuentro el menu: abri la fogata primero") return end
        local btn = list:FindFirstChild("Wood")
        if not btn then aviso("No hay boton Wood") return end
        local conns = getconnections(btn.Activated)
        local f = conns[1] and conns[1].Function
        if not f then aviso("sin funcion") return end
        local strs = {}
        for _, k in ipairs(debug.getconstants(f)) do
            if type(k) == "string" then strs[#strs + 1] = k end
        end
        chunks("STR: ", table.concat(strs, " | "))
        for idx, v in pairs(debug.getupvalues(f)) do
            if type(v) == "table" then
                local keys = {}
                local n = 0
                for k, val in pairs(v) do
                    n = n + 1
                    if n <= 12 then keys[#keys + 1] = tostring(k) .. ":" .. typeof(val) end
                end
                chunks("UP" .. idx .. " tabla: ", table.concat(keys, ", "))
            end
        end
    end)
    if not ok then aviso("ERROR: " .. tostring(e)) end
end)

-- arrancar Auto Eat y Waste Fruits ya activados
task.defer(function()
    if Settings.AutoEatEnabled then startAutoEat() end
    if Settings.WasteFruitsEnabled then _startWasteOnce() end
end)

-- [[ HUD: tiempo, FPS, Oro y Bluefruit ]] --
do
    local hudGui = Instance.new("ScreenGui")
    hudGui.Name = "ASTER_HUD"
    hudGui.ResetOnSpawn = false
    hudGui.DisplayOrder = 50
    hudGui.Parent = getAsterHiddenUI()
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 170, 0, 92)
    frame.Position = UDim2.new(0, 12, 0.42, 0)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    frame.BackgroundTransparency = 0.25
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = hudGui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(150, 110, 255)
    stroke.Thickness = 1.2
    stroke.Parent = frame
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -12, 1, -8)
    label.Position = UDim2.new(0, 8, 0, 4)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(235, 225, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Text = "..."
    label.Parent = frame

    -- arrastrable
    local dragging, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging, dragStart, startPos = true, input.Position, frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)

    -- FPS
    local frames, fps = 0, 0
    game:GetService("RunService").RenderStepped:Connect(function() frames = frames + 1 end)
    local t0 = os.clock()
    local fpsT = os.clock()
    local function fmtTime(sec)
        sec = math.floor(sec)
        return string.format("%02d:%02d:%02d", math.floor(sec / 3600), math.floor(sec / 60) % 60, sec % 60)
    end
    local function count(name)
        local ok, slot, n = pcall(getInventorySlotAndCount, name)
        if ok and slot then return n or 0 end
        return 0
    end
    local function fmtNum(n)
        local s = tostring(math.floor(n))
        local out = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
        if out:sub(1, 1) == "." then out = out:sub(2) end
        return out
    end
    task.spawn(function()
        while hudGui.Parent do
            local now = os.clock()
            if now - fpsT >= 1 then
                fps = math.floor(frames / (now - fpsT) + 0.5)
                frames, fpsT = 0, now
            end
            pcall(function()
                label.Text = "Tiempo: " .. fmtTime(now - t0)
                    .. "\nFPS: " .. fps
                    .. "\nOro: " .. fmtNum(count("Gold"))
                    .. "\nBluefruit: " .. fmtNum(count("Bluefruit"))
            end)
            task.wait(0.5)
        end
    end)
    Settings.ShowHUD = true
    ASTER.Tabs.Automation:AddToggle("Show HUD (tiempo/FPS/items)", true, function(v)
        Settings.ShowHUD = v
        hudGui.Enabled = v
    end)
end
end -- ASTER_MyTabs

do -- AsterFinalize
-- // 24/7 ANTI-AFK // --
trackConnection("antiAfk_Idled", game:GetService("Players").LocalPlayer.Idled:Connect(function()
    pcall(function()
        game:GetService("VirtualUser"):CaptureController()
        game:GetService("VirtualUser"):ClickButton2(Vector2.new())
    end)
end))

-- Final Refresh
    pcall(function()
        Window:UpdateTheme(Themes.Premium)
        Window_ApplyMobileLayout()
        Window_ApplyCompactMode()
        setBreadcrumb("Combat / PvP")
        if ASTER.Tabs.Combat and ASTER.Tabs.Combat.Page then
            ASTER.Tabs.Combat.Page.Visible = true
            updateTabVisuals(ASTER.Tabs.Combat, true)
        end
        updateLoadingStep()
        if ASTER.ToggleBind and ASTER.ToggleBind.finishInit then
            ASTER.ToggleBind.finishInit()
        end
        -- Ensure tab pages can actually display built controls (two-column layout).
        for _, t in pairs(Window.Tabs or {}) do
            if t and t.PageScroll then
                local left = t.PageScroll:FindFirstChild("LeftColumn")
                local right = t.PageScroll:FindFirstChild("RightColumn")
                if left then left.AutomaticSize = Enum.AutomaticSize.Y end
                if right then right.AutomaticSize = Enum.AutomaticSize.Y end
                t.PageScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                for _, d in ipairs(t.PageScroll:GetDescendants()) do
                    if d:GetAttribute("IsSectionCard") then
                        d.ClipsDescendants = false
                        d.AutomaticSize = Enum.AutomaticSize.Y
                    end
                end
                local lh = left and left:FindFirstChildOfClass("UIListLayout")
                local rh = right and right:FindFirstChildOfClass("UIListLayout")
                local tallest = math.max(
                    lh and lh.AbsoluteContentSize.Y or 0,
                    rh and rh.AbsoluteContentSize.Y or 0,
                    left and left.AbsoluteSize.Y or 0,
                    right and right.AbsoluteSize.Y or 0
                )
                t.PageScroll.CanvasSize = UDim2.new(0, 0, 0, math.max(tallest + 24, 400))
            end
        end
        task.defer(function()
            for _, t in pairs(Window.Tabs or {}) do
                if t and t.PageScroll then
                    local left = t.PageScroll:FindFirstChild("LeftColumn")
                    local right = t.PageScroll:FindFirstChild("RightColumn")
                    local lh = left and left:FindFirstChildOfClass("UIListLayout")
                    local rh = right and right:FindFirstChildOfClass("UIListLayout")
                    local tallest = math.max(
                        lh and lh.AbsoluteContentSize.Y or 0,
                        rh and rh.AbsoluteContentSize.Y or 0,
                        left and left.AbsoluteSize.Y or 0,
                        right and right.AbsoluteSize.Y or 0
                    )
                    if tallest > 0 then
                        t.PageScroll.CanvasSize = UDim2.new(0, 0, 0, tallest + 24)
                    end
                end
            end
        end)
    end)


-- // UI KEYBIND LISTENER // --
trackConnection("uiKeybind_InputBegan", game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- Ignore while typing in ASTER text fields (search, UI keybind input, etc.)
    local focused = UserInputService:GetFocusedTextBox()
    if focused and screenGui and focused:IsDescendantOf(screenGui) then return end
    
    local keyName = input.KeyCode.Name
    local bind = Settings.Keybind
    if not bind or bind == "" then return end
    local lowerBind = tostring(bind):lower()
    local lowerKey = keyName:lower()
    
    -- Direct Match (Case Insensitive)
    if lowerKey == lowerBind then
        if Window.ToggleGUI then Window.ToggleGUI(true) end
        return
    end

    -- Alias Handling (ctrl, rctrl, alt, ralt, shift, rshift)
    if (lowerBind == "ctrl" and keyName == "LeftControl") or
       (lowerBind == "rctrl" and keyName == "RightControl") or
       (lowerBind == "alt" and keyName == "LeftAlt") or
       (lowerBind == "ralt" and keyName == "RightAlt") or
       (lowerBind == "shift" and keyName == "LeftShift") or
       (lowerBind == "rshift" and keyName == "RightShift") then
        
        if Window.ToggleGUI then Window.ToggleGUI(true) end
    end
end))

end -- AsterFinalize
