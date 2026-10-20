-- android_console.lua: Virtual retro handheld controller for portrait Android display
local android_console = {}

local input = nil
local active_touches = {}
local swipe_track = {}
local button_states = {}

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
        chassis = {0.220, 0.380, 0.480},
        bezel   = {0.125, 0.235, 0.315},
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
local dpad_anim_alpha = 1.0

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
}

local game_canvas = nil

function android_console.init(input_ref)
    input = input_ref or require("input")

    -- Initialize animated console colors immediately to match current active theme
    local init_chassis, init_bezel = getThemeConsoleColors(_G.theme or "light")
    anim_chassis = {init_chassis[1], init_chassis[2], init_chassis[3]}
    anim_bezel   = {init_bezel[1], init_bezel[2], init_bezel[3]}


    _G.design_w = 640
    _G.design_h = 480
    _G.sx = 1.0
    _G.sy = 1.0
    _G.scale = 1.0

    -- Lock UI scale so game menus/tiles inside 640x480 virtual screen are never zoomed
    _G.update_ui_scale = function()
        _G.design_w = 640
        _G.design_h = 480
        _G.sx = 1.0
        _G.sy = 1.0
        _G.scale = 1.0
    end

    -- Load Vector D-Pad sprites with mipmaps & anisotropic filtering
    local dpad_names = {"cross", "cross_u", "cross_d", "cross_l", "cross_r", "cross_ul", "cross_ur", "cross_dl", "cross_dr"}
    for _, name in ipairs(dpad_names) do
        local ok, img = pcall(love.graphics.newImage, "android/assets/dpad/" .. name .. ".png", {mipmaps = true})
        if not ok then ok, img = pcall(love.graphics.newImage, "assets/dpad/" .. name .. ".png", {mipmaps = true}) end
        if not ok then ok, img = pcall(love.graphics.newImage, "android/assets/dpad/" .. name .. ".png") end
        if not ok then ok, img = pcall(love.graphics.newImage, "assets/dpad/" .. name .. ".png") end
        if ok and img then
            pcall(function() img:setFilter("linear", "linear", 4) end)
            assets.dpad[name] = img
        end
    end

    -- Load Vector Button sprites with mipmaps & anisotropic filtering
    local btn_names = {
        "a", "b", "x", "y",
        "a_pressed", "b_pressed", "x_pressed", "y_pressed",
        "l", "r", "select", "start",
        "l_pressed", "r_pressed", "select_pressed", "start_pressed"
    }
    for _, name in ipairs(btn_names) do
        local ok, img = pcall(love.graphics.newImage, "android/assets/buttons/" .. name .. ".png", {mipmaps = true})
        if not ok then ok, img = pcall(love.graphics.newImage, "assets/buttons/" .. name .. ".png", {mipmaps = true}) end
        if not ok then ok, img = pcall(love.graphics.newImage, "android/assets/buttons/" .. name .. ".png") end
        if not ok then ok, img = pcall(love.graphics.newImage, "assets/buttons/" .. name .. ".png") end
        if ok and img then
            pcall(function() img:setFilter("linear", "linear", 4) end)
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

    -- Support custom brand PNG with mipmaps & anisotropic filtering for razor-sharp rendering
    for _, brand_path in ipairs({"android/assets/brand.png", "android/assets/2048_plus.png", "assets/brand.png", "assets/2048_plus.png"}) do
        local ok_b, img_b = pcall(love.graphics.newImage, brand_path, {mipmaps = true})
        if not ok_b then ok_b, img_b = pcall(love.graphics.newImage, brand_path) end
        if ok_b and img_b then
            pcall(function() img_b:setFilter("linear", "linear", 4) end)
            assets.brand_image = img_b
            break
        end
    end

    android_console.updateLayout()
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
    local origin_x = 0
    local w = real_w
    local h = real_h

    -- Auto-rotate landscape fallback
    -- Pillarbox portrait console in center
    if real_w > real_h then
        w = math.min(real_w, math.floor(real_h * (9 / 16)))
        origin_x = math.floor((real_w - w) / 2)
    end

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
    local pad_top = math.max(8, math.floor(w * 0.025))
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
    local dpad_x = origin_x + math.floor(w * 0.24)
    local dpad_y = ctrl_mid_y

    geo.dpad_x = dpad_x
    geo.dpad_y = dpad_y
    geo.dpad_size = dpad_size
    geo.dpad_r = dpad_size / 2

    -- Action buttons diamond cluster in menu mode, row during gameplay
    local btn_size = math.floor(dpad_size * 0.43)
    local center_act_x = origin_x + math.floor(w * 0.76)
    local center_act_y = ctrl_mid_y
    local offset_r = math.floor(btn_size * 0.82)

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

local function triggerHaptic(duration)
    pcall(function()
        if love.system and love.system.vibrate then
            love.system.vibrate(duration or 0.015)
        end
    end)
end

