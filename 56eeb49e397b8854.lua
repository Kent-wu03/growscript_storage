return {
    info = {
        name = "Harvesting",
        author = "RockyHub",
        version = "1.0"
    },
    settings = {
        ids = 787,
        delay_recon = 3500,
        wplant = "worldkalian"
    },
    init = function(cfg)
        cfg.idb = cfg.ids - 1
        cfg.tstock = 0
        cfg.dc = false
    end,
    run = function(cfg)
        cfg.running = true
        while cfg.running do
            harvesting(cfg)
            Sleep(200)
        end
    end,
    stop = function(cfg)
        cfg.running = false
    end
}

local function log(text)
    SendVariantList({[0] = "OnTextOverlay", [1] = "[ `^RockyHub Info `w] : " .. text})
end

local function ltc(text)
    LogToConsole("`^" .. text)
end

local function wrench(x, y)
    SendPacketRaw(false,{type=3,value=32,px=x,py=y,x=GetLocal().pos.x,y=GetLocal().pos.y})
end

local function punch(x, y)
    SendPacketRaw(false,{type=3,value=18,px=x,py=y,x=GetLocal().pos.x,y=GetLocal().pos.y})
    Sleep(175)
end

local function move(tx, ty, s, h)
    s = s or 4
    while cfg.running do
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

local function harvesting(cfg)
    local world = GetWorld()
    if not world or world.name ~= cfg.wplant then
        Sleep(1300)
        ltc("Reconnecting to " .. cfg.wplant)
        RequestJoinWorld(cfg.wplant)
        Sleep(cfg.delay_recon)
        world = GetWorld()
        if world and world.name == cfg.wplant then
            cfg.dc = true
        end
    end

    if cfg.dc then
        log("Going back to pos")
        cfg.dc = false
    end

    Sleep(500)

    for _, tile in ipairs(GetTiles()) do
        if tile.fg == cfg.ids and tile.extra and tile.extra.progress == 1.0 then
            FindPath(tile.x, tile.y, 700)
            while GetTile(tile.x, tile.y) and GetTile(tile.x, tile.y).fg ~= 0 do
                punch(tile.x, tile.y)
            end
        end
    end
end