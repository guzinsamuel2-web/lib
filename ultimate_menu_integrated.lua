--[[
    =====================================================================
    Ultimate Cheat Menu UI + Ilha Bela 2.0 Integration
    Professional Roblox UI com Farm/Uber/Erva Systems
    =====================================================================
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/guzinsamuel2-web/lib/refs/heads/main/README.md"))()

local Window = Library:CreateWindow({
    Title = "Ultimate Cheat Menu + Ilha Bela 2.0",
    Icon = "rbxassetid://13149791439",
    Theme = "Dark"
})

-- ============================================================================
-- SERVIÇOS E VARIÁVEIS GLOBAIS
-- ============================================================================

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = Workspace.CurrentCamera

-- Estados globais
local Toggles = {
    -- Farm
    AutoIfood = false,
    AutoFarmGari = false,
    AutoFarmGariTPTO = false,
    AutoUber = false,
    AutoErva = false,
    -- Anti
    Noclip = false,
    AntiAfk = true,
    AntiSit = true,
    -- Combat
    AimbotEnabled = false,
    ESPEnabled = false,
}

local Connections = {}
local Threads = {}

-- ============================================================================
-- FUNÇÕES AUXILIARES
-- ============================================================================

local function GetChar()
    return LocalPlayer.Character
end

local function GetHRP()
    local c = GetChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3
        })
    end)
end

local function TpTo(pos)
    local hrp = GetHRP()
    if not hrp then return false end
    local safe = Vector3.new(pos.X, math.max(pos.Y, 3), pos.Z)
    local dir = safe - hrp.Position
    if dir.Magnitude <= 6 then
        hrp.CFrame = CFrame.lookAt(safe, safe + dir.Unit)
        return true
    end
    local u = dir.Unit
    while true do
        if not (Toggles.AutoIfood or Toggles.AutoFarmGari or Toggles.AutoFarmGariTPTO or Toggles.AutoErva) then return false end
        local h = GetHRP()
        if not h then return false end
        local rem = (safe - h.Position).Magnitude
        if rem <= 7.2 then break end
        local nxt = h.Position + u * 6
        if nxt.Y < 3 then nxt = Vector3.new(nxt.X, 5, nxt.Z) end
        h.CFrame = CFrame.lookAt(nxt, nxt + u)
        local hum = GetChar() and GetChar():FindFirstChildOfClass("Humanoid")
        if hum then hum:MoveTo(nxt) end
        task.wait(0.035)
    end
    return true
end

local function FirePrompt(prompt)
    if not prompt then return false end
    pcall(function()
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 100
        prompt.RequiresLineOfSight = false
    end)
    local fire = fireproximityprompt or function(p)
        p:InputHoldBegin(Enum.UserInputType.MouseButton1)
        task.wait(0.08)
        p:InputHoldEnd(Enum.UserInputType.MouseButton1)
    end
    return pcall(fire, prompt)
end

local function ToggleNoclip(s)
    Toggles.Noclip = s
    if Connections.Noclip then
        Connections.Noclip:Disconnect()
        Connections.Noclip = nil
    end
    
    if s then
        Connections.Noclip = RunService.Stepped:Connect(function()
            if not Toggles.Noclip then return end
            local ch = GetChar()
            if not ch then return end
            for _, p in ipairs(ch:GetDescendants()) do
                if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end
            end
        end)
        Notify("NoClip", "Ativado! ✓")
    else
        local ch = GetChar()
        if ch then
            for _, p in ipairs(ch:GetDescendants()) do
                if p:IsA("BasePart") then pcall(function() p.CanCollide = true end) end
            end
        end
        Notify("NoClip", "Desativado! ✗")
    end
end

local function ToggleAntiSit(s)
    Toggles.AntiSit = s
    if Connections.AntiSit then
        Connections.AntiSit:Disconnect()
        Connections.AntiSit = nil
    end
    
    if s then
        Connections.AntiSit = RunService.Heartbeat:Connect(function()
            if not Toggles.AntiSit then return end
            local ch = GetChar()
            if not ch then return end
            local h = ch:FindFirstChildOfClass("Humanoid")
            if h then
                if h.Sit then h.Sit = false end
                if h:GetState() == Enum.HumanoidStateType.Seated then
                    h:ChangeState(Enum.HumanoidStateType.Running)
                end
            end
        end)
    end
