#include "utility.lua"
#include "staticData.lua"


--================================================================================================================
-- Hammer of Dawn (Gears of War) - By: Cheejins
--================================================================================================================


-- staticData.lua
local sounds = getSounds()
local vols = getVols()
local sprites = getSprites()


-- Hammer of Dawn properties.
local hod = {
    targetPos = nil,
    targetActive = false,
    raycastPos = nil,
    raycastTargetPos = nil, -- Raycast down over lerped targetPos (keeps lerped target pos on ground)
    playerDamage = 0.1,

    charge = 0.0, -- between 0 and 1. Used to lerp thin beams towards center.
    chargeRate = 0.01, -- convergence speed
    dechargeRate = 0.02,

    beams = 10,
    beamSpread = 14,
    beamLocations = {},
    beamWidths = {
        thin = 0.8,
        thick = 5.2,
    },
    beamWidth = 4,
    beamSpriteHeight = 100,

    beamChaseRate = 0.17,

    beamParticles = 150,
    beamParticlesTrs = {},
    beamAnimationSpeed = 1.2,

    timer = 0,
    rpm = 1200,
    explosions = {
        size = 3,
        enabled = true,
    },

    targetPositiveBeep = {
        timer = 0,
        rpm = 130,
    },

    soundCues = {
        impactPlayed = false
    },

}

--- Player position, updated every tick.
local ppos = GetPlayerPos()

function init()
    RegisterTool("hammerOfDawn", "Hammer of Dawn", "MOD/vox/hammerOfDawn.vox")
    SetBool("game.tool.hammerOfDawn.enabled", true)
end


function tick()
    manageHod()
    ppos = GetPlayerPos()
    -- debugMod()
end


function manageHod()
    if GetString("game.player.tool") == "hammerOfDawn" and InputDown('lmb') then

        if hod.targetActive == false then
            setTarget()
            initBeamAnimation()
            hod.targetActive = true

            snd_HodStart()
        end

        shootHod()
        increaseCharge()
    else
        if hod.charge >= 0 then
            hod.charge = hod.charge - hod.dechargeRate
        end
        if InputReleased("lmb") and hod.targetActive == true then
            snd_HodEnd()
        end
        hod.targetActive = false
    end
end


function setTarget()
    local camTr = GetCameraTransform()
    local hitPos = raycastFromTransform(camTr)
    hod.targetPos = hitPos
    local spread = hod.beamSpread

    for i = 1, hod.beams do
        hod.beamLocations[i] = VecAdd(hitPos, Vec(rdm(-spread,spread), 0, rdm(-spread,spread)))
    end
end


function shootHod()
    if hod.targetPos ~= nil then

        local camTr = GetCameraTransform()
        local rcPos = raycastFromTransform(camTr)

        if hod.charge >= 0.95 then -- Converged beam

            hod.beamWidth = hod.beamWidths.thick
            local targetSubVec = VecScale(VecNormalize(VecSub(rcPos, hod.targetPos)), hod.beamChaseRate) -- Vec pointing towards player raycast.
            hod.targetPos = VecAdd(hod.targetPos, targetSubVec)

            shootBeam(hod.targetPos, hod.beamWidth)
            checkPlayerDamage(hod.raycastPos, 1.2)

            setRaycastTargetPos()
            -- MakeHole(sphereHitPos, holeSize, holeSize * 0.75, holeSize * 0.5)

            beamAnimation(hod.raycastTargetPos)

            for i = 1, 5 do
                local firePos = Vec(
                    hod.raycastPos[1] + rdm(-hod.beamWidth,hod.beamWidth),
                    hod.raycastPos[2] + rdm(-0.3, 0.3),
                    hod.raycastPos[3] + rdm(-hod.beamWidth,hod.beamWidth))
                SpawnFire(firePos)
            end

            SpawnParticle("darksmoke", hod.raycastPos, Vec(rdm(-3,3), 1, rdm(-3,3)), 2, 1)
            snd_HodConvergedLoop()


        else -- Converging beams

            hod.beamWidth = hod.beamWidths.thin

            for i = 1, #hod.beamLocations do
                local beamLocation = hod.beamLocations[i]
                local lerpFraction = 1 - hod.charge
                local beamLerp = VecLerp(hod.targetPos, beamLocation, lerpFraction)
                shootBeam(beamLerp)

                for i = 1, 3 do
                    local firePos = Vec(
                        hod.raycastPos[1] + rdm(-hod.beamWidth,hod.beamWidth),
                        hod.raycastPos[2] + rdm(-0.3, 0.3),
                        hod.raycastPos[3] + rdm(-hod.beamWidth,hod.beamWidth))
                    SpawnFire(firePos)
                end

                checkPlayerDamage(beamLerp, 0.35)
            end

            hod.soundCues.impactPlayed = false
            snd_HodConvergingLoop()
        end

    end
