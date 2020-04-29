local LIMIT_7_RATIOS = {16/15, 9/8, 6/5, 5/4, 4/3, 7/5, 3/2, 8/5, 5/3, 16/9, 15/8, 2}

local JustIntonation = {}

function JustIntonation.calculate_freq_mul(interval)
  if interval == 0 then
    return 1
  else
    local result
    local negative_interval = interval < 0
    if negative_interval then interval = -interval end
    result = LIMIT_7_RATIOS[((interval - 1) % 12) + 1] * math.ceil(interval / 12)
    if negative_interval then result = 1 / result end
    return result
  end
end

return JustIntonation
