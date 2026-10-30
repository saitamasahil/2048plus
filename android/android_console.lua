-- android_console.lua: Virtual retro handheld controller for portrait Android display
local android_console = {}

local Game = require("game")
local renderer = require("renderer")
local input = nil
local active_touches = {}
local swipe_track = {}
local button_states = {}

-- View mode and overlay state
local android_view_mode = "console"
local screen_overlay_visible = false
local screen_overlay_timer = 0
local transition_active = false
local transition_progress = 0.0
local transition_target = 0.0
local transition_duration = 0.24
local transition_dir = 1
local custom_icons = {}
local fs_active_touches = {}
local fs_button_pressed = nil
local fs_buttons = {}
local fs_top_buttons = {}
local fs_swipe_track = {}
local fs_canvas = nil
local fs_canvas_w = 0
local fs_canvas_h = 0
local fs_tutorial_seen = false
local fs_tutorial_active = false
local fs_tutorial_time = 0.0
local console_swipe_count = 0

-- MrBreakfast animated prompts
local assets = {
    dpad = {},
    buttons = {},
}

-- Theme console color palettes
-- Classic 2048 theme colors
local theme_console_colors = {
    -- Classic 2048 Handheld
    light = {
        chassis = {0.733, 0.678, 0.627}, -- Board taupe
        bezel   = {0.467, 0.431, 0.396}, -- Slate brown
    },
    -- Dark and OLED Editions
    dark = {
        chassis = {0.180, 0.180, 0.188}, -- Stealth graphite
        bezel   = {0.105, 0.105, 0.110},
    },
    oled = {
        chassis = {0.115, 0.115, 0.120},
        bezel   = {0.045, 0.045, 0.050},
    },
    -- Victory Gold Editions
    gold = {
        chassis = {0.820, 0.678, 0.240}, -- Victory gold tile
        bezel   = {0.480, 0.380, 0.120},
    },
    retrogold = {
        chassis = {0.790, 0.650, 0.230},
        bezel   = {0.450, 0.350, 0.110},
    },
    gold_luxe = {
        chassis = {0.830, 0.690, 0.250},
        bezel   = {0.490, 0.390, 0.130},
    },
    -- Lo-Fi sepia
    lofi = {
        chassis = {0.561, 0.459, 0.380}, -- #8f7561
        bezel   = {0.341, 0.271, 0.220}, -- #574538
    },
    -- Cyberpunk / Synthwave / Neon
    cyberpunk = {
        chassis = {0.180, 0.141, 0.259}, -- #2e2442
        bezel   = {0.102, 0.071, 0.149}, -- #1a1226
    },
    synthwave = {
        chassis = {0.190, 0.145, 0.280},
        bezel   = {0.110, 0.075, 0.165},
    },
    neon = {
        chassis = {0.120, 0.157, 0.200}, -- #1f2833
        bezel   = {0.043, 0.047, 0.063}, -- #0b0c10
    },
    cyber_grid = {
        chassis = {0.130, 0.160, 0.220},
        bezel   = {0.060, 0.080, 0.120},
    },
    vaporwave = {
        chassis = {0.240, 0.180, 0.320},
        bezel   = {0.140, 0.090, 0.200},
    },
    -- Matrix
    matrix = {
        chassis = {0.095, 0.170, 0.110},
        bezel   = {0.045, 0.085, 0.055},
    },
    -- Classic Game Boy Retro
    retro = {
        chassis = {0.608, 0.737, 0.059}, -- #9bbc0f
        bezel   = {0.188, 0.384, 0.188}, -- #306230
    },
    -- Cherry / Blossom / Candy
    cherry = {
        chassis = {0.720, 0.540, 0.580},
        bezel   = {0.440, 0.300, 0.350},
    },
    cherry_blossom = {
        chassis = {0.720, 0.540, 0.580},
        bezel   = {0.440, 0.300, 0.350},
    },
    candy = {
        chassis = {0.760, 0.520, 0.650},
        bezel   = {0.480, 0.280, 0.390},
    },
    -- Ocean / Guardian
    ocean = {
        chassis = {0.110, 0.260, 0.400},
        bezel   = {0.045, 0.125, 0.220},
    },
    guardian = {
        chassis = {0.200, 0.340, 0.450},
        bezel   = {0.110, 0.210, 0.290},
    },
    -- Matcha
    matcha = {
        chassis = {0.545, 0.620, 0.460},
        bezel   = {0.320, 0.380, 0.260},
    },
    -- Sunset / Peach
    sunset = {
        chassis = {0.780, 0.520, 0.440},
        bezel   = {0.460, 0.280, 0.220},
    },
    peach = {
        chassis = {0.820, 0.600, 0.520},
        bezel   = {0.500, 0.340, 0.280},
    },
    -- Forest
    forest = {
        chassis = {0.250, 0.380, 0.280},
        bezel   = {0.140, 0.230, 0.160},
    },
    -- Dracula
    dracula = {
        chassis = {0.240, 0.220, 0.320},
        bezel   = {0.150, 0.135, 0.210},
    },
    -- Pastel
    pastel = {
        chassis = {0.740, 0.700, 0.760},
        bezel   = {0.460, 0.420, 0.490},
    },
    -- Platinum
    platinum = {
        chassis = {0.680, 0.710, 0.740},
        bezel   = {0.400, 0.430, 0.460},
    },
    -- Cosmic / Nebula / Abyss / Midnight / Eclipse
    cosmic = {
        chassis = {0.160, 0.140, 0.250},
        bezel   = {0.090, 0.075, 0.150},
    },
    nebula = {
        chassis = {0.180, 0.120, 0.240},
        bezel   = {0.100, 0.065, 0.140},
    },
    abyss = {
        chassis = {0.110, 0.130, 0.180},
        bezel   = {0.055, 0.070, 0.105},
    },
    midnight = {
        chassis = {0.120, 0.140, 0.200},
        bezel   = {0.065, 0.080, 0.120},
    },
    eclipse = {
        chassis = {0.140, 0.140, 0.160},
        bezel   = {0.075, 0.075, 0.090},
    },
    -- Volcano / Inferno
    volcano = {
        chassis = {0.450, 0.200, 0.160},
        bezel   = {0.260, 0.100, 0.080},
    },
    inferno = {
        chassis = {0.480, 0.190, 0.140},
        bezel   = {0.280, 0.095, 0.070},
    },
    -- Pawprint / Neko Night
    pawprint = {
        chassis = {0.550, 0.360, 0.300},
        bezel   = {0.330, 0.200, 0.160},
    },
    neko_night = {
        chassis = {0.200, 0.150, 0.280},
        bezel   = {0.120, 0.080, 0.170},
    },
}

local function getThemeConsoleColors(theme_name)
    if theme_name and theme_console_colors[theme_name] then
        return theme_console_colors[theme_name].chassis, theme_console_colors[theme_name].bezel
    end
    -- Query renderer dynamically if theme is custom or modded
    local r = package.loaded["renderer"] or _G.renderer
    if r and r.getThemeHighlightColors then
        local ok, _, board_col = pcall(r.getThemeHighlightColors)
        if ok and board_col and board_col[1] then
            local cr, cg, cb = board_col[1], board_col[2], board_col[3]
            return {cr, cg, cb}, {cr * 0.60, cg * 0.60, cb * 0.60}
        end
    end
    -- Fallback to Classic 2048 Taupe Board & Slate Bezel
    return theme_console_colors.light.chassis, theme_console_colors.light.bezel
end

-- Color state for theme transitions
local anim_chassis = {0.733, 0.678, 0.627}
local anim_bezel   = {0.467, 0.431, 0.396}
local last_theme_name = nil
local speaker_theme_anim_timer = 0.0
local speaker_theme_anim_dur = 0.45
local dpad_anim_alpha = 1.0
local swipe_box_anim = 0.0
local swipe_text_alpha = 1.0
local console_has_swiped = false
local last_is_gameplay = false

-- Layout geometry
local geo = {
    screen_x = 0,
    screen_y = 0,
    screen_w = 0,
    screen_h = 0,
    scale_x = 1,
    scale_y = 1,
    bezel_x = 0,
    bezel_y = 0,
    bezel_w = 0,
    bezel_h = 0,
    dpad_x = 0,
    dpad_y = 0,
    dpad_size = 0,
    dpad_r = 0,
    center_act_x = 0,
    center_act_y = 0,
    btn_size = 0,
    origin_x = 0,
    console_w = 0,
    console_h = 0,
    real_w = 0,
    real_h = 0,
    buttons = {},
    swipe_box = {x = 0, y = 0, w = 0, h = 0, r = 16},
}

local game_canvas = nil

function android_console.init(input_ref)
    input = input_ref or require("input")

    -- Initialize animated console colors immediately to match current active theme
    local init_chassis, init_bezel = getThemeConsoleColors(_G.theme or "light")
    anim_chassis = {init_chassis[1], init_chassis[2], init_chassis[3]}
    anim_bezel   = {init_bezel[1], init_bezel[2], init_bezel[3]}
    last_theme_name = _G.theme or "light"
    speaker_theme_anim_timer = 0.0


    _G.design_w = 640
    _G.design_h = 480
    _G.sx = 1.0
    _G.sy = 1.0
    _G.scale = 1.0

    _G.android_fullscreen = false
    _G.hide_game_footer = false
    _G.android_header_y = nil
    _G.android_board_y = nil
    _G.android_toast_y = nil
    custom_icons = {}

    -- Lock UI scale in portrait console mode, dynamic in landscape
    _G.update_ui_scale = function()
        if not android_console.isLandscape() then
            _G.design_w = 640
            _G.design_h = 480
            _G.sx = 1.0
            _G.sy = 1.0
            _G.scale = 1.0
            return
        end
        local rw, rh = love.graphics.getDimensions()
        _G.design_w = 640
        _G.design_h = 480
        _G.sx = rw / _G.design_w
        _G.sy = rh / _G.design_h
        _G.scale = math.min(_G.sx, _G.sy)
        if math.abs(_G.scale - 1) < 0.01 then
            _G.scale = 1
            _G.sx = 1
            _G.sy = 1
        end
    end

    -- Safe image loader with format fallback
    local function loadSafeImage(path)
        local ok, img = pcall(love.graphics.newImage, path, {mipmaps = true})
        if not ok then ok, img = pcall(love.graphics.newImage, path) end
        if not ok then
            local ok_data, idata = pcall(love.image.newImageData, path)
            if ok_data and idata then
                if idata.getFormat and idata:getFormat() ~= "rgba8" then
                    local w, h = idata:getDimensions()
                    local ok_conv, idata8 = pcall(function()
                        local d8 = love.image.newImageData(w, h, "rgba8")
                        d8:paste(idata, 0, 0, 0, 0, w, h)
                        return d8
                    end)
                    if ok_conv and idata8 then idata = idata8 end
                end
                ok, img = pcall(love.graphics.newImage, idata)
            end
        end
        if ok and img then
            pcall(function() img:setFilter("linear", "linear", 4) end)
            return img
        end
        return nil
    end

    local function loadAsset(subpath)
        return loadSafeImage("android/assets/" .. subpath) or loadSafeImage("assets/" .. subpath)
    end

    -- Load D-Pad sprites
    local dpad_names = {"cross", "cross_u", "cross_d", "cross_l", "cross_r", "cross_ul", "cross_ur", "cross_dl", "cross_dr"}
    for _, name in ipairs(dpad_names) do
        local img = loadAsset("dpad/" .. name .. ".png")
        if img then
            assets.dpad[name] = img
        end
    end

    -- Load button sprites
    local btn_names = {
        "a", "b", "x", "y",
        "a_pressed", "b_pressed", "x_pressed", "y_pressed",
        "l", "r", "select", "start",
        "l_pressed", "r_pressed", "select_pressed", "start_pressed"
    }
    for _, name in ipairs(btn_names) do
        local img = loadAsset("buttons/" .. name .. ".png")
        if img then
            assets.buttons[name] = img
        end
    end

    -- Fixed font for branding
    local ok_font, font = pcall(love.graphics.newFont, "assets/font/ClearSans-Bold.ttf", 16)
    if ok_font and font then
        assets.font_brand = font
    else
        assets.font_brand = love.graphics.newFont(16)
    end

    -- Font for action button labels
    local ok_btn_font, btn_font = pcall(love.graphics.newFont, "assets/font/ClearSans-Bold.ttf", 13)
    if ok_btn_font and btn_font then
        assets.font_btn_label = btn_font
    else
        assets.font_btn_label = love.graphics.newFont(13)
    end

    local ok_badge_font, badge_font = pcall(love.graphics.newFont, "assets/font/ClearSans-Bold.ttf", 16)
    if ok_badge_font and badge_font then
        assets.font_badge = badge_font
    else
        assets.font_badge = love.graphics.newFont(16)
    end

    -- Load saved view mode preference
    local ok_save, save = pcall(require, "save")
    if ok_save and save and save.loadAndroidViewMode then
        local saved_mode = save.loadAndroidViewMode()
        if saved_mode == "fullscreen" or saved_mode == "console" then
            android_view_mode = saved_mode
            transition_progress = (saved_mode == "fullscreen") and 1.0 or 0.0
            transition_active = false
        end
        if save.loadFullscreenTutorialSeen then
            fs_tutorial_seen = save.loadFullscreenTutorialSeen()
        end
    end
    if android_view_mode == "fullscreen" then
        fs_tutorial_seen = true
    end

    -- Support custom brand image
    for _, brand_path in ipairs({"android/assets/brand.png", "android/assets/2048_plus.png", "assets/brand.png", "assets/2048_plus.png"}) do
        local img_b = loadSafeImage(brand_path)
        if img_b then
            assets.brand_image = img_b
            break
        end
    end

    android_console.updateLayout()
end

local function emitEvent(event)
    if not event or not input then return end
    if love.keypressed then
        love.keypressed(event)
    elseif input.emit then
        if input.state then input.state[event] = true end
        input.emit(event, false)
    end
end

local function releaseEvent(event)
    if not event or not input then return end
    if input.state then input.state[event] = false end
    if love.keyreleased then
        love.keyreleased(event)
    end
end

local function triggerHaptic(duration)
    pcall(function()
        if love.system and love.system.vibrate then
            love.system.vibrate(duration or 0.015)
        end
    end)
end

function android_console.getViewMode()
    return android_view_mode
end

function android_console.setViewMode(mode)
    if mode ~= "fullscreen" and mode ~= "console" then return end
    if mode == android_view_mode and not transition_active then return end

    fs_button_pressed = nil
    for k in pairs(button_states) do button_states[k] = false end
    for _, touch in pairs(fs_active_touches) do
        if touch.btn and touch.btn.event then releaseEvent(touch.btn.event) end
        if touch.event then releaseEvent(touch.event) end
    end
    fs_active_touches = {}
    for _, touch in pairs(active_touches) do
        if touch.event then releaseEvent(touch.event) end
        if touch.type == "dpad" then
            releaseEvent(input.events.UP)
            releaseEvent(input.events.DOWN)
            releaseEvent(input.events.LEFT)
            releaseEvent(input.events.RIGHT)
        end
    end
    active_touches = {}
    fs_swipe_track = {}
    swipe_track = {}

    local is_gameplay = (_G.appState == "GAME")
    if is_gameplay then
        transition_active = true
        transition_dir = (mode == "fullscreen") and 1 or -1
        transition_target = (mode == "fullscreen") and 1.0 or 0.0
        triggerHaptic(0.02)
    else
        transition_active = false
        transition_progress = (mode == "fullscreen") and 1.0 or 0.0
    end

    android_view_mode = mode
    local ok_save, save = pcall(require, "save")
    if ok_save and save and save.saveAndroidViewMode then
        save.saveAndroidViewMode(mode)
    end
    if mode == "fullscreen" then
        fs_tutorial_seen = true
        fs_tutorial_active = false
        if ok_save and save and save.saveFullscreenTutorialSeen then
            save.saveFullscreenTutorialSeen()
        end
    end