local function emitEvent(event)
    if not event or not input then return end
    if input.state then input.state[event] = true end
    if input.emit then
        input.emit(event, false)
    elseif love.keypressed then
        love.keypressed(event)
    end
end

local function releaseEvent(event)
    if not event or not input then return end
    if input.state then input.state[event] = false end
    if love.keyreleased then
        love.keyreleased(event)
    end
end

function android_console.touchpressed(id, x, y, dx, dy, pressure)
    local w, h = love.graphics.getDimensions()
    if x <= 1.0 and y <= 1.0 and w > 10 then
        x = x * w
        y = y * h
    end
    local is_gameplay = (_G.appState == "GAME")

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
        swipe_track[id] = {
            start_x = x,
            start_y = y,
            fired = false,
            time = love.timer.getTime(),
            in_screen = false,
        }
    end
end

function android_console.touchmoved(id, x, y, dx, dy, pressure)
    local w, h = love.graphics.getDimensions()
    if x <= 1.0 and y <= 1.0 and w > 10 then
        x = x * w
        y = y * h
    end
    local is_gameplay = (_G.appState == "GAME")

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
        end
        return
    end

    -- Gesture swipe during gameplay
    local sw = swipe_track[id]
    if sw and not sw.fired and is_gameplay then
        local diff_x = x - sw.start_x
        local diff_y = y - sw.start_y
        local abs_x = math.abs(diff_x)
        local abs_y = math.abs(diff_y)

        local threshold = 24
        if abs_x > threshold or abs_y > threshold then
            sw.fired = true
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
    local w, h = love.graphics.getDimensions()
    if x <= 1.0 and y <= 1.0 and w > 10 then
        x = x * w
        y = y * h
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

