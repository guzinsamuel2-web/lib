--[[
    ===========================================================================
    UI Library v1.0.0
    Professional Open Source UI Library for Roblox
    MIT License
    ===========================================================================
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer

local Modules = {}
local ModuleCache = {}

local function loadModule(name)
    if ModuleCache[name] then return ModuleCache[name] end
    local loader = Modules[name]
    if not loader then error("[UILibrary] Module not found: " .. tostring(name), 2) end
    ModuleCache[name] = loader()
    return ModuleCache[name]
end

----------------------------------------------------------------
Modules["Helpers"] = function()
    local Helpers = {}
    
    function Helpers.deepCopy(t)
        if type(t) ~= "table" then return t end
        local res = {}
        for k, v in pairs(t) do
            res[Helpers.deepCopy(k)] = Helpers.deepCopy(v)
        end
        return res
    end
    
    function Helpers.deepMerge(base, override)
        for k, v in pairs(override) do
            if type(v) == "table" and type(base[k]) == "table" then
                base[k] = Helpers.deepMerge(base[k], v)
            else
                base[k] = v
            end
        end
        return base
    end
    
    function Helpers.generateId()
        return HttpService:GenerateGUID(false)
    end
    
    function Helpers.clamp(value, min, max)
        return math.clamp(value, min, max)
    end
    
    function Helpers.lerp(a, b, t)
        return a + (b - a) * t
    end
    
    function Helpers.lerpColor(c1, c2, t)
        return c1:Lerp(c2, t)
    end
    
    function Helpers.getDarker(color, factor)
        local h, s, v = color:ToHSV()
        return Color3.fromHSV(h, s, math.clamp(v * (1 - factor), 0, 1))
    end
    
    function Helpers.getLighter(color, factor)
        local h, s, v = color:ToHSV()
        return Color3.fromHSV(h, s, math.clamp(v + (1 - v) * factor, 0, 1))
    end
    
    function Helpers.round(value, decimals)
        local mult = 10^(decimals or 0)
        return math.floor(value * mult + 0.5) / mult
    end
    
    function Helpers.formatNumber(value)
        local formatted = tostring(Helpers.round(value, 2))
        local k = 0
        while true do
            formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
            if k == 0 then break end
        end
        return formatted
    end
    
    function Helpers.truncate(str, maxLen)
        if #str > maxLen then
            return string.sub(str, 1, maxLen - 3) .. "..."
        end
        return str
    end
    
    return Helpers
end

----------------------------------------------------------------
Modules["Create"] = function()
    local Create = {}
    
    function Create.new(className, properties, children)
        local instance = Instance.new(className)
        if properties then
            for prop, value in pairs(properties) do
                if prop ~= "Parent" then
                    instance[prop] = value
                end
            end
            if properties.Parent then
                instance.Parent = properties.Parent
            end
        end
        if children then
            for _, child in ipairs(children) do
                child.Parent = instance
            end
        end
        return instance
    end
    
    return Create
end

----------------------------------------------------------------
Modules["Signal"] = function()
    local Signal = {}
    Signal.__index = Signal
    
    function Signal.new()
        local self = setmetatable({}, Signal)
        self._connections = {}
        return self
    end
    
    function Signal:Connect(fn)
        local connection = {
            Connected = true,
            _fn = fn,
        }
        
        function connection:Disconnect()
            self.Connected = false
        end
        
        table.insert(self._connections, connection)
        return connection
    end
    
    function Signal:Once(fn)
        local connection
        connection = self:Connect(function(...)
            if connection.Connected then
                connection:Disconnect()
                fn(...)
            end
        end)
        return connection
    end
    
    function Signal:Fire(...)
        for _, connection in ipairs(self._connections) do
            if connection.Connected then
                task.spawn(connection._fn, ...)
            end
        end
    end
    
    function Signal:Wait()
        local thread = coroutine.running()
        local connection
        connection = self:Connect(function(...)
            connection:Disconnect()
            task.spawn(thread, ...)
        end)
        return coroutine.yield()
    end
    
    function Signal:DisconnectAll()
        for _, connection in ipairs(self._connections) do
            connection:Disconnect()
        end
        table.clear(self._connections)
    end
    
    function Signal:Destroy()
        self:DisconnectAll()
    end
    
    return Signal
end

----------------------------------------------------------------
Modules["Maid"] = function()
    local Maid = {}
    Maid.__index = Maid
    
    function Maid.new()
        local self = setmetatable({}, Maid)
        self._tasks = {}
        return self
    end
    
    function Maid:GiveTask(task)
        table.insert(self._tasks, task)
        return task
    end
    
    function Maid:DoCleaning()
        for _, task in ipairs(self._tasks) do
            if type(task) == "function" then
                task()
            elseif typeof(task) == "RBXScriptConnection" then
                task:Disconnect()
            elseif type(task) == "table" then
                if type(task.Destroy) == "function" then
                    task:Destroy()
                elseif type(task.Disconnect) == "function" then
                    task:Disconnect()
                end
            elseif typeof(task) == "Instance" then
                task:Destroy()
            end
        end
        table.clear(self._tasks)
    end
    
    function Maid:Destroy()
        self:DoCleaning()
    end
    
    return Maid
end

----------------------------------------------------------------
Modules["Icons"] = function()
    return {
        Logo = "rbxassetid://SEU_ASSET",
        Search = "rbxassetid://SEU_ASSET",
        Settings = "rbxassetid://SEU_ASSET",
        Player = "rbxassetid://SEU_ASSET",
        Home = "rbxassetid://SEU_ASSET",
        Visuals = "rbxassetid://SEU_ASSET",
        Misc = "rbxassetid://SEU_ASSET",
        Arrow = "rbxassetid://SEU_ASSET",
        Close = "rbxassetid://SEU_ASSET",
        Minimize = "rbxassetid://SEU_ASSET",
        Notification = "rbxassetid://SEU_ASSET",
        Warning = "rbxassetid://SEU_ASSET",
        Success = "rbxassetid://SEU_ASSET",
        Error = "rbxassetid://SEU_ASSET",
        Info = "rbxassetid://SEU_ASSET",
        Check = "rbxassetid://SEU_ASSET",
        ChevronDown = "rbxassetid://SEU_ASSET",
        ChevronRight = "rbxassetid://SEU_ASSET",
        ChevronUp = "rbxassetid://SEU_ASSET",
        ColorWheel = "rbxassetid://SEU_ASSET",
        Drag = "rbxassetid://SEU_ASSET",
        Plus = "rbxassetid://SEU_ASSET",
        Minus = "rbxassetid://SEU_ASSET",
        Edit = "rbxassetid://SEU_ASSET",
        Trash = "rbxassetid://SEU_ASSET",
        Copy = "rbxassetid://SEU_ASSET",
        Star = "rbxassetid://SEU_ASSET",
        Heart = "rbxassetid://SEU_ASSET",
        Flag = "rbxassetid://SEU_ASSET",
        Bell = "rbxassetid://SEU_ASSET",
        Gear = "rbxassetid://SEU_ASSET",
        Lock = "rbxassetid://SEU_ASSET",
        Unlock = "rbxassetid://SEU_ASSET",
        Eye = "rbxassetid://SEU_ASSET",
        EyeOff = "rbxassetid://SEU_ASSET",
        Refresh = "rbxassetid://SEU_ASSET",
        Download = "rbxassetid://SEU_ASSET",
        Upload = "rbxassetid://SEU_ASSET",
        Link = "rbxassetid://SEU_ASSET",
        Unlink = "rbxassetid://SEU_ASSET",
        Filter = "rbxassetid://SEU_ASSET",
        Sort = "rbxassetid://SEU_ASSET",
        Menu = "rbxassetid://SEU_ASSET",
        MoreHorizontal = "rbxassetid://SEU_ASSET",
        MoreVertical = "rbxassetid://SEU_ASSET",
        ExternalLink = "rbxassetid://SEU_ASSET",
        Calendar = "rbxassetid://SEU_ASSET",
        Clock = "rbxassetid://SEU_ASSET",
        User = "rbxassetid://SEU_ASSET",
        Users = "rbxassetid://SEU_ASSET",
        Mail = "rbxassetid://SEU_ASSET",
        Phone = "rbxassetid://SEU_ASSET",
        MapPin = "rbxassetid://SEU_ASSET",
        Globe = "rbxassetid://SEU_ASSET",
        Code = "rbxassetid://SEU_ASSET",
        Terminal = "rbxassetid://SEU_ASSET",
        Database = "rbxassetid://SEU_ASSET",
        Cloud = "rbxassetid://SEU_ASSET",
        Wifi = "rbxassetid://SEU_ASSET",
        Bluetooth = "rbxassetid://SEU_ASSET",
        Battery = "rbxassetid://SEU_ASSET",
        Volume = "rbxassetid://SEU_ASSET",
        VolumeOff = "rbxassetid://SEU_ASSET",
        Mic = "rbxassetid://SEU_ASSET",
        MicOff = "rbxassetid://SEU_ASSET",
        Camera = "rbxassetid://SEU_ASSET",
        Image = "rbxassetid://SEU_ASSET",
        Video = "rbxassetid://SEU_ASSET",
        Music = "rbxassetid://SEU_ASSET",
        File = "rbxassetid://SEU_ASSET",
        Folder = "rbxassetid://SEU_ASSET",
        Bookmark = "rbxassetid://SEU_ASSET",
        Tag = "rbxassetid://SEU_ASSET",
        Hash = "rbxassetid://SEU_ASSET",
        AtSign = "rbxassetid://SEU_ASSET",
        Send = "rbxassetid://SEU_ASSET",
        Share = "rbxassetid://SEU_ASSET",
        Save = "rbxassetid://SEU_ASSET"
    }
end

----------------------------------------------------------------
Modules["Theme"] = function()
    local Signal = loadModule("Signal")
    local Helpers = loadModule("Helpers")
    
    local Theme = {}
    
    Theme.Changed = Signal.new()
    
    Theme._themes = {
        Dark = {
            Background = Color3.fromRGB(12, 12, 12),
            SecondaryBackground = Color3.fromRGB(20, 20, 22),
            Topbar = Color3.fromRGB(10, 10, 10),
            Border = Color3.fromRGB(30, 30, 30),
            Accent = Color3.fromRGB(80, 210, 255),
            Hover = Color3.fromRGB(25, 25, 28),
            Success = Color3.fromRGB(70, 200, 120),
            Warning = Color3.fromRGB(255, 185, 50),
            Error = Color3.fromRGB(255, 75, 75),
            Text = Color3.fromRGB(240, 240, 240),
            SubText = Color3.fromRGB(150, 150, 150),
            Shadow = Color3.fromRGB(0, 0, 0),
            Input = Color3.fromRGB(25, 25, 28),
            Divider = Color3.fromRGB(35, 35, 38),
            Overlay = Color3.fromRGB(0, 0, 0)
        },
        Light = {
            Background = Color3.fromRGB(240, 240, 245),
            SecondaryBackground = Color3.fromRGB(250, 250, 252),
            Topbar = Color3.fromRGB(230, 230, 235),
            Border = Color3.fromRGB(200, 200, 210),
            Accent = Color3.fromRGB(0, 140, 230),
            Hover = Color3.fromRGB(225, 225, 232),
            Success = Color3.fromRGB(50, 180, 100),
            Warning = Color3.fromRGB(230, 160, 30),
            Error = Color3.fromRGB(220, 60, 60),
            Text = Color3.fromRGB(30, 30, 35),
            SubText = Color3.fromRGB(100, 100, 110),
            Shadow = Color3.fromRGB(150, 150, 160),
            Input = Color3.fromRGB(235, 235, 240),
            Divider = Color3.fromRGB(210, 210, 218),
            Overlay = Color3.fromRGB(0, 0, 0)
        }
    }
    
    Theme._current = "Dark"
    Theme._colors = Helpers.deepCopy(Theme._themes.Dark)
    
    function Theme:GetColor(token)
        return self._colors[token]
    end
    
    function Theme:SetTheme(name)
        if self._themes[name] then
            self._current = name
            self._colors = Helpers.deepCopy(self._themes[name])
            self.Changed:Fire(name)
        end
    end
    
    function Theme:GetThemeName()
        return self._current
    end
    
    function Theme:CreateTheme(name, colors)
        local newTheme = Helpers.deepCopy(self._themes.Dark)
        for k, v in pairs(colors) do
            newTheme[k] = v
        end
        self._themes[name] = newTheme
    end
    
    function Theme:SetColor(token, color)
        if self._colors[token] then
            self._colors[token] = color
            self._themes[self._current][token] = color
        end
    end
    
    function Theme:GetAllColors()
        return Helpers.deepCopy(self._colors)
    end
    
    return Theme
end

----------------------------------------------------------------
Modules["Config"] = function()
    local Helpers = loadModule("Helpers")
    
    local Config = {}
    
    Config._defaults = {
        Title = "UI Library",
        Logo = "rbxassetid://SEU_ASSET",
        Theme = "Dark",
        Font = Enum.Font.GothamMedium,
        FontBold = Enum.Font.GothamBold,
        AccentColor = nil,
        BorderRadius = 8,
        AnimationSpeed = 0.3,
        AnimationEasing = Enum.EasingStyle.Quart,
        AnimationDirection = Enum.EasingDirection.Out,
        Padding = 8,
        Scale = 1,
        WindowSize = UDim2.new(0, 780, 0, 470),
        TabWidth = 160,
        TopBarHeight = 42,
        ComponentHeight = 36,
        SaveEnabled = true,
        SaveKey = "UILibrary_Save",
        KeybindToggle = Enum.KeyCode.RightShift,
        SearchEnabled = true,
        NotificationDuration = 5,
        NotificationMax = 5,
        MobileScaleMultiplier = 1.15
    }
    
    Config._config = Helpers.deepCopy(Config._defaults)
    
    function Config:Get(key)
        return self._config[key]
    end
    
    function Config:Set(key, value)
        if self._config[key] ~= nil then
            self._config[key] = value
        end
    end
    
    function Config:Reset()
        self._config = Helpers.deepCopy(self._defaults)
    end
    
    function Config:GetAll()
        return Helpers.deepCopy(self._config)
    end
    
    function Config:SetMultiple(tbl)
        for k, v in pairs(tbl) do
            self:Set(k, v)
        end
    end
    
    return Config
end

----------------------------------------------------------------
Modules["Tween"] = function()
    local Config = loadModule("Config")
    local Tween = {}
    
    function Tween:GetInfo(duration, easingStyle, easingDirection)
        return TweenInfo.new(
            duration or Config:Get("AnimationSpeed"),
            easingStyle or Config:Get("AnimationEasing"),
            easingDirection or Config:Get("AnimationDirection")
        )
    end
    
    function Tween:Create(instance, tweenInfo, properties)
        return TweenService:Create(instance, tweenInfo, properties)
    end
    
    function Tween:Run(instance, tweenInfo, properties)
        local tween = self:Create(instance, tweenInfo, properties)
        tween:Play()
        return tween
    end
    
    function Tween:RunCallback(instance, tweenInfo, properties, callback)
        local tween = self:Create(instance, tweenInfo, properties)
        local connection
        connection = tween.Completed:Connect(function()
            connection:Disconnect()
            if callback then callback() end
        end)
        tween:Play()
        return tween
    end
    
    function Tween:Cancel(tween)
        if tween and typeof(tween) == "Instance" and tween.ClassName == "Tween" then
            tween:Cancel()
        end
    end
    
    function Tween:FadeIn(instance, duration)
        local props = { BackgroundTransparency = 0 }
        if instance:IsA("TextLabel") or instance:IsA("TextButton") then
            props.TextTransparency = 0
        end
        return self:Run(instance, self:GetInfo(duration), props)
    end
    
    function Tween:FadeOut(instance, duration)
        local props = { BackgroundTransparency = 1 }
        if instance:IsA("TextLabel") or instance:IsA("TextButton") then
            props.TextTransparency = 1
        end
        return self:Run(instance, self:GetInfo(duration), props)
    end
    
    function Tween:ScaleIn(instance, duration)
        instance.Size = UDim2.new(0.8, 0, 0.8, 0)
        return self:Run(instance, self:GetInfo(duration), { Size = UDim2.new(1, 0, 1, 0) })
    end
    
    function Tween:ScaleOut(instance, duration)
        return self:Run(instance, self:GetInfo(duration), { Size = UDim2.new(0.8, 0, 0.8, 0) })
    end
    
    function Tween:SlideIn(instance, duration, direction)
        return self:Run(instance, self:GetInfo(duration), { Position = direction })
    end
    
    function Tween:SlideOut(instance, duration, direction)
        return self:Run(instance, self:GetInfo(duration), { Position = direction })
    end
    
    return Tween
end

----------------------------------------------------------------
Modules["Mobile"] = function()
    local Config = loadModule("Config")
    local Create = loadModule("Create")
    local Icons = loadModule("Icons")
    
    local Mobile = {}
    Mobile._isMobile = nil
    
    function Mobile:IsMobile()
        if self._isMobile ~= nil then return self._isMobile end
        
        local screenSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
        local isTouch = UserInputService.TouchEnabled
        local hasMouse = UserInputService.MouseEnabled
        
        if screenSize.X < 800 or (isTouch and not hasMouse) then
            self._isMobile = true
        else
            self._isMobile = false
        end
        
        return self._isMobile
    end
    
    function Mobile:GetScale()
        if self:IsMobile() then
            return Config:Get("MobileScaleMultiplier")
        end
        return 1
    end
    
    function Mobile:GetPadding()
        return Config:Get("Padding") * self:GetScale()
    end
    
    function Mobile:GetComponentHeight()
        return Config:Get("ComponentHeight") * self:GetScale()
    end
    
    function Mobile:GetFontSize(baseSize)
        return math.floor(baseSize * self:GetScale())
    end
    
    function Mobile:GetSafeArea()
        return GuiService:GetGuiInset()
    end
    
    function Mobile:CreateFloatingButton(screenGui, onClick)
        local frame = Create.new("ImageButton", {
            Name = "FloatingButton",
            Size = UDim2.new(0, 60, 0, 60),
            Position = UDim2.new(1, -80, 0, 80),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(27, 27, 30),
            AutoButtonColor = false,
            ZIndex = 999
        })
        
        Create.new("UICorner", {
            CornerRadius = UDim.new(0, 30),
            Parent = frame
        })
        
        Create.new("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = Icons.Logo,
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ZIndex = 1000,
            Parent = frame
        })
        
        local dragging = false
        local dragInput, dragStart, startPos
        
        local function update(input)
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
        
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
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
        
        frame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                update(input)
            end
        end)
        
        frame.MouseButton1Click:Connect(function()
            if onClick then onClick() end
        end)
        
        frame.Parent = screenGui
        return frame
    end
    
    return Mobile
