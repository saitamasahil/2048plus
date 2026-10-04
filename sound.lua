local sound = {}
local save = require("save")

local enabled = true
local achSource = nil
local splashSource = nil
local victorySource = nil
local gameOverSource = nil
local menuMoveSource = nil
local menuSelectSource = nil
local menuBackSource = nil
local toastSource = nil

local bgmEnabled = true
local bgmPlaylist = {}
local currentBgmIdx = 0
local currentBgmSource = nil
local bgmStartDelay = 0
local duckTimer = 0
local bgmStoppedBySystem = false
local bgmPausedByUser = false

local activeJoystick = nil
local joystickInitialized = false

local function getJoystick()
    if joystickInitialized then
        return activeJoystick
    end
    if love.joystick then
        local joysticks = love.joystick.getJoysticks()
        if #joysticks > 0 then
            activeJoystick = joysticks[1]
            joystickInitialized = true
        end
    end
    return activeJoystick
end

local function triangle(phase)
    local p = phase - math.floor(phase)
    if p < 0.25 then
        return 4 * p
    elseif p < 0.75 then
        return 2 - 4 * p
    else
        return 4 * p - 4
    end
end

function sound.init()
    enabled = save.loadSound()
    pcall(getJoystick)

    -- Pre-generate the sounds so they are ready to play instantly
    if love.sound and love.audio then
        local sampleRate = 44100

        -- Achievement sound
        local achDuration = 0.6
        local achLength = math.floor(sampleRate * achDuration)
        local achSoundData = love.sound.newSoundData(achLength, sampleRate, 16, 1)
        local phase = 0
        for i = 0, achLength - 1 do
            local t = i / sampleRate
            local freq, env
            if t < 0.08 then
                freq = 523.25 -- C5
                env = math.exp(-15 * t)
            elseif t < 0.16 then
                freq = 659.25 -- E5
                env = math.exp(-15 * (t - 0.08))
            elseif t < 0.24 then
                freq = 783.99 -- G5
                env = math.exp(-15 * (t - 0.16))
            else
                freq = 1046.50 -- C6
                env = math.exp(-6 * (t - 0.24))
            end
            phase = phase + freq / sampleRate
            local val = triangle(phase) * env * 0.95
            achSoundData:setSample(i, val)
        end
        achSource = love.audio.newSource(achSoundData)
        achSource:setVolume(0.60)

        -- Splash sound
        local success, src = pcall(love.audio.newSource, "assets/sfx/logo_pop.wav", "static")
        if success then
            splashSource = src
            splashSource:setVolume(1.0)
        end

        -- Victory sound
        local victoryDuration = 1.0
        local victoryLength = math.floor(sampleRate * victoryDuration)
        local victorySoundData = love.sound.newSoundData(victoryLength, sampleRate, 16, 1)
        local vPhase = 0
        for i = 0, victoryLength - 1 do
            local t = i / sampleRate
            local freq, env
            if t < 0.07 then
                freq = 523.25 -- C5
                env = math.exp(-15 * t)
            elseif t < 0.14 then
                freq = 659.25 -- E5
                env = math.exp(-15 * (t - 0.07))
            elseif t < 0.21 then
                freq = 783.99 -- G5
                env = math.exp(-15 * (t - 0.14))
            elseif t < 0.28 then
                freq = 1046.50 -- C6
                env = math.exp(-15 * (t - 0.21))
            elseif t < 0.35 then
                freq = 1318.51 -- E6
                env = math.exp(-15 * (t - 0.28))
            elseif t < 0.42 then
                freq = 1567.98 -- G6
                env = math.exp(-15 * (t - 0.35))
            else
                freq = 2093.00 -- C7
                env = math.exp(-5 * (t - 0.42))
            end
            vPhase = vPhase + freq / sampleRate
            local val = triangle(vPhase) * env * 0.95
            victorySoundData:setSample(i, val)
        end
        victorySource = love.audio.newSource(victorySoundData)
        victorySource:setVolume(0.60)

        -- Game over sound
        local gameOverDuration = 0.8
        local gameOverLength = math.floor(sampleRate * gameOverDuration)
        local gameOverSoundData = love.sound.newSoundData(gameOverLength, sampleRate, 16, 1)
        local goPhase = 0
        for i = 0, gameOverLength - 1 do
            local t = i / sampleRate
            local freq, env
            if t < 0.2 then
                freq = 130.81 -- C3
                env = math.exp(-8 * t)
            elseif t < 0.4 then
                freq = 103.83 -- Ab2
                env = math.exp(-8 * (t - 0.2))
            else
                freq = 87.31 -- F2
                env = math.exp(-4 * (t - 0.4))
            end
            goPhase = goPhase + freq / sampleRate
            local val = triangle(goPhase) * env * 0.95
            gameOverSoundData:setSample(i, val)
        end
        gameOverSource = love.audio.newSource(gameOverSoundData)
        gameOverSource:setVolume(0.60)

        -- Menu hover sound
        local menuMoveDuration = 0.04
        local menuMoveLength = math.floor(sampleRate * menuMoveDuration)
        local menuMoveSoundData = love.sound.newSoundData(menuMoveLength, sampleRate, 16, 1)
        local mmPhase = 0
        for i = 0, menuMoveLength - 1 do
            local t = i / sampleRate
            local freq = 600
            local env = math.exp(-75 * t)
            mmPhase = mmPhase + freq / sampleRate
            local val = triangle(mmPhase) * env * 0.95
            menuMoveSoundData:setSample(i, val)
        end
        menuMoveSource = love.audio.newSource(menuMoveSoundData)
        menuMoveSource:setVolume(1.0)

        -- Menu select sound
        local menuSelectDuration = 0.13
        local menuSelectLength = math.floor(sampleRate * menuSelectDuration)
        local menuSelectSoundData = love.sound.newSoundData(menuSelectLength, sampleRate, 16, 1)
        local msPhase = 0
        for i = 0, menuSelectLength - 1 do
            local t = i / sampleRate
            local freq, env
            if t < 0.05 then
                freq = 1318.51 -- E6
                env = math.exp(-40 * t)
            else
                freq = 1760.00 -- A6
                env = math.exp(-25 * (t - 0.05))
            end
            msPhase = msPhase + freq / sampleRate
            local val = triangle(msPhase) * env * 0.95
            menuSelectSoundData:setSample(i, val)
        end
        menuSelectSource = love.audio.newSource(menuSelectSoundData)
        menuSelectSource:setVolume(0.40)

        -- Menu back sound
        local menuBackDuration = 0.13
        local menuBackLength = math.floor(sampleRate * menuBackDuration)
        local menuBackSoundData = love.sound.newSoundData(menuBackLength, sampleRate, 16, 1)
        local mbPhase = 0
        for i = 0, menuBackLength - 1 do
            local t = i / sampleRate
            local freq, env
            if t < 0.05 then
                freq = 1567.98 -- G6
                env = math.exp(-40 * t)
            else
                freq = 1174.66 -- D6
                env = math.exp(-25 * (t - 0.05))
            end
            mbPhase = mbPhase + freq / sampleRate
            local val = triangle(mbPhase) * env * 0.95
            menuBackSoundData:setSample(i, val)
        end
        menuBackSource = love.audio.newSource(menuBackSoundData)
        menuBackSource:setVolume(0.40)

        -- Toast chime sound
        local toastDuration = 0.15
        local toastLength = math.floor(sampleRate * toastDuration)
        local toastSoundData = love.sound.newSoundData(toastLength, sampleRate, 16, 1)
        local toastPhase = 0
        for i = 0, toastLength - 1 do
            local t = i / sampleRate
            local freq, env
            if t < 0.05 then
                freq = 1760.00 -- A6
                env = math.exp(-40 * t)
            else
                freq = 2093.00 -- C7
                env = math.exp(-25 * (t - 0.05))
            end
            toastPhase = toastPhase + freq / sampleRate
            local val = triangle(toastPhase) * env * 0.95
            toastSoundData:setSample(i, val)
        end
        toastSource = love.audio.newSource(toastSoundData)
        toastSource:setVolume(0.40)
    end

    enabled = save.loadSound()
    bgmEnabled = save.loadMusic()

    sound.initPlaylist()
