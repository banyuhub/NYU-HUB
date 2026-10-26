--[[
    ========================================================================
    NYU HUB - Standalone Distribution Bundle
    Generated: 2026-10-26T06:42:01.962Z
    Modules: 23 registered
    Architecture: Custom NYU UI Foundation (No third-party UI library)
    ========================================================================
--]]

-- Single Execution Guard
if _G.__NYU_HUB_LOADED then
    warn("[NYU HUB] Already loaded. Reopen via settings or toggle if needed.")
    return
end
_G.__NYU_HUB_LOADED = true

-- Virtual Module Registry & Custom Require
local __modules = {}
local __cache = {}
local __loading = {}

local function __custom_require(name)
    if not name or typeof(name) ~= "string" then
        error("[NYU HUB] require expects a module path string, got " .. typeof(name))
    end

    -- Normalize path separators and remove extension
    local normalized = name:gsub("\\", "/"):gsub("^%./", ""):gsub("%.lua$", "")

    -- Fast cache hit
    if __cache[normalized] ~= nil then
        return __cache[normalized]
    end

    -- Circular dependency detection
    if __loading[normalized] then
        error("[NYU HUB BUNDLER] Circular dependency detected: " .. normalized)
    end

    -- Registry resolution
    local factory = __modules[normalized]
    if not factory then
        error("[NYU HUB BUNDLER] Module not found in bundle: '" .. normalized .. "' (requested as '" .. name .. "')")
    end

    __loading[normalized] = true
    local success, result = pcall(factory, __custom_require)
    __loading[normalized] = nil

    if not success then
        error("[NYU HUB BUNDLER] Error executing module '" .. normalized .. "': " .. tostring(result))
    end

    __cache[normalized] = result
    return result
end

-- ========================================================================
-- MODULE REGISTRY
-- ========================================================================

-- [[[ MODULE: Config ]]]
__modules["Config"] = function(require)

local Config = {
    Name = "NYU HUB",
    Version = "1.0.0",
    Subtitle = "By banyuwkwk",

    Tabs = {
        Home = "Home",
        Utilities = "Utilities",
        Settings = "Settings",
    },

    WalkSpeed = {
        Minimum = 16,
        Maximum = 100,
        Increment = 1,
        Default = 16,
    },
}

return Config
end

-- [[[ MODULE: Core/Character ]]]
__modules["Core/Character"] = function(require)
    --[[
        NYU HUB - Core Character Utilities
        Handles character existence and root part verification.
    ]]

    local Services = nil

    local Character = {}

    function Character.init(services)
        Services = services
    end

    function Character.WaitForCharacterReady(timeout, shouldCancelCheck)
        timeout = timeout or 6
        local start = tick()
        local localPlayer = Services and Services.LocalPlayer or game:GetService("Players").LocalPlayer

        while tick() - start < timeout do
            if shouldCancelCheck and shouldCancelCheck() then
                return nil, nil, nil
            end

            local char = localPlayer and localPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                if hum and root and hum.Health > 0 then
                    return char, root, hum
                end
            end
            task.wait(0.2)
        end
        return nil, nil, nil
    end

    function Character.GetRootPart(shouldCancelCheck)
        local char, root = Character.WaitForCharacterReady(3, shouldCancelCheck)
        return root
    end

    return Character
end

-- [[[ MODULE: Core/Logger ]]]
__modules["Core/Logger"] = function(require)
    --[[
        NYU HUB - Core Logger & Status Manager
        Coordinates status updates, UI text/divider display, and notifications.
    ]]

    local Logger = {
        CurrentFarmState = "IDLE",
        StatusComponent = nil,
        Window = nil,
        Config = nil,
    }

    function Logger.init(config, window, statusComponent)
        Logger.Config = config
        Logger.Window = window
        Logger.StatusComponent = statusComponent
    end

    function Logger.SetStatusComponent(component)
        Logger.StatusComponent = component
    end

    function Logger.SetWindow(window)
        Logger.Window = window
    end

    function Logger.UpdateStatus(state, detail, target)
        Logger.CurrentFarmState = state
        local targetText = target or "-"
        local detailText = detail or ""
        local summary = string.format("[%s] %s | Target: %s", state, detailText, targetText)

        if Logger.StatusComponent then
            pcall(function()
                if Logger.StatusComponent.SetTitle and Logger.StatusComponent.Set then
                    Logger.StatusComponent:SetTitle("Status: " .. state)
                    Logger.StatusComponent:Set(string.format("Target: %s | Detail: %s", targetText, detailText))
                elseif Logger.StatusComponent.Set then
                    Logger.StatusComponent:Set(summary)
                end
            end)
        end
        print(string.format("[NYU HUB] [%s] %s (Target: %s)", state, detailText, targetText))
    end

    function Logger.Notify(title, content)
        if Logger.Window then
            pcall(function()
                Logger.Window:Notify({
                    title = title or (Logger.Config and Logger.Config.Name or "NYU HUB"),
                    content = content,
                })
            end)
        end
    end

    return Logger
end

-- [[[ MODULE: Core/Network ]]]
__modules["Core/Network"] = function(require)
    --[[
        NYU HUB - Core Network Utilities
        Wraps Red Network interaction and quest completion dispatch.
    ]]

    local Services = nil

    local Network = {}

    function Network.init(services)
        Services = services
    end

    function Network.GetRedNetwork()
        local replicatedStorage = Services and Services.ReplicatedStorage or game:GetService("ReplicatedStorage")
        local dependencies = replicatedStorage:FindFirstChild("Dependencies")
        if dependencies then
            local redModule = dependencies:FindFirstChild("Red")
            if redModule then
                local ok, Red = pcall(require, redModule)
                if ok and Red and Red.Client then
                    local netOk, net = pcall(function()
                        return Red.Client("Network")
                    end)
                    if netOk and net then
                        return net
                    end
                end
            end
        end
        return nil
    end

    function Network.TryCompleteDelivery(targetNPCName)
        local net = Network.GetRedNetwork()
        if net then
            local success, err = pcall(function()
                net:Fire("CompleteDeliveryQuest", targetNPCName)
            end)
            if success then
                print("[NYU HUB] Mengirim CompleteDeliveryQuest untuk:", targetNPCName)
                return true
            else
                warn("[NYU HUB] Error saat memanggil CompleteDeliveryQuest:", err)
            end
        else
            warn("[NYU HUB] Red Network tidak ditemukan di ReplicatedStorage.")
        end
        return false
    end

    return Network
end

-- [[[ MODULE: Core/Services ]]]
__modules["Core/Services"] = function(require)
    --[[
        NYU HUB - Core Services
        Provides shared Roblox engine service references.
    ]]

    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer

    local Services = {
        Players = Players,
        Workspace = Workspace,
        VirtualInputManager = VirtualInputManager,
        ReplicatedStorage = ReplicatedStorage,
        LocalPlayer = LocalPlayer,
    }

    return Services
end

-- [[[ MODULE: Core/Teleport ]]]
__modules["Core/Teleport"] = function(require)
    --[[
        NYU HUB - Core Teleport & Arrival Verification
        Preserves exact velocity damping, re-pivot, and arrival stability logic.
    ]]

    local Character = nil

    local Teleport = {}

    function Teleport.init(characterModule)
        Character = characterModule
    end

    function Teleport.TeleportTo(targetPos, shouldCancelCheck)
        local char, root, hum = Character.WaitForCharacterReady(5, shouldCancelCheck)
        if not char or not root or not hum or hum.Health <= 0 then
            warn("[NYU HUB TELEPORT] Karakter tidak tersedia atau sedang respawn.")
            return false, "CharacterNotReady"
        end

        local targetV3 = typeof(targetPos) == "CFrame" and targetPos.Position or targetPos
        local targetCF = typeof(targetPos) == "CFrame" and targetPos or CFrame.new(targetPos)
        local initDist = (root.Position - targetV3).Magnitude

        print(string.format("[NYU HUB TELEPORT] Memulai navigasi ke target (%.1f, %.1f, %.1f) | Jarak awal: %.2f studs",
            targetV3.X, targetV3.Y, targetV3.Z, initDist))

        -- Nolkan kecepatan physics sebelum pivot agar karakter tidak meluncur
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)

        char:PivotTo(targetCF)
        return true, targetV3
    end

    function Teleport.VerifyArrival(targetPos, maxWaitSeconds, toleranceStuds, shouldCancelCheck)
        maxWaitSeconds = maxWaitSeconds or 6
        toleranceStuds = toleranceStuds or 8

        local targetV3 = typeof(targetPos) == "CFrame" and targetPos.Position or targetPos
        local targetCF = typeof(targetPos) == "CFrame" and targetPos or CFrame.new(targetPos)

        local elapsed = 0
        local consecutiveStable = 0
        local requiredStable = 3
        local lastDist = 999

        while elapsed < maxWaitSeconds do
            if shouldCancelCheck and shouldCancelCheck() then
                break
            end

            task.wait(0.2)
            elapsed = elapsed + 0.2

            local char, root, hum = Character.WaitForCharacterReady(1, shouldCancelCheck)
            if char and root and hum and hum.Health > 0 then
                local dist = (root.Position - targetV3).Magnitude
                local vel = root.AssemblyLinearVelocity.Magnitude
                lastDist = dist

                print(string.format("[NYU HUB TELEPORT] Verifikasi kedatangan: Jarak = %.2f studs (toleransi %.1f), Kecepatan = %.2f studs/s [Stabil: %d/%d]",
                    dist, toleranceStuds, vel, consecutiveStable, requiredStable))

                -- Syarat kedatangan: jarak dalam batas toleransi dan kecepatan fisik berhenti/sangat rendah
                if dist <= toleranceStuds and vel < 3.0 then
                    consecutiveStable = consecutiveStable + 1
                    if consecutiveStable >= requiredStable then
                        pcall(function()
                            root.AssemblyLinearVelocity = Vector3.zero
                            root.AssemblyAngularVelocity = Vector3.zero
                        end)
                        print(string.format("[NYU HUB TELEPORT] KEDATANGAN TERVERIFIKASI: Posisi stabil pada jarak %.2f studs dari target (%d checks stabil).", dist, consecutiveStable))
                        return true, "Arrived", dist
                    end
                else
                    consecutiveStable = 0
                    -- Re-pivot jika terjadi rubberband setelah jeda awal
                    if elapsed > 1.2 and dist > toleranceStuds then
                        pcall(function()
                            root.AssemblyLinearVelocity = Vector3.zero
                        end)
                        char:PivotTo(targetCF)
                    end
                end
            else
                warn("[NYU HUB TELEPORT] Karakter tidak valid selama verifikasi posisi.")
                consecutiveStable = 0
            end
        end

        warn(string.format("[NYU HUB TELEPORT] Timeout verifikasi kedatangan dalam %.1fs (Jarak akhir: %.1f studs, toleransi: %.1f).", maxWaitSeconds, lastDist, toleranceStuds))
        return false, "Timeout", lastDist
    end

    function Teleport.TeleportAndVerifyArrival(targetPos, maxWaitSeconds, toleranceStuds, shouldCancelCheck)
        local ok, reason = Teleport.TeleportTo(targetPos, shouldCancelCheck)
        if not ok then
            return false, reason, 999
        end
        return Teleport.VerifyArrival(targetPos, maxWaitSeconds, toleranceStuds, shouldCancelCheck)
    end

    return Teleport     
end