end

----------------------------------------------------------------
Modules["Save"] = function()
    local HttpService = game:GetService("HttpService")
    local Config = loadModule("Config")
    local Save = {}
    
    Save._data = {}
    Save._loaded = false
    
    function Save:_getFilePath()
        return Config:Get("SaveKey") .. ".json"
    end
    
    function Save:Load()
        local path = self:_getFilePath()
        local success, result = pcall(function()
            if readfile then
                return readfile(path)
            end
            return nil
        end)
        
        if success and result then
            local decodedSuccess, decodedData = pcall(function()
                return HttpService:JSONDecode(result)
            end)
            if decodedSuccess and type(decodedData) == "table" then
                self._data = decodedData
            end
        else
            self._data = {}
        end
        
        self._loaded = true
    end
    
    function Save:Save()
        if not Config:Get("SaveEnabled") then return end
        local path = self:_getFilePath()
        pcall(function()
            if writefile then
                writefile(path, HttpService:JSONEncode(self._data))
            end
        end)
    end
    
    function Save:Set(key, value)
        self._data[key] = value
        self:Save()
    end
    
    function Save:Get(key, default)
        if self._data[key] ~= nil then
            return self._data[key]
        end
        return default
    end
    
    function Save:Delete(key)
        self._data[key] = nil
        self:Save()
    end
    
    function Save:Clear()
        self._data = {}
        self:Save()
    end
    
    function Save:GetAll()
        local Helpers = loadModule("Helpers")
        return Helpers.deepCopy(self._data)
    end
    
    return Save
end
-- ==========================================
-- MODULE: Window
-- ==========================================
Modules["Window"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Config = loadModule("Config")
    local Tween = loadModule("Tween")
    local Mobile = loadModule("Mobile")
    local Icons = loadModule("Icons")
    local Maid = loadModule("Maid")
    local Signal = loadModule("Signal")
    
    local UserInputService = game:GetService("UserInputService")
    local CoreGui = game:GetService("CoreGui")
    
    local function getScreenGui()
        local screenGui = Create.new("ScreenGui", {
            Name = Config:Get("Title"),
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Global,
            IgnoreGuiInset = true,
        })
        -- Try to protect gui
        local success = pcall(function()
            screenGui.Parent = CoreGui
        end)
        if not success then
            local Players = game:GetService("Players")
            if Players.LocalPlayer then
                screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
            end
        end
        return screenGui
    end

    local Window = {}
    Window.__index = Window

    function Window.new(config)
        local self = setmetatable({}, Window)
        self._maid = Maid.new()
        self._tabs = {}
        self._activeTab = nil
        self._searchableElements = {}
        self._visible = true
        
        self._screenGui = getScreenGui()
        self._maid:GiveTask(self._screenGui)
        
        self:_build(config or {})
        self:_setupDrag()
        self:_setupSearch()
        self:_setupTheme()
        self:_setupKeybind()
        
        -- Open animation
        self._mainFrame.Size = UDim2.new(0, 0, 0, 0)
        self._shadowFrame.Size = UDim2.new(0, 0, 0, 0)
        
        local windowSize = Config:Get("WindowSize")
        self._mainFrame.GroupTransparency = 1
        
        local tweenInfo = Tween:GetInfo(Config:Get("AnimationSpeed"), Config:Get("AnimationEasing"), Config:Get("AnimationDirection"))
        Tween:Run(self._mainFrame, tweenInfo, {
            Size = windowSize,
            GroupTransparency = 0
        })
        Tween:Run(self._shadowFrame, tweenInfo, {
            Size = UDim2.new(0, windowSize.X.Offset + 20, 0, windowSize.Y.Offset + 20)
        })

        return self
    end

    function Window:_build(config)
        local windowSize = Config:Get("WindowSize")
        
        self._shadowFrame = Create.new("ImageLabel", {
            Name = "Shadow",
            Parent = self._screenGui,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, windowSize.X.Offset + 20, 0, windowSize.Y.Offset + 20),
            BackgroundTransparency = 1,
            Image = "rbxassetid://6015536813",
            ImageColor3 = Color3.new(0, 0, 0),
            ImageTransparency = 0.5,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(49, 49, 450, 450)
        })

        self._mainFrame = Create.new("CanvasGroup", {
            Name = "MainFrame",
            Parent = self._screenGui,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = windowSize,
            BackgroundColor3 = Theme:GetColor("Background"),
            BorderSizePixel = 0,
        }, {
            Create.new("UICorner", {
                CornerRadius = UDim.new(0, Config:Get("BorderRadius"))
            }),
            Create.new("UIStroke", {
                Color = Theme:GetColor("Border"),
                Thickness = 1
            })
        })
        
        self._topBar = Create.new("Frame", {
            Name = "TopBar",
            Parent = self._mainFrame,
            Size = UDim2.new(1, 0, 0, Config:Get("TopBarHeight")),
            BackgroundColor3 = Theme:GetColor("Topbar"),
            BorderSizePixel = 0,
        }, {
            Create.new("Frame", {
                Name = "BottomLine",
                Size = UDim2.new(1, 0, 0, 1),
                Position = UDim2.new(0, 0, 1, -1),
                BackgroundColor3 = Theme:GetColor("Border"),
                BorderSizePixel = 0
            })
        })

        self._logoImage = Create.new("ImageLabel", {
            Name = "Logo",
            Parent = self._topBar,
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(0, Config:Get("Padding"), 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Image = Config:Get("Logo") or Icons.Logo
        })

        self._titleLabel = Create.new("TextLabel", {
            Name = "Title",
            Parent = self._topBar,
            Size = UDim2.new(1, -200, 1, 0),
            Position = UDim2.new(0, 40, 0, 0),
            BackgroundTransparency = 1,
            Text = config.Title or Config:Get("Title"),
            TextColor3 = Theme:GetColor("Text"),
            Font = Config:Get("FontBold"),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        self._closeButton = Create.new("ImageButton", {
            Name = "Close",
            Parent = self._topBar,
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(1, -Config:Get("Padding"), 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
            Image = Icons.Close,
            ImageColor3 = Theme:GetColor("SubText")
        })

        self._maid:GiveTask(self._closeButton.MouseButton1Click:Connect(function()
            self:Destroy()
        end))
        
        self._maid:GiveTask(self._closeButton.MouseEnter:Connect(function()
            Tween:Run(self._closeButton, Tween:GetInfo(0.2), {ImageColor3 = Theme:GetColor("Error")})
        end))
        self._maid:GiveTask(self._closeButton.MouseLeave:Connect(function()
            Tween:Run(self._closeButton, Tween:GetInfo(0.2), {ImageColor3 = Theme:GetColor("SubText")})
        end))

        if Mobile:IsMobile() then
            self._minimizeButton = Create.new("ImageButton", {
                Name = "Minimize",
                Parent = self._topBar,
                Size = UDim2.new(0, 24, 0, 24),
                Position = UDim2.new(1, -Config:Get("Padding") - 30, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Image = Icons.Minimize,
                ImageColor3 = Theme:GetColor("SubText")
            })
            
            self._maid:GiveTask(self._minimizeButton.MouseButton1Click:Connect(function()
                self:SetVisible(false)
                self._floatingButton = Mobile:CreateFloatingButton(self._screenGui, function()
                    self:SetVisible(true)
                    if self._floatingButton then
                        self._floatingButton:Destroy()
                        self._floatingButton = nil
                    end
                end)
            end))
        end
        
        if Config:Get("SearchEnabled") then
            self._searchFrame = Create.new("Frame", {
                Name = "SearchFrame",
                Parent = self._topBar,
                Size = UDim2.new(0, 160, 0, 28),
                Position = UDim2.new(1, -Config:Get("Padding") - (Mobile:IsMobile() and 60 or 30), 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = Theme:GetColor("Input"),
                BorderSizePixel = 0
            }, {
                Create.new("UICorner", { CornerRadius = UDim.new(0, 4) }),
                Create.new("UIStroke", {
                    Name = "Stroke",
                    Color = Theme:GetColor("Border"),
                    Thickness = 1
                })
            })
            
            self._searchIcon = Create.new("ImageLabel", {
                Name = "Icon",
                Parent = self._searchFrame,
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(0, 8, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                Image = Icons.Search,
                ImageColor3 = Theme:GetColor("SubText")
            })
            
            self._searchTextBox = Create.new("TextBox", {
                Name = "Input",
                Parent = self._searchFrame,
                Size = UDim2.new(1, -30, 1, 0),
                Position = UDim2.new(0, 26, 0, 0),
                BackgroundTransparency = 1,
                Text = "",
                PlaceholderText = "Search...",
                PlaceholderColor3 = Theme:GetColor("SubText"),
                TextColor3 = Theme:GetColor("Text"),
                Font = Config:Get("Font"),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false
            })
        end

        self._tabContainer = Create.new("Frame", {
            Name = "TabContainer",
            Parent = self._topBar,
            Size = UDim2.new(0.5, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
        }, {
            Create.new("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 10)
            }),
            Create.new("UIPadding", { PaddingRight = UDim.new(0, 40) })
        })

        self._bodyFrame = Create.new("Frame", {
            Name = "Body",
            Parent = self._mainFrame,
            Size = UDim2.new(1, 0, 1, -Config:Get("TopBarHeight")),
            Position = UDim2.new(0, 0, 0, Config:Get("TopBarHeight")),
            BackgroundTransparency = 1
        })
        
        self._contentContainer = Create.new("Frame", {
            Name = "Content",
            Parent = self._bodyFrame,
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        }, {
            Create.new("UIPadding", {
                PaddingTop = UDim.new(0, Config:Get("Padding")),
                PaddingBottom = UDim.new(0, Config:Get("Padding")),
                PaddingLeft = UDim.new(0, Config:Get("Padding")),
                PaddingRight = UDim.new(0, Config:Get("Padding"))
            })
        })
    end

    function Window:_setupDrag()
        local dragging, dragStart, startPos
        self._maid:GiveTask(self._topBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = self._mainFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end))
        self._maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                self._mainFrame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end))
    end
    
    function Window:_setupSearch()
        if not self._searchTextBox then return end
        
        self._maid:GiveTask(self._searchTextBox.Focused:Connect(function()
            Tween:Run(self._searchFrame.Stroke, Tween:GetInfo(0.2), {Color = Theme:GetColor("Accent")})
        end))
        
        self._maid:GiveTask(self._searchTextBox.FocusLost:Connect(function()
            Tween:Run(self._searchFrame.Stroke, Tween:GetInfo(0.2), {Color = Theme:GetColor("Border")})
        end))
        
        self._maid:GiveTask(self._searchTextBox:GetPropertyChangedSignal("Text"):Connect(function()
            self:_performSearch(self._searchTextBox.Text)
        end))
    end
    
    function Window:_setupTheme()
        self._maid:GiveTask(Theme.Changed:Connect(function()
            self._mainFrame.BackgroundColor3 = Theme:GetColor("Background")
            self._mainFrame.UIStroke.Color = Theme:GetColor("Border")
            self._topBar.BackgroundColor3 = Theme:GetColor("Topbar")
            self._topBar.BottomLine.BackgroundColor3 = Theme:GetColor("Border")
            self._titleLabel.TextColor3 = Theme:GetColor("Text")
            self._closeButton.ImageColor3 = Theme:GetColor("SubText")
            
            if self._minimizeButton then
                self._minimizeButton.ImageColor3 = Theme:GetColor("SubText")
            end
            
            if self._searchFrame then
                self._searchFrame.BackgroundColor3 = Theme:GetColor("Input")
                self._searchFrame.Stroke.Color = Theme:GetColor("Border")
                self._searchIcon.ImageColor3 = Theme:GetColor("SubText")
                self._searchTextBox.PlaceholderColor3 = Theme:GetColor("SubText")
                self._searchTextBox.TextColor3 = Theme:GetColor("Text")
            end
        end))
    end
    
    function Window:_setupKeybind()
        self._maid:GiveTask(UserInputService.InputBegan:Connect(function(input, processed)
            if not processed and input.KeyCode == Config:Get("KeybindToggle") then
                self:Toggle()
            end
        end))
    end

    function Window:CreateTab(config)
        local Tab = loadModule("Tab")
        local tab = Tab.new(config, self)
        table.insert(self._tabs, tab)
        if #self._tabs == 1 then
            tab:SetActive(true)
        end
        return tab
    end

    function Window:SetTitle(title)
        self._titleLabel.Text = title
    end

    function Window:SetVisible(visible)
        self._visible = visible
        local tweenInfo = Tween:GetInfo(Config:Get("AnimationSpeed"), Config:Get("AnimationEasing"), Config:Get("AnimationDirection"))
        
        if visible then
            self._mainFrame.Visible = true
            self._shadowFrame.Visible = true
            Tween:Run(self._mainFrame, tweenInfo, {GroupTransparency = 0})
            Tween:Run(self._shadowFrame, tweenInfo, {ImageTransparency = 0.5})
        else
            local t = Tween:Run(self._mainFrame, tweenInfo, {GroupTransparency = 1})
            Tween:Run(self._shadowFrame, tweenInfo, {ImageTransparency = 1})
            
            self._maid:GiveTask(t.Completed:Connect(function()
                if not self._visible then
                    self._mainFrame.Visible = false
                    self._shadowFrame.Visible = false
                end
            end))
        end
    end

    function Window:Toggle()
        self:SetVisible(not self._visible)
    end

    function Window:Destroy()
        local tweenInfo = Tween:GetInfo(Config:Get("AnimationSpeed"), Config:Get("AnimationEasing"), Config:Get("AnimationDirection"))
        local t = Tween:Run(self._mainFrame, tweenInfo, {GroupTransparency = 1, Size = UDim2.new(0, 0, 0, 0)})
        Tween:Run(self._shadowFrame, tweenInfo, {ImageTransparency = 1, Size = UDim2.new(0, 0, 0, 0)})
        
        self._maid:GiveTask(t.Completed:Connect(function()
            self._maid:DoCleaning()
        end))
    end

    function Window:Notify(config)
        local Notification = loadModule("Notification")
        return Notification.new(config)
    end

    function Window:Dialog(config)
        local Dialog = loadModule("Dialog")
        return Dialog.new(config, self._screenGui)
    end

    function Window:_registerSearchable(name, frame)
        table.insert(self._searchableElements, {name = name, frame = frame})
    end

    function Window:_performSearch(query)
        if query == "" then
            for _, element in ipairs(self._searchableElements) do
                element.frame.Visible = true
            end
        else
            local lowerQuery = string.lower(query)
            for _, element in ipairs(self._searchableElements) do
                if string.find(string.lower(element.name), lowerQuery) then
                    element.frame.Visible = true
                else
                    element.frame.Visible = false
                end
            end
        end
    end

    return Window
end

-- ==========================================
-- MODULE: Tab
-- ==========================================
Modules["Tab"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Config = loadModule("Config")
    local Tween = loadModule("Tween")
    local Maid = loadModule("Maid")
    
    local Tab = {}
    Tab.__index = Tab
    
    function Tab.new(config, window)
        local self = setmetatable({}, Tab)
        self._name = config.Name or "Tab"
        self._icon = config.Icon
        self._window = window
        self._active = false
        self._sections = {}
        self._maid = Maid.new()
        
        self:_build()
        self:_setupTheme()
        return self
    end
    
    function Tab:_build()
        self._button = Create.new("TextButton", {
            Name = self._name,
            Parent = self._window._tabContainer,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Theme:GetColor("SecondaryBackground"),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            BorderSizePixel = 0,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 6) })
        })
        
        self._indicator = Create.new("Frame", {
            Name = "Indicator",
            Parent = self._button,
            Size = UDim2.new(1, 0, 0, 2),
            Position = UDim2.new(0, 0, 1, -2),
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = Theme:GetColor("Accent"),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 2) })
        })
        
        local textOffset = 8
        if self._icon then
            self._iconImage = Create.new("ImageLabel", {
                Name = "Icon",
                Parent = self._button,
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(0, 8, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                Image = self._icon,
                ImageColor3 = Theme:GetColor("SubText")
            })
            textOffset = 32
        end
        
        self._nameLabel = Create.new("TextLabel", {
            Name = "Title",
            Parent = self._button,
            Size = UDim2.new(1, -textOffset - 8, 1, 0),
            Position = UDim2.new(0, textOffset, 0, 0),
            BackgroundTransparency = 1,
            Text = self._name,
            TextColor3 = Theme:GetColor("SubText"),
            Font = Config:Get("Font"),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        self._content = Create.new("ScrollingFrame", {
            Name = self._name .. "Content",
            Parent = self._window._contentContainer,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme:GetColor("Accent"),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Visible = false
        }, {
            Create.new("UIPadding", {
                PaddingTop = UDim.new(0, 0),
                PaddingBottom = UDim.new(0, 0),
                PaddingLeft = UDim.new(0, 0),
                PaddingRight = UDim.new(0, 10)
            })
        })
        
        self._leftColumn = Create.new("Frame", {
            Name = "LeftColumn",
            Parent = self._content,
            Size = UDim2.new(0.5, -4, 1, 0),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y
        }, {
            Create.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
        })
        self._rightColumn = Create.new("Frame", {
            Name = "RightColumn",
            Parent = self._content,
            Size = UDim2.new(0.5, -4, 1, 0),
            Position = UDim2.new(0.5, 4, 0, 0),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y
        }, {
            Create.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
        })
        
        self._window:_registerSearchable(self._name, self._button)
        
        self._maid:GiveTask(self._button.MouseEnter:Connect(function()
            if not self._active then
                Tween:Run(self._button, Tween:GetInfo(0.2), {BackgroundColor3 = Theme:GetColor("Hover"), BackgroundTransparency = 0})
            end
        end))
        
        self._maid:GiveTask(self._button.MouseLeave:Connect(function()
            if not self._active then
                Tween:Run(self._button, Tween:GetInfo(0.2), {BackgroundTransparency = 1})
            end
        end))
        
        self._maid:GiveTask(self._button.MouseButton1Click:Connect(function()
            self:SetActive(true)
        end))
    end
    
    function Tab:_setupTheme()
        self._maid:GiveTask(Theme.Changed:Connect(function()
            self._indicator.BackgroundColor3 = Theme:GetColor("Accent")
            self._content.ScrollBarImageColor3 = Theme:GetColor("Accent")
            if self._active then
                self._button.BackgroundColor3 = Theme:GetColor("SecondaryBackground")
                self._nameLabel.TextColor3 = Theme:GetColor("Text")
                if self._iconImage then self._iconImage.ImageColor3 = Theme:GetColor("Text") end
            else
                self._nameLabel.TextColor3 = Theme:GetColor("SubText")
                if self._iconImage then self._iconImage.ImageColor3 = Theme:GetColor("SubText") end
            end
        end))
    end
    
    function Tab:CreateSection(name)
        local Section = loadModule("Section")
        local section = Section.new(name, self)
        table.insert(self._sections, section)
        return section
    end
    
    function Tab:SetActive(active)
        if active then
            if self._window._activeTab and self._window._activeTab ~= self then
                self._window._activeTab:SetActive(false)
            end
            self._window._activeTab = self
        end
        
        self._active = active
        self._content.Visible = active
        
        local tweenInfo = Tween:GetInfo(0.2)
        if active then
            Tween:Run(self._indicator, tweenInfo, {BackgroundTransparency = 0})
            Tween:Run(self._button, tweenInfo, {BackgroundColor3 = Theme:GetColor("SecondaryBackground"), BackgroundTransparency = 0})
            Tween:Run(self._nameLabel, tweenInfo, {TextColor3 = Theme:GetColor("Text")})
            if self._iconImage then
                Tween:Run(self._iconImage, tweenInfo, {ImageColor3 = Theme:GetColor("Text")})
            end
        else
            Tween:Run(self._indicator, tweenInfo, {BackgroundTransparency = 1})
            Tween:Run(self._button, tweenInfo, {BackgroundTransparency = 1})
            Tween:Run(self._nameLabel, tweenInfo, {TextColor3 = Theme:GetColor("SubText")})
            if self._iconImage then
                Tween:Run(self._iconImage, tweenInfo, {ImageColor3 = Theme:GetColor("SubText")})
            end
        end
    end
    
    function Tab:Destroy()
        self._maid:DoCleaning()
        if self._button then self._button:Destroy() end
        if self._content then self._content:Destroy() end
    end
    
    return Tab
end

-- ==========================================
-- MODULE: Section
-- ==========================================
Modules["Section"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Config = loadModule("Config")
    local Maid = loadModule("Maid")
    local Helpers = loadModule("Helpers")
    
    local Section = {}
    Section.__index = Section
    
    function Section.new(name, tab)
        local self = setmetatable({}, Section)
        self._name = name or "Section"
        self._tab = tab
        self._maid = Maid.new()
        
        self:_build()
        self:_setupTheme()
        return self
    end
    
    function Section:_build()
        self._frame = Create.new("Frame", {
            Name = "Section_" .. self._name,
            Parent = self._tab._leftColumn,
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 0,
            BackgroundColor3 = Theme:GetColor("SecondaryBackground"),
            AutomaticSize = Enum.AutomaticSize.Y,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 6) }),
            Create.new("UIStroke", {
                Color = Theme:GetColor("Border"),
                Thickness = 1
            })
        })
        
        self._header = Create.new("Frame", {
            Name = "Header",
            Parent = self._frame,
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
        })
        
        self._title = Create.new("TextLabel", {
            Name = "Title",
            Parent = self._header,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = self._name,
            TextColor3 = Theme:GetColor("SubText"),
            Font = Config:Get("FontBold"),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        
        self._divider = Create.new("Frame", {
            Name = "Divider",
            Parent = self._header,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            BackgroundColor3 = Theme:GetColor("Divider"),
            BorderSizePixel = 0,
        })
        
        self._maid:GiveTask(self._title:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            self._divider.Size = UDim2.new(1, -self._title.AbsoluteSize.X - 16, 0, 1)
        end))
        self._divider.Size = UDim2.new(1, -self._title.AbsoluteSize.X - 16, 0, 1)
        
        self._content = Create.new("Frame", {
            Name = "Content",
            Parent = self._frame,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 0, 28),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
        }, {
            Create.new("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4)
            })
        })
        
        self._tab._window:_registerSearchable(self._name, self._frame)
    end
    
    function Section:_setupTheme()
        self._maid:GiveTask(Theme.Changed:Connect(function()
            self._title.TextColor3 = Theme:GetColor("SubText")
            self._divider.BackgroundColor3 = Theme:GetColor("Divider")
        end))
    end
    
    function Section:CreateButton(config)
        local Button = loadModule("Button")
        local component = Button.new(config, self)
        self._tab._window:_registerSearchable(config.Name or "Button", component._frame)
        return component
    end
    
    function Section:CreateToggle(config)
        local Toggle = loadModule("Toggle")
        local component = Toggle.new(config, self)
        self._tab._window:_registerSearchable(config.Name or "Toggle", component._frame)
        return component
    end
    
    function Section:CreateSlider(config)
        local Slider = loadModule("Slider")
        local component = Slider.new(config, self)
        self._tab._window:_registerSearchable(config.Name or "Slider", component._frame)
        return component
    end
    
    function Section:CreateDropdown(config)
        local Dropdown = loadModule("Dropdown")
        local component = Dropdown.new(config, self)
        self._tab._window:_registerSearchable(config.Name or "Dropdown", component._frame)
        return component
    end
    
    function Section:CreateTextbox(config)
        local Textbox = loadModule("Textbox")
        local component = Textbox.new(config, self)
        self._tab._window:_registerSearchable(config.Name or "Textbox", component._frame)
        return component
    end
    
    function Section:CreateLabel(config)
        local Label = loadModule("Label")
        local component = Label.new(config, self)
        self._tab._window:_registerSearchable(config.Name or "Label", component._frame)
        return component
    end
    
    function Section:CreateParagraph(config)
        local Paragraph = loadModule("Paragraph")
        local component = Paragraph.new(config, self)
        self._tab._window:_registerSearchable(config.Name or "Paragraph", component._frame)
        return component
    end
    
    function Section:CreateKeybind(config)
        local Keybind = loadModule("Keybind")
        local component = Keybind.new(config, self)
        self._tab._window:_registerSearchable(config.Name or "Keybind", component._frame)
        return component
    end
    
    function Section:CreateColorPicker(config)
        local ColorPicker = loadModule("ColorPicker")
        local component = ColorPicker.new(config, self)
        self._tab._window:_registerSearchable(config.Name or "ColorPicker", component._frame)
        return component
    end
    
    function Section:CreateSeparator(config)
        local Separator = loadModule("Separator")
        return Separator.new(config, self)
    end
    
    function Section:CreateProgressBar(config) return nil end
    function Section:CreateImage(config) return nil end
    function Section:CreateContainer(config) return nil end
    function Section:CreateBadge(config) return nil end
    function Section:CreateChip(config) return nil end
    function Section:CreateAccordion(config) return nil end
    function Section:CreateStatusIndicator(config) return nil end
    
    function Section:Destroy()
        self._maid:DoCleaning()
        if self._frame then self._frame:Destroy() end
    end
    
    return Section
