local ala = nil
local function pipe(o)
    local oP = Instance.find(gm.constants.oP)
    if oP ~= -4 and oP.x ~= nil then
        local p = o:create(oP.x - 25, oP.y - 1000)
        local pipeData = p:get_data()
        pipeData.victim = oP
        ala = Alarm.create(pipe, math.random(180, 50000), o)
    end
end
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto(true)
local function init()
    local piO = Object.new("RoughSpatula", "FallingPipe")
    local sPipe =
        Resources.sprite_load("RoughSpatula", "sPipe", path.combine(_ENV["!plugins_mod_folder_path"], "pipe1.png"))
    pipe_sound =
        Resources.sfx_load("RoughSpatula", "PipeFall", path.combine(_ENV["!plugins_mod_folder_path"], "pipe.ogg"))
    piO:set_depth(1)
    piO:set_sprite(sPipe)
    piO:onCreate(
        function(inst)
            local selfData = inst:get_data()
            selfData.duration = 3600
            selfData.state = 0
            inst.image_yscale = 0.4
            inst.team = 4
            inst.image_xscale = 0.4
            inst.gravity = 0.2
        end
    )
    piO:onStep(
        function(inst)
            local selfDa = inst:get_data()
            if selfDa.state < 2 then
                if inst.y + 100 > selfDa.victim.y then
                    local speedy = inst.vspeed + gm.sign(inst.vspeed) * 0.5
                    if inst:is_colliding(gm.constants.pBlock, inst.x, inst.y + speedy - 20) then
                        inst.gravity = 0.0
                        inst.vspeed = 0.0
                        selfDa.state = true
                        selfDa.state = 2
                        inst:sound_play(pipe_sound, 1, 1)
                        gm._mod_attack_fire_explosion_noparent(
                            inst.x + 15,
                            inst.y + 15,
                            50,
                            50,
                            10,
                            1000,
                            1,
                            -1,
                            gm.constants["sSparks17_PROV"]
                        )
                    end
                end
                if selfDa.state < 1 then
                    local ac = inst:get_collisions(gm.constants.pActor)
                    for _, act in ipairs(ac) do
                        gm._mod_attack_fire_explosion_noparent(
                            inst.x + 15,
                            inst.y + 15,
                            50,
                            50,
                            10,
                            1000,
                            1,
                            -1,
                            gm.constants["sSparks17_PROV"]
                        )
                        selfDa.state = 1
                    end
                end
            end
            selfDa.duration = selfDa.duration - 1
            if selfDa.duration < 0 then
                inst:destroy()
            end
        end
    )
    Callback.add(
        Callback.TYPE.onGameStart,
        "PipeSetup",
        function()
            Alarm.destroy(ala)
            ala = Alarm.create(pipe, math.random(180, 50000), piO)
        end
    )
end
Initialize(init)
if hotload then
    init()
end
hotload = true
log.info("loaded " .. _ENV["!guid"] .. ".")
