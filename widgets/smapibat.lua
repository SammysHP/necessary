local textbox = require("wibox.widget.textbox")
local timer = require("gears.timer")

local BAT_UNKNOWN = 0
local BAT_DISCHARGING = 1
local BAT_CHARGING = 2
local BAT_AC = 3

local smapibat = {}

local function get_battery_status(adapter)
    local fper = io.open("/sys/devices/platform/smapi/" .. adapter .. "/remaining_percent")
    local percent = fper:read()
    fper:close()

    local fsta = io.open("/sys/devices/platform/smapi/" .. adapter .. "/state")
    local sta = fsta:read()
    fsta:close()

    local fpow = io.open("/sys/devices/platform/smapi/" .. adapter .. "/power_avg")
    local pow = fpow:read()
    fpow:close()

    local frem = io.open("/sys/devices/platform/smapi/" .. adapter .. "/remaining_running_time")
    local rem = frem:read()
    frem:close()

    local status
    if sta:match("discharging") then
        status = BAT_DISCHARGING
    elseif sta:match("charging") then
        status = BAT_CHARGING
    else
        status = BAT_AC
    end

    local indicator
    local power = ""
    local remaining = ""

    if status == BAT_DISCHARGING then
        indicator = "↓"
        power = string.format(" %.2f", pow / -1000) .. "W"
        remaining = string.format(" %dh%dm", math.floor(rem / 60), math.floor(rem % 60))
    elseif status == BAT_CHARGING then
        indicator = "↑"
    elseif status == BAT_AC then
        indicator = "AC"
        percent = ""
    else
        indicator = "?"
        percent = ""
    end

    return percent .. indicator .. power .. remaining
end

function smapibat.new(args)
    args = args or {}
    local adapter = args.adapter or "BAT0"
    local interval = args.interval or 15

    local w = textbox()

    timer.start_new(interval, function() w.text = get_battery_status(adapter); return true end):emit_signal("timeout")

    return { widget = w }
end

return smapibat