end

-- ==========================================
-- MODULE: Button
-- ==========================================
Modules["Button"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Tween = loadModule("Tween")
    local Config = loadModule("Config")
    local Maid = loadModule("Maid")
    local Signal = loadModule("Signal")
    
    local Button = {}
    Button.__index = Button
    
    function Button.new(config, section)
        local self = setmetatable({}, Button)
        self._config = config
        self._section = section
        self._maid = Maid.new()
        
        self:_build()
        self:_setupTheme()
        return self
    end
    
    function Button:_build()
        local height = self._config.Description and 50 or Config:Get("ComponentHeight")
        
        self._frame = Create.new("TextButton", {
            Name = self._config.Name or "Button",
            Parent = self._section._content,
            Size = UDim2.new(1, 0, 0, height),
            BackgroundColor3 = Theme:GetColor("SecondaryBackground"),
            AutoButtonColor = false,
            Text = "",
            BorderSizePixel = 0,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 6) })
        })
        
        self._nameLabel = Create.new("TextLabel", {
            Name = "Name",
            Parent = self._frame,
            Size = UDim2.new(1, -32, 0, 20),
            Position = UDim2.new(0, Config:Get("Padding"), 0, self._config.Description and 8 or height/2 - 10),
            BackgroundTransparency = 1,
            Text = self._config.Name or "Button",
            TextColor3 = Theme:GetColor("Text"),
            Font = Config:Get("Font"),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        
        if self._config.Description then
            self._descLabel = Create.new("TextLabel", {
                Name = "Description",
                Parent = self._frame,
                Size = UDim2.new(1, -32, 0, 14),
                Position = UDim2.new(0, Config:Get("Padding"), 0, 28),
                BackgroundTransparency = 1,
                Text = self._config.Description,
                TextColor3 = Theme:GetColor("SubText"),
                Font = Config:Get("Font"),
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
        end
        
        if self._config.Icon then
            self._iconImage = Create.new("ImageLabel", {
                Name = "Icon",
                Parent = self._frame,
                Size = UDim2.new(0, 16, 0, 16),
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -Config:Get("Padding"), 0.5, 0),
                BackgroundTransparency = 1,
                Image = self._config.Icon,
                ImageColor3 = Theme:GetColor("Text"),
            })
        end
        
        self._highlight = Create.new("Frame", {
            Name = "Highlight",
            Parent = self._frame,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Theme:GetColor("Accent"),
            BackgroundTransparency = 1,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 6) })
        })
        
        self._maid:GiveTask(self._frame.MouseEnter:Connect(function()
            Tween:Run(self._frame, Tween:GetInfo(0.2), {BackgroundColor3 = Theme:GetColor("Hover")})
        end))
        
        self._maid:GiveTask(self._frame.MouseLeave:Connect(function()
            Tween:Run(self._frame, Tween:GetInfo(0.2), {BackgroundColor3 = Theme:GetColor("SecondaryBackground")})
            Tween:Run(self._highlight, Tween:GetInfo(0.2), {BackgroundTransparency = 1})
        end))
        
        self._maid:GiveTask(self._frame.MouseButton1Down:Connect(function()
            Tween:Run(self._highlight, Tween:GetInfo(0.1), {BackgroundTransparency = 0.7})
        end))
        
        self._maid:GiveTask(self._frame.MouseButton1Up:Connect(function()
            Tween:Run(self._highlight, Tween:GetInfo(0.3), {BackgroundTransparency = 1})
        end))
        
        self._maid:GiveTask(self._frame.MouseButton1Click:Connect(function()
            if self._config.Callback then
                task.spawn(self._config.Callback)
            end
        end))
    end
    
    function Button:_setupTheme()
        self._maid:GiveTask(Theme.Changed:Connect(function()
            self._frame.BackgroundColor3 = Theme:GetColor("SecondaryBackground")
            self._nameLabel.TextColor3 = Theme:GetColor("Text")
            if self._descLabel then self._descLabel.TextColor3 = Theme:GetColor("SubText") end
            if self._iconImage then self._iconImage.ImageColor3 = Theme:GetColor("Text") end
            self._highlight.BackgroundColor3 = Theme:GetColor("Accent")
        end))
    end
    
    function Button:Destroy()
        self._maid:DoCleaning()
        if self._frame then self._frame:Destroy() end
    end
    
    return Button
end

-- ==========================================
-- MODULE: Toggle
-- ==========================================
Modules["Toggle"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Tween = loadModule("Tween")
    local Config = loadModule("Config")
    local Maid = loadModule("Maid")
    local Signal = loadModule("Signal")
    local Save = loadModule("Save")
    local Icons = loadModule("Icons")
    
    local Toggle = {}
    Toggle.__index = Toggle
    
    function Toggle.new(config, section)
        local self = setmetatable({}, Toggle)
        self._config = config
        self._section = section
        self._maid = Maid.new()
        self.Changed = Signal.new()
        
        self._value = config.Default or false
        if config.Flag then
            self._value = Save:Get(config.Flag, self._value)
        end
        
        self:_build()
        self:_setupTheme()
        self:Set(self._value, true)
        return self
    end
    
    function Toggle:_build()
        local height = self._config.Description and 50 or Config:Get("ComponentHeight")
        
        self._frame = Create.new("TextButton", {
            Name = self._config.Name or "Toggle",
            Parent = self._section._content,
            Size = UDim2.new(1, 0, 0, height),
            BackgroundColor3 = Theme:GetColor("SecondaryBackground"),
            AutoButtonColor = false,
            Text = "",
            BorderSizePixel = 0,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 6) })
        })
        
        self._nameLabel = Create.new("TextLabel", {
            Name = "Name",
            Parent = self._frame,
            Size = UDim2.new(1, -60, 0, 20),
            Position = UDim2.new(0, Config:Get("Padding"), 0, self._config.Description and 8 or height/2 - 10),
            BackgroundTransparency = 1,
            Text = self._config.Name or "Toggle",
            TextColor3 = Theme:GetColor("Text"),
            Font = Config:Get("Font"),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        
        if self._config.Description then
            self._descLabel = Create.new("TextLabel", {
                Name = "Description",
                Parent = self._frame,
                Size = UDim2.new(1, -60, 0, 14),
                Position = UDim2.new(0, Config:Get("Padding"), 0, 28),
                BackgroundTransparency = 1,
                Text = self._config.Description,
                TextColor3 = Theme:GetColor("SubText"),
                Font = Config:Get("Font"),
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
        end
        
        self._toggleFrame = Create.new("Frame", {
            Name = "ToggleFrame",
            Parent = self._frame,
            Size = UDim2.new(0, 16, 0, 16),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -Config:Get("Padding"), 0.5, 0),
            BackgroundColor3 = self._value and Theme:GetColor("Accent") or Theme:GetColor("SecondaryBackground"),
            BackgroundTransparency = self._value and 0 or 1,
            BorderSizePixel = 0,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 4) }),
            Create.new("UIStroke", {
                Name = "Stroke",
                Color = Theme:GetColor("Border"),
                Thickness = 1
            })
        })
        
        self._toggleCheck = Create.new("ImageLabel", {
            Name = "Check",
            Parent = self._toggleFrame,
            Size = UDim2.new(1, -4, 1, -4),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = Icons.Check,
            ImageColor3 = Color3.new(1, 1, 1),
            Visible = self._value
        })
        
        self._maid:GiveTask(self._frame.MouseEnter:Connect(function()
            Tween:Run(self._frame, Tween:GetInfo(0.2), {BackgroundColor3 = Theme:GetColor("Hover")})
        end))
        
        self._maid:GiveTask(self._frame.MouseLeave:Connect(function()
            Tween:Run(self._frame, Tween:GetInfo(0.2), {BackgroundColor3 = Theme:GetColor("SecondaryBackground")})
        end))
        
        self._maid:GiveTask(self._frame.MouseButton1Click:Connect(function()
            self:Set(not self._value)
        end))
    end
    
    function Toggle:_setupTheme()
        self._maid:GiveTask(Theme.Changed:Connect(function()
            self._frame.BackgroundColor3 = Theme:GetColor("SecondaryBackground")
            self._nameLabel.TextColor3 = Theme:GetColor("Text")
            if self._descLabel then self._descLabel.TextColor3 = Theme:GetColor("SubText") end
            self._toggleFrame.BackgroundColor3 = self._value and Theme:GetColor("Accent") or Theme:GetColor("SecondaryBackground")
            self._toggleFrame.Stroke.Color = Theme:GetColor("Border")
        end))
    end
    
    function Toggle:Set(value, ignoreCallback)
        self._value = value
        
        Tween:Run(self._toggleFrame, Tween:GetInfo(0.2), {
            BackgroundColor3 = value and Theme:GetColor("Accent") or Theme:GetColor("SecondaryBackground"),
            BackgroundTransparency = value and 0 or 1
        })
        
        self._toggleCheck.Visible = value
        
        if self._config.Flag then
            Save:Set(self._config.Flag, value)
        end
        
        self.Changed:Fire(value)
        
        if not ignoreCallback and self._config.Callback then
            task.spawn(self._config.Callback, value)
        end
    end
    
    function Toggle:Get()
        return self._value
    end
    
    function Toggle:Destroy()
        self._maid:DoCleaning()
        if self._frame then self._frame:Destroy() end
    end
    
    return Toggle
