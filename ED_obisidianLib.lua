local S = function(n)
    local s = game:GetService(n)
    return cloneref and cloneref(s) or s
end

local GAME_IDS = { 3927488489, 5927366432, 6023940812 }
local PLACE_IDS =
    { 10891480658, 16810788519, 17324650150, 17639491565, 17594182379 }
if
    not (
        table.find(GAME_IDS, game.GameId) and table.find(
            PLACE_IDS,
            game.PlaceId
        )
    )
then
    return
end

local pOLD, pEPIC, pREN, pEMARC, pCLASS =
    10891480658, 16810788519, 17324650150, 17639491565, 17594182379

local Players = S('Players')
local TweenService = S('TweenService')
local RunService = S('RunService')
local UIS = S('UserInputService')
local PPromptService = S('ProximityPromptService')
local SoundService = S('SoundService')

local LocalPlayer = Players.LocalPlayer

local IsOnMobile = (function()
    local platform = UIS:GetPlatform()
    if
        platform == Enum.Platform.IOS
        or platform == Enum.Platform.Android
        or platform == Enum.Platform.AndroidTV
        or platform == Enum.Platform.Chromecast
        or platform == Enum.Platform.MetaOS
    then
        return true
    end
    if platform == Enum.Platform.None then
        return UIS.TouchEnabled
            and not (UIS.KeyboardEnabled or UIS.MouseEnabled)
    end
    return false
end)()

local GameFolder = workspace:WaitForChild('Game')
local Values = GameFolder:WaitForChild('Values')
local Rooms = GameFolder:WaitForChild('Rooms')
local Entities = GameFolder:WaitForChild('Entities')

local currentCamera = workspace.CurrentCamera

local brightLoop, antiAFKConn, fovLockConn, cameraConn, infJumpConn, mobHoldConn, mobDownConn, mobUpConn
local overCon, lurkCon, watchCon, flowCon, abyssCon, takerCon, chaseCon

local greedActive = false
local decalID = 95434351872718

local scriptRunning = true
local activeConnections = {}