end

local BUILTIN_TRACKS = {
    ["all night - roa .mp3"] = true,
    ["beloved - roa.mp3"] = true,
    ["chillout - audiocoffee.mp3"] = true,
    ["crescent moon - purrple cat.mp3"] = true,
    ["day off - tokyo music walker .mp3"] = true,
    ["downtown glow - ghostrifter official.mp3"] = true,
    ["embrace - roa.mp3"] = true,
    ["golden hour - purrple cat.mp3"] = true,
    ["green tea - purrple cat.mp3"] = true,
    ["journey - roa.mp3"] = true,
    ["late at night - sakura girl.mp3"] = true,
    ["missing you - purrple cat.mp3"] = true,
    ["purple dream - ghostrifter official.mp3"] = true,
    ["summer madness - roa.mp3"] = true,
    ["sunset drive - tokyo music walker.mp3"] = true,
    ["when i was a boy - tokyo music walker.mp3"] = true,
}

local server_process_running = false

function sound.initPlaylist(keepSource)
    bgmPlaylist = {}
    if not keepSource then
        currentBgmIdx = 0
        currentBgmSource = nil
    end

    -- Ensure write/save directory path exists for dynamic downloaded tracks
    love.filesystem.createDirectory("assets/music")

    local files = love.filesystem.getDirectoryItems("assets/music")
    for _, file in ipairs(files) do
        local lower = file:lower()
        if lower:match("%.mp3$") or lower:match("%.ogg$") or lower:match("%.wav$") then
            local title, artist
            local stem = file:match("^(.+)%.[^.]+$") or file
            local t_part, a_part = stem:match("^([^-]+)%s*-%s*(.+)$")
            if t_part and a_part then
                title = t_part:gsub("^%s*(.-)%s*$", "%1")
                artist = a_part:gsub("^%s*(.-)%s*$", "%1")
            else
                title = stem
                artist = "Custom Track"
            end

            local is_builtin = BUILTIN_TRACKS[lower] or false

            table.insert(bgmPlaylist, {
                path = "assets/music/" .. file,
                filename = file,
                title = title,
                artist = artist,
                is_custom = not is_builtin
            })
        end
    end

    -- Sort A-Z by title
    table.sort(bgmPlaylist, function(a, b)
        return a.title:lower() < b.title:lower()
    end)

    if not keepSource then
        currentBgmIdx = 0
    end