end

-- ==========================================
-- MODULE: Slider
-- ==========================================
Modules["Slider"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Tween = loadModule("Tween")
    local Config = loadModule("Config")
    local Maid = loadModule("Maid")
    local Signal = loadModule("Signal")
    local Save = loadModule("Save")
    local Helpers = loadModule("Helpers")
    
    local UserInputService = game:GetService("UserInputService")
    
    local Slider = {}
    Slider.__index = Slider
    
    function Slider.new(config, section)
        local self = setmetatable({}, Slider)
        self._config = config
        self._section = section
        self._maid = Maid.new()
        self.Changed = Signal.new()
        
        self._min = config.Min or 0
        self._max = config.Max or 100
        self._increment = config.Increment or 1
        
        self._value = config.Default or self._min
        if config.Flag then
            self._value = Save:Get(config.Flag, self._value)
        end
        
        self:_build()
        self:_setupTheme()
        self:_setupDrag()
        self:Set(self._value, true)
        return self
    end
    
    function Slider:_build()
        self._frame = Create.new("Frame", {
            Name = self._config.Name or "Slider",
            Parent = self._section._content,
            Size = UDim2.new(1, 0, 0, 50),
            BackgroundColor3 = Theme:GetColor("SecondaryBackground"),
            BorderSizePixel = 0,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 6) })
        })
        
        self._nameLabel = Create.new("TextLabel", {
            Name = "Name",
            Parent = self._frame,
            Size = UDim2.new(1, -100, 0, 20),
            Position = UDim2.new(0, Config:Get("Padding"), 0, 8),
            BackgroundTransparency = 1,
            Text = self._config.Name or "Slider",
            TextColor3 = Theme:GetColor("Text"),
            Font = Config:Get("Font"),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        
        self._valueLabel = Create.new("TextLabel", {
            Name = "Value",
            Parent = self._frame,
            Size = UDim2.new(0, 80, 0, 20),
            Position = UDim2.new(1, -Config:Get("Padding") - 80, 0, 8),
            BackgroundTransparency = 1,
            Text = tostring(self._value) .. (self._config.Suffix or ""),
            TextColor3 = Theme:GetColor("SubText"),
            Font = Config:Get("Font"),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Right,
        })
        
        self._track = Create.new("TextButton", {
            Name = "Track",
            Parent = self._frame,
            Size = UDim2.new(1, -(Config:Get("Padding")*2), 0, 4),
            Position = UDim2.new(0, Config:Get("Padding"), 0, 36),
            BackgroundColor3 = Theme:GetColor("Hover"),
            AutoButtonColor = false,
            Text = "",
            BorderSizePixel = 0,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 2) })
        })
        
        self._fill = Create.new("Frame", {
            Name = "Fill",
            Parent = self._track,
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = Theme:GetColor("Accent"),
            BorderSizePixel = 0,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 2) })
        })
        
        self._handle = Create.new("Frame", {
            Name = "Handle",
            Parent = self._fill,
            Size = UDim2.new(0, 12, 0, 12),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 6) })
        })
    end
    
    function Slider:_setupTheme()
        self._maid:GiveTask(Theme.Changed:Connect(function()
            self._frame.BackgroundColor3 = Theme:GetColor("SecondaryBackground")
            self._nameLabel.TextColor3 = Theme:GetColor("Text")
            self._valueLabel.TextColor3 = Theme:GetColor("SubText")
            self._track.BackgroundColor3 = Theme:GetColor("Hover")
            self._fill.BackgroundColor3 = Theme:GetColor("Accent")
        end))
    end
    
    function Slider:_setupDrag()
        local dragging = false
        
        local function update(input)
            local pos = input.Position
            local fraction = math.clamp((pos.X - self._track.AbsolutePosition.X) / self._track.AbsoluteSize.X, 0, 1)
            local rawValue = self._min + (self._max - self._min) * fraction
            
            local snapped = math.floor(rawValue / self._increment + 0.5) * self._increment
            snapped = math.clamp(snapped, self._min, self._max)
            
            self:Set(snapped)
        end
        
        self._maid:GiveTask(self._track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                update(input)
            end
        end))
        
        self._maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))
        
        self._maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                update(input)
            end
        end))
    end
    
    function Slider:Set(value, ignoreCallback)
        local clamped = math.clamp(value, self._min, self._max)
        self._value = clamped
        
        local fraction = (clamped - self._min) / (self._max - self._min)
        Tween:Run(self._fill, Tween:GetInfo(0.1), {Size = UDim2.new(fraction, 0, 1, 0)})
        
        local displayValue = tostring(Helpers.round(clamped, 2))
        self._valueLabel.Text = displayValue .. (self._config.Suffix or "")
        
        if self._config.Flag then
            Save:Set(self._config.Flag, clamped)
        end
        
        self.Changed:Fire(clamped)
        
        if not ignoreCallback and self._config.Callback then
            task.spawn(self._config.Callback, clamped)
        end
    end
    
    function Slider:Get()
        return self._value
    end
    
    function Slider:Destroy()
        self._maid:DoCleaning()
        if self._frame then self._frame:Destroy() end
    end
    
    return Slider
end

-- ==========================================
-- MODULE: Dropdown
-- ==========================================
Modules["Dropdown"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Tween = loadModule("Tween")
    local Config = loadModule("Config")
    local Maid = loadModule("Maid")
    local Signal = loadModule("Signal")
    local Save = loadModule("Save")
    local Icons = loadModule("Icons")
    
    local Dropdown = {}
    Dropdown.__index = Dropdown
    
    function Dropdown.new(config, section)
        local self = setmetatable({}, Dropdown)
        self._config = config
        self._section = section
        self._maid = Maid.new()
        self.Changed = Signal.new()
        self._open = false
        
        self._options = config.Options or {}
        self._multi = config.MultiSelect or false
        
        self._value = config.Default
        if self._multi and type(self._value) ~= "table" then
            self._value = self._value and {self._value} or {}
        end
        
        if config.Flag then
            self._value = Save:Get(config.Flag, self._value)
        end
        
        self:_build()
        self:_setupTheme()
        self:Set(self._value, true)
        return self
    end
    
    function Dropdown:_build()
        self._frame = Create.new("Frame", {
            Name = self._config.Name or "Dropdown",
            Parent = self._section._content,
            Size = UDim2.new(1, 0, 0, Config:Get("ComponentHeight")),
            BackgroundColor3 = Theme:GetColor("SecondaryBackground"),
            BorderSizePixel = 0,
            ZIndex = 1,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 6) })
        })
        
        self._button = Create.new("TextButton", {
            Name = "Button",
            Parent = self._frame,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 2,
        })
        
        self._nameLabel = Create.new("TextLabel", {
            Name = "Name",
            Parent = self._frame,
            Size = UDim2.new(0.5, -Config:Get("Padding")),
            Position = UDim2.new(0, Config:Get("Padding"), 0, 0),
            BackgroundTransparency = 1,
            Text = self._config.Name or "Dropdown",
            TextColor3 = Theme:GetColor("Text"),
            Font = Config:Get("Font"),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2,
        })
        
        self._selectedLabel = Create.new("TextLabel", {
            Name = "Selected",
            Parent = self._frame,
            Size = UDim2.new(0.5, -Config:Get("Padding") - 20, 1, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "Select...",
            TextColor3 = Theme:GetColor("SubText"),
            Font = Config:Get("Font"),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 2,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
        
        self._icon = Create.new("ImageLabel", {
            Name = "Icon",
            Parent = self._frame,
            Size = UDim2.new(0, 12, 0, 12),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -Config:Get("Padding"), 0.5, 0),
            BackgroundTransparency = 1,
            Image = Icons.ChevronDown,
            ImageColor3 = Theme:GetColor("SubText"),
            ZIndex = 2,
        })
        
        self._dropdownList = Create.new("Frame", {
            Name = "List",
            Parent = self._frame,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 1, 2),
            BackgroundColor3 = Theme:GetColor("SecondaryBackground"),
            BorderSizePixel = 0,
            Visible = false,
            ClipsDescendants = true,
            ZIndex = 10,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 6) }),
            Create.new("UIStroke", { Color = Theme:GetColor("Border"), Thickness = 1 }),
            Create.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
            Create.new("UIPadding", {
                PaddingTop = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4),
            })
        })
        
        self._maid:GiveTask(self._button.MouseButton1Click:Connect(function()
            self:_toggleOpen()
        end))
        
        self:_refreshOptions()
    end
    
    function Dropdown:_refreshOptions()
        for _, child in ipairs(self._dropdownList:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        
        local totalHeight = 8
        for i, option in ipairs(self._options) do
            local btn = Create.new("TextButton", {
                Name = "Option_" .. option,
                Parent = self._dropdownList,
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = Theme:GetColor("SecondaryBackground"),
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                Text = "",
                ZIndex = 11,
            }, {
                Create.new("UICorner", { CornerRadius = UDim.new(0, 4) })
            })
            
            local label = Create.new("TextLabel", {
                Name = "Label",
                Parent = btn,
                Size = UDim2.new(1, -24, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                Text = tostring(option),
                TextColor3 = Theme:GetColor("Text"),
                Font = Config:Get("Font"),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 11,
            })
            
            local check = Create.new("ImageLabel", {
                Name = "Check",
                Parent = btn,
                Size = UDim2.new(0, 14, 0, 14),
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -8, 0.5, 0),
                BackgroundTransparency = 1,
                Image = Icons.Check,
                ImageColor3 = Theme:GetColor("Accent"),
                Visible = false,
                ZIndex = 11,
            })
            
            btn.MouseEnter:Connect(function()
                Tween:Run(btn, Tween:GetInfo(0.2), {BackgroundTransparency = 0, BackgroundColor3 = Theme:GetColor("Hover")})
            end)
            btn.MouseLeave:Connect(function()
                Tween:Run(btn, Tween:GetInfo(0.2), {BackgroundTransparency = 1})
            end)
            btn.MouseButton1Click:Connect(function()
                if self._multi then
                    local current = self._value or {}
                    local idx = table.find(current, option)
                    if idx then
                        table.remove(current, idx)
                    else
                        table.insert(current, option)
                    end
                    self:Set(current)
                else
                    self:Set(option)
                    self:_toggleOpen(false)
                end
            end)
            
            totalHeight = totalHeight + 30
        end
        
        self._listHeight = totalHeight
        if self._open then
            self._dropdownList.Size = UDim2.new(1, 0, 0, self._listHeight)
        end
        self:_updateChecks()
    end
    
    function Dropdown:_updateChecks()
        for _, child in ipairs(self._dropdownList:GetChildren()) do
            if child:IsA("TextButton") then
                local opt = child.Label.Text
                local isSelected = false
                if self._multi then
                    isSelected = table.find(self._value or {}, opt) ~= nil
                else
                    isSelected = (self._value == opt)
                end
                
                child.Check.Visible = isSelected
                child.Label.TextColor3 = isSelected and Theme:GetColor("Accent") or Theme:GetColor("Text")
            end
        end
    end
    
    function Dropdown:_toggleOpen(forceState)
        self._open = forceState ~= nil and forceState or not self._open
        
        if self._open then
            self._dropdownList.Visible = true
            Tween:Run(self._icon, Tween:GetInfo(0.2), {Rotation = 180})
            Tween:Run(self._dropdownList, Tween:GetInfo(0.2), {Size = UDim2.new(1, 0, 0, self._listHeight)})
        else
            Tween:Run(self._icon, Tween:GetInfo(0.2), {Rotation = 0})
            local t = Tween:Run(self._dropdownList, Tween:GetInfo(0.2), {Size = UDim2.new(1, 0, 0, 0)})
            task.spawn(function()
                t.Completed:Wait()
                if not self._open then self._dropdownList.Visible = false end
            end)
        end
    end
    
    function Dropdown:_setupTheme()
        self._maid:GiveTask(Theme.Changed:Connect(function()
            self._frame.BackgroundColor3 = Theme:GetColor("SecondaryBackground")
            self._nameLabel.TextColor3 = Theme:GetColor("Text")
            self._selectedLabel.TextColor3 = Theme:GetColor("SubText")
            self._icon.ImageColor3 = Theme:GetColor("SubText")
            self._dropdownList.BackgroundColor3 = Theme:GetColor("SecondaryBackground")
            self._dropdownList.UIStroke.Color = Theme:GetColor("Border")
            self:_updateChecks()
        end))
    end
    
    function Dropdown:SetOptions(options)
        self._options = options
        self:_refreshOptions()
    end
    
    function Dropdown:Set(value, ignoreCallback)
        self._value = value
        
        if self._multi then
            local text = #value > 0 and table.concat(value, ", ") or "Select..."
            self._selectedLabel.Text = text
        else
            self._selectedLabel.Text = value and tostring(value) or "Select..."
        end
        
        self:_updateChecks()
        
        if self._config.Flag then
            Save:Set(self._config.Flag, value)
        end
        
        self.Changed:Fire(value)
        
        if not ignoreCallback and self._config.Callback then
            task.spawn(self._config.Callback, value)
        end
    end
    
    function Dropdown:Get()
        return self._value
    end
    
    function Dropdown:Destroy()
        self._maid:DoCleaning()
        if self._frame then self._frame:Destroy() end
    end
    
    return Dropdown
end

-- ==========================================
-- MODULE: Textbox
-- ==========================================
Modules["Textbox"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Tween = loadModule("Tween")
    local Config = loadModule("Config")
    local Maid = loadModule("Maid")
    local Signal = loadModule("Signal")
    local Save = loadModule("Save")
    
    local Textbox = {}
    Textbox.__index = Textbox
    
    function Textbox.new(config, section)
        local self = setmetatable({}, Textbox)
        self._config = config
        self._section = section
        self._maid = Maid.new()
        self.Changed = Signal.new()
        
        self._value = config.Default or ""
        if config.Flag then
            self._value = Save:Get(config.Flag, self._value)
        end
        
        self:_build()
        self:_setupTheme()
        self:Set(self._value, true)
        return self
    end
    
    function Textbox:_build()
        self._frame = Create.new("Frame", {
            Name = self._config.Name or "Textbox",
            Parent = self._section._content,
            Size = UDim2.new(1, 0, 0, Config:Get("ComponentHeight")),
            BackgroundColor3 = Theme:GetColor("SecondaryBackground"),
            BorderSizePixel = 0,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 6) })
        })
        
        self._nameLabel = Create.new("TextLabel", {
            Name = "Name",
            Parent = self._frame,
            Size = UDim2.new(1, -200, 1, 0),
            Position = UDim2.new(0, Config:Get("Padding"), 0, 0),
            BackgroundTransparency = 1,
            Text = self._config.Name or "Textbox",
            TextColor3 = Theme:GetColor("Text"),
            Font = Config:Get("Font"),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        
        self._inputFrame = Create.new("Frame", {
            Name = "InputFrame",
            Parent = self._frame,
            Size = UDim2.new(0, 180, 0, 26),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -Config:Get("Padding"), 0.5, 0),
            BackgroundColor3 = Theme:GetColor("Input"),
            BorderSizePixel = 0,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 4) }),
            Create.new("UIStroke", { Name = "Stroke", Color = Theme:GetColor("Border"), Thickness = 1 })
        })
        
        self._textBox = Create.new("TextBox", {
            Name = "Input",
            Parent = self._inputFrame,
            Size = UDim2.new(1, -12, 1, 0),
            Position = UDim2.new(0, 6, 0, 0),
            BackgroundTransparency = 1,
            Text = self._value,
            PlaceholderText = self._config.Placeholder or "",
            PlaceholderColor3 = Theme:GetColor("SubText"),
            TextColor3 = Theme:GetColor("Text"),
            Font = Config:Get("Font"),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = self._config.ClearOnFocus or false,
        })
        
        self._maid:GiveTask(self._textBox.Focused:Connect(function()
            Tween:Run(self._inputFrame.Stroke, Tween:GetInfo(0.2), {Color = Theme:GetColor("Accent")})
        end))
        
        self._maid:GiveTask(self._textBox.FocusLost:Connect(function(enterPressed)
            Tween:Run(self._inputFrame.Stroke, Tween:GetInfo(0.2), {Color = Theme:GetColor("Border")})
            if enterPressed then
                self:Set(self._textBox.Text)
            end
        end))
    end
    
    function Textbox:_setupTheme()
        self._maid:GiveTask(Theme.Changed:Connect(function()
            self._frame.BackgroundColor3 = Theme:GetColor("SecondaryBackground")
            self._nameLabel.TextColor3 = Theme:GetColor("Text")
            self._inputFrame.BackgroundColor3 = Theme:GetColor("Input")
            self._inputFrame.Stroke.Color = Theme:GetColor("Border")
            self._textBox.PlaceholderColor3 = Theme:GetColor("SubText")
            self._textBox.TextColor3 = Theme:GetColor("Text")
        end))
    end
    
    function Textbox:Set(value, ignoreCallback)
        self._value = value
        self._textBox.Text = value
        
        if self._config.Flag then
            Save:Set(self._config.Flag, value)
        end
        
        self.Changed:Fire(value)
        
        if not ignoreCallback and self._config.Callback then
            task.spawn(self._config.Callback, value)
        end
    end
    
    function Textbox:Get()
        return self._value
    end
    
    function Textbox:Destroy()
        self._maid:DoCleaning()
        if self._frame then self._frame:Destroy() end
    end
    
    return Textbox