end


function android_console.isLandscape()
    local rw, rh = love.graphics.getDimensions()
    return rw > rh
end

function android_console.isConsoleActive()
    local rw, rh = love.graphics.getDimensions()
    return rh >= rw
end

function android_console.getCanvas()
    if not game_canvas then
        game_canvas = love.graphics.newCanvas(640, 480)
        game_canvas:setFilter("linear", "linear")
    end
    return game_canvas
end

function android_console.updateLayout()
    local real_w, real_h = love.graphics.getDimensions()
    if real_w > real_h then
        -- In landscape orientation, console is inactive and fullscreen resets
        _G.android_fullscreen = false
        _G.hide_game_footer = false
        _G.android_header_y = nil
        _G.android_board_y = nil
        _G.android_toast_y = nil
        return
    end

    local origin_x = 0
    local w = real_w
    local h = real_h

    geo.origin_x = origin_x
    geo.console_w = w
    geo.console_h = h
    geo.real_w = real_w
    geo.real_h = real_h

    -- 1. Screen Bezel & Display Cutout
    -- Query hardware safe area to clear punch-hole camera or notch
    local safe_top = 0
    pcall(function()
        if love.window and love.window.getSafeArea then
            local _, sy = love.window.getSafeArea()
            if sy and sy > 0 then safe_top = sy end
        end
    end)

    local bezel_margin = math.max(6, math.floor(w * 0.022))
    local bezel_w = w - bezel_margin * 2
    local pad_x = math.max(6, math.floor(w * 0.02))
    local pad_top = math.max(18, math.floor(w * 0.048))
    local pad_bottom = math.max(30, math.floor(w * 0.082)) -- Generous chin for centered branding

    local screen_w = bezel_w - pad_x * 2
    local screen_h = math.floor(screen_w * (480 / 640))
    local screen_x = origin_x + bezel_margin + pad_x

    -- Clear punch hole camera: safe area top + minimum 5.2% screen height
    local top_margin = math.max(safe_top + math.floor(12 * (w / 390)), math.floor(h * 0.052), math.floor(36 * (w / 390)))
    local bezel_x = origin_x + bezel_margin
    local bezel_y = top_margin
    local bezel_h = screen_h + pad_top + pad_bottom
    local screen_y = bezel_y + pad_top

    geo.bezel_x = bezel_x
    geo.bezel_y = bezel_y
    geo.bezel_w = bezel_w
    geo.bezel_h = bezel_h

    geo.screen_x = screen_x
    geo.screen_y = screen_y
    geo.screen_w = screen_w
    geo.screen_h = screen_h
    geo.scale_x = screen_w / 640
    geo.scale_y = screen_h / 480

    -- Shoulder buttons below bezel
    local shoulder_y = bezel_y + bezel_h + math.floor(26 * (w / 390))
    local shoulder_w = math.floor(w * 0.19)
    local shoulder_h = math.floor(shoulder_w * (237 / 250))

    geo.buttons["l"] = {
        x = origin_x + bezel_margin + math.floor(8 * (w / 390)),
        y = shoulder_y,
        w = shoulder_w,
        h = shoulder_h,
        event = input and input.events and input.events.L1 or "l1",
        color = {0.25, 0.75, 0.95},
    }
    geo.buttons["r"] = {
        x = origin_x + w - bezel_margin - math.floor(8 * (w / 390)) - shoulder_w,
        y = shoulder_y,
        w = shoulder_w,
        h = shoulder_h,
        event = input and input.events and input.events.R1 or "r1",
        color = {0.25, 0.75, 0.95},
    }

    -- 3. Thumb Controller Area
    local ctrl_top = shoulder_y + shoulder_h + math.floor(12 * (w / 390))
    local ctrl_bottom = h - math.floor(h * 0.085)
    -- Shift D-pad and ABXY buttons up slightly for ergonomic thumb reach
    local up_shift = math.floor(18 * (h / 844))
    local ctrl_mid_y = math.floor((ctrl_top + ctrl_bottom) / 2) - up_shift

    -- D-Pad on left side
    local dpad_size = math.min(math.floor(w * 0.40), math.floor((ctrl_bottom - ctrl_top) * 0.62))
    local dpad_y = ctrl_mid_y

    -- Action buttons diamond cluster in menu mode, row during gameplay
    local btn_size = math.floor(dpad_size * 0.43)
    local center_act_x = origin_x + math.floor(w * 0.76)
    local center_act_y = ctrl_mid_y
    local offset_r = math.floor(btn_size * 0.82)

    -- Match D-pad left gap with button A right gap
    local a_right_gap = (origin_x + w) - (center_act_x + offset_r + math.floor(btn_size / 2))
    local dpad_x = origin_x + a_right_gap + math.floor(dpad_size / 2)

    geo.dpad_x = dpad_x
    geo.dpad_y = dpad_y
    geo.dpad_size = dpad_size
    geo.dpad_r = dpad_size / 2

    geo.center_act_x = center_act_x
    geo.center_act_y = center_act_y
    geo.btn_size = btn_size

    -- Calculate gameplay coordinates between L1 and R1:
    -- L1 is on left, R1 is on right. The 4 action buttons sit in a row: Y, X, B, A
    local l_x_end = geo.buttons["l"].x + shoulder_w
    local r_x_start = geo.buttons["r"].x
    local space_w = r_x_start - l_x_end
    local mid_y = shoulder_y + math.floor(shoulder_h / 2)

    local order = {"y", "x", "b", "a"}
    local game_btn_size = math.min(math.floor(shoulder_h * 0.72), math.floor(space_w * 0.21))
    local spacing = (space_w - 4 * game_btn_size) / 5
    local start_cx = l_x_end + spacing + game_btn_size / 2
    local step_cx = game_btn_size + spacing

    local game_coords = {}
    for i, name in ipairs(order) do
        game_coords[name] = {
            cx = math.floor(start_cx + (i - 1) * step_cx),
            cy = mid_y,
            sz = game_btn_size
        }
    end

    local function setBtn(name, menu_cx, menu_cy, menu_sz, game_cx, game_cy, game_sz, ev, col)
        geo.buttons[name] = {
            menu_cx = menu_cx,
            menu_cy = menu_cy,
            menu_sz = menu_sz,
            game_cx = game_cx,
            game_cy = game_cy,
            game_sz = game_sz,
            cx = menu_cx,
            cy = menu_cy,
            w = menu_sz,
            h = menu_sz,
            x = menu_cx - menu_sz / 2,
            y = menu_cy - menu_sz / 2,
            event = ev,
            color = col,
        }
    end

    -- Retro Handheld Layout: X=Top, B=Bottom, Y=Left, A=Right
    setBtn("x", center_act_x, center_act_y - offset_r, btn_size, game_coords["x"].cx, game_coords["x"].cy, game_coords["x"].sz, input and input.events and input.events.X or "x", {0.18, 0.75, 0.95})
    setBtn("b", center_act_x, center_act_y + offset_r, btn_size, game_coords["b"].cx, game_coords["b"].cy, game_coords["b"].sz, input and input.events and input.events.BACK or "backspace", {0.95, 0.38, 0.22})
    setBtn("y", center_act_x - offset_r, center_act_y, btn_size, game_coords["y"].cx, game_coords["y"].cy, game_coords["y"].sz, input and input.events and input.events.Y or "y", {0.96, 0.75, 0.18})
    setBtn("a", center_act_x + offset_r, center_act_y, btn_size, game_coords["a"].cx, game_coords["a"].cy, game_coords["a"].sz, input and input.events and input.events.CONFIRM or "return", {0.58, 0.88, 0.21})

    -- Immediately position based on current animation state so hitboxes are always valid
    local game_t = 1.0 - (dpad_anim_alpha or 1.0)
    local t_curve = game_t * game_t * (3.0 - 2.0 * game_t)
    for _, b_name in ipairs(order) do
        local btn = geo.buttons[b_name]
        if btn then
            local cx = btn.menu_cx + (btn.game_cx - btn.menu_cx) * t_curve
            local cy = btn.menu_cy + (btn.game_cy - btn.menu_cy) * t_curve
            local sz = btn.menu_sz + (btn.game_sz - btn.menu_sz) * t_curve
            btn.cx = cx
            btn.cy = cy
            btn.w = sz
            btn.h = sz
            btn.x = cx - sz / 2
            btn.y = cy - sz / 2
        end
    end

    -- Select and Start pill buttons
    local pill_w = math.floor(w * 0.20)
    local pill_h = math.floor(pill_w * (27 / 48))
    local pill_y = h - pill_h - math.floor(h * 0.034)
    local pill_gap = math.floor(w * 0.05)
    local center_pill_x = origin_x + math.floor(w / 2)

    geo.buttons["select"] = {
        x = math.floor(center_pill_x - pill_w - pill_gap / 2),
        y = pill_y,
        w = pill_w,
        h = pill_h,
        event = input and input.events and input.events.SELECT or "tab",
    }
    geo.buttons["start"] = {
        x = math.floor(center_pill_x + pill_gap / 2),
        y = pill_y,
        w = pill_w,
        h = pill_h,
        event = input and input.events and input.events.START or "space",
    }

    local pad_w = math.floor(w * 0.78)
    local pad_x = origin_x + math.floor((w - pad_w) / 2)
    local pad_top = ctrl_top + math.floor(10 * (h / 844))
    local pad_bottom = pill_y - math.floor(14 * (h / 844))
    local pad_h = pad_bottom - pad_top

    geo.swipe_box = {
        x = pad_x,
        y = pad_top,
        w = pad_w,
        h = pad_h,
        r = 16,
    }
end

-- Check D-Pad direction based on touch offset from D-pad center
local function getDpadDirection(tx, ty)
    local dx = tx - geo.dpad_x
    local dy = ty - geo.dpad_y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < geo.dpad_r * 0.18 or dist > geo.dpad_r * 1.35 then
        return nil
    end

    local angle = math.atan2(dy, dx)
    if angle < 0 then angle = angle + 2 * math.pi end

    local octant = math.floor((angle + math.pi / 8) / (math.pi / 4)) % 8
    if octant == 0 then return "r"
    elseif octant == 1 then return "dr"
    elseif octant == 2 then return "d"
    elseif octant == 3 then return "dl"
    elseif octant == 4 then return "l"
    elseif octant == 5 then return "ul"
    elseif octant == 6 then return "u"
    elseif octant == 7 then return "ur"
    end
    return nil
end

local crt_shader_code = [[
    extern vec2 screen_size;

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 cc = texture_coords - 0.5;
        float dist = dot(cc, cc);
        
        vec2 distorted_coords = cc * (1.0 + dist * 0.05) * 0.965 + 0.5;
        distorted_coords = clamp(distorted_coords, 0.0, 1.0);

        float ca = 0.0012 * (1.0 + dist * 1.5);
        float r = Texel(texture, distorted_coords - vec2(ca, 0.0)).r;
        float g = Texel(texture, distorted_coords).g;
        float b = Texel(texture, distorted_coords + vec2(ca, 0.0)).b;
        vec4 tex_color = vec4(r, g, b, 1.0);

        float scanline = sin(distorted_coords.y * screen_size.y * 1.2) * 0.045 + 0.955;
        float mask = sin(distorted_coords.x * screen_size.x * 1.5) * 0.025 + 0.975;
        float vig = smoothstep(0.70, 0.30, length(cc));
        float vignette = 0.90 + 0.10 * vig;

        return tex_color * vec4(vec3(scanline * mask * vignette), 1.0) * color;
    }
]]

local crt_shader = nil
local crt_shader_failed = false

local function getCrtShader()
    if crt_shader then return crt_shader end
    if crt_shader_failed then return nil end
    local ok, res = pcall(function()
        return love.graphics.newShader(crt_shader_code)
    end)
    if ok and res then
        crt_shader = res
        return crt_shader
    else
        crt_shader_failed = true
        return nil
    end
end

local function getBottomNavMargin(w, h)
    local safe_bottom = 0
    pcall(function()
        if love.window and love.window.getSafeArea then
            local _, sy, _, sh = love.window.getSafeArea()
            local win_h = select(2, love.graphics.getDimensions())
            if sh and sh > 0 and win_h and win_h > 0 then
                safe_bottom = math.max(0, win_h - ((sy or 0) + sh))
            end
        end
    end)
    local min_gesture_margin = math.max(math.floor(h * 0.075), math.floor(54 * (w / 390)), 50)
    return math.max(safe_bottom, min_gesture_margin)
end

local function getTopStatusBarMargin(w, h)
    local safe_top = 0
    pcall(function()
        if love.window and love.window.getSafeArea then
            local _, sy = love.window.getSafeArea()
            if sy and sy > 0 then
                safe_top = sy
            end
        end
    end)
    local min_status_margin = math.max(math.floor(h * 0.05), math.floor(36 * (w / 390)), 32)
    return math.max(safe_top, min_status_margin)
end

function android_console.touchpressed(id, x, y, dx, dy, pressure)
    if transition_active then
        return
    end

    local w, h = love.graphics.getDimensions()
    if x <= 1.0 and y <= 1.0 and w > 10 then
        x = x * w
        y = y * h
    end
    local is_gameplay = (_G.appState == "GAME")

    -- Fullscreen mode touch handling
    if is_gameplay and android_view_mode == "fullscreen" then
        local origin_x = geo.origin_x or 0
        local console_w = geo.console_w or w
        local console_h = geo.console_h or h
        local vw = 390
        local vh = math.floor(vw * (console_h / console_w))
        local vx = (x - origin_x) * (vw / console_w)
        local vy = y * (vh / console_h)

        -- Top bar pause button
        local pb = fs_top_buttons.pause
        if pb and vx >= pb.x - 4 and vx <= pb.x + pb.w + 4 and vy >= pb.y - 4 and vy <= pb.y + pb.h + 4 then
            fs_button_pressed = "pause"
            fs_active_touches[id] = {type = "top_button", id = "pause", event = input.events.START}
            emitEvent(input.events.START)
            triggerHaptic(0.018)
            return
        end

        -- Top bar console mode switch
        local cb = fs_top_buttons.console
        if cb and vx >= cb.x - 4 and vx <= cb.x + cb.w + 4 and vy >= cb.y - 4 and vy <= cb.y + cb.h + 4 then
            fs_button_pressed = "console"
            fs_active_touches[id] = {type = "top_button", id = "console", action = "console"}
            triggerHaptic(0.018)
            return
        end

        -- Bottom action buttons
        for _, btn in ipairs(fs_buttons) do
            if vx >= btn.x and vx <= btn.x + btn.w and vy >= btn.y and vy <= btn.y + btn.h then
                if not btn.disabled then
                    fs_button_pressed = btn.id
                    fs_active_touches[id] = {type = "fs_button", btn = btn}
                    if btn.action == "console" then
                        -- Dispatched on touch release
                    elseif btn.event then
                        emitEvent(btn.event)
                    end
                    triggerHaptic(0.018)
                end
                return
            end
        end

        -- Ignore swipes starting in top status bar area to prevent accidental move
        local status_margin = getTopStatusBarMargin(w, h)
        if y <= status_margin then
            return
        end

        -- Ignore swipes starting in bottom navigation bar gesture zone
        local nav_margin = getBottomNavMargin(w, h)
        if y >= h - nav_margin then
            return
        end

        -- Gesture swipe track
        fs_swipe_track[id] = {
            start_x = x,
            start_y = y,
            fired = false,
            time = love.timer.getTime(),
            vx = vx,
            vy = vy,
        }
        return
    end

    -- Ignore touches in top status bar area to prevent accidental move
    local status_margin = getTopStatusBarMargin(w, h)
    if y <= status_margin then
        return
    end

    -- Check if touch is on virtual screen
    if x >= geo.screen_x and x <= geo.screen_x + geo.screen_w and
       y >= geo.screen_y and y <= geo.screen_y + geo.screen_h then
        
        swipe_track[id] = {
            start_x = x,
            start_y = y,
            fired = false,
            time = love.timer.getTime(),
            in_screen = true,
        }
        return
    end

    -- Check D-Pad touch ONLY when NOT in gameplay and D-pad is visible
    if not is_gameplay and dpad_anim_alpha > 0.2 then
        local dpad_dir = getDpadDirection(x, y)
        if dpad_dir then
            button_states["dpad"] = dpad_dir
            active_touches[id] = {type = "dpad", dir = dpad_dir}

            if dpad_dir:find("u") then emitEvent(input.events.UP) end
            if dpad_dir:find("d") then emitEvent(input.events.DOWN) end
            if dpad_dir:find("l") then emitEvent(input.events.LEFT) end
            if dpad_dir:find("r") then emitEvent(input.events.RIGHT) end
            triggerHaptic(0.015)
            return
        end
    end

    -- Check action & shoulder buttons
    for name, btn in pairs(geo.buttons) do
        if btn.cx and btn.cy then
            local dx = x - btn.cx
            local dy = y - btn.cy
            if (dx * dx + dy * dy) <= (btn.w * 0.58) ^ 2 then
                button_states[name] = true
                active_touches[id] = {type = "button", name = name, event = btn.event}
                emitEvent(btn.event)
                triggerHaptic(0.018)
                return
            end
        elseif x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            button_states[name] = true
            active_touches[id] = {type = "button", name = name, event = btn.event}
            emitEvent(btn.event)
            triggerHaptic(0.018)
            return
        end
    end

    -- Gameplay swipe gesture area outside buttons
    if is_gameplay then
        local nav_margin = getBottomNavMargin(w, h)
        if y > status_margin and y < h - nav_margin then
            swipe_track[id] = {
                start_x = x,
                start_y = y,
                fired = false,
                time = love.timer.getTime(),
                in_screen = false,
            }
        end
    end
