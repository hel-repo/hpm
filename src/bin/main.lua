local toml = require("toml")
local fs = require("filesystem")
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

local config = {}
local defaultConfig = {
  tmp = "/tmp/.hpm"
}

------------------------------------------
-- Optimization

local tRemove, tUnpack = table.remove, table.unpack
local getenv, setenv = os.getenv, os.setenv
local fConcat, fExists, fMD = fs.concat, fs.exists, fs.makeDirectory
local setFG, getFG = gpu.setForeground, gpu.getForeground
local write = io.write
local format, rep = string.format, string.rep
local read, open = io.read, io.open

------------------------------------------
-- Utils

local function contains(table, element)
  for k, value in pairs(table) do
    if value == element then
      return true, k
    end
  end
  
  return false
end

------------------------------------------
-- Output

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

local function iQuestion(text, correctAnswers, onInput, default, likeList, color)
  local wasRead = false
  local finalInput, finalInputIndex
  
  while not wasRead do
    if colorsOn then
      setFG(color or colors.info)
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
          setFG(color or colors.info)
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
  
  return onInput(finalInput, finalInputIndex)
end

function iText(text, color)
  while true do
    if colorsOn then
      setFG(color or colors.info)
      write(" [??] ")
      setFG(colors.white)
      write(text .. ": ")
    else
      write(" [??] " .. text .. ": ")
    end
    
    local input = read()
    
    if input then
      return input
    end
  end
end

------------------------------------------
-- Config

local function readConfig()
  oInfo("Reading configuration file...")
  oDebug("Getting HPM_ROOT...")
  local env = getenv("HPM_ROOT")
  
  if not env then
    oLine()
    
    oDebug("HPM_ROOT does NOT exists.")
    oWarn("HPM_ROOT variable does NOT exists.")
    if not iQuestion("Do you want to specify it?", {"y", "n"}, function (input)
          if input == "y" then
            setenv("HPM_ROOT", iText("HPM_ROOT", colors.warn))
            return true
          end
          
          oLine()
          
          oError("Configuration file has NOT been read!")
          return
        end, 1, _, colors.warn) then
        
      return
    end
  else
    oDebug("HPM_ROOT found: %s!", env)
  end
  
  env = getenv("HPM_ROOT")
  
  if not fs.exists(env) then
    oDebug("Directory %s does NOT exists!", env)
    oDebug("Making directory %s...", env)
    local ok, err = fs.makeDirectory(env)
    
    if not ok then
      oLine()
      
      oDebug("Could NOT create directory (%s): %s", env, err)
      oError("Could NOT create directory (%s): %s", env, err)
      
      oLine()
      
      oError("Configuration file has NOT been read!")
      return
    end
    
    oDebug("Directory %s has been made!", env)
  end
  
  local conf_path = fs.concat(env, "config.toml")
  
  if not fs.exists(conf_path) then
    oDebug("File %s does NOT exists!", conf_path)
    
    oLine()
    
    oWarn("Could NOT find configuration file in HPM_ROOT.")
    if not iQuestion("Do you want to set default config?", {"y", "n"}, function (input)
          if input == "y" then
            oDebug("Opening file %s...", conf_path)
            local file, err = open(conf_path, "w")
            
            if not file then
              oDebug("File %s has NOT been opened!", conf_path)
              oError("Could not open %s: %s", conf_path, err)
              
              oLine()
              
              oError("Configuration file has NOT been read!")
              return
            end
            
            oDebug("File %s has been opened!", conf_path)
            oDebug("Writing default config...")
            
            file:write(toml.encode(defaultConfig))
            file:flush()
            file:close()
            
            oDebug("Default config has been wrote.")
            return true
          end
          
          oLine()
          
          oError("Configuration file has NOT been read!")
          return
        end, 1, _, colors.warn) then
        
      return
    end
  end

  oDebug("Opening file %s...", conf_path)
  local file, err = open(conf_path, "r")
  
  if not file then
    oLine()
    
    oDebug("File %s has NOT been opened!", conf_path)
    oError("Could not open %s: %s", conf_path, err)
    
    oLine()
    
    oError("Configuration file has NOT been read!")
    return
  end
  
  oDebug("File %s has been opened!", conf_path)
  oDebug("Reading & parsing config...")
  local config_str = file:read("*all")
  local ok, config_table = pcall(toml.parse, config_str)
  
  if not ok then
    oDebug("TOML error: %s", config_table)
    oError("TOML error: %s", config_table)
    
    oLine()
    
    oError("Configuration file has NOT been read!")
    return
  end
  
  config = config_table  -- yeah!
end

------------------------------------------
-- Main function

local function main(...)
  oDebug("M-m-m... Cookies...")
  
  readConfig()
end

main(...)
setFG(colors.white)