-- [[[ MODULE: Features/AutoFarmTofu/Dialogue ]]]
__modules["Features/AutoFarmTofu/Dialogue"] = function(require)
    --[[
        NYU HUB - Auto Farm Tofu Dialogue Inspector & Skip Logic
        Preserves exact GUI visibility verification, conversation signatures, and auto-advance logic.
    ]]

    local Dialogue = {}

    -- Kalimat signature percakapan spesifik Bunta (tidak menggunakan kata tunggal umum)
    Dialogue.BUNTA_CONVERSATION_SIGNATURES = {
        "do you have a job for me",
        "what do you got for sale",
        "sure, i'll take it",
        "actually nevermind",
        "welcome to fujiwara tofu shop",
        "are you sure you want to",
        "good to know, now go out there",
        "break the tofu",
    }

    -- Memeriksa apakah elemen GUI benar-benar terlihat di layar (bukan frame tersembunyi/dormant)
    function Dialogue.IsGuiObjectTrulyVisible(guiObj)
        if not guiObj or not guiObj:IsA("GuiObject") then return false end
        if not guiObj.Visible then return false end
        if guiObj.AbsoluteSize.X <= 10 or guiObj.AbsoluteSize.Y <= 10 then return false end

        -- Cek TextTransparency untuk elemen teks
        if guiObj:IsA("TextLabel") or guiObj:IsA("TextButton") then
            if guiObj.TextTransparency >= 0.9 then return false end
            if #guiObj.Text == 0 then return false end
        end

        -- Cek CanvasGroup GroupTransparency jika elemen sendiri adalah CanvasGroup
        if guiObj:IsA("CanvasGroup") and guiObj.GroupTransparency >= 0.9 then
            return false
        end

        -- Cek posisi di layar (viewport) agar frame yang di-tween ke luar layar tidak terdeteksi aktif
        local camera = workspace.CurrentCamera
        if camera then
            local vpSize = camera.ViewportSize
            local pos = guiObj.AbsolutePosition
            local size = guiObj.AbsoluteSize
            if pos.X + size.X <= 0 or pos.Y + size.Y <= 0 or pos.X >= vpSize.X or pos.Y >= vpSize.Y then
                return false
            end
        end

        -- Periksa seluruh ancestor hingga ScreenGui
        local current = guiObj.Parent
        while current and not current:IsA("ScreenGui") and not current:IsA("Workspace") do
            if current:IsA("GuiObject") then
                if not current.Visible then return false end
                if current.AbsoluteSize.X <= 0 or current.AbsoluteSize.Y <= 0 then return false end
                if current:IsA("CanvasGroup") and current.GroupTransparency >= 0.9 then return false end
            end
            current = current.Parent
        end

        if current and current:IsA("ScreenGui") then
            return current.Enabled
        end

        return true
    end

    -- Cek apakah sebuah tombol adalah pilihan penting yang TIDAK boleh di-skip
    function Dialogue.IsImportantDialogChoice(btnText)
        if not btnText then return false end
        local lower = btnText:lower()
        return lower:find("job for me", 1, true)
            or lower:find("for sale", 1, true)
            or lower:find("take it", 1, true)
            or lower:find("nevermind", 1, true)
    end

    -- Mencari container ScreenGui/Frame spesifik dialog Fujiwara Bunta
    function Dialogue.FindBuntaDialogueContainer(localPlayer)
        localPlayer = localPlayer or game:GetService("Players").LocalPlayer
        local playerGui = localPlayer and localPlayer:FindFirstChildOfClass("PlayerGui")
        if not playerGui then return nil, nil end

        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled then
                local gName = gui.Name:lower()
                -- Abaikan GUI Rayfield dan NYU HUB
                if not gName:find("rayfield") and not gName:find("nyu") then
                    for _, desc in ipairs(gui:GetDescendants()) do
                        if (desc:IsA("TextLabel") or desc:IsA("TextButton")) and Dialogue.IsGuiObjectTrulyVisible(desc) then
                            local text = desc.Text:lower()
                            for _, sig in ipairs(Dialogue.BUNTA_CONVERSATION_SIGNATURES) do
                                if text:find(sig, 1, true) then
                                    -- Container ditemukan! Cari Frame pembungkus teratas di bawah ScreenGui
                                    local topFrame = desc
                                    while topFrame.Parent and topFrame.Parent ~= gui and topFrame.Parent:IsA("GuiObject") do
                                        topFrame = topFrame.Parent
                                    end
                                    return topFrame, gui
                                end
                            end
                        end
                    end
                end
            end
        end

        return nil, nil
    end

    -- Inspeksi state dialog Bunta secara akurat dan terisolasi
    function Dialogue.InspectBuntaDialogue(localPlayer)
        local container, screenGui = Dialogue.FindBuntaDialogueContainer(localPlayer)
        if not container then
            return {
                isOpen = false,
                container = nil,
                gui = nil,
                narration = "",
                buttons = {},
                optionJob = nil,
                optionSale = nil,
                optionTakeIt = nil,
                optionNevermind = nil,
                advanceBtn = nil,
                isJobAcceptedNarration = false,
            }
        end

        local narrationList = {}
        local buttons = {}
        local optJob = nil
        local optSale = nil
        local optTakeIt = nil
        local optNevermind = nil
        local advanceBtn = nil

        for _, desc in ipairs(container:GetDescendants()) do
            if desc:IsA("TextLabel") and Dialogue.IsGuiObjectTrulyVisible(desc) and #desc.Text > 0 then
                local clean = desc.Text:gsub("%s+", " "):match("^%s*(.-)%s*$")
                if clean and #clean > 0 then
                    table.insert(narrationList, clean)
                end
            elseif desc:IsA("GuiButton") and Dialogue.IsGuiObjectTrulyVisible(desc) then
                local btnText = ""
                if desc:IsA("TextButton") and #desc.Text > 0 then
                    btnText = desc.Text
                else
                    for _, sub in ipairs(desc:GetDescendants()) do
                        if sub:IsA("TextLabel") and Dialogue.IsGuiObjectTrulyVisible(sub) and #sub.Text > 0 then
                            btnText = sub.Text
                            break
                        end
                    end
                end
                local clean = btnText:gsub("%s+", " "):match("^%s*(.-)%s*$") or ""
                local lower = clean:lower()
                local lowerName = desc.Name:lower()

                local btnInfo = {
                    instance = desc,
                    name = desc.Name,
                    text = clean,
                }
                table.insert(buttons, btnInfo)

                -- Klasifikasi tombol secara eksplisit
                if lower:find("job for me", 1, true) then
                    optJob = btnInfo
                elseif lower:find("for sale", 1, true) then
                    optSale = btnInfo
                elseif lower:find("take it", 1, true) then
                    optTakeIt = btnInfo
                elseif lower:find("nevermind", 1, true) then
                    optNevermind = btnInfo
                elseif lower:find("skip", 1, true)
                    or lower:find("continue", 1, true)
                    or lower:find("next", 1, true)
                    or lower:find("lanjut", 1, true)
                    or lower:find("lewati", 1, true)
                    or lower:find("ok", 1, true)
                    or lower:find("close", 1, true)
                    or lowerName:find("skip", 1, true)
                    or lowerName:find("continue", 1, true)
                    or lowerName:find("next", 1, true)
                    or lowerName:find("close", 1, true) then
                    advanceBtn = btnInfo
                end
            end
        end

        local fullNarration = table.concat(narrationList, " | ")
        local lowerNarration = fullNarration:lower()

        local isAcceptedNarration = lowerNarration:find("good to know", 1, true)
            or lowerNarration:find("break the tofu", 1, true)

        -- Dialog dianggap terbuka hanya jika ada tombol interaktif atau narasi yang benar-benar aktif di layar
        local genuinelyOpen = (#buttons > 0 or #narrationList > 0) and (
            optJob ~= nil or optTakeIt ~= nil or optSale ~= nil or optNevermind ~= nil or advanceBtn ~= nil or isAcceptedNarration or #narrationList > 0
        )

        return {
            isOpen = genuinelyOpen,
            container = container,
            gui = screenGui,
            narration = fullNarration,
            buttons = buttons,
            optionJob = optJob,
            optionSale = optSale,
            optionTakeIt = optTakeIt,
            optionNevermind = optNevermind,
            advanceBtn = advanceBtn,
            isJobAcceptedNarration = isAcceptedNarration,
        }
    end

    -- Cari elemen clickable generik di dalam dialog container untuk auto-advance
    function Dialogue.FindDialogAdvanceTarget(container)
        if not container then return nil end

        local candidates = {}

        for _, desc in ipairs(container:GetDescendants()) do
            if desc:IsA("GuiButton") and Dialogue.IsGuiObjectTrulyVisible(desc) then
                local btnText = ""
                if desc:IsA("TextButton") and #desc.Text > 0 then
                    btnText = desc.Text
                else
                    for _, sub in ipairs(desc:GetDescendants()) do
                        if sub:IsA("TextLabel") and Dialogue.IsGuiObjectTrulyVisible(sub) and #sub.Text > 0 then
                            btnText = sub.Text
                            break
                        end
                    end
                end

                if not Dialogue.IsImportantDialogChoice(btnText) then
                    local priority = 0
                    local lowerText = btnText:lower()
                    local lowerName = desc.Name:lower()

                    if lowerText:find("skip", 1, true)
                        or lowerText:find("continue", 1, true)
                        or lowerText:find("next", 1, true)
                        or lowerText:find("lanjut", 1, true)
                        or lowerText:find("lewati", 1, true)
                        or lowerText:find("ok", 1, true)
                        or lowerText:find("close", 1, true)
                        or lowerName:find("skip", 1, true)
                        or lowerName:find("continue", 1, true)
                        or lowerName:find("next", 1, true)
                        or lowerName:find("advance", 1, true)
                        or lowerName:find("close", 1, true) then
                        priority = 10
                    elseif #btnText <= 2 then
                        priority = 5
                    elseif desc:IsA("ImageButton") then
                        local size = desc.AbsoluteSize
                        if size.X > 100 and size.Y > 40 then
                            priority = 7
                        else
                            priority = 3
                        end
                    else
                        priority = 2
                    end

                    table.insert(candidates, {instance = desc, text = btnText, priority = priority})
                end
            end
        end

        table.sort(candidates, function(a, b) return a.priority > b.priority end)

        if #candidates > 0 then
            return candidates[1]
        end
        return nil
    end

    -- Auto-skip dialog naratif: tekan elemen advance secara berurutan
    function Dialogue.AutoSkipNarrativeDialog(shouldCancelCheck, clickGuiButtonFn, localPlayer)
        local maxSkipAttempts = 15
        local skipCount = 0

        while skipCount < maxSkipAttempts do
            if shouldCancelCheck and shouldCancelCheck() then
                break
            end

            local dInfo = Dialogue.InspectBuntaDialogue(localPlayer)

            -- Dialog sudah tertutup
            if not dInfo.isOpen then
                print("[NYU HUB DIALOG-SKIP] Dialog sudah tertutup setelah " .. skipCount .. " skip.")
                return true, "DialogClosed"
            end

            -- Pilihan penting muncul - berhenti skip, serahkan ke alur utama
            if dInfo.optionJob or dInfo.optionTakeIt or dInfo.optionSale then
                print("[NYU HUB DIALOG-SKIP] Pilihan penting terdeteksi, menghentikan auto-skip.")
                return true, "ImportantChoiceFound"
            end

            -- Narasi job accepted - berhenti skip, serahkan ke alur utama
            if dInfo.isJobAcceptedNarration then
                print("[NYU HUB DIALOG-SKIP] Narasi job accepted terdeteksi, menghentikan auto-skip.")
                return true, "JobAcceptedNarration"
            end

            -- Cari elemen advance menggunakan finder yang lebih luas
            local advTarget = Dialogue.FindDialogAdvanceTarget(dInfo.container)

            if advTarget then
                print(string.format("[NYU HUB DIALOG-SKIP] Skip #%d: menekan '%s' (Name: %s, Priority: %d)",
                    skipCount + 1, advTarget.text, advTarget.instance.Name, advTarget.priority))
                if clickGuiButtonFn then
                    clickGuiButtonFn(advTarget.instance)
                end
                skipCount = skipCount + 1
                task.wait(0.4)
            else
                -- Tidak ada tombol yang bisa ditekan, coba klik container itu sendiri
                if dInfo.container and dInfo.container:IsA("GuiButton") then
                    print("[NYU HUB DIALOG-SKIP] Skip #" .. (skipCount + 1) .. ": menekan container langsung.")
                    if clickGuiButtonFn then
                        clickGuiButtonFn(dInfo.container)
                    end
                    skipCount = skipCount + 1
                    task.wait(0.4)
                else
                    -- Tidak ada yang bisa diklik, tunggu sebentar dan cek ulang
                    print("[NYU HUB DIALOG-SKIP] Tidak ada elemen advance. Menunggu perubahan dialog...")
                    task.wait(0.6)
                    local dInfo2 = Dialogue.InspectBuntaDialogue(localPlayer)
                    if not dInfo2.isOpen then
                        return true, "DialogClosedAfterWait"
                    end
                    if dInfo2.narration == dInfo.narration and not dInfo2.optionJob and not dInfo2.optionTakeIt then
                        print("[NYU HUB DIALOG-SKIP] Dialog tampak stuck, keluar dari auto-skip.")
                        return false, "Stuck"
                    end
                end
            end
        end

        warn("[NYU HUB DIALOG-SKIP] Mencapai batas maksimum skip (" .. maxSkipAttempts .. ").")
        return false, "MaxSkipReached"
    end

    return Dialogue
end

-- [[[ MODULE: Features/AutoFarmTofu/FarmCycle ]]]
__modules["Features/AutoFarmTofu/FarmCycle"] = function(require)
    --[[
        NYU HUB - Auto Farm Tofu State Machine & Lifecycle
        Preserves exact 8-stage execution cycle, timing, retry parameters, and state transitions.
    ]]

    local Character = nil
    local Teleport = nil
    local Network = nil
    local Logger = nil
    local Dialogue = nil
    local Interaction = nil
    local QuestDetector = nil
    local Config = nil

    local FarmCycle = {
        AutoFarmEnabled = false,
        CurrentFarmState = "IDLE",
        FarmThread = nil,
        LastDeliveredTarget = nil,

        BUNTA_POSITION = Vector3.new(-144.784, -11.521, 665.749),
        BUNTA_NAME = "Fujiwara Bunta",
    }

    function FarmCycle.init(dependencies)
        Character = dependencies.Character
        Teleport = dependencies.Teleport
        Network = dependencies.Network
        Logger = dependencies.Logger
        Dialogue = dependencies.Dialogue
        Interaction = dependencies.Interaction
        QuestDetector = dependencies.QuestDetector
        Config = dependencies.Config
    end

    function FarmCycle.IsEnabled()
        return FarmCycle.AutoFarmEnabled
    end

    function FarmCycle.ShouldCancel()
        return not FarmCycle.AutoFarmEnabled
    end

    function FarmCycle.RunCycle()
        local BUNTA_POSITION = FarmCycle.BUNTA_POSITION
        local BUNTA_NAME = FarmCycle.BUNTA_NAME

        while FarmCycle.AutoFarmEnabled do
            -- ----------------------------------------------------
            -- TAHAP 1: TELEPORT MENUJU FUJIWARA BUNTA
            -- ----------------------------------------------------
            Logger.UpdateStatus("TELEPORT_TO_BUNTA", "Memulai teleport menuju Fujiwara Bunta...")

            -- ----------------------------------------------------
            -- TAHAP 2: VERIFY_ARRIVAL (Verifikasi Jarak & Kestabilan Posisi)
            -- ----------------------------------------------------
            Logger.UpdateStatus("VERIFY_ARRIVAL", "Memverifikasi kedatangan dan kestabilan posisi...")
            local arrived, arriveReason = Teleport.TeleportAndVerifyArrival(BUNTA_POSITION, 6, 8, FarmCycle.ShouldCancel)
            if not arrived then
                warn("[NYU HUB] Kedatangan di lokasi Bunta belum stabil (" .. arriveReason .. "). Mengulang navigasi...")
                task.wait(1.0)
                continue
            end
            if not FarmCycle.AutoFarmEnabled then break end

            -- ----------------------------------------------------
            -- TAHAP 3: PERIKSA JOB AKTIF (Jika sudah ada, lewati interaksi)
            -- BUG2 FIX: Jika activeTarget sama dengan LastDeliveredTarget,
            -- anggap itu data quest lama yang belum bersih - jangan skip interaksi Bunta
            -- ----------------------------------------------------
            local activeTarget = QuestDetector.DetectActiveDeliveryTarget()
            if activeTarget and activeTarget ~= FarmCycle.LastDeliveredTarget then
                print(string.format("[NYU HUB] Job delivery '%s' sudah aktif. Langsung menuju tahap pengiriman.", activeTarget))
            else
                if activeTarget and activeTarget == FarmCycle.LastDeliveredTarget then
                    print(string.format("[NYU HUB] Target '%s' sama dengan delivery terakhir - kemungkinan data quest lama, paksa interaksi Bunta.", activeTarget))
                end
                -- ----------------------------------------------------
                -- TAHAP 4: INTERACT_WITH_NPC & VERIFY_DIALOG_OPEN
                -- ----------------------------------------------------
                local buntaModel = Interaction.FindNPCModel(BUNTA_NAME)
                if not buntaModel then
                    warn("[NYU HUB] Model NPC Bunta belum dimuat di Workspace. Menunggu...")
                    task.wait(1.5)
                    continue
                end

                local dInfo = Dialogue.InspectBuntaDialogue()
                local dialogOpened = dInfo.isOpen

                if not dialogOpened then
                    local interactAttempts = 0
                    local maxInteract = 4

                    while interactAttempts < maxInteract and FarmCycle.AutoFarmEnabled do
                        interactAttempts = interactAttempts + 1
                        Logger.UpdateStatus("INTERACT_WITH_NPC", string.format("Memicu interaksi NPC Bunta (percobaan #%d)...", interactAttempts))

                        local ok, reason = Interaction.TriggerBuntaInteraction(buntaModel, FarmCycle.ShouldCancel)
                        if not ok then
                            warn("[NYU HUB] Gagal memicu interaksi: " .. reason)
                        end

                        -- VERIFY_DIALOG_OPEN: Menunggu dialog benar-benar muncul di layar
                        Logger.UpdateStatus("VERIFY_DIALOG_OPEN", string.format("Menunggu dialog terbuka (percobaan #%d)...", interactAttempts))
                        local waitElapsed = 0
                        while waitElapsed < 2.5 and FarmCycle.AutoFarmEnabled do
                            task.wait(0.3)
                            waitElapsed = waitElapsed + 0.3
                            dInfo = Dialogue.InspectBuntaDialogue()
                            if dInfo.isOpen then
                                dialogOpened = true
                                print(string.format("[NYU HUB] DIALOG TERBUKA TERVERIFIKASI! (Container: '%s', Narasi: '%s')", dInfo.container.Name, dInfo.narration))
                                break
                            end
                        end

                        if dialogOpened then break end
                        warn(string.format("[NYU HUB] Dialog belum terbuka pada percobaan #%d. Jeda sebelum retry...", interactAttempts))
                        task.wait(0.8)
                    end
                else
                    print(string.format("[NYU HUB] Dialog Bunta sudah dalam keadaan terbuka. (Container: '%s')", dInfo.container.Name))
                end

                if not FarmCycle.AutoFarmEnabled then break end

                if not dialogOpened then
                    warn("[NYU HUB] Gagal membuka dialog NPC Bunta setelah 4 percobaan. Mengulang dari navigasi...")
                    task.wait(1.5)
                    continue
                end

                -- ----------------------------------------------------
                -- TAHAP 4.5: AUTO-SKIP DIALOG NARATIF AWAL (BUG1 FIX)
                -- Skip semua narasi sebelum pilihan job muncul
                -- ----------------------------------------------------
                Logger.UpdateStatus("AUTO_SKIP_DIALOG", "Melewati dialog naratif awal...")
                Dialogue.AutoSkipNarrativeDialog(FarmCycle.ShouldCancel, Interaction.ClickGuiButton)
                task.wait(0.3)
                if not FarmCycle.AutoFarmEnabled then break end

                -- ----------------------------------------------------
                -- TAHAP 5: SELECT_DIALOG_OPTION (Tahap 1 & Tahap 2)
                -- ----------------------------------------------------
                dInfo = Dialogue.InspectBuntaDialogue()

                -- Tahap 1: Pilih "Do you have a job for me?" jika tersedia
                if dInfo.optionJob and not dInfo.optionTakeIt and not dInfo.isJobAcceptedNarration then
                    Logger.UpdateStatus("SELECT_OPTION_S1", "Memilih opsi: 'Do you have a job for me?'...")
                    print(string.format("[NYU HUB DIALOG] Menekan tombol opsi Tahap 1: '%s'", dInfo.optionJob.text))
                    Interaction.ClickGuiButton(dInfo.optionJob.instance)
                    task.wait(0.8)

                    -- BUG1 FIX: Auto-skip narasi setelah memilih job
                    Logger.UpdateStatus("AUTO_SKIP_DIALOG", "Melewati dialog setelah memilih job...")
                    Dialogue.AutoSkipNarrativeDialog(FarmCycle.ShouldCancel, Interaction.ClickGuiButton)
                    task.wait(0.3)
                end

                if not FarmCycle.AutoFarmEnabled then break end

                -- Tahap 2: Konfirmasi "Sure, I'll take it."
                dInfo = Dialogue.InspectBuntaDialogue()
                if not dInfo.isJobAcceptedNarration then
                    Logger.UpdateStatus("CONFIRM_JOB_S2", "Menunggu konfirmasi: 'Sure, I\\'ll take it.'...")
                    local s2Timeout = 6
                    local s2Elapsed = 0
                    local confirmed = false

                    while s2Elapsed < s2Timeout and FarmCycle.AutoFarmEnabled do
                        dInfo = Dialogue.InspectBuntaDialogue()
                        if dInfo.isJobAcceptedNarration then
                            confirmed = true
                            break
                        end

                        if dInfo.optionTakeIt then
                            print(string.format("[NYU HUB DIALOG] Menekan tombol opsi Tahap 2: '%s'", dInfo.optionTakeIt.text))
                            Interaction.ClickGuiButton(dInfo.optionTakeIt.instance)
                            confirmed = true
                            task.wait(0.8)
                            break
                        elseif dInfo.advanceBtn then
                            print(string.format("[NYU HUB DIALOG] Menekan tombol lanjutan/skip: '%s'", dInfo.advanceBtn.text))
                            Interaction.ClickGuiButton(dInfo.advanceBtn.instance)
                            task.wait(0.5)
                        end

                        task.wait(0.3)
                        s2Elapsed = s2Elapsed + 0.3
                    end

                    if not FarmCycle.AutoFarmEnabled then break end

                    if not confirmed then
                        warn("[NYU HUB] Konfirmasi job gagal dipilih. Mengulang siklus...")
                        task.wait(1.5)
                        continue
                    end
                end

                -- ----------------------------------------------------
                -- TAHAP 6: VERIFY_JOB (Tutup dialog & pastikan target terdeteksi)
                -- ----------------------------------------------------
                -- BUG1 FIX: Auto-skip narasi setelah konfirmasi job (menutup dialog)
                Logger.UpdateStatus("VERIFY_JOB", "Memverifikasi job aktif & melewati narasi sisa...")
                Dialogue.AutoSkipNarrativeDialog(FarmCycle.ShouldCancel, Interaction.ClickGuiButton)
                task.wait(0.3)
            end

            -- Polling verifikasi data quest aktif
            local detectedTarget = nil
            local detectSource = nil
            local verifyTimeout = 10
            local elapsed = 0

            while elapsed < verifyTimeout and FarmCycle.AutoFarmEnabled do
                detectedTarget, detectSource = QuestDetector.DetectActiveDeliveryTarget()
                if detectedTarget then
                    break
                end
                task.wait(0.5)
                elapsed = elapsed + 0.5
            end

            if not FarmCycle.AutoFarmEnabled then break end

            if not detectedTarget then
                warn("[NYU HUB] Target job belum terverifikasi dari game data. Mengulang siklus...")
                task.wait(2)
                continue
            end

            print(string.format("[NYU HUB] VERIFIKASI JOB BERHASIL: Target = '%s' (via %s)", detectedTarget, detectSource))
            Logger.UpdateStatus("JOB_ACCEPTED", string.format("Target: %s (via %s)", detectedTarget, detectSource), detectedTarget)
            Logger.Notify(Config and Config.Name or "NYU HUB", "Job Aktif: Antar ke " .. detectedTarget)
            task.wait(0.5)
            if not FarmCycle.AutoFarmEnabled then break end

            -- ----------------------------------------------------
            -- TAHAP 7: TELEPORT_TO_RECIPIENT & DELIVER
            -- ----------------------------------------------------
            Logger.UpdateStatus("DELIVER_TO_RECIPIENT", "Navigasi menuju penerima: " .. detectedTarget, detectedTarget)
            local targetModel = Interaction.FindNPCModel(detectedTarget)
            if targetModel then
                local targetPart = targetModel:FindFirstChild("HumanoidRootPart")
                    or targetModel.PrimaryPart
                    or targetModel:FindFirstChildWhichIsA("BasePart")
                if targetPart then
                    Teleport.TeleportAndVerifyArrival(targetPart.Position + Vector3.new(0, 0, 3), 6, 10, FarmCycle.ShouldCancel)
                end
            else
                print(string.format("[NYU HUB] Model target '%s' belum ditemukan di Workspace. Mengirim sinyal network.", detectedTarget))
            end

            task.wait(0.6)
            if not FarmCycle.AutoFarmEnabled then break end

            if targetModel then
                local prompt = targetModel:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and fireproximityprompt then
                    pcall(function() fireproximityprompt(prompt) end)
                end
            end
            Network.TryCompleteDelivery(detectedTarget)

            -- BUG2 FIX: Simpan target terakhir yang dideliver, bersihkan referensi lama
            FarmCycle.LastDeliveredTarget = detectedTarget
            targetModel = nil  -- Bersihkan referensi model NPC penerima

            Logger.UpdateStatus("DELIVERY_COMPLETE", "Paket diserahkan ke " .. detectedTarget, detectedTarget)
            task.wait(1.5)
            if not FarmCycle.AutoFarmEnabled then break end

            -- ----------------------------------------------------
            -- TAHAP 8: RETURN_TO_START & COOLDOWN
            -- ----------------------------------------------------
            Logger.UpdateStatus("RETURN_TO_START", "Kembali ke Fujiwara Bunta untuk job berikutnya...")
            local backArrived, backReason = Teleport.TeleportAndVerifyArrival(BUNTA_POSITION, 6, 8, FarmCycle.ShouldCancel)
            if not backArrived then
                warn("[NYU HUB] Kembali ke Bunta timeout (" .. backReason .. "). Melakukan re-pivot...")
                Teleport.TeleportAndVerifyArrival(BUNTA_POSITION, 4, 10, FarmCycle.ShouldCancel)
            end

            -- BUG2 FIX: Verifikasi bahwa kita berada dekat Bunta sebelum melanjutkan
            Logger.UpdateStatus("VERIFY_RETURN", "Memverifikasi posisi di dekat Fujiwara Bunta...")
            local buntaReturnModel = Interaction.FindNPCModel(BUNTA_NAME)
            if buntaReturnModel then
                local buntaReturnPart = buntaReturnModel:FindFirstChild("HumanoidRootPart")
                    or buntaReturnModel.PrimaryPart
                    or buntaReturnModel:FindFirstChildWhichIsA("BasePart")
                if buntaReturnPart then
                    local returnRoot = Character.GetRootPart(FarmCycle.ShouldCancel)
                    if returnRoot then
                        local distToBunta = (returnRoot.Position - buntaReturnPart.Position).Magnitude
                        if distToBunta > 15 then
                            warn(string.format("[NYU HUB] Masih terlalu jauh dari Bunta (%.1f studs). Re-teleport...", distToBunta))
                            Teleport.TeleportAndVerifyArrival(BUNTA_POSITION, 6, 8, FarmCycle.ShouldCancel)
                        end
                    end
                end
            end

            -- Tunggu hingga data quest lama bersih sebelum siklus berikutnya
            Logger.UpdateStatus("COOLDOWN", "Menunggu quest lama bersih & persiapan siklus baru...")
            local clearTimer = 0
            while clearTimer < 4 and FarmCycle.AutoFarmEnabled do
                local current = QuestDetector.DetectActiveDeliveryTarget()
                if not current or current ~= detectedTarget then
                    break
                end
                task.wait(0.5)
                clearTimer = clearTimer + 0.5
            end

            -- BUG2 FIX: Reset referensi agar siklus baru tidak menggunakan target lama
            print(string.format("[NYU HUB] Siklus selesai. LastDeliveredTarget = '%s'. Memulai siklus baru.", tostring(FarmCycle.LastDeliveredTarget)))

            if not FarmCycle.AutoFarmEnabled then break end
            task.wait(1.0)
        end

        Logger.UpdateStatus("IDLE", "Auto Farm dihentikan.", "-")
    end

    function FarmCycle.SetAutoFarmEnabled(enabled)
        FarmCycle.AutoFarmEnabled = enabled

        if enabled then
            Logger.Notify(Config and Config.Name or "NYU HUB", "Auto Farm Tofu diaktifkan...")
            print("[NYU HUB] Auto Farm Tofu: ON")

            if FarmCycle.FarmThread then
                task.cancel(FarmCycle.FarmThread)
                FarmCycle.FarmThread = nil
            end

            FarmCycle.FarmThread = task.spawn(FarmCycle.RunCycle)
        else
            FarmCycle.AutoFarmEnabled = false
            if FarmCycle.FarmThread then
                task.cancel(FarmCycle.FarmThread)
                FarmCycle.FarmThread = nil
            end
            Logger.UpdateStatus("IDLE", "Auto Farm dimatikan oleh pengguna.", "-")

            Logger.Notify(Config and Config.Name or "NYU HUB", "Auto Farm Tofu dimatikan.")
            print("[NYU HUB] Auto Farm Tofu: OFF")
        end
    end

    return FarmCycle
