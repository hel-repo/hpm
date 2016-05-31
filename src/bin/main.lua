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
local outputLevel = outputLevels.debug

local tRemove, tUnpack = table.remove, table.unpack

------------------------------------------
-- Utils

function contains(table, element)
  for k, value in pairs(table) do
    if value == element then
      return true, k
    end
  end
  
  return false
end

------------------------------------------
-- Output

local setFG, getFG = gpu.setForeground, gpu.getForeground
local write = io.write
local format, rep = string.format, string.rep

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

  oInfo  = outputFactory(outputLevels.info,  "::", colors.info)
  oSucc  = outputFactory(outputLevels.succ,  "++", colors.succ)
  oWarn  = outputFactory(outputLevels.warn,  "!!", colors.warn, colors.warn)
  oError = outputFactory(outputLevels.error, "--", colors.error, colors.error)
  oDebug = outputFactory(outputLevels.debug, "··", colors.debug, colors.debug)
end

local function oPadding(color, string, padding)
  if colorsOn then
    setFG(color)
    write(rep(" ", padding or 6))
    write(string .. "\n")
  else
    write(rep(" ", padding or 6) .. string .. "\n")
  end
end

local function oArrow(arrowColor, string, padding, textColor, noEndLine)
  if colorsOn then
    setFG(arrowColor)
    write(rep(" ", padding or 1) .. "=> ")
    setFG(textColor or colors.white)
    write(string .. (noEndLine and "" or "\n"))
  else
    write(rep(" ", padding or 1).. "=> " .. string .. "\n")
  end
end

local function oLine()
  write("\n")
end

------------------------------------------
-- Input

local read = io.read

local function iQuestion(text, correctAnswers, onInput, default, likeList)
  local wasRead = false
  local finalInput, finalInputIndex
  
  while not wasRead do
    if colorsOn then
      setFG(colors.info)
      write(" [??] ")
      setFG(colors.white)
      write(text)
    else
      write(" [??] " .. text)
    end
    
    if likeList then
      write(".\n")
      
      for i, option in ipairs(correctAnswers) do
        if colorsOn then
          setFG(colors.info)
        end
        
        if default and i == default then
          write(rep(" ", 6) .. i .. ". [Default] ")
        else
          write(rep(" ", 6) .. i .. ". ")
        end
        
        if colorsOn then
          setFG(colors.white)
        end
        
        write(option .. "\n")
      end
      
      oArrow(colors.info, "Answer (1-" .. tonumber(#correctAnswers) .. "): ", _, _, true)
      local input = read()
      
      local inputN = tonumber(input)
      
      if input and inputN and inputN > 0 and inputN <= #correctAnswers then
        wasRead = true
        finalInput = correctAnswers[inputN]
        finalInputIndex = inputN
      elseif default then
        wasRead = true
        finalInput = correctAnswers[default]
        finalInputIndex = default
      end
    else
      write(" (")
      
      for i, option in ipairs(correctAnswers) do
        if default and i == default then
          write("[" .. option .. "]")
        else
          write(option)
        end
        
        if i < #correctAnswers then
          write("/")
        end
      end
      write("): ")
      
      local input = read()
      
      local containsInput, key = contains(correctAnswers, input)
      
      if input and containsInput then
        wasRead = true
        finalInput = input
        finalInputIndex = key
      elseif default then
        wasRead = true
        finalInput = correctAnswers[default]
        finalInputIndex = default
      end
    end
  end
  
  return onInput(finalInput, finalInputIndex) or true
end

------------------------------------------
-- Main function

local function main(...)
  oInfo("I'm info!")
  oSucc("I'm success!")
  oWarn("I'm warning!")
  oError("I'm error!")
  oDebug("I'm debug!")
  
  oLine()
  
  oError("I'm very very very")
  oPadding(colors.error, "long error")
  
  oLine()
  
  question("Are you sure want to do something?", {"y", "n"}, function (input)
    oSucc("Yup! `%s`", input)
  end, 1)
  
  oLine()
  
  question("Are you sure want to do something?", 
    {"Yes!", "No!", "Shut Up!"}, function (input)
      oSucc("Yup! `%s`", input)
    end, 
  1, true)

  oLine()
  
  question("Are you sure want to do something?", {"y", "n"}, function (input)
    oSucc("Yup! `%s`", input)
  end)
  
  oLine()
  
  question("Are you sure want to do something?", 
    {"Yes!", "No!", "Shut Up!"}, function (input)
      oSucc("Yup! `%s`", input)
    end, 
  _, true)
  
  setFG(colors.white)
end

------------------------------------------
-- Config file

main(...)
