--[[VECTOR]]
function CalcDistance(vec1, vec2)
    return VecLength(VecSub(vec1, vec2))
end
--- return number if not = 0, else return 0.00000001
function rdmVec(min, max)
    return Vec(rdm(min, max),rdm(min, max),rdm(min, max))
end
--- Prints quats or vectors. dec = decimal places. dec default = 3. title is optional.
function printVec(vec, dec, title)
    DebugPrint(
        (title or "") .. 
        "  " .. sfn(vec[1], dec or 2) ..
        "  " .. sfn(vec[2], dec or 2) ..
        "  " .. sfn(vec[3], dec or 2)
    )
end
--- Fully prints quats or vectors will all decimals. title is optional.
function printVecf(vec, title)
    DebugPrint(
        (title or "") .. 
        "  " .. sfn(vec[1]) ..
        "  " .. sfn(vec[2]) ..
        "  " .. sfn(vec[3])
    )
end
function particleLine(vec1, vec2, particle, density, thickness)
    local maxLength = 500 -- prevents infinite particle line crashing your game.
    local transform = Transform(vec1, QuatLookAt(vec1,vec2))
    for i=1, VecLength(VecSub(vec1, vec2))*(density or 1) do
        if i < maxLength then
            local fwdpos = TransformToParentPoint(transform, Vec(0,0,-i/(density or 1)))
            SpawnParticle(particle or "darksmoke", fwdpos, 1, 1 or thickness, 0.2, 0, 0)
        end
    end
end



--[[RAYCAST]]
function raycastFromTransform(tr)
    local plyTransform = tr
    local fwdPos = TransformToParentPoint(plyTransform, Vec(0, 0, -3000))
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



--[[SFX]]
local debugSounds = {
    beep = LoadSound("warning-beep"),
    buzz = LoadSound("light/spark0"),
    chime = LoadSound("elevator-chime"),}
function beep(vol) PlaySound(debugSounds.beep, GetPlayerPos(), vol or 0.3) end
function buzz(vol) PlaySound(debugSounds.buzz, GetPlayerPos(), vol or 0.3) end
function chime(vol) PlaySound(debugSounds.chime, GetPlayerPos(), vol or 0.3) end



--[[MATH]]
function round(number, decimals)
    local power = 10^decimals
    return math.floor(number * power) / power
end
--- return number if > 0, else return 0.00000001
function gtZero(val)
    if val <= 0 then
        return 0.0000001
    end
    return val
end
--- return number if not = 0, else return 0.00000001
function nZero(val)
    if val == 0 then return 0.0000001 end
    return val
end
--- return number if not = 0, else return 0.00000001
function rdm(min, max)
    return math.random(min or 0, max or 1)
end




--[[FORMATTING]]
--- string format. default 2 decimals.
function sfn(numberToFormat, dec)
    local s = (tostring(dec or 2))
    return string.format("%."..s.."f", numberToFormat)
end