end

function sound.reloadPlaylist()
    local old_path = (currentBgmIdx > 0 and bgmPlaylist[currentBgmIdx]) and bgmPlaylist[currentBgmIdx].path or nil
    sound.initPlaylist(true)
    local found = false
    if old_path then
        for i, t in ipairs(bgmPlaylist) do
            if t.path == old_path then
                currentBgmIdx = i
                found = true
                break
            end
        end
    end
    if not found and old_path and currentBgmSource then
        currentBgmSource:stop()
        currentBgmSource = nil
        currentBgmIdx = 0
    end
    return #bgmPlaylist
end

local server_ip = nil
local server_port = 8048
local qr_image = nil

function sound.getQrImage()
    if qr_image then return qr_image end
    local work_dir = _G.WORK_DIR or "."
    local candidates = {
        work_dir .. "/static/web_qr.png",
        work_dir .. "/gamedata/static/web_qr.png",
        "static/web_qr.png",
        "gamedata/static/web_qr.png"
    }
    for _, qr_path in ipairs(candidates) do
        local f = io.open(qr_path, "rb")
        if f then
            local data = f:read("*all")
            f:close()
            local ok, img = pcall(function()
                local fileData = love.filesystem.newFileData(data, "qr.png")
                local imageData = love.image.newImageData(fileData)
                return love.graphics.newImage(imageData)
            end)
            if ok and img then
                qr_image = img
                return qr_image
            end
        end
    end
    return nil
end

local function is_valid_lan_ip(ip)
    if not ip or type(ip) ~= "string" or ip == "" then return false end
    local o1, o2, o3, o4 = ip:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
    if not (o1 and o2 and o3 and o4) then return false end
    o1, o2, o3, o4 = tonumber(o1), tonumber(o2), tonumber(o3), tonumber(o4)
    if not (o1 and o2 and o3 and o4) then return false end
    if o1 > 255 or o2 > 255 or o3 > 255 or o4 > 255 then return false end
    if o1 == 0 and o2 == 0 and o3 == 0 and o4 == 0 then return false end
    if o1 == 127 then return false end
    if o1 == 169 and o2 == 254 then return false end
    if o1 == 192 and o2 == 168 and o3 == 7 and o4 == 1 then return false end -- ArkOS usb gadget
    return true
end

local function is_gadget_iface(iface)
    if not iface then return true end
    iface = iface:lower()
    return iface:match("^lo") or iface:match("^usb") or iface:match("^rndis") or iface:match("^dummy")
end