end

function android_console.touchmoved(id, x, y, dx, dy, pressure)
    if transition_active then
        return
    end

    local w, h = love.graphics.getDimensions()
    if x <= 1.0 and y <= 1.0 and w > 10 then
        x = x * w
        y = y * h
    end
    local is_gameplay = (_G.appState == "GAME")

    -- Fullscreen swipe tracking
    if is_gameplay and android_view_mode == "fullscreen" then
        local sw = fs_swipe_track[id]
        if sw and not sw.fired then
            local status_margin = getTopStatusBarMargin(w, h)
            if sw.start_y <= status_margin or y <= status_margin then
                return
            end
            local nav_margin = getBottomNavMargin(w, h)
            if sw.start_y >= h - nav_margin then
                return
            end
            local diff_x = x - sw.start_x
            local diff_y = y - sw.start_y
            local abs_x = math.abs(diff_x)
            local abs_y = math.abs(diff_y)
            local threshold = 24
            if abs_x > threshold or abs_y > threshold then
                sw.fired = true
                console_has_swiped = true
                local ev = nil
                if abs_x > abs_y then
                    ev = (diff_x > 0) and input.events.RIGHT or input.events.LEFT
                else
                    ev = (diff_y > 0) and input.events.DOWN or input.events.UP
                end
                if ev then
                    sw.event = ev
                    emitEvent(ev)
                    pcall(function()
                        local timer = require("timer")
                        timer.after(0.08, function()
                            releaseEvent(ev)
                            if sw and sw.event == ev then sw.event = nil end
                        end)
                    end)
                end
            end
        end
        return
    end

    -- Update D-Pad direction on slide
    local touch = active_touches[id]
    if touch and touch.type == "dpad" and not is_gameplay and dpad_anim_alpha > 0.2 then
        local new_dir = getDpadDirection(x, y)
        if new_dir and new_dir ~= button_states["dpad"] then
            releaseEvent(input.events.UP)
            releaseEvent(input.events.DOWN)
            releaseEvent(input.events.LEFT)
            releaseEvent(input.events.RIGHT)

            button_states["dpad"] = new_dir
            touch.dir = new_dir

            if new_dir:find("u") then emitEvent(input.events.UP) end
            if new_dir:find("d") then emitEvent(input.events.DOWN) end
            if new_dir:find("l") then emitEvent(input.events.LEFT) end
            if new_dir:find("r") then emitEvent(input.events.RIGHT) end
            triggerHaptic(0.012)
        elseif not new_dir and button_states["dpad"] then
            releaseEvent(input.events.UP)
            releaseEvent(input.events.DOWN)
            releaseEvent(input.events.LEFT)
            releaseEvent(input.events.RIGHT)
            button_states["dpad"] = nil
            touch.dir = nil
        end
        return
    end

    local sw = swipe_track[id]

    -- Gesture swipe or drag in Achievements
    if sw and _G.appState == "ACHIEVEMENTS" and sw.in_screen then
        local diff_y = y - (sw.last_y or sw.start_y)
        local diff_x = x - (sw.last_x or sw.start_x)
        local drag_threshold = 24
        if math.abs(diff_y) >= drag_threshold then
            local ev = (diff_y < 0) and input.events.DOWN or input.events.UP
            emitEvent(ev)
            pcall(function()
                local timer = require("timer")
                timer.after(0.08, function()
                    releaseEvent(ev)
                end)
            end)
            sw.last_y = y
            sw.last_x = x
            sw.fired = true
        elseif not sw.fired and math.abs(diff_x) >= 40 and math.abs(diff_x) > math.abs(diff_y) * 1.5 then
            local ev = (diff_x < 0) and input.events.RIGHT or input.events.LEFT
            emitEvent(ev)
            pcall(function()
                local timer = require("timer")
                timer.after(0.08, function()
                    releaseEvent(ev)
                end)
            end)
            sw.last_x = x
            sw.last_y = y
            sw.fired = true
        end
        return
    end

    -- Gesture swipe during gameplay
    if sw and not sw.fired and is_gameplay then
        local status_margin = getTopStatusBarMargin(w, h)
        if sw.start_y <= status_margin or y <= status_margin then
            return
        end
        local nav_margin = getBottomNavMargin(w, h)
        if sw.start_y >= h - nav_margin then
            return
        end
        local diff_x = x - sw.start_x
        local diff_y = y - sw.start_y
        local abs_x = math.abs(diff_x)
        local abs_y = math.abs(diff_y)

        local threshold = 24
        if abs_x > threshold or abs_y > threshold then
            sw.fired = true
            console_has_swiped = true
            screen_overlay_visible = false
            console_swipe_count = console_swipe_count + 1
            if not fs_tutorial_seen and not fs_tutorial_active and console_swipe_count >= 8 then
                fs_tutorial_active = true
                fs_tutorial_time = 0.0
            end
            local ev = nil
            if abs_x > abs_y then
                if diff_x > 0 then
                    ev = input.events.RIGHT
                else
                    ev = input.events.LEFT
                end
            else
                if diff_y > 0 then
                    ev = input.events.DOWN
                else
                    ev = input.events.UP
                end
            end
            if ev then
                sw.event = ev
                emitEvent(ev)
                -- Auto-release after brief impulse so D-pad dot highlight turns off cleanly
                pcall(function()
                    local timer = require("timer")
                    timer.after(0.08, function()
                        releaseEvent(ev)
                        if sw and sw.event == ev then sw.event = nil end
                    end)
                end)
            end
            -- Note: Haptic vibration deliberately omitted for swipe gestures
        end
    end
end


function android_console.touchreleased(id, x, y, dx, dy, pressure)
    if fs_button_pressed then fs_button_pressed = nil end

    if transition_active then
        if fs_active_touches[id] then
            local touch = fs_active_touches[id]
            if touch.btn and touch.btn.event then releaseEvent(touch.btn.event) end
            if touch.event then releaseEvent(touch.event) end
            fs_active_touches[id] = nil
        end
        if active_touches[id] then
            local touch = active_touches[id]
            if touch.event then releaseEvent(touch.event) end
            if touch.name then button_states[touch.name] = nil end
            if touch.type == "dpad" then
                button_states["dpad"] = nil
                releaseEvent(input.events.UP)
                releaseEvent(input.events.DOWN)
                releaseEvent(input.events.LEFT)
                releaseEvent(input.events.RIGHT)
            end
            active_touches[id] = nil
        end
        fs_swipe_track[id] = nil
        swipe_track[id] = nil
        return
    end

    local w, h = love.graphics.getDimensions()
    if x <= 1.0 and y <= 1.0 and w > 10 then
        x = x * w
        y = y * h
    end
    local is_gameplay = (_G.appState == "GAME")

    -- Fullscreen touch release
    if is_gameplay and android_view_mode == "fullscreen" then
        local touch = fs_active_touches[id]
        if touch then
            if touch.action == "console" or (touch.btn and touch.btn.action == "console") then
                fs_active_touches[id] = nil
                android_console.setViewMode("console")
                return
            end
            if touch.btn and touch.btn.event then releaseEvent(touch.btn.event) end
            if touch.event then releaseEvent(touch.event) end
            fs_active_touches[id] = nil
        end

        local sw = fs_swipe_track[id]
        if sw and not sw.fired then
            local dur = love.timer.getTime() - sw.time
            local dist_sq = (x - sw.start_x) ^ 2 + (y - sw.start_y) ^ 2
            if dur < 0.35 and dist_sq < 160 then
                local renderer = require("renderer")
                local r_layout = renderer.getLayout and renderer.getLayout()
                if r_layout and (_G.powerup_targeting or (_G.game and (_G.game.state == Game.STATE_TARGETING_BOMB or _G.game.state == Game.STATE_TARGETING_SWAP_1 or _G.game.state == Game.STATE_TARGETING_SWAP_2 or _G.game.state == Game.STATE_TARGETING_SHIELD))) then
                    local bx = r_layout.board_x or 16
                    local by = r_layout.board_y or 124
                    local bs = r_layout.board_size or 358
                    local gap = r_layout.cell_gap or 7
                    local csize = r_layout.cell_size or 80
                    local size = (_G.game and _G.game.size) or 4
                    if sw.vx >= bx and sw.vx <= (bx + bs) and sw.vy >= by and sw.vy <= (by + bs) then
                        local col = math.floor((sw.vx - bx - gap) / (csize + gap)) + 1
                        local row = math.floor((sw.vy - by - gap) / (csize + gap)) + 1
                        if col >= 1 and col <= size and row >= 1 and row <= size then
                            _G.target_col = col
                            _G.target_row = row
                            emitEvent(input.events.CONFIRM)
                            triggerHaptic(0.02)
                        end
                    end
                end
            end
        end
        if sw and sw.event then releaseEvent(sw.event) end
        fs_swipe_track[id] = nil
        return
    end

    -- Handle D-Pad release
    local touch = active_touches[id]
    if touch and touch.type == "dpad" then
        button_states["dpad"] = nil
        releaseEvent(input.events.UP)
        releaseEvent(input.events.DOWN)
        releaseEvent(input.events.LEFT)
        releaseEvent(input.events.RIGHT)
        active_touches[id] = nil
        return
    end

    -- Handle button release
    if touch and touch.type == "button" then
        button_states[touch.name] = nil
        releaseEvent(touch.event)
        active_touches[id] = nil
        return
    end

    -- Direct tap inside virtual screen
    local sw = swipe_track[id]
    if sw and sw.in_screen and not sw.fired then
        local dur = love.timer.getTime() - sw.time
        local dist_sq = (x - sw.start_x)^2 + (y - sw.start_y)^2
        if dur < 0.35 and dist_sq < 160 then
            local gx = (x - geo.screen_x) / geo.scale_x
            local gy = (y - geo.screen_y) / geo.scale_y

            -- Powerup tile targeting
            if _G.powerup_targeting and _G.grid and _G.grid_x and _G.grid_y and _G.cell_size then
                local col = math.floor((gx - _G.grid_x) / _G.cell_size) + 1
                local row = math.floor((gy - _G.grid_y) / _G.cell_size) + 1
                local size = _G.grid_size or 4
                if col >= 1 and col <= size and row >= 1 and row <= size then
                    _G.target_col = col
                    _G.target_row = row
                    emitEvent(input.events.CONFIRM)
                    triggerHaptic(0.02)
                    swipe_track[id] = nil
                    return
                end
            end

            -- Customization tab button tap
            if _G.appState == "THEME_SELECT" and _G.customization_tab_bounds then
                for idx, b in ipairs(_G.customization_tab_bounds) do
                    if gx >= b.x and gx <= b.x + b.w and gy >= b.y and gy <= b.y + b.h then
                        local cur_tab = _G.customization_tab or 1
                        if idx ~= cur_tab then
                            local sound = require("sound")
                            if sound and sound.playMenuMove then sound.playMenuMove() end
                            local renderer = require("renderer")
                            if cur_tab == 1 then
                                _G.theme = _G.themeSelectInitialTheme or "light"
                                if renderer.applyTheme then renderer.applyTheme(true) end
                            end
                            if idx == 1 and renderer.syncCustomThemeIndex then
                                renderer.syncCustomThemeIndex()
                            end
                            local dir = (idx > cur_tab) and 1 or -1
                            if _G.screen_transitions and renderer.startCustomizationTabTransition then
                                renderer.startCustomizationTabTransition(cur_tab, idx, dir)
                            else
                                _G.customization_tab = idx
                            end
                            triggerHaptic(0.015)
                        end
                        swipe_track[id] = nil
                        return
                    end
                end
            end

            -- Customization chevron button tap
            if _G.appState == "THEME_SELECT" then
                local pb = _G.customization_prev_btn_bounds
                if pb and gx >= pb.x and gx <= pb.x + pb.w and gy >= pb.y and gy <= pb.y + pb.h then
                    local sound = require("sound")
                    if sound and sound.playMenuMove then sound.playMenuMove() end
                    local tab = _G.customization_tab or 1
                    local renderer = require("renderer")
                    if tab == 1 then
                        if renderer.cycleCustomTheme then renderer.cycleCustomTheme(-1) end
                    elseif tab == 2 then
                        if renderer.cycleBoardSkin then renderer.cycleBoardSkin(-1) end
                    elseif tab == 3 then
                        if renderer.cyclePet then renderer.cyclePet(-1) end
                    end
                    triggerHaptic(0.015)
                    swipe_track[id] = nil
                    return
                end
                local nb = _G.customization_next_btn_bounds
                if nb and gx >= nb.x and gx <= nb.x + nb.w and gy >= nb.y and gy <= nb.y + nb.h then
                    local sound = require("sound")
                    if sound and sound.playMenuMove then sound.playMenuMove() end
                    local tab = _G.customization_tab or 1
                    local renderer = require("renderer")
                    if tab == 1 then
                        if renderer.cycleCustomTheme then renderer.cycleCustomTheme(1) end
                    elseif tab == 2 then
                        if renderer.cycleBoardSkin then renderer.cycleBoardSkin(1) end
                    elseif tab == 3 then
                        if renderer.cyclePet then renderer.cyclePet(1) end
                    end
                    triggerHaptic(0.015)
                    swipe_track[id] = nil
                    return
                end
            end

            -- Achievements tab button tap
            if _G.appState == "ACHIEVEMENTS" and _G.achievements_tab_bounds then
                for idx, b in ipairs(_G.achievements_tab_bounds) do
                    if gx >= b.x and gx <= b.x + b.w and gy >= b.y and gy <= b.y + b.h then
                        local cur_tab = _G.achievements_tab or 1
                        if idx ~= cur_tab then
                            local sound = require("sound")
                            if sound and sound.playMenuMove then sound.playMenuMove() end
                            local renderer = require("renderer")
                            if _G.screen_transitions then
                                renderer.captureOldAchievementsSlide(cur_tab)
                                _G.achievements_slide_dir = (idx > cur_tab) and 1 or -1
                                _G.achievements_slide_timer = 0.20
                                _G.achievements_slide_ready = false
                            end
                            _G.achievements_tab = idx
                            triggerHaptic(0.015)
                        end
                        swipe_track[id] = nil
                        return
                    end
                end
            end

            -- Store sort button tap
            if _G.appState == "STORE" and _G.store_sort_btn_bounds then
                local b = _G.store_sort_btn_bounds
                if gx >= b.x and gx <= (b.x + b.w) and gy >= b.y and gy <= (b.y + b.h) then
                    if _G.cycleStoreSortMode then
                        _G.cycleStoreSortMode()
                        triggerHaptic(0.02)
                    end
                    swipe_track[id] = nil
                    return
                end
            end

            -- Tap screen during gameplay to toggle overlay with full screen icon
            if is_gameplay then
                if fs_tutorial_active then
                    local btn_sz = math.floor(geo.screen_w * 0.12)
                    local btn_x = geo.screen_x + geo.screen_w - btn_sz - 8
                    local btn_y = geo.screen_y + geo.screen_h - btn_sz - 8
                    if x >= btn_x - 14 and x <= btn_x + btn_sz + 14 and y >= btn_y - 14 and y <= btn_y + btn_sz + 14 then
                        fs_tutorial_active = false
                        fs_tutorial_seen = true
                        screen_overlay_visible = false
                        android_console.setViewMode("fullscreen")
                        local ok_save, save = pcall(require, "save")
                        if ok_save and save and save.saveFullscreenTutorialSeen then
                            save.saveFullscreenTutorialSeen()
                        end
                        swipe_track[id] = nil
                        return
                    end
                end
                if screen_overlay_visible then
                    local btn_sz = math.floor(geo.screen_w * 0.12)
                    local btn_x = geo.screen_x + geo.screen_w - btn_sz - 8
                    local btn_y = geo.screen_y + geo.screen_h - btn_sz - 8
                    if x >= btn_x - 6 and x <= btn_x + btn_sz + 6 and y >= btn_y - 6 and y <= btn_y + btn_sz + 6 then
                        screen_overlay_visible = false
                        android_console.setViewMode("fullscreen")
                        swipe_track[id] = nil
                        return
                    else
                        screen_overlay_visible = false
                        triggerHaptic(0.01)
                        swipe_track[id] = nil
                        return
                    end
                else
                    screen_overlay_visible = true
                    screen_overlay_timer = 4.5
                    triggerHaptic(0.015)
                    swipe_track[id] = nil
                    return
                end
            end
        end
    end

    if sw and sw.event then
        releaseEvent(sw.event)
        sw.event = nil
    end
    swipe_track[id] = nil
