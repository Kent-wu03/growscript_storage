return {

    info = {
        name = "SC PABRIK",
        author = "RockyBandel",
        version = "1.0"
    },

    settings = {
        -- sblm start script berdiri di posisi break
        idb = 880, -- id block
        bhit = 2, -- jumlah hit block
        plat = 102, -- plat for farm (for plant)
        trash = {5026, 5024 , 5028},
        wpabrik = "worldkalian", -- world pabrik
        idpabrik = "iddoor", -- id world pabrik
        delay_recon = 3500, -- delay reconnect
    },

    init = function(cfg)
        cfg.farming = false
        cfg.planting = false
        cfg.harvesting = false
        cfg.dc = false
        cfg.ex = nil
        cfg.ey = nil
        cfg.ids = nil
        cfg.tworld = ""
        cfg.pos = {}

        -- do not touch
        SendVariantList({[0] = "OnDialogRequest", [1] = [[
set_default_color|`w
add_label_with_icon|small|`cPABRIK|left|1438|
add_label_with_icon|small|`9Script by RockyBandel|left|2480|
add_spacer|small|
add_smalltext|`2This script is free|
add_spacer|small|
add_smalltext|`2Feature|
add_label_with_icon|small|`cAuto reconnect `0- `5(ignore error console)|left|3802|
add_label_with_icon|small|`cFast PNB `0- `5keknya :v |left|1438|
add_label_with_icon|small|`cAuto detect tile|left|102|
add_label_with_icon|small|`cAuto store seed on vend|left|23|
add_label_with_icon|small|`cAuto plant & harvest|left|3200|
add_label_with_icon|small|`cAuto trash with custom id `0- `5Setting di config|left|5026|
add_spacer|small|
add_smalltext|`4DO NOT RESELL!|
add_quick_exit|]]})

        ChangeValue("[C] Modfly v2", true)

        cfg.farming = true
        cfg.planting = false
        cfg.harvesting = false
        cfg.dc = false

        cfg.ex = math.floor(GetLocal().pos.x / 32)
        cfg.ey = math.floor(GetLocal().pos.y / 32)
        cfg.ids = cfg.idb + 1
        cfg.tworld = cfg.wpabrik.."|"..cfg.idpabrik

        local function ltc(text)
            LogToConsole("`^"..text)
        end 

        local function getdata(cfg)
            ltc("Getting data")
            for _, tile in pairs(GetTiles()) do
                if tile.fg == cfg.plat and tile.y == cfg.ey + 1 then
                    table.insert(cfg.pos, {x = tile.x, y = tile.y})
                end
            end
            ltc("total "..#cfg.pos.." tile")
        end

        getdata(cfg)
    end,

    ui = function(cfg)

    end,

    run = function(cfg)
        local function log(text) 
            SendVariantList({[0] = "OnTextOverlay", [1] = "[ `^RockyHub Info `w] : " .. text}) 
        end

        local function ltc(text)
            LogToConsole("`^"..text)
        end 

        local function move(tx, ty, s, h)
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

        local function getTile(x, y)
            for _, tile in pairs(GetTiles()) do
                if tile.x == x and tile.y == y then
                    return tile
                end
            end
            return nil
        end

        local function inv(id)
            for _, item in pairs(GetInventory()) do
                if item.id == id then return item.amount end
            end
            return 0
        end

        local function trash(cfg)
            for _, id in ipairs(cfg.trash) do
                local titem = inv(id)
                if titem >= 15 then
                    SendPacket(2, "action|trash\n|itemID|"..id)
                    Sleep(1000)
                    SendPacket(2, "action|dialog_return\ndialog_name|trash_item\nitemID|"..id.."|\ncount|"..titem)
                    Sleep(1010)
                    log("Trashed "..titem.." items")
                end
            end
        end

        local function checktree(cfg)
            for _, p in pairs(cfg.pos) do
                local tile = getTile(p.x, p.y - 1)

                if tile and tile.fg == cfg.ids then
                    if not tile.extra or tile.extra.progress < 1.0 then
                        return false
                    end
                end
            end

            return true
        end

        local function wrench(x, y)
            SendPacketRaw(false, {
                type = 3,
                value = 32,
                px = x,
                py = y,
                x = GetLocal().pos.x,
                y = GetLocal().pos.y
            })
        end

        local function addvend(cfg)
            AddHook('OnVariant','blockvending', function(var, netid, delay)
                if var[0] == 'OnDialogRequest' then
                    LogToConsole('Blocked Dialog!')
                    return true
                end
            end)
            log("Add seed")
            wrench(cfg.ex,cfg.ey)
            SendPacket(2, "action|dialog_return\ndialog_name|vending\ntilex|"..cfg.ex.."|\ntiley|"..cfg.ey.."|\nbuttonClicked|addstock\n\nsetprice|100\nchk_peritem|1\nchk_perlock|0")
            RemoveHook('blockvending')
        end

        local function collect(obj)
            SendPacketRaw(false, {type=11,value=obj.oid,x=obj.pos.x,y=obj.pos.y})
        end

        local function collectDrop(cfg)
            local bx = cfg.ex - 1
            local by = cfg.ey

            for _, obj in pairs(GetObjectList()) do
                local ox = math.floor(obj.pos.x / 32)
                local oy = math.floor(obj.pos.y / 32)

                if math.abs(ox - bx) <= 2 and math.abs(oy - by) <= 2 then
                    collect(obj)
                    Sleep(20)
                end
            end
        end

        local function plant(cfg, x, y)
            local pkt = {}
            pkt.type = 3
            pkt.value = cfg.ids
            pkt.px = x
            pkt.py = y
            pkt.x = GetLocal().pos.x
            pkt.y = GetLocal().pos.y
            SendPacketRaw(false,pkt)
            Sleep(180)
        end

        local function placeb(cfg, x, y)
            local pkt = {}
            pkt.type = 3
            pkt.value = cfg.idb
            pkt.px = x
            pkt.py = y
            pkt.x = GetLocal().pos.x
            pkt.y = GetLocal().pos.y
            SendPacketRaw(false,pkt)
            Sleep(180)
        end

        local function breakb(x, y)
            local pkt = {}
            pkt.type = 3
            pkt.value = 18
            pkt.px = x
            pkt.py = y
            pkt.x = GetLocal().pos.x
            pkt.y = GetLocal().pos.y
            SendPacketRaw(false,pkt)
            Sleep(180)
        end

        local function pnb(cfg)
            log("Start PNB")
            move(cfg.ex, cfg.ey, 4, false)
            while inv(cfg.idb) > 10 do
                local bx = cfg.ex - 1
                local by = cfg.ey

                collectDrop(cfg)
                placeb(cfg, bx, by)

                for i = 1, cfg.bhit do
                    breakb(bx, by)
                end
            end
        end

        local function pt(cfg)
            log("Planting")
            for _, p in pairs(cfg.pos) do
                local above = getTile(p.x, p.y - 1)

                if above and above.fg == 0 then
                    move(p.x,p.y - 1,4,false)
                    plant(cfg, p.x, p.y-1)
                    Sleep(100)
                end
            end
        end

        local function collectht()
            local px = math.floor(GetLocal().pos.x / 32)
            local py = math.floor(GetLocal().pos.y / 32)

            for _, obj in pairs(GetObjectList()) do
                local ox = math.floor(obj.pos.x / 32)
                local oy = math.floor(obj.pos.y / 32)

                if math.abs(ox - px) <= 2 and math.abs(oy - py) <= 2 then
                    collect(obj)
                    Sleep(20)
                end
            end
        end

        local function ht(cfg)
            while not checktree(cfg) do
                Sleep(5000)
            end
                log("Harvesting")
            for _, p in pairs(cfg.pos) do
                local above = getTile(p.x, p.y - 1)

                if above and above.fg == cfg.ids then
                    if above.extra and above.extra.progress == 1.0 then
                        if inv(cfg.idb) <= 170 then
                            move(p.x, p.y - 1, 4, false)
                            breakb(p.x, p.y - 1)
                            Sleep(100)
                            collectht()
                        end
                    end
                end
            end
        end

        local function ds(x, jumlah)
                SendPacket(2, "action|drop\nitemID|" ..x)
                Sleep(500)
                SendPacket(2,
                    "action|dialog_return\n" ..
                    "dialog_name|drop_item\n" ..
                    "itemID|" .. x .. "|\n" ..
                    "count|" .. jumlah
                )
        end

        local function pabrik(cfg)
            local world = GetWorld()
            if not world or world.name ~= cfg.wpabrik then
                Sleep(1300)
                ltc("Reconnecting to " .. cfg.wpabrik)
                RequestJoinWorld(cfg.tworld)
                Sleep(cfg.delay_recon)
                world = GetWorld()
                if world and world.name == cfg.wpabrik then
                    cfg.dc = true
                end
            end

            if cfg.dc then
                log("Going back to pos")
                move(cfg.ex, cfg.ey, 4, false)
                cfg.dc = false
            end

            Sleep(500)

            local blockCount = inv(cfg.idb)
            local seedCount  = inv(cfg.ids)
            local condA = blockCount > 10  
            local condB = seedCount <= (#cfg.pos + 50)

            if condA and condB then
                pnb(cfg)

            elseif condA and not condB then
                local toDrop = #cfg.pos
                ds(cfg.ids,toDrop)
                Sleep(800)
                addvend(cfg)
            else
                pt(cfg)
                ht(cfg)
                pnb(cfg)
            end
            trash(cfg)
            collectDrop(cfg)
            Sleep(500)
        end

        while true do
            if cfg.running == false then
                break
            end
            local ok, err = pcall(pabrik, cfg)
            if not ok then
                ltc("Error: " .. tostring(err))
                Sleep(3000)
            end
            Sleep(200)
        end
    end,

    stop = function(cfg)
        cfg.running = false
    end

}