end


function checkPlayerDamage(dPos, dmgMult)
    for i = 1, 30 do
        if CalcDistance(VecAdd(dPos, Vec(0, dPos[2] + (i*hod.beamWidth*0.8), 0)), ppos) < hod.beamWidth*0.8 then
            SetPlayerHealth(GetPlayerHealth() - hod.playerDamage * (dmgMult))
        end
    end
end


function shootBeam(pos)

    -- Raycast down from sky.
    local rcPosUp = VecAdd(pos, Vec(0,hod.beamSpriteHeight,0))
    local rcTr = Transform(rcPosUp, QuatLookAt(rcPosUp, pos))
    local rcPos = raycastFromTransform(rcTr)
    hod.raycastPos = rcPos

    -- Beam floor fire
    local beamFireTr = Transform(rcPos, QuatEuler(rdm(-90,90),rdm(-90,90),rdm(-90,90)))
    local beamFireTr2 = Transform(rcPos, QuatEuler(rdm(-90,90),rdm(-90,90),rdm(-90,90)))
    DrawSprite(sprites.beam_fire, beamFireTr, 0.2, 0.2, 1, 1, 1, 1)
    DrawSprite(sprites.beam_fire, beamFireTr2, 0.2, 0.2, 1, 1, 1, 1)

    -- Beams
    local beamTr = Transform(pos, QuatEuler(0,90,90))
    local beamTrRot = Transform(pos, QuatEuler(0,0,90))
    DrawSprite(sprites.beam_thin, beamTr, hod.beamSpriteHeight/2, 1.5, 1, 1, 1, 1, 0)
    DrawSprite(sprites.beam_thin, beamTrRot, hod.beamSpriteHeight/2, 1.5, 1, 1, 1, 1, 0)

    -- Smoke sprite
    SpawnParticle("smoke", rcPos, Vec(0,0,0), 0.5, 0.5)

    -- Red light
    PointLight(rcPos, 1, rdm(0,0.3), 0, rdm(0,1))

    -- Timed for performance.
    if hod.timer <= 0 then
        hod.timer = 60/hod.rpm

        -- perimeter fire
        for i = 1, 5 do
            local edgePos = VecCopy(pos)
            local rdmDist = rdm(0,2)
            edgePos[1] = pos[1] + rdmDist
            edgePos[3] = pos[3] + rdmDist

            -- local centerToEdgeVec = VecScale(VecNormalize(VecSub(edgePos, pos), hod.beamWidths.thick*0.75), hod.beamWidths.thick*hod.charge)
            -- DebugLine(pos, centerToEdgeVec)
        end

        -- Make hole based on the type of beam.
        local holeTargetPos = rcPos
        if hod.beamWidth == hod.beamWidths.thick then

            holeTargetPos = hod.raycastTargetPos

            ---- Create timed explosions.
            -- local rpm = hod.rpm/rdm(50,100)
            -- if hod.timer <= 60/rpm then
            --     local vecSpread = rdmVec(0.5,2)
            --     local explosionPos = VecAdd(holeTargetPos, vecSpread)
            --     Explosion(explosionPos, 3)
            -- end

        end
        MakeHole(holeTargetPos, hod.beamWidth, hod.beamWidth * 0.75, hod.beamWidth * 0.5)

        -- for i = 1, 1 do
        --     local shpereRcPosHeightOffset = Vec(hod.raycastPos[1], hod.raycastPos[2] + (i*holeSize), hod.raycastPos[3])
        --     local sphereTr = Transform(shpereRcPosHeightOffset, QuatEuler(0,0,0))
        --     local sphereHitPos = spherecastFromTransform(sphereTr, 5, 5)
        --     MakeHole(sphereHitPos, hod.beamWidth, hod.beamWidth * 0.75, hod.beamWidth * 0.5)
        -- end

    else
        hod.timer = hod.timer - GetTimeStep()
    end

end


