local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/guzinsamuel2-web/lib/refs/heads/main/README.md"))()

local Window = Library:CreateWindow({
    Title = "Ultimate Cheat Menu UI",
    Icon = "rbxassetid://13149791439",
    Theme = "Dark"
})

-----------------------------------------------------------
-- TAB 1: LEGITBOT (Exemplos)
-----------------------------------------------------------
local LegitbotTab = Window:CreateTab({ Name = "Legitbot", Icon = "rbxassetid://10651113645" })
local AimSection = LegitbotTab:CreateSection("Aimbot Settings")

AimSection:CreateToggle({
    Name = "Enable Aimbot",
    Default = false,
    Callback = function(state) print("Aimbot:", state) end
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

-----------------------------------------------------------
-- TAB 2: VISUALS 
-----------------------------------------------------------
local VisualsTab = Window:CreateTab({ Name = "Visuals", Icon = "rbxassetid://11222047805" })

local EspSection = VisualsTab:CreateSection("Player ESP")
EspSection:CreateToggle({ Name = "Enable ESP", Default = true, Callback = function() end })
EspSection:CreateToggle({ Name = "Show Boxes", Default = false, Callback = function() end })
EspSection:CreateToggle({ Name = "Show Names", Default = true, Callback = function() end })
EspSection:CreateToggle({ Name = "Show Health", Default = true, Callback = function() end })

local ColorSection = VisualsTab:CreateSection("ESP Colors")
ColorSection:CreateColorPicker({ Name = "Enemy Color", Default = Color3.fromRGB(255, 50, 50), Callback = function() end })
ColorSection:CreateColorPicker({ Name = "Team Color", Default = Color3.fromRGB(50, 255, 50), Callback = function() end })

-----------------------------------------------------------
-- TAB 3: MISC 
-----------------------------------------------------------
local MiscTab = Window:CreateTab({ Name = "Misc", Icon = "rbxassetid://10651113645" })

local PlayerSection = MiscTab:CreateSection("LocalPlayer")
PlayerSection:CreateSlider({
    Name = "WalkSpeed",
    Min = 16,
    Max = 200,
    Default = 16,
    Suffix = " m/s",
    Callback = function(val)
        if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = val
        end
    end
})
PlayerSection:CreateToggle({ Name = "Infinite Jump", Default = false, Callback = function() end })
PlayerSection:CreateToggle({ Name = "No Clip", Default = false, Callback = function() end })
PlayerSection:CreateKeybind({ Name = "No Clip Key", Default = Enum.KeyCode.N, Callback = function() end })

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
    Content = "This section shows off text labels and paragraphs inside the grid system."
})
ElementsSection:CreateLabel({
    Name = "System Running: OK",
    Icon = "rbxassetid://11222047805"
})

-----------------------------------------------------------
-- TAB 4: CONFIGS
-----------------------------------------------------------
local ConfigTab = Window:CreateTab({ Name = "Configs", Icon = "rbxassetid://11222047805" })
local SaveSection = ConfigTab:CreateSection("Save & Load")

SaveSection:CreateTextbox({
    Name = "Config Name",
    Placeholder = "my_legit_config",
    Callback = function() end
})

SaveSection:CreateButton({
    Name = "Save Configuration",
    Callback = function()
        Library:Notify({
            Title = "Saved!",
            Message = "Your configuration has been saved successfully.",
            Type = "Success"
        })
    end
})

SaveSection:CreateButton({
    Name = "Load Configuration",
    Callback = function()
        Window:Dialog({
            Title = "Load Config?",
            Message = "Are you sure you want to overwrite your current settings?",
            Options = {
                {
                    Name = "Yes",
                    Callback = function()
                        Library:Notify({ Title = "Loaded", Message = "Settings applied.", Type = "Info" })
                    end
                },
                {
                    Name = "No",
                    Callback = function() end
                }
            }
        })
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

print("✓ Ultimate Cheat Menu UI - Carregado com sucesso!")
