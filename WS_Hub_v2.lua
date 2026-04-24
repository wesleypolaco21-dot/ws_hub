--[[
  ██╗    ██╗███████╗    ██╗  ██╗██╗   ██╗██████╗
  ██║    ██║██╔════╝    ██║  ██║██║   ██║██╔══██╗
  ██║ █╗ ██║███████╗    ███████║██║   ██║██████╔╝
  ██║███╗██║╚════██║    ██╔══██║██║   ██║██╔══██╗
  ╚███╔███╔╝███████║    ██║  ██║╚██████╔╝██████╔╝
   ╚══╝╚══╝ ╚══════╝    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝
  WS Hub v2.0
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local lp = Players.LocalPlayer

-- ============================================================
-- CONFIG (edite aqui os valores)
-- ============================================================
local CFG = {
    DuelsSpeed      = 59.5,   -- velocidade da aba Speed (Duels)
    SpeedBooster    = 29.5,   -- velocidade Speed Booster
    FlySpeed        = 55,     -- velocidade do Fly Defender e Bat Aimbot
    SpinSpeed       = 30,     -- velocidade do spin (rad/s)
    FloatHeight     = 10,     -- altura do float (studs)
    HelicopterSpeed = 40,     -- velocidade horizontal do helicopter
    BatDelay        = 0.15,   -- delay do Auto Bat (segundos)
    SpamDelay       = 0.08,   -- delay do Spam Bat (segundos)
    AimbotSpeed     = 55,     -- velocidade de approach do Bat Aimbot
    STEP_MIN        = 2,      -- incremento mínimo dos botões +/-
}

-- ============================================================
-- ANTI-KICK
-- ============================================================
pcall(function()
    for _, v in pairs(getconnections(lp.Idled)) do v:Disable() end
    game:GetService("ScriptContext").Error:Connect(function() return end)
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local old = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local m = getnamecallmethod()
        if m == "Kick" or m == "kick" then return nil end
        return old(self, ...)
    end)
end)

-- ============================================================
-- HELPERS
-- ============================================================
local function getChar()  return lp.Character or lp.CharacterAdded:Wait() end
local function getHRP()   local c=getChar() return c:WaitForChild("HumanoidRootPart") end

local function findBat()
    local c = lp.Character; if not c then return end
    return c:FindFirstChild("Bat") or (lp.Backpack and lp.Backpack:FindFirstChild("Bat"))
end

local function getNearestEnemy()
    local c = lp.Character; if not c then return nil end
    local h = c:FindFirstChild("HumanoidRootPart"); if not h then return nil end
    local best, bestD = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local eh  = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if eh and hum and hum.Health > 0 then
                local d = (eh.Position - h.Position).Magnitude
                if d < bestD then bestD = d; best = p.Character end
            end
        end
    end
    return best
end

local function getHRPSpeed(hrp)
    if not hrp then return 0 end
    local v = hrp.AssemblyLinearVelocity
    return math.floor(Vector3.new(v.X, 0, v.Z).Magnitude * 10) / 10
end

-- ============================================================
-- STATE
-- ============================================================
local State = {}
local Connections = {}

local function cleanup(k)
    if Connections[k] then Connections[k]:Disconnect() Connections[k] = nil end
end

-- ============================================================
-- CORES
-- ============================================================
local C = {
    BG       = Color3.fromRGB(18, 18, 18),
    Panel    = Color3.fromRGB(26, 26, 26),
    TabBG    = Color3.fromRGB(22, 22, 22),
    Border   = Color3.fromRGB(60, 60, 60),
    Text     = Color3.fromRGB(220, 220, 220),
    Sub      = Color3.fromRGB(130, 130, 130),
    ON       = Color3.fromRGB(55, 55, 55),
    OFF      = Color3.fromRGB(30, 30, 30),
    ONText   = Color3.fromRGB(200, 255, 180),
    OFFText  = Color3.fromRGB(180, 180, 180),
    Accent   = Color3.fromRGB(80, 80, 80),
    HUD      = Color3.fromRGB(12, 12, 12),
    HUDText  = Color3.fromRGB(200, 200, 200),
    HUDHigh  = Color3.fromRGB(255, 255, 255),
}

-- ============================================================
-- GUI FACTORY
-- ============================================================
local function make(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do if k ~= "Parent" then obj[k] = v end end
    if props.Parent then obj.Parent = props.Parent end
    return obj
end

pcall(function()
    if CoreGui:FindFirstChild("WSHub_v2") then CoreGui.WSHub_v2:Destroy() end
end)

local Root = make("ScreenGui", {
    Name          = "WSHub_v2",
    ResetOnSpawn  = false,
    ZIndexBehavior= Enum.ZIndexBehavior.Sibling,
    Parent        = CoreGui,
})

-- ============================================================
-- TOGGLE ICON
-- ============================================================
local IconBtn = make("TextButton", {
    Size            = UDim2.new(0, 46, 0, 46),
    Position        = UDim2.new(0, 10, 0.5, -23),
    BackgroundColor3= C.BG,
    Text            = "WS",
    TextColor3      = C.Text,
    Font            = Enum.Font.GothamBold,
    TextSize        = 13,
    Parent          = Root,
})
make("UICorner", {CornerRadius=UDim.new(0,8),  Parent=IconBtn})
make("UIStroke", {Color=C.Border,Thickness=1.5,Parent=IconBtn})

-- ============================================================
-- MAIN WINDOW
-- ============================================================
local Win = make("Frame", {
    Size            = UDim2.new(0, 380, 0, 480),
    Position        = UDim2.new(0.5,-190, 0.5,-240),
    BackgroundColor3= C.BG,
    Visible         = false,
    Active          = true,
    Parent          = Root,
})
make("UICorner", {CornerRadius=UDim.new(0,10), Parent=Win})
make("UIStroke", {Color=C.Border, Thickness=1, Parent=Win})

-- ── HEADER ──
local Head = make("Frame", {
    Size            = UDim2.new(1,0,0,40),
    BackgroundColor3= C.Panel,
    Parent          = Win,
})
make("UICorner", {CornerRadius=UDim.new(0,10), Parent=Head})

make("TextLabel", {
    Text            = "WS HUB  v2.0",
    Size            = UDim2.new(0.7,0,1,0),
    Position        = UDim2.new(0.03,0,0,0),
    BackgroundTransparency=1,
    TextColor3      = C.Text,
    Font            = Enum.Font.GothamBold,
    TextSize        = 15,
    TextXAlignment  = Enum.TextXAlignment.Left,
    Parent          = Head,
})

local XBtn = make("TextButton", {
    Size            = UDim2.new(0,26,0,26),
    Position        = UDim2.new(1,-32,0.5,-13),
    BackgroundColor3= Color3.fromRGB(60,30,30),
    Text            = "X",
    TextColor3      = Color3.fromRGB(220,100,100),
    Font            = Enum.Font.GothamBold,
    TextSize        = 12,
    Parent          = Head,
})
make("UICorner", {CornerRadius=UDim.new(0,5), Parent=XBtn})
XBtn.MouseButton1Click:Connect(function() Win.Visible=false end)

-- ── DIVIDER ──
make("Frame", {
    Size=UDim2.new(0.94,0,0,1), Position=UDim2.new(0.03,0,0,41),
    BackgroundColor3=C.Border, BorderSizePixel=0, Parent=Win,
})

-- ── TAB BAR ──
local TabBar = make("Frame", {
    Size            = UDim2.new(0.94,0,0,30),
    Position        = UDim2.new(0.03,0,0,46),
    BackgroundColor3= C.TabBG,
    Parent          = Win,
})
make("UICorner",     {CornerRadius=UDim.new(0,6), Parent=TabBar})
make("UIListLayout", {
    FillDirection       = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    Parent              = TabBar,
})

-- ── PAGE AREA ──
local PageArea = make("Frame", {
    Size                = UDim2.new(1,0,0,385),
    Position            = UDim2.new(0,0,0,80),
    BackgroundTransparency=1,
    Parent              = Win,
})

local Pages, TabBtns = {}, {}

local function CreatePage(name)
    local page = make("ScrollingFrame", {
        Size                = UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Visible             = false,
        ScrollBarThickness  = 3,
        ScrollBarImageColor3= C.Border,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent              = PageArea,
    })
    make("UIListLayout",{HorizontalAlignment=Enum.HorizontalAlignment.Center,
                          Padding=UDim.new(0,5), Parent=page})
    make("UIPadding",  {PaddingTop=UDim.new(0,6), Parent=page})
    Pages[name] = page

    local btn = make("TextButton", {
        Size            = UDim2.new(0.24,0,1,0),
        BackgroundTransparency=1,
        Text            = name,
        TextColor3      = C.Sub,
        Font            = Enum.Font.GothamBold,
        TextSize        = 11,
        Parent          = TabBar,
    })
    btn.MouseButton1Click:Connect(function()
        for _,p in pairs(Pages)   do p.Visible=false end
        for _,b in pairs(TabBtns) do b.TextColor3=C.Sub end
        page.Visible   = true
        btn.TextColor3 = C.Text
    end)
    TabBtns[name] = btn
end

-- ============================================================
-- BUTTON ROW  (toggle button style)
-- ============================================================
local function AddButton(pageName, label, onToggle)
    local active = false

    local row = make("Frame", {
        Size            = UDim2.new(0.93,0,0,42),
        BackgroundColor3= C.OFF,
        Parent          = Pages[pageName],
    })
    make("UICorner", {CornerRadius=UDim.new(0,7), Parent=row})
    make("UIStroke", {Color=C.Border, Thickness=1, Transparency=0.5, Parent=row})

    local lbl = make("TextLabel", {
        Text            = label,
        Size            = UDim2.new(0.72,0,1,0),
        Position        = UDim2.new(0.04,0,0,0),
        BackgroundTransparency=1,
        TextColor3      = C.OFFText,
        Font            = Enum.Font.GothamBold,
        TextSize        = 13,
        TextXAlignment  = Enum.TextXAlignment.Left,
        Parent          = row,
    })

    local pill = make("TextLabel", {
        Text            = "OFF",
        Size            = UDim2.new(0,46,0,22),
        Position        = UDim2.new(1,-54,0.5,-11),
        BackgroundColor3= Color3.fromRGB(40,40,40),
        TextColor3      = C.Sub,
        Font            = Enum.Font.GothamBold,
        TextSize        = 11,
        TextXAlignment  = Enum.TextXAlignment.Center,
        Parent          = row,
    })
    make("UICorner", {CornerRadius=UDim.new(0,5), Parent=pill})

    local clickBtn = make("TextButton", {
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Text="",
        Parent=row,
    })
    clickBtn.MouseButton1Click:Connect(function()
        active = not active
        if active then
            TweenService:Create(row,  TweenInfo.new(0.15), {BackgroundColor3=C.ON}):Play()
            TweenService:Create(lbl,  TweenInfo.new(0.15), {TextColor3=C.ONText}):Play()
            TweenService:Create(pill, TweenInfo.new(0.15), {
                BackgroundColor3=Color3.fromRGB(60,90,55),
                TextColor3=C.ONText,
            }):Play()
            pill.Text = "ON"
        else
            TweenService:Create(row,  TweenInfo.new(0.15), {BackgroundColor3=C.OFF}):Play()
            TweenService:Create(lbl,  TweenInfo.new(0.15), {TextColor3=C.OFFText}):Play()
            TweenService:Create(pill, TweenInfo.new(0.15), {
                BackgroundColor3=Color3.fromRGB(40,40,40),
                TextColor3=C.Sub,
            }):Play()
            pill.Text = "OFF"
        end
        onToggle(active)
    end)

    return row
end

-- ============================================================
-- CONFIG ROW  (label + value + -/+ buttons)
-- ============================================================
local function AddConfig(pageName, label, cfgKey, step, minVal, maxVal)
    local row = make("Frame", {
        Size            = UDim2.new(0.93,0,0,42),
        BackgroundColor3= C.Panel,
        Parent          = Pages[pageName],
    })
    make("UICorner", {CornerRadius=UDim.new(0,7), Parent=row})
    make("UIStroke", {Color=C.Border, Thickness=1, Transparency=0.6, Parent=row})

    make("TextLabel", {
        Text            = label,
        Size            = UDim2.new(0.5,0,1,0),
        Position        = UDim2.new(0.04,0,0,0),
        BackgroundTransparency=1,
        TextColor3      = C.Sub,
        Font            = Enum.Font.Gotham,
        TextSize        = 12,
        TextXAlignment  = Enum.TextXAlignment.Left,
        Parent          = row,
    })

    local valLabel = make("TextLabel", {
        Text            = tostring(CFG[cfgKey]),
        Size            = UDim2.new(0.2,0,1,0),
        Position        = UDim2.new(0.52,0,0,0),
        BackgroundTransparency=1,
        TextColor3      = C.Text,
        Font            = Enum.Font.GothamBold,
        TextSize        = 13,
        TextXAlignment  = Enum.TextXAlignment.Center,
        Parent          = row,
    })

    local function mkBtn(xOff, char, delta)
        local b = make("TextButton", {
            Size            = UDim2.new(0,26,0,26),
            Position        = UDim2.new(1,xOff,0.5,-13),
            BackgroundColor3= Color3.fromRGB(38,38,38),
            Text            = char,
            TextColor3      = C.Text,
            Font            = Enum.Font.GothamBold,
            TextSize        = 14,
            Parent          = row,
        })
        make("UICorner",{CornerRadius=UDim.new(0,5),Parent=b})
        make("UIStroke",{Color=C.Border,Thickness=1,Parent=b})
        b.MouseButton1Click:Connect(function()
            local cur = CFG[cfgKey]
            local new = math.clamp(cur + delta, minVal or -9999, maxVal or 9999)
            CFG[cfgKey] = math.floor(new * 10) / 10
            valLabel.Text = tostring(CFG[cfgKey])
        end)
        return b
    end

    mkBtn(-32, "+", step)
    mkBtn(-62, "-", -step)
end

-- ============================================================
-- CREATE PAGES
-- ============================================================
for _, t in ipairs({"Combat","Speed","Duel","Config"}) do CreatePage(t) end
TabBtns["Combat"].TextColor3 = C.Text
Pages["Combat"].Visible = true

-- ============================================================
-- FEATURE LOGIC
-- ============================================================

-- ── BAT AIMBOT ──────────────────────────────────────────────
local BAData = {align=nil, attach=nil}
local function startBatAimbot()
    local c=getChar(); local h=c:WaitForChild("HumanoidRootPart")
    BAData.attach = Instance.new("Attachment",h)
    BAData.align  = Instance.new("AlignOrientation",h)
    BAData.align.Attachment0=BAData.attach
    BAData.align.Mode=Enum.OrientationAlignmentMode.OneAttachment
    BAData.align.RigidityEnabled=true
    BAData.align.MaxTorque=math.huge
    BAData.align.Enabled=false
    Connections.BatAimbot = RunService.Heartbeat:Connect(function()
        if not State.BatAimbot then return end
        local ch=lp.Character; if not ch then return end
        local hrp=ch:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local hum=ch:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local bat=findBat()
        if bat and bat.Parent~=ch then pcall(function() hum:EquipTool(bat) end) end
        local tgt=getNearestEnemy()
        if tgt then
            local th=tgt:FindFirstChild("HumanoidRootPart")
            if th then
                hum.AutoRotate=false
                BAData.align.Enabled=true
                BAData.align.CFrame=CFrame.lookAt(hrp.Position,
                    Vector3.new(th.Position.X,hrp.Position.Y,th.Position.Z))
                local flat=Vector3.new(th.Position.X-hrp.Position.X,0,th.Position.Z-hrp.Position.Z)
                if flat.Magnitude>1.5 then
                    hrp.AssemblyLinearVelocity=Vector3.new(
                        flat.Unit.X*CFG.AimbotSpeed, hrp.AssemblyLinearVelocity.Y,
                        flat.Unit.Z*CFG.AimbotSpeed)
                end
                local eb=ch:FindFirstChild("Bat") or ch:FindFirstChild("Medusa")
                if eb then pcall(function() eb:Activate() end) end
            end
        else
            BAData.align.Enabled=false; hum.AutoRotate=true
        end
    end)
end
local function stopBatAimbot()
    cleanup("BatAimbot")
    if BAData.align  then BAData.align:Destroy()  BAData.align=nil end
    if BAData.attach then BAData.attach:Destroy() BAData.attach=nil end
    pcall(function() if lp.Character then lp.Character.Humanoid.AutoRotate=true end end)
end

-- ── HIT CIRCLE ───────────────────────────────────────────────
local HC={conn=nil,circle=nil,align=nil,attach=nil}
local function startHitCircle()
    local c=getChar(); local h=c:WaitForChild("HumanoidRootPart")
    HC.attach=Instance.new("Attachment",h)
    HC.align=Instance.new("AlignOrientation",h)
    HC.align.Attachment0=HC.attach
    HC.align.Mode=Enum.OrientationAlignmentMode.OneAttachment
    HC.align.RigidityEnabled=true
    HC.circle=Instance.new("Part")
    HC.circle.Shape=Enum.PartType.Cylinder
    HC.circle.Material=Enum.Material.Neon
    HC.circle.Size=Vector3.new(0.05,14,14)
    HC.circle.Color=Color3.fromRGB(180,180,180)
    HC.circle.CanCollide=false; HC.circle.Massless=true
    HC.circle.Parent=workspace
    local w=Instance.new("Weld")
    w.Part0=h; w.Part1=HC.circle
    w.C0=CFrame.new(0,-1,0)*CFrame.Angles(0,0,math.rad(90))
    w.Parent=HC.circle
    HC.conn=RunService.RenderStepped:Connect(function()
        if not State.HitCircle then return end
        local ch=lp.Character; if not ch then return end
        local hrp=ch:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local tgt,dist=nil,7.5
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local d=(p.Character.HumanoidRootPart.Position-hrp.Position).Magnitude
                if d<=dist then dist=d; tgt=p.Character.HumanoidRootPart end
            end
        end
        if tgt then
            ch.Humanoid.AutoRotate=false
            HC.align.Enabled=true
            HC.align.CFrame=CFrame.lookAt(hrp.Position,
                Vector3.new(tgt.Position.X,hrp.Position.Y,tgt.Position.Z))
            local eb=ch:FindFirstChild("Bat") or ch:FindFirstChild("Medusa")
            if eb then pcall(function() eb:Activate() end) end
        else
            HC.align.Enabled=false; ch.Humanoid.AutoRotate=true
        end
    end)
end
local function stopHitCircle()
    if HC.conn   then HC.conn:Disconnect()   HC.conn=nil end
    if HC.circle then HC.circle:Destroy()    HC.circle=nil end
    if HC.align  then HC.align:Destroy()     HC.align=nil end
    if HC.attach then HC.attach:Destroy()    HC.attach=nil end
    pcall(function() if lp.Character then lp.Character.Humanoid.AutoRotate=true end end)
end

-- ── AUTO BAT ────────────────────────────────────────────────
local autoBatThr=nil
local function startAutoBat()
    autoBatThr=task.spawn(function()
        while State.AutoBat do
            local c=lp.Character
            if c then
                local hum=c:FindFirstChildOfClass("Humanoid")
                if hum then
                    local bat=findBat()
                    if bat then
                        if bat.Parent==lp.Backpack then hum:EquipTool(bat) task.wait(0.1) end
                        local eb=c:FindFirstChild("Bat")
                        if eb then pcall(function() eb:Activate() end) end
                    end
                end
            end
            task.wait(CFG.BatDelay)
        end
    end)
end
local function stopAutoBat()
    if autoBatThr then pcall(function() task.cancel(autoBatThr) end) autoBatThr=nil end
end

-- ── FLY DEFENDER ────────────────────────────────────────────
local flyBatThr=nil
local function startFlyDefender()
    flyBatThr=task.spawn(function()
        while State.FlyDefender do
            local c=lp.Character
            if c then
                local hum=c:FindFirstChildOfClass("Humanoid")
                if hum then
                    local bat=findBat()
                    if bat then
                        if bat.Parent==lp.Backpack then hum:EquipTool(bat) task.wait(0.1) end
                        local eb=c:FindFirstChild("Bat")
                        if eb then pcall(function() eb:Activate() end) end
                    end
                end
            end
            task.wait(CFG.BatDelay)
        end
    end)
    Connections.FlyDefender=RunService.Heartbeat:Connect(function()
        if not State.FlyDefender then return end
        local c=lp.Character; if not c then return end
        local h=c:FindFirstChild("HumanoidRootPart"); if not h then return end
        local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local tgt=getNearestEnemy()
        if tgt then
            local th=tgt:FindFirstChild("HumanoidRootPart")
            if th then
                h.AssemblyLinearVelocity=(th.Position-h.Position).Unit*CFG.FlySpeed
                hum.PlatformStand=true
            end
        end
    end)
end
local function stopFlyDefender()
    cleanup("FlyDefender")
    if flyBatThr then pcall(function() task.cancel(flyBatThr) end) flyBatThr=nil end
    pcall(function()
        if lp.Character then
            local h=lp.Character:FindFirstChild("HumanoidRootPart")
            local hum=lp.Character:FindFirstChildOfClass("Humanoid")
            if h then h.AssemblyLinearVelocity=Vector3.zero end
            if hum then hum.PlatformStand=false end
        end
    end)
end

-- ── SPAM BAT ────────────────────────────────────────────────
local spamThr=nil
local function startSpamBat()
    spamThr=task.spawn(function()
        while State.SpamBat do
            local c=lp.Character
            if c then
                local hum=c:FindFirstChildOfClass("Humanoid")
                if hum then
                    local bat=findBat()
                    if bat then
                        if bat.Parent==lp.Backpack then hum:EquipTool(bat) task.wait(0.05) end
                        local eb=c:FindFirstChild("Bat")
                        if eb then pcall(function() eb:Activate() end) end
                    end
                end
            end
            task.wait(CFG.SpamDelay)
        end
    end)
end
local function stopSpamBat()
    if spamThr then pcall(function() task.cancel(spamThr) end) spamThr=nil end
end

-- ── DUELS SPEED ─────────────────────────────────────────────
local function startDuelsSpeed()
    Connections.DuelsSpeed=RunService.Heartbeat:Connect(function()
        if not State.DuelsSpeed then return end
        local c=lp.Character; if not c then return end
        local h=c:FindFirstChild("HumanoidRootPart"); if not h then return end
        local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local mv=hum.MoveDirection
        if mv.Magnitude>0.1 then
            local d=Vector3.new(mv.X,0,mv.Z).Unit
            h.AssemblyLinearVelocity=Vector3.new(d.X*CFG.DuelsSpeed,h.AssemblyLinearVelocity.Y,d.Z*CFG.DuelsSpeed)
        else
            h.AssemblyLinearVelocity=Vector3.new(0,h.AssemblyLinearVelocity.Y,0)
        end
    end)
end
local function stopDuelsSpeed()
    cleanup("DuelsSpeed")
    pcall(function()
        local h=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if h then h.AssemblyLinearVelocity=Vector3.new(0,h.AssemblyLinearVelocity.Y,0) end
    end)
end

-- ── SPEED BOOSTER ───────────────────────────────────────────
local function startSpeedBooster()
    Connections.SpeedBooster=RunService.Heartbeat:Connect(function()
        if not State.SpeedBooster then return end
        local c=lp.Character; if not c then return end
        local h=c:FindFirstChild("HumanoidRootPart"); if not h then return end
        local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local mv=hum.MoveDirection
        if mv.Magnitude>0.1 then
            local d=Vector3.new(mv.X,0,mv.Z).Unit
            h.AssemblyLinearVelocity=Vector3.new(d.X*CFG.SpeedBooster,h.AssemblyLinearVelocity.Y,d.Z*CFG.SpeedBooster)
        else
            h.AssemblyLinearVelocity=Vector3.new(0,h.AssemblyLinearVelocity.Y,0)
        end
    end)
end
local function stopSpeedBooster()
    cleanup("SpeedBooster")
    pcall(function()
        local h=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if h then h.AssemblyLinearVelocity=Vector3.new(0,h.AssemblyLinearVelocity.Y,0) end
    end)
end

-- ── AUTO SPIN ───────────────────────────────────────────────
local spinAlign,spinAttach,spinAngle=nil,nil,0
local function startAutoSpin()
    local c=getChar(); local h=c:WaitForChild("HumanoidRootPart")
    spinAttach=Instance.new("Attachment",h)
    spinAlign=Instance.new("AlignOrientation",h)
    spinAlign.Attachment0=spinAttach
    spinAlign.Mode=Enum.OrientationAlignmentMode.OneAttachment
    spinAlign.Responsiveness=30; spinAlign.MaxTorque=math.huge
    spinAlign.RigidityEnabled=false; spinAlign.Enabled=true
    spinAngle=0
    Connections.AutoSpin=RunService.Heartbeat:Connect(function(dt)
        if not State.AutoSpin then return end
        spinAngle+=CFG.SpinSpeed*dt
        if spinAlign then spinAlign.CFrame=CFrame.Angles(0,spinAngle,0) end
    end)
end
local function stopAutoSpin()
    cleanup("AutoSpin")
    if spinAlign  then spinAlign:Destroy()  spinAlign=nil end
    if spinAttach then spinAttach:Destroy() spinAttach=nil end
end

-- ── FLOAT ───────────────────────────────────────────────────
local floatConn=nil
local function startFloat()
    local c=getChar(); local h=c:WaitForChild("HumanoidRootPart")
    local targetY=h.Position.Y+CFG.FloatHeight
    local t0=tick(); local desc=false
    floatConn=RunService.Heartbeat:Connect(function()
        if not State.Float then return end
        local ch=lp.Character; if not ch then return end
        local hrp=ch:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local hum=ch:FindFirstChildOfClass("Humanoid")
        local mv=hum and hum.MoveDirection or Vector3.zero
        if tick()-t0>=4 then desc=true end
        local diff=targetY-hrp.Position.Y
        local vy
        if desc then
            vy=-20
            if hrp.Position.Y<=targetY-CFG.FloatHeight+0.5 then
                hrp.AssemblyLinearVelocity=Vector3.zero
                State.Float=false
                if floatConn then floatConn:Disconnect() floatConn=nil end
                return
            end
        else
            vy = diff>0.3 and math.clamp(diff*8,5,50) or diff<-0.3 and math.clamp(diff*8,-50,-5) or 0
        end
        hrp.AssemblyLinearVelocity=Vector3.new(
            mv.Magnitude>0.1 and mv.X*30 or 0, vy,
            mv.Magnitude>0.1 and mv.Z*30 or 0)
    end)
end
local function stopFloat()
    if floatConn then floatConn:Disconnect() floatConn=nil end
    pcall(function()
        local h=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if h then h.AssemblyLinearVelocity=Vector3.zero end
    end)
end

-- ── HELICOPTER ──────────────────────────────────────────────
local function startHelicopter()
    Connections.Helicopter=RunService.Heartbeat:Connect(function()
        if not State.Helicopter then return end
        local c=lp.Character; if not c then return end
        local h=c:FindFirstChild("HumanoidRootPart"); if not h then return end
        local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then return end
        hum.PlatformStand=true
        local mv=hum.MoveDirection
        local vx=mv.Magnitude>0.1 and mv.X*CFG.HelicopterSpeed or 0
        local vz=mv.Magnitude>0.1 and mv.Z*CFG.HelicopterSpeed or 0
        local vy=UserInputService:IsKeyDown(Enum.KeyCode.Space)      and  25 or
                  UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)  and -25 or 0
        h.AssemblyLinearVelocity=Vector3.new(vx,vy,vz)
    end)
end
local function stopHelicopter()
    cleanup("Helicopter")
    pcall(function()
        if lp.Character then
            local h=lp.Character:FindFirstChild("HumanoidRootPart")
            local hum=lp.Character:FindFirstChildOfClass("Humanoid")
            if h   then h.AssemblyLinearVelocity=Vector3.zero end
            if hum then hum.PlatformStand=false end
        end
    end)
end

-- ── DUEL PATHS ──────────────────────────────────────────────
local redSpots = {
    CFrame.new(-475.51,-5.85,25.98)*CFrame.Angles(0,math.rad(15.95),0),
    CFrame.new(-488.59,-3.39,24.23)*CFrame.Angles(0,math.rad(81.05),0),
    CFrame.new(-474.57,-5.85,26.02)*CFrame.Angles(0,math.rad(-85.51),0),
    CFrame.new(-473.54,-5.39,112.07)*CFrame.Angles(0,math.rad(-178.57),0),
}
local blueSpots = {
    CFrame.new(-474.76,-5.85,92.83)*CFrame.Angles(0,math.rad(164.72),0),
    CFrame.new(-486.61,-3.39,93.54)*CFrame.Angles(0,math.rad(89.19),0),
    CFrame.new(-473.64,-5.85,93.82)*CFrame.Angles(0,math.rad(-36.21),0),
    CFrame.new(-473.25,-5.85,17.89)*CFrame.Angles(0,math.rad(-0.38),0),
}
local duelConn=nil

local function stopDuel()
    if duelConn then duelConn:Disconnect() duelConn=nil end
    State.RedDuel=false; State.BlueDuel=false
    pcall(function()
        local h=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if h then h.AssemblyLinearVelocity=Vector3.zero end
    end)
end

local function startDuel(spots, colorKey)
    stopDuel()
    State[colorKey]=true
    local idx=1
    duelConn=RunService.Heartbeat:Connect(function()
        if not State[colorKey] then duelConn:Disconnect() duelConn=nil return end
        local c=lp.Character; if not c then return end
        local h=c:FindFirstChild("HumanoidRootPart"); if not h then return end
        if idx>#spots then stopDuel() return end
        local tgt=spots[idx]
        local dist=(tgt.Position-h.Position).Magnitude
        if dist<=3 then
            h.CFrame=tgt; h.AssemblyLinearVelocity=Vector3.zero; idx+=1
        else
            h.AssemblyLinearVelocity=(tgt.Position-h.Position).Unit*(idx>=3 and 30 or 60)
        end
    end)
end

-- ── SAFE FOLLOW ─────────────────────────────────────────────
local function startSafeFollow()
    Connections.SafeFollow=RunService.Heartbeat:Connect(function()
        if not State.SafeFollow then return end
        local c=lp.Character; if not c then return end
        local h=c:FindFirstChild("HumanoidRootPart"); if not h then return end
        local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local tgt=getNearestEnemy(); if not tgt then return end
        local th=tgt:FindFirstChild("HumanoidRootPart"); if not th then return end
        local dir=Vector3.new(th.Position.X-h.Position.X,0,th.Position.Z-h.Position.Z)
        if dir.Magnitude>4 then hum:MoveTo(h.Position+dir.Unit*math.min(dir.Magnitude,6)) end
    end)
end
local function stopSafeFollow() cleanup("SafeFollow") end

-- ── UNWALK ──────────────────────────────────────────────────
local savedAnim=nil
local function startUnwalk()
    local c=lp.Character; if not c then return end
    local hum=c:FindFirstChildOfClass("Humanoid")
    if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
    local a=c:FindFirstChild("Animate")
    if a then savedAnim=a:Clone() a:Destroy() end
end
local function stopUnwalk()
    local c=lp.Character
    if c and savedAnim then savedAnim:Clone().Parent=c savedAnim=nil end
end

-- ── ANTI RAGDOLL ────────────────────────────────────────────
local arConn=nil
local function startAntiRagdoll()
    arConn=lp.CharacterAdded:Connect(function(c)
        local hum=c:WaitForChild("Humanoid",5)
        if hum then hum.AutoRotate=true end
    end)
    pcall(function()
        for _,obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") and obj.Name:lower():find("ragdoll") then
                obj.OnClientEvent:Connect(function() return end)
            end
        end
    end)
end
local function stopAntiRagdoll()
    if arConn then arConn:Disconnect() arConn=nil end
end

-- ============================================================
-- POPULATE PAGES
-- ============================================================

-- COMBAT
AddButton("Combat","Bat Aimbot",     function(v) State.BatAimbot=v    if v then startBatAimbot()   else stopBatAimbot()   end end)
AddButton("Combat","Hit Circle",     function(v) State.HitCircle=v    if v then startHitCircle()   else stopHitCircle()   end end)
AddButton("Combat","Auto Bat",       function(v) State.AutoBat=v      if v then startAutoBat()     else stopAutoBat()     end end)
AddButton("Combat","Fly Defender",   function(v) State.FlyDefender=v  if v then startFlyDefender() else stopFlyDefender() end end)
AddButton("Combat","Spam Bat",       function(v) State.SpamBat=v      if v then startSpamBat()     else stopSpamBat()     end end)
AddButton("Combat","Anti-Ragdoll",   function(v) State.AntiRagdoll=v  if v then startAntiRagdoll() else stopAntiRagdoll() end end)

-- SPEED
AddButton("Speed","Duels Speed",    function(v) State.DuelsSpeed=v   if v then startDuelsSpeed()   else stopDuelsSpeed()   end end)
AddButton("Speed","Speed Booster",  function(v) State.SpeedBooster=v if v then startSpeedBooster() else stopSpeedBooster() end end)
AddButton("Speed","Auto Spin",      function(v) State.AutoSpin=v     if v then startAutoSpin()     else stopAutoSpin()     end end)
AddButton("Speed","Float",          function(v) State.Float=v        if v then startFloat()        else stopFloat()        end end)
AddButton("Speed","Helicopter",     function(v) State.Helicopter=v   if v then startHelicopter()   else stopHelicopter()   end end)

-- DUEL
AddButton("Duel","Red Duel",     function(v) if v then startDuel(redSpots,  "RedDuel")  else stopDuel() end end)
AddButton("Duel","Blue Duel",    function(v) if v then startDuel(blueSpots, "BlueDuel") else stopDuel() end end)
AddButton("Duel","Safe Follow",  function(v) State.SafeFollow=v if v then startSafeFollow() else stopSafeFollow() end end)
AddButton("Duel","Unwalk",       function(v) State.Unwalk=v     if v then startUnwalk()     else stopUnwalk()     end end)

-- CONFIG
AddConfig("Config","Duels Speed",       "DuelsSpeed",      5,   5, 200)
AddConfig("Config","Speed Booster",     "SpeedBooster",    5,   5, 200)
AddConfig("Config","Fly Speed",         "FlySpeed",        5,   5, 200)
AddConfig("Config","Aimbot Speed",      "AimbotSpeed",     5,   5, 200)
AddConfig("Config","Helicopter Speed",  "HelicopterSpeed", 5,   5, 200)
AddConfig("Config","Spin Speed",        "SpinSpeed",       5,   1, 200)
AddConfig("Config","Float Height",      "FloatHeight",     2,   2,  80)
AddConfig("Config","Bat Delay (ms)",    "BatDelay",        0.05,0.05, 1)
AddConfig("Config","Spam Delay (ms)",   "SpamDelay",       0.02,0.02, 1)

-- ============================================================
-- SPEED HUD
-- ============================================================
local HUD = make("Frame", {
    Size            = UDim2.new(0, 170, 0, 20),
    Position        = UDim2.new(1,-180, 0, 8),
    BackgroundColor3= C.HUD,
    BackgroundTransparency=0.25,
    Parent          = Root,
})
make("UICorner", {CornerRadius=UDim.new(0,6), Parent=HUD})
make("UIStroke", {Color=C.Border, Thickness=1, Transparency=0.5, Parent=HUD})

local hudList = make("UIListLayout", {
    HorizontalAlignment=Enum.HorizontalAlignment.Left,
    Padding=UDim.new(0,1),
    Parent=HUD,
})
make("UIPadding",{PaddingLeft=UDim.new(0,5),PaddingTop=UDim.new(0,2),Parent=HUD})

-- header row
local hudTitle = make("TextLabel", {
    Size=UDim2.new(1,-10,0,14),
    BackgroundTransparency=1,
    Text="SPEED MONITOR",
    TextColor3=C.Sub,
    Font=Enum.Font.GothamBold,
    TextSize=9,
    TextXAlignment=Enum.TextXAlignment.Left,
    Parent=HUD,
})

-- rows cache  [playerName] = TextLabel
local speedRows = {}

local function getOrCreateRow(name)
    if speedRows[name] then return speedRows[name] end
    local lbl = make("TextLabel", {
        Size=UDim2.new(1,-10,0,13),
        BackgroundTransparency=1,
        Text="",
        TextColor3=C.HUDText,
        Font=Enum.Font.GothamBold,
        TextSize=10,
        TextXAlignment=Enum.TextXAlignment.Left,
        Parent=HUD,
    })
    speedRows[name] = lbl
    return lbl
end

local hudUpdateTimer = 0
RunService.Heartbeat:Connect(function(dt)
    hudUpdateTimer += dt
    if hudUpdateTimer < 0.1 then return end
    hudUpdateTimer = 0

    -- resize HUD dynamically
    local rows = 1 -- title
    local allPlayers = Players:GetPlayers()

    -- local player
    local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    local mySpd = myHRP and getHRPSpeed(myHRP) or 0
    local myRow = getOrCreateRow("__ME__")
    myRow.Text  = "YOU  " .. string.format("%.1f", mySpd)
    myRow.TextColor3 = mySpd > 30 and C.HUDHigh or C.HUDText
    rows += 1

    -- others
    local seen = {}
    for _, p in ipairs(allPlayers) do
        if p ~= lp then
            local name = p.Name
            seen[name] = true
            local pHRP = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            local pSpd = pHRP and getHRPSpeed(pHRP) or 0
            local row  = getOrCreateRow(name)
            local short = #name > 10 and name:sub(1,10)..".." or name
            row.Text = short .. "  " .. string.format("%.1f", pSpd)
            row.TextColor3 = pSpd > 30 and Color3.fromRGB(220,160,100) or C.Sub
            rows += 1
        end
    end

    -- remove stale rows
    for name, lbl in pairs(speedRows) do
        if name ~= "__ME__" and not seen[name] then
            lbl:Destroy()
            speedRows[name] = nil
        end
    end

    HUD.Size = UDim2.new(0, 170, 0, 6 + rows * 14)
end)

-- ============================================================
-- DRAGGING
-- ============================================================
do
    local drag,dInput,dStart,dPos
    Head.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; dStart=i.Position; dPos=Win.Position
            i.Changed:Connect(function()
                if i.UserInputState==Enum.UserInputState.End then drag=false end
            end)
        end
    end)
    Head.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch then dInput=i end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i==dInput and drag then
            local d=i.Position-dStart
            Win.Position=UDim2.new(dPos.X.Scale,dPos.X.Offset+d.X,
                                    dPos.Y.Scale,dPos.Y.Offset+d.Y)
        end
    end)
end

-- ============================================================
-- TOGGLE ICON
-- ============================================================
IconBtn.MouseButton1Click:Connect(function()
    Win.Visible = not Win.Visible
end)

-- ============================================================
-- RESPAWN
-- ============================================================
lp.CharacterAdded:Connect(function()
    task.wait(1)
    if State.BatAimbot   then startBatAimbot()   end
    if State.HitCircle   then startHitCircle()   end
    if State.AutoBat     then startAutoBat()      end
    if State.FlyDefender then startFlyDefender()  end
    if State.SpamBat     then startSpamBat()      end
    if State.DuelsSpeed  then startDuelsSpeed()   end
    if State.SpeedBooster then startSpeedBooster() end
    if State.AutoSpin    then startAutoSpin()     end
    if State.Helicopter  then startHelicopter()   end
    if State.SafeFollow  then startSafeFollow()   end
end)

-- ============================================================
print("[WS Hub v2] Carregado! Clique em WS para abrir.")
print("[WS Hub v2] 15 funcoes | Config live | Speed HUD")