end

-- [[[ MODULE: Features/AutoFarmTofu/Interaction ]]]
__modules["Features/AutoFarmTofu/Interaction"] = function(require)
    --[[
        NYU HUB - Auto Farm Tofu Interaction Logic
        Handles NPC model resolution, multi-method GUI clicking, and Bunta interaction triggers.
    ]]

    local Services = nil
    local Character = nil

    local Interaction = {}

    function Interaction.init(services, characterModule)
        Services = services
        Character = characterModule
    end

    function Interaction.FindNPCModel(npcName)
        if not npcName or #npcName == 0 then return nil end
        local workspace = Services and Services.Workspace or game:GetService("Workspace")
        local npcFolder = workspace:FindFirstChild("NPCs")
        if npcFolder then
            local direct = npcFolder:FindFirstChild(npcName)
            if direct then return direct end
            for _, child in ipairs(npcFolder:GetChildren()) do
                if child.Name:lower() == npcName:lower() or child.Name:lower():find(npcName:lower(), 1, true) then
                    return child
                end
            end
        end
        local directWs = workspace:FindFirstChild(npcName)
        if directWs then return directWs end
        for _, child in ipairs(workspace:GetChildren()) do
            if child:IsA("Model") and (child.Name:lower() == npcName:lower() or child.Name:lower():find(npcName:lower(), 1, true)) then
                return child
            end
        end
        return nil
    end

    function Interaction.ClickGuiButton(btn)
        if not btn or not btn:IsA("GuiButton") then return false end

        local clicked = false

        -- Metode 1: firesignal
        if firesignal then
            pcall(function()
                firesignal(btn.MouseButton1Click)
                clicked = true
            end)
            pcall(function()
                firesignal(btn.Activated)
                clicked = true
            end)
        end

        -- Metode 2: getconnections
        if getconnections then
            pcall(function()
                for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
                    conn:Fire()
                    clicked = true
                end
                for _, conn in ipairs(getconnections(btn.Activated)) do
                    conn:Fire()
                    clicked = true
                end
            end)
        end

        -- Metode 3: VirtualInputManager (simulasi klik mouse langsung pada koordinat tombol)
        pcall(function()
            local vim = Services and Services.VirtualInputManager or game:GetService("VirtualInputManager")
            local absPos = btn.AbsolutePosition
            local absSize = btn.AbsoluteSize
            local centerX = absPos.X + absSize.X / 2
            local centerY = absPos.Y + absSize.Y / 2
            vim:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
            task.wait(0.05)
            vim:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
            clicked = true
        end)

        return clicked
    end

    function Interaction.TriggerBuntaInteraction(buntaModel, shouldCancelCheck)
        if not buntaModel then return false, "NoModel" end

        local char, root, hum = Character.WaitForCharacterReady(2, shouldCancelCheck)
        if not root then return false, "NoRoot" end

        local buntaPart = buntaModel:FindFirstChild("HumanoidRootPart")
            or buntaModel.PrimaryPart
            or buntaModel:FindFirstChild("Head")
            or buntaModel:FindFirstChildWhichIsA("BasePart")

        if not buntaPart then return false, "NoBuntaPart" end

        -- Pastikan karakter benar-benar dekat (< 20 studs) sebelum interaksi dijalankan
        local dist = (root.Position - buntaPart.Position).Magnitude
        if dist > 20 then
            warn(string.format("[NYU HUB INTERACT] Jarak karakter ke Bunta terlalu jauh (%.1f studs, toleransi 20 studs). Interaksi ditolak.", dist))
            return false, "TooFar"
        end

        print(string.format("[NYU HUB INTERACT] Menjalankan mekanisme interaksi ke '%s' (Jarak aktual: %.2f studs)...", buntaModel.Name, dist))

        local triggeredPrompt = false
        local triggeredClick = false
        local triggeredMouseSim = false
        local triggeredKey = false

        -- 1. ProximityPrompt di dalam model Bunta
        local prompt = buntaModel:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt and fireproximityprompt then
            pcall(function()
                local origHold = prompt.HoldDuration
                local origDist = prompt.MaxActivationDistance
                local origLos = prompt.RequiresLineOfSight
                prompt.HoldDuration = 0
                prompt.MaxActivationDistance = 50
                prompt.RequiresLineOfSight = false
                fireproximityprompt(prompt)
                prompt.HoldDuration = origHold
                prompt.MaxActivationDistance = origDist
                prompt.RequiresLineOfSight = origLos
                triggeredPrompt = true
            end)
        end

        -- 2. ClickDetector di dalam model Bunta
        for _, desc in ipairs(buntaModel:GetDescendants()) do
            if desc:IsA("ClickDetector") and fireclickdetector then
                pcall(function()
                    local origDist = desc.MaxActivationDistance
                    desc.MaxActivationDistance = 50
                    fireclickdetector(desc, 1)
                    desc.MaxActivationDistance = origDist
                    triggeredClick = true
                end)
            end
        end

        -- 3. Hadapkan kamera langsung ke Bunta dan lakukan simulasi klik mouse
        pcall(function()
            local workspace = Services and Services.Workspace or game:GetService("Workspace")
            local camera = workspace.CurrentCamera
            if camera and buntaPart then
                camera.CFrame = CFrame.new(camera.CFrame.Position, buntaPart.Position)
                local screenPos, onScreen = camera:WorldToViewportPoint(buntaPart.Position)
                if onScreen then
                    local vim = Services and Services.VirtualInputManager or game:GetService("VirtualInputManager")
                    vim:SendMouseMoveEvent(screenPos.X, screenPos.Y, game)
                    task.wait(0.04)
                    vim:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, true, game, 1)
                    task.wait(0.06)
                    vim:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, false, game, 1)
                    triggeredMouseSim = true
                end
            end
        end)

        -- 4. KeyCode E interaksi keyboard
        pcall(function()
            local vim = Services and Services.VirtualInputManager or game:GetService("VirtualInputManager")
            vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.05)
            vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            triggeredKey = true
        end)

        print(string.format("[NYU HUB INTERACT] Sinyal interaksi dikirim (Prompt: %s, ClickDetector: %s, MouseSim: %s, KeyE: %s).",
            tostring(triggeredPrompt), tostring(triggeredClick), tostring(triggeredMouseSim), tostring(triggeredKey)))
        return true, "Success"
    end

    return Interaction
end