end

local function ToggleAntiAfk(s)
    Toggles.AntiAfk = s
    if Threads.AntiAfk then
        pcall(task.cancel, Threads.AntiAfk)
        Threads.AntiAfk = nil
    end
    
    if s then
        Threads.AntiAfk = task.spawn(function()
            local t = false
            while Toggles.AntiAfk do
                task.wait(50)
                local ch = GetChar()
                local h = ch and ch:FindFirstChildOfClass("Humanoid")
                if h then
                    t = not t
                    pcall(function()
                        h:Move(t and Vector3.new(0.1,0,0) or Vector3.new(-0.1,0,0), false)
                        task.wait(0.1)
                        h:Move(Vector3.new(), false)
                    end)
                end
            end
        end)
    end
end

-- ============================================================================
-- AUTO IFOOD
-- ============================================================================

local function GetPizzaria()
    local construcoes = Workspace:FindFirstChild("Construcoes")
    return construcoes and construcoes:FindFirstChild("Pizzaria")
end

local function GetPedidoPads()
    local pads = {}
    local pizzaria = GetPizzaria()
    local folder = pizzaria and pizzaria:FindFirstChild("ifoodplace")
    if not folder then return pads end
    for _, obj in ipairs(folder:GetChildren()) do
        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
        local pos
        if obj:IsA("BasePart") then
            pos = obj.Position
        else
            local ok, pivot = pcall(function() return obj:GetPivot() end)
            if ok then pos = pivot.Position end
        end
        if prompt and pos then
            table.insert(pads, { part = obj, prompt = prompt, position = pos })
        end
    end
    return pads
end

local function GetClientPads()
    local pads = {}
    local pizzaria = GetPizzaria()
    local folder = pizzaria and pizzaria:FindFirstChild("OrderCharSpawns")
    if not folder then return pads end
    for _, pad in ipairs(folder:GetChildren()) do
        table.insert(pads, pad)
    end
    return pads
end