-- Draw virtual retro handheld console and display
function android_console.draw(game_draw_fn)
    local w, h = love.graphics.getDimensions()

    -- 1. Render game scene into virtual 640x480 canvas
    local canvas = android_console.getCanvas()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 1)

    -- Safety check: ensure directional states don't stay stuck when touches are released
    if next(active_touches) == nil and next(swipe_track) == nil and input and input.state and input.events then
        if not love.keyboard or not (love.keyboard.isDown("up") or love.keyboard.isDown("down") or love.keyboard.isDown("left") or love.keyboard.isDown("right")) then
            input.state[input.events.UP] = false
            input.state[input.events.DOWN] = false
            input.state[input.events.LEFT] = false
            input.state[input.events.RIGHT] = false
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

    -- Lerp towards target theme console colors
    local dt = love.timer.getDelta()
    if dt > 0.1 then dt = 0.1 end
    local target_chassis, target_bezel = getThemeConsoleColors(_G.theme or "light")
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
        -- Pillarbox background when phone is turned landscape in external runners
        love.graphics.setColor(0.04, 0.04, 0.06, 1)
        love.graphics.rectangle("fill", 0, 0, real_w, real_h)
    end

    -- Console body
    love.graphics.setColor(cr, cg, cb, 1)
    love.graphics.rectangle("fill", origin_x, 0, w, h)

    -- Side grip textures
    local grip_w = math.max(6, math.floor(w * 0.018))
    local grip_y_start = geo.bezel_y + 40
    local grip_y_end = h - 60
    for gy = grip_y_start, grip_y_end, 10 do
        love.graphics.setColor(cr * 0.80, cg * 0.80, cb * 0.80, 0.70)
        love.graphics.rectangle("fill", origin_x + 2, gy, grip_w, 4, 2, 2)
        love.graphics.rectangle("fill", origin_x + w - grip_w - 2, gy, grip_w, 4, 2, 2)
        -- Subtle highlight edge
        love.graphics.setColor(math.min(1, cr * 1.25 + 0.08), math.min(1, cg * 1.25 + 0.08), math.min(1, cb * 1.25 + 0.08), 0.45)
        love.graphics.rectangle("fill", origin_x + 2, gy + 1, grip_w, 1.5, 1, 1)
        love.graphics.rectangle("fill", origin_x + w - grip_w - 2, gy + 1, grip_w, 1.5, 1, 1)
    end

    -- Speaker grilles at bottom corners
    love.graphics.setColor(cr * 0.70, cg * 0.70, cb * 0.70, 0.75)
    local spk_r = math.max(1.5, math.floor(w * 0.005))
    local spk_left_x = origin_x + math.floor(w * 0.10)
    local spk_right_x = origin_x + math.floor(w * 0.90)
    local spk_y = h - math.floor(h * 0.04)
    for row = -1, 1 do
        for col = -1, 1 do
            love.graphics.circle("fill", spk_left_x + col * 7, spk_y + row * 7, spk_r)
            love.graphics.circle("fill", spk_right_x + col * 7, spk_y + row * 7, spk_r)
        end
    end

    -- 3. Screen Bezel & Lens: Rich Bezel Framing Display
    local bx, by, bw, bh = geo.bezel_x, geo.bezel_y, geo.bezel_w, geo.bezel_h

    -- Screen Bezel
    love.graphics.setColor(bzr, bzg, bzb, 1)
    love.graphics.rectangle("fill", bx, by, bw, bh, 16, 16)

    -- Bezel subtle outer highlight & shadow rim
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", bx, by, bw, bh, 16, 16)

    -- Battery LED indicator top-right of bezel
    local led_x = bx + bw - math.floor(18 * (w / 390))
    local led_y = by + math.floor(12 * (w / 390))
    local led_r = math.floor(3.5 * (w / 390))

    -- Recessed LED socket in deep bezel tone
    love.graphics.setColor(bzr * 0.65, bzg * 0.65, bzb * 0.65, 0.9)
    love.graphics.circle("fill", led_x, led_y, led_r + 1.5)

    local percent = 100
    pcall(function()
        if love.system.getPowerInfo then
            local _, p = love.system.getPowerInfo()
            if p then percent = p end
        end
    end)

    if percent > 30 then
        love.graphics.setColor(0.12, 0.85, 0.35, 0.95)
    elseif percent > 15 then
        love.graphics.setColor(0.95, 0.70, 0.15, 0.95)
    else
        local blink = (math.sin(love.timer.getTime() * 8) > 0)
        love.graphics.setColor(0.95, 0.20, 0.20, blink and 0.95 or 0.25)
    end
    love.graphics.circle("fill", led_x, led_y, led_r)

    -- Render virtual screen with rounded corners
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.stencil(function()
        love.graphics.rectangle("fill", geo.screen_x, geo.screen_y, geo.screen_w, geo.screen_h, 12, 12)
    end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)

    local crt = _G.crt_filter and getCrtShader()
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
    love.graphics.setStencilTest()

    -- Screen inner frame border / shadow
    love.graphics.setColor(bzr * 0.75, bzg * 0.75, bzb * 0.75, 0.85)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", geo.screen_x, geo.screen_y, geo.screen_w, geo.screen_h, 12, 12)

    -- Branding below screen centered in chin
    local chin_top = geo.screen_y + geo.screen_h
    local chin_bottom = geo.bezel_y + geo.bezel_h
    local chin_h = chin_bottom - chin_top

    -- Check if custom brand PNG is provided
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
        -- Draw user's custom brand image centered in chin
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
        -- Uniform text in fixed font
        local f_brand = assets.font_brand or love.graphics.getFont()
        love.graphics.setFont(f_brand)

        local text_str = "2048 PLUS"
        local font_h = f_brand:getHeight()
        local brand_y = math.floor((chin_top + chin_bottom - font_h) / 2)
        local text_w = f_brand:getWidth(text_str)
        local center_chin_x = geo.bezel_x + geo.bezel_w / 2
        local brand_x = math.floor(center_chin_x - text_w / 2)

        -- Text shadow
        love.graphics.setColor(0, 0, 0, 0.40)
        love.graphics.print(text_str, brand_x, brand_y + 1)

        -- Text on bezel
        love.graphics.setColor(1, 1, 1, 0.95)
        love.graphics.print(text_str, brand_x, brand_y)
    end

    -- 5. Controls Rendering
    -- 5. Controls Rendering & Animations
    local is_gameplay = (_G.appState == "GAME")
    local target_dpad = is_gameplay and 0.0 or 1.0
    local dpad_lerp_rate = 1.0 - math.exp(-dt * 9.0)
    dpad_anim_alpha = dpad_anim_alpha + (target_dpad - dpad_anim_alpha) * dpad_lerp_rate
    if dpad_anim_alpha < 0.005 then dpad_anim_alpha = 0.0 end
    if dpad_anim_alpha > 0.995 then dpad_anim_alpha = 1.0 end

    -- Smooth interpolation for action buttons moving between diamond cluster and row between L1/R1
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

    -- Shoulder triggers L1 and R1
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
            end
        end
    end

    -- D-Pad animates out during gameplay leaving space for gestures
    if dpad_anim_alpha > 0.005 then
        local dpad_dir = button_states["dpad"]
        local dpad_sprite_name = dpad_dir and ("cross_" .. dpad_dir) or "cross"
        local dpad_img = assets.dpad[dpad_sprite_name] or assets.dpad["cross"]
        if dpad_img then
            love.graphics.setColor(1, 1, 1, dpad_anim_alpha * 0.95)
            local current_scale = 0.85 + 0.15 * dpad_anim_alpha
            local slide_y = (1.0 - dpad_anim_alpha) * math.floor(18 * (w / 390))
            local s = (geo.dpad_size * current_scale) / dpad_img:getWidth()
            local cx = geo.dpad_x
            local cy = geo.dpad_y + slide_y
            love.graphics.draw(dpad_img, cx - (dpad_img:getWidth() * s) / 2, cy - (dpad_img:getHeight() * s) / 2, 0, s, s)
        end
    end

    -- Action buttons A, B, X, Y
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
            end
        end
    end

    love.graphics.pop()
    love.graphics.setCanvas()
end

return android_console