function sound.isValidLanIp(ip)
    return is_valid_lan_ip(ip)
end

function sound.get_ip_address(force_refresh)
    if not force_refresh and server_ip and is_valid_lan_ip(server_ip) then
        return server_ip
    end
    for _, iface in ipairs({"wlan0", "wlan1", "mlan0", "ra0"}) do
        local h = io.popen(string.format("ip -4 addr show %s 2>/dev/null", iface))
        if h then
            local res = h:read("*a")
            h:close()
            if res then
                local candidate = res:match("inet%s+(%d+%.%d+%.%d+%.%d+)")
                if is_valid_lan_ip(candidate) then
                    server_ip = candidate
                    return candidate
                end
            end
        end
    end
    for _, iface in ipairs({"eth0", "eth1"}) do
        local h = io.popen(string.format("ip -4 addr show %s 2>/dev/null", iface))
        if h then
            local res = h:read("*a")
            h:close()
            if res then
                local candidate = res:match("inet%s+(%d+%.%d+%.%d+%.%d+)")
                if is_valid_lan_ip(candidate) then
                    server_ip = candidate
                    return candidate
                end
            end
        end
    end
    local h_all = io.popen("ip -4 -o addr show 2>/dev/null")
    if h_all then
        local res = h_all:read("*a")
        h_all:close()
        if res then
            for line in res:gmatch("[^\r\n]+") do
                local iface, ip = line:match("%d+:%s+([%w%-_]+)%s+inet%s+(%d+%.%d+%.%d+%.%d+)")
                if iface and ip and not is_gadget_iface(iface) and is_valid_lan_ip(ip) then
                    server_ip = ip
                    return ip
                end
            end
        end
    end
    local handle = io.popen("ip route get 8.8.8.8 2>/dev/null")
    if handle then
        local res = handle:read("*a")
        handle:close()
        if res then
            local dev = res:match("dev%s+([%w%-_]+)")
            local candidate = res:match("src%s+(%d+%.%d+%.%d+%.%d+)")
            if dev and not is_gadget_iface(dev) and is_valid_lan_ip(candidate) then
                server_ip = candidate
                return candidate
            end
        end
    end
    local h2 = io.popen("hostname -I 2>/dev/null")
    if h2 then
        local res = h2:read("*a")
        h2:close()
        if res then
            for token in res:gmatch("%S+") do
                if is_valid_lan_ip(token) and token ~= "192.168.7.1" then
                    server_ip = token
                    return token
                end
            end
        end
    end
    server_ip = "127.0.0.1"
    return "127.0.0.1"
end

function sound.has_wifi()
    local ip = sound.get_ip_address(true)
    if not is_valid_lan_ip(ip) then
        return false, nil
    end
    return true, ip
end

function sound.startWebServer(port)
    port = port or 8048
    local work_dir = _G.WORK_DIR or "."

    local function resolve_path(rel)
        local candidates = {
            work_dir .. "/" .. rel,
            work_dir .. "/gamedata/" .. rel,
            "gamedata/" .. rel,
            rel
        }
        for _, p in ipairs(candidates) do
            local f = io.open(p, "r")
            if f then f:close(); return p end
        end
        return work_dir .. "/" .. rel
    end

    local script_path = resolve_path("scripts/jukebox_server.py")
    local music_dir = resolve_path("assets/music")
    local font_path = resolve_path("assets/font/ClearSans-Bold.ttf")

    local static_dir = work_dir .. "/static"
    local st_check = io.open(static_dir .. "/theme.dat", "r") or io.open(static_dir .. "/theme_state.json", "r")
    if not st_check then
        local g_static = work_dir .. "/gamedata/static"
        local gst_check = io.open(g_static .. "/theme.dat", "r") or io.open(g_static .. "/theme_state.json", "r")
        if gst_check then
            gst_check:close()
            static_dir = g_static
        end
    else
        st_check:close()
    end

    local qr_path = static_dir .. "/web_qr.png"
    local theme_path = static_dir .. "/theme_state.json"

    local ok_wifi, ip = sound.has_wifi()
    if not ok_wifi then
        server_ip = "127.0.0.1"
        server_port = port
        qr_image = nil
        os.remove(qr_path)
        return "127.0.0.1", port
    end

    if server_ip ~= ip or server_port ~= port then
        qr_image = nil
    end
    server_ip = ip
    server_port = port

    -- Write initial theme state
    if renderer and renderer.applyTheme then
        renderer.applyTheme(true)
    else
        local tf = io.open(theme_path, "w")
        if tf then
            local t_name = renderer and renderer.getThemeDisplayName and renderer.getThemeDisplayName(_G.theme or "light", false) or (_G.theme or "light")
            tf:write(string.format('{"theme":"%s","name":"%s","timestamp":%d}', _G.theme or "light", t_name, os.time()))
            tf:close()
        end
    end

    os.execute("pkill -9 -f jukebox_server.py 2>/dev/null")

    local cmd = string.format('python3 "%s" --daemon --host "%s" --music-dir "%s" --port %d --qr-path "%s" --font-path "%s" --theme-file "%s" > /dev/null 2>&1',
        script_path, ip, music_dir, port, qr_path, font_path, theme_path)
    os.execute(cmd)

    server_process_running = true
    if not qr_image then
        sound.getQrImage()
    end
    return ip, port