end

-- ==========================================
-- MODULE: Label
-- ==========================================
Modules["Label"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Config = loadModule("Config")
    local Maid = loadModule("Maid")
    
    local Label = {}
    Label.__index = Label
    
    function Label.new(config, section)
        local self = setmetatable({}, Label)
        self._config = config
        self._section = section
        self._maid = Maid.new()
        
        self:_build()
        self:_setupTheme()
        return self
    end
    
    function Label:_build()
        self._frame = Create.new("Frame", {
            Name = self._config.Name or "Label",
            Parent = self._section._content,
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
        })
        
        local textOffset = 8
        if self._config.Icon then
            self._iconImage = Create.new("ImageLabel", {
                Name = "Icon",
                Parent = self._frame,
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(0, 8, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                Image = self._config.Icon,
                ImageColor3 = Theme:GetColor("Text"),
            })
            textOffset = 28
        end
        
        self._textLabel = Create.new("TextLabel", {
            Name = "Text",
            Parent = self._frame,
            Size = UDim2.new(1, -textOffset - 8, 1, 0),
            Position = UDim2.new(0, textOffset, 0, 0),
            BackgroundTransparency = 1,
            Text = self._config.Name or "Label",
            TextColor3 = Theme:GetColor("Text"),
            Font = Config:Get("Font"),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
    end
    
    function Label:_setupTheme()
        self._maid:GiveTask(Theme.Changed:Connect(function()
            self._textLabel.TextColor3 = Theme:GetColor("Text")
            if self._iconImage then self._iconImage.ImageColor3 = Theme:GetColor("Text") end
        end))
    end
    
    function Label:Set(text)
        self._textLabel.Text = text
    end
    
    function Label:Destroy()
        self._maid:DoCleaning()
        if self._frame then self._frame:Destroy() end
    end
    
    return Label
end

-- ==========================================
-- MODULE: Paragraph
-- ==========================================
Modules["Paragraph"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Config = loadModule("Config")
    local Maid = loadModule("Maid")
    
    local Paragraph = {}
    Paragraph.__index = Paragraph
    
    function Paragraph.new(config, section)
        local self = setmetatable({}, Paragraph)
        self._config = config
        self._section = section
        self._maid = Maid.new()
        
        self:_build()
        self:_setupTheme()
        return self
    end
    
    function Paragraph:_build()
        self._frame = Create.new("Frame", {
            Name = self._config.Name or "Paragraph",
            Parent = self._section._content,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Theme:GetColor("SecondaryBackground"),
            BorderSizePixel = 0,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 6) }),
            Create.new("UIPadding", {
                PaddingTop = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
            }),
            Create.new("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4)
            })
        })
        
        if self._config.Name then
            self._titleLabel = Create.new("TextLabel", {
                Name = "Title",
                Parent = self._frame,
                Size = UDim2.new(1, 0, 0, 16),
                BackgroundTransparency = 1,
                Text = self._config.Name,
                TextColor3 = Theme:GetColor("Text"),
                Font = Config:Get("FontBold"),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
        end
        
        self._contentLabel = Create.new("TextLabel", {
            Name = "Content",
            Parent = self._frame,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text = self._config.Content or "",
            TextColor3 = Theme:GetColor("SubText"),
            Font = Config:Get("Font"),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
        })
    end
    
    function Paragraph:_setupTheme()
        self._maid:GiveTask(Theme.Changed:Connect(function()
            self._frame.BackgroundColor3 = Theme:GetColor("SecondaryBackground")
            if self._titleLabel then self._titleLabel.TextColor3 = Theme:GetColor("Text") end
            self._contentLabel.TextColor3 = Theme:GetColor("SubText")
        end))
    end
    
    function Paragraph:SetTitle(text)
        if self._titleLabel then self._titleLabel.Text = text end
    end
    
    function Paragraph:SetContent(text)
        self._contentLabel.Text = text
    end
    
    function Paragraph:Destroy()
        self._maid:DoCleaning()
        if self._frame then self._frame:Destroy() end
    end
    
    return Paragraph
end

-- ==========================================
-- MODULE: Keybind
-- ==========================================
Modules["Keybind"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Tween = loadModule("Tween")
    local Config = loadModule("Config")
    local Maid = loadModule("Maid")
    local Signal = loadModule("Signal")
    local Save = loadModule("Save")
    
    local UserInputService = game:GetService("UserInputService")
    
    local Keybind = {}
    Keybind.__index = Keybind
    
    function Keybind.new(config, section)
        local self = setmetatable({}, Keybind)
        self._config = config
        self._section = section
        self._maid = Maid.new()
        self.Changed = Signal.new()
        
        self._value = config.Default
        if config.Flag then
            local saved = Save:Get(config.Flag, self._value and self._value.Name)
            if saved and typeof(saved) == "string" then
                self._value = Enum.KeyCode[saved]
            end
        end
        
        self._binding = false
        
        self:_build()
        self:_setupTheme()
        self:_setupInput()
        self:Set(self._value, true)
        return self
    end
    
    function Keybind:_build()
        self._frame = Create.new("Frame", {
            Name = self._config.Name or "Keybind",
            Parent = self._section._content,
            Size = UDim2.new(1, 0, 0, Config:Get("ComponentHeight")),
            BackgroundColor3 = Theme:GetColor("SecondaryBackground"),
            BorderSizePixel = 0,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 6) })
        })
        
        self._nameLabel = Create.new("TextLabel", {
            Name = "Name",
            Parent = self._frame,
            Size = UDim2.new(1, -120, 1, 0),
            Position = UDim2.new(0, Config:Get("Padding"), 0, 0),
            BackgroundTransparency = 1,
            Text = self._config.Name or "Keybind",
            TextColor3 = Theme:GetColor("Text"),
            Font = Config:Get("Font"),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        
        self._button = Create.new("TextButton", {
            Name = "BindButton",
            Parent = self._frame,
            Size = UDim2.new(0, 100, 0, 24),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -Config:Get("Padding"), 0.5, 0),
            BackgroundColor3 = Theme:GetColor("Input"),
            Text = "",
            BorderSizePixel = 0,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 4) })
        })
        
        self._valueLabel = Create.new("TextLabel", {
            Name = "Value",
            Parent = self._button,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "None",
            TextColor3 = Theme:GetColor("Text"),
            Font = Config:Get("Font"),
            TextSize = 13,
        })
        
        self._maid:GiveTask(self._button.MouseButton1Click:Connect(function()
            self._binding = true
            self._valueLabel.Text = "..."
            Tween:Run(self._button, Tween:GetInfo(0.2), {BackgroundColor3 = Theme:GetColor("Accent")})
        end))
    end
    
    function Keybind:_setupTheme()
        self._maid:GiveTask(Theme.Changed:Connect(function()
            self._frame.BackgroundColor3 = Theme:GetColor("SecondaryBackground")
            self._nameLabel.TextColor3 = Theme:GetColor("Text")
            self._button.BackgroundColor3 = self._binding and Theme:GetColor("Accent") or Theme:GetColor("Input")
            self._valueLabel.TextColor3 = Theme:GetColor("Text")
        end))
    end
    
    function Keybind:_setupInput()
        self._maid:GiveTask(UserInputService.InputBegan:Connect(function(input, processed)
            if self._binding then
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    self._binding = false
                    local key = input.KeyCode
                    if key == Enum.KeyCode.Escape then
                        self:Set(nil)
                    else
                        self:Set(key)
                    end
                end
            elseif not processed and self._value and input.KeyCode == self._value then
                if self._config.OnPressed then
                    task.spawn(self._config.OnPressed)
                end
            end
        end))
    end
    
    function Keybind:Set(keyCode, ignoreCallback)
        self._value = keyCode
        
        if keyCode then
            self._valueLabel.Text = keyCode.Name
        else
            self._valueLabel.Text = "None"
        end
        
        Tween:Run(self._button, Tween:GetInfo(0.2), {BackgroundColor3 = Theme:GetColor("Input")})
        
        if self._config.Flag then
            Save:Set(self._config.Flag, keyCode and keyCode.Name or nil)
        end
        
        self.Changed:Fire(keyCode)
        
        if not ignoreCallback and self._config.Callback then
            task.spawn(self._config.Callback, keyCode)
        end
    end
    
    function Keybind:Get()
        return self._value
    end
    
    function Keybind:Destroy()
        self._maid:DoCleaning()
        if self._frame then self._frame:Destroy() end
    end
    
    return Keybind
end

-- ==========================================
-- MODULE: ColorPicker
-- ==========================================
Modules["ColorPicker"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Tween = loadModule("Tween")
    local Config = loadModule("Config")
    local Maid = loadModule("Maid")
    local Signal = loadModule("Signal")
    local Save = loadModule("Save")
    local Helpers = loadModule("Helpers")
    
    local UserInputService = game:GetService("UserInputService")
    
    local ColorPicker = {}
    ColorPicker.__index = ColorPicker
    
    function ColorPicker.new(config, section)
        local self = setmetatable({}, ColorPicker)
        self._config = config
        self._section = section
        self._maid = Maid.new()
        self.Changed = Signal.new()
        self._open = false
        
        self._value = config.Default or Color3.new(1, 1, 1)
        if config.Flag then
            local saved = Save:Get(config.Flag, self._value:ToHex())
            if saved and type(saved) == "string" then
                self._value = Color3.fromHex(saved)
            end
        end
        
        self._h, self._s, self._v = self._value:ToHSV()
        
        self:_build()
        self:_setupTheme()
        self:Set(self._value, true)
        return self
    end
    
    function ColorPicker:_build()
        self._frame = Create.new("Frame", {
            Name = self._config.Name or "ColorPicker",
            Parent = self._section._content,
            Size = UDim2.new(1, 0, 0, Config:Get("ComponentHeight")),
            BackgroundColor3 = Theme:GetColor("SecondaryBackground"),
            BorderSizePixel = 0,
            ZIndex = 1,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 6) })
        })
        
        self._nameLabel = Create.new("TextLabel", {
            Name = "Name",
            Parent = self._frame,
            Size = UDim2.new(1, -60, 1, 0),
            Position = UDim2.new(0, Config:Get("Padding"), 0, 0),
            BackgroundTransparency = 1,
            Text = self._config.Name or "ColorPicker",
            TextColor3 = Theme:GetColor("Text"),
            Font = Config:Get("Font"),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2,
        })
        
        self._previewButton = Create.new("TextButton", {
            Name = "Preview",
            Parent = self._frame,
            Size = UDim2.new(0, 24, 0, 24),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -Config:Get("Padding"), 0.5, 0),
            BackgroundColor3 = self._value,
            Text = "",
            BorderSizePixel = 0,
            ZIndex = 2,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 4) }),
            Create.new("UIStroke", { Color = Theme:GetColor("Border"), Thickness = 1 })
        })
        
        self._pickerFrame = Create.new("Frame", {
            Name = "Picker",
            Parent = self._frame,
            Size = UDim2.new(0, 200, 0, 220),
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -Config:Get("Padding") - 30, 1, 2),
            BackgroundColor3 = Theme:GetColor("SecondaryBackground"),
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 10,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 8) }),
            Create.new("UIStroke", { Color = Theme:GetColor("Border"), Thickness = 1 })
        })
        
        self._svBox = Create.new("TextButton", {
            Name = "SVBox",
            Parent = self._pickerFrame,
            Size = UDim2.new(1, -16, 0, 150),
            Position = UDim2.new(0, 8, 0, 8),
            BackgroundColor3 = Color3.fromHSV(self._h, 1, 1),
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
            ZIndex = 11,
        }, {
            Create.new("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
                },
                Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1)
                }
            })
        })
        
        self._svOverlay = Create.new("Frame", {
            Name = "Overlay",
            Parent = self._svBox,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 12,
        }, {
            Create.new("UIGradient", {
                Color = ColorSequence.new(Color3.new(0, 0, 0)),
                Rotation = 90,
                Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0)
                }
            })
        })
        
        self._svCursor = Create.new("Frame", {
            Name = "Cursor",
            Parent = self._svBox,
            Size = UDim2.new(0, 8, 0, 8),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(self._s, 0, 1 - self._v, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            ZIndex = 13,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(1, 0) }),
            Create.new("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1 })
        })
        
        self._hueSlider = Create.new("TextButton", {
            Name = "HueSlider",
            Parent = self._pickerFrame,
            Size = UDim2.new(1, -16, 0, 14),
            Position = UDim2.new(0, 8, 0, 166),
            BackgroundColor3 = Color3.new(1, 1, 1),
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
            ZIndex = 11,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 7) }),
            Create.new("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
                    ColorSequenceKeypoint.new(1/6, Color3.new(1, 1, 0)),
                    ColorSequenceKeypoint.new(2/6, Color3.new(0, 1, 0)),
                    ColorSequenceKeypoint.new(3/6, Color3.new(0, 1, 1)),
                    ColorSequenceKeypoint.new(4/6, Color3.new(0, 0, 1)),
                    ColorSequenceKeypoint.new(5/6, Color3.new(1, 0, 1)),
                    ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0))
                }
            })
        })
        
        self._hueCursor = Create.new("Frame", {
            Name = "Cursor",
            Parent = self._hueSlider,
            Size = UDim2.new(0, 14, 0, 14),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(self._h, 0, 0.5, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            ZIndex = 12,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(1, 0) }),
            Create.new("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1 })
        })
        
        self._hexInput = Create.new("TextBox", {
            Name = "HexInput",
            Parent = self._pickerFrame,
            Size = UDim2.new(1, -16, 0, 24),
            Position = UDim2.new(0, 8, 0, 188),
            BackgroundColor3 = Theme:GetColor("Input"),
            Text = "#" .. self._value:ToHex():upper(),
            TextColor3 = Theme:GetColor("Text"),
            Font = Config:Get("Font"),
            TextSize = 13,
            ZIndex = 11,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 4) }),
            Create.new("UIStroke", { Color = Theme:GetColor("Border"), Thickness = 1 })
        })
        
        self._maid:GiveTask(self._previewButton.MouseButton1Click:Connect(function()
            self._open = not self._open
            self._pickerFrame.Visible = self._open
        end))
        
        self:_setupDrag(self._svBox, function(x, y)
            self._s = math.clamp(x, 0, 1)
            self._v = 1 - math.clamp(y, 0, 1)
            self._svCursor.Position = UDim2.new(self._s, 0, 1 - self._v, 0)
            self:_updateColor()
        end)
        
        self:_setupDrag(self._hueSlider, function(x, y)
            self._h = 1 - math.clamp(x, 0, 1)
            self._hueCursor.Position = UDim2.new(x, 0, 0.5, 0)
            self._svBox.BackgroundColor3 = Color3.fromHSV(self._h, 1, 1)
            self:_updateColor()
        end)
        
        self._maid:GiveTask(self._hexInput.FocusLost:Connect(function()
            local text = self._hexInput.Text:gsub("#", "")
            local success, col = pcall(function() return Color3.fromHex(text) end)
            if success then
                self:Set(col)
            else
                self._hexInput.Text = "#" .. self._value:ToHex():upper()
            end
        end))
    end
    
    function ColorPicker:_setupDrag(gui, callback)
        local dragging = false
        self._maid:GiveTask(gui.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                local x = (input.Position.X - gui.AbsolutePosition.X) / gui.AbsoluteSize.X
                local y = (input.Position.Y - gui.AbsolutePosition.Y) / gui.AbsoluteSize.Y
                callback(x, y)
            end
        end))
        self._maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))
        self._maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local x = (input.Position.X - gui.AbsolutePosition.X) / gui.AbsoluteSize.X
                local y = (input.Position.Y - gui.AbsolutePosition.Y) / gui.AbsoluteSize.Y
                callback(x, y)
            end
        end))
    end
    
    function ColorPicker:_updateColor()
        local col = Color3.fromHSV(self._h, self._s, self._v)
        self:Set(col)
    end
    
    function ColorPicker:_setupTheme()
        self._maid:GiveTask(Theme.Changed:Connect(function()
            self._frame.BackgroundColor3 = Theme:GetColor("SecondaryBackground")
            self._nameLabel.TextColor3 = Theme:GetColor("Text")
            self._pickerFrame.BackgroundColor3 = Theme:GetColor("SecondaryBackground")
            self._pickerFrame.UIStroke.Color = Theme:GetColor("Border")
            self._hexInput.BackgroundColor3 = Theme:GetColor("Input")
            self._hexInput.TextColor3 = Theme:GetColor("Text")
            self._hexInput.UIStroke.Color = Theme:GetColor("Border")
        end))
    end
    
    function ColorPicker:Set(color, ignoreCallback)
        self._value = color
        self._h, self._s, self._v = color:ToHSV()
        
        self._previewButton.BackgroundColor3 = color
        self._hexInput.Text = "#" .. color:ToHex():upper()
        
        self._svBox.BackgroundColor3 = Color3.fromHSV(self._h, 1, 1)
        self._svCursor.Position = UDim2.new(self._s, 0, 1 - self._v, 0)
        self._hueCursor.Position = UDim2.new(1 - self._h, 0, 0.5, 0)
        
        if self._config.Flag then
            Save:Set(self._config.Flag, color:ToHex())
        end
        
        self.Changed:Fire(color)
        
        if not ignoreCallback and self._config.Callback then
            task.spawn(self._config.Callback, color)
        end
    end
    
    function ColorPicker:Get()
        return self._value
    end
    
    function ColorPicker:Destroy()
        self._maid:DoCleaning()
        if self._frame then self._frame:Destroy() end
    end
    
    return ColorPicker