end

-- Mouse emulation for desktop testing
function android_console.mousepressed(x, y, button)
    if button == 1 then
        android_console.touchpressed("mouse", x, y, 0, 0, 1)
    end
end

function android_console.mousemoved(x, y, dx, dy)
    if love.mouse.isDown(1) then
        android_console.touchmoved("mouse", x, y, dx, dy, 1)
    end
end

function android_console.mousereleased(x, y, button)
    if button == 1 then
        android_console.touchreleased("mouse", x, y, 0, 0, 1)
    end
end

-- Icon cache and loader for custom UI sprites
local icon_files = {
    pause = "pause",
    play = "play",
    console = "console",
    fullscreen = "fullscreen",
    undo = "undo",
    theme = "theme",
    bomb = "bomb",
    swap = "swap",
    restart = "restart",
    skip = "skip",
    quit = "quit",
    shield = "shield",
    confirm = "confirm",
}

local function getCustomIcon(name)
    if custom_icons[name] ~= nil then
        return custom_icons[name] or nil
    end

    local file_base = icon_files[name] or name
    local search_names = {file_base}
    if name == "console" and file_base ~= "gamepad" then
        table.insert(search_names, "gamepad")
    elseif name == "skip" and file_base ~= "music" then
        table.insert(search_names, "music")
    end

    local search_dirs = {
        "android/assets/icon/",
        "android/icon/",
        "assets/icon/",
    }

    for _, dir in ipairs(search_dirs) do
        for _, sname in ipairs(search_names) do
            local file_path = dir .. sname .. ".png"
            local info = love.filesystem.getInfo and love.filesystem.getInfo(file_path)
            if info then
                local ok_data, img_data = pcall(love.image.newImageData, file_path)
                if ok_data and img_data then
                    pcall(function()
                        img_data:mapPixel(function(x, y, r, g, b, a)
                            if a > 0 then return 1, 1, 1, a end
                            return 0, 0, 0, 0
                        end)
                    end)
                    local ok_img, img = pcall(love.graphics.newImage, img_data, {mipmaps = true})
                    if not ok_img then ok_img, img = pcall(love.graphics.newImage, img_data) end
                    if ok_img and img then
                        pcall(function() img:setFilter("linear", "linear", 4) end)
                        custom_icons[name] = img
                        return img
                    end
                else
                    local ok, img = pcall(love.graphics.newImage, file_path, {mipmaps = true})
                    if not ok then ok, img = pcall(love.graphics.newImage, file_path) end
                    if ok and img then
                        pcall(function() img:setFilter("linear", "linear", 4) end)
                        custom_icons[name] = img
                        return img
                    end
                end
            end
        end
    end

    custom_icons[name] = false
    return nil
end

-- Vector icon rendering helpers for fullscreen and overlay controls
local function drawFullscreenIcon(cx, cy, sz, col)
    love.graphics.setColor(col or {1, 1, 1, 1})
    local half = sz * 0.45
    local arm = sz * 0.28
    love.graphics.setLineWidth(math.max(2, math.floor(sz * 0.10)))
    love.graphics.line(cx - half, cy - half + arm, cx - half, cy - half, cx - half + arm, cy - half)
    love.graphics.line(cx + half - arm, cy - half, cx + half, cy - half, cx + half, cy - half + arm)
    love.graphics.line(cx - half, cy + half - arm, cx - half, cy + half, cx - half + arm, cy + half)
    love.graphics.line(cx + half - arm, cy + half, cx + half, cy + half, cx + half, cy + half - arm)
end

local function drawPauseIcon(cx, cy, sz, col)
    love.graphics.setColor(col or {1, 1, 1, 1})
    local bar_w = math.max(3, math.floor(sz * 0.22))
    local bar_h = math.floor(sz * 0.65)
    local gap = math.max(3, math.floor(sz * 0.18))
    local y = cy - bar_h / 2
    love.graphics.rectangle("fill", cx - gap / 2 - bar_w, y, bar_w, bar_h, 2, 2)
    love.graphics.rectangle("fill", cx + gap / 2, y, bar_w, bar_h, 2, 2)
end

local function drawPlayIcon(cx, cy, sz, col)
    love.graphics.setColor(col or {1, 1, 1, 1})
    local r = sz * 0.38
    love.graphics.polygon("fill", cx - r * 0.6, cy - r, cx - r * 0.6, cy + r, cx + r, cy)
end

local function drawConsoleIcon(cx, cy, sz, col)
    love.graphics.setColor(col or {1, 1, 1, 1})
    local bw = sz * 0.92
    local bh = sz * 0.54
    love.graphics.rectangle("fill", cx - bw / 2, cy - bh / 2, bw, bh, 6, 6)
    love.graphics.setColor(0.12, 0.12, 0.15, 0.85)
    local dpad_cx = cx - bw * 0.24
    local dpad_cy = cy
    local dpad_arm = sz * 0.16
    local dpad_thick = sz * 0.08
    love.graphics.rectangle("fill", dpad_cx - dpad_arm, dpad_cy - dpad_thick / 2, dpad_arm * 2, dpad_thick, 1, 1)
    love.graphics.rectangle("fill", dpad_cx - dpad_thick / 2, dpad_cy - dpad_arm, dpad_thick, dpad_arm * 2, 1, 1)
    local btn_cx = cx + bw * 0.24
    local btn_cy = cy
    local btn_r = sz * 0.065
    love.graphics.circle("fill", btn_cx - btn_r * 1.5, btn_cy, btn_r)
    love.graphics.circle("fill", btn_cx + btn_r * 1.5, btn_cy, btn_r)
end

local function drawUndoIcon(cx, cy, sz, col)
    love.graphics.setColor(col or {1, 1, 1, 1})
    local r = sz * 0.30
    love.graphics.setLineWidth(math.max(2, math.floor(sz * 0.09)))
    love.graphics.arc("line", "open", cx, cy + sz * 0.06, r, -math.pi * 0.9, math.pi * 0.3)
    local ax = cx - r * 0.9
    local ay = cy + sz * 0.06 - r * 0.4
    love.graphics.polygon("fill", ax - sz * 0.14, ay, ax + sz * 0.06, ay - sz * 0.12, ax + sz * 0.04, ay + sz * 0.12)
end

local function drawThemeIcon(cx, cy, sz, col)
    love.graphics.setColor(col or {1, 1, 1, 1})
    local r = sz * 0.38
    love.graphics.setLineWidth(math.max(2, math.floor(sz * 0.08)))
    love.graphics.circle("line", cx, cy, r)
    local dot_r = sz * 0.07
    love.graphics.circle("fill", cx - r * 0.42, cy - r * 0.3, dot_r)
    love.graphics.circle("fill", cx + r * 0.42, cy - r * 0.3, dot_r)
    love.graphics.circle("fill", cx - r * 0.25, cy + r * 0.35, dot_r)
    love.graphics.circle("fill", cx + r * 0.25, cy + r * 0.35, dot_r)
end

local function drawBombIcon(cx, cy, sz, col)
    love.graphics.setColor(col or {1, 1, 1, 1})
    local r = sz * 0.32
    love.graphics.circle("fill", cx, cy + sz * 0.08, r)
    love.graphics.rectangle("fill", cx - sz * 0.08, cy - sz * 0.30, sz * 0.16, sz * 0.08, 1, 1)
    love.graphics.setLineWidth(math.max(2, math.floor(sz * 0.08)))
    love.graphics.line(cx, cy - sz * 0.30, cx + sz * 0.16, cy - sz * 0.42)
end

local function drawSwapIcon(cx, cy, sz, col)
    love.graphics.setColor(col or {1, 1, 1, 1})
    local hw = sz * 0.36
    local y1 = cy - sz * 0.14
    local y2 = cy + sz * 0.14
    love.graphics.setLineWidth(math.max(2, math.floor(sz * 0.09)))
    love.graphics.line(cx - hw, y1, cx + hw, y1)
    love.graphics.polygon("fill", cx + hw, y1, cx + hw - sz * 0.14, y1 - sz * 0.10, cx + hw - sz * 0.14, y1 + sz * 0.10)
    love.graphics.line(cx + hw, y2, cx - hw, y2)
    love.graphics.polygon("fill", cx - hw, y2, cx - hw + sz * 0.14, y2 - sz * 0.10, cx - hw + sz * 0.14, y2 + sz * 0.10)
end

local function drawRestartIcon(cx, cy, sz, col)
    love.graphics.setColor(col or {1, 1, 1, 1})
    local r = sz * 0.32
    love.graphics.setLineWidth(math.max(2, math.floor(sz * 0.09)))
    love.graphics.arc("line", "open", cx, cy, r, -math.pi * 0.3, math.pi * 1.3)
    local ax = cx + r * math.cos(-math.pi * 0.3)
    local ay = cy + r * math.sin(-math.pi * 0.3)
    love.graphics.polygon("fill", ax + sz * 0.02, ay - sz * 0.12, ax + sz * 0.12, ay + sz * 0.04, ax - sz * 0.06, ay + sz * 0.02)
end

local function drawSkipIcon(cx, cy, sz, col)
    love.graphics.setColor(col or {1, 1, 1, 1})
    local r = sz * 0.28
    love.graphics.polygon("fill", cx - r * 1.3, cy - r, cx - r * 1.3, cy + r, cx - r * 0.2, cy)
    love.graphics.polygon("fill", cx - r * 0.2, cy - r, cx - r * 0.2, cy + r, cx + r * 0.9, cy)
    love.graphics.rectangle("fill", cx + r * 0.9 + 2, cy - r, math.max(2, math.floor(sz * 0.09)), r * 2, 1, 1)
end

local function drawQuitIcon(cx, cy, sz, col)
    love.graphics.setColor(col or {1, 1, 1, 1})
    local arm = sz * 0.26
    love.graphics.setLineWidth(math.max(2, math.floor(sz * 0.10)))
    love.graphics.line(cx - arm, cy - arm, cx + arm, cy + arm)
    love.graphics.line(cx + arm, cy - arm, cx - arm, cy + arm)
end

local function drawShieldIcon(cx, cy, sz, col)
    love.graphics.setColor(col or {1, 1, 1, 1})
    local w = sz * 0.32
    local h = sz * 0.40
    local top_y = cy - h * 0.9
    local bot_y = cy + h * 0.9
    love.graphics.polygon("fill", cx - w, top_y, cx + w, top_y, cx + w, cy + h * 0.2, cx, bot_y, cx - w, cy + h * 0.2)
end

local function drawConfirmIcon(cx, cy, sz, col)
    love.graphics.setColor(col or {1, 1, 1, 1})
    love.graphics.setLineWidth(math.max(2.5, math.floor(sz * 0.11)))
    love.graphics.line(cx - sz * 0.30, cy + sz * 0.02, cx - sz * 0.08, cy + sz * 0.24, cx + sz * 0.32, cy - sz * 0.24)
end

local function drawStarIcon(cx, cy, sz, col)
    love.graphics.setColor(col or {1, 1, 1, 1})
    local r1 = sz * 0.36
    local r2 = sz * 0.16
    local points = {}
    for i = 0, 9 do
        local angle = -math.pi / 2 + i * (math.pi / 5)
        local r = (i % 2 == 0) and r1 or r2
        table.insert(points, cx + r * math.cos(angle))
        table.insert(points, cy + r * math.sin(angle))
    end
    love.graphics.polygon("fill", points)
end

-- Draw custom sprite or procedural vector fallback
local function drawButtonIcon(name, cx, cy, sz, col)
    local img = getCustomIcon(name)
    if img then
        local iw = img:getWidth()
        local ih = img:getHeight()
        local scale = (sz * 0.90) / math.max(iw, ih)
        love.graphics.setColor(col or {1, 1, 1, 1})
        love.graphics.draw(img, cx, cy, 0, scale, scale, iw / 2, ih / 2)
        return
    end

    if name == "pause" then drawPauseIcon(cx, cy, sz, col)
    elseif name == "play" then drawPlayIcon(cx, cy, sz, col)
    elseif name == "console" then drawConsoleIcon(cx, cy, sz, col)
    elseif name == "undo" then drawUndoIcon(cx, cy, sz, col)
    elseif name == "theme" then drawThemeIcon(cx, cy, sz, col)
    elseif name == "bomb" then drawBombIcon(cx, cy, sz, col)
    elseif name == "swap" then drawSwapIcon(cx, cy, sz, col)
    elseif name == "restart" then drawRestartIcon(cx, cy, sz, col)
    elseif name == "skip" then drawSkipIcon(cx, cy, sz, col)
    elseif name == "quit" then drawQuitIcon(cx, cy, sz, col)
    elseif name == "shield" then drawShieldIcon(cx, cy, sz, col)
    elseif name == "confirm" then drawConfirmIcon(cx, cy, sz, col)
    elseif name == "star" then drawStarIcon(cx, cy, sz, col)
    else drawFullscreenIcon(cx, cy, sz, col) end
end