function beamAnimation(pos)

    for i = 1, hod.beamParticles do

        local beamTr = hod.beamParticlesTrs[i]
        if beamTr.pos[2] < pos[2] then
            hod.beamParticlesTrs[i].pos[2] = hod.beamSpriteHeight/2
        else
            local rot = QuatEuler(0,rdm(0,180), 90)
            hod.beamParticlesTrs[i].rot = rot

            local randomSpriteSizeL = rdm(-3, 3)
            local randomSpriteSizeW = rdm(-1, 1)
            DrawSprite(sprites.beam_fire, hod.beamParticlesTrs[i], 8 + randomSpriteSizeL, 1.5 + randomSpriteSizeW, 1, 1, 1, 0.8, 0)

            local beamPos2 = hod.beamParticlesTrs[i].pos
            local beamTr2 = Transform(Vec(beamPos2[1] + rdm(-1, 1), beamPos2[2], beamPos2[3] + rdm(-1, 1)), hod.beamParticlesTrs[i].rot)
            DrawSprite(sprites.beam_fire2, beamTr2, 10 + randomSpriteSizeL, 1 + randomSpriteSizeW, 1, 1, 1, 0.8, 0)

            -- Set new beam tr
            hod.beamParticlesTrs[i].pos[1] = hod.targetPos[1] + rdm(-0.5, 0.5)
            hod.beamParticlesTrs[i].pos[2] = beamTr.pos[2] - hod.beamAnimationSpeed + rdm(-5, 5)
            hod.beamParticlesTrs[i].pos[3] = hod.targetPos[3] + rdm(-0.5, 0.5)

        end
    end

    local heightOffset = 4
    for i = 1, 10 do
        PointLight(VecAdd(hod.raycastPos, Vec(0,i*heightOffset,0)), 1, rdm(0,0.3), 0, rdm(2,13))
    end

end


function initBeamAnimation()
    for i = 1, hod.beamParticles do
        local randomHeightOffset = rdm(0,hod.beamSpriteHeight)
        local tr = Transform(VecAdd(hod.targetPos, Vec(0,randomHeightOffset,0)), QuatEuler(0,90,90))

        hod.beamParticlesTrs[i] = tr
    end
end


function setRaycastTargetPos()
    local targetPosBeamHeight = VecAdd(hod.targetPos, Vec(0,hod.heightOffset,0))
    local rcTargetFloorTr = Transform(targetPosBeamHeight, QuatLookDown(hod.targetPos))
    hod.raycastTargetPos = raycastFromTransform(rcTargetFloorTr)
end


function increaseCharge()
    if hod.charge <= 1 then
        hod.charge = hod.charge + hod.chargeRate
    end
end


--[[SOUND]]
function snd_HodStart()
    PlaySound(sounds.HODFire01, ppos, vols.vol2)
    PlaySound(sounds.HoDStartWarmup, hod.targetPos, 1)
end
function snd_HodEnd()
    PlaySound(sounds.HODEarthCool, hod.targetPos, vols.vol2)
    PlaySound(sounds.HODBeamEnd, ppos, vols.vol2)
end
function snd_HodConvergedLoop()
    PlayLoop(sounds.HODBeamLoopB, hod.targetPos, 1)
    PlayLoop(sounds.HODFireBeam01, hod.targetPos, 100)
    if hod.soundCues.impactPlayed == false then
        PlaySound(sounds.HoDStartImpact, hod.targetPos, 1)
        hod.soundCues.impactPlayed = true
    end
end
function snd_HodConvergingLoop()
    PlayLoop(sounds.HODBeamLoop, hod.targetPos, 1)
    if hod.targetPositiveBeep.timer <= 0 then
        hod.targetPositiveBeep.timer = 60/hod.targetPositiveBeep.rpm
            PlaySound(sounds.HODTargetPositive01, ppos, vols.vol2)
    else
        hod.targetPositiveBeep.timer = hod.targetPositiveBeep.timer - GetTimeStep()
    end
end


--[[DEBUG]]
function debugMod()
    DebugWatch("hod.charge", hod.charge)
    DebugWatch("tool", GetString("game.player.tool"))
end


--[[UTILITY]]
function raycastFromTransform(tr)
    local plyTransform = tr
    local fwdPos = TransformToParentPoint(plyTransform, Vec(0, 0, -1000))
    local direction = VecSub(fwdPos, plyTransform.pos)
    local dist = VecLength(direction)
    direction = VecNormalize(direction)
    local hit, dist = QueryRaycast(tr.pos, direction, dist)
    if hit then
        local hitPos = TransformToParentPoint(plyTransform, Vec(0, 0, dist * -1))
        return hitPos
    end
    return TransformToParentPoint(tr, Vec(0, 0, -1000))
end
function spherecastFromTransform(tr, dist, rad)
    local plyTransform = tr
    local fwdPos = TransformToParentPoint(plyTransform, Vec(0, 0, -1000))
    local direction = VecSub(fwdPos, plyTransform.pos)
    direction = VecNormalize(direction)
    local hit, dist = QueryRaycast(tr.pos, direction, dist, rad)
    if hit then
        local hitPos = TransformToParentPoint(plyTransform, Vec(0, 0, dist * -1))
        return hitPos
    end
    return TransformToParentPoint(tr, Vec(0, 0, -1000))
end
function QuatLookDown(pos)
    local downVec = Vec(0,-1,0)
    local downPos = VecAdd(pos, downVec)
    local downRot = QuatLookAt(pos, downPos)
    return downRot
end