end

function sound.stopWebServer()
    os.execute("pkill -9 -f jukebox_server.py 2>/dev/null")
    server_process_running = false
    -- Cache QR code image
    return sound.reloadPlaylist()
end

function sound.isWebServerRunning()
    return server_process_running
end


function sound.stopBgm()
    if currentBgmSource then
        currentBgmSource:stop()
        currentBgmSource = nil
    end
    currentBgmIdx = 0
    bgmStartDelay = 0
    bgmStoppedBySystem = false
    bgmPausedByUser = false
end

function sound.enterJukebox()
    sound.stopBgm()
    _G.jukebox_prev_track = nil
    _G.jukebox_eq_states = {}
    _G.jukebox_energies = {}
    _G.jukebox_peaks = {}
    _G.jukebox_disc_angle = 0
    _G.jukebox_viz_level = 0
    _G.jukebox_viz_stop_time = love.timer.getTime() - 10
    _G.jukebox_card_change_time = 0
    _G.jukebox_selection = 1
    _G.jukebox_scroll_offset = 0
    _G.jukebox_anim_sel_idx = 1
    _G.jukebox_target_scroll = 0
    _G.jukebox_just_opened = true
end

function sound.exitJukebox()
    if server_process_running then
        sound.stopWebServer()
    end
    _G.jukebox_web_modal = false
    sound.stopBgm()
    _G.jukebox_prev_track = nil
    _G.jukebox_eq_states = {}
    _G.jukebox_energies = {}
    _G.jukebox_peaks = {}
    _G.jukebox_disc_angle = 0
    _G.jukebox_viz_level = 0
    _G.jukebox_card_change_time = 0
end