local touch_app_img = nil
local function drawTapIcon(cx, cy, sz, col, pulse)
    local s = sz / 40
    local p = pulse or 0
    local alpha = (col and col[4]) or 1.0
    local cr = (col and col[1]) or 0
    local cg = (col and col[2]) or 0
    local cb = (col and col[3]) or 0

    if p > 0.05 and p < 0.95 then
        local ring_r = (8 + 20 * p) * s
        local ring_a = math.max(0, (1 - p) * 0.75 * alpha)
        love.graphics.setColor(cr, cg, cb, ring_a)
        love.graphics.setLineWidth(math.max(1.5, 2.5 * s))
        love.graphics.circle("line", cx, cy, ring_r)
    end

    if touch_app_img == nil then
        local candidates = {
            "assets/icon/touch_app.png",
            "android/assets/icon/touch_app.png",
            "android/icon/touch_app.png",
        }
        for _, path in ipairs(candidates) do
            local ok_data, img_data = pcall(love.image.newImageData, path)
            if ok_data and img_data then
                pcall(function()
                    img_data:mapPixel(function(x, y, r, g, b, a)
                        if a > 0 then return 1, 1, 1, a end
                        return 0, 0, 0, 0
                    end)
                end)
                local ok, img = pcall(love.graphics.newImage, img_data)
                if ok and img then
                    pcall(function() img:setFilter("linear", "linear") end)
                    touch_app_img = img
                    break
                end
            else
                local ok, img = pcall(love.graphics.newImage, path)
                if ok and img then
                    pcall(function() img:setFilter("linear", "linear") end)
                    touch_app_img = img
                    break
                end
            end
        end
        if not touch_app_img then
            touch_app_img = false
        end
    end

    local bounce = math.sin(p * math.pi) * 3 * s

    if touch_app_img then
        local target_h = math.floor(48 * s)
        local iw, ih = touch_app_img:getDimensions()
        local img_scale = target_h / ih
        -- Touch contact point in normalized coordinates
        local ox = iw * 0.47
        local oy = ih * 0.23
        local draw_x = cx
        local draw_y = cy + bounce

        -- Subtle white border for contrast across light and dark backgrounds
        love.graphics.setColor(1, 1, 1, 0.85 * alpha)
        love.graphics.draw(touch_app_img, draw_x - 1, draw_y, 0, img_scale, img_scale, ox, oy)
        love.graphics.draw(touch_app_img, draw_x + 1, draw_y, 0, img_scale, img_scale, ox, oy)
        love.graphics.draw(touch_app_img, draw_x, draw_y - 1, 0, img_scale, img_scale, ox, oy)
        love.graphics.draw(touch_app_img, draw_x, draw_y + 1, 0, img_scale, img_scale, ox, oy)

        -- Black icon
        love.graphics.setColor(cr, cg, cb, alpha)
        love.graphics.draw(touch_app_img, draw_x, draw_y, 0, img_scale, img_scale, ox, oy)
    else
        love.graphics.push()
        love.graphics.translate(cx, cy)
        love.graphics.rotate(math.rad(36))
        love.graphics.translate(0, bounce)

        -- Subtle white border for procedural fallback
        love.graphics.setColor(1, 1, 1, 0.75 * alpha)
        love.graphics.rectangle("fill", -5 * s, -1 * s, 10 * s, 26 * s, 4 * s, 4 * s)
        love.graphics.rectangle("fill", -2 * s, 11 * s, 18 * s, 22 * s, 5 * s, 5 * s)

        love.graphics.setColor(cr, cg, cb, alpha)
        love.graphics.rectangle("fill", -4 * s, 0, 8 * s, 24 * s, 4 * s, 4 * s)
        love.graphics.rectangle("fill", -1 * s, 12 * s, 16 * s, 20 * s, 5 * s, 5 * s)
        love.graphics.rectangle("fill", -7 * s, 16 * s, 7 * s, 12 * s, 3.5 * s, 3.5 * s)
        love.graphics.pop()
    end
end

local function drawTutorialPill(text, cx, cy, alpha)
    local f = assets.font_btn_label or love.graphics.getFont()
    love.graphics.setFont(f)
    local tw = f:getWidth(text)
    local th = f:getHeight()
    local pw = tw + 20
    local ph = th + 10
    local px = math.floor(cx - pw / 2)
    local py = math.floor(cy - ph / 2)

    love.graphics.setColor(0, 0, 0, 0.35 * alpha)
    love.graphics.rectangle("fill", px, py + 1, pw, ph, 8, 8)

    love.graphics.setColor(0.12, 0.12, 0.16, 0.92 * alpha)
    love.graphics.rectangle("fill", px, py, pw, ph, 8, 8)

    love.graphics.setColor(1, 1, 1, 0.25 * alpha)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", px, py, pw, ph, 8, 8)

    love.graphics.setColor(1, 1, 1, 0.95 * alpha)
    love.graphics.print(text, px + 10, py + 5)
end

local function drawFullscreenTutorial(dt)
    if not fs_tutorial_active or not geo or not geo.screen_w then return end

    fs_tutorial_time = fs_tutorial_time + dt
    local loop_duration = 3.6
    local t = fs_tutorial_time % loop_duration

    local scx = math.floor(geo.screen_x + geo.screen_w / 2)
    local scy = math.floor(geo.screen_y + geo.screen_h / 2)

    local btn_sz = math.floor(geo.screen_w * 0.12)
    local btn_x = geo.screen_x + geo.screen_w - btn_sz - 8
    local btn_y = geo.screen_y + geo.screen_h - btn_sz - 8
    local target_x = math.floor(btn_x + btn_sz / 2)
    local target_y = math.floor(btn_y + btn_sz / 2)

    local btn_alpha = 1.0
    if t < 0.6 then
        btn_alpha = math.min(1.0, 0.4 + 0.6 * (t / 0.6))
    elseif t > 3.0 then
        btn_alpha = math.max(0.4, (3.5 - t) / 0.5)
    end

    love.graphics.setColor(0.12, 0.12, 0.16, 0.92 * btn_alpha)
    love.graphics.rectangle("fill", btn_x, btn_y, btn_sz, btn_sz, 8, 8)
    love.graphics.setColor(1, 1, 1, 0.50 * btn_alpha)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", btn_x, btn_y, btn_sz, btn_sz, 8, 8)
    drawButtonIcon("fullscreen", target_x, target_y, btn_sz * 0.65, {1, 1, 1, 0.95 * btn_alpha})

    if t < 1.1 then
        local alpha = math.min(1.0, t / 0.25)
        local pulse = (t % 0.55) / 0.55
        drawTutorialPill("Tap screen for Fullscreen", scx, scy - 48, alpha)
        drawTapIcon(scx, scy, 36, {0, 0, 0, alpha}, pulse)
    elseif t < 1.8 then
        local p = (t - 1.1) / 0.7
        local p_ease = p * p * (3 - 2 * p)
        local fx = math.floor(scx + (target_x - scx) * p_ease)
        local fy = math.floor(scy + (target_y - scy) * p_ease)
        drawTapIcon(fx, fy, 36, {0, 0, 0, 1.0}, 0)
    elseif t < 3.0 then
        local pulse = ((t - 1.8) % 0.6) / 0.6
        local glow = 0.5 + 0.5 * math.sin((t - 1.8) * 8)
        love.graphics.setColor(0.96, 0.72, 0.22, glow)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", btn_x - 3, btn_y - 3, btn_sz + 6, btn_sz + 6, 10, 10)

        local pill_cx = math.max(geo.screen_x + 90, btn_x - 76)
        drawTutorialPill("Play in Fullscreen", pill_cx, target_y, 1.0)
        drawTapIcon(target_x, target_y, 36, {0, 0, 0, 1.0}, pulse)
    else
        local fade = math.max(0, (3.4 - t) / 0.4)
        if fade > 0 then
            drawTapIcon(target_x, target_y, 36, {0, 0, 0, fade}, 0)
        end
    end
end

-- Resolve dynamic touch action buttons based on gameplay state
local function getFullscreenButtons(game)
    local buttons = {}
    if not game then return buttons end

    if game.state == Game.STATE_PAUSED then
        table.insert(buttons, {id = "resume", label = "Resume", icon = "play", event = input.events.START})
        table.insert(buttons, {id = "restart", label = "Restart", icon = "restart", event = input.events.CONFIRM})
        local ok_snd, sound = pcall(require, "sound")
        if ok_snd and sound and sound.isBgmEnabled and sound.isBgmEnabled() then
            table.insert(buttons, {id = "skip", label = "Skip Track", icon = "skip", event = input.events.L1})
        end
        table.insert(buttons, {id = "quit", label = "Quit", icon = "quit", event = input.events.X})

    elseif game.state == Game.STATE_LOST then
        table.insert(buttons, {id = "restart", label = "New Game", icon = "restart", event = input.events.CONFIRM})
        local shield_cnt = _G.stats and (_G.stats.second_chance_count or 0) or 0
        if shield_cnt > 0 and not game.timesUp and not (game.mode == "timeattack" and game.timeLeft and game.timeLeft <= 0) then
            table.insert(buttons, {id = "shield", label = "Shield", badge = tostring(shield_cnt), icon = "shield", event = input.events.R1})
        end
        if game.mode ~= "timeattack" and game.mode ~= "nomercy" and game.mode ~= "goose" and game.canUndo then
            local badge = (game.mode == "plus" and game.powerups and tostring(game.powerups.undo)) or nil
            table.insert(buttons, {id = "undo", label = "Undo", badge = badge, icon = "undo", event = input.events.BACK})
        end
        table.insert(buttons, {id = "quit", label = "Quit", icon = "quit", event = input.events.X})

    elseif game.state == Game.STATE_WON then
        table.insert(buttons, {id = "continue", label = "Continue", icon = "play", event = input.events.CONFIRM})
        table.insert(buttons, {id = "restart", label = "Restart", icon = "restart", event = input.events.SELECT})
        if game.canUndo then
            local badge = (game.mode == "plus" and game.powerups and tostring(game.powerups.undo)) or nil
            table.insert(buttons, {id = "undo", label = "Undo", badge = badge, icon = "undo", event = input.events.BACK})
        end
        table.insert(buttons, {id = "quit", label = "Quit", icon = "quit", event = input.events.X})

    elseif game.state == Game.STATE_TARGETING_BOMB or game.state == Game.STATE_TARGETING_SWAP_1 or game.state == Game.STATE_TARGETING_SWAP_2 or game.state == Game.STATE_TARGETING_SHIELD then
        table.insert(buttons, {id = "confirm", label = "Confirm", icon = "confirm", event = input.events.CONFIRM})
        table.insert(buttons, {id = "cancel", label = "Cancel", icon = "quit", event = input.events.BACK})

    else
        if game.mode == "plus" then
            local u_cnt = (game.powerups and game.powerups.undo) or 0
            local s_cnt = (game.powerups and game.powerups.swap) or 0
            local b_cnt = (game.powerups and game.powerups.bomb) or 0
            table.insert(buttons, {id = "undo", label = "Undo", badge = tostring(u_cnt), icon = "undo", event = input.events.BACK, disabled = (u_cnt <= 0)})
            table.insert(buttons, {id = "bomb", label = "Bomb", badge = tostring(b_cnt), icon = "bomb", event = input.events.R1, disabled = (b_cnt <= 0)})
            table.insert(buttons, {id = "swap", label = "Swap", badge = tostring(s_cnt), icon = "swap", event = input.events.L1, disabled = (s_cnt <= 0)})
            table.insert(buttons, {id = "theme", label = "Theme", icon = "theme", event = input.events.Y})
        else
            if game.mode ~= "timeattack" and game.mode ~= "nomercy" and game.mode ~= "goose" then
                table.insert(buttons, {id = "undo", label = "Undo", icon = "undo", event = input.events.BACK, disabled = not game.canUndo})
            end
            table.insert(buttons, {id = "theme", label = "Theme", icon = "theme", event = input.events.Y})
        end
    end

    return buttons
end