end

-- ==========================================
-- MODULE: Separator
-- ==========================================
Modules["Separator"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Config = loadModule("Config")
    local Maid = loadModule("Maid")
    
    local Separator = {}
    Separator.__index = Separator
    
    function Separator.new(config, section)
        local self = setmetatable({}, Separator)
        self._config = config or {}
        self._section = section
        self._maid = Maid.new()
        
        self:_build()
        self:_setupTheme()
        return self
    end
    
    function Separator:_build()
        self._frame = Create.new("Frame", {
            Name = "Separator",
            Parent = self._section._content,
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
        })
        
        if self._config.Text then
            self._leftLine = Create.new("Frame", {
                Name = "LeftLine",
                Parent = self._frame,
                Size = UDim2.new(0.5, -30, 0, 1),
                Position = UDim2.new(0, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Theme:GetColor("Divider"),
                BorderSizePixel = 0,
            })
            self._textLabel = Create.new("TextLabel", {
                Name = "Text",
                Parent = self._frame,
                Size = UDim2.new(0, 60, 1, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Text = self._config.Text,
                TextColor3 = Theme:GetColor("SubText"),
                Font = Config:Get("Font"),
                TextSize = 12,
            })
            self._rightLine = Create.new("Frame", {
                Name = "RightLine",
                Parent = self._frame,
                Size = UDim2.new(0.5, -30, 0, 1),
                Position = UDim2.new(1, 0, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = Theme:GetColor("Divider"),
                BorderSizePixel = 0,
            })
        else
            self._line = Create.new("Frame", {
                Name = "Line",
                Parent = self._frame,
                Size = UDim2.new(1, 0, 0, 1),
                Position = UDim2.new(0, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Theme:GetColor("Divider"),
                BorderSizePixel = 0,
            })
        end
    end
    
    function Separator:_setupTheme()
        self._maid:GiveTask(Theme.Changed:Connect(function()
            if self._line then self._line.BackgroundColor3 = Theme:GetColor("Divider") end
            if self._leftLine then self._leftLine.BackgroundColor3 = Theme:GetColor("Divider") end
            if self._rightLine then self._rightLine.BackgroundColor3 = Theme:GetColor("Divider") end
            if self._textLabel then self._textLabel.TextColor3 = Theme:GetColor("SubText") end
        end))
    end
    
    function Separator:Destroy()
        self._maid:DoCleaning()
        if self._frame then self._frame:Destroy() end
    end
    
    return Separator
end

-- ==========================================
-- MODULE: Notification
-- ==========================================
Modules["Notification"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Tween = loadModule("Tween")
    local Config = loadModule("Config")
    local Icons = loadModule("Icons")
    
    local CoreGui = game:GetService("CoreGui")
    
    local container = nil
    
    local Notification = {}
    Notification.__index = Notification
    
    function Notification.new(config)
        local self = setmetatable({}, Notification)
        self._config = config
        
        if not container or not container.Parent then
            local screenGui = Create.new("ScreenGui", {
                Name = "UI_Notifications",
                ResetOnSpawn = false,
                ZIndexBehavior = Enum.ZIndexBehavior.Global,
            })
            pcall(function() screenGui.Parent = CoreGui end)
            if not screenGui.Parent then
                local Players = game:GetService("Players")
                if Players.LocalPlayer then screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
            end
            
            container = Create.new("Frame", {
                Name = "Container",
                Parent = screenGui,
                Size = UDim2.new(0, 300, 1, -40),
                Position = UDim2.new(1, -320, 0, 20),
                BackgroundTransparency = 1,
            }, {
                Create.new("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalAlignment = Enum.VerticalAlignment.Bottom,
                    Padding = UDim.new(0, 10)
                })
            })
        end
        
        self:_build()
        return self
    end
    
    function Notification:_build()
        local nType = self._config.Type or "Info"
        local color = Theme:GetColor("Accent")
        local icon = Icons.Info
        if nType == "Success" then color = Theme:GetColor("Success"); icon = Icons.Success
        elseif nType == "Warning" then color = Theme:GetColor("Warning"); icon = Icons.Warning
        elseif nType == "Error" then color = Theme:GetColor("Error"); icon = Icons.Error
        end
        
        if self._config.Icon then icon = self._config.Icon end
        
        self._frame = Create.new("Frame", {
            Name = "Notification",
            Parent = container,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(1, 320, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Theme:GetColor("SecondaryBackground"),
            BorderSizePixel = 0,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 8) }),
            Create.new("UIStroke", { Color = Theme:GetColor("Border"), Thickness = 1 }),
            Create.new("UIPadding", {
                PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
            })
        })
        
        self._icon = Create.new("ImageLabel", {
            Name = "Icon",
            Parent = self._frame,
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Image = icon,
            ImageColor3 = color,
        })
        
        self._title = Create.new("TextLabel", {
            Name = "Title",
            Parent = self._frame,
            Size = UDim2.new(1, -44, 0, 20),
            Position = UDim2.new(0, 28, 0, 0),
            BackgroundTransparency = 1,
            Text = self._config.Title or "Notification",
            TextColor3 = Theme:GetColor("Text"),
            Font = Config:Get("FontBold"),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        
        self._close = Create.new("ImageButton", {
            Name = "Close",
            Parent = self._frame,
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(1, -16, 0, 2),
            BackgroundTransparency = 1,
            Image = Icons.Close,
            ImageColor3 = Theme:GetColor("SubText"),
        })
        
        self._message = Create.new("TextLabel", {
            Name = "Message",
            Parent = self._frame,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 0, 28),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text = self._config.Message or "",
            TextColor3 = Theme:GetColor("SubText"),
            Font = Config:Get("Font"),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
        })
        
        self._progress = Create.new("Frame", {
            Name = "Progress",
            Parent = self._frame,
            Size = UDim2.new(1, 20, 0, 2),
            Position = UDim2.new(0, -10, 1, 10),
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
        })
        
        local duration = self._config.Duration or Config:Get("NotificationDuration")
        
        -- Animation In
        Tween:Run(self._frame, Tween:GetInfo(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)})
        Tween:Run(self._progress, Tween:GetInfo(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)})
        
        local closed = false
        local function close()
            if closed then return end
            closed = true
            local t = Tween:Run(self._frame, Tween:GetInfo(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(1, 320, 0, 0)})
            t.Completed:Connect(function()
                self._frame:Destroy()
            end)
        end
        
        self._close.MouseButton1Click:Connect(close)
        task.delay(duration, close)
        
        local max = Config:Get("NotificationMax")
        local children = container:GetChildren()
        local notifs = {}
        for _, c in ipairs(children) do
            if c:IsA("Frame") then table.insert(notifs, c) end
        end
        if #notifs > max then
            notifs[1]:Destroy()
        end
    end
    
    return Notification
end

-- ==========================================
-- MODULE: Dialog
-- ==========================================
Modules["Dialog"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Tween = loadModule("Tween")
    local Config = loadModule("Config")
    
    local Dialog = {}
    Dialog.__index = Dialog
    
    function Dialog.new(config, screenGui)
        local self = setmetatable({}, Dialog)
        self._config = config
        
        self._overlay = Create.new("Frame", {
            Name = "DialogOverlay",
            Parent = screenGui,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Active = true,
        })
        
        self._dialog = Create.new("Frame", {
            Name = "Dialog",
            Parent = self._overlay,
            Size = UDim2.new(0, 320, 0, 180),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundColor3 = Theme:GetColor("SecondaryBackground"),
            BorderSizePixel = 0,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 8) }),
            Create.new("UIStroke", { Color = Theme:GetColor("Border"), Thickness = 1 }),
            Create.new("UIScale", { Name = "Scale", Scale = 0.9 })
        })
        
        self._title = Create.new("TextLabel", {
            Name = "Title",
            Parent = self._dialog,
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundTransparency = 1,
            Text = config.Title or "Dialog",
            TextColor3 = Theme:GetColor("Text"),
            Font = Config:Get("FontBold"),
            TextSize = 16,
        })
        
        self._message = Create.new("TextLabel", {
            Name = "Message",
            Parent = self._dialog,
            Size = UDim2.new(1, -40, 1, -90),
            Position = UDim2.new(0, 20, 0, 40),
            BackgroundTransparency = 1,
            Text = config.Message or "",
            TextColor3 = Theme:GetColor("SubText"),
            Font = Config:Get("Font"),
            TextSize = 13,
            TextWrapped = true,
        })
        
        self._buttonRow = Create.new("Frame", {
            Name = "Buttons",
            Parent = self._dialog,
            Size = UDim2.new(1, -40, 0, 36),
            Position = UDim2.new(0, 20, 1, -50),
            BackgroundTransparency = 1,
        }, {
            Create.new("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 10)
            })
        })
        
        local buttons = config.Buttons or {
            { Name = "Cancel", Callback = function() end },
            { Name = "Confirm", Callback = function() end }
        }
        
        for i, btn in ipairs(buttons) do
            local isLast = i == #buttons
            local btnBg = isLast and Theme:GetColor("Accent") or Theme:GetColor("SubText")
            
            local b = Create.new("TextButton", {
                Name = btn.Name,
                Parent = self._buttonRow,
                Size = UDim2.new(0, 100, 1, 0),
                BackgroundColor3 = btnBg,
                Text = btn.Name,
                TextColor3 = Color3.new(1, 1, 1),
                Font = Config:Get("FontMedium") or Enum.Font.GothamMedium,
                TextSize = 14,
                AutoButtonColor = false,
            }, {
                Create.new("UICorner", { CornerRadius = UDim.new(0, 6) })
            })
            
            b.MouseEnter:Connect(function() Tween:Run(b, Tween:GetInfo(0.2), {BackgroundTransparency = 0.2}) end)
            b.MouseLeave:Connect(function() Tween:Run(b, Tween:GetInfo(0.2), {BackgroundTransparency = 0}) end)
            b.MouseButton1Click:Connect(function()
                if btn.Callback then btn.Callback() end
                self:_close()
            end)
        end
        
        Tween:Run(self._overlay, Tween:GetInfo(0.2), {BackgroundTransparency = 0.5})
        Tween:Run(self._dialog.Scale, Tween:GetInfo(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
        
        return self
    end
    
    function Dialog:_close()
        Tween:Run(self._overlay, Tween:GetInfo(0.2), {BackgroundTransparency = 1})
        local t = Tween:Run(self._dialog.Scale, Tween:GetInfo(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0.9})
        t.Completed:Connect(function()
            self._overlay:Destroy()
        end)
    end
    
    return Dialog
end
-- ==========================================
-- ProgressBar Component
-- ==========================================
Modules["ProgressBar"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Config = loadModule("Config")
    local Tween = loadModule("Tween")
    local Signal = loadModule("Signal")
    local Maid = loadModule("Maid")
    local Helpers = loadModule("Helpers")

    local ProgressBar = {}
    ProgressBar.__index = ProgressBar

    function ProgressBar.new(config, section)
        local self = setmetatable({}, ProgressBar)
        self._maid = Maid.new()
        self._config = config or {}
        self._section = section
        self._value = self._config.Default or 0
        self._suffix = self._config.Suffix or "%"
        self.Changed = self._maid:GiveTask(Signal.new())

        local name = self._config.Name or "ProgressBar"

        self._frame = Create.new("Frame", {
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = Theme:GetColor("SecondaryBackground"),
            BackgroundTransparency = 0,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 6) }),
            Create.new("UIPadding", {
                PaddingTop = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8)
            }),
            Create.new("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6)
            })
        })

        local topRow = Create.new("Frame", {
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            LayoutOrder = 1,
            Parent = self._frame
        }, {
            Create.new("TextLabel", {
                Name = "NameLabel",
                Size = UDim2.new(1, -50, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = name,
                TextColor3 = Theme:GetColor("Text"),
                Font = Config:Get("Font"),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            }),
            Create.new("TextLabel", {
                Name = "ValueLabel",
                Size = UDim2.new(0, 50, 1, 0),
                Position = UDim2.new(1, -50, 0, 0),
                BackgroundTransparency = 1,
                Text = tostring(math.floor(self._value)) .. self._suffix,
                TextColor3 = Theme:GetColor("SubText"),
                Font = Config:Get("Font"),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right,
            })
        })

        self._valueLabel = topRow.ValueLabel
        self._nameLabel = topRow.NameLabel

        local trackFrame = Create.new("Frame", {
            Size = UDim2.new(1, 0, 0, 6),
            BackgroundColor3 = Theme:GetColor("Input"),
            LayoutOrder = 2,
            Parent = self._frame
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 3) })
        })

        local fraction = Helpers.clamp(self._value / 100, 0, 1)
        self._fillFrame = Create.new("Frame", {
            Size = UDim2.new(fraction, 0, 1, 0),
            BackgroundColor3 = Theme:GetColor("Accent"),
            Parent = trackFrame
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 3) })
        })

        self._maid:GiveTask(Theme.Changed:Connect(function()
            self._frame.BackgroundColor3 = Theme:GetColor("SecondaryBackground")
            self._nameLabel.TextColor3 = Theme:GetColor("Text")
            self._valueLabel.TextColor3 = Theme:GetColor("SubText")
            trackFrame.BackgroundColor3 = Theme:GetColor("Input")
            self._fillFrame.BackgroundColor3 = Theme:GetColor("Accent")
        end))

        if section then
            self._frame.Parent = section._content
            section._maid:GiveTask(self)
        end

        return self
    end

    function ProgressBar:Set(value)
        self._value = Helpers.clamp(value, 0, 100)
        self._valueLabel.Text = tostring(math.floor(self._value)) .. self._suffix
        local fraction = self._value / 100
        Tween:Run(self._fillFrame, Tween:GetInfo(Config:Get("AnimationSpeed"), Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Size = UDim2.new(fraction, 0, 1, 0) })
        self.Changed:Fire(self._value)
    end

    function ProgressBar:Get()
        return self._value
    end

    function ProgressBar:Destroy()
        self._maid:DoCleaning()
        if self._frame then self._frame:Destroy() end
    end

    return ProgressBar
end