-- [[[ MODULE: Features/AutoFarmTofu/QuestDetector ]]]
__modules["Features/AutoFarmTofu/QuestDetector"] = function(require)
    --[[
        NYU HUB - Auto Farm Tofu Quest Detector
        Detects active delivery destination through attributes, player values, GUI labels, and workspace markers.
    ]]

    local Services = nil

    local QuestDetector = {
        BUNTA_NAME = "Fujiwara Bunta",
    }

    function QuestDetector.init(services)
        Services = services
    end

    function QuestDetector.DetectActiveDeliveryTarget(localPlayer, buntaName)
        buntaName = buntaName or QuestDetector.BUNTA_NAME
        localPlayer = localPlayer or (Services and Services.LocalPlayer) or game:GetService("Players").LocalPlayer
        if not localPlayer then return nil, nil end

        -- 1. Deteksi melalui attribute LocalPlayer
        local checkAttrs = {
            "DeliveryTarget",
            "DeliveryNPC",
            "QuestTarget",
            "TargetNPC",
            "DeliveryDestination",
            "ActiveDelivery",
            "Target",
        }
        for _, attrName in ipairs(checkAttrs) do
            local val = localPlayer:GetAttribute(attrName)
            if val and typeof(val) == "string" and #val > 0 then
                return val, "PlayerAttribute:" .. attrName
            end
        end

        -- 2. Deteksi melalui Value object di folder player (Quests, Job, dsb)
        local checkFolders = {
            "Quests", "Quest", "Job", "CurrentJob", "Delivery", "PlayerData"
        }
        for _, folderName in ipairs(checkFolders) do
            local folder = localPlayer:FindFirstChild(folderName)
            if folder then
                for _, child in ipairs(folder:GetChildren()) do
                    if child:IsA("StringValue") and #child.Value > 0 then
                        return child.Value, "PlayerValue:" .. folderName .. "." .. child.Name
                    end
                end
            end
        end

        -- 3. Deteksi melalui PlayerGui text label yang aktif
        local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
        if playerGui then
            for _, gui in ipairs(playerGui:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Enabled then
                    for _, desc in ipairs(gui:GetDescendants()) do
                        if desc:IsA("TextLabel") and desc.Visible then
                            local text = desc.Text
                            local target = text:match("[Dd]eliver to%s+([%w%s]+)")
                                or text:match("[Aa]ntar ke%s+([%w%s]+)")
                                or text:match("[Tt]arget:%s*([%w%s]+)")
                                or text:match("[Tt]o:%s*([%w%s]+)")
                            if target then
                                local cleaned = target:match("^%s*(.-)%s*$")
                                if #cleaned > 1 and cleaned ~= buntaName then
                                    return cleaned, "PlayerGui:" .. desc.Name
                                end
                            end
                        end
                    end
                end
            end
        end

        -- 4. Deteksi melalui marker Workspace aktif (BillboardGui/Highlight selain pada Bunta)
        local workspace = Services and Services.Workspace or game:GetService("Workspace")
        local npcFolder = workspace:FindFirstChild("NPCs")
        if npcFolder then
            for _, npc in ipairs(npcFolder:GetChildren()) do
                if npc.Name ~= buntaName then
                    local marker = npc:FindFirstChildWhichIsA("BillboardGui", true)
                        or npc:FindFirstChildWhichIsA("Highlight", true)
                    if marker and marker.Enabled then
                        return npc.Name, "WorkspaceMarker:" .. npc.Name
                    end
                end
            end
        end

        return nil, nil
    end

    return QuestDetector
end

-- [[[ MODULE: Features/Diagnostics ]]]
__modules["Features/Diagnostics"] = function(require)
    --[[
        NYU HUB - Quest & Client Diagnostics Feature
        Dumps player attributes, folders, Bunta dialogue state, NPC presence, and copies summary to clipboard.
    ]]

    local Services = nil
    local Dialogue = nil
    local Interaction = nil
    local Logger = nil
    local Config = nil

    local Diagnostics = {
        BUNTA_NAME = "Fujiwara Bunta",
    }

    function Diagnostics.init(dependencies)
        Services = dependencies.Services
        Dialogue = dependencies.Dialogue
        Interaction = dependencies.Interaction
        Logger = dependencies.Logger
        Config = dependencies.Config
    end

    function Diagnostics.Run()
        local localPlayer = Services and Services.LocalPlayer or game:GetService("Players").LocalPlayer
        local BUNTA_NAME = Diagnostics.BUNTA_NAME

        local lines = {}
        local function logLine(txt)
            table.insert(lines, txt)
            print(txt)
        end

        logLine("========== [NYU HUB] QUEST & CLIENT DIAGNOSTICS ==========")

        -- 1. Attributes
        local attrs = localPlayer:GetAttributes()
        local attrCount = 0
        for k, v in pairs(attrs) do
            attrCount = attrCount + 1
            logLine(string.format("  [Player Attribute] %s = %s (%s)", tostring(k), tostring(v), typeof(v)))
        end
        if attrCount == 0 then
            logLine("  [Player Attribute] Tidak ada attribute pada LocalPlayer.")
        end

        -- 2. Children / Folders
        logLine("  [Player Children]:")
        for _, child in ipairs(localPlayer:GetChildren()) do
            if child:IsA("ValueBase") or child:IsA("Folder") or child:IsA("Configuration") then
                logLine(string.format("    - %s (%s)", child.Name, child.ClassName))
                for _, subChild in ipairs(child:GetChildren()) do
                    if subChild:IsA("ValueBase") then
                        logLine(string.format("        * %s = %s", subChild.Name, tostring(subChild.Value)))
                    end
                end
            end
        end

        -- 3. Bunta Dialogue Container Analysis
        local dInfo = Dialogue.InspectBuntaDialogue()
        logLine(string.format("  [Bunta Dialogue Status] Terbuka: %s | Narasi: '%s'", tostring(dInfo.isOpen), dInfo.narration))
        if dInfo.isOpen then
            logLine(string.format("    - Container Name: %s (Parent: %s)", dInfo.container.Name, dInfo.gui.Name))
            for i, btn in ipairs(dInfo.buttons) do
                logLine(string.format("        [Button %d] '%s' (Name: %s)", i, btn.text, btn.name))
            end
        end

        -- 4. Status Bunta
        local buntaModel = Interaction.FindNPCModel(BUNTA_NAME)
        if buntaModel then
            local prompt = buntaModel:FindFirstChildWhichIsA("ProximityPrompt", true)
            local cd = buntaModel:FindFirstChildWhichIsA("ClickDetector", true)
            logLine(string.format("  [NPC %s] Ada. Prompt: %s | ClickDetector: %s", BUNTA_NAME, prompt and "YA" or "TIDAK", cd and "YA" or "TIDAK"))
        else
            logLine(string.format("  [NPC %s] Belum ditemukan di Workspace.", BUNTA_NAME))
        end

        logLine("==========================================================")

        local fullReport = table.concat(lines, "\n")

        -- Cetak ke warn agar selalu terlihat di console F9
        warn("[NYU HUB DIAGNOSTICS] Ringkasan tercatat (" .. #lines .. " baris).")

        -- Salin ke clipboard jika executor mendukung
        if setclipboard then
            pcall(function()
                setclipboard(fullReport)
                print("[NYU HUB] Laporan diagnostik disalin ke clipboard!")
            end)
        end

        if Logger and Logger.StatusComponent then
            pcall(function()
                local statusComponent = Logger.StatusComponent
                if statusComponent.SetTitle and statusComponent.Set then
                    statusComponent:SetTitle("Status: DIAGNOSTICS DONE")
                    statusComponent:Set(string.format("Laporan dibuat (%d baris). Cek F9 / clipboard.", #lines))
                elseif statusComponent.Set then
                    statusComponent:Set(string.format("[DIAGNOSTICS DONE] %d baris dicatat", #lines))
                end
            end)
        end

        if Logger then
            Logger.Notify(Config and Config.Name or "NYU HUB", "Diagnostik selesai (" .. #lines .. " baris). Disalin ke clipboard!")
        end
    end

    return Diagnostics
end

-- [[[ MODULE: Features/TeleportPlayer ]]]
__modules["Features/TeleportPlayer"] = function(require)
    --[[
        NYU HUB - Teleport to Player Feature
        Provides teleportation to another player by username.
    ]]

    local Services = nil
    local Logger = nil

    local TeleportPlayer = {
        SelectedUsername = "",
    }

    function TeleportPlayer.init(services, logger)
        Services = services
        Logger = logger
    end

    function TeleportPlayer.SetUsername(name)
        TeleportPlayer.SelectedUsername = name or ""
    end

    function TeleportPlayer.GetUsername()
        return TeleportPlayer.SelectedUsername
    end

    function TeleportPlayer.ExecuteTeleport()
        local username = TeleportPlayer.SelectedUsername:match("^%s*(.-)%s*$")
        local localPlayer = Services and Services.LocalPlayer or game:GetService("Players").LocalPlayer
        local playersService = Services and Services.Players or game:GetService("Players")

        if username == "" then
            if Logger then
                Logger.Notify(nil, "Masukkan username terlebih dahulu.")
            end
            return false, "EmptyUsername"
        end

        -- Cari username yang tepat di server saat ini
        local targetPlayer = nil

        for _, player in ipairs(playersService:GetPlayers()) do
            if player.Name:lower() == username:lower() then
                targetPlayer = player
                break
            end
        end

        if not targetPlayer then
            if Logger then
                Logger.Notify(nil, "Username tidak ditemukan di server ini.")
            end
            return false, "UserNotFound"
        end

        if targetPlayer == localPlayer then
            if Logger then
                Logger.Notify(nil, "Tidak bisa memilih akun sendiri.")
            end
            return false, "SelfTarget"
        end

        -- Validasi karakter
        local character = localPlayer.Character
        local targetCharacter = targetPlayer.Character

        local targetRoot = targetCharacter
            and targetCharacter:FindFirstChild("HumanoidRootPart")

        if not character or not character:FindFirstChild("HumanoidRootPart") then
            if Logger then
                Logger.Notify(nil, "Karakter kamu belum siap.")
            end
            return false, "LocalCharNotReady"
        end

        if not targetRoot then
            if Logger then
                Logger.Notify(nil, "Karakter target belum siap.")
            end
            return false, "TargetCharNotReady"
        end

        -- Perpindahan lokal; server game dapat membatalkannya
        character:PivotTo(
            targetRoot.CFrame * CFrame.new(0, 0, 3)
        )

        if Logger then
            Logger.Notify(nil, "Teleport dicoba ke " .. targetPlayer.Name)
        end

        print("[NYU HUB] Teleport target:", targetPlayer.Name)
        return true
    end

    return TeleportPlayer
end

-- [[[ MODULE: Features/WalkSpeed ]]]
__modules["Features/WalkSpeed"] = function(require)
    --[[
        NYU HUB - Walk Speed Feature
        Manages player WalkSpeed modifications.
    ]]

    local Services = nil

    local WalkSpeed = {}

    function WalkSpeed.init(services)
        Services = services
    end

    function WalkSpeed.SetWalkSpeed(value)
        local localPlayer = Services and Services.LocalPlayer or game:GetService("Players").LocalPlayer
        local character = localPlayer and localPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if not humanoid then
            warn("[NYU HUB] Humanoid tidak ditemukan.")
            return false
        end

        humanoid.WalkSpeed = value
        print("[NYU HUB] Walk Speed:", value)
        return true
    end

    return WalkSpeed
end

-- [[[ MODULE: Main ]]]
__modules["Main"] = function(require)
--[[
    NYU HUB
    Version: 1.2.0
    Module: Main Entrypoint
    UI Library: Custom NYU UI Foundation
]]

local Main = {}

function Main.init(require)
    local Config = require("Config")
    local Services = require("Core/Services")
    local Character = require("Core/Character")
    local Teleport = require("Core/Teleport")
    local Network = require("Core/Network")
    local Logger = require("Core/Logger")

    local WalkSpeed = require("Features/WalkSpeed")
    local TeleportPlayer = require("Features/TeleportPlayer")
    local Diagnostics = require("Features/Diagnostics")

    local Dialogue = require("Features/AutoFarmTofu/Dialogue")
    local Interaction = require("Features/AutoFarmTofu/Interaction")
    local QuestDetector = require("Features/AutoFarmTofu/QuestDetector")
    local FarmCycle = require("Features/AutoFarmTofu/FarmCycle")

    local Window = require("UI/Window")
    local HomeTab = require("UI/Tabs/HomeTab")
    local UtilitiesTab = require("UI/Tabs/UtilitiesTab")
    local SettingsTab = require("UI/Tabs/SettingsTab")

    -- Check LocalPlayer
    if not Services.LocalPlayer then
        warn("[NYU HUB] LocalPlayer is unavailable.")
        return
    end

    -- Wire Core singletons
    Character.init(Services)
    Teleport.init(Character)
    Network.init(Services)
    Interaction.init(Services, Character)
    QuestDetector.init(Services)

    -- Wire Features
    WalkSpeed.init(Services)
    TeleportPlayer.init(Services, Logger)

    FarmCycle.init({
        Character = Character,
        Teleport = Teleport,
        Network = Network,
        Logger = Logger,
        Dialogue = Dialogue,
        Interaction = Interaction,
        QuestDetector = QuestDetector,
        Config = Config,
    })

    Diagnostics.init({
        Services = Services,
        Dialogue = Dialogue,
        Interaction = Interaction,
        Logger = Logger,
        Config = Config,
    })

    -- Create Custom UI Window
    local window = Window.Create(Config)
    if not window then
        warn("[NYU HUB] Failed to create UI Window.")
        return
    end

    Logger.init(Config, window, nil)

    -- Build Tabs
    local homeTab = HomeTab.Create(window, Config)
    local utilitiesTab, statusComponent = UtilitiesTab.Create(window, Config, {
        WalkSpeed = WalkSpeed,
        TeleportPlayer = TeleportPlayer,
        Diagnostics = Diagnostics,
        FarmCycle = FarmCycle,
    }, Logger)
    local settingsTab = SettingsTab.Create(window, Config)

    if statusComponent then
        Logger.SetStatusComponent(statusComponent)
    end

    -- Initialization complete
    print(
        "[NYU HUB] Version "
        .. Config.Version
        .. " loaded successfully."
    )
end

return Main
end

-- [[[ MODULE: UI/Components/Button ]]]
__modules["UI/Components/Button"] = function(require)
--[[
    NYU HUB - Button Component
    Interactive button with hover states, description support, and smooth transitions.
]]

local Theme = nil

local function getTheme()
    if not Theme then
        local success, result = pcall(function()
            return require(script.Parent.Parent.Theme)
        end)
        if success and result then
            Theme = result
        else
            -- Fallback defaults if Theme cannot be required directly
            Theme = {
                Colors = {
                    Card = Color3.fromRGB(30, 34, 42),
                    CardHover = Color3.fromRGB(38, 43, 53),
                    CardActive = Color3.fromRGB(48, 54, 68),
                    Border = Color3.fromRGB(46, 52, 64),
                    BorderHover = Color3.fromRGB(79, 140, 255),
                    TextPrimary = Color3.fromRGB(243, 244, 246),
                    TextSecondary = Color3.fromRGB(156, 163, 175),
                    Accent = Color3.fromRGB(79, 140, 255),
                },
                Fonts = {
                    Heading = Enum.Font.GothamMedium,
                    Body = Enum.Font.Gotham,
                },
                TextSizes = {
                    Body = 13,
                    Caption = 11,
                },
                CornerRadius = {
                    Medium = UDim.new(0, 8),
                    Small = UDim.new(0, 6),
                },
                Tween = {
                    Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                },
                Animate = function(inst, info, goal)
                    local ts = game:GetService("TweenService")
                    local tw = ts:Create(inst, info or TweenInfo.new(0.15), goal)
                    tw:Play()
                    return tw
                end,
                Round = function(inst, rad)
                    local c = Instance.new("UICorner")
                    c.CornerRadius = rad or UDim.new(0, 8)
                    c.Parent = inst
                    return c
                end,
                Stroke = function(inst, col, th)
                    local s = Instance.new("UIStroke")
                    s.Color = col or Color3.fromRGB(46, 52, 64)
                    s.Thickness = th or 1
                    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    s.Parent = inst
                    return s
                end,
                Padding = function(inst, top, bot, left, right)
                    local p = Instance.new("UIPadding")
                    p.PaddingTop = UDim.new(0, top or 8)
                    p.PaddingBottom = UDim.new(0, bot or top or 8)
                    p.PaddingLeft = UDim.new(0, left or 12)
                    p.PaddingRight = UDim.new(0, right or left or 12)
                    p.Parent = inst
                    return p
                end,
            }
        end
    end
    return Theme
end

local Button = {}

function Button.Create(parent, options)
    options = options or {}
    local theme = getTheme()

    local titleText = options.name or options.title or "Button"
    local descText = options.description or ""
    local callback = options.callback or function() end

    local hasDesc = descText ~= ""
    local height = hasDesc and 54 or 42

    local buttonFrame = Instance.new("TextButton")
    buttonFrame.Name = "Button_" .. titleText
    buttonFrame.Size = UDim2.new(1, 0, 0, height)
    buttonFrame.BackgroundColor3 = theme.Colors.Card
    buttonFrame.BorderSizePixel = 0
    buttonFrame.AutoButtonColor = false
    buttonFrame.Text = ""
    buttonFrame.ClipsDescendants = true
    buttonFrame.Parent = parent

    theme.Round(buttonFrame, theme.CornerRadius.Medium)
    local stroke = theme.Stroke(buttonFrame, theme.Colors.Border, 1)
    theme.Padding(buttonFrame, 8, 8, 14, 14)

    -- Text Container
    local textContainer = Instance.new("Frame")
    textContainer.Name = "TextContainer"
    textContainer.Size = UDim2.new(1, -36, 1, 0)
    textContainer.BackgroundTransparency = 1
    textContainer.Parent = buttonFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    listLayout.Padding = UDim.new(0, 3)
    listLayout.Parent = textContainer

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 16)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = theme.Fonts.Heading
    titleLabel.Text = titleText
    titleLabel.TextColor3 = theme.Colors.TextPrimary
    titleLabel.TextSize = theme.TextSizes.Body
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = textContainer

    local descLabel = nil
    if hasDesc then
        descLabel = Instance.new("TextLabel")
        descLabel.Name = "Description"
        descLabel.Size = UDim2.new(1, 0, 0, 14)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = theme.Fonts.Body
        descLabel.Text = descText
        descLabel.TextColor3 = theme.Colors.TextSecondary
        descLabel.TextSize = theme.TextSizes.Caption
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextTruncate = Enum.TextTruncate.AtEnd
        descLabel.Parent = textContainer
    end

    -- Right Action Indicator
    local arrowLabel = Instance.new("TextLabel")
    arrowLabel.Name = "Arrow"
    arrowLabel.AnchorPoint = Vector2.new(1, 0.5)
    arrowLabel.Position = UDim2.new(1, 0, 0.5, 0)
    arrowLabel.Size = UDim2.new(0, 20, 0, 20)
    arrowLabel.BackgroundTransparency = 1
    arrowLabel.Font = theme.Fonts.Heading
    arrowLabel.Text = "›"
    arrowLabel.TextColor3 = theme.Colors.TextMuted or theme.Colors.TextSecondary
    arrowLabel.TextSize = 16
    arrowLabel.Parent = buttonFrame

    -- Hover & Click Interactions
    local isHovered = false
    local isPressed = false

    buttonFrame.MouseEnter:Connect(function()
        isHovered = true
        theme.Animate(buttonFrame, theme.Tween.Fast, {
            BackgroundColor3 = theme.Colors.CardHover,
        })
        theme.Animate(stroke, theme.Tween.Fast, {
            Color = theme.Colors.BorderHover,
        })
        theme.Animate(arrowLabel, theme.Tween.Fast, {
            TextColor3 = theme.Colors.Accent,
        })
    end)

    buttonFrame.MouseLeave:Connect(function()
        isHovered = false
        isPressed = false
        theme.Animate(buttonFrame, theme.Tween.Fast, {
            BackgroundColor3 = theme.Colors.Card,
        })
        theme.Animate(stroke, theme.Tween.Fast, {
            Color = theme.Colors.Border,
        })
        theme.Animate(arrowLabel, theme.Tween.Fast, {
            TextColor3 = theme.Colors.TextMuted or theme.Colors.TextSecondary,
        })
    end)

    buttonFrame.MouseButton1Down:Connect(function()
        isPressed = true
        theme.Animate(buttonFrame, theme.Tween.Fast, {
            BackgroundColor3 = theme.Colors.CardActive,
        })
    end)

    buttonFrame.MouseButton1Up:Connect(function()
        if isPressed then
            isPressed = false
            local targetBg = isHovered and theme.Colors.CardHover or theme.Colors.Card
            theme.Animate(buttonFrame, theme.Tween.Fast, {
                BackgroundColor3 = targetBg,
            })
            pcall(callback)
        end
    end)

    -- Component Object
    local component = {
        Instance = buttonFrame,
    }

    function component:SetTitle(newTitle)
        titleLabel.Text = tostring(newTitle)
    end

    function component:SetDescription(newDesc)
        if descLabel then
            descLabel.Text = tostring(newDesc)
        end
    end

    function component:SetCallback(newCallback)
        callback = newCallback or function() end
    end

    function component:SetVisible(visible)
        buttonFrame.Visible = visible
    end

    function component:Destroy()
        buttonFrame:Destroy()
    end

    return component
end

return Button
end

-- [[[ MODULE: UI/Components/Input ]]]
__modules["UI/Components/Input"] = function(require)
--[[
    NYU HUB - Input Component
    Interactive text input field with placeholder, focus styling, numeric filtering, and callback.
]]

local Theme = nil

local function getTheme()
    if not Theme then
        local success, result = pcall(function()
            return require(script.Parent.Parent.Theme)
        end)
        if success and result then
            Theme = result
        else
            Theme = {
                Colors = {
                    Card = Color3.fromRGB(30, 34, 42),
                    CardHover = Color3.fromRGB(38, 43, 53),
                    Border = Color3.fromRGB(46, 52, 64),
                    BorderHover = Color3.fromRGB(79, 140, 255),
                    BorderActive = Color3.fromRGB(102, 155, 255),
                    TextPrimary = Color3.fromRGB(243, 244, 246),
                    TextSecondary = Color3.fromRGB(156, 163, 175),
                    TextMuted = Color3.fromRGB(107, 114, 128),
                    Accent = Color3.fromRGB(79, 140, 255),
                },
                Fonts = {
                    Heading = Enum.Font.GothamMedium,
                    Body = Enum.Font.Gotham,
                },
                TextSizes = {
                    Body = 13,
                    Caption = 11,
                },
                CornerRadius = {
                    Medium = UDim.new(0, 8),
                    Small = UDim.new(0, 6),
                },
                Tween = {
                    Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                },
                Animate = function(inst, info, goal)
                    local ts = game:GetService("TweenService")
                    local tw = ts:Create(inst, info or TweenInfo.new(0.15), goal)
                    tw:Play()
                    return tw
                end,
                Round = function(inst, rad)
                    local c = Instance.new("UICorner")
                    c.CornerRadius = rad or UDim.new(0, 8)
                    c.Parent = inst
                    return c
                end,
                Stroke = function(inst, col, th)
                    local s = Instance.new("UIStroke")
                    s.Color = col or Color3.fromRGB(46, 52, 64)
                    s.Thickness = th or 1
                    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    s.Parent = inst
                    return s
                end,
                Padding = function(inst, top, bot, left, right)
                    local p = Instance.new("UIPadding")
                    p.PaddingTop = UDim.new(0, top or 8)
                    p.PaddingBottom = UDim.new(0, bot or top or 8)
                    p.PaddingLeft = UDim.new(0, left or 12)
                    p.PaddingRight = UDim.new(0, right or left or 12)
                    p.Parent = inst
                    return p
                end,
            }
        end
    end
    return Theme
end

local Input = {}

function Input.Create(parent, options)
    options = options or {}
    local theme = getTheme()

    local titleText = options.name or options.title or "Input"
    local descText = options.description or ""
    local placeholder = options.placeholder or "Type here..."
    local defaultText = options.default or options.value or ""
    local isNumeric = options.numeric or false
    local fireOnFinishOnly = (options.finished == nil) and true or options.finished
    local callback = options.callback or function() end

    local hasDesc = descText ~= ""
    local height = hasDesc and 64 or 46

    local inputCard = Instance.new("Frame")
    inputCard.Name = "Input_" .. titleText
    inputCard.Size = UDim2.new(1, 0, 0, height)
    inputCard.BackgroundColor3 = theme.Colors.Card
    inputCard.BorderSizePixel = 0
    inputCard.Parent = parent

    theme.Round(inputCard, theme.CornerRadius.Medium)
    local cardStroke = theme.Stroke(inputCard, theme.Colors.Border, 1)
    theme.Padding(inputCard, 8, 8, 14, 14)

    -- Left Text Container
    local textContainer = Instance.new("Frame")
    textContainer.Name = "TextContainer"
    textContainer.Size = UDim2.new(1, -150, 1, 0)
    textContainer.BackgroundTransparency = 1
    textContainer.Parent = inputCard

    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    listLayout.Padding = UDim.new(0, 3)
    listLayout.Parent = textContainer

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 16)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = theme.Fonts.Heading
    titleLabel.Text = titleText
    titleLabel.TextColor3 = theme.Colors.TextPrimary
    titleLabel.TextSize = theme.TextSizes.Body
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = textContainer

    local descLabel = nil
    if hasDesc then
        descLabel = Instance.new("TextLabel")
        descLabel.Name = "Description"
        descLabel.Size = UDim2.new(1, 0, 0, 14)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = theme.Fonts.Body
        descLabel.Text = descText
        descLabel.TextColor3 = theme.Colors.TextSecondary
        descLabel.TextSize = theme.TextSizes.Caption
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextTruncate = Enum.TextTruncate.AtEnd
        descLabel.Parent = textContainer
    end

    -- Right TextBox Box
    local boxContainer = Instance.new("Frame")
    boxContainer.Name = "BoxContainer"
    boxContainer.AnchorPoint = Vector2.new(1, 0.5)
    boxContainer.Position = UDim2.new(1, 0, 0.5, 0)
    boxContainer.Size = UDim2.new(0, 136, 0, 28)
    boxContainer.BackgroundColor3 = theme.Colors.CardHover or Color3.fromRGB(38, 43, 53)
    boxContainer.BorderSizePixel = 0
    boxContainer.Parent = inputCard

    theme.Round(boxContainer, theme.CornerRadius.Small)
    local boxStroke = theme.Stroke(boxContainer, theme.Colors.Border, 1)
    theme.Padding(boxContainer, 0, 0, 8, 8)

    local textBox = Instance.new("TextBox")
    textBox.Name = "InputBox"
    textBox.Size = UDim2.new(1, 0, 1, 0)
    textBox.BackgroundTransparency = 1
    textBox.Font = theme.Fonts.Body
    textBox.Text = tostring(defaultText)
    textBox.PlaceholderText = placeholder
    textBox.PlaceholderColor3 = theme.Colors.TextMuted or Color3.fromRGB(107, 114, 128)
    textBox.TextColor3 = theme.Colors.TextPrimary
    textBox.TextSize = theme.TextSizes.Body
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.ClearTextOnFocus = false
    textBox.ClipsDescendants = true
    textBox.Parent = boxContainer

    -- Numeric filtering
    if isNumeric then
        textBox:GetPropertyChangedSignal("Text"):Connect(function()
            local sanitized = textBox.Text:gsub("%D+", "")
            if textBox.Text ~= sanitized then
                textBox.Text = sanitized
            end
        end)
    end

    -- Focus animations
    textBox.Focused:Connect(function()
        theme.Animate(boxStroke, theme.Tween.Fast, {
            Color = theme.Colors.BorderActive or theme.Colors.Accent,
        })
    end)

    textBox.FocusLost:Connect(function(enterPressed)
        theme.Animate(boxStroke, theme.Tween.Fast, {
            Color = theme.Colors.Border,
        })
        if fireOnFinishOnly then
            pcall(callback, textBox.Text, enterPressed)
        end
    end)

    if not fireOnFinishOnly then
        textBox:GetPropertyChangedSignal("Text"):Connect(function()
            pcall(callback, textBox.Text, false)
        end)
    end

    local component = {
        Instance = inputCard,
        TextBox = textBox,
    }

    function component:Set(newText, skipCallback)
        textBox.Text = tostring(newText or "")
        if not skipCallback then
            pcall(callback, textBox.Text, false)
        end
    end

    function component:Get()
        return textBox.Text
    end

    function component:SetTitle(newTitle)
        titleLabel.Text = tostring(newTitle)
    end

    function component:SetDescription(newDesc)
        if descLabel then
            descLabel.Text = tostring(newDesc)
        end
    end

    function component:SetPlaceholder(newPlaceholder)
        textBox.PlaceholderText = tostring(newPlaceholder or "")
    end

    function component:SetCallback(newCallback)
        callback = newCallback or function() end
    end

    function component:Destroy()
        inputCard:Destroy()
    end

    return component
end

return Input
end

-- [[[ MODULE: UI/Components/Slider ]]]
__modules["UI/Components/Slider"] = function(require)
--[[
    NYU HUB - Slider Component
    Draggable slider with range clamping, increment snapping, and live value badge.
]]

local UserInputService = game:GetService("UserInputService")
local Theme = nil

local function getTheme()
    if not Theme then
        local success, result = pcall(function()
            return require(script.Parent.Parent.Theme)
        end)
        if success and result then
            Theme = result
        else
            Theme = {
                Colors = {
                    Card = Color3.fromRGB(30, 34, 42),
                    CardHover = Color3.fromRGB(38, 43, 53),
                    Border = Color3.fromRGB(46, 52, 64),
                    BorderHover = Color3.fromRGB(79, 140, 255),
                    TextPrimary = Color3.fromRGB(243, 244, 246),
                    TextSecondary = Color3.fromRGB(156, 163, 175),
                    Accent = Color3.fromRGB(79, 140, 255),
                    Track = Color3.fromRGB(46, 52, 64),
                    TrackFill = Color3.fromRGB(79, 140, 255),
                    Knob = Color3.fromRGB(255, 255, 255),
                },
                Fonts = {
                    Heading = Enum.Font.GothamMedium,
                    Body = Enum.Font.Gotham,
                    Code = Enum.Font.Code,
                },
                TextSizes = {
                    Body = 13,
                    Caption = 11,
                },
                CornerRadius = {
                    Medium = UDim.new(0, 8),
                    Small = UDim.new(0, 4),
                    Pill = UDim.new(1, 0),
                },
                Tween = {
                    Fast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                },
                Animate = function(inst, info, goal)
                    local ts = game:GetService("TweenService")
                    local tw = ts:Create(inst, info or TweenInfo.new(0.12), goal)
                    tw:Play()
                    return tw
                end,
                Round = function(inst, rad)
                    local c = Instance.new("UICorner")
                    c.CornerRadius = rad or UDim.new(0, 8)
                    c.Parent = inst
                    return c
                end,
                Stroke = function(inst, col, th)
                    local s = Instance.new("UIStroke")
                    s.Color = col or Color3.fromRGB(46, 52, 64)
                    s.Thickness = th or 1
                    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    s.Parent = inst
                    return s
                end,
                Padding = function(inst, top, bot, left, right)
                    local p = Instance.new("UIPadding")
                    p.PaddingTop = UDim.new(0, top or 8)
                    p.PaddingBottom = UDim.new(0, bot or top or 8)
                    p.PaddingLeft = UDim.new(0, left or 12)
                    p.PaddingRight = UDim.new(0, right or left or 12)
                    p.Parent = inst
                    return p
                end,
            }
        end
    end
    return Theme
end

local Slider = {}

function Slider.Create(parent, options)
    options = options or {}
    local theme = getTheme()

    local titleText = options.name or options.title or "Slider"
    local descText = options.description or ""
    local callback = options.callback or function() end
    local range = options.range or { 0, 100 }
    local min = tonumber(range[1]) or 0
    local max = tonumber(range[2]) or 100
    local increment = tonumber(options.increment) or 1
    local currentValue = tonumber(options.value or options.default) or min

    local hasDesc = descText ~= ""
    local height = hasDesc and 68 or 56

    local sliderFrame = Instance.new("Frame")
    sliderFrame.Name = "Slider_" .. titleText
    sliderFrame.Size = UDim2.new(1, 0, 0, height)
    sliderFrame.BackgroundColor3 = theme.Colors.Card
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = parent

    theme.Round(sliderFrame, theme.CornerRadius.Medium)
    local stroke = theme.Stroke(sliderFrame, theme.Colors.Border, 1)
    theme.Padding(sliderFrame, 10, 10, 14, 14)

    -- Top Header Container (Title on left, Value badge on right)
    local headerFrame = Instance.new("Frame")
    headerFrame.Name = "Header"
    headerFrame.Size = UDim2.new(1, 0, 0, 18)
    headerFrame.BackgroundTransparency = 1
    headerFrame.Parent = sliderFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = theme.Fonts.Heading
    titleLabel.Text = titleText
    titleLabel.TextColor3 = theme.Colors.TextPrimary
    titleLabel.TextSize = theme.TextSizes.Body
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = headerFrame

    local valueBadge = Instance.new("TextLabel")
    valueBadge.Name = "ValueBadge"
    valueBadge.AnchorPoint = Vector2.new(1, 0)
    valueBadge.Position = UDim2.new(1, 0, 0, 0)
    valueBadge.Size = UDim2.new(0, 52, 1, 0)
    valueBadge.BackgroundColor3 = theme.Colors.CardHover
    valueBadge.BorderSizePixel = 0
    valueBadge.Font = theme.Fonts.Code or Enum.Font.GothamMedium
    valueBadge.TextColor3 = theme.Colors.Accent
    valueBadge.TextSize = theme.TextSizes.Caption
    valueBadge.Text = tostring(currentValue)
    valueBadge.Parent = headerFrame
    theme.Round(valueBadge, theme.CornerRadius.Small)

    -- Optional Description
    local descLabel = nil
    if hasDesc then
        descLabel = Instance.new("TextLabel")
        descLabel.Name = "Description"
        descLabel.Size = UDim2.new(1, 0, 0, 12)
        descLabel.Position = UDim2.new(0, 0, 0, 20)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = theme.Fonts.Body
        descLabel.Text = descText
        descLabel.TextColor3 = theme.Colors.TextSecondary
        descLabel.TextSize = theme.TextSizes.Caption
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = sliderFrame
    end

    -- Slider Track Bar
    local trackButton = Instance.new("TextButton")
    trackButton.Name = "Track"
    trackButton.AnchorPoint = Vector2.new(0, 1)
    trackButton.Position = UDim2.new(0, 0, 1, 0)
    trackButton.Size = UDim2.new(1, 0, 0, 8)
    trackButton.BackgroundColor3 = theme.Colors.Track
    trackButton.BorderSizePixel = 0
    trackButton.AutoButtonColor = false
    trackButton.Text = ""
    trackButton.Parent = sliderFrame
    theme.Round(trackButton, theme.CornerRadius.Pill)

    local fillBar = Instance.new("Frame")
    fillBar.Name = "Fill"
    fillBar.Size = UDim2.new(0, 0, 1, 0)
    fillBar.BackgroundColor3 = theme.Colors.TrackFill
    fillBar.BorderSizePixel = 0
    fillBar.Parent = trackButton
    theme.Round(fillBar, theme.CornerRadius.Pill)

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(1, 0, 0.5, 0)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.BackgroundColor3 = theme.Colors.Knob
    knob.BorderSizePixel = 0
    knob.Parent = fillBar
    theme.Round(knob, theme.CornerRadius.Pill)

    local function snap(val)
        val = math.clamp(val, min, max)
        local steps = math.floor((val - min) / increment + 0.5)
        local snapped = min + (steps * increment)
        if increment >= 1 then
            return math.floor(snapped + 0.5)
        else
            return tonumber(string.format("%.2f", snapped)) or snapped
        end
    end

    local function updateVisuals(val)
        local safeMax = (max > min) and max or (min + 1)
        local progress = math.clamp((val - min) / (safeMax - min), 0, 1)
        fillBar.Size = UDim2.new(progress, 0, 1, 0)
        valueBadge.Text = tostring(val)
    end

    currentValue = snap(currentValue)
    updateVisuals(currentValue)

    -- Hover interactions
    sliderFrame.MouseEnter:Connect(function()
        theme.Animate(stroke, theme.Tween.Fast, {
            Color = theme.Colors.BorderHover,
        })
    end)

    sliderFrame.MouseLeave:Connect(function()
        theme.Animate(stroke, theme.Tween.Fast, {
            Color = theme.Colors.Border,
        })
    end)

    -- Drag Handling
    local isDragging = false

    local function calculateValueFromInput(input)
        local trackAbsPos = trackButton.AbsolutePosition.X
        local trackAbsSize = trackButton.AbsoluteSize.X
        if trackAbsSize <= 0 then
            return currentValue
        end
        local mousePos = input.Position.X
        local relative = math.clamp((mousePos - trackAbsPos) / trackAbsSize, 0, 1)
        local rawValue = min + (relative * (max - min))
        return snap(rawValue)
    end

    local function updateFromInput(input, fireCb)
        local newVal = calculateValueFromInput(input)
        if newVal ~= currentValue then
            currentValue = newVal
            updateVisuals(currentValue)
            if fireCb then
                pcall(callback, currentValue)
            end
        end
    end

    trackButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            theme.Animate(knob, theme.Tween.Fast, {
                Size = UDim2.new(0, 18, 0, 18),
            })
            updateFromInput(input, true)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input, true)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if isDragging then
                isDragging = false
                theme.Animate(knob, theme.Tween.Fast, {
                    Size = UDim2.new(0, 14, 0, 14),
                })
            end
        end
    end)

    local component = {
        Instance = sliderFrame,
    }

    function component:Set(newValue, skipCallback)
        currentValue = snap(tonumber(newValue) or min)
        updateVisuals(currentValue)
        if not skipCallback then
            pcall(callback, currentValue)
        end
    end

    function component:Get()
        return currentValue
    end

    function component:SetTitle(newTitle)
        titleLabel.Text = tostring(newTitle)
    end

    function component:SetDescription(newDesc)
        if descLabel then
            descLabel.Text = tostring(newDesc)
        end
    end

    function component:SetRange(newMin, newMax, newInc)
        min = tonumber(newMin) or min
        max = tonumber(newMax) or max
        if newInc then
            increment = tonumber(newInc) or increment
        end
        component:Set(currentValue, true)
    end

    function component:SetCallback(newCallback)
        callback = newCallback or function() end
    end

    function component:Destroy()
        sliderFrame:Destroy()
    end

    return component
end

return Slider
end

-- [[[ MODULE: UI/Components/Toggle ]]]
__modules["UI/Components/Toggle"] = function(require)
--[[
    NYU HUB - Toggle Component
    Interactive toggle switch with animated thumb, flag support, and callback trigger.
]]

local Theme = nil

local function getTheme()
    if not Theme then
        local success, result = pcall(function()
            return require(script.Parent.Parent.Theme)
        end)
        if success and result then
            Theme = result
        else
            Theme = {
                Colors = {
                    Card = Color3.fromRGB(30, 34, 42),
                    CardHover = Color3.fromRGB(38, 43, 53),
                    Border = Color3.fromRGB(46, 52, 64),
                    BorderHover = Color3.fromRGB(79, 140, 255),
                    TextPrimary = Color3.fromRGB(243, 244, 246),
                    TextSecondary = Color3.fromRGB(156, 163, 175),
                    Accent = Color3.fromRGB(79, 140, 255),
                    Track = Color3.fromRGB(46, 52, 64),
                    TrackFill = Color3.fromRGB(79, 140, 255),
                    Knob = Color3.fromRGB(255, 255, 255),
                },
                Fonts = {
                    Heading = Enum.Font.GothamMedium,
                    Body = Enum.Font.Gotham,
                },
                TextSizes = {
                    Body = 13,
                    Caption = 11,
                },
                CornerRadius = {
                    Medium = UDim.new(0, 8),
                    Pill = UDim.new(1, 0),
                },
                Tween = {
                    Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    Normal = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                },
                Animate = function(inst, info, goal)
                    local ts = game:GetService("TweenService")
                    local tw = ts:Create(inst, info or TweenInfo.new(0.15), goal)
                    tw:Play()
                    return tw
                end,
                Round = function(inst, rad)
                    local c = Instance.new("UICorner")
                    c.CornerRadius = rad or UDim.new(0, 8)
                    c.Parent = inst
                    return c
                end,
                Stroke = function(inst, col, th)
                    local s = Instance.new("UIStroke")
                    s.Color = col or Color3.fromRGB(46, 52, 64)
                    s.Thickness = th or 1
                    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    s.Parent = inst
                    return s
                end,
                Padding = function(inst, top, bot, left, right)
                    local p = Instance.new("UIPadding")
                    p.PaddingTop = UDim.new(0, top or 8)
                    p.PaddingBottom = UDim.new(0, bot or top or 8)
                    p.PaddingLeft = UDim.new(0, left or 12)
                    p.PaddingRight = UDim.new(0, right or left or 12)
                    p.Parent = inst
                    return p
                end,
            }
        end
    end
    return Theme
end

local Toggle = {}

function Toggle.Create(parent, options)
    options = options or {}
    local theme = getTheme()

    local titleText = options.name or options.title or "Toggle"
    local descText = options.description or ""
    local callback = options.callback or function() end
    local state = options.default or options.value or false
    local flag = options.flag

    local hasDesc = descText ~= ""
    local height = hasDesc and 54 or 42

    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "Toggle_" .. titleText
    toggleButton.Size = UDim2.new(1, 0, 0, height)
    toggleButton.BackgroundColor3 = theme.Colors.Card
    toggleButton.BorderSizePixel = 0
    toggleButton.AutoButtonColor = false
    toggleButton.Text = ""
    toggleButton.ClipsDescendants = true
    toggleButton.Parent = parent

    theme.Round(toggleButton, theme.CornerRadius.Medium)
    local stroke = theme.Stroke(toggleButton, theme.Colors.Border, 1)
    theme.Padding(toggleButton, 8, 8, 14, 14)

    -- Left Text Container
    local textContainer = Instance.new("Frame")
    textContainer.Name = "TextContainer"
    textContainer.Size = UDim2.new(1, -54, 1, 0)
    textContainer.BackgroundTransparency = 1
    textContainer.Parent = toggleButton

    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    listLayout.Padding = UDim.new(0, 3)
    listLayout.Parent = textContainer

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 16)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = theme.Fonts.Heading
    titleLabel.Text = titleText
    titleLabel.TextColor3 = theme.Colors.TextPrimary
    titleLabel.TextSize = theme.TextSizes.Body
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = textContainer

    local descLabel = nil
    if hasDesc then
        descLabel = Instance.new("TextLabel")
        descLabel.Name = "Description"
        descLabel.Size = UDim2.new(1, 0, 0, 14)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = theme.Fonts.Body
        descLabel.Text = descText
        descLabel.TextColor3 = theme.Colors.TextSecondary
        descLabel.TextSize = theme.TextSizes.Caption
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextTruncate = Enum.TextTruncate.AtEnd
        descLabel.Parent = textContainer
    end

    -- Switch Graphic (Pill & Thumb)
    local switchTrack = Instance.new("Frame")
    switchTrack.Name = "SwitchTrack"
    switchTrack.AnchorPoint = Vector2.new(1, 0.5)
    switchTrack.Position = UDim2.new(1, 0, 0.5, 0)
    switchTrack.Size = UDim2.new(0, 40, 0, 22)
    switchTrack.BackgroundColor3 = state and theme.Colors.TrackFill or theme.Colors.Track
    switchTrack.BorderSizePixel = 0
    switchTrack.Parent = toggleButton
    theme.Round(switchTrack, theme.CornerRadius.Pill)

    local switchKnob = Instance.new("Frame")
    switchKnob.Name = "Knob"
    switchKnob.Size = UDim2.new(0, 16, 0, 16)
    switchKnob.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    switchKnob.BackgroundColor3 = theme.Colors.Knob
    switchKnob.BorderSizePixel = 0
    switchKnob.Parent = switchTrack
    theme.Round(switchKnob, theme.CornerRadius.Pill)

    local function updateVisuals(animate)
        local trackTargetColor = state and theme.Colors.TrackFill or theme.Colors.Track
        local knobTargetPos = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)

        if animate then
            theme.Animate(switchTrack, theme.Tween.Normal, {
                BackgroundColor3 = trackTargetColor,
            })
            theme.Animate(switchKnob, theme.Tween.Normal, {
                Position = knobTargetPos,
            })
        else
            switchTrack.BackgroundColor3 = trackTargetColor
            switchKnob.Position = knobTargetPos
        end
    end

    -- Hover Interactions
    toggleButton.MouseEnter:Connect(function()
        theme.Animate(toggleButton, theme.Tween.Fast, {
            BackgroundColor3 = theme.Colors.CardHover,
        })
        theme.Animate(stroke, theme.Tween.Fast, {
            Color = theme.Colors.BorderHover,
        })
    end)

    toggleButton.MouseLeave:Connect(function()
        theme.Animate(toggleButton, theme.Tween.Fast, {
            BackgroundColor3 = theme.Colors.Card,
        })
        theme.Animate(stroke, theme.Tween.Fast, {
            Color = theme.Colors.Border,
        })
    end)

    local component = {
        Instance = toggleButton,
        Flag = flag,
    }

    local function setState(newValue, skipCallback)
        state = not not newValue
        updateVisuals(true)
        if not skipCallback then
            pcall(callback, state)
        end
    end

    toggleButton.MouseButton1Click:Connect(function()
        setState(not state, false)
    end)

    function component:Set(newValue, skipCallback)
        setState(newValue, skipCallback)
    end

    function component:Get()
        return state
    end

    function component:SetTitle(newTitle)
        titleLabel.Text = tostring(newTitle)
    end

    function component:SetDescription(newDesc)
        if descLabel then
            descLabel.Text = tostring(newDesc)
        end
    end

    function component:SetCallback(newCallback)
        callback = newCallback or function() end
    end

    function component:Destroy()
        toggleButton:Destroy()
    end

    return component
end

return Toggle
end

-- [[[ MODULE: UI/Tabs/HomeTab ]]]
__modules["UI/Tabs/HomeTab"] = function(require)
--[[
    NYU HUB - UI Home Tab
    Preserves Notification test, Example Toggle, and Example Slider with Custom UI.
]]

local HomeTab = {}

function HomeTab.Create(window, config)
    local tab = window:CreateTab({
        name = config.Tabs and config.Tabs.Home or "Home",
    })

    -- Welcome Banner / Info
    tab:CreateParagraph({
        title = (config.Name or "NYU HUB") .. " Dashboard",
        content = "Selamat datang! Silakan gunakan tab navigasi untuk mengakses fitur.",
    })

    -- Section: Tests & Examples
    tab:CreateSection({
        name = "System Check & Examples",
    })

    -- Notification Test
    tab:CreateButton({
        name = "Test Notification",
        description = "Test the NYU HUB notification system",
        callback = function()
            window:Notify({
                title = config.Name or "NYU HUB",
                content = "Foundation berhasil merespons!",
                duration = 3.5,
            })
        end,
    })

    -- Example Toggle
    tab:CreateToggle({
        name = "Example Toggle",
        description = "Sample toggle switch component",
        flag = "NyuExampleToggle",
        default = false,
        callback = function(enabled)
            print("[NYU HUB] Example Toggle:", enabled)
        end,
    })

    -- Example Slider
    tab:CreateSlider({
        name = "Example Slider",
        description = "Sample draggable value slider",
        range = { 1, 100 },
        increment = 1,
        value = 50,
        callback = function(value)
            print("[NYU HUB] Example Slider:", value)
        end,
    })

    return tab
end

return HomeTab
end

-- [[[ MODULE: UI/Tabs/SettingsTab ]]]
__modules["UI/Tabs/SettingsTab"] = function(require)
--[[
    NYU HUB - UI Settings Tab
    Displays hub configuration, version information, and window controls.
]]

local SettingsTab = {}

function SettingsTab.Create(window, config)
    local tab = window:CreateTab({
        name = config.Tabs and config.Tabs.Settings or "Settings",
    })

    -- System Info Section
    tab:CreateSection({
        name = "Hub Information",
    })

    tab:CreateParagraph({
        title = config.Name or "NYU HUB",
        content = string.format("Version: %s | %s", tostring(config.Version or "1.0.0"), tostring(config.Subtitle or "")),
    })

    tab:CreateButton({
        name = "Check Version",
        description = "Display the current NYU HUB version notification",
        callback = function()
            window:Notify({
                title = config.Name or "NYU HUB",
                content = "Running Version " .. tostring(config.Version or "1.0.0"),
                duration = 3.5,
            })
        end,
    })

    -- Window Controls Section
    tab:CreateSection({
        name = "Window Controls",
    })

    tab:CreateButton({
        name = "Toggle Window Visibility",
        description = "Hide or show the NYU HUB dashboard",
        callback = function()
            window:Toggle()
        end,
    })

    tab:CreateButton({
        name = "Unload / Destroy UI",
        description = "Safely destroy the ScreenGui from Roblox",
        callback = function()
            window:Destroy()
        end,
    })

    return tab
end

return SettingsTab
end

-- [[[ MODULE: UI/Tabs/UtilitiesTab ]]]
__modules["UI/Tabs/UtilitiesTab"] = function(require)
--[[
    NYU HUB - UI Utilities Tab
    Connects FarmCycle, WalkSpeed, TeleportPlayer, and Diagnostics features to Custom UI components.
    Provides the active status component for Logger integration.
]]

local UtilitiesTab = {}

function UtilitiesTab.Create(window, config, features, logger)
    features = features or {}

    local tab = window:CreateTab({
        name = config.Tabs and config.Tabs.Utilities or "Utilities",
    })

    -- 1. Status Display Component (Wired to Logger)
    local statusComponent = tab:CreateParagraph({
        title = "Status: " .. (logger and logger.CurrentFarmState or "IDLE"),
        content = "Target: - | Detail: Siap digunakan.",
    })

    -- 2. Auto Farm Tofu Controls
    tab:CreateSection({
        name = "Auto Farm Tofu",
    })

    local farmCycle = features.FarmCycle
    tab:CreateToggle({
        name = "Auto Farm Tofu",
        description = "Otomatisasi pengiriman tofu Fujiwara Bunta",
        default = farmCycle and farmCycle.IsEnabled and farmCycle.IsEnabled() or false,
        flag = "NyuAutoFarmTofu",
        callback = function(enabled)
            if farmCycle and farmCycle.SetAutoFarmEnabled then
                farmCycle.SetAutoFarmEnabled(enabled)
            else
                warn("[NYU HUB] FarmCycle module is not available.")
            end
        end,
    })

    -- 3. Player Movement & Navigation
    tab:CreateSection({
        name = "Player Utilities",
    })

    local wsConfig = config.WalkSpeed or {
        Minimum = 16,
        Maximum = 100,
        Increment = 1,
        Default = 16,
    }

    local walkSpeed = features.WalkSpeed
    tab:CreateSlider({
        name = "WalkSpeed",
        description = "Sesuaikan kecepatan berjalan karakter",
        range = { wsConfig.Minimum or 16, wsConfig.Maximum or 100 },
        increment = wsConfig.Increment or 1,
        value = wsConfig.Default or 16,
        callback = function(value)
            if walkSpeed and walkSpeed.SetWalkSpeed then
                walkSpeed.SetWalkSpeed(value)
            end
        end,
    })

    local teleportPlayer = features.TeleportPlayer
    tab:CreateInput({
        name = "Target Player",
        description = "Ketik username target untuk teleport",
        placeholder = "Username...",
        finished = false,
        callback = function(text)
            if teleportPlayer and teleportPlayer.SetUsername then
                teleportPlayer.SetUsername(text)
            end
        end,
    })

    tab:CreateButton({
        name = "Teleport to Player",
        description = "Lakukan teleport ke pemain yang dipilih",
        callback = function()
            if teleportPlayer and teleportPlayer.ExecuteTeleport then
                teleportPlayer.ExecuteTeleport()
            end
        end,
    })

    -- 4. Diagnostics & Inspection
    tab:CreateSection({
        name = "Diagnostics",
    })

    local diagnostics = features.Diagnostics
    tab:CreateButton({
        name = "Run Diagnostics",
        description = "Dump attribute pemain, Bunta dialogue, dan NPC",
        callback = function()
            if diagnostics and diagnostics.Run then
                diagnostics.Run()
            end
        end,
    })

    return tab, statusComponent
end

return UtilitiesTab
end

-- [[[ MODULE: UI/Theme ]]]
__modules["UI/Theme"] = function(require)
--[[
    NYU HUB - UI Theme System
    Provides modern, clean neutral design tokens and animation helpers.
]]

local TweenService = game:GetService("TweenService")

local Theme = {
    -- Color Palette (Modern Dark / Neutral Slate)
    Colors = {
        Background = Color3.fromRGB(18, 20, 24),
        BackgroundSecondary = Color3.fromRGB(24, 27, 32),
        Card = Color3.fromRGB(30, 34, 42),
        CardHover = Color3.fromRGB(38, 43, 53),
        CardActive = Color3.fromRGB(44, 50, 62),

        Sidebar = Color3.fromRGB(22, 25, 30),
        SidebarActive = Color3.fromRGB(35, 40, 50),

        Border = Color3.fromRGB(46, 52, 64),
        BorderHover = Color3.fromRGB(68, 76, 94),
        BorderActive = Color3.fromRGB(90, 100, 122),

        TextPrimary = Color3.fromRGB(243, 244, 246),
        TextSecondary = Color3.fromRGB(156, 163, 175),
        TextMuted = Color3.fromRGB(107, 114, 128),

        Accent = Color3.fromRGB(79, 140, 255),
        AccentHover = Color3.fromRGB(102, 155, 255),
        AccentMuted = Color3.fromRGB(40, 70, 130),

        Success = Color3.fromRGB(52, 211, 153),
        Warning = Color3.fromRGB(251, 191, 36),
        Danger = Color3.fromRGB(248, 113, 113),

        Track = Color3.fromRGB(38, 43, 53),
        TrackFill = Color3.fromRGB(79, 140, 255),
        Knob = Color3.fromRGB(255, 255, 255),

        Shadow = Color3.fromRGB(0, 0, 0),
    },

    -- Typography
    Fonts = {
        Heading = Enum.Font.GothamBold,
        Subheading = Enum.Font.GothamMedium,
        Body = Enum.Font.Gotham,
        Code = Enum.Font.Code,
    },

    TextSizes = {
        Title = 16,
        Subheading = 13,
        Body = 12,
        Caption = 11,
    },

    -- Sizing & Geometry
    CornerRadius = {
        Large = UDim.new(0, 10),
        Medium = UDim.new(0, 8),
        Small = UDim.new(0, 6),
        Pill = UDim.new(1, 0),
    },

    WindowSize = UDim2.new(0, 620, 0, 390),
    SidebarWidth = 160,
    HeaderHeight = 44,

    -- Transitions
    Tween = {
        Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Normal = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Slow = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    },
}

-- Helper: Tween an instance smoothly
function Theme.Animate(instance, tweenInfo, goal)
    if not instance then
        return nil
    end
    local tween = TweenService:Create(instance, tweenInfo or Theme.Tween.Normal, goal)
    tween:Play()
    return tween
end

-- Helper: Add rounded corners
function Theme.Round(instance, cornerRadius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = cornerRadius or Theme.CornerRadius.Medium
    corner.Parent = instance
    return corner
end

-- Helper: Add stroke / border
function Theme.Stroke(instance, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Colors.Border
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = instance
    return stroke
end

-- Helper: Add uniform padding
function Theme.Padding(instance, top, bottom, left, right)
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, top or 8)
    padding.PaddingBottom = UDim.new(0, bottom or top or 8)
    padding.PaddingLeft = UDim.new(0, left or 10)
    padding.PaddingRight = UDim.new(0, right or left or 10)
    padding.Parent = instance
    return padding
end

return Theme
end

-- [[[ MODULE: UI/Window ]]]
__modules["UI/Window"] = function(require)
--[[
    NYU HUB - Window System
    Custom modern window foundation without third-party library dependencies.
    Provides draggable main window, sidebar tabs, content containers, notifications, and component factories.
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local CoreGui = nil

pcall(function()
    CoreGui = game:GetService("CoreGui")
end)

-- Dynamic requires with multi-path resolution and fallback
local function resolveModule(paths)
    for _, p in ipairs(paths) do
        local success, result = pcall(function()
            if typeof(p) == "function" then
                return p()
            else
                return require(p)
            end
        end)
        if success and result then
            return result
        end
    end
    return nil
end

local Theme = resolveModule({
    function() return script.Parent.Theme end,
    "UI/Theme",
}) or {
    Colors = {
        Background = Color3.fromRGB(18, 20, 24),
        BackgroundSecondary = Color3.fromRGB(24, 27, 32),
        Card = Color3.fromRGB(30, 34, 42),
        CardHover = Color3.fromRGB(38, 43, 53),
        CardActive = Color3.fromRGB(44, 50, 62),
        Sidebar = Color3.fromRGB(22, 25, 30),
        SidebarActive = Color3.fromRGB(35, 40, 50),
        Border = Color3.fromRGB(46, 52, 64),
        BorderHover = Color3.fromRGB(68, 76, 94),
        BorderActive = Color3.fromRGB(90, 100, 122),
        TextPrimary = Color3.fromRGB(243, 244, 246),
        TextSecondary = Color3.fromRGB(156, 163, 175),
        TextMuted = Color3.fromRGB(107, 114, 128),
        Accent = Color3.fromRGB(79, 140, 255),
        Danger = Color3.fromRGB(248, 113, 113),
    },
    Fonts = {
        Heading = Enum.Font.GothamBold,
        Body = Enum.Font.Gotham,
    },
    TextSizes = {
        Title = 16,
        Body = 12,
        Caption = 11,
    },
    CornerRadius = {
        Large = UDim.new(0, 10),
        Medium = UDim.new(0, 8),
        Small = UDim.new(0, 6),
        Pill = UDim.new(1, 0),
    },
    WindowSize = UDim2.new(0, 620, 0, 390),
    SidebarWidth = 160,
    HeaderHeight = 44,
    Tween = {
        Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Normal = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    },
    Animate = function(inst, info, goal)
        local tw = game:GetService("TweenService"):Create(inst, info or TweenInfo.new(0.2), goal)
        tw:Play()
        return tw
    end,
    Round = function(inst, rad)
        local c = Instance.new("UICorner")
        c.CornerRadius = rad or UDim.new(0, 8)
        c.Parent = inst
        return c
    end,
    Stroke = function(inst, col, th, tr)
        local s = Instance.new("UIStroke")
        s.Color = col or Color3.fromRGB(46, 52, 64)
        s.Thickness = th or 1
        s.Transparency = tr or 0
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent = inst
        return s
    end,
    Padding = function(inst, top, bot, left, right)
        local p = Instance.new("UIPadding")
        p.PaddingTop = UDim.new(0, top or 8)
        p.PaddingBottom = UDim.new(0, bot or top or 8)
        p.PaddingLeft = UDim.new(0, left or 10)
        p.PaddingRight = UDim.new(0, right or left or 10)
        p.Parent = inst
        return p
    end,
}

local Button = resolveModule({
    function() return script.Parent.Components.Button end,
    "UI/Components/Button",
})

local Toggle = resolveModule({
    function() return script.Parent.Components.Toggle end,
    "UI/Components/Toggle",
})

local Slider = resolveModule({
    function() return script.Parent.Components.Slider end,
    "UI/Components/Slider",
})

local Input = resolveModule({
    function() return script.Parent.Components.Input end,
    "UI/Components/Input",
})

local Window = {}
Window.__index = Window

function Window.SetComponents(components)
    if not components then return end
    if components.Theme then Theme = components.Theme end
    if components.Button then Button = components.Button end
    if components.Toggle then Toggle = components.Toggle end
    if components.Slider then Slider = components.Slider end
    if components.Input then Input = components.Input end
end

local function getGuiParent()
    if syn and syn.protect_gui and CoreGui then
        local sg = Instance.new("ScreenGui")
        syn.protect_gui(sg)
        sg.Parent = CoreGui
        return sg, true
    elseif CoreGui then
        local success = pcall(function()
            local test = Instance.new("Folder")
            test.Parent = CoreGui
            test:Destroy()
        end)
        if success then
            return CoreGui, false
        end
    end

    local localPlayer = Players.LocalPlayer
    if localPlayer then
        return localPlayer:WaitForChild("PlayerGui"), false
    end

    return game:GetService("StarterGui"), false
end

function Window.Create(config)
    config = config or {}
    local theme = Theme

    -- ScreenGui Setup
    local parentTarget, isProtected = getGuiParent()
    local screenGui = nil

    if isProtected then
        screenGui = parentTarget
    else
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "NYU_HUB_" .. (config.Name and config.Name:gsub("%s+", "_") or "UI")
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.Parent = parentTarget
    end

    -- Main Container Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = theme.WindowSize or UDim2.new(0, 620, 0, 390)
    mainFrame.Position = UDim2.new(0.5, -310, 0.5, -195)
    mainFrame.BackgroundColor3 = theme.Colors.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = false
    mainFrame.Parent = screenGui

    theme.Round(mainFrame, theme.CornerRadius.Large)
    local windowStroke = theme.Stroke(mainFrame, theme.Colors.Border, 1)

    -- Top Header / Navigation Bar
    local headerFrame = Instance.new("Frame")
    headerFrame.Name = "Header"
    headerFrame.Size = UDim2.new(1, 0, 0, theme.HeaderHeight or 44)
    headerFrame.BackgroundColor3 = theme.Colors.BackgroundSecondary
    headerFrame.BorderSizePixel = 0
    headerFrame.Parent = mainFrame
    theme.Round(headerFrame, theme.CornerRadius.Large)

    -- Straight bottom corners for header
    local headerBottomCover = Instance.new("Frame")
    headerBottomCover.Name = "BottomCover"
    headerBottomCover.Size = UDim2.new(1, 0, 0, 10)
    headerBottomCover.Position = UDim2.new(0, 0, 1, -10)
    headerBottomCover.BackgroundColor3 = theme.Colors.BackgroundSecondary
    headerBottomCover.BorderSizePixel = 0
    headerBottomCover.Parent = headerFrame

    local headerDivider = Instance.new("Frame")
    headerDivider.Name = "Divider"
    headerDivider.Size = UDim2.new(1, 0, 0, 1)
    headerDivider.Position = UDim2.new(0, 0, 1, 0)
    headerDivider.BackgroundColor3 = theme.Colors.Border
    headerDivider.BorderSizePixel = 0
    headerDivider.Parent = headerFrame

    -- Branding (Hub Title + Subtitle)
    local brandingContainer = Instance.new("Frame")
    brandingContainer.Name = "Branding"
    brandingContainer.Size = UDim2.new(1, -100, 1, 0)
    brandingContainer.Position = UDim2.new(0, 16, 0, 0)
    brandingContainer.BackgroundTransparency = 1
    brandingContainer.Parent = headerFrame

    local brandingLayout = Instance.new("UIListLayout")
    brandingLayout.FillDirection = Enum.FillDirection.Horizontal
    brandingLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    brandingLayout.Padding = UDim.new(0, 8)
    brandingLayout.Parent = brandingContainer

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(0, 0, 1, 0)
    titleLabel.AutomaticSize = Enum.AutomaticSize.X
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = theme.Fonts.Heading
    titleLabel.Text = tostring(config.Name or "NYU HUB")
    titleLabel.TextColor3 = theme.Colors.TextPrimary
    titleLabel.TextSize = theme.TextSizes.Title
    titleLabel.Parent = brandingContainer

    local versionLabel = Instance.new("TextLabel")
    versionLabel.Name = "VersionBadge"
    versionLabel.Size = UDim2.new(0, 0, 0, 18)
    versionLabel.AutomaticSize = Enum.AutomaticSize.X
    versionLabel.BackgroundColor3 = theme.Colors.CardHover
    versionLabel.BorderSizePixel = 0
    versionLabel.Font = theme.Fonts.Body
    versionLabel.Text = "v" .. tostring(config.Version or "1.0.0")
    versionLabel.TextColor3 = theme.Colors.Accent
    versionLabel.TextSize = theme.TextSizes.Caption
    versionLabel.Parent = brandingContainer
    theme.Round(versionLabel, theme.CornerRadius.Small)
    theme.Padding(versionLabel, 0, 0, 6, 6)

    if config.Subtitle then
        local subtitleLabel = Instance.new("TextLabel")
        subtitleLabel.Name = "Subtitle"
        subtitleLabel.Size = UDim2.new(0, 0, 1, 0)
        subtitleLabel.AutomaticSize = Enum.AutomaticSize.X
        subtitleLabel.BackgroundTransparency = 1
        subtitleLabel.Font = theme.Fonts.Body
        subtitleLabel.Text = "• " .. tostring(config.Subtitle)
        subtitleLabel.TextColor3 = theme.Colors.TextMuted
        subtitleLabel.TextSize = theme.TextSizes.Caption
        subtitleLabel.Parent = brandingContainer
    end

    -- Window Controls (Minimize & Close)
    local controlsContainer = Instance.new("Frame")
    controlsContainer.Name = "Controls"
    controlsContainer.AnchorPoint = Vector2.new(1, 0.5)
    controlsContainer.Position = UDim2.new(1, -12, 0.5, 0)
    controlsContainer.Size = UDim2.new(0, 60, 0, 24)
    controlsContainer.BackgroundTransparency = 1
    controlsContainer.Parent = headerFrame

    local controlsLayout = Instance.new("UIListLayout")
    controlsLayout.FillDirection = Enum.FillDirection.Horizontal
    controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    controlsLayout.Padding = UDim.new(0, 6)
    controlsLayout.Parent = controlsContainer

    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 22, 0, 22)
    closeButton.BackgroundColor3 = theme.Colors.Card
    closeButton.BorderSizePixel = 0
    closeButton.AutoButtonColor = false
    closeButton.Font = theme.Fonts.Heading
    closeButton.Text = "✕"
    closeButton.TextColor3 = theme.Colors.TextSecondary
    closeButton.TextSize = 12
    closeButton.Parent = controlsContainer
    theme.Round(closeButton, theme.CornerRadius.Small)

    closeButton.MouseEnter:Connect(function()
        theme.Animate(closeButton, theme.Tween.Fast, {
            BackgroundColor3 = theme.Colors.Danger,
            TextColor3 = Color3.fromRGB(255, 255, 255),
        })
    end)

    closeButton.MouseLeave:Connect(function()
        theme.Animate(closeButton, theme.Tween.Fast, {
            BackgroundColor3 = theme.Colors.Card,
            TextColor3 = theme.Colors.TextSecondary,
        })
    end)

    -- Body Container
    local bodyFrame = Instance.new("Frame")
    bodyFrame.Name = "Body"
    bodyFrame.Size = UDim2.new(1, 0, 1, -theme.HeaderHeight)
    bodyFrame.Position = UDim2.new(0, 0, 0, theme.HeaderHeight)
    bodyFrame.BackgroundTransparency = 1
    bodyFrame.Parent = mainFrame

    -- Left Sidebar (Tabs List)
    local sidebarFrame = Instance.new("Frame")
    sidebarFrame.Name = "Sidebar"
    sidebarFrame.Size = UDim2.new(0, theme.SidebarWidth or 160, 1, 0)
    sidebarFrame.BackgroundColor3 = theme.Colors.Sidebar
    sidebarFrame.BorderSizePixel = 0
    sidebarFrame.Parent = bodyFrame

    -- Straighten right side of sidebar
    local sidebarRightBorder = Instance.new("Frame")
    sidebarRightBorder.Name = "BorderRight"
    sidebarRightBorder.Size = UDim2.new(0, 1, 1, 0)
    sidebarRightBorder.Position = UDim2.new(1, 0, 0, 0)
    sidebarRightBorder.BackgroundColor3 = theme.Colors.Border
    sidebarRightBorder.BorderSizePixel = 0
    sidebarRightBorder.Parent = sidebarFrame

    local sidebarScroll = Instance.new("ScrollingFrame")
    sidebarScroll.Name = "TabList"
    sidebarScroll.Size = UDim2.new(1, 0, 1, 0)
    sidebarScroll.BackgroundTransparency = 1
    sidebarScroll.BorderSizePixel = 0
    sidebarScroll.ScrollBarThickness = 2
    sidebarScroll.ScrollBarImageColor3 = theme.Colors.Border
    sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    sidebarScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sidebarScroll.Parent = sidebarFrame
    theme.Padding(sidebarScroll, 12, 12, 10, 10)

    local tabListLayout = Instance.new("UIListLayout")
    tabListLayout.FillDirection = Enum.FillDirection.Vertical
    tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabListLayout.Padding = UDim.new(0, 6)
    tabListLayout.Parent = sidebarScroll

    -- Right Content Area (Active Tab Views)
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -(theme.SidebarWidth or 160) - 1, 1, 0)
    contentArea.Position = UDim2.new(0, (theme.SidebarWidth or 160) + 1, 0, 0)
    contentArea.BackgroundTransparency = 1
    contentArea.ClipsDescendants = true
    contentArea.Parent = bodyFrame

    -- Floating Notification Area
    local notifyContainer = Instance.new("Frame")
    notifyContainer.Name = "NotificationContainer"
    notifyContainer.AnchorPoint = Vector2.new(1, 1)
    notifyContainer.Position = UDim2.new(1, -20, 1, -20)
    notifyContainer.Size = UDim2.new(0, 280, 0, 0)
    notifyContainer.AutomaticSize = Enum.AutomaticSize.Y
    notifyContainer.BackgroundTransparency = 1
    notifyContainer.Parent = screenGui

    local notifyLayout = Instance.new("UIListLayout")
    notifyLayout.FillDirection = Enum.FillDirection.Vertical
    notifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notifyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    notifyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    notifyLayout.Padding = UDim.new(0, 8)
    notifyLayout.Parent = notifyContainer

    -- Dragging System
    local isDragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    headerFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStart = input.Position
            startPos = mainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                end
            end)
        end
    end)

    headerFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and isDragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- Window instance object
    local windowInstance = setmetatable({
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        ContentArea = contentArea,
        SidebarScroll = sidebarScroll,
        NotifyContainer = notifyContainer,
        Tabs = {},
        ActiveTab = nil,
        Config = config,
        Theme = theme,
    }, Window)

    closeButton.MouseButton1Click:Connect(function()
        windowInstance:Destroy()
    end)

    return windowInstance
