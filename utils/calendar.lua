-- original code made by Bzed and published on http://awesome.naquadah.org/wiki/Calendar_widget
-- modified by Marc Dequènes (Duck) <Duck@DuckCorp.org> (2009-12-29), under the same licence,
-- and with the following changes:
--   + transformed to module
--   + the current day formating is customizable
-- modified by Jörg Thalheim (Mic92) <jthalheim@gmail.com> (2011), under the same licence,
-- and with the following changes:
--   + use tooltip instead of naughty.notify
--   + rename it to cal
--   + lua52 compliant module
-- modified by Sven Greiner (SammysHP) <sven@sammyshp.de> (2017), under the same license
-- and with the following changes:
--   + integration in necessary and cleanup

local awful = require("awful")
local beautiful = require("beautiful")

local calendar = {}

function calendar.getMonthString(month, year, weekStart)
    local t, wkSt = os.time{year=year, month=month+1, day=0}, weekStart or 1
    local d = os.date("*t",t)
    local mthDays, stDay = d.day, (d.wday-d.day-wkSt+1)%7

    local lines = "    "

    for x=0,6 do
            lines = lines .. os.date(" %a ",os.time{year=2006,month=1,day=x+wkSt})
    end

    lines = lines .. "\n" .. os.date(" %V",os.time{year=year,month=month,day=1})

    local writeLine = 1
    while writeLine < (stDay + 1) do
            lines = lines .. "    "
            writeLine = writeLine + 1
    end

    for d=1, mthDays do
            local x = d
            local t = os.time{year=year,month=month,day=d}
            if writeLine == 8 then
                    writeLine = 1
                    lines = lines .. "\n" .. os.date(" %V",t)
            end
            if os.date("%Y-%m-%d") == os.date("%Y-%m-%d", t) then
                    x = string.format("<span color=\"" .. (beautiful.tooltip_bg_color or beautiful.bg_normal) .. "\" background=\"" .. (beautiful.tooltip_fg_color or beautiful.fg_normal) .. "\" weight=\"bold\">%s</span>", d)
            end
            if d < 10 then
                    x = " " .. x
            end
            lines = lines .. "  " .. x
            writeLine = writeLine + 1
    end
    if stDay + mthDays < 36 then
            lines = lines .. "\n"
    end
    if stDay + mthDays < 29 then
            lines = lines .. "\n"
    end
    local header = os.date("%B %Y\n",os.time{year=year,month=month,day=1})

    return header .. "\n" .. lines
end


function calendar.registertooltip(mywidget)
    local state = {}

    tooltip = awful.tooltip({
        objects = { mywidget },
        delay_show = beautiful.tooltip_delay or 0
    })

    local function update_tooltip()
            local month, year = os.date('%m'), os.date('%Y')
            state = {month, year}
            tooltip.markup = string.format('<span font_desc="monospace">%s</span>', calendar.getMonthString(month, year, 2))
    end
    update_tooltip()
    mywidget:connect_signal("mouse::enter", update_tooltip)

    local function switchMonth(delta)
        state[1] = state[1] + (delta or 1)
        local text = string.format('<span font_desc="monospace">%s</span>', calendar.getMonthString(state[1], state[2], 2))
        tooltip.markup = text
    end

    mywidget:buttons(awful.util.table.join(
        awful.button({         }, 1, function() switchMonth(-1)  end),
        awful.button({         }, 3, function() switchMonth(1)   end),
        awful.button({         }, 4, function() switchMonth(-1)  end),
        awful.button({         }, 5, function() switchMonth(1)   end),
        awful.button({ 'Shift' }, 1, function() switchMonth(-12) end),
        awful.button({ 'Shift' }, 3, function() switchMonth(12)  end),
        awful.button({ 'Shift' }, 4, function() switchMonth(-12) end),
        awful.button({ 'Shift' }, 5, function() switchMonth(12)  end)
    ))
end

return calendar
