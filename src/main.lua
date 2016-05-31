local component = require("component")
local gpu = component.gpu

------------------------------------------
-- Data

local colors = {
  info  = 0x66A9BA,
  succ  = 0x33FF33,
  warn  = 0xFDA53C,
  error = 0xFF3333,
  debug = 0xBBBBBB,
  
  white = 0xFFFFFF
}

local outputLevels = {
  info  = 0,
  succ  = 1,
  warn  = 2,
  error = 3,
  debug = 4
}

local colorsOn = true
local outputLevel = 4

------------------------------------------
-- I/O

local setFG, getFG = gpu.setForeground, gpu.getForeground
local write = io.write
local format = string.format

local oInfo, oSucc, oWarn, oError, oDebug
do  -- create output functions, like debug, info, error
  local function outputFactory(level, prefix, prefixColor, textColor)
    return function (string, ...)
      if outputLevel < level then
        return
      end
      
      if colorsOn then
        setFG(prefixColor)
        write(" [" .. prefix .. "] ")
        setFG(textColor or colors.white)
        write(format(string, ...) .. "\n")
      else
        write(" [" .. prefix .. "] " .. format(string, ...) .. "\n")
      end
    end
  end

  oInfo  = outputFactory(outputLevels.info,  "==", colors.info)
  oSucc  = outputFactory(outputLevels.succ,  "++", colors.succ)
  oWarn  = outputFactory(outputLevels.warn,  "!!", colors.warn, colors.warn)
  oError = outputFactory(outputLevels.error, "!!", colors.error, colors.error)
  oDebug = outputFactory(outputLevels.debug, "--", colors.debug, colors.debug)
end

------------------------------------------
-- Main function

function main(...)
  oInfo("I'm info!")
  oSucc("I'm success!")
  oWarn("I'm warning!")
  oError("I'm error!")
  oDebug("I'm debug!")
  
  setFG(colors.white)
end

main(...)