-- ==========================================
-- Image Component
-- ==========================================
Modules["Image"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Config = loadModule("Config")
    local Signal = loadModule("Signal")
    local Maid = loadModule("Maid")

    local Image = {}
    Image.__index = Image

    function Image.new(config, section)
        local self = setmetatable({}, Image)
        self._maid = Maid.new()
        self._config = config or {}
        self._section = section
        self.Changed = self._maid:GiveTask(Signal.new())

        local imageId = self._config.Image or ""
        local size = self._config.Size or UDim2.new(1, 0, 0, 100)
        local name = self._config.Name

        local frameProps = {
            Size = size,
            BackgroundTransparency = 1,
        }
        if not self._config.Size then
            frameProps.AutomaticSize = Enum.AutomaticSize.Y
        end

        self._frame = Create.new("Frame", frameProps, {
            Create.new("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
                HorizontalAlignment = Enum.HorizontalAlignment.Center
            })
        })

        self._imageLabel = Create.new("ImageLabel", {
            Size = size,
            BackgroundTransparency = 1,
            Image = imageId,
            ScaleType = Enum.ScaleType.Fit,
            LayoutOrder = 1,
            Parent = self._frame
        })

        if name then
            self._nameLabel = Create.new("TextLabel", {
                Size = UDim2.new(1, 0, 0, 14),
                BackgroundTransparency = 1,
                Text = name,
                TextColor3 = Theme:GetColor("SubText"),
                Font = Config:Get("Font"),
                TextSize = 12,
                LayoutOrder = 2,
                Parent = self._frame
            })
            
            self._maid:GiveTask(Theme.Changed:Connect(function()
                if self._nameLabel then
                    self._nameLabel.TextColor3 = Theme:GetColor("SubText")
                end
            end))
        end

        if section then
            self._frame.Parent = section._content
            section._maid:GiveTask(self)
        end

        return self
    end

    function Image:SetImage(assetId)
        self._imageLabel.Image = assetId
        self.Changed:Fire(assetId)
    end

    function Image:Destroy()
        self._maid:DoCleaning()
        if self._frame then self._frame:Destroy() end
    end

    return Image
end

-- ==========================================
-- Container Component
-- ==========================================
Modules["Container"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Config = loadModule("Config")
    local Tween = loadModule("Tween")
    local Maid = loadModule("Maid")
    local Icons = loadModule("Icons")

    local Container = {}
    Container.__index = Container

    function Container.new(config, section)
        local self = setmetatable({}, Container)
        self._maid = Maid.new()
        self._config = config or {}
        self._section = section
        self._components = {}
        self._open = true
        self._collapsible = self._config.Collapsible == true

        local name = self._config.Name

        self._frame = Create.new("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Theme:GetColor("SecondaryBackground"),
            ClipsDescendants = true
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 6) }),
            Create.new("UIStroke", {
                Color = Theme:GetColor("Border"),
                Thickness = 1
            }),
            Create.new("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder
            })
        })

        if name then
            local headerSize = UDim2.new(1, 0, 0, 36)
            local headerBtn = Create.new("TextButton", {
                Size = headerSize,
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = 1,
                Parent = self._frame
            }, {
                Create.new("UIPadding", {
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8)
                }),
                Create.new("TextLabel", {
                    Name = "Title",
                    Size = UDim2.new(1, -20, 1, 0),
                    BackgroundTransparency = 1,
                    Text = name,
                    TextColor3 = Theme:GetColor("Text"),
                    Font = Config:Get("Font"),
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
            })
            
            self._header = headerBtn
            self._titleLabel = headerBtn.Title

            if self._collapsible then
                self._chevron = Create.new("ImageLabel", {
                    Size = UDim2.new(0, 12, 0, 12),
                    Position = UDim2.new(1, -12, 0.5, -6),
                    BackgroundTransparency = 1,
                    Image = Icons.ChevronDown,
                    ImageColor3 = Theme:GetColor("SubText"),
                    Parent = headerBtn
                })

                self._maid:GiveTask(headerBtn.MouseButton1Click:Connect(function()
                    self:Toggle()
                end))
            end
        end

        self._content = Create.new("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = 2,
            Parent = self._frame
        }, {
            Create.new("UIPadding", {
                PaddingTop = name and UDim.new(0, 0) or UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8)
            }),
            Create.new("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4)
            })
        })
        
        self._maid:GiveTask(Theme.Changed:Connect(function()
            self._frame.BackgroundColor3 = Theme:GetColor("SecondaryBackground")
            local stroke = self._frame:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = Theme:GetColor("Border") end
            if self._titleLabel then self._titleLabel.TextColor3 = Theme:GetColor("Text") end
            if self._chevron then self._chevron.ImageColor3 = Theme:GetColor("SubText") end
        end))

        if section then
            self._frame.Parent = section._content
            section._maid:GiveTask(self)
        end

        return self
    end

    function Container:Toggle()
        if not self._collapsible then return end
        self:SetOpen(not self._open)
    end

    function Container:SetOpen(open)
        if not self._collapsible then return end
        self._open = open
        self._content.Visible = open
        if self._chevron then
            Tween:Run(self._chevron, Tween:GetInfo(0.2), { Rotation = open and 0 or -90 })
        end
    end

    function Container:Destroy()
        self._maid:DoCleaning()
        if self._frame then self._frame:Destroy() end
    end
    
    -- Component Creation Methods matching Section
    function Container:CreateButton(config)
        local btn = loadModule("Button").new(config, self)
        table.insert(self._components, btn)
        if self._section and self._section._tab and self._section._tab._window then
            self._section._tab._window:_registerSearchable(config.Name, btn._frame)
        end
        return btn
    end

    return Container
end

-- ==========================================
-- Badge Component
-- ==========================================
Modules["Badge"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Config = loadModule("Config")
    local Maid = loadModule("Maid")

    local Badge = {}
    Badge.__index = Badge

    function Badge.new(config, section)
        local self = setmetatable({}, Badge)
        self._maid = Maid.new()
        self._config = config or {}
        self._section = section

        local text = self._config.Name or ""
        self._bgColor = self._config.Color or Theme:GetColor("Accent")
        self._textColor = self._config.TextColor or Color3.new(1, 1, 1)

        self._frame = Create.new("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundColor3 = self._bgColor,
            Text = text,
            TextColor3 = self._textColor,
            Font = Config:Get("FontBold"),
            TextSize = 11,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 4) }),
            Create.new("UIPadding", {
                PaddingTop = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8)
            })
        })

        self._maid:GiveTask(Theme.Changed:Connect(function()
            if not self._config.Color then
                self._bgColor = Theme:GetColor("Accent")
                self._frame.BackgroundColor3 = self._bgColor
            end
        end))

        if section then
            self._frame.Parent = section._content
            section._maid:GiveTask(self)
        end

        return self
    end

    function Badge:Set(text)
        self._frame.Text = tostring(text)
    end

    function Badge:SetColor(color)
        self._bgColor = color
        self._frame.BackgroundColor3 = color
    end

    function Badge:Destroy()
        self._maid:DoCleaning()
        if self._frame then self._frame:Destroy() end
    end

    return Badge
end

-- ==========================================
-- Chip Component
-- ==========================================
Modules["Chip"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Config = loadModule("Config")
    local Maid = loadModule("Maid")
    local Icons = loadModule("Icons")

    local Chip = {}
    Chip.__index = Chip

    function Chip.new(config, section)
        local self = setmetatable({}, Chip)
        self._maid = Maid.new()
        self._config = config or {}
        self._section = section

        local name = self._config.Name or "Chip"
        local removable = self._config.Removable == true
        local onRemove = self._config.OnRemove
        local bgColor = self._config.Color or Theme:GetColor("SecondaryBackground")

        self._frame = Create.new("Frame", {
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 0, 28),
            BackgroundColor3 = bgColor,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 14) }),
            Create.new("UIStroke", {
                Color = Theme:GetColor("Border"),
                Thickness = 1
            }),
            Create.new("UIPadding", {
                PaddingTop = UDim.new(0, 0),
                PaddingBottom = UDim.new(0, 0),
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, removable and 4 or 8)
            }),
            Create.new("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 4),
                VerticalAlignment = Enum.VerticalAlignment.Center
            })
        })

        self._label = Create.new("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Theme:GetColor("Text"),
            Font = Config:Get("Font"),
            TextSize = 12,
            LayoutOrder = 1,
            Parent = self._frame
        })

        if removable then
            local removeBtn = Create.new("ImageButton", {
                Size = UDim2.new(0, 14, 0, 14),
                BackgroundTransparency = 1,
                Image = Icons.Close,
                ImageColor3 = Theme:GetColor("SubText"),
                LayoutOrder = 2,
                Parent = self._frame
            })
            
            self._maid:GiveTask(removeBtn.MouseButton1Click:Connect(function()
                if onRemove then onRemove() end
                self:Destroy()
            end))
            self._removeBtn = removeBtn
        end

        self._maid:GiveTask(Theme.Changed:Connect(function()
            if not self._config.Color then
                self._frame.BackgroundColor3 = Theme:GetColor("SecondaryBackground")
            end
            local stroke = self._frame:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = Theme:GetColor("Border") end
            self._label.TextColor3 = Theme:GetColor("Text")
            if self._removeBtn then self._removeBtn.ImageColor3 = Theme:GetColor("SubText") end
        end))

        if section then
            self._frame.Parent = section._content
            section._maid:GiveTask(self)
        end

        return self
    end

    function Chip:Destroy()
        self._maid:DoCleaning()
        if self._frame then self._frame:Destroy() end
    end

    return Chip
end

-- ==========================================
-- Tooltip Component
-- ==========================================
Modules["Tooltip"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Config = loadModule("Config")
    local Tween = loadModule("Tween")
    local Maid = loadModule("Maid")
    local UserInputService = game:GetService("UserInputService")

    local Tooltip = {}
    Tooltip.__index = Tooltip

    function Tooltip.new(config)
        local self = setmetatable({}, Tooltip)
        self._maid = Maid.new()
        self._config = config or {}
        
        local target = self._config.Target
        local text = self._config.Text or ""
        
        if not target then return self end

        self._frame = Create.new("Frame", {
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundColor3 = Theme:GetColor("SecondaryBackground"),
            Visible = false,
            ZIndex = 100,
            BackgroundTransparency = 1,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 6) }),
            Create.new("UIStroke", {
                Color = Theme:GetColor("Border"),
                Thickness = 1,
                Transparency = 1
            }),
            Create.new("UIPadding", {
                PaddingTop = UDim.new(0, 6),
                PaddingBottom = UDim.new(0, 6),
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8)
            }),
            Create.new("TextLabel", {
                Name = "Label",
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = Theme:GetColor("Text"),
                Font = Config:Get("Font"),
                TextSize = 12,
                TextTransparency = 1,
                ZIndex = 101
            })
        })

        local function findScreenGui(inst)
            while inst do
                if inst:IsA("ScreenGui") then return inst end
                inst = inst.Parent
            end
            return nil
        end
        
        local screenGui = findScreenGui(target)
        if screenGui then
            self._frame.Parent = screenGui
        end

        self._maid:GiveTask(Theme.Changed:Connect(function()
            self._frame.BackgroundColor3 = Theme:GetColor("SecondaryBackground")
            local stroke = self._frame:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = Theme:GetColor("Border") end
            self._frame.Label.TextColor3 = Theme:GetColor("Text")
        end))

        local stroke = self._frame:FindFirstChildOfClass("UIStroke")
        local hoverTask = nil

        self._maid:GiveTask(target.MouseEnter:Connect(function()
            if hoverTask then task.cancel(hoverTask) end
            hoverTask = task.delay(0.2, function()
                local mousePos = UserInputService:GetMouseLocation()
                self._frame.Position = UDim2.new(0, mousePos.X + 10, 0, mousePos.Y + 10)
                self._frame.Visible = true
                Tween:Run(self._frame, Tween:GetInfo(0.15), { BackgroundTransparency = 0 })
                Tween:Run(self._frame.Label, Tween:GetInfo(0.15), { TextTransparency = 0 })
                if stroke then
                    Tween:Run(stroke, Tween:GetInfo(0.15), { Transparency = 0 })
                end
            end)
        end))
        
        self._maid:GiveTask(target.MouseMoved:Connect(function()
            if self._frame.Visible then
                local mousePos = UserInputService:GetMouseLocation()
                -- Keep on screen logic could go here
                self._frame.Position = UDim2.new(0, mousePos.X + 10, 0, mousePos.Y + 10)
            end
        end))

        self._maid:GiveTask(target.MouseLeave:Connect(function()
            if hoverTask then task.cancel(hoverTask) hoverTask = nil end
            Tween:Run(self._frame, Tween:GetInfo(0.15), { BackgroundTransparency = 1 })
            Tween:Run(self._frame.Label, Tween:GetInfo(0.15), { TextTransparency = 1 })
            if stroke then
                Tween:Run(stroke, Tween:GetInfo(0.15), { Transparency = 1 })
            end
            task.delay(0.15, function()
                if self._frame and self._frame.BackgroundTransparency == 1 then
                    self._frame.Visible = false
                end
            end)
        end))

        return self
    end

    function Tooltip:Destroy()
        self._maid:DoCleaning()
        if self._frame then self._frame:Destroy() end
    end

    return Tooltip
end

-- ==========================================
-- ContextMenu Component
-- ==========================================
Modules["ContextMenu"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Config = loadModule("Config")
    local Tween = loadModule("Tween")
    local Maid = loadModule("Maid")
    local UserInputService = game:GetService("UserInputService")

    local ContextMenu = {}
    ContextMenu.__index = ContextMenu

    function ContextMenu.new(config)
        local self = setmetatable({}, ContextMenu)
        self._maid = Maid.new()
        self._config = config or {}
        
        local target = self._config.Target
        local options = self._config.Options or {}
        
        if not target then return self end

        self._frame = Create.new("Frame", {
            Size = UDim2.new(0, 180, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Theme:GetColor("SecondaryBackground"),
            Visible = false,
            ZIndex = 100,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 6) }),
            Create.new("UIStroke", {
                Color = Theme:GetColor("Border"),
                Thickness = 1
            }),
            Create.new("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
            Create.new("UIPadding", {
                PaddingTop = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4)
            })
        })

        for i, opt in ipairs(options) do
            local optBtn = Create.new("TextButton", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
                BackgroundColor3 = Theme:GetColor("Hover"),
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = i,
                ZIndex = 101,
                Parent = self._frame
            }, {
                Create.new("UICorner", { CornerRadius = UDim.new(0, 4) }),
                Create.new("UIPadding", {
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8)
                }),
                Create.new("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDim.new(0, 8),
                    VerticalAlignment = Enum.VerticalAlignment.Center
                })
            })
            
            if opt.Icon then
                Create.new("ImageLabel", {
                    Size = UDim2.new(0, 14, 0, 14),
                    BackgroundTransparency = 1,
                    Image = opt.Icon,
                    ImageColor3 = Theme:GetColor("SubText"),
                    LayoutOrder = 1,
                    ZIndex = 102,
                    Parent = optBtn
                })
            end
            
            Create.new("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = opt.Name or "Option",
                TextColor3 = Theme:GetColor("Text"),
                Font = Config:Get("Font"),
                TextSize = 13,
                LayoutOrder = 2,
                ZIndex = 102,
                Parent = optBtn
            })
            
            self._maid:GiveTask(optBtn.MouseEnter:Connect(function()
                Tween:Run(optBtn, Tween:GetInfo(0.15), { BackgroundTransparency = 0 })
            end))
            self._maid:GiveTask(optBtn.MouseLeave:Connect(function()
                Tween:Run(optBtn, Tween:GetInfo(0.15), { BackgroundTransparency = 1 })
            end))
            self._maid:GiveTask(optBtn.MouseButton1Click:Connect(function()
                self:Close()
                if opt.Callback then opt.Callback() end
            end))
        end

        local function findScreenGui(inst)
            while inst do
                if inst:IsA("ScreenGui") then return inst end
                inst = inst.Parent
            end
            return nil
        end
        
        local screenGui = findScreenGui(target)
        if screenGui then
            self._frame.Parent = screenGui
        end
        
        local closeConn
        closeConn = self._maid:GiveTask(UserInputService.InputBegan:Connect(function(input)
            if self._frame.Visible then
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    -- check if clicking outside
                    local pos = input.Position
                    local ax, ay = self._frame.AbsolutePosition.X, self._frame.AbsolutePosition.Y
                    local asx, asy = self._frame.AbsoluteSize.X, self._frame.AbsoluteSize.Y
                    if pos.X < ax or pos.X > ax + asx or pos.Y < ay or pos.Y > ay + asy then
                        self:Close()
                    end
                end
            end
        end))

        self._maid:GiveTask(target.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                local mousePos = UserInputService:GetMouseLocation()
                self._frame.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
                self:Open()
            end
        end))
        
        -- Mobile long press can be implemented similarly with TouchLongPress if needed

        self._maid:GiveTask(Theme.Changed:Connect(function()
            self._frame.BackgroundColor3 = Theme:GetColor("SecondaryBackground")
            local stroke = self._frame:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = Theme:GetColor("Border") end
            for _, child in ipairs(self._frame:GetChildren()) do
                if child:IsA("TextButton") then
                    child.BackgroundColor3 = Theme:GetColor("Hover")
                    for _, v in ipairs(child:GetChildren()) do
                        if v:IsA("TextLabel") then v.TextColor3 = Theme:GetColor("Text") end
                        if v:IsA("ImageLabel") then v.ImageColor3 = Theme:GetColor("SubText") end
                    end
                end
            end
        end))

        return self
    end
    
    function ContextMenu:Open()
        self._frame.Visible = true
    end
    
    function ContextMenu:Close()
        self._frame.Visible = false
    end

    function ContextMenu:Destroy()
        self._maid:DoCleaning()
        if self._frame then self._frame:Destroy() end
    end

    return ContextMenu
end