local function trackConnection(conn)
    if conn then
        activeConnections[#activeConnections + 1] = conn
    end
    return conn
end

getgenv().speed = tonumber(getgenv().speed) or 16
getgenv().jump = tonumber(getgenv().jump) or 30
getgenv().fov = tonumber(getgenv().fov) or 70

local function GuiRoot()
    return (gethui and gethui())
        or S('CoreGui'):FindFirstChild('RobloxGui')
        or S('CoreGui')
        or LocalPlayer:WaitForChild('PlayerGui')
end

if not game:IsLoaded() then
    local m = Instance.new('Message', GuiRoot())
    m.Text = 'waiting for the game to load'
    game.Loaded:Wait()
    m:Destroy()
end

local function rootOf(c)
    if c:IsA('Player') then
        c = c.Character
    end
    return c
        and (
            c:FindFirstChild('HumanoidRootPart')
            or c:FindFirstChild('UpperTorso')
            or c:FindFirstChild('Torso')
            or c:FindFirstChild('LowerTorso')
            or c:FindFirstChildWhichIsA('BasePart')
        )
end

local function charValStr(ctn, nm)
    local ch = LocalPlayer.Character
    local o = ch and ch:FindFirstChild(ctn) and ch[ctn]:FindFirstChild(nm)
    return o and tostring(o.Value)
end

local function tpToDoor()
    local r = Rooms:FindFirstChild('Room' .. Values.RoomsNumber.Value)
    if r and r:FindFirstChild('Door') then
        LocalPlayer.Character:PivotTo(r.Door:GetPivot())
    end
end

local function tpToKey()
    local ch = LocalPlayer.Character
    local hk = ch
        and ch:FindFirstChild('Values')
        and ch.Values:FindFirstChild('HasKey')
    if hk and hk.Value then
        return
    end
    local r = Rooms:FindFirstChild('Room' .. Values.RoomsNumber.Value)
    if not r then
        return
    end
    for _, d in ipairs(r:GetDescendants()) do
        if
            d:IsA('BasePart')
            and d.Name:lower() == 'roomkey'
            and d.Parent.Name:lower() ~= 'door'
        then
            LocalPlayer.Character:PivotTo(d:GetPivot())
            break
        end
    end
end

local function tpToLever()
    local r = Rooms:FindFirstChild('Room' .. Values.RoomsNumber.Value)
    if not r then
        return
    end
    for _, d in ipairs(r:GetDescendants()) do
        if
            (d:IsA('BasePart') or d:IsA('Model'))
            and d.Name:lower() == 'gatelever'
        then
            LocalPlayer.Character:PivotTo(d:GetPivot())
            break
        end
    end
end

local function disableRagdoll()
    local t = LocalPlayer.Character:FindFirstChild('RagdollTrigger')
    if t then
        t.Value = false
    end
end

local function bindFOV(cam)
    if fovLockConn then
        fovLockConn:Disconnect()
        fovLockConn = nil
    end
    cam.FieldOfView = tonumber(getgenv().fov) or 70
    fovLockConn = trackConnection(
        cam:GetPropertyChangedSignal('FieldOfView'):Connect(function()
            if
                getgenv().wide
                and cam.FieldOfView ~= (tonumber(getgenv().fov) or 70)
            then
                cam.FieldOfView = tonumber(getgenv().fov) or 70
            end
        end)
    )
end

local PLACE_NAME = ({
    [pOLD] = 'Endless Doors [OLD]',
    [pEPIC] = 'Endless Doors [OLD Epic Mode]',
    [pREN] = 'Endless Doors',
    [pEMARC] = 'Endless Doors [Epic Mode]',
    [pCLASS] = 'Endless Doors [Retro #classic]',
})[game.PlaceId] or 'unknown'
local TITLE = PLACE_NAME .. (IsOnMobile and ' | Mobile ' or ' ') .. 'v2.2'

local function playerRoom()
    return tostring(LocalPlayer.leaderstats.Room.Value)
end
local function playerBits()
    return tostring(LocalPlayer.leaderstats.Bits.Value)
end
local function doubleBits()
    return tostring(LocalPlayer.Character.Values.DoubleBits.Value)
end
local function fame()
    return tostring(LocalPlayer.Fame.Value)
end
local function deaths()
    return tostring(LocalPlayer.Deaths.Value)
end
local function rift()
    return tostring(LocalPlayer.Rift.Value)
end
local function inGroup()
    return tostring(LocalPlayer.JoinedGroup.Value)
end
local function curRoom()
    return tostring(Values.RoomsNumber.Value)
end
local function phil()
    return tostring(Values.PhilMeter.Value)
end
local function spider()
    return tostring(Values.SpiderChance.Value)
end
local function revivePrice()
    return tostring(Values.RevivePrice.Value)
end
local function alive()
    return tostring(Values.PlayersAlive.Value)
end
local function inGame()
    return tostring(Values.PlayersInGame.Value)
end
local function fuz()
    return charValStr('Collectibles', 'Fuzzi')
end
local function zav()
    return charValStr('Collectibles', 'Zav')
end
local function jake()
    return charValStr('Collectibles', 'Jake')
end
local function blue()
    return charValStr('Collectibles', 'Blue')
end
local function alan()
    return charValStr('Collectibles', 'Alan')
end

local function getBasePart(o)
    if o:IsA('BasePart') then
        return o
    end
    if o:IsA('Model') then
        if o.PrimaryPart then
            return o.PrimaryPart
        end
        return o:FindFirstChildWhichIsA('BasePart')
    end
end

local function CreateESP(target, color, label)
    local base = getBasePart(target)
    if not base then
        return
    end
    local bc = color or Color3.new(1, 0, 0)
    local h, s, v = Color3.toHSV(bc)
    local dark = Color3.fromHSV(h, s, math.clamp(v - 0.5, 0, 1))
    local lite = Color3.fromHSV(h, s, math.clamp(v + 0.5, 0, 1))
    local box = Instance.new('BoxHandleAdornment')
    box.Name = target.Name:lower() .. '_ESP'
    box.Adornee = base
    box.Parent = target
    box.AlwaysOnTop = true
    box.ZIndex = 0
    box.Transparency = 0.45
    box.Color3 = lite
    if target:IsA('Model') then
        local _, sz = target:GetBoundingBox()
        box.Size = sz + Vector3.new(0.1, 0.1, 0.1)
    else
        box.Size = base.Size + Vector3.new(0.1, 0.1, 0.1)
    end
    local tw = TweenService:Create(
        box,
        TweenInfo.new(
            1,
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.InOut,
            math.huge,
            true
        ),
        { Color3 = dark }
    )
    tw:Play()
    local bb = Instance.new('BillboardGui')
    bb.Name = target.Name:lower() .. '_LABEL'
    bb.Parent = target
    bb.Adornee = base
    bb.Size = UDim2.new(0, 100, 0, 30)
    bb.StudsOffset = Vector3.new(0, box.Size.Y / 2 + 0.2, 0)
    bb.AlwaysOnTop = true
    bb.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local tl = Instance.new('TextLabel')
    tl.Parent = bb
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Font = Enum.Font.SourceSansBold
    tl.Text = label or target.Name
    tl.TextSize = 14
    tl.TextColor3 = Color3.new(1, 1, 1)
    tl.TextStrokeTransparency = 0.5
    local grad = Instance.new('UIGradient')
    grad.Color = ColorSequence.new(dark, lite)
    grad.Parent = tl
    local rs
    rs = RunService.RenderStepped:Connect(function()
        if not box.Parent then
            tw:Cancel()
            rs:Disconnect()
            return
        end
        local r = rootOf(LocalPlayer.Character)
        if r then
            local d = (r.Position - base.Position).Magnitude
            tl.Text = string.format('%s | %.1f', label or target.Name, d)
        end
    end)
    return box
end

local function RemoveESP(p)
    pcall(function()
        for _, c in ipairs(p:GetChildren()) do
            if
                c:IsA('BoxHandleAdornment')
                or c:IsA('BillboardGui')
                or c:IsA('Highlight')
            then
                c:Destroy()
            end
        end
    end)
end

trackConnection(PPromptService.PromptButtonHoldBegan:Connect(function(p)
    task.defer(function()
        fireproximityprompt(p)
    end)
end))

local junk = {
    fdmg = true,
    brokenlamp = true,
    longcrate = true,
    crate = true,
    chair = true,
    sofa = true,
    fire = true,
}
task.spawn(function()
    repeat
        task.wait()
    until LocalPlayer.Character
    task.wait(2)
    for _, d in ipairs(game:GetDescendants()) do
        if junk[d.Name:lower()] then
            task.defer(function()
                if d and d.Parent then
                    d:Destroy()
                end
            end)
        end
    end
end)

task.spawn(function()
    if game.PlaceId == pREN then
        while scriptRunning do
            disableRagdoll()
            task.wait()
        end
    end
end)

trackConnection(workspace.DescendantAdded:Connect(function(o)
    if junk[o.Name:lower()] then
        task.defer(function()
            if o and o.Parent then
                o:Destroy()
            end
        end)
    end
end))

task.spawn(function()
    local function setAutoJump(h)
        if h then
            h.AutoJumpEnabled = false
        end
    end
    setAutoJump(
        LocalPlayer.Character
            and LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid')
    )
    trackConnection(LocalPlayer.CharacterAdded:Connect(function(ch)
        setAutoJump(ch:WaitForChild('Humanoid', 5))
    end))
end)

local function resolveHolder(inst)
    if not inst then
        return nil
    end
    local p = inst.Parent
    if p and (p:IsA('Model') or p:IsA('BasePart')) then
        return p
    end
    local mdl = inst:FindFirstAncestorOfClass('Model')
    if mdl then
        return mdl
    end
    local bp = inst:FindFirstAncestorOfClass('BasePart')
    if bp then
        return bp
    end
    return p
end

local function resolveDistancePart(inst)
    local h = resolveHolder(inst)
    if not h then
        return nil
    end
    if h:IsA('Model') then
        if h.PrimaryPart then
            return h.PrimaryPart
        end
        return h:FindFirstChildWhichIsA('BasePart', true)
    end
    return h
end

local function holderName(inst)
    local h = resolveHolder(inst)
    return (h and h.Name) or 'unknown'
end

local proximityPrompts = {}
local function onPPAdded(o)
    proximityPrompts[#proximityPrompts + 1] = o
end
local function onPPRemoved(o)
    for i, v in ipairs(proximityPrompts) do
        if v == o then
            table.remove(proximityPrompts, i)
            break
        end
    end
end
for _, o in ipairs(workspace:GetDescendants()) do
    if o:IsA('ProximityPrompt') then
        onPPAdded(o)
    end
end
trackConnection(workspace.DescendantAdded:Connect(function(o)
    if o:IsA('ProximityPrompt') then
        onPPAdded(o)
    end
end))
trackConnection(workspace.DescendantRemoving:Connect(function(o)
    if o:IsA('ProximityPrompt') then
        onPPRemoved(o)
    end
end))

local lastHandle = 0
local selectedPromptNames = {}
local selectedPromptDisplay = {}

local function addSelectionName(name)
    if typeof(name) ~= 'string' then
        return
    end
    local trimmed = name:gsub('^%s+', ''):gsub('%s+$', '')
    if trimmed == '' or trimmed == 'None' then
        return
    end
    local key = trimmed:lower()
    selectedPromptNames[key] = true
    selectedPromptDisplay[key] = trimmed
end

local function clearSelection()
    for k in pairs(selectedPromptNames) do
        selectedPromptNames[k] = nil
    end
    for k in pairs(selectedPromptDisplay) do
        selectedPromptDisplay[k] = nil
    end
end

local function selectionEmpty()
    return next(selectedPromptNames) == nil
end

local function currentSelectionList()
    local list = {}
    for _, display in pairs(selectedPromptDisplay) do
        list[#list + 1] = display
    end
    table.sort(list)
    return list
end

local function selectionDictionary()
    local dict = {}
    for _, display in pairs(selectedPromptDisplay) do
        dict[display] = true
    end
    return dict
end

local function updateModeLabelText()
    if not modeLabel then
        return
    end
    if selectionEmpty() then
        modeLabel:Set('Mode: Default (all prompts)')
    else
        local names = currentSelectionList()
        modeLabel:Set(
            'Mode: Selected holders only (' .. table.concat(names, ', ') .. ')'
        )
    end
end

local function applySelectionFromValue(value)
    clearSelection()
    if typeof(value) == 'table' then
        if value[1] ~= nil then
            for _, entry in ipairs(value) do
                addSelectionName(entry)
            end
        else
            for entry, state in pairs(value) do
                if state then
                    addSelectionName(entry)
                end
            end
        end
    elseif typeof(value) == 'string' then
        addSelectionName(value)
    end
    updateModeLabelText()
end

local function promptAllowed(pp)
    if not (pp and pp.Parent) then
        return false
    end
    if selectionEmpty() then
        return pp:IsA('ProximityPrompt') and pp.Name == 'ProximityPrompt'
    else
        if not pp:IsA('ProximityPrompt') then
            return false
        end
        local n = holderName(pp)
        return n and selectedPromptNames[n:lower()] or false
    end
end

local function firePrompts()
    local root = rootOf(LocalPlayer.Character)
    if not (root and root.Parent) then
        return
    end
    local bitsStat = LocalPlayer.leaderstats
        and LocalPlayer.leaderstats:FindFirstChild('Bits')
    for i = #proximityPrompts, 1, -1 do
        local pp = proximityPrompts[i]
        if not (pp and pp.Parent) then
            table.remove(proximityPrompts, i)
        else
            if promptAllowed(pp) then
                local hold = resolveHolder(pp)
                local bp = resolveDistancePart(pp)
                if bp then
                    local d = (root.Position - bp.Position).Magnitude
                    local rad = pp.MaxActivationDistance or 12
                    if d <= rad + 6 then
                        local nm = hold and hold.Name:lower() or ''
                        local skip = false
                        if hold then
                            for _, c in ipairs(hold:GetChildren()) do
                                if
                                    c:IsA('BoolValue')
                                    and c.Name:lower():find('greed')
                                    and c.Value
                                then
                                    skip = true
                                    break
                                end
                            end
                        end
                        if
                            not skip and not (nm == 'handle' and greedActive)
                        then
                            if
                                game.PlaceId == pEPIC
                                or game.PlaceId == pEMARC
                            then
                                local b = (bitsStat and bitsStat.Value) or 0
                                if (b >= 2500 and nm ~= 'bit') or b < 2500 then
                                    fireproximityprompt(pp)
                                end
                            elseif game.PlaceId == pCLASS then
                                if nm == 'handle' then
                                    local now = tick()
                                    if now - lastHandle >= 0.4 then
                                        fireproximityprompt(pp)
                                        lastHandle = now
                                    end
                                else
                                    fireproximityprompt(pp)
                                end
                            else
                                fireproximityprompt(pp)
                            end
                        end
                    end
                end
            end
        end
    end
end

local ObsidianRepo =
    'https://raw.githubusercontent.com/deividcomsono/Obsidian/main/'
local ObsidianLibrary =
    loadstring(game:HttpGet(ObsidianRepo .. 'Library.lua'))()
local ObsidianSaveManager =
    loadstring(game:HttpGet(ObsidianRepo .. 'addons/SaveManager.lua'))()
local ObsidianThemeManager =
    loadstring(game:HttpGet(ObsidianRepo .. 'addons/ThemeManager.lua'))()

local function sanitizeIdSegment(text)
    local str = typeof(text) == 'string' and text or tostring(text or '')
    str = str:gsub('%W', '')
    if str == '' then
        str = 'ctrl'
    end
    return str
end

local function copyArray(list)
    local new = {}
    if typeof(list) == 'table' then
        for i, v in ipairs(list) do
            new[i] = v
        end
    end
    return new
end

local function snapshotSelection(dict)
    local values = {}
    if typeof(dict) == 'table' then
        for key, enabled in pairs(dict) do
            if enabled then
                values[#values + 1] = key
            end
        end
    end
    table.sort(values, function(a, b)
        return tostring(a) < tostring(b)
    end)
    return values
end

local function toDictionary(list)
    local dict = {}
    if typeof(list) == 'table' then
        for _, value in ipairs(list) do
            if typeof(value) == 'string' then
                dict[value] = true
            end
        end
    end
    return dict
end

local function inferRounding(step)
    if typeof(step) ~= 'number' or step <= 0 then
        return 0
    end
    local decimals = tostring(step):match('%.(%d+)')
    return decimals and #decimals or 0
end

local function normalizeSoundId(value)
    if value == nil then
        return nil
    end
    local valueType = typeof(value)
    if valueType == 'number' then
        if value <= 0 then
            return nil
        end
        return string.format('rbxassetid://%d', value)
    elseif valueType == 'string' then
        local trimmed = value:match('^%s*(.-)%s*$')
        if trimmed == '' then
            return nil
        end
        if trimmed:match('^%d+$') then
            return 'rbxassetid://' .. trimmed
        end
        return trimmed
    end
    return nil
end

local ObsidianUI = {
    Library = ObsidianLibrary,
    SaveManager = ObsidianSaveManager,
    ThemeManager = ObsidianThemeManager,
    _configEnabled = false,
    _configName = nil,
    _isLoadingConfig = false,
    NotifySoundId = 'rbxassetid://8551372796',
    NotifySoundVolume = 2,
}

local function disconnectConn(conn)
    if conn then
        pcall(function()
            conn:Disconnect()
        end)
    end
end

function ObsidianUI:Cleanup()
    if self._cleaned then
        return
    end
    self._cleaned = true
    scriptRunning = false

    local tracked = {
        brightLoop,
        antiAFKConn,
        fovLockConn,
        cameraConn,
        infJumpConn,
        mobHoldConn,
        mobDownConn,
        mobUpConn,
        overCon,
        lurkCon,
        watchCon,
        flowCon,
        abyssCon,
        takerCon,
        chaseCon,
    }
    for _, conn in ipairs(tracked) do
        disconnectConn(conn)
    end
    brightLoop = nil
    antiAFKConn = nil
    fovLockConn = nil
    cameraConn = nil
    infJumpConn = nil
    mobHoldConn = nil
    mobDownConn = nil
    mobUpConn = nil
    overCon = nil
    lurkCon = nil
    watchCon = nil
    flowCon = nil
    abyssCon = nil
    takerCon = nil
    chaseCon = nil

    for _, conn in ipairs(activeConnections) do
        disconnectConn(conn)
    end
    activeConnections = {}

    getgenv().chaos = false
    getgenv().entityEsp = false
    getgenv().keyESP = false
    getgenv().bitESP = false
    getgenv().leverESP = false
    getgenv().batteryESP = false
    getgenv().remoteThingy = false
    getgenv().entityNotif = false
    getgenv().sped = false
    getgenv().jumpy = false
    getgenv().teletodoor = false
    getgenv().teletokey = false
    getgenv().teletolever = false

    pcall(function()
        for _, obj in ipairs(Entities:GetDescendants()) do
            RemoveESP(obj)
        end
        for _, obj in ipairs(Rooms:GetDescendants()) do
            RemoveESP(obj)
        end
    end)
end

local WindowMeta = {}
WindowMeta.__index = WindowMeta
local TabMeta = {}
TabMeta.__index = TabMeta
local LabelMeta = {}
LabelMeta.__index = LabelMeta
local DropdownMeta = {}
DropdownMeta.__index = DropdownMeta

function ObsidianUI:_setupConfig(config)
    if self.SaveManager and config and config.Enabled then
        self.SaveManager:SetLibrary(self.Library)
        self.SaveManager:IgnoreThemeSettings()
        self.SaveManager:SetFolder(config.FolderName or 'ObsidianConfigs')
        self.SaveManager:SetSubFolder(config.SubFolder or '')
        self._configEnabled = true
        self._configName = config.FileName or 'default'
    else
        self._configEnabled = false
        self._configName = nil
    end
    if self.ThemeManager then
        self.ThemeManager:SetLibrary(self.Library)
        self.ThemeManager:SetFolder(
            (config and config.FolderName) or 'ObsidianConfigs'
        )
    end
end

function ObsidianUI:_autoSave()
    if
        not (self._configEnabled and self._configName and self.SaveManager)
        or self._isLoadingConfig
    then
        return
    end
    local ok, err = self.SaveManager:Save(self._configName)
    if not ok and err then
        warn('[ObsidianCompat] Failed to save config:', err)
    end
end

function ObsidianUI:LoadConfiguration()
    if not (self._configEnabled and self._configName and self.SaveManager) then
        return
    end
    self._isLoadingConfig = true
    local ok = self.SaveManager:Load(self._configName)
    self._isLoadingConfig = false
    if not ok then
        self.SaveManager:Save(self._configName)
    end
end

function ObsidianUI:_playNotifySound(soundId, volume)
    local normalized = normalizeSoundId(soundId)
    if not normalized then
        return
    end
    local vol =
        math.clamp(tonumber(volume) or self.NotifySoundVolume or 1, 0, 10)
    local soundInstance = Instance.new('Sound')
    soundInstance.SoundId = normalized
    soundInstance.Volume = vol
    soundInstance.PlayOnRemove = true
    soundInstance.Parent = SoundService
    soundInstance:Destroy()
end

function ObsidianUI:Notify(payload, duration)
    local message = payload
    local soundId = self.NotifySoundId
    local soundVolume = self.NotifySoundVolume
    if typeof(payload) == 'table' then
        local data = {}
        for k, v in pairs(payload) do
            if
                k ~= 'SoundId'
                and k ~= 'SoundVolume'
                and k ~= 'Header'
                and k ~= 'Content'
                and k ~= 'Duration'
            then
                data[k] = v
            end
        end
        data.Title = payload.Title
            or payload.Header
            or data.Title
            or 'Notification'
        data.Description = payload.Description
            or payload.Content
            or data.Description
            or ''
        data.Time = payload.Time or payload.Duration or data.Time
        message = data
    end
    local result = self.Library:Notify(message, duration)
    if soundId then
        self:_playNotifySound(soundId, soundVolume)
    end
    return result
end

function ObsidianUI:CreateWindow(options)
    options = options or {}
    local window = self.Library:CreateWindow({
        Title = options.Name or options.LoadingTitle or 'Obsidian',
        Footer = options.LoadingSubtitle or '',
        NotifySide = options.NotifySide or 'Left',
        ShowCustomCursor = true,
    })
    self:_setupConfig(options.ConfigurationSaving)
    local wrapper = setmetatable({
        _window = window,
        _ObsidianUI = self,
        _idCounters = {},
    }, WindowMeta)
    return wrapper
end

function WindowMeta:_nextId(prefix, tabName)
    tabName = sanitizeIdSegment(tabName or 'tab')
    self._idCounters[prefix] = (self._idCounters[prefix] or 0) + 1
    return string.format('%s_%s_%d', prefix, tabName, self._idCounters[prefix])
end

function WindowMeta:_autoSave()
    if self._ObsidianUI then
        self._ObsidianUI:_autoSave()
    end
end

function WindowMeta:CreateTab(name)
    local tab = self._window:AddTab(name)
    local wrapper = setmetatable({
        _windowWrapper = self,
        _tab = tab,
        _group = nil,
        _tabName = name,
    }, TabMeta)
    return wrapper
end

function TabMeta:_groupbox()
    if not self._group then
        self._group =
            self._tab:AddLeftGroupbox(self._tabName .. ' Controls', 'list')
    end
    return self._group
end

function TabMeta:_autoSave()
    self._windowWrapper:_autoSave()
end

function TabMeta:_nextId(kind)
    return self._windowWrapper:_nextId(kind, self._tabName)
end

function TabMeta:CreateGroupbox(title, icon, side)
    local tab = self._tab
    if not tab then
        return self
    end
    local group
    if side == 'right' then
        group = tab:AddRightGroupbox(
            title or (self._tabName .. ' Right'),
            icon or 'layout-panel-right'
        )
    else
        group = tab:AddLeftGroupbox(
            title or (self._tabName .. ' Left'),
            icon or 'layout-panel-left'
        )
    end
    return setmetatable({
        _windowWrapper = self._windowWrapper,
        _tab = tab,
        _group = group,
        _tabName = self._tabName,
    }, TabMeta)
end

function TabMeta:CreateSection(text)
    local group = self:_groupbox()
    group:AddDivider()
    if text and text ~= '' then
        group:AddLabel(text, true)
    end
end

function TabMeta:CreateLabel(text)
    local label = self:_groupbox():AddLabel(text or '', true)
    return setmetatable({ _label = label }, LabelMeta)
end

function LabelMeta:Set(value)
    if self._label and self._label.SetText then
        self._label:SetText(value or '')
    end
end

function TabMeta:CreateButton(info)
    info = info or {}
    return self:_groupbox():AddButton({
        Text = info.Name or 'Button',
        Func = function()
            if info.Callback then
                info.Callback()
            end
        end,
    })
end

function TabMeta:CreateToggle(info)
    info = info or {}
    local id = info.Flag or self:_nextId('toggle')
    return self:_groupbox():AddToggle(id, {
        Text = info.Name or id,
        Default = info.CurrentValue or false,
        Callback = function(state)
            if info.Callback then
                info.Callback(state)
            end
            self:_autoSave()
        end,
    })
end

function TabMeta:CreateSlider(info)
    info = info or {}
    local id = info.Flag or self:_nextId('slider')
    local range = info.Range or { 0, 100 }
    local min = tonumber(range[1]) or 0
    local max = tonumber(range[2]) or (min + 100)
    return self:_groupbox():AddSlider(id, {
        Text = info.Name or id,
        Default = info.CurrentValue or min,
        Min = min,
        Max = max,
        Rounding = inferRounding(info.Increment),
        Callback = function(value)
            if info.Callback then
                info.Callback(value)
            end
            self:_autoSave()
        end,
    })
end

function TabMeta:CreateInput(info)
    info = info or {}
    local id = info.Flag or self:_nextId('input')
    return self:_groupbox():AddInput(id, {
        Text = info.Name or id,
        Default = info.CurrentValue or '',
        Placeholder = info.PlaceholderText,
        ClearTextOnFocus = info.RemoveTextAfterFocusLost or false,
        Callback = function(value)
            if info.Callback then
                info.Callback(value)
            end
            self:_autoSave()
        end,
    })
end

function TabMeta:CreateDropdown(info)
    info = info or {}
    local id = info.Flag or self:_nextId('dropdown')
    local values = copyArray(info.Options or {})
    local multi = info.MultiSelection or info.MultipleOptions or false
    local default = info.CurrentOption
    if multi then
        if typeof(default) == 'table' and next(default) then
            local arr = {}
            for _, v in ipairs(default) do
                arr[#arr + 1] = v
            end
            default = arr
        elseif typeof(default) == 'string' then
            default = { default }
        else
            default = nil
        end
    else
        if typeof(default) == 'table' then
            default = default[1]
        end
    end
    local dropdown = self:_groupbox():AddDropdown(id, {
        Text = info.Name or id,
        Values = values,
        Default = default,
        Multi = multi,
        Callback = function()
            local current
            if multi then
                current = snapshotSelection(dropdown.Value)
            else
                current = dropdown.Value
            end
            if info.Callback then
                info.Callback(current)
            end
            self:_autoSave()
        end,
    })
    return setmetatable({ _dropdown = dropdown }, DropdownMeta)
end

function DropdownMeta:Refresh(values, keepCurrent)
    if not self._dropdown then
        return
    end
    local dropdown = self._dropdown
    local previous
    if keepCurrent then
        if dropdown.Multi then
            previous = snapshotSelection(dropdown.Value)
        else
            previous = dropdown.Value
        end
    end
    dropdown:SetValues(copyArray(values or {}))
    if keepCurrent and previous then
        if dropdown.Multi then
            dropdown:SetValue(toDictionary(previous))
        elseif table.find(values or {}, previous) then
            dropdown:SetValue(previous)
        end
    end
end

function DropdownMeta:SetValue(value)
    if not self._dropdown then
        return
    end
    self._dropdown:SetValue(value)
end

local Win = ObsidianUI:CreateWindow({
    Name = TITLE,
    LoadingTitle = TITLE,
    LoadingSubtitle = 'zavaled loves KitaFuzzi',
    ConfigurationSaving = {
        Enabled = true,
        FolderName = 'Endless Doors',
        FileName = 'RENOVATION',
    },
})

if ObsidianUI.Library and ObsidianUI.Library.OnUnload then
    ObsidianUI.Library:OnUnload(function()
        ObsidianUI:Cleanup()
    end)
end

local tabMain = Win:CreateTab('Main', decalID)
local mainCore = tabMain:CreateGroupbox('Core Actions', 'zap', 'left')
local mainBypass = tabMain:CreateGroupbox('Bypasses', 'shield', 'left')
local interactGroup =
    tabMain:CreateGroupbox('Interactables', 'command', 'right')
local miscGroup = tabMain:CreateGroupbox('Misc Utilities', 'tool', 'right')

mainCore:CreateButton({
    Name = 'Infinite Flashlight',
    Callback = function()
        task.defer(function()
            S('ReplicatedStorage').Remotes.FLASHLIGHT_TOGGLE:FireServer(
                false,
                1e14
            )
        end)
    end,
})
mainCore:CreateButton({
    Name = 'God Mode [WIP]',
    Callback = function()
        task.defer(function()
            loadstring(
                game:HttpGet(
                    'https://raw.githubusercontent.com/ltseverydayyou/endless-doors/main/ED%20god'
                )
            )()
        end)
    end,
})
mainCore:CreateToggle({
    Name = 'Disable Look Script',
    CurrentValue = false,
    Flag = 'lookerLook',
    Callback = function(v)
        task.defer(function()
            if game.PlaceId ~= pCLASS then
                LocalPlayer.PlayerScripts:FindFirstChild('Looking').Enabled =
                    not v
            end
        end)
    end,
})
mainCore:CreateToggle({
    Name = 'Disable Camera Shaking',
    CurrentValue = false,
    Flag = 'camShaking',
    Callback = function(v)
        task.defer(function()
            if game.PlaceId == pREN then
                LocalPlayer.PlayerScripts:FindFirstChild('LocalShaking').Enabled =
                    not v
                LocalPlayer.PlayerScripts:FindFirstChild('CameraShake').Enabled =
                    not v
            end
        end)
    end,
})
mainCore:CreateToggle({
    Name = 'Full Bright',
    CurrentValue = false,
    Flag = 'brightLol',
    Callback = function(v)
        task.defer(function()
            local L = S('Lighting')
            if v then
                if brightLoop then
                    brightLoop:Disconnect()
                end
                brightLoop =
                    trackConnection(RunService.Stepped:Connect(function()
                        L.ClockTime = 0
                        L.FogEnd = 1e10
                        L.FogStart = 0
                        L.GlobalShadows = false
                        L.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
                        L.Brightness = 3
                    end))
            else
                if brightLoop then
                    brightLoop:Disconnect()
                    brightLoop = nil
                end
                L.ClockTime = 0
                L.FogEnd = 100000
                L.FogStart = 0
                L.GlobalShadows = false
                L.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
                L.Brightness = 1
            end
        end)
    end,
})
mainCore:CreateToggle({
    Name = 'Anti AFK',
    CurrentValue = false,
    Flag = 'antiAFK',
    Callback = function(v)
        task.defer(function()
            if v then
                if antiAFKConn then
                    antiAFKConn:Disconnect()
                end
                antiAFKConn =
                    trackConnection(LocalPlayer.Idled:Connect(function()
                        S('VirtualUser'):Button2Down(
                            Vector2.new(),
                            workspace.CurrentCamera.CFrame
                        )
                        task.wait(1)
                        S('VirtualUser'):Button2Up(
                            Vector2.new(),
                            workspace.CurrentCamera.CFrame
                        )
                    end))
            else
                if antiAFKConn then
                    antiAFKConn:Disconnect()
                    antiAFKConn = nil
                end
            end
        end)
    end,
})
mainCore:CreateButton({
    Name = 'Play Again',
    DoubleClick = true,
    Callback = function()
        task.defer(function()
            S('ReplicatedStorage').Remotes.PLAY_AGAIN:FireServer()
        end)
    end,
})
mainCore:CreateButton({
    Name = 'Buy Respawn',
    DoubleClick = true,
    Callback = function()
        task.defer(function()
            S('ReplicatedStorage').Remotes.BUY_RESPAWN:FireServer()
        end)
    end,
})
mainCore:CreateButton({
    Name = 'Die',
    DoubleClick = true,
    Callback = function()
        task.defer(function()
            S('ReplicatedStorage').Remotes.F_DMG:FireServer(1000)
        end)
    end,
})

interactGroup:CreateSection('Interactables')
local promptList = { 'None' }
local dropdownObj, modeLabel
local suppressDropdownCallback = false

local function rebuildPromptList()
    local seen = {}
    for _, pp in ipairs(proximityPrompts) do
        if pp and pp.Parent then
            local n = holderName(pp)
            if n and n ~= '' then
                seen[n] = true
            end
        end
    end
    local new = { 'None' }
    for k in pairs(seen) do
        new[#new + 1] = k
    end
    table.sort(new, function(a, b)
        return a < b
    end)
    local changed = false
    if #new ~= #promptList then
        changed = true
    else
        for i = 1, #new do
            if new[i] ~= promptList[i] then
                changed = true
                break
            end
        end
    end
    if changed then
        promptList = new
        if dropdownObj then
            pcall(function()
                suppressDropdownCallback = true
                dropdownObj:Refresh(promptList, true)
                dropdownObj:SetValue(selectionDictionary())
            end)
            suppressDropdownCallback = false
        end
    end
end

dropdownObj = interactGroup:CreateDropdown({
    Name = 'Prompt Names [BUGGY/WIP]',
    Options = promptList,
    CurrentOption = {},
    MultiSelection = true,
    MultipleOptions = true,
    Flag = 'PromptNamesMulti',
    Callback = function(opt)
        if suppressDropdownCallback then
            return
        end
        applySelectionFromValue(opt)
    end,
})

interactGroup:CreateButton({
    Name = 'Clear Selection',
    Callback = function()
        if dropdownObj and dropdownObj.SetValue then
            suppressDropdownCallback = true
            dropdownObj:SetValue({})
            suppressDropdownCallback = false
        end
        clearSelection()
        updateModeLabelText()
    end,
})

interactGroup:CreateToggle({
    Name = 'Auto Interact',
    CurrentValue = false,
    Flag = 'AuraAll',
    Callback = function(v)
        getgenv().chaos = v
    end,
})

interactGroup:CreateSection('Interactable Info')
modeLabel = interactGroup:CreateLabel('Mode: Default (all prompts)')
updateModeLabelText()
interactGroup:CreateLabel(
    'Select one or more holder names to target only those prompts.'
)
interactGroup:CreateLabel('The list updates automatically.')

task.spawn(function()
    while scriptRunning do
        task.wait(0.35)
        if not scriptRunning then
            break
        end
        pcall(rebuildPromptList)
    end
end)
trackConnection(workspace.DescendantAdded:Connect(function(o)
    if o:IsA('ProximityPrompt') then
        task.defer(rebuildPromptList)
    end
end))
trackConnection(workspace.DescendantRemoving:Connect(function(o)
    if o:IsA('ProximityPrompt') then
        task.defer(rebuildPromptList)
    end
end))

local tabToggles = Win:CreateTab('Toggles', 12544524983)
tabToggles:CreateSection('ESP')
tabToggles:CreateToggle({
    Name = 'Entity Esp',
    CurrentValue = false,
    Flag = 'entityESP',
    Callback = function(v)
        task.defer(function()
            getgenv().entityEsp = v
            if not v then
                for _, e in ipairs(Entities:GetDescendants()) do
                    RemoveESP(e)
                end
            else
                for _, e in ipairs(Entities:GetChildren()) do
                    CreateESP(e)
                end
            end
        end)
    end,
})
tabToggles:CreateToggle({
    Name = 'Key Esp',
    CurrentValue = false,
    Flag = 'KeyESP',
    Callback = function(v)
        task.defer(function()
            getgenv().keyESP = v
            if not v then
                for _, p in ipairs(Rooms:GetDescendants()) do
                    if
                        p:IsA('BasePart')
                        and p.Name:lower() == 'roomkey'
                        and p.Parent.Name:lower() ~= 'door'
                    then
                        RemoveESP(p)
                    end
                end
            else
                for _, p in ipairs(Rooms:GetDescendants()) do
                    if
                        p:IsA('BasePart')
                        and p.Name:lower() == 'roomkey'
                        and p.Parent.Name:lower() ~= 'door'
                    then
                        CreateESP(p, Color3.new(1, 1, 0), 'Key')
                    end
                end
            end
        end)
    end,
})
tabToggles:CreateToggle({
    Name = 'Bits Esp',
    CurrentValue = false,
    Flag = 'BitsESP',
    Callback = function(v)
        task.defer(function()
            getgenv().bitESP = v
            if not v then
                for _, p in ipairs(Rooms:GetDescendants()) do
                    if p:IsA('BasePart') and p.Name:lower() == 'bit' then
                        RemoveESP(p)
                    end
                end
            else
                for _, p in ipairs(Rooms:GetDescendants()) do
                    if p:IsA('BasePart') and p.Name:lower() == 'bit' then
                        CreateESP(p, Color3.new(1, 0.666667, 0))
                    end
                end
            end
        end)
    end,
})
tabToggles:CreateToggle({
    Name = 'Lever Esp',
    CurrentValue = false,
    Flag = 'LeverESP',
    Callback = function(v)
        task.defer(function()
            getgenv().leverESP = v
            if not v then
                for _, p in ipairs(Rooms:GetDescendants()) do
                    if p:IsA('BasePart') and p.Name:lower() == 'lever' then
                        RemoveESP(p)
                    end
                end
            else
                for _, p in ipairs(Rooms:GetDescendants()) do
                    if p:IsA('BasePart') and p.Name:lower() == 'lever' then
                        CreateESP(p, Color3.fromRGB(139, 145, 165))
                    end
                end
            end
        end)
    end,
})
tabToggles:CreateToggle({
    Name = 'Battery Esp',
    CurrentValue = false,
    Flag = 'BatteryESP',
    Callback = function(v)
        task.defer(function()
            getgenv().batteryESP = v
            if not v then
                for _, p in ipairs(Rooms:GetDescendants()) do
                    if p:IsA('BasePart') and p.Name:lower() == 'battery' then
                        RemoveESP(p)
                    end
                end
            else
                for _, p in ipairs(Rooms:GetDescendants()) do
                    if p:IsA('BasePart') and p.Name:lower() == 'battery' then
                        CreateESP(p, Color3.new(0, 0.666667, 0))
                    end
                end
            end
        end)
    end,
})
tabToggles:CreateSection('Utility Toggles')
tabToggles:CreateToggle({
    Name = 'Entity Remote Logger',
    CurrentValue = false,
    Flag = 'entRem',
    Callback = function(v)
        getgenv().remoteThingy = v
    end,
})
tabToggles:CreateToggle({
    Name = 'Entity Notifier',
    CurrentValue = false,
    Flag = 'entityNotifs',
    Callback = function(v)
        getgenv().entityNotif = v
    end,
})

mainBypass:CreateSection('Bypass (General)')
mainBypass:CreateToggle({
    Name = 'Bypass Overseer',
    CurrentValue = false,
    Flag = 'overSeer',
    Callback = function(v)
        task.defer(function()
            if v then
                if overCon then
                    overCon:Disconnect()
                end
                overCon = trackConnection(
                    workspace.DescendantAdded:Connect(function(o)
                        if o.Name:lower() == 'overseer' then
                            task.defer(function()
                                if o and o.Parent then
                                    o:Destroy()
                                end
                            end)
                        end
                    end)
                )
                for _, o in ipairs(workspace:GetDescendants()) do
                    if o.Name:lower() == 'overseer' then
                        task.defer(function()
                            if o and o.Parent then
                                o:Destroy()
                            end
                        end)
                    end
                end
            else
                if overCon then
                    overCon:Disconnect()
                    overCon = nil
                end
            end
        end)
    end,
})
mainBypass:CreateToggle({
    Name = 'Bypass Lurker',
    CurrentValue = false,
    Flag = 'lurkER',
    Callback = function(v)
        task.defer(function()
            if v then
                if lurkCon then
                    lurkCon:Disconnect()
                end
                lurkCon = trackConnection(
                    workspace.DescendantAdded:Connect(function(o)
                        if o.Name:lower() == 'lurker' then
                            task.defer(function()
                                if o and o.Parent then
                                    o:Destroy()
                                end
                            end)
                        end
                    end)
                )
                for _, o in ipairs(workspace:GetDescendants()) do
                    if o.Name:lower() == 'lurker' then
                        task.defer(function()
                            if o and o.Parent then
                                o:Destroy()
                            end
                        end)
                    end
                end
            else
                if lurkCon then
                    lurkCon:Disconnect()
                    lurkCon = nil
                end
            end
        end)
    end,
})
mainBypass:CreateToggle({
    Name = 'Bypass Watchbane',
    CurrentValue = false,
    Flag = 'watcherBANE',
    Callback = function(v)
        task.defer(function()
            if v then
                if watchCon then
                    watchCon:Disconnect()
                end
                watchCon = trackConnection(
                    workspace.DescendantAdded:Connect(function(o)
                        if o.Name:lower() == 'watchbane' then
                            task.defer(function()
                                if o and o.Parent then
                                    o:Destroy()
                                end
                            end)
                        end
                    end)
                )
                for _, o in ipairs(workspace:GetDescendants()) do
                    if o.Name:lower() == 'watchbane' then
                        task.defer(function()
                            if o and o.Parent then
                                o:Destroy()
                            end
                        end)
                    end
                end
            else
                if watchCon then
                    watchCon:Disconnect()
                    watchCon = nil
                end
            end
        end)
    end,
})
mainBypass:CreateToggle({
    Name = 'Bypass FlowerGrowth',
    CurrentValue = false,
    Flag = 'flowerGrowth',
    Callback = function(v)
        task.defer(function()
            if v then
                if flowCon then
                    flowCon:Disconnect()
                end
                flowCon = trackConnection(
                    workspace.DescendantAdded:Connect(function(o)
                        if o.Name:lower() == 'flowergrowth' then
                            task.defer(function()
                                if o and o.Parent then
                                    o:Destroy()
                                end
                            end)
                        end
                    end)
                )
                for _, o in ipairs(workspace:GetDescendants()) do
                    if o.Name:lower() == 'flowergrowth' then
                        task.defer(function()
                            if o and o.Parent then
                                o:Destroy()
                            end
                        end)
                    end
                end
            else
                if flowCon then
                    flowCon:Disconnect()
                    flowCon = nil
                end
            end
        end)
    end,
})
mainBypass:CreateToggle({
    Name = 'Bypass Abyss',
    CurrentValue = false,
    Flag = 'abyssKILL',
    Callback = function(v)
        task.defer(function()
            if v then
                if abyssCon then
                    abyssCon:Disconnect()
                end
                abyssCon = trackConnection(
                    workspace.DescendantAdded:Connect(function(o)
                        if o.Name:lower() == 'abysskill' then
                            task.defer(function()
                                if o and o.Parent then
                                    o:Destroy()
                                end
                            end)
                        end
                    end)
                )
                for _, o in ipairs(workspace:GetDescendants()) do
                    if o.Name:lower() == 'abysskill' then
                        task.defer(function()
                            if o and o.Parent then
                                o:Destroy()
                            end
                        end)
                    end
                end
            else
                if abyssCon then
                    abyssCon:Disconnect()
                    abyssCon = nil
                end
            end
        end)
    end,
})

mainBypass:CreateSection('Bypass [Special]')
mainBypass:CreateToggle({
    Name = 'Bypass Taker [HEIST MODIFIER]',
    CurrentValue = false,
    Flag = 'TAKERRRRR',
    Callback = function(v)
        task.defer(function()
            if v then
                if takerCon then
                    takerCon:Disconnect()
                end
                takerCon = trackConnection(
                    workspace.DescendantAdded:Connect(function(o)
                        if o.Name:lower() == 'taker' then
                            task.defer(function()
                                if o and o.Parent then
                                    o:Destroy()
                                end
                            end)
                        end
                    end)
                )
                for _, o in ipairs(workspace:GetDescendants()) do
                    if o.Name:lower() == 'taker' then
                        task.defer(function()
                            if o and o.Parent then
                                o:Destroy()
                            end
                        end)
                    end
                end
            else
                if takerCon then
                    takerCon:Disconnect()
                    takerCon = nil
                end
            end
        end)
    end,
})
mainBypass:CreateToggle({
    Name = 'Bypass ChaseTrigger [EPIC MODE]',
    CurrentValue = false,
    Flag = 'chaseTrigger',
    Callback = function(v)
        task.defer(function()
            if v then
                if chaseCon then
                    chaseCon:Disconnect()
                end
                chaseCon = trackConnection(
                    workspace.DescendantAdded:Connect(function(o)
                        if o.Name:lower() == 'chasetrigger' then
                            task.defer(function()
                                if o and o.Parent then
                                    o:Destroy()
                                end
                            end)
                        end
                    end)
                )
                for _, o in ipairs(workspace:GetDescendants()) do
                    if o.Name:lower() == 'chasetrigger' then
                        task.defer(function()
                            if o and o.Parent then
                                o:Destroy()
                            end
                        end)
                    end
                end
            else
                if chaseCon then
                    chaseCon:Disconnect()
                    chaseCon = nil
                end
            end
        end)
    end,
})

local tabPlayer = Win:CreateTab('Player', 470645116)
tabPlayer:CreateSlider({
    Name = 'Set WalkSpeed',
    Range = (game.PlaceId == pCLASS) and { 0, 35 } or { 0, 100 },
    Increment = 1,
    CurrentValue = getgenv().speed,
    Flag = 'WalkSpeedValue',
    Callback = function(v)
        getgenv().speed = v
    end,
})
tabPlayer:CreateToggle({
    Name = 'Toggle WalkSpeed',
    CurrentValue = false,
    Flag = 'WSspeed',
    Callback = function(v)
        getgenv().sped = v
    end,
})
tabPlayer:CreateSlider({
    Name = 'Set JumpPower',
    Range = { 0, 100 },
    Increment = 1,
    CurrentValue = getgenv().jump,
    Flag = 'JumpPowerValue',
    Callback = function(v)
        getgenv().jump = v
    end,
})
tabPlayer:CreateToggle({
    Name = 'Toggle JumpPower',
    CurrentValue = false,
    Flag = 'JPtgl',
    Callback = function(v)
        getgenv().jumpy = v
    end,
})
tabPlayer:CreateSlider({
    Name = 'Set FOV',
    Range = { 0, 120 },
    Increment = 1,
    CurrentValue = tonumber(getgenv().fov) or 70,
    Flag = 'FieldOfViewValue',
    Callback = function(v)
        getgenv().fov = v
        if getgenv().wide then
            workspace.CurrentCamera.FieldOfView = v
        end
    end,
})
tabPlayer:CreateToggle({
    Name = 'Toggle FOV',
    CurrentValue = false,
    Flag = 'FovTgl',
    Callback = function(v)
        getgenv().wide = v
        if v then
            bindFOV(workspace.CurrentCamera)
        else
            if fovLockConn then
                fovLockConn:Disconnect()
                fovLockConn = nil
            end
        end
    end,
})
tabPlayer:CreateToggle({
    Name = 'Infinite Jump',
    CurrentValue = false,
    Flag = 'infJP',
    Callback = function(v)
        if infJumpConn then
            infJumpConn:Disconnect()
            infJumpConn = nil
        end
        if mobHoldConn then
            mobHoldConn:Disconnect()
            mobHoldConn = nil
        end
        if mobDownConn then
            mobDownConn:Disconnect()
            mobDownConn = nil
        end
        if mobUpConn then
            mobUpConn:Disconnect()
            mobUpConn = nil
        end
        if v then
            infJumpConn = trackConnection(UIS.JumpRequest:Connect(function()
                local h = LocalPlayer.Character
                    and LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
                if h then
                    h:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end))
            if IsOnMobile and game.PlaceId == pREN then
                local h = LocalPlayer.Character
                    and LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
                if h then
                    h:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                end
                local jb = LocalPlayer.PlayerGui
                    :WaitForChild('TouchControls')
                    :WaitForChild('MobileControls')
                    :WaitForChild('JumpButton')
                local function startHold()
                    if mobHoldConn then
                        return
                    end
                    mobHoldConn =
                        trackConnection(RunService.Heartbeat:Connect(function()
                            local mh = LocalPlayer.Character
                                and LocalPlayer.Character:FindFirstChildOfClass(
                                    'Humanoid'
                                )
                            if mh then
                                mh:ChangeState(Enum.HumanoidStateType.Jumping)
                            end
                        end))
                end
                local function endHold()
                    if mobHoldConn then
                        mobHoldConn:Disconnect()
                        mobHoldConn = nil
                    end
                end
                mobDownConn = trackConnection(jb.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.Touch then
                        startHold()
                    end
                end))
                mobUpConn = trackConnection(jb.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.Touch then
                        endHold()
                    end
                end))
            end
        end
    end,
})

miscGroup:CreateSection('Misc Utilities')
miscGroup:CreateButton({
    Name = 'Hide Value',
    Callback = function()
        LocalPlayer.Character.Hiding.Value =
            not LocalPlayer.Character.Hiding.Value
    end,
})
miscGroup:CreateButton({
    Name = 'Teleport to Door',
    Callback = function()
        tpToDoor()
    end,
})
miscGroup:CreateButton({
    Name = 'Teleport to Key',
    Callback = function()
        tpToKey()
    end,
})
miscGroup:CreateButton({
    Name = 'Teleport to Lever',
    Callback = function()
        tpToLever()
    end,
})
miscGroup:CreateToggle({
    Name = 'Loop Teleport To Door',
    CurrentValue = false,
    Callback = function(v)
        task.spawn(function()
            getgenv().teletodoor = v
            while scriptRunning and getgenv().teletodoor do
                pcall(tpToDoor)
                task.wait(0.3)
            end
        end)
    end,
})
miscGroup:CreateToggle({
    Name = 'Loop Teleport To Key',
    CurrentValue = false,
    Callback = function(v)
        task.spawn(function()
            getgenv().teletokey = v
            while scriptRunning and getgenv().teletokey do
                pcall(tpToKey)
                task.wait(0.5)
            end
        end)
    end,
})
miscGroup:CreateToggle({
    Name = 'Loop Teleport To Lever',
    CurrentValue = false,
    Callback = function(v)
        task.spawn(function()
            getgenv().teletolever = v
            while scriptRunning and getgenv().teletolever do
                pcall(tpToLever)
                task.wait(0.5)
            end
        end)
    end,
})
miscGroup:CreateSection('Notifications')
miscGroup:CreateInput({
    Name = 'Notification Text',
    PlaceholderText = 'Text',
    RemoveTextAfterFocusLost = false,
    Callback = function(t)
        getgenv().Notifv1 = t
    end,
})
miscGroup:CreateButton({
    Name = 'Send Notification',
    Callback = function()
        ObsidianUI:Notify({
            Title = 'Notification',
            Content = getgenv().Notifv1 or 'Door',
            Duration = 3,
            Image = decalID,
        })
    end,
})

local tabInfo = Win:CreateTab('Info/Stats', 2246486837)
local L_rooms = tabInfo:CreateLabel('Rooms: ' .. playerRoom())
local L_bits = tabInfo:CreateLabel('Bits: ' .. playerBits())
local L_dbl = tabInfo:CreateLabel('Double Bits: ' .. doubleBits())
tabInfo:CreateSection('')
local L_fame, L_deaths, L_rift, L_group
if game.PlaceId == pREN then
    L_fame = tabInfo:CreateLabel('Fame: ' .. fame())
    L_deaths = tabInfo:CreateLabel('Deaths: ' .. deaths())
    L_rift = tabInfo:CreateLabel('Rift: ' .. rift())
    L_group = tabInfo:CreateLabel('Joined Group: ' .. inGroup())
    tabInfo:CreateSection('')
end
local L_cur = tabInfo:CreateLabel('Current Room: ' .. curRoom())
local L_phil = tabInfo:CreateLabel('Phil Chance: ' .. phil())
local L_spider = tabInfo:CreateLabel('Spider Chance: ' .. spider())
local L_rev
if game.PlaceId ~= pCLASS then
    L_rev = tabInfo:CreateLabel('Revive Price: ' .. revivePrice())
end
local L_alive = tabInfo:CreateLabel('Players Alive: ' .. alive())
local L_ingame = tabInfo:CreateLabel('Players In Game: ' .. inGame())
if game.PlaceId == pREN then
    tabInfo:CreateSection('')
    tabInfo:CreateLabel('Fuzzi: ' .. fuz())
    tabInfo:CreateLabel('Zav: ' .. zav())
    tabInfo:CreateLabel('Jake: ' .. jake())
    tabInfo:CreateLabel('Blue: ' .. blue())
    tabInfo:CreateLabel('Alan: ' .. alan())
end

local tabSettings = Win:CreateTab('Settings', 12544524983)
local settingsTabRaw = tabSettings and tabSettings._tab
if settingsTabRaw then
    local settingsMenu = settingsTabRaw:AddLeftGroupbox('Menu', 'wrench')
    if settingsMenu then
        settingsMenu:AddToggle('Settings_CustomCursor', {
            Text = 'Use Custom Cursor',
            Default = ObsidianUI.Library
                    and (ObsidianUI.Library.ShowCustomCursor ~= false)
                or true,
            Callback = function(value)
                if ObsidianUI.Library then
                    ObsidianUI.Library.ShowCustomCursor = value
                end
            end,
        })
        settingsMenu:AddDropdown('Settings_NotifySide', {
            Text = 'Notification Side',
            Values = { 'Left', 'Right' },
            Default = (ObsidianUI.Library and ObsidianUI.Library.NotifySide)
                or 'Left',
            Callback = function(value)
                if ObsidianUI.Library and value then
                    ObsidianUI.Library:SetNotifySide(value)
                end
            end,
        })
        local currentDpiPercent = function()
            local scale = ObsidianUI.Library and ObsidianUI.Library.DPIScale
                or 1
            return math.floor((scale * 100) + 0.5)
        end
        settingsMenu:AddDropdown('Settings_DPI', {
            Text = 'DPI Scale',
            Values = { '50%', '75%', '100%', '125%', '150%', '175%', '200%' },
            Default = tostring(currentDpiPercent()) .. '%',
            Callback = function(value)
                if not (ObsidianUI.Library and value) then
                    return
                end
                local cleaned = tostring(value):gsub('[^%d%.]', '')
                local pct = tonumber(cleaned)
                if pct then
                    ObsidianUI.Library:SetDPIScale(pct)
                end
            end,
        })
        settingsMenu:AddDivider()
        local function resolveMenuKeyDefault()
            local key = ObsidianUI.Library
                and ObsidianUI.Library.ToggleKeybind
                and ObsidianUI.Library.ToggleKeybind.Value
            if typeof(key) == 'EnumItem' and key.EnumType == Enum.KeyCode then
                return key.Name
            elseif typeof(key) == 'string' and key ~= '' then
                return key
            end
            return 'RightControl'
        end
        local defaultMenuKey = resolveMenuKeyDefault()
        settingsMenu:AddLabel('Menu Bind'):AddKeyPicker(
            'MenuKeybind',
            { Default = defaultMenuKey, NoUI = true, Text = 'Menu keybind' }
        )
        settingsMenu:AddButton('Unload', function()
            ObsidianUI:Cleanup()
            if ObsidianUI.Library then
                ObsidianUI.Library:Unload()
            end
        end)
    end
    local optionsRef = ObsidianUI.Library and ObsidianUI.Library.Options
    if optionsRef and optionsRef.MenuKeybind then
        ObsidianUI.Library.ToggleKeybind = optionsRef.MenuKeybind
    end
    if ObsidianUI.ThemeManager then
        ObsidianUI.ThemeManager:ApplyToTab(settingsTabRaw)
    end
    if ObsidianUI.SaveManager then
        ObsidianUI.SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
        ObsidianUI.SaveManager:BuildConfigSection(settingsTabRaw)
    end
end

task.spawn(function()
    while scriptRunning do
        task.wait()
        if not scriptRunning then
            break
        end
        pcall(function()
            L_rooms:Set('Rooms: ' .. playerRoom())
            L_bits:Set('Bits: ' .. playerBits())
            L_dbl:Set('Double Bits: ' .. doubleBits())
            L_cur:Set('Current Room: ' .. curRoom())
            L_phil:Set('Phil Chance: ' .. phil())
            L_spider:Set('Spider Chance: ' .. spider())
            if L_rev then
                L_rev:Set('Revive Price: ' .. revivePrice())
            end
            L_alive:Set('Players Alive: ' .. alive())
            L_ingame:Set('Players In Game: ' .. inGame())
            if game.PlaceId == pREN then
                L_fame:Set('Fame: ' .. fame())
                L_deaths:Set('Deaths: ' .. deaths())
                L_rift:Set('Rift: ' .. rift())
                L_group:Set('Joined Group: ' .. inGroup())
            end
        end)
    end
end)

trackConnection(Players.PlayerAdded:Connect(function(pl)
    task.defer(function()
        local n = pl.Name
        local d = pl.DisplayName
        local f = (n:lower() == d:lower()) and ('@' .. n)
            or (d .. ' (@' .. n .. ')')
        ObsidianUI:Notify({
            Title = 'Player Join Log',
            Content = f .. ' Joined',
            Duration = 3,
            Image = decalID,
        })
    end)
end))

task.spawn(function()
    local pg = LocalPlayer:WaitForChild('PlayerGui', 5)
    if not pg then
        return
    end
    trackConnection(pg.DescendantAdded:Connect(function(txt)
        if not txt:IsA('TextLabel') then
            return
        end
        local parent = txt.Parent
        if not parent or parent.Name:lower() ~= 'hintframe' then
            return
        end
        local t = txt.Text:lower()
        if t:find('cannot pick that up') or t:find('you already have this') then
            task.defer(function()
                if txt and txt.Parent then
                    txt:Destroy()
                end
            end)
        end
    end))
end)

trackConnection(Entities.ChildAdded:Connect(function(ent)
    if getgenv().entityEsp then
        task.defer(function()
            CreateESP(ent)
            if getgenv().entityNotif then
                ObsidianUI:Notify({
                    Title = 'Entity',
                    Content = ent.Name .. ' Has Spawned',
                    Duration = 3,
                    Image = decalID,
                })
            end
        end)
    end
end))

trackConnection(
    Values.MimicActivated:GetPropertyChangedSignal('Value'):Connect(function()
        if getgenv().entityNotif then
            task.defer(function()
                local txt = Values.MimicActivated.Value and 'Mimic Is Enabled'
                    or 'Mimic Is Disabled'
                ObsidianUI:Notify({
                    Title = 'Entity',
                    Content = txt,
                    Duration = 3,
                    Image = decalID,
                })
            end)
        end
    end)
)

trackConnection(
    S('ReplicatedStorage').Remotes
        :FindFirstChild('E_A', true).OnClientEvent
        :Connect(function(ent)
            if tostring(ent):lower() == 'greed' then
                task.defer(function()
                    greedActive = true
                    task.wait(9)
                    greedActive = false
                end)
                if getgenv().entityNotif then
                    ObsidianUI:Notify({
                        Title = 'Entity',
                        Content = 'Greed Spawned',
                        Duration = 3,
                        Image = decalID,
                    })
                end
            end
            if getgenv().remoteThingy then
                task.defer(function()
                    ObsidianUI:Notify({
                        Title = 'Remote Call',
                        Content = 'Returned: ' .. tostring(ent),
                        Duration = 3,
                        Image = decalID,
                    })
                end)
            end
        end)
)

trackConnection(Rooms.DescendantAdded:Connect(function(o)
    if
        getgenv().keyESP
        and o:IsA('BasePart')
        and o.Name:lower() == 'roomkey'
        and o.Parent.Name:lower() ~= 'door'
    then
        task.defer(function()
            CreateESP(o, Color3.new(1, 1, 0), 'Key')
        end)
    end
end))
trackConnection(Rooms.DescendantAdded:Connect(function(o)
    if getgenv().bitESP and o:IsA('BasePart') and o.Name:lower() == 'bit' then
        task.defer(function()
            CreateESP(o, Color3.new(1, 0.666667, 0))
        end)
    end
end))
trackConnection(Rooms.DescendantAdded:Connect(function(o)
    if
        getgenv().leverESP
        and o:IsA('BasePart')
        and o.Name:lower() == 'lever'
    then
        task.defer(function()
            CreateESP(o, Color3.fromRGB(139, 145, 165))
        end)
    end
end))
trackConnection(Rooms.DescendantAdded:Connect(function(o)
    if
        getgenv().batteryESP
        and o:IsA('BasePart')
        and o.Name:lower() == 'battery'
    then
        task.defer(function()
            CreateESP(o, Color3.new(0, 0.666667, 0))
        end)
    end
end))

ObsidianUI:LoadConfiguration()

trackConnection(RunService.Stepped:Connect(function()
    if getgenv().chaos then
        firePrompts()
    end
end))

cameraConn = trackConnection(
    workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
        currentCamera = workspace.CurrentCamera
        if getgenv().wide then
            bindFOV(currentCamera)
        end
    end)
)

task.spawn(function()
    while scriptRunning do
        task.wait()
        if not scriptRunning then
            break
        end
        local h = LocalPlayer.Character
            and LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
        if h then
            if getgenv().sped and getgenv().speed then
                h.WalkSpeed = getgenv().speed
            end
            if getgenv().jumpy and getgenv().jump then
                h.JumpPower = getgenv().jump
            end
        end
    end
end)