function sound.startFreshGameBgm()
    if #bgmPlaylist == 0 then return end
    sound.stopBgm()

    local new_idx = love.math.random(1, #bgmPlaylist)
    if #bgmPlaylist > 1 and new_idx == currentBgmIdx then
        new_idx = (new_idx % #bgmPlaylist) + 1
    end
    currentBgmIdx = new_idx

    local track = bgmPlaylist[currentBgmIdx]

    local success, source = pcall(love.audio.newSource, track.path, "stream")
    if success and source then
        currentBgmSource = source
        currentBgmSource:setVolume(0.55)
        bgmStartDelay = 2.0
        bgmStoppedBySystem = false
        bgmPausedByUser = false
    else
        print("Failed to load music track: " .. tostring(track.path))
    end
end

function sound.playNextBgm()
    if #bgmPlaylist == 0 then return end

    bgmStoppedBySystem = false
    bgmPausedByUser = false

    if currentBgmIdx > 0 and currentBgmIdx <= #bgmPlaylist then
        _G.jukebox_prev_track = bgmPlaylist[currentBgmIdx]
    end

    if currentBgmSource then
        currentBgmSource:stop()
        currentBgmSource = nil
    end

    currentBgmIdx = currentBgmIdx + 1
    if currentBgmIdx > #bgmPlaylist then
        currentBgmIdx = 1
    end

    local track = bgmPlaylist[currentBgmIdx]
    local success, source = pcall(love.audio.newSource, track.path, "stream")
    if success and source then
        currentBgmSource = source
        currentBgmSource:setVolume(0.55)
        currentBgmSource:play()
        bgmStartDelay = 0
        _G.jukebox_card_change_time = love.timer.getTime()

        if _G.appState == "JUKEBOX" and _G.stats then
            _G.stats.played_bgm_ids = _G.stats.played_bgm_ids or {}
            local key = track.title or track.path or tostring(currentBgmIdx)
            if not _G.stats.played_bgm_ids[key] then
                _G.stats.played_bgm_ids[key] = true
                local count = 0
                for _ in pairs(_G.stats.played_bgm_ids) do count = count + 1 end
                if count >= 5 and _G.unlockAchievement then
                    _G.unlockAchievement("ach_melody_maker")
                end
                local save = require("save")
                if save and save.saveStats then save.saveStats(_G.stats) end
            end
        end
    else
        print("Failed to load music track: " .. tostring(track.path))
    end
end

function sound.playPrevBgm()
    if #bgmPlaylist == 0 then return end

    bgmStoppedBySystem = false
    bgmPausedByUser = false

    if currentBgmIdx > 0 and currentBgmIdx <= #bgmPlaylist then
        _G.jukebox_prev_track = bgmPlaylist[currentBgmIdx]
    end

    if currentBgmSource then
        currentBgmSource:stop()
        currentBgmSource = nil
    end

    currentBgmIdx = currentBgmIdx - 1
    if currentBgmIdx < 1 then
        currentBgmIdx = #bgmPlaylist
    end

    local track = bgmPlaylist[currentBgmIdx]
    local success, source = pcall(love.audio.newSource, track.path, "stream")
    if success and source then
        currentBgmSource = source
        currentBgmSource:setVolume(0.55)
        currentBgmSource:play()
        bgmStartDelay = 0
        _G.jukebox_card_change_time = love.timer.getTime()

        if _G.appState == "JUKEBOX" and _G.stats then
            _G.stats.played_bgm_ids = _G.stats.played_bgm_ids or {}
            local key = track.title or track.path or tostring(currentBgmIdx)
            if not _G.stats.played_bgm_ids[key] then
                _G.stats.played_bgm_ids[key] = true
                local count = 0
                for _ in pairs(_G.stats.played_bgm_ids) do count = count + 1 end
                if count >= 5 and _G.unlockAchievement then
                    _G.unlockAchievement("ach_melody_maker")
                end
                local save = require("save")
                if save and save.saveStats then save.saveStats(_G.stats) end
            end
        end
    else
        print("Failed to load music track: " .. tostring(track.path))
    end
end

function sound.update(dt)
    local in_game    = _G.appState == "GAME"
    local in_jukebox = _G.appState == "JUKEBOX"
    local allowed    = sound.isBgmEnabled() and (in_game or in_jukebox)

    -- Stop music on screen transition
    if not allowed then
        if currentBgmSource then
            currentBgmSource:stop()
            currentBgmSource = nil
            currentBgmIdx = 0
            bgmPausedByUser = false
        end
        return
    end

    -- Handle start delay
    if bgmStartDelay > 0 then
        bgmStartDelay = math.max(0, bgmStartDelay - dt)
        if bgmStartDelay == 0 and currentBgmSource and not bgmPausedByUser and not bgmStoppedBySystem then
            currentBgmSource:play()
            _G.jukebox_card_change_time = love.timer.getTime()
        end
    end

    -- Update ducking timer
    if duckTimer > 0 then
        duckTimer = math.max(0, duckTimer - dt)
    end

    -- Update BGM volume smoothly if BGM is active
    if currentBgmSource and currentBgmSource:isPlaying() then
        local currentVol = currentBgmSource:getVolume()
        local targetVol = 0.55
        if duckTimer > 0 then
            targetVol = 0.12
        end
        if math.abs(currentVol - targetVol) > 0.01 then
            local speed = (targetVol < currentVol) and 4 or 2
            local newVol = currentVol + (targetVol - currentVol) * math.min(1.0, speed * dt)
            currentBgmSource:setVolume(newVol)
        else
            currentBgmSource:setVolume(targetVol)
        end
    end

    if #bgmPlaylist == 0 then return end

    if currentBgmSource then
        if not currentBgmSource:isPlaying() and bgmStartDelay == 0 and not bgmPausedByUser and not bgmStoppedBySystem then
            sound.playNextBgm()
            if in_jukebox then
                _G.jukebox_selection = currentBgmIdx
            end
        end
    elseif in_game and bgmStartDelay == 0 and not bgmPausedByUser and not bgmStoppedBySystem then
        sound.startFreshGameBgm()
    end
end

function sound.isBgmEnabled()
    return bgmEnabled
end

function sound.toggleBgm()
    bgmEnabled = not bgmEnabled
    save.saveMusic(bgmEnabled)
    if not bgmEnabled then
        if currentBgmSource then
            currentBgmSource:pause()
        end
    else
        -- Only start playing immediately if we are currently in the gameplay screen
        if _G.appState == "GAME" then
            if not currentBgmSource or not currentBgmSource:isPlaying() then
                sound.playNextBgm()
            end
        end
    end
end

function sound.getCurrentTrack()
    if not bgmEnabled or #bgmPlaylist == 0 or currentBgmIdx == 0 or bgmStartDelay > 0 then
        return nil
    end
    return bgmPlaylist[currentBgmIdx]
end

function sound.getBgmPlaylist()
    return bgmPlaylist
end

function sound.getCurrentBgmIndex()
    return currentBgmIdx
end

function sound.playBgmIndex(idx)
    if #bgmPlaylist == 0 then return end
    idx = math.max(1, math.min(#bgmPlaylist, idx))
    currentBgmIdx = idx - 1
    bgmEnabled = true
    save.saveMusic(true)
    _G.jukebox_card_change_time = love.timer.getTime()
    sound.playNextBgm()
end

function sound.getBgmProgress()
    if not currentBgmSource then return 0, 0 end
    local ok_pos, pos = pcall(function() return currentBgmSource:tell("seconds") end)
    local ok_dur, dur = pcall(function() return currentBgmSource:getDuration("seconds") end)
    pos = (ok_pos and type(pos) == "number") and pos or 0
    dur = (ok_dur and type(dur) == "number" and dur > 0) and dur or 0
    return pos, dur
end

function sound.isBgmPlaying()
    return currentBgmSource ~= nil and currentBgmSource:isPlaying()
end

function sound.seekBgm(offsetSeconds)
    if not currentBgmSource then return false end
    local ok_pos, pos = pcall(function() return currentBgmSource:tell("seconds") end)
    local ok_dur, dur = pcall(function() return currentBgmSource:getDuration("seconds") end)
    if ok_pos and ok_dur and type(pos) == "number" and type(dur) == "number" and dur > 0 then
        local new_pos = math.max(0, math.min(dur - 0.5, pos + offsetSeconds))
        local ok_seek = pcall(function() currentBgmSource:seek(new_pos, "seconds") end)
        return ok_seek
    end
    return false
end

function sound.toggleBgmPause()
    if not currentBgmSource then return end
    if currentBgmSource:isPlaying() then
        currentBgmSource:pause()
        bgmPausedByUser = true
    else
        currentBgmSource:play()
        bgmPausedByUser = false
    end
end

function sound.isEnabled()
    return enabled
end

function sound.toggle()
    enabled = not enabled
    save.saveSound(enabled)
end

function sound.playAchievement()
    if enabled and achSource then
        achSource:seek(0)
        achSource:play()
        duckTimer = 1.5 -- Duck BGM for achievement sound
    end
    sound.vibrate(0.15)
end

function sound.playSplash()
    if enabled and splashSource then
        splashSource:seek(0)
        splashSource:play()
    end
end

function sound.stopSplash()
    if splashSource then
        splashSource:stop()
    end
end

function sound.playVictory()
    if enabled and victorySource then
        victorySource:seek(0)
        victorySource:play()
        duckTimer = 2.0 -- Duck BGM for victory sound
    end
    sound.vibrate(0.4)
end

function sound.playGameOver()
    if enabled and gameOverSource then
        gameOverSource:seek(0)
        gameOverSource:play()
        duckTimer = 2.5 -- Duck BGM for game over sound
    end
    sound.vibrate(0.5)
end

function sound.playMenuMove()
    if enabled and menuMoveSource then
        menuMoveSource:seek(0)
        menuMoveSource:play()
    end
end

function sound.playMenuSelect()
    if enabled and menuSelectSource then
        menuSelectSource:seek(0)
        menuSelectSource:play()
    end
end

function sound.playMenuBack()
    if enabled and menuBackSource then
        menuBackSource:seek(0)
        menuBackSource:play()
    end
end

function sound.playToast()
    if enabled and toastSource then
        toastSource:seek(0)
        toastSource:play()
    end
end

function sound.vibrate(duration)
    if not _G.vibration then return end
    local j = getJoystick()
    if j and j:isVibrationSupported() then
        j:setVibration(0.6, 0.6, duration or 0.1)
    end
end
return sound