-- ==========================================
-- LoadingSpinner Component
-- ==========================================
Modules["LoadingSpinner"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Tween = loadModule("Tween")
    local Maid = loadModule("Maid")
    local TweenService = game:GetService("TweenService")

    local LoadingSpinner = {}
    LoadingSpinner.__index = LoadingSpinner

    function LoadingSpinner.new(config, section)
        local self = setmetatable({}, LoadingSpinner)
        self._maid = Maid.new()
        self._config = config or {}
        self._section = section

        local size = self._config.Size or 24
        local color = self._config.Color or Theme:GetColor("Accent")

        self._frame = Create.new("Frame", {
            Size = UDim2.new(0, size, 0, size),
            BackgroundTransparency = 1,
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(1, 0) }),
            Create.new("UIStroke", {
                Name = "Stroke",
                Thickness = math.max(2, size / 8),
                Color = color,
                Transparency = 0
            })
        })

        local gradient = Create.new("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0), 
                NumberSequenceKeypoint.new(0.75, 0), 
                NumberSequenceKeypoint.new(0.76, 1), 
                NumberSequenceKeypoint.new(1, 1)
            }),
            Rotation = 0,
            Parent = self._frame:FindFirstChild("Stroke")
        })

        self._spinTween = TweenService:Create(
            self._frame, 
            TweenInfo.new(0.8, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), 
            { Rotation = 360 }
        )
        self._spinTween:Play()

        self._maid:GiveTask(Theme.Changed:Connect(function()
            if not self._config.Color then
                local s = self._frame:FindFirstChild("Stroke")
                if s then s.Color = Theme:GetColor("Accent") end
            end
        end))

        if section then
            self._frame.Parent = section._content
            section._maid:GiveTask(self)
        end

        return self
    end

    function LoadingSpinner:Start()
        self._frame.Visible = true
        if self._spinTween then self._spinTween:Play() end
    end

    function LoadingSpinner:Stop()
        self._frame.Visible = false
        if self._spinTween then self._spinTween:Pause() end
    end

    function LoadingSpinner:Destroy()
        self._maid:DoCleaning()
        if self._spinTween then self._spinTween:Cancel() end
        if self._frame then self._frame:Destroy() end
    end

    return LoadingSpinner
end

-- ==========================================
-- StatusIndicator Component
-- ==========================================
Modules["StatusIndicator"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Config = loadModule("Config")
    local Maid = loadModule("Maid")

    local StatusIndicator = {}
    StatusIndicator.__index = StatusIndicator

    function StatusIndicator.new(config, section)
        local self = setmetatable({}, StatusIndicator)
        self._maid = Maid.new()
        self._config = config or {}
        self._section = section
        
        local name = self._config.Name or "Status"
        self._status = self._config.Status or "Online"
        
        local function getColorForStatus(stat)
            if self._config.Color then return self._config.Color end
            if stat == "Online" then return Theme:GetColor("Success") end
            if stat == "Offline" then return Theme:GetColor("SubText") end
            if stat == "Busy" then return Theme:GetColor("Error") end
            if stat == "Away" then return Theme:GetColor("Warning") end
            return Theme:GetColor("SubText")
        end

        self._frame = Create.new("Frame", {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
        }, {
            Create.new("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 8),
                VerticalAlignment = Enum.VerticalAlignment.Center
            })
        })

        self._dot = Create.new("Frame", {
            Size = UDim2.new(0, 10, 0, 10),
            BackgroundColor3 = getColorForStatus(self._status),
            LayoutOrder = 1,
            Parent = self._frame
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 5) })
        })

        self._label = Create.new("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Theme:GetColor("Text"),
            Font = Config:Get("Font"),
            TextSize = 13,
            LayoutOrder = 2,
            Parent = self._frame
        })

        self._maid:GiveTask(Theme.Changed:Connect(function()
            self._dot.BackgroundColor3 = getColorForStatus(self._status)
            self._label.TextColor3 = Theme:GetColor("Text")
        end))

        if section then
            self._frame.Parent = section._content
            section._maid:GiveTask(self)
        end

        return self
    end

    function StatusIndicator:SetStatus(status)
        self._status = status
        self._dot.BackgroundColor3 = Theme:GetColor("Success") -- fallback
        if not self._config.Color then
            if status == "Online" then self._dot.BackgroundColor3 = Theme:GetColor("Success")
            elseif status == "Offline" then self._dot.BackgroundColor3 = Theme:GetColor("SubText")
            elseif status == "Busy" then self._dot.BackgroundColor3 = Theme:GetColor("Error")
            elseif status == "Away" then self._dot.BackgroundColor3 = Theme:GetColor("Warning")
            else self._dot.BackgroundColor3 = Theme:GetColor("SubText") end
        end
    end

    function StatusIndicator:SetColor(color)
        self._config.Color = color
        self._dot.BackgroundColor3 = color
    end

    function StatusIndicator:Destroy()
        self._maid:DoCleaning()
        if self._frame then self._frame:Destroy() end
    end

    return StatusIndicator
end

-- ==========================================
-- Breadcrumb Component
-- ==========================================
Modules["Breadcrumb"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Config = loadModule("Config")
    local Maid = loadModule("Maid")

    local Breadcrumb = {}
    Breadcrumb.__index = Breadcrumb

    function Breadcrumb.new(config, section)
        local self = setmetatable({}, Breadcrumb)
        self._maid = Maid.new()
        self._config = config or {}
        self._section = section

        self._separator = self._config.Separator or ">"
        self._callback = self._config.Callback
        
        self._frame = Create.new("Frame", {
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
        }, {
            Create.new("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 4),
                VerticalAlignment = Enum.VerticalAlignment.Center
            })
        })
        
        self._itemMaid = self._maid:GiveTask(Maid.new())

        if section then
            self._frame.Parent = section._content
            section._maid:GiveTask(self)
        end
        
        self:SetItems(self._config.Items or {})

        self._maid:GiveTask(Theme.Changed:Connect(function()
            self:SetItems(self._items or {})
        end))

        return self
    end

    function Breadcrumb:SetItems(items)
        self._items = items
        self._itemMaid:DoCleaning()
        
        for i, item in ipairs(items) do
            local isLast = i == #items
            
            if isLast then
                Create.new("TextLabel", {
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = item,
                    TextColor3 = Theme:GetColor("Text"),
                    Font = Config:Get("FontBold"),
                    TextSize = 13,
                    LayoutOrder = i * 2 - 1,
                    Parent = self._frame
                })
            else
                local btn = Create.new("TextButton", {
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = item,
                    TextColor3 = self._callback and Theme:GetColor("Accent") or Theme:GetColor("SubText"),
                    Font = Config:Get("Font"),
                    TextSize = 13,
                    LayoutOrder = i * 2 - 1,
                    Parent = self._frame
                })
                
                if self._callback then
                    self._itemMaid:GiveTask(btn.MouseButton1Click:Connect(function()
                        self._callback(i, item)
                    end))
                end
                
                Create.new("TextLabel", {
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = self._separator,
                    TextColor3 = Theme:GetColor("SubText"),
                    Font = Config:Get("Font"),
                    TextSize = 13,
                    LayoutOrder = i * 2,
                    Parent = self._frame
                })
            end
        end
    end

    function Breadcrumb:Destroy()
        self._maid:DoCleaning()
        if self._frame then self._frame:Destroy() end
    end

    return Breadcrumb
end

-- ==========================================
-- Accordion Component
-- ==========================================
Modules["Accordion"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Config = loadModule("Config")
    local Tween = loadModule("Tween")
    local Maid = loadModule("Maid")
    local Icons = loadModule("Icons")

    local Accordion = {}
    Accordion.__index = Accordion

    function Accordion.new(config, section)
        local self = setmetatable({}, Accordion)
        self._maid = Maid.new()
        self._config = config or {}
        self._section = section
        self._components = {}
        self._open = self._config.DefaultOpen == true

        local name = self._config.Name or "Accordion"
        local contentText = self._config.Content

        self._frame = Create.new("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Theme:GetColor("SecondaryBackground"),
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 6) }),
            Create.new("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder
            })
        })

        self._headerBtn = Create.new("TextButton", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = 1,
            Parent = self._frame
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 6) }),
            Create.new("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8)
            }),
            Create.new("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -20, 1, 0),
                BackgroundTransparency = 1,
                Text = name,
                TextColor3 = Theme:GetColor("Text"),
                Font = Config:Get("Font"),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            }),
            Create.new("ImageLabel", {
                Name = "Chevron",
                Size = UDim2.new(0, 12, 0, 12),
                Position = UDim2.new(1, -12, 0.5, -6),
                BackgroundTransparency = 1,
                Image = self._open and Icons.ChevronUp or Icons.ChevronDown,
                ImageColor3 = Theme:GetColor("SubText"),
            })
        })
        
        self._titleLabel = self._headerBtn.Title
        self._chevron = self._headerBtn.Chevron

        self._content = Create.new("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Visible = self._open,
            LayoutOrder = 2,
            Parent = self._frame
        }, {
            Create.new("UIPadding", {
                PaddingTop = UDim.new(0, 0),
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8)
            }),
            Create.new("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4)
            })
        })
        
        if contentText then
            self._contentLabel = Create.new("TextLabel", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Text = contentText,
                TextColor3 = Theme:GetColor("SubText"),
                Font = Config:Get("Font"),
                TextSize = 13,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = self._content
            })
        end

        self._maid:GiveTask(self._headerBtn.MouseButton1Click:Connect(function()
            self:Toggle()
        end))

        self._maid:GiveTask(Theme.Changed:Connect(function()
            self._frame.BackgroundColor3 = Theme:GetColor("SecondaryBackground")
            self._titleLabel.TextColor3 = Theme:GetColor("Text")
            self._chevron.ImageColor3 = Theme:GetColor("SubText")
            if self._contentLabel then
                self._contentLabel.TextColor3 = Theme:GetColor("SubText")
            end
        end))

        if section then
            self._frame.Parent = section._content
            section._maid:GiveTask(self)
        end

        return self
    end

    function Accordion:Toggle()
        self:SetOpen(not self._open)
    end

    function Accordion:SetOpen(open)
        self._open = open
        self._chevron.Image = open and Icons.ChevronUp or Icons.ChevronDown
        self._content.Visible = open
    end
    
    function Accordion:IsOpen()
        return self._open
    end

    function Accordion:Destroy()
        self._maid:DoCleaning()
        if self._frame then self._frame:Destroy() end
    end
    
    -- Component Creation Methods matching Section
    function Accordion:CreateButton(config)
        local btn = loadModule("Button").new(config, self)
        table.insert(self._components, btn)
        if self._section and self._section._tab and self._section._tab._window then
            self._section._tab._window:_registerSearchable(config.Name, btn._frame)
        end
        return btn
    end

    return Accordion
end

-- ==========================================
-- SearchBox Component
-- ==========================================
Modules["SearchBox"] = function()
    local Create = loadModule("Create")
    local Theme = loadModule("Theme")
    local Config = loadModule("Config")
    local Tween = loadModule("Tween")
    local Maid = loadModule("Maid")
    local Icons = loadModule("Icons")

    local SearchBox = {}
    SearchBox.__index = SearchBox

    function SearchBox.new(config, section)
        local self = setmetatable({}, SearchBox)
        self._maid = Maid.new()
        self._config = config or {}
        self._section = section

        local name = self._config.Name
        local placeholder = self._config.Placeholder or "Search..."
        local callback = self._config.Callback

        self._frame = Create.new("Frame", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = Theme:GetColor("Input"),
        }, {
            Create.new("UICorner", { CornerRadius = UDim.new(0, 6) }),
            Create.new("UIStroke", {
                Name = "Stroke",
                Color = Theme:GetColor("Border"),
                Thickness = 1
            }),
            Create.new("UIPadding", {
                PaddingTop = UDim.new(0, 0),
                PaddingBottom = UDim.new(0, 0),
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8)
            }),
            Create.new("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 6),
                VerticalAlignment = Enum.VerticalAlignment.Center
            })
        })

        self._icon = Create.new("ImageLabel", {
            Size = UDim2.new(0, 14, 0, 14),
            BackgroundTransparency = 1,
            Image = Icons.Search or "rbxassetid://6031154871", -- Assuming a search icon fallback
            ImageColor3 = Theme:GetColor("SubText"),
            LayoutOrder = 1,
            Parent = self._frame
        })

        self._textBox = Create.new("TextBox", {
            Size = UDim2.new(1, -20, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = Theme:GetColor("Text"),
            PlaceholderText = placeholder,
            PlaceholderColor3 = Theme:GetColor("SubText"),
            Font = Config:Get("Font"),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 2,
            ClearTextOnFocus = false,
            Parent = self._frame
        })

        local stroke = self._frame:FindFirstChild("Stroke")

        self._maid:GiveTask(self._textBox.Focused:Connect(function()
            if stroke then
                Tween:Run(stroke, Tween:GetInfo(0.2), { Color = Theme:GetColor("Accent") })
            end
        end))

        self._maid:GiveTask(self._textBox.FocusLost:Connect(function()
            if stroke then
                Tween:Run(stroke, Tween:GetInfo(0.2), { Color = Theme:GetColor("Border") })
            end
        end))

        self._maid:GiveTask(self._textBox:GetPropertyChangedSignal("Text"):Connect(function()
            if callback then callback(self._textBox.Text) end
        end))

        self._maid:GiveTask(Theme.Changed:Connect(function()
            self._frame.BackgroundColor3 = Theme:GetColor("Input")
            if not self._textBox:IsFocused() and stroke then
                stroke.Color = Theme:GetColor("Border")
            end
            self._icon.ImageColor3 = Theme:GetColor("SubText")
            self._textBox.TextColor3 = Theme:GetColor("Text")
            self._textBox.PlaceholderColor3 = Theme:GetColor("SubText")
        end))

        if section then
            self._frame.Parent = section._content
            section._maid:GiveTask(self)
        end

        return self
    end

    function SearchBox:SetText(text)
        self._textBox.Text = text
    end

    function SearchBox:GetText()
        return self._textBox.Text
    end

    function SearchBox:Clear()
        self._textBox.Text = ""
    end

    function SearchBox:Destroy()
        self._maid:DoCleaning()
        if self._frame then self._frame:Destroy() end
    end

    return SearchBox
end

-- ==========================================
-- Main Module
-- ==========================================
Modules["Main"] = function()
    local Window = loadModule("Window")
    local Theme = loadModule("Theme")
    local Config = loadModule("Config")
    local Notification = loadModule("Notification")
    local Dialog = loadModule("Dialog")
    local Tooltip = loadModule("Tooltip")
    local ContextMenu = loadModule("ContextMenu")
    local Save = loadModule("Save")
    
    local Library = {}
    Library.__index = Library
    Library._version = "1.0.0"
    Library._windows = {}
    Library._initialized = false
    
    function Library:Init()
        if self._initialized then return end
        self._initialized = true
        Save:Load()
        -- Apply saved theme if exists
        local savedTheme = Save:Get("_theme")
        if savedTheme then
            pcall(function() Theme:SetTheme(savedTheme) end)
        end
    end
    
    function Library:CreateWindow(config)
        self:Init()
        -- Apply config overrides
        if config.Title then Config:Set("Title", config.Title) end
        if config.Icon then Config:Set("Logo", config.Icon) end
        if config.Theme then
            pcall(function() Theme:SetTheme(config.Theme) end)
        end
        if config.Size then Config:Set("WindowSize", config.Size) end
        if config.Font then Config:Set("Font", config.Font) end
        if config.AccentColor then
            Theme:SetColor("Accent", config.AccentColor)
        end
        if config.BorderRadius then Config:Set("BorderRadius", config.BorderRadius) end
        if config.AnimationSpeed then Config:Set("AnimationSpeed", config.AnimationSpeed) end
        if config.Padding then Config:Set("Padding", config.Padding) end
        if config.Scale then Config:Set("Scale", config.Scale) end
        if config.SaveEnabled ~= nil then Config:Set("SaveEnabled", config.SaveEnabled) end
        if config.SearchEnabled ~= nil then Config:Set("SearchEnabled", config.SearchEnabled) end
        if config.KeybindToggle then Config:Set("KeybindToggle", config.KeybindToggle) end
        
        local window = Window.new(config)
        table.insert(self._windows, window)
        return window
    end
    
    function Library:SetTheme(name)
        Theme:SetTheme(name)
        if Config:Get("SaveEnabled") then
            Save:Set("_theme", name)
        end
    end
    
    function Library:GetTheme()
        return Theme:GetThemeName()
    end
    
    function Library:CreateTheme(name, colors)
        Theme:CreateTheme(name, colors)
    end
    
    function Library:Notify(config)
        local Notif = loadModule("Notification")
        return Notif:Send(config)
    end
    
    function Library:Dialog(config)
        local Dlg = loadModule("Dialog")
        return Dlg:Show(config)
    end
    
    function Library:CreateTooltip(config)
        return Tooltip.new(config)
    end
    
    function Library:CreateContextMenu(config)
        return ContextMenu.new(config)
    end
    
    function Library:Destroy()
        for _, window in ipairs(self._windows) do
            window:Destroy()
        end
        self._windows = {}
        self._initialized = false
    end
    
    function Library:GetVersion()
        return self._version
    end
    
    return Library
end

return loadModule("Main")