-- Render fullscreen board and touch controls
function android_console.drawFullscreen(game_draw_fn, dt, ui_anim_t, only_render_canvas)
    local real_w, real_h = love.graphics.getDimensions()
    local origin_x = geo.origin_x or 0
    local console_w = geo.console_w or real_w
    local console_h = geo.console_h or real_h
    local vw = 390
    local vh = math.floor(vw * (console_h / console_w))
    local scale_fs_x = console_w / vw
    local scale_fs_y = console_h / vh
    _G.android_fs_vw = vw
    _G.android_fs_vh = vh

    if not fs_canvas or fs_canvas_w ~= vw or fs_canvas_h ~= vh then
        fs_canvas = love.graphics.newCanvas(vw, vh)
        fs_canvas:setFilter("linear", "linear")
        fs_canvas_w = vw
        fs_canvas_h = vh
    end

    local safe_top = 0
    pcall(function()
        if love.window and love.window.getSafeArea then
            local _, sy = love.window.getSafeArea()
            if sy and sy > 0 then safe_top = sy end
        end
    end)
    local virt_safe_top = math.max(12, math.floor(safe_top / scale_fs_y))

    local board_sz = 358
    local ideal_board_y = math.floor((vh - board_sz) / 2)
    local min_board_y = virt_safe_top + 110
    _G.android_board_y = math.max(min_board_y, ideal_board_y)

    local box_h = (_G.text_size == "large" and 56 or 48)
    local ideal_header_y = _G.android_board_y - box_h - 20
    _G.android_header_y = math.max(virt_safe_top + 42, ideal_header_y)
    _G.android_toast_y = virt_safe_top + 46

    _G.android_fullscreen = true
    _G.hide_game_footer = true
    _G.scale = 1.0

    love.graphics.setCanvas({fs_canvas, stencil = true})
    love.graphics.clear(0, 0, 0, 1)

    local real_getDimensions = love.graphics.getDimensions
    local real_getWidth = love.graphics.getWidth
    local real_getHeight = love.graphics.getHeight

    love.graphics.getDimensions = function() return vw, vh end
    love.graphics.getWidth = function() return vw end
    love.graphics.getHeight = function() return vh end

    game_draw_fn()

    love.graphics.getDimensions = real_getDimensions
    love.graphics.getWidth = real_getWidth
    love.graphics.getHeight = real_getHeight

    local anim_t = ui_anim_t or 1.0
    local top_slide = (1 - anim_t) * (-50)
    local top_alpha = math.min(1.0, anim_t * 1.5)
    local bottom_slide = (1 - anim_t) * 70
    local bottom_alpha = math.min(1.0, anim_t * 1.5)

    local renderer = require("renderer")
    local s_bg, s_lbl, s_val, ui_txt = renderer.getScoreBoxColors()
    if not s_bg then s_bg = {0.73, 0.68, 0.63, 0.95} end
    if not s_val then s_val = {1, 1, 1, 1} end
    if not ui_txt then ui_txt = {0.95, 0.95, 0.95, 0.95} end

    local br = s_bg[1] or 0.73
    local bg = s_bg[2] or 0.68
    local bb = s_bg[3] or 0.63

    local btn_content_col = renderer.getContrastTextColor(s_bg, ui_txt, {0.18, 0.16, 0.14, 1})

    -- Top bar controls
    local y_bar = virt_safe_top + 4 + top_slide
    local p_x = 16
    local p_y = y_bar
    local p_w = 40
    local p_h = 34
    fs_top_buttons.pause = { x = p_x, y = p_y, w = p_w, h = p_h }

    local is_pause_pressed = (fs_button_pressed == "pause")
    local p_offset = is_pause_pressed and 1.5 or 0
    if is_pause_pressed then
        love.graphics.setColor(br * 0.82, bg * 0.82, bb * 0.82, 0.95 * top_alpha)
    else
        love.graphics.setColor(br, bg, bb, 0.92 * top_alpha)
    end
    love.graphics.rectangle("fill", p_x, p_y + p_offset, p_w, p_h, 8, 8)
    love.graphics.setColor(1, 1, 1, 0.18 * top_alpha)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", p_x, p_y + p_offset, p_w, p_h, 8, 8)

    local is_paused = (_G.game and _G.game.state == Game.STATE_PAUSED)
    local top_icon_col = {btn_content_col[1], btn_content_col[2], btn_content_col[3], 0.95 * top_alpha}
    if is_paused then
        drawButtonIcon("play", p_x + p_w / 2, p_y + p_offset + p_h / 2, 18, top_icon_col)
    else
        drawButtonIcon("pause", p_x + p_w / 2, p_y + p_offset + p_h / 2, 18, top_icon_col)
    end

    -- Console switch button
    local c_x = p_x + p_w + 8
    local c_y = y_bar
    local c_w = 40
    local c_h = 34
    fs_top_buttons.console = { x = c_x, y = c_y, w = c_w, h = c_h }

    local is_con_pressed = (fs_button_pressed == "console")
    local c_offset = is_con_pressed and 1.5 or 0
    if is_con_pressed then
        love.graphics.setColor(br * 0.82, bg * 0.82, bb * 0.82, 0.95 * top_alpha)
    else
        love.graphics.setColor(br, bg, bb, 0.92 * top_alpha)
    end
    love.graphics.rectangle("fill", c_x, c_y + c_offset, c_w, c_h, 8, 8)
    love.graphics.setColor(1, 1, 1, 0.18 * top_alpha)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", c_x, c_y + c_offset, c_w, c_h, 8, 8)
    drawButtonIcon("console", c_x + c_w / 2, c_y + c_offset + c_h / 2, 22, top_icon_col)

    -- Bottom action buttons
    local board_bottom = _G.android_board_y + 358
    local bottom_space = vh - board_bottom
    local buttons = getFullscreenButtons(_G.game)
    fs_buttons = buttons

    local n = #buttons
    local f_lbl = assets.font_btn_label or love.graphics.getFont()
    love.graphics.setFont(f_lbl)

    if n > 0 then
        local gap = 8
        if n <= 4 then
            local btn_w = math.floor((vw - 32 - (n - 1) * gap) / n)
            local btn_h = 62
            local total_content_h = btn_h + 30
            local pad_y = math.max(14, math.floor((bottom_space - total_content_h) * 0.42))
            local btn_y = board_bottom + pad_y + bottom_slide
            for i, btn in ipairs(buttons) do
                btn.x = 16 + (i - 1) * (btn_w + gap)
                btn.y = btn_y
                btn.w = btn_w
                btn.h = btn_h
            end
        else
            local btn_h = 54
            local total_content_h = btn_h * 2 + gap + 28
            local pad_y = math.max(12, math.floor((bottom_space - total_content_h) * 0.38))
            local y_start = board_bottom + pad_y + bottom_slide
            local row1_count = 3
            local btn_w1 = math.floor((vw - 32 - (row1_count - 1) * gap) / row1_count)
            for i = 1, 3 do
                local btn = buttons[i]
                btn.x = 16 + (i - 1) * (btn_w1 + gap)
                btn.y = y_start
                btn.w = btn_w1
                btn.h = btn_h
            end
            local row2_count = n - 3
            local btn_w2 = math.floor((vw - 32 - (row2_count - 1) * gap) / row2_count)
            for i = 4, n do
                local btn = buttons[i]
                local col = i - 3
                btn.x = 16 + (col - 1) * (btn_w2 + gap)
                btn.y = y_start + btn_h + gap
                btn.w = btn_w2
                btn.h = btn_h
            end
        end

        for _, btn in ipairs(buttons) do
            if btn.id == "theme" then
                _G.android_fs_theme_x = btn.x + math.floor(btn.w / 2)
                _G.android_fs_theme_y = btn.y + math.floor(btn.h / 2)
            end
            local is_pressed = (fs_button_pressed == btn.id)
            local press_offset = is_pressed and 2 or 0

            if is_pressed then
                love.graphics.setColor(br * 0.82, bg * 0.82, bb * 0.82, 0.95 * bottom_alpha)
            else
                love.graphics.setColor(br, bg, bb, 0.92 * bottom_alpha)
            end
            love.graphics.rectangle("fill", btn.x, btn.y + press_offset, btn.w, btn.h, 10, 10)

            love.graphics.setColor(1, 1, 1, 0.15 * bottom_alpha)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", btn.x, btn.y + press_offset, btn.w, btn.h, 10, 10)

            local content_alpha = (btn.disabled and not btn.badge and 0.40 or 0.95) * bottom_alpha
            local icon_col = {btn_content_col[1], btn_content_col[2], btn_content_col[3], content_alpha}
            drawButtonIcon(btn.icon, btn.x + btn.w / 2, btn.y + press_offset + 20, 20, icon_col)

            love.graphics.setColor(btn_content_col[1], btn_content_col[2], btn_content_col[3], content_alpha)
            local lw = f_lbl:getWidth(btn.label)
            love.graphics.print(btn.label, btn.x + math.floor((btn.w - lw) / 2), btn.y + press_offset + 34)

            if btn.badge then
                local f_badge = assets.font_badge or f_lbl
                love.graphics.setFont(f_badge)
                love.graphics.setColor(btn_content_col[1], btn_content_col[2], btn_content_col[3], 0.95 * bottom_alpha)
                local bw = f_badge:getWidth(btn.badge)
                local bx = btn.x + btn.w - bw - 7
                local by = btn.y + press_offset + 4
                love.graphics.print(btn.badge, bx, by)
                love.graphics.setFont(f_lbl)
            end
        end
    end

    love.graphics.setCanvas()

    if only_render_canvas then
        return
    end

    if real_w > real_h then
        love.graphics.setColor(0.04, 0.04, 0.06, 1)
        love.graphics.rectangle("fill", 0, 0, real_w, real_h)
    end

    love.graphics.setColor(1, 1, 1, 1)
    local in_crt_transition = renderer.isCrtTransitionActive and renderer.isCrtTransitionActive()
    local apply_crt = _G.crt_filter or in_crt_transition
    local crt = apply_crt and getCrtShader()
    if crt and in_crt_transition and renderer.drawCrtScreenWithTransition then
        pcall(function() crt:send("screen_size", {vw, vh}) end)
        renderer.drawCrtScreenWithTransition(fs_canvas, crt, origin_x, 0, math.floor(vw * scale_fs_x), math.floor(vh * scale_fs_y), origin_x, 0, scale_fs_x, scale_fs_y)
    else
        if crt then
            pcall(function()
                crt:send("screen_size", {vw, vh})
                love.graphics.setShader(crt)
            end)
        end
        love.graphics.draw(fs_canvas, origin_x, 0, 0, scale_fs_x, scale_fs_y)
        if crt then
            love.graphics.setShader()
        end
    end
end