end

Window.new = Window.Create

-- Tab Creation Method
function Window:CreateTab(options)
    options = options or {}
    local tabName = options.name or options.title or ("Tab " .. (#self.Tabs + 1))
    local theme = self.Theme

    -- Sidebar Tab Button
    local tabButton = Instance.new("TextButton")
    tabButton.Name = "TabBtn_" .. tabName
    tabButton.Size = UDim2.new(1, 0, 0, 36)
    tabButton.BackgroundColor3 = theme.Colors.Sidebar
    tabButton.BorderSizePixel = 0
    tabButton.AutoButtonColor = false
    tabButton.Text = ""
    tabButton.Parent = self.SidebarScroll

    theme.Round(tabButton, theme.CornerRadius.Medium)
    theme.Padding(tabButton, 0, 0, 12, 12)

    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.AnchorPoint = Vector2.new(0, 0.5)
    indicator.Position = UDim2.new(0, -6, 0.5, 0)
    indicator.Size = UDim2.new(0, 3, 0, 16)
    indicator.BackgroundColor3 = theme.Colors.Accent
    indicator.BorderSizePixel = 0
    indicator.BackgroundTransparency = 1
    indicator.Parent = tabButton
    theme.Round(indicator, theme.CornerRadius.Pill)

    local tabLabel = Instance.new("TextLabel")
    tabLabel.Name = "Label"
    tabLabel.Size = UDim2.new(1, 0, 1, 0)
    tabLabel.BackgroundTransparency = 1
    tabLabel.Font = theme.Fonts.Heading
    tabLabel.Text = tabName
    tabLabel.TextColor3 = theme.Colors.TextSecondary
    tabLabel.TextSize = theme.TextSizes.Body
    tabLabel.TextXAlignment = Enum.TextXAlignment.Left
    tabLabel.Parent = tabButton

    -- Content Scroll Area for this tab
    local contentScroll = Instance.new("ScrollingFrame")
    contentScroll.Name = "Content_" .. tabName
    contentScroll.Size = UDim2.new(1, 0, 1, 0)
    contentScroll.BackgroundTransparency = 1
    contentScroll.BorderSizePixel = 0
    contentScroll.ScrollBarThickness = 3
    contentScroll.ScrollBarImageColor3 = theme.Colors.Border
    contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentScroll.Visible = false
    contentScroll.Parent = self.ContentArea
    theme.Padding(contentScroll, 14, 14, 16, 16)

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.FillDirection = Enum.FillDirection.Vertical
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.Parent = contentScroll

    local tabObject = {
        Name = tabName,
        Button = tabButton,
        Label = tabLabel,
        Indicator = indicator,
        Container = contentScroll,
        Window = self,
        Components = {},
    }

    local function activate()
        for _, otherTab in ipairs(self.Tabs) do
            if otherTab == tabObject then
                otherTab.Container.Visible = true
                theme.Animate(otherTab.Button, theme.Tween.Fast, {
                    BackgroundColor3 = theme.Colors.SidebarActive,
                })
                theme.Animate(otherTab.Label, theme.Tween.Fast, {
                    TextColor3 = theme.Colors.TextPrimary,
                })
                theme.Animate(otherTab.Indicator, theme.Tween.Fast, {
                    BackgroundTransparency = 0,
                })
            else
                otherTab.Container.Visible = false
                theme.Animate(otherTab.Button, theme.Tween.Fast, {
                    BackgroundColor3 = theme.Colors.Sidebar,
                })
                theme.Animate(otherTab.Label, theme.Tween.Fast, {
                    TextColor3 = theme.Colors.TextSecondary,
                })
                theme.Animate(otherTab.Indicator, theme.Tween.Fast, {
                    BackgroundTransparency = 1,
                })
            end
        end
        self.ActiveTab = tabObject
    end

    tabButton.MouseButton1Click:Connect(activate)

    tabButton.MouseEnter:Connect(function()
        if self.ActiveTab ~= tabObject then
            theme.Animate(tabButton, theme.Tween.Fast, {
                BackgroundColor3 = theme.Colors.CardHover,
            })
            theme.Animate(tabLabel, theme.Tween.Fast, {
                TextColor3 = theme.Colors.TextPrimary,
            })
        end
    end)

    tabButton.MouseLeave:Connect(function()
        if self.ActiveTab ~= tabObject then
            theme.Animate(tabButton, theme.Tween.Fast, {
                BackgroundColor3 = theme.Colors.Sidebar,
            })
            theme.Animate(tabLabel, theme.Tween.Fast, {
                TextColor3 = theme.Colors.TextSecondary,
            })
        end
    end)

    -- Factory methods on tab
    function tabObject:CreateButton(btnOptions)
        local btnMod = Button or resolveModule({
            function() return script.Parent.Components.Button end,
            "UI/Components/Button",
        })
        if not btnMod then
            warn("[NYU HUB] Button component module is not available.")
            return nil
        end
        local comp = btnMod.Create(contentScroll, btnOptions)
        table.insert(tabObject.Components, comp)
        return comp
    end

    function tabObject:CreateToggle(toggleOptions)
        local toggleMod = Toggle or resolveModule({
            function() return script.Parent.Components.Toggle end,
            "UI/Components/Toggle",
        })
        if not toggleMod then
            warn("[NYU HUB] Toggle component module is not available.")
            return nil
        end
        local comp = toggleMod.Create(contentScroll, toggleOptions)
        table.insert(tabObject.Components, comp)
        return comp
    end

    function tabObject:CreateSlider(sliderOptions)
        local sliderMod = Slider or resolveModule({
            function() return script.Parent.Components.Slider end,
            "UI/Components/Slider",
        })
        if not sliderMod then
            warn("[NYU HUB] Slider component module is not available.")
            return nil
        end
        local comp = sliderMod.Create(contentScroll, sliderOptions)
        table.insert(tabObject.Components, comp)
        return comp
    end

    function tabObject:CreateInput(inputOptions)
        local inputMod = Input or resolveModule({
            function() return script.Parent.Components.Input end,
            "UI/Components/Input",
        })
        if not inputMod then
            warn("[NYU HUB] Input component module is not available.")
            return nil
        end
        local comp = inputMod.Create(contentScroll, inputOptions)
        table.insert(tabObject.Components, comp)
        return comp
    end

    -- Section divider
    function tabObject:CreateSection(secOptions)
        secOptions = secOptions or {}
        local secTitle = secOptions.name or secOptions.title or "Section"

        local secFrame = Instance.new("Frame")
        secFrame.Name = "Section_" .. secTitle
        secFrame.Size = UDim2.new(1, 0, 0, 26)
        secFrame.BackgroundTransparency = 1
        secFrame.Parent = contentScroll

        local secLabel = Instance.new("TextLabel")
        secLabel.Name = "Label"
        secLabel.Size = UDim2.new(1, 0, 1, 0)
        secLabel.BackgroundTransparency = 1
        secLabel.Font = theme.Fonts.Heading
        secLabel.Text = string.upper(secTitle)
        secLabel.TextColor3 = theme.Colors.TextMuted
        secLabel.TextSize = theme.TextSizes.Caption
        secLabel.TextXAlignment = Enum.TextXAlignment.Left
        secLabel.Parent = secFrame

        local secComponent = {
            Instance = secFrame,
            SetTitle = function(_, newText)
                secLabel.Text = string.upper(tostring(newText))
            end,
            Destroy = function(_)
                secFrame:Destroy()
            end,
        }
        table.insert(tabObject.Components, secComponent)
        return secComponent
    end

    -- Paragraph / Status Component (supports SetTitle and Set)
    function tabObject:CreateParagraph(paraOptions)
        paraOptions = paraOptions or {}
        local pTitle = paraOptions.title or paraOptions.name or "Information"
        local pContent = paraOptions.content or ""

        local cardFrame = Instance.new("Frame")
        cardFrame.Name = "Card_" .. pTitle
        cardFrame.Size = UDim2.new(1, 0, 0, 58)
        cardFrame.BackgroundColor3 = theme.Colors.Card
        cardFrame.BorderSizePixel = 0
        cardFrame.Parent = contentScroll

        theme.Round(cardFrame, theme.CornerRadius.Medium)
        local stroke = theme.Stroke(cardFrame, theme.Colors.Border, 1)
        theme.Padding(cardFrame, 10, 10, 14, 14)

        local pLayout = Instance.new("UIListLayout")
        pLayout.FillDirection = Enum.FillDirection.Vertical
        pLayout.Padding = UDim.new(0, 4)
        pLayout.Parent = cardFrame

        local cardTitle = Instance.new("TextLabel")
        cardTitle.Name = "Title"
        cardTitle.Size = UDim2.new(1, 0, 0, 16)
        cardTitle.BackgroundTransparency = 1
        cardTitle.Font = theme.Fonts.Heading
        cardTitle.Text = pTitle
        cardTitle.TextColor3 = theme.Colors.TextPrimary
        cardTitle.TextSize = theme.TextSizes.Body
        cardTitle.TextXAlignment = Enum.TextXAlignment.Left
        cardTitle.Parent = cardFrame

        local cardBody = Instance.new("TextLabel")
        cardBody.Name = "Content"
        cardBody.Size = UDim2.new(1, 0, 0, 16)
        cardBody.BackgroundTransparency = 1
        cardBody.Font = theme.Fonts.Body
        cardBody.Text = pContent
        cardBody.TextColor3 = theme.Colors.TextSecondary
        cardBody.TextSize = theme.TextSizes.Caption
        cardBody.TextXAlignment = Enum.TextXAlignment.Left
        cardBody.TextTruncate = Enum.TextTruncate.AtEnd
        cardBody.Parent = cardFrame

        local paraComponent = {
            Instance = cardFrame,
            SetTitle = function(_, newTitle)
                cardTitle.Text = tostring(newTitle)
            end,
            Set = function(_, newContent)
                cardBody.Text = tostring(newContent)
            end,
            Destroy = function(_)
                cardFrame:Destroy()
            end,
        }
        table.insert(tabObject.Components, paraComponent)
        return paraComponent
    end

    table.insert(self.Tabs, tabObject)

    -- Activate automatically if it's the first tab
    if #self.Tabs == 1 then
        activate()
    end

    return tabObject
end

-- Notification System
function Window:Notify(options)
    options = options or {}
    local theme = self.Theme
    local titleText = options.title or (self.Config and self.Config.Name) or "Notification"
    local contentText = options.content or ""
    local duration = tonumber(options.duration) or 3.5

    local notifCard = Instance.new("Frame")
    notifCard.Name = "Notification"
    notifCard.Size = UDim2.new(1, 0, 0, 56)
    notifCard.BackgroundColor3 = theme.Colors.CardHover
    notifCard.BorderSizePixel = 0
    notifCard.BackgroundTransparency = 1
    notifCard.Parent = self.NotifyContainer

    theme.Round(notifCard, theme.CornerRadius.Medium)
    local stroke = theme.Stroke(notifCard, theme.Colors.Accent, 1, 1)
    theme.Padding(notifCard, 8, 8, 12, 12)

    local notifLayout = Instance.new("UIListLayout")
    notifLayout.FillDirection = Enum.FillDirection.Vertical
    notifLayout.Padding = UDim.new(0, 3)
    notifLayout.Parent = notifCard

    local notifTitle = Instance.new("TextLabel")
    notifTitle.Name = "Title"
    notifTitle.Size = UDim2.new(1, 0, 0, 16)
    notifTitle.BackgroundTransparency = 1
    notifTitle.Font = theme.Fonts.Heading
    notifTitle.Text = titleText
    notifTitle.TextColor3 = theme.Colors.TextPrimary
    notifTitle.TextSize = theme.TextSizes.Body
    notifTitle.TextTransparency = 1
    notifTitle.TextXAlignment = Enum.TextXAlignment.Left
    notifTitle.Parent = notifCard

    local notifDesc = Instance.new("TextLabel")
    notifDesc.Name = "Content"
    notifDesc.Size = UDim2.new(1, 0, 0, 16)
    notifDesc.BackgroundTransparency = 1
    notifDesc.Font = theme.Fonts.Body
    notifDesc.Text = contentText
    notifDesc.TextColor3 = theme.Colors.TextSecondary
    notifDesc.TextSize = theme.TextSizes.Caption
    notifDesc.TextTransparency = 1
    notifDesc.TextXAlignment = Enum.TextXAlignment.Left
    notifDesc.TextTruncate = Enum.TextTruncate.AtEnd
    notifDesc.Parent = notifCard

    -- Fade In
    theme.Animate(notifCard, theme.Tween.Normal, {
        BackgroundTransparency = 0,
    })
    theme.Animate(stroke, theme.Tween.Normal, {
        Transparency = 0,
    })
    theme.Animate(notifTitle, theme.Tween.Normal, {
        TextTransparency = 0,
    })
    theme.Animate(notifDesc, theme.Tween.Normal, {
        TextTransparency = 0,
    })

    -- Dismiss Timer
    task.delay(duration, function()
        if notifCard and notifCard.Parent then
            theme.Animate(notifCard, theme.Tween.Normal, {
                BackgroundTransparency = 1,
            })
            theme.Animate(stroke, theme.Tween.Normal, {
                Transparency = 1,
            })
            theme.Animate(notifTitle, theme.Tween.Normal, {
                TextTransparency = 1,
            })
            local exitTween = theme.Animate(notifDesc, theme.Tween.Normal, {
                TextTransparency = 1,
            })
            if exitTween then
                exitTween.Completed:Connect(function()
                    if notifCard and notifCard.Parent then
                        notifCard:Destroy()
                    end
                end)
            else
                notifCard:Destroy()
            end
        end
    end)
end

-- Window Visibility & Cleanup
function Window:Toggle()
    self.MainFrame.Visible = not self.MainFrame.Visible
end

function Window:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

return Window
end

-- ========================================================================
-- BOOTSTRAP ENTRYPOINT
-- ========================================================================

local initSuccess, initError = pcall(function()
    local Main = __custom_require("Main")
    if Main and Main.init then
        Main.init(__custom_require)
    else
        error("Main module does not export an init function")
    end
end)

if not initSuccess then
    _G.__NYU_HUB_LOADED = nil
    warn("[NYU HUB] Failed to start hub: " .. tostring(initError))
end
