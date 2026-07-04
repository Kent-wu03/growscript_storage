ids = 787 -- id seed
delay_recon = 3500
wplant = "worldkalian" -- worldplant|id kalo ada

-- do not touch
isht = true
dc = false

idb = ids-1
tstock = 0

function log(text)
    SendVariantList({[0] = "OnTextOverlay", [1] = "[ `^RockyHub Info `w] : " .. text})
end

function ltc(text)
    LogToConsole("`^" .. text)
end

function wrench(x, y)
    SendPacketRaw(false,{type=3,value=32,px=x,py=y,x=GetLocal().pos.x,y=GetLocal().pos.y})
end

function punch(x, y)
	SendPacketRaw(false,{type=3,value=18,px=x,py=y,x=GetLocal().pos.x,y=GetLocal().pos.y})
	Sleep(175)
end

function move(tx, ty, s, h)
    s = s or 4
    while true do
        local x = math.floor(GetLocal().pos.x / 32)
        local y = math.floor(GetLocal().pos.y / 32)
        if x == tx and y == ty then return true end
        local dx, dy, nx, ny = tx - x, ty - y, x, y
        if h then
            nx = x + math.max(-s, math.min(s, dx))
            if nx == x then ny = y + math.max(-s, math.min(s, dy)) end
        else
            ny = y + math.max(-s, math.min(s, dy))
            if ny == y then nx = x + math.max(-s, math.min(s, dx)) end
        end
        FindPath(nx, ny)
        Sleep(300 + math.random(30, 80))
    end
end

function harvesting()
    while isht do
        local world = GetWorld()
        if not world or world.name ~= wplant then
            Sleep(1300)
            ltc("Reconnecting to " .. wplant)
            RequestJoinWorld(wplant)
            Sleep(delay_recon)
            world = GetWorld()
            if world and world.name == wplant then
                dc = true
            end
        end

        if dc then
            log("Going back to pos")
            dc = false
        end

        Sleep(500)

        for _, tile in ipairs(GetTiles()) do
            if tile.fg == ids and tile.extra and tile.extra.progress == 1.0 then
                FindPath(tile.x, tile.y, 700)
                while GetTile(tile.x, tile.y) and GetTile(tile.x, tile.y).fg ~= 0 do
                    punch(tile.x, tile.y)
                end
            end
        end
    end
end

while true do
    if not isht then    
        break
    end

    local ok, err = pcall(harvesting)
    if not ok then
        ltc("Error: " .. tostring(err))
        Sleep(3000)
    end
    Sleep(200)
end