-- Render virtual retro handheld console and display
function android_console.drawConsole(game_draw_fn, dt, chassis_slide_y, chassis_alpha, skip_screen_draw)
    local w, h = love.graphics.getDimensions()
    local is_gameplay = (_G.appState == "GAME")

    _G.android_fullscreen = false
    _G.hide_game_footer = false
    _G.android_header_y = nil
    _G.android_board_y = nil
    _G.android_toast_y = nil

    -- 1. Render game scene into virtual 640x480 canvas
    local canvas = android_console.getCanvas()
    love.graphics.setCanvas({canvas, stencil = true})
    love.graphics.clear(0, 0, 0, 1)

    -- Ensure directional states clear when touches are inactive
    if next(active_touches) == nil and next(swipe_track) == nil and input and input.state and input.events then
        if not love.keyboard or not (love.keyboard.isDown("up") or love.keyboard.isDown("down") or love.keyboard.isDown("left") or love.keyboard.isDown("right")) then
            if input.state[input.events.UP] then releaseEvent(input.events.UP) end
            if input.state[input.events.DOWN] then releaseEvent(input.events.DOWN) end
            if input.state[input.events.LEFT] then releaseEvent(input.events.LEFT) end
            if input.state[input.events.RIGHT] then releaseEvent(input.events.RIGHT) end
        end
    end

    -- Force scale to 1.0 inside virtual canvas
    _G.scale = 1.0
    _G.sx = 1.0
    _G.sy = 1.0

    local real_getDimensions = love.graphics.getDimensions
    local real_getWidth = love.graphics.getWidth
    local real_getHeight = love.graphics.getHeight

    love.graphics.getDimensions = function() return 640, 480 end
    love.graphics.getWidth = function() return 640 end
    love.graphics.getHeight = function() return 480 end

    game_draw_fn()

    love.graphics.getDimensions = real_getDimensions
    love.graphics.getWidth = real_getWidth
    love.graphics.getHeight = real_getHeight

    love.graphics.setCanvas()

    love.graphics.push("all")

    local c_alpha = chassis_alpha or 1.0
    local slide_y = chassis_slide_y or 0
    if slide_y ~= 0 then
        love.graphics.translate(0, slide_y)
    end

    local old_setColor = love.graphics.setColor
    if c_alpha < 0.999 then
        love.graphics.setColor = function(r, g, b, a)
            if type(r) == "table" then
                old_setColor({r[1], r[2], r[3], (r[4] or 1) * c_alpha})
            else
                old_setColor(r, g, b, (a or 1) * c_alpha)
            end
        end
    end

    -- Lerp towards target theme console colors
    dt = dt or love.timer.getDelta()
    if dt > 0.1 then dt = 0.1 end
    local cur_theme = _G.theme or "light"
    if last_theme_name and cur_theme ~= last_theme_name then
        speaker_theme_anim_timer = speaker_theme_anim_dur
    end
    last_theme_name = cur_theme

    if speaker_theme_anim_timer > 0 then
        speaker_theme_anim_timer = math.max(0, speaker_theme_anim_timer - dt)
    end

    local target_chassis, target_bezel = getThemeConsoleColors(cur_theme)
    local lerp_rate = 1.0 - math.exp(-dt * 3.2)
    for i = 1, 3 do
        anim_chassis[i] = anim_chassis[i] + (target_chassis[i] - anim_chassis[i]) * lerp_rate
        anim_bezel[i]   = anim_bezel[i]   + (target_bezel[i]   - anim_bezel[i])   * lerp_rate
    end

    local cr, cg, cb = anim_chassis[1], anim_chassis[2], anim_chassis[3]
    local bzr, bzg, bzb = anim_bezel[1], anim_bezel[2], anim_bezel[3]

    -- Console body
    local real_w, real_h = love.graphics.getDimensions()
    local origin_x = geo.origin_x or 0
    local w = geo.console_w or real_w
    local h = geo.console_h or real_h

    if real_w > real_h then
        love.graphics.setColor(0.04, 0.04, 0.06, 1)
        love.graphics.rectangle("fill", 0, 0, real_w, real_h)
        if origin_x > 0 then
            love.graphics.setColor(0, 0, 0, 0.35)
            love.graphics.rectangle("fill", origin_x - 6, 0, w + 12, h)
        end
    end

    love.graphics.setColor(cr, cg, cb, 1)
    love.graphics.rectangle("fill", origin_x, 0, w, h)

    -- Speaker grille at bottom right with precision acoustic rosette
    local btn_st = geo.buttons and geo.buttons["start"]
    local spk_x = origin_x + math.floor(w * 0.885)
    local spk_y = btn_st and math.floor(btn_st.y + btn_st.h / 2) or (h - math.floor(h * 0.058))
    local lum = cr * 0.299 + cg * 0.587 + cb * 0.114

    -- Smooth continuous luminance blending without threshold pop
    local dark_factor = 0.0
    if lum <= 0.32 then
        dark_factor = 1.0
    elseif lum >= 0.52 then
        dark_factor = 0.0
    else
        local u = (lum - 0.32) / 0.20
        dark_factor = 1.0 - u * u * (3.0 - 2.0 * u)
    end

    local l_hl = {math.min(1, cr * 1.35 + 0.15), math.min(1, cg * 1.35 + 0.15), math.min(1, cb * 1.35 + 0.15), 0.60}
    local l_hole = {cr * 0.20, cg * 0.20, cb * 0.20, 0.95}
    local l_dish = {cr * 0.88, cg * 0.88, cb * 0.88, 0.70}
    local l_sh = {cr * 0.68, cg * 0.68, cb * 0.68, 0.45}

    local d_hl = {1, 1, 1, 0.22}
    local d_hole = {0, 0, 0, 0.95}
    local d_dish = {0, 0, 0, 0.25}
    local d_sh = {0, 0, 0, 0.45}

    local hl_col = {
        l_hl[1] + (d_hl[1] - l_hl[1]) * dark_factor,
        l_hl[2] + (d_hl[2] - l_hl[2]) * dark_factor,
        l_hl[3] + (d_hl[3] - l_hl[3]) * dark_factor,
        l_hl[4] + (d_hl[4] - l_hl[4]) * dark_factor,
    }
    local hole_col = {
        l_hole[1] + (d_hole[1] - l_hole[1]) * dark_factor,
        l_hole[2] + (d_hole[2] - l_hole[2]) * dark_factor,
        l_hole[3] + (d_hole[3] - l_hole[3]) * dark_factor,
        l_hole[4] + (d_hole[4] - l_hole[4]) * dark_factor,
    }
    local dish_col = {
        l_dish[1] + (d_dish[1] - l_dish[1]) * dark_factor,
        l_dish[2] + (d_dish[2] - l_dish[2]) * dark_factor,
        l_dish[3] + (d_dish[3] - l_dish[3]) * dark_factor,
        l_dish[4] + (d_dish[4] - l_dish[4]) * dark_factor,
    }
    local shadow_col = {
        l_sh[1] + (d_sh[1] - l_sh[1]) * dark_factor,
        l_sh[2] + (d_sh[2] - l_sh[2]) * dark_factor,
        l_sh[3] + (d_sh[3] - l_sh[3]) * dark_factor,
        l_sh[4] + (d_sh[4] - l_sh[4]) * dark_factor,
    }

    local dish_r = math.max(16, math.floor(20 * (w / 390)))

    -- Theme transition acoustic glint animation
    local inner_glint = 0.0
    local outer_glint = 0.0
    if speaker_theme_anim_timer > 0 then
        local wave_p = 1.0 - (speaker_theme_anim_timer / speaker_theme_anim_dur)
        if wave_p >= 0.20 and wave_p <= 0.60 then
            inner_glint = math.sin((wave_p - 0.20) / 0.40 * 3.14159265) * 0.40
        end
        if wave_p >= 0.45 and wave_p <= 0.90 then
            outer_glint = math.sin((wave_p - 0.45) / 0.45 * 3.14159265) * 0.40
        end
    end

    -- Lower highlight rim on dish
    love.graphics.setColor(hl_col)
    love.graphics.circle("fill", spk_x, spk_y + 1, dish_r)

    -- Dish recessed bed
    love.graphics.setColor(dish_col)
    love.graphics.circle("fill", spk_x, spk_y, dish_r)

    -- Inset top inner shadow
    love.graphics.setColor(shadow_col)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", spk_x, spk_y, dish_r)

    -- Precision acoustic perforations in concentric rings
    local center_r = math.max(2.0, math.floor(2.6 * (w / 390)))
    local inner_r = math.max(1.7, math.floor(2.1 * (w / 390)))
    local outer_r = math.max(1.4, math.floor(1.7 * (w / 390)))

    local r_inner = dish_r * 0.44
    local r_outer = dish_r * 0.78

    -- Center port
    love.graphics.setColor(hl_col)
    love.graphics.circle("fill", spk_x, spk_y + 0.9, center_r)
    love.graphics.setColor(hole_col)
    love.graphics.circle("fill", spk_x, spk_y, center_r)

    -- Inner ring ports
    for k = 0, 5 do
        local a_rad = k * 1.04719755 -- pi divided by 3
        local hx = spk_x + r_inner * math.cos(a_rad)
        local hy = spk_y + r_inner * math.sin(a_rad)
        if inner_glint > 0 then
            love.graphics.setColor(hl_col[1], hl_col[2], hl_col[3], math.min(1.0, hl_col[4] + inner_glint))
            love.graphics.circle("fill", hx, hy + 0.9, inner_r)
            love.graphics.setColor(hole_col[1] + inner_glint * 0.5, hole_col[2] + inner_glint * 0.5, hole_col[3] + inner_glint * 0.5, hole_col[4])
            love.graphics.circle("fill", hx, hy, inner_r)
        else
            love.graphics.setColor(hl_col)
            love.graphics.circle("fill", hx, hy + 0.9, inner_r)
            love.graphics.setColor(hole_col)
            love.graphics.circle("fill", hx, hy, inner_r)
        end
    end

    -- Outer ring ports
    for k = 0, 11 do
        local a_rad = (k + 0.5) * 0.52359877 -- pi divided by 6
        local hx = spk_x + r_outer * math.cos(a_rad)
        local hy = spk_y + r_outer * math.sin(a_rad)
        if outer_glint > 0 then
            love.graphics.setColor(hl_col[1], hl_col[2], hl_col[3], math.min(1.0, hl_col[4] + outer_glint))
            love.graphics.circle("fill", hx, hy + 0.9, outer_r)
            love.graphics.setColor(hole_col[1] + outer_glint * 0.5, hole_col[2] + outer_glint * 0.5, hole_col[3] + outer_glint * 0.5, hole_col[4])
            love.graphics.circle("fill", hx, hy, outer_r)
        else
            love.graphics.setColor(hl_col)
            love.graphics.circle("fill", hx, hy + 0.9, outer_r)
            love.graphics.setColor(hole_col)
            love.graphics.circle("fill", hx, hy, outer_r)
        end
    end

    -- Screen bezel
    local bx, by, bw, bh = geo.bezel_x, geo.bezel_y, geo.bezel_w, geo.bezel_h

    -- Soft shadow under bezel
    love.graphics.setColor(0, 0, 0, 0.12)
    love.graphics.rectangle("fill", bx, by + 2, bw, bh, 16, 16)

    love.graphics.setColor(bzr, bzg, bzb, 1)
    love.graphics.rectangle("fill", bx, by, bw, bh, 16, 16)

    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", bx, by, bw, bh, 16, 16)

    if not skip_screen_draw then
        -- Render virtual screen with rounded corners
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.stencil(function()
            love.graphics.rectangle("fill", geo.screen_x, geo.screen_y, geo.screen_w, geo.screen_h, 12, 12)
        end, "replace", 1)
        love.graphics.setStencilTest("greater", 0)

        local in_crt_transition = renderer.isCrtTransitionActive and renderer.isCrtTransitionActive()
        local apply_crt = _G.crt_filter or in_crt_transition
        local crt = apply_crt and getCrtShader()
        if crt and in_crt_transition and renderer.drawCrtScreenWithTransition then
            pcall(function() crt:send("screen_size", {640, 480}) end)
            renderer.drawCrtScreenWithTransition(canvas, crt, geo.screen_x, geo.screen_y, geo.screen_w, geo.screen_h, geo.screen_x, geo.screen_y, geo.scale_x, geo.scale_y)
        else
            if crt then
                pcall(function()
                    crt:send("screen_size", {640, 480})
                    love.graphics.setShader(crt)
                end)
            end
            love.graphics.draw(canvas, geo.screen_x, geo.screen_y, 0, geo.scale_x, geo.scale_y)
            if crt then
                love.graphics.setShader()
            end
        end
        love.graphics.setStencilTest()

        -- Screen inner frame border
        love.graphics.setColor(bzr * 0.75, bzg * 0.75, bzb * 0.75, 0.85)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", geo.screen_x, geo.screen_y, geo.screen_w, geo.screen_h, 12, 12)
    end

    -- Battery LED indicator on top right bezel above screen
    local pad_top = geo.screen_y - by
    local pad_x = geo.screen_x - bx
    local led_x = bx + bw - pad_x - math.floor(14 * (w / 390))
    local led_y = by + math.floor(pad_top / 2)
    local led_r = math.max(2.5, math.floor(3.5 * (w / 390)))

    local state, percent = nil, 100
    pcall(function()
        if love.system and love.system.getPowerInfo then
            local s, p = love.system.getPowerInfo()
            if s then state = tostring(s):lower() end
            if p and type(p) == "number" and p >= 0 then percent = p end
        end
    end)

    local is_charging = (state and (state:find("charg") ~= nil or (state == "nobattery" and percent and percent > 0)))
    if _G.battery_charging_override ~= nil then
        is_charging = _G.battery_charging_override
    end

    if is_charging then
        local t = love.timer.getTime() * 2.8
        local breath = 0.5 + 0.5 * math.sin(t)
        local ease = breath * breath * (3.0 - 2.0 * breath)

        -- Smooth ambient glow aura behind socket
        local glow_r1 = led_r * (1.8 + 1.6 * ease)
        local glow_r2 = led_r * (1.3 + 0.9 * ease)
        local glow_a1 = (0.05 + 0.18 * ease)
        local glow_a2 = (0.10 + 0.28 * ease)

        love.graphics.setColor(0.12, 0.92, 0.38, glow_a1)
        love.graphics.circle("fill", led_x, led_y, glow_r1, 36)
        love.graphics.setColor(0.15, 0.96, 0.42, glow_a2)
        love.graphics.circle("fill", led_x, led_y, glow_r2, 36)

        -- Recessed socket housing
        love.graphics.setColor(bzr * 0.30, bzg * 0.30, bzb * 0.30, 0.95)
        love.graphics.circle("fill", led_x, led_y, led_r + 1.8, 36)
        love.graphics.setColor(1, 1, 1, 0.16)
        love.graphics.circle("line", led_x, led_y + 0.6, led_r + 1.8, 36)
        love.graphics.setColor(bzr * 0.15, bzg * 0.15, bzb * 0.15, 0.95)
        love.graphics.circle("fill", led_x, led_y, led_r + 0.8, 36)

        -- Breathing bulb core
        local core_g = 0.52 + 0.46 * ease
        local core_b = 0.18 + 0.22 * ease
        local core_a = 0.55 + 0.43 * ease
        love.graphics.setColor(0.08, core_g, core_b, core_a)
        love.graphics.circle("fill", led_x, led_y, led_r, 36)

        -- Inner hot spot
        love.graphics.setColor(0.35 + 0.45 * ease, 0.98, 0.55 + 0.35 * ease, 0.30 + 0.65 * ease)
        love.graphics.circle("fill", led_x, led_y, led_r * 0.58, 36)

        -- Specular glint
        love.graphics.setColor(1, 1, 1, 0.20 + 0.65 * ease)
        love.graphics.circle("fill", led_x - led_r * 0.30, led_y - led_r * 0.30, math.max(1.0, led_r * 0.28), 24)
    else
        local led_col
        if percent <= 10 then
            -- Critical battery: 10 percent and below blinks red
            local blink = (math.sin(love.timer.getTime() * 8) > 0)
            led_col = {0.96, 0.18, 0.18, blink and 0.95 or 0.20}
        elseif percent <= 20 then
            -- Low battery: solid red
            led_col = {0.96, 0.22, 0.22, 0.95}
        elseif percent <= 35 then
            -- Medium battery: amber orange
            led_col = {0.96, 0.68, 0.14, 0.95}
        else
            -- Healthy battery: solid green
            led_col = {0.12, 0.88, 0.35, 0.95}
        end

        local col_a = led_col[4] or 1.0

        -- Ambient soft halo glow
        if col_a > 0.35 then
            love.graphics.setColor(led_col[1], led_col[2], led_col[3], 0.10 * col_a)
            love.graphics.circle("fill", led_x, led_y, led_r * 2.6, 36)
            love.graphics.setColor(led_col[1], led_col[2], led_col[3], 0.22 * col_a)
            love.graphics.circle("fill", led_x, led_y, led_r * 1.6, 36)
        end

        -- Recessed socket housing
        love.graphics.setColor(bzr * 0.30, bzg * 0.30, bzb * 0.30, 0.95)
        love.graphics.circle("fill", led_x, led_y, led_r + 1.8, 36)
        love.graphics.setColor(1, 1, 1, 0.16)
        love.graphics.circle("line", led_x, led_y + 0.6, led_r + 1.8, 36)
        love.graphics.setColor(bzr * 0.15, bzg * 0.15, bzb * 0.15, 0.95)
        love.graphics.circle("fill", led_x, led_y, led_r + 0.8, 36)

        -- LED bulb core
        love.graphics.setColor(led_col)
        love.graphics.circle("fill", led_x, led_y, led_r, 36)

        -- Inner hot spot
        if col_a > 0.35 then
            local hr = math.min(1, led_col[1] * 1.25)
            local hg = math.min(1, led_col[2] * 1.25)
            local hb = math.min(1, led_col[3] * 1.25)
            love.graphics.setColor(hr, hg, hb, 0.50 * col_a)
            love.graphics.circle("fill", led_x, led_y, led_r * 0.55, 36)
        end

        -- Specular glint
        if col_a > 0.35 then
            love.graphics.setColor(1, 1, 1, 0.65)
            love.graphics.circle("fill", led_x - led_r * 0.30, led_y - led_r * 0.30, math.max(1.0, led_r * 0.28), 24)
        end
    end

    -- Chin branding
    local chin_top = geo.screen_y + geo.screen_h
    local chin_bottom = geo.bezel_y + geo.bezel_h
    local chin_h = chin_bottom - chin_top

    local brand_img = assets.brand_image
    if not brand_img then
        for _, brand_path in ipairs({"android/assets/brand.png", "android/assets/2048_plus.png", "assets/brand.png", "assets/2048_plus.png"}) do
            local ok_b, img_b = pcall(love.graphics.newImage, brand_path, {mipmaps = true})
            if not ok_b then ok_b, img_b = pcall(love.graphics.newImage, brand_path) end
            if ok_b and img_b then
                pcall(function() img_b:setFilter("linear", "linear", 4) end)
                assets.brand_image = img_b
                brand_img = img_b
                break
            end
        end
    end

    if brand_img then
        local target_h = math.floor(chin_h * 0.65)
        local scale = target_h / brand_img:getHeight()
        local draw_w = brand_img:getWidth() * scale
        local draw_h = brand_img:getHeight() * scale
        local center_chin_x = geo.bezel_x + geo.bezel_w / 2
        local draw_x = math.floor(center_chin_x - draw_w / 2)
        local draw_y = math.floor((chin_top + chin_bottom - draw_h) / 2)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(brand_img, draw_x, draw_y, 0, scale, scale)
    else
        local f_brand = assets.font_brand or love.graphics.getFont()
        love.graphics.setFont(f_brand)

        local text_str = "2048 PLUS"
        local font_h = f_brand:getHeight()
        local brand_y = math.floor((chin_top + chin_bottom - font_h) / 2)
        local text_w = f_brand:getWidth(text_str)
        local center_chin_x = geo.bezel_x + geo.bezel_w / 2
        local brand_x = math.floor(center_chin_x - text_w / 2)

        love.graphics.setColor(0, 0, 0, 0.40)
        love.graphics.print(text_str, brand_x, brand_y + 1)

        love.graphics.setColor(1, 1, 1, 0.95)
        love.graphics.print(text_str, brand_x, brand_y)
    end

    -- Screen overlay with full screen icon toggle button
    if not skip_screen_draw and is_gameplay and screen_overlay_visible then
        love.graphics.setColor(0, 0, 0, 0.45)
        love.graphics.rectangle("fill", geo.screen_x, geo.screen_y, geo.screen_w, geo.screen_h, 12, 12)

        local btn_sz = math.floor(geo.screen_w * 0.12)
        local btn_x = geo.screen_x + geo.screen_w - btn_sz - 8
        local btn_y = geo.screen_y + geo.screen_h - btn_sz - 8

        love.graphics.setColor(0.12, 0.12, 0.16, 0.90)
        love.graphics.rectangle("fill", btn_x, btn_y, btn_sz, btn_sz, 8, 8)
        love.graphics.setColor(1, 1, 1, 0.50)
        love.graphics.setLineWidth(1.5)
        love.graphics.rectangle("line", btn_x, btn_y, btn_sz, btn_sz, 8, 8)

        drawButtonIcon("fullscreen", btn_x + btn_sz / 2, btn_y + btn_sz / 2, btn_sz * 0.65, {1, 1, 1, 0.95})
    end

    if not skip_screen_draw and is_gameplay and fs_tutorial_active then
        drawFullscreenTutorial(dt)
    end

    -- Controls rendering
    local target_dpad = is_gameplay and 0.0 or 1.0
    local dpad_lerp_rate = 1.0 - math.exp(-dt * 9.0)
    dpad_anim_alpha = dpad_anim_alpha + (target_dpad - dpad_anim_alpha) * dpad_lerp_rate
    if dpad_anim_alpha < 0.015 then dpad_anim_alpha = 0.0 end
    if dpad_anim_alpha > 0.985 then dpad_anim_alpha = 1.0 end

    local game_t = 1.0 - dpad_anim_alpha
    local t_curve = game_t * game_t * (3.0 - 2.0 * game_t)
    for _, b_name in ipairs({"y", "a", "x", "b"}) do
        local btn = geo.buttons[b_name]
        if btn and btn.menu_cx and btn.game_cx then
            local cx = btn.menu_cx + (btn.game_cx - btn.menu_cx) * t_curve
            local cy = btn.menu_cy + (btn.game_cy - btn.menu_cy) * t_curve
            local sz = btn.menu_sz + (btn.game_sz - btn.menu_sz) * t_curve
            btn.cx = cx
            btn.cy = cy
            btn.w = sz
            btn.h = sz
            btn.x = cx - sz / 2
            btn.y = cy - sz / 2
        end
    end

    local btn_alpha = 0.95

    -- Shoulder triggers
    for _, s_name in ipairs({"l", "r"}) do
        local btn = geo.buttons[s_name]
        if btn then
            local is_pressed = (button_states[s_name] == true)
            local press_offset = is_pressed and 2.0 or 0
            local shade = is_pressed and 0.95 or 1.0

            local img = is_pressed and (assets.buttons[s_name .. "_pressed"] or assets.buttons[s_name]) or assets.buttons[s_name]
            if img then
                love.graphics.setColor(shade, shade, shade, btn_alpha)
                local sx = btn.w / img:getWidth()
                local sy = btn.h / img:getHeight()
                love.graphics.draw(img, btn.x, btn.y + press_offset, 0, sx, sy)
            else
                love.graphics.setColor(0.24 * shade, 0.24 * shade, 0.28 * shade, btn_alpha)
                love.graphics.rectangle("fill", btn.x, btn.y + press_offset, btn.w, btn.h, 8, 8)
                love.graphics.setColor(1, 1, 1, 0.20 * btn_alpha)
                love.graphics.setLineWidth(1.5)
                love.graphics.rectangle("line", btn.x, btn.y + press_offset, btn.w, btn.h, 8, 8)
                local f = assets.font_badge or love.graphics.getFont()
                love.graphics.setFont(f)
                local lbl = s_name:upper() .. "1"
                local tw = f:getWidth(lbl)
                local th = f:getHeight()
                love.graphics.setColor(1, 1, 1, 0.90 * btn_alpha)
                love.graphics.print(lbl, math.floor(btn.x + (btn.w - tw) / 2), math.floor(btn.y + press_offset + (btn.h - th) / 2))
            end
        end
    end

    -- D-Pad
    if dpad_anim_alpha > 0.005 then
        local dpad_dir = button_states["dpad"]
        local dpad_sprite_name = dpad_dir and ("cross_" .. dpad_dir) or "cross"
        local dpad_img = assets.dpad[dpad_sprite_name] or assets.dpad["cross"]
        local current_scale = 0.85 + 0.15 * dpad_anim_alpha
        local slide_y = (1.0 - dpad_anim_alpha) * math.floor(18 * (w / 390))
        local cx = geo.dpad_x
        local cy = geo.dpad_y + slide_y

        if dpad_img then
            love.graphics.setColor(1, 1, 1, dpad_anim_alpha * 0.95)
            local s = (geo.dpad_size * current_scale) / dpad_img:getWidth()
            love.graphics.draw(dpad_img, cx - (dpad_img:getWidth() * s) / 2, cy - (dpad_img:getHeight() * s) / 2, 0, s, s)
        else
            local sz = geo.dpad_size * current_scale
            local arm_w = math.floor(sz * 0.35)
            local a = dpad_anim_alpha * 0.95

            love.graphics.setColor(0.18, 0.18, 0.22, a)
            love.graphics.rectangle("fill", cx - arm_w / 2, cy - sz / 2, arm_w, sz, 6, 6)
            love.graphics.rectangle("fill", cx - sz / 2, cy - arm_w / 2, sz, arm_w, 6, 6)

            love.graphics.setColor(0.12, 0.12, 0.15, a)
            love.graphics.circle("fill", cx, cy, arm_w * 0.40)
        end
    end

    -- Track swipe gesture state for gameplay session
    if is_gameplay and not last_is_gameplay then
        if not _G.game or not _G.game.moves or _G.game.moves == 0 then
            console_has_swiped = false
            swipe_text_alpha = 1.0
        end
    end
    last_is_gameplay = is_gameplay

    if is_gameplay and _G.game and _G.game.moves and _G.game.moves > 0 then
        console_has_swiped = true
    end

    -- Swipe box appears after dpad fades and abxy finishes moving upward
    local target_swipe_box = (is_gameplay and dpad_anim_alpha == 0.0) and 1.0 or 0.0
    local box_lerp_rate = 1.0 - math.exp(-dt * 8.0)
    swipe_box_anim = swipe_box_anim + (target_swipe_box - swipe_box_anim) * box_lerp_rate
    if swipe_box_anim < 0.01 then swipe_box_anim = 0.0 end
    if swipe_box_anim > 0.99 then swipe_box_anim = 1.0 end

    local target_text = (console_has_swiped or not is_gameplay) and 0.0 or 1.0
    local text_lerp_rate = 1.0 - math.exp(-dt * 9.5)
    swipe_text_alpha = swipe_text_alpha + (target_text - swipe_text_alpha) * text_lerp_rate
    if swipe_text_alpha < 0.02 then swipe_text_alpha = 0.0 end
    if swipe_text_alpha > 0.98 then swipe_text_alpha = 1.0 end

    if swipe_box_anim > 0.005 and geo.swipe_box then
        local p = swipe_box_anim
        local ease = p * p * (3.0 - 2.0 * p)
        local box_alpha = ease * 0.95
        local slide_y = (1.0 - ease) * 16

        local bx = geo.swipe_box.x
        local by = geo.swipe_box.y + slide_y
        local bw = geo.swipe_box.w
        local bh = geo.swipe_box.h
        local br = geo.swipe_box.r or 18

        -- Adapt styling to chassis luminance
        local lum = cr * 0.299 + cg * 0.587 + cb * 0.114
        local is_dark = (lum < 0.45)
        local border_r = is_dark and 1.0 or bzr
        local border_g = is_dark and 1.0 or bzg
        local border_b = is_dark and 1.0 or bzb
        local border_a = (is_dark and 0.22 or 0.35) * box_alpha

        local hint_r = is_dark and 0.88 or bzr
        local hint_g = is_dark and 0.88 or bzg
        local hint_b = is_dark and 0.92 or bzb

        -- Recessed trackpad fill
        if is_dark then
            love.graphics.setColor(0, 0, 0, 0.35 * box_alpha)
        else
            love.graphics.setColor(cr * 0.86, cg * 0.86, cb * 0.86, 0.60 * box_alpha)
        end
        love.graphics.rectangle("fill", bx, by, bw, bh, br, br)


        -- Micropattern stipple texture
        local dot_alpha = (is_dark and 0.07 or 0.11) * box_alpha
        love.graphics.setColor(hint_r, hint_g, hint_b, dot_alpha)
        for px = bx + 24, bx + bw - 24, 22 do
            for py = by + 24, by + bh - 24, 22 do
                love.graphics.rectangle("fill", px, py, 1.5, 1.5)
            end
        end

        -- Border outline
        love.graphics.setColor(border_r, border_g, border_b, border_a)
        love.graphics.setLineWidth(1.5)
        love.graphics.rectangle("line", bx, by, bw, bh, br, br)

        -- Corner accent tick marks
        local m_sz = 10
        local m_ins = 12
        love.graphics.setColor(border_r, border_g, border_b, (is_dark and 0.28 or 0.30) * box_alpha)
        love.graphics.setLineWidth(1.4)
        love.graphics.line(bx + m_ins, by + m_ins + m_sz, bx + m_ins, by + m_ins, bx + m_ins + m_sz, by + m_ins)
        love.graphics.line(bx + bw - m_ins - m_sz, by + m_ins, bx + bw - m_ins, by + m_ins, bx + bw - m_ins, by + m_ins + m_sz)
        love.graphics.line(bx + m_ins, by + bh - m_ins - m_sz, bx + m_ins, by + bh - m_ins, bx + m_ins + m_sz, by + bh - m_ins)
        love.graphics.line(bx + bw - m_ins - m_sz, by + bh - m_ins, bx + bw - m_ins, by + bh - m_ins, bx + bw - m_ins, by + bh - m_ins - m_sz)

        -- Directional arrow glyphs and text indicator
        if swipe_text_alpha > 0.005 then
            local t_alpha = swipe_text_alpha * box_alpha
            local cx = bx + bw / 2
            local cy = by + bh / 2

            local glyph_alpha = (is_dark and 0.78 or 0.72) * t_alpha
            love.graphics.setColor(hint_r, hint_g, hint_b, glyph_alpha)

            -- Center touch ring
            love.graphics.setLineWidth(1.8)
            love.graphics.circle("line", cx, cy - 16, 4.5)
            love.graphics.circle("fill", cx, cy - 16, 2.0)

            -- Four directional arrowheads and stems
            love.graphics.polygon("fill", cx, cy - 36, cx - 6, cy - 27, cx + 6, cy - 27)
            love.graphics.polygon("fill", cx, cy + 4, cx - 6, cy - 5, cx + 6, cy - 5)
            love.graphics.polygon("fill", cx - 20, cy - 16, cx - 11, cy - 22, cx - 11, cy - 10)
            love.graphics.polygon("fill", cx + 20, cy - 16, cx + 11, cy - 22, cx + 11, cy - 10)

            love.graphics.setLineWidth(2.0)
            love.graphics.line(cx, cy - 21, cx, cy - 26)
            love.graphics.line(cx, cy - 11, cx, cy - 6)
            love.graphics.line(cx - 5, cy - 16, cx - 10, cy - 16)
            love.graphics.line(cx + 5, cy - 16, cx + 10, cy - 16)

            -- Text
            local str = "Swipe to Play"
            local f = assets.font_badge or assets.font_btn_label
            if f then
                love.graphics.setFont(f)
                local tw = f:getWidth(str)
                love.graphics.setColor(hint_r, hint_g, hint_b, (is_dark and 0.85 or 0.78) * t_alpha)
                love.graphics.print(str, math.floor(cx - tw / 2), math.floor(cy + 16))
            end
        end
    end

    -- Action buttons
    for _, b_name in ipairs({"y", "a", "x", "b"}) do
        local btn = geo.buttons[b_name]
        if btn then
            local is_pressed = (button_states[b_name] == true)
            local press_offset = is_pressed and 2.5 or 0
            local shade = is_pressed and 0.90 or 1.0
            local cx = btn.cx or (btn.x + btn.w / 2)
            local cy = btn.cy or (btn.y + btn.h / 2)

            local img = is_pressed and (assets.buttons[b_name .. "_pressed"] or assets.buttons[b_name]) or assets.buttons[b_name]
            if img then
                love.graphics.setColor(shade, shade, shade, btn_alpha)
                local s = btn.w / img:getWidth()
                local ix = cx - (img:getWidth() * s) / 2
                local iy = cy + press_offset - (img:getHeight() * s) / 2
                love.graphics.draw(img, ix, iy, 0, s, s)
            else
                local r = btn.w / 2
                local col_map = {
                    y = {0.28, 0.76, 0.38},
                    b = {0.92, 0.72, 0.18},
                    a = {0.88, 0.24, 0.24},
                    x = {0.24, 0.54, 0.88},
                }
                local base_col = col_map[b_name] or {0.6, 0.6, 0.6}
                local factor = is_pressed and 0.80 or 1.0

                love.graphics.setColor(0, 0, 0, 0.35 * btn_alpha)
                love.graphics.circle("fill", cx, cy + press_offset + 2.5, r)

                love.graphics.setColor(base_col[1] * factor, base_col[2] * factor, base_col[3] * factor, btn_alpha)
                love.graphics.circle("fill", cx, cy + press_offset, r)

                love.graphics.setColor(1, 1, 1, 0.25 * btn_alpha)
                love.graphics.setLineWidth(1.5)
                love.graphics.circle("line", cx, cy + press_offset, r)

                local f = assets.font_badge or love.graphics.getFont()
                love.graphics.setFont(f)
                local lbl = b_name:upper()
                local tw = f:getWidth(lbl)
                local th = f:getHeight()
                love.graphics.setColor(1, 1, 1, 0.95 * btn_alpha)
                love.graphics.print(lbl, math.floor(cx - tw / 2), math.floor(cy + press_offset - th / 2))
            end
        end
    end

    -- Select and Start buttons
    for _, p_name in ipairs({"select", "start"}) do
        local btn = geo.buttons[p_name]
        if btn then
            local is_pressed = (button_states[p_name] == true)
            local press_offset = is_pressed and 1.5 or 0
            local shade = is_pressed and 0.95 or 1.0

            local img = is_pressed and (assets.buttons[p_name .. "_pressed"] or assets.buttons[p_name]) or assets.buttons[p_name]
            if img then
                love.graphics.setColor(shade, shade, shade, btn_alpha)
                local sx = btn.w / img:getWidth()
                local sy = btn.h / img:getHeight()
                love.graphics.draw(img, btn.x, btn.y + press_offset, 0, sx, sy)
            else
                love.graphics.setColor(0.24 * shade, 0.24 * shade, 0.28 * shade, btn_alpha)
                love.graphics.rectangle("fill", btn.x, btn.y + press_offset, btn.w, btn.h, 6, 6)
                love.graphics.setColor(1, 1, 1, 0.18 * btn_alpha)
                love.graphics.setLineWidth(1.2)
                love.graphics.rectangle("line", btn.x, btn.y + press_offset, btn.w, btn.h, 6, 6)
                local f = assets.font_btn_label or love.graphics.getFont()
                love.graphics.setFont(f)
                local lbl = p_name:upper()
                local tw = f:getWidth(lbl)
                local th = f:getHeight()
                love.graphics.setColor(1, 1, 1, 0.90 * btn_alpha)
                love.graphics.print(lbl, math.floor(btn.x + (btn.w - tw) / 2), math.floor(btn.y + press_offset + (btn.h - th) / 2))
            end
        end
    end

    if old_setColor then
        love.graphics.setColor = old_setColor
    end
    love.graphics.pop()
    love.graphics.setCanvas()
    return canvas