local function GetActiveClient()
    for _, pad in ipairs(GetClientPads()) do
        for _, obj in ipairs(pad:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                local holder = obj.Parent
                local pos
                if holder and holder:IsA("BasePart") then
                    pos = holder.Position
                else
                    local model = obj:FindFirstAncestorWhichIsA("Model")
                    if model then
                        local ok, pivot = pcall(function() return model:GetPivot() end)
                        if ok then pos = pivot.Position end
                    end
                end
                if pos then
                    return { prompt = obj, position = pos, holder = holder }
                end
            end
        end
    end
end

local function DeleteIfoodEntrega()
    local target = Vector3.new(3306.12378, 13.8949165, 3034.4917)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Folder") then
            local ok, pivot = pcall(function() return obj:GetPivot() end)
            if ok and (pivot.Position - target).Magnitude < 2 then
                pcall(function() obj:Destroy() end)
                return true
            end
        end
    end
    return false
end

local function EntregarCliente(info, timeout)
    if not info then return false end
    timeout = timeout or 8
    ToggleNoclip(true)
    if not TpTo(info.position) then ToggleNoclip(false); return false end
    local hrp = GetHRP()
    if hrp then hrp.CFrame = CFrame.new(info.position + Vector3.new(0, 3, 0)) end
    local start = tick()
    while Toggles.AutoIfood and info.prompt and info.prompt.Parent and tick() - start < timeout do
        FirePrompt(info.prompt)
        task.wait(0.12)
    end
    DeleteIfoodEntrega()
    ToggleNoclip(false)
    return true
end

local function PegarPedidoIfood()
    local pads = GetPedidoPads()
    if #pads == 0 then return false end
    for _, info in ipairs(pads) do
        if not Toggles.AutoIfood then ToggleNoclip(false); return false end
        ToggleNoclip(true)
        if TpTo(info.position) then
            local hrp = GetHRP()
            if hrp then hrp.CFrame = CFrame.new(info.position + Vector3.new(0, 3, 0)) end
            for _ = 1, 8 do
                if not Toggles.AutoIfood then ToggleNoclip(false); return false end
                FirePrompt(info.prompt)
                task.wait(0.15)
            end
            task.wait(6)
            if GetActiveClient() then
                return true
            end
        end
    end
    ToggleNoclip(false)
    return false
end

local function AutoIfoodLoop()
    ToggleAntiSit(true)
    while Toggles.AutoIfood do
        local cliente = GetActiveClient()
        if cliente then
            EntregarCliente(cliente, 10)
        else
            PegarPedidoIfood()
        end
        task.wait(3)
    end
    ToggleNoclip(false)
end

-- ============================================================================
-- AUTO FARM GARI
-- ============================================================================

local function MoverAtePosicaoGari(posicaoAlvo)
    local humanoid = GetChar() and GetChar():FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    local originalSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = originalSpeed * 1.15
    
    local hrp = GetHRP()
    if not hrp then humanoid.WalkSpeed = originalSpeed; return false end
    
    humanoid:MoveTo(posicaoAlvo)
    
    local lastPos = hrp.Position
    local stuckTimer = 0
    local success = false
    
    for _ = 1, 300 do
        if not Toggles.AutoFarmGari then break end
        task.wait(0.1)
        if not humanoid or not humanoid.Parent then break end
        if not hrp or not hrp.Parent then break end
        
        local currentPos = hrp.Position
        local dist = (currentPos - posicaoAlvo).Magnitude
        if dist <= 3 then
            success = true
            break
        end
        
        if (currentPos - lastPos).Magnitude < 0.3 then
            stuckTimer = stuckTimer + 0.1
            if stuckTimer >= 1.5 then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                task.wait(0.2)
                humanoid:MoveTo(posicaoAlvo)
                stuckTimer = 0
            end
        else
            stuckTimer = 0
        end
        lastPos = currentPos
    end
    
    humanoid.WalkSpeed = originalSpeed
    humanoid:MoveTo(hrp.Position)
    return success
end

local function SelecionarCaminhaoGari()
    local carros = Workspace:FindFirstChild("CarrosSpawnados")
    if not carros then return nil end
    
    local hrp = GetHRP()
    if not hrp then return nil end
    
    local escolhido = nil
    local menorDist = math.huge
    
    for _, car in ipairs(carros:GetChildren()) do
        if car.Name == "Lixeiro" or car.Name:lower():find("lixeiro") then
            local pos = car:FindFirstChild("HumanoidRootPart") and car.HumanoidRootPart.Position or car:GetPivot().Position
            if pos then
                local dist = (pos - hrp.Position).Magnitude
                if dist < menorDist then
                    menorDist = dist
                    escolhido = car
                end
            end
        end
    end
    return escolhido
end

local function ObterLixosGari(caminhao, maxQuantidade)
    local lixosFolder = Workspace:FindFirstChild("Construcoes") and Workspace.Construcoes:FindFirstChild("SistemaGari") and Workspace.Construcoes.SistemaGari:FindFirstChild("Lixos")
    if not lixosFolder then return {} end
    
    local caminhaoPos = caminhao:FindFirstChild("HumanoidRootPart") and caminhao.HumanoidRootPart.Position or caminhao:GetPivot().Position
    if not caminhaoPos then return {} end
    
    local lixos = {}
    for _, obj in ipairs(lixosFolder:GetChildren()) do
        if obj.Name == "Lixo" then
            local prompt = nil
            for _, p in ipairs(obj:GetDescendants()) do
                if p:IsA("ProximityPrompt") then
                    prompt = p
                    break
                end
            end
            if prompt then
                local pos = obj:FindFirstChild("HumanoidRootPart") and obj.HumanoidRootPart.Position or obj:GetPivot().Position
                if pos then
                    local dist = (pos - caminhaoPos).Magnitude
                    table.insert(lixos, { obj = obj, pos = pos, dist = dist, prompt = prompt })
                end
            end
        end
    end
    
    table.sort(lixos, function(a,b) return a.dist < b.dist end)
    if #lixos > maxQuantidade then
        while #lixos > maxQuantidade do table.remove(lixos) end
    end
    return lixos
end

local function ObterPromptEntregaGari(caminhao)
    if not caminhao then return nil end
    local bodyPart = caminhao:FindFirstChild("body") or caminhao:FindFirstChild("Body")
    if not bodyPart then return nil end
    local proximitikk = bodyPart:FindFirstChild("Proximitikk")
    if proximitikk and proximitikk:IsA("BasePart") then
        for _, p in ipairs(proximitikk:GetDescendants()) do
            if p:IsA("ProximityPrompt") then
                return p, proximitikk
            end
        end
    end
    return nil, nil
end

local function JogadorAindaComLixoGari()
    local playerModel = Workspace:FindFirstChild(LocalPlayer.Name)
    if playerModel then
        return playerModel:FindFirstChild("Lixo") ~= nil
    end
    return false
end

local function AguardarLixoSumirGari()
    local start = tick()
    while Toggles.AutoFarmGari and tick() - start < 15 do
        if not JogadorAindaComLixoGari() then
            return true
        end
        task.wait(0.2)
    end
    return false
end

local function AutoFarmGariLoop()
    local caminhao = SelecionarCaminhaoGari()
    if not caminhao then
        Toggles.AutoFarmGari = false
        Notify("Auto Farm Gari", "Caminhão não encontrado! ✗")
        return
    end
    
    ToggleNoclip(true)
    ToggleAntiSit(true)
    
    while Toggles.AutoFarmGari do
        local lixos = ObterLixosGari(caminhao, 20)
        if #lixos == 0 then
            task.wait(2)
            continue
        end
        
        for _, lixo in ipairs(lixos) do
            if not Toggles.AutoFarmGari then break end
            
            if MoverAtePosicaoGari(lixo.pos) then
                if lixo.prompt then
                    FirePrompt(lixo.prompt)
                end
                
                local startWait = tick()
                local pegou = false
                while Toggles.AutoFarmGari and tick() - startWait < 8 do
                    if JogadorAindaComLixoGari() then
                        pegou = true
                        break
                    end
                    task.wait(0.2)
                end
                
                if pegou then
                    local promptEntrega, parteBase = ObterPromptEntregaGari(caminhao)
                    if promptEntrega and parteBase then
                        if MoverAtePosicaoGari(parteBase.Position) then
                            local hrp = GetHRP()
                            if hrp then
                                local dist = (hrp.Position - parteBase.Position).Magnitude
                                if dist <= promptEntrega.MaxActivationDistance then
                                    FirePrompt(promptEntrega)
                                end
                            end
                            
                            AguardarLixoSumirGari()
                        end
                    end
                end
            end
            task.wait(0.2)
        end
    end
    
    ToggleNoclip(false)
end

-- ============================================================================
-- AUTO UBER
-- ============================================================================

local function GetMyCar()
    local carros = Workspace:FindFirstChild("CarrosSpawnados")
    if not carros then return nil end
    for _, car in pairs(carros:GetChildren()) do
        local seat = car:FindFirstChildWhichIsA("VehicleSeat") or car:FindFirstChild("DriveSeat")
        if seat and seat.Occupant and seat.Occupant.Parent == LocalPlayer.Character then return car end
    end
    return nil
end

local function TeleportCarToDestino(car, destinoCF)
    if not car or not destinoCF then return end
    local pos = destinoCF.Position
    local rayOrigin = Vector3.new(pos.X, pos.Y + 50, pos.Z)
    local rayDirection = Vector3.new(0, -150, 0)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {car, LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local rayResult = Workspace:Raycast(rayOrigin, rayDirection, rayParams)
    local groundY = pos.Y
    if rayResult then groundY = rayResult.Position.Y + 3 end
    car:PivotTo(CFrame.new(pos.X, groundY, pos.Z))
end

local function AutoUberLoop()
    while Toggles.AutoUber do
        local destino = Workspace:FindFirstChild("LocalMarcado")
        if destino then
            local car = GetMyCar()
            if car then
                TeleportCarToDestino(car, destino.CFrame)
                task.wait(1.5)
                local rotas = Workspace:FindFirstChild("LocaisCorrida") and Workspace.LocaisCorrida:FindFirstChild("RotasCliente")
                if rotas then
                    local cps = {}
                    for _, v in pairs(rotas:GetChildren()) do
                        local n = tonumber(v.Name)
                        if n then table.insert(cps, {obj = v, i = n}) end
                    end
                    table.sort(cps, function(a,b) return a.i < b.i end)
                    for _, cp in ipairs(cps) do
                        if not Toggles.AutoUber or not Workspace:FindFirstChild("LocalMarcado") then break end
                        car = GetMyCar()
                        if car then
                            TeleportCarToDestino(car, CFrame.new(cp.obj.Position))
                            task.wait(1.35)
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end

-- ============================================================================
-- AUTO ERVA
-- ============================================================================

local autoErvaCurrentSlot = 1

local function PressNumberKey(num)
    local key = num == 1 and Enum.KeyCode.One or num == 2 and Enum.KeyCode.Two or Enum.KeyCode.Three
    local vim = game:GetService("VirtualInputManager")
    pcall(function()
        vim:SendKeyEvent(true, key, false, game)
        task.wait(0.05)
        vim:SendKeyEvent(false, key, false, game)
    end)
end

local function GetPlantinhaArea()
    local construcoes = Workspace:FindFirstChild("Construcoes")
    return construcoes and construcoes:FindFirstChild("Plantinha_Ilegal")
end

local function GetObjectPosition(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    local ok, pivot = pcall(function() return obj:GetPivot() end)
    if ok then return pivot.Position end
    local part = obj:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position or nil
end

local function GetPlayerPotInfo()
    local model = Workspace:FindFirstChild(LocalPlayer.Name)
    local pote = model and model:FindFirstChild("PoteErva", true)
    if not pote then return nil, 0 end
    local qnts = pote:FindFirstChild("qnts", true)
    local amount = 0
    if qnts and qnts.Value ~= nil then amount = tonumber(qnts.Value) or 0 end
    return pote, amount
end

local function TpToErva(pos)
    local hrp = GetHRP()
    if not hrp then return false end
    local safe = Vector3.new(pos.X, math.max(pos.Y, 4), pos.Z)
    local dir = safe - hrp.Position
    if dir.Magnitude <= 4 then
        hrp.CFrame = CFrame.lookAt(safe, safe + Vector3.new(0, 0, -1))
        return true
    end
    local u = dir.Unit
    for _ = 1, 80 do
        if not Toggles.AutoErva then return false end
        local h = GetHRP()
        if not h then return false end
        local rem = (safe - h.Position).Magnitude
        if rem <= 5 then break end
        local nxt = h.Position + u * math.min(7, rem)
        if nxt.Y < 4 then nxt = Vector3.new(nxt.X, 5, nxt.Z) end
        h.CFrame = CFrame.lookAt(nxt, nxt + u)
        local hum = GetChar() and GetChar():FindFirstChildOfClass("Humanoid")
        if hum then hum:MoveTo(nxt) end
        task.wait(0.03)
    end
    return true
end

local function GetErvaPrompts()
    local area = GetPlantinhaArea()
    local prompts = {}
    if not area then return prompts end
    for _, obj in ipairs(area:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local name = string.lower(obj.Name or "")
            if name ~= "npcvendedor" then
                table.insert(prompts, obj)
            end
        end
    end
    table.sort(prompts, function(a, b)
        local hrp = GetHRP()
        if not hrp then return false end
        local ap = GetObjectPosition(a.Parent) or hrp.Position
        local bp = GetObjectPosition(b.Parent) or hrp.Position
        return (hrp.Position - ap).Magnitude < (hrp.Position - bp).Magnitude
    end)
    return prompts
end

local function ColetarErvasUmaRodada()
    local prompts = GetErvaPrompts()
    if #prompts == 0 then return false end
    for _, prompt in ipairs(prompts) do
        if not Toggles.AutoErva then return false end
        local pos = GetObjectPosition(prompt.Parent)
        if pos then TpToErva(pos) end
        FirePrompt(prompt)
        task.wait(0.2)
    end
    return true
end

local function VenderErvas()
    local area = GetPlantinhaArea()
    local vendedor = area and area:FindFirstChild("Vendedor", true)
    if not vendedor then return false end
    local pos = GetObjectPosition(vendedor)
    if pos then TpToErva(pos) end
    task.wait(0.4)
    local promptVenda
    for _, obj in ipairs(vendedor:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and string.lower(obj.Name or "") == "npcvendedor" then
            promptVenda = obj
            break
        end
    end
    if not promptVenda then
        promptVenda = vendedor:FindFirstChildWhichIsA("ProximityPrompt", true)
    end
    if not promptVenda then return false end
    for _ = 1, 8 do
        if not Toggles.AutoErva then return false end
        FirePrompt(promptVenda)
        task.wait(0.2)
    end
    return true
end

local function TrocarProximoPote()
    if autoErvaCurrentSlot >= 3 then return false end
    autoErvaCurrentSlot = autoErvaCurrentSlot + 1
    PressNumberKey(autoErvaCurrentSlot)
    task.wait(0.5)
    return GetPlayerPotInfo() ~= nil
end

local function AutoErvaLoop()
    ToggleNoclip(true)
    ToggleAntiSit(true)
    autoErvaCurrentSlot = 1
    while Toggles.AutoErva do
        local pote = GetPlayerPotInfo()
        if not pote then
            task.wait(1.5)
            continue
        end
        local area = GetPlantinhaArea()
        local areaPos = GetObjectPosition(area)
        if areaPos then TpToErva(areaPos) end

        local semAumento = 0
        local ultimaQnt = -1
        while Toggles.AutoErva do
            local _, qnt = GetPlayerPotInfo()
            if qnt >= 10 then
                if not TrocarProximoPote() then break end
                ultimaQnt = -1
                semAumento = 0
                continue
            end
            local coletou = ColetarErvasUmaRodada()
            task.wait(0.7)
            local _, novaQnt = GetPlayerPotInfo()
            if not coletou or novaQnt == ultimaQnt then
                semAumento = semAumento + 1
            else
                semAumento = 0
                ultimaQnt = novaQnt
            end
            if semAumento >= 5 then
                if not TrocarProximoPote() then break end
                semAumento = 0
                ultimaQnt = -1
            end
        end

        VenderErvas()
        autoErvaCurrentSlot = 1
        PressNumberKey(1)
        task.wait(1)
    end
    ToggleNoclip(false)
end

-- ============================================================================
-- TAB 1: FARM (ILHA BELA)
-- ============================================================================

local FarmTab = Window:CreateTab({ Name = "Farm", Icon = "rbxassetid://10651113645" })

local IfoodSection = FarmTab:CreateSection("Auto Ifood")
IfoodSection:CreateToggle({
    Name = "Auto Ifood",
    Default = false,
    Callback = function(state)
        Toggles.AutoIfood = state
        if state then
            Threads.AutoIfood = task.spawn(AutoIfoodLoop)
            Notify("Auto Ifood", "Iniciado! ✓", 3)
        else
            if Threads.AutoIfood then
                pcall(task.cancel, Threads.AutoIfood)
                Threads.AutoIfood = nil
            end
            ToggleNoclip(false)
            Notify("Auto Ifood", "Parado! ✗", 3)
        end
    end
})

local GariSection = FarmTab:CreateSection("Auto Farm Gari")
GariSection:CreateToggle({
    Name = "Auto Farm Gari",
    Default = false,
    Callback = function(state)
        Toggles.AutoFarmGari = state
        if state then
            Threads.AutoFarmGari = task.spawn(AutoFarmGariLoop)
            Notify("Auto Farm Gari", "Iniciado! ✓", 3)
        else
            if Threads.AutoFarmGari then
                pcall(task.cancel, Threads.AutoFarmGari)
                Threads.AutoFarmGari = nil
            end
            ToggleNoclip(false)
            Notify("Auto Farm Gari", "Parado! ✗", 3)
        end
    end
})

local ErvaSection = FarmTab:CreateSection("Auto Erva")
ErvaSection:CreateToggle({
    Name = "Auto Erva",
    Default = false,
    Callback = function(state)
        Toggles.AutoErva = state
        if state then
            Threads.AutoErva = task.spawn(AutoErvaLoop)
            Notify("Auto Erva", "Iniciado! ✓", 3)
        else
            if Threads.AutoErva then
                pcall(task.cancel, Threads.AutoErva)
                Threads.AutoErva = nil
            end
            ToggleNoclip(false)
            Notify("Auto Erva", "Parado! ✗", 3)
        end
    end
})

-- ============================================================================
-- TAB 2: UBER
-- ============================================================================

local UberTab = Window:CreateTab({ Name = "Uber", Icon = "rbxassetid://10651113645" })
local UberSection = UberTab:CreateSection("Auto Uber")

UberSection:CreateToggle({
    Name = "Auto Uber",
    Default = false,
    Callback = function(state)
        Toggles.AutoUber = state
        if state then
            Threads.AutoUber = task.spawn(AutoUberLoop)
            Notify("Auto Uber", "Iniciado! ✓", 3)
        else
            if Threads.AutoUber then
                pcall(task.cancel, Threads.AutoUber)
                Threads.AutoUber = nil
            end
            Notify("Auto Uber", "Parado! ✗", 3)
        end
    end
})

-- ============================================================================
-- TAB 3: LEGITBOT (Exemplo)
-- ============================================================================

local LegitbotTab = Window:CreateTab({ Name = "Legitbot", Icon = "rbxassetid://10651113645" })
local AimSection = LegitbotTab:CreateSection("Aimbot Settings")

AimSection:CreateToggle({
    Name = "Enable Aimbot",
    Default = false,
    Callback = function(state) 
        Toggles.AimbotEnabled = state
        print("Aimbot:", state) 
    end
})

AimSection:CreateKeybind({
    Name = "Aimbot Key",
    Default = Enum.UserInputType.MouseButton2,
    Callback = function(key) print("Aimbot key:", key) end
})

AimSection:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "Torso", "Random"},
    Default = "Head",
    Callback = function(selected) print("Target:", selected) end
})

AimSection:CreateSlider({
    Name = "Smoothing",
    Min = 1,
    Max = 100,
    Default = 20,
    Suffix = "%",
    Callback = function(val) print("Smoothing:", val) end
})

local FovSection = LegitbotTab:CreateSection("FOV Configs")
FovSection:CreateToggle({ Name = "Draw FOV", Default = true, Callback = function(s) end })
FovSection:CreateColorPicker({
    Name = "FOV Color",
    Default = Color3.fromRGB(80, 210, 255),
    Callback = function(c) end
})
FovSection:CreateSlider({ Name = "FOV Radius", Min = 10, Max = 800, Default = 150, Callback = function() end })

-- ============================================================================
-- TAB 4: VISUALS
-- ============================================================================

local VisualsTab = Window:CreateTab({ Name = "Visuals", Icon = "rbxassetid://11222047805" })

local EspSection = VisualsTab:CreateSection("Player ESP")
EspSection:CreateToggle({ 
    Name = "Enable ESP", 
    Default = false, 
    Callback = function(state) 
        Toggles.ESPEnabled = state
    end 
})
EspSection:CreateToggle({ Name = "Show Boxes", Default = false, Callback = function() end })
EspSection:CreateToggle({ Name = "Show Names", Default = true, Callback = function() end })
EspSection:CreateToggle({ Name = "Show Health", Default = true, Callback = function() end })

local ColorSection = VisualsTab:CreateSection("ESP Colors")
ColorSection:CreateColorPicker({ Name = "Enemy Color", Default = Color3.fromRGB(255, 50, 50), Callback = function() end })
ColorSection:CreateColorPicker({ Name = "Team Color", Default = Color3.fromRGB(50, 255, 50), Callback = function() end })

-- ============================================================================
-- TAB 5: MISC
-- ============================================================================

local MiscTab = Window:CreateTab({ Name = "Misc", Icon = "rbxassetid://10651113645" })

local PlayerSection = MiscTab:CreateSection("LocalPlayer")
PlayerSection:CreateSlider({
    Name = "WalkSpeed",
    Min = 16,
    Max = 200,
    Default = 16,
    Suffix = " m/s",
    Callback = function(val)
        if GetChar() and GetChar():FindFirstChild("Humanoid") then
            GetChar().Humanoid.WalkSpeed = val
        end
    end
})
PlayerSection:CreateToggle({ Name = "Infinite Jump", Default = false, Callback = function() end })

local NoclipSection = MiscTab:CreateSection("NoClip")
NoclipSection:CreateToggle({ 
    Name = "NoClip", 
    Default = false, 
    Callback = function(state) 
        ToggleNoclip(state)
    end 
})
NoclipSection:CreateKeybind({ 
    Name = "NoClip Key", 
    Default = Enum.KeyCode.N, 
    Callback = function(key) end,
    OnPressed = function()
        ToggleNoclip(not Toggles.Noclip)
    end
})

local AntiSection = MiscTab:CreateSection("Anti Systems")
AntiSection:CreateToggle({ 
    Name = "Anti AFK", 
    Default = true, 
    Callback = function(state) 
        ToggleAntiAfk(state)
    end 
})
AntiSection:CreateToggle({ 
    Name = "Anti Sit", 
    Default = true, 
    Callback = function(state) 
        ToggleAntiSit(state)
    end 
})

local FunSection = MiscTab:CreateSection("Fun")
FunSection:CreateTextbox({
    Name = "Chat Spammer",
    Placeholder = "Enter text to spam...",
    Callback = function(text) print("Spamming:", text) end
})
FunSection:CreateButton({
    Name = "Teleport to Spawn",
    Callback = function() print("Teleported") end
})

local ElementsSection = MiscTab:CreateSection("Extra Components")
ElementsSection:CreateParagraph({
    Name = "Information",
    Content = "Sistema completo com Farm, Uber, Erva e sistemas de proteção."
})
ElementsSection:CreateLabel({
    Name = "System Running: ✓ OK",
    Icon = "rbxassetid://11222047805"
})

-- ============================================================================
-- TAB 6: ENVIRONMENT
-- ============================================================================

local EnvironmentTab = Window:CreateTab({ Name = "Environment", Icon = "rbxassetid://11222047805" })

local LightingSection = EnvironmentTab:CreateSection("Lighting")
LightingSection:CreateSlider({
    Name = "Brightness",
    Min = 0,
    Max = 2,
    Default = 1,
    Suffix = "x",
    Callback = function(value)
        pcall(function()
            Lighting.Ambient = Color3.fromRGB(
                math.min(255 * value, 255),
                math.min(255 * value, 255),
                math.min(255 * value, 255)
            )
        end)
    end
})

LightingSection:CreateButton({
    Name = "Reset Lighting",
    Callback = function()
        Lighting.Ambient = Color3.fromRGB(100, 100, 100)
        Lighting.OutdoorAmbient = Color3.fromRGB(100, 100, 100)
        Notify("Lighting", "Resetado!", 3)
    end
})

-- ============================================================================
-- TAB 7: CONFIGS
-- ============================================================================

local ConfigTab = Window:CreateTab({ Name = "Configs", Icon = "rbxassetid://11222047805" })
local SaveSection = ConfigTab:CreateSection("Save & Load")

SaveSection:CreateTextbox({
    Name = "Config Name",
    Placeholder = "my_config",
    Callback = function() end
})

SaveSection:CreateButton({
    Name = "Save Configuration",
    Callback = function()
        Notify("Saved", "Configuration saved successfully!", 3)
    end
})

SaveSection:CreateButton({
    Name = "Load Configuration",
    Callback = function()
        Notify("Loaded", "Settings applied!", 3)
    end
})

local UiSection = ConfigTab:CreateSection("UI Settings")
UiSection:CreateKeybind({
    Name = "Toggle Menu Key",
    Default = Enum.KeyCode.RightShift,
    Callback = function(key) end,
    OnPressed = function() Window:Toggle() end
})
UiSection:CreateButton({
    Name = "Unload UI",
    Callback = function() Window:Destroy() end
})

-- ============================================================================
-- INICIALIZAÇÃO
-- ============================================================================

print("✓ Ultimate Cheat Menu + Ilha Bela 2.0 - Carregado com sucesso!")
Notify("Ultimate Cheat Menu", "Carregado com sucesso! ✓", 5)

-- Anti AFK ativado por padrão
ToggleAntiAfk(true)
ToggleAntiSit(true)