end

-- Animated transition between console and fullscreen modes
function android_console.drawModeTransition(game_draw_fn, dt, progress)
    local real_w, real_h = love.graphics.getDimensions()
    local origin_x = geo.origin_x or 0
    local console_w = geo.console_w or real_w
    local console_h = geo.console_h or real_h
    local vw = 390
    local vh = math.floor(vw * (console_h / console_w))
    local scale_fs_x = console_w / vw
    local scale_fs_y = console_h / vh

    local p = math.max(0.0, math.min(1.0, progress))
    local t = p * p * (3 - 2 * p)

    local renderer = require("renderer")
    local theme_bg = (renderer.getThemeBgColor and renderer.getThemeBgColor()) or {0.98, 0.97, 0.94}
    love.graphics.setColor(theme_bg[1] or 0.98, theme_bg[2] or 0.97, theme_bg[3] or 0.94, 1)
    love.graphics.rectangle("fill", 0, 0, real_w, real_h)

    if real_w > real_h then
        love.graphics.setColor(0.04, 0.04, 0.06, 1)
        love.graphics.rectangle("fill", 0, 0, real_w, real_h)
        love.graphics.setColor(theme_bg[1] or 0.98, theme_bg[2] or 0.97, theme_bg[3] or 0.94, 1)
        love.graphics.rectangle("fill", origin_x, 0, console_w, console_h)
    end

    if transition_dir == 1 then
        -- Console to Fullscreen
        if t < 0.48 then
            local fade_out = (1.0 - (t / 0.48)) ^ 1.5
            local slide_y = (t / 0.48) * 24
            android_console.drawConsole(game_draw_fn, dt, slide_y, fade_out, false)
        else
            local in_p = (t - 0.48) / 0.52
            local fade_in = in_p ^ 1.3
            local settle_y = (1.0 - in_p) * 16
            android_console.drawFullscreen(game_draw_fn, dt, in_p, true)

            love.graphics.setColor(1, 1, 1, fade_in)
            love.graphics.draw(fs_canvas, origin_x, settle_y, 0, scale_fs_x, scale_fs_y)
        end
    else
        -- Fullscreen to Console
        if t > 0.48 then
            local out_p = (t - 0.48) / 0.52
            local fade_out = out_p ^ 1.3
            local slide_y = (1.0 - out_p) * -16
            android_console.drawFullscreen(game_draw_fn, dt, out_p, true)

            love.graphics.setColor(1, 1, 1, fade_out)
            love.graphics.draw(fs_canvas, origin_x, slide_y, 0, scale_fs_x, scale_fs_y)
        else
            local in_p = 1.0 - (t / 0.48)
            local fade_in = in_p ^ 1.4
            local slide_y = (1.0 - in_p) * 20
            android_console.drawConsole(game_draw_fn, dt, slide_y, fade_in, false)
        end
    end
end

-- Primary draw dispatch
function android_console.draw(game_draw_fn)
    local rw, rh = love.graphics.getDimensions()
    if rw > rh then
        -- Landscape mode: render native handheld display without console chassis
        _G.android_fullscreen = false
        _G.hide_game_footer = false
        _G.android_header_y = nil
        _G.android_board_y = nil
        _G.android_toast_y = nil
        game_draw_fn()
        return
    end

    local is_gameplay = (_G.appState == "GAME")
    local dt = love.timer.getDelta()
    if dt > 0.1 then dt = 0.1 end

    if is_gameplay and not last_is_gameplay then
        if not _G.game or not _G.game.moves or _G.game.moves == 0 then
            console_has_swiped = false
            swipe_text_alpha = 1.0
        end
    end
    last_is_gameplay = is_gameplay

    if is_gameplay and _G.game and _G.game.moves and _G.game.moves > 0 then
        console_has_swiped = true
    end

    if screen_overlay_visible then
        screen_overlay_timer = screen_overlay_timer - dt
        if screen_overlay_timer <= 0 then
            screen_overlay_visible = false
        end
    end

    if is_gameplay and transition_active then
        local step = dt / transition_duration
        if transition_dir == 1 then
            transition_progress = math.min(1.0, transition_progress + step)
            if transition_progress >= 1.0 then
                transition_progress = 1.0
                transition_active = false
                fs_button_pressed = nil
            end
        else
            transition_progress = math.max(0.0, transition_progress - step)
            if transition_progress <= 0.0 then
                transition_progress = 0.0
                transition_active = false
                fs_button_pressed = nil
            end
        end

        android_console.drawModeTransition(game_draw_fn, dt, transition_progress)
        return
    end

    if android_view_mode == "fullscreen" and is_gameplay then
        android_console.drawFullscreen(game_draw_fn, dt)
        return
    end

    android_console.drawConsole(game_draw_fn, dt)
end

return android_console
