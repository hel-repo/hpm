local isAvailable
isAvailable = require("component").isAvailable
local parse
parse = require("shell").parse
local exit
exit = os.exit
local write, stderr
do
  local _obj_0 = io
  write, stderr = _obj_0.write, _obj_0.stderr
end
local options, args = { }, { }
local request = nil
local HEL_URL = "http://hel-roottree.rhcloud.com/"
local USAGE = "Usage: hpm [-vq] <command>\n  -q: Quiet mode - no console output.\n  -v: Verbose mode - show additional info.\n  \nAvailable commands:\n  install <package> [...]   Download package[s] from Hel Repository, and install it into the system.\n  remove <package> [...]    Remove all package[s] files from the system.\n  help                      Show this message.\n  \nAvailable package formats:\n  [hel:]<name>[@<version>]  Package from Hel Package Repository (default option).\n  local:<path>              Get package from local file system.\n  pastebin:<id>             Download source code from given Pastebin page.\n  direct:<url>              Fetch file from <url>.\n"
local log = {
  fatal = function(message)
    if not (options.q) then
      stderr:write("[ x( ] " .. tostring(message))
    end
    return exit(1)
  end,
  error = function(message)
    if not (options.q) then
      return stderr:write("[ :( ] " .. tostring(message))
    end
  end,
  info = function(message)
    if options.v then
      return print("[ :) ] " .. tostring(message))
    end
  end
}
local assert
assert = function(statement, message)
  if not (statement) then
    return log.fatal(message)
  end
end
local unimplemented
unimplemented = function(what)
  return log.fatal((tostring(what)) .. ": Not implemented yet!")
end
local printUsage
printUsage = function()
  write(USAGE)
  return exit(0)
end
local empty
empty = function(str)
  return not str or #str < 1
end
local parseArguments
parseArguments = function(...)
  args, options = parse(...)
  if #args < 1 then
    return printUsage()
  end
end
local parsePackageName
parsePackageName = function(value)
  return value:match("^([^:]-):?([^:@]+)@?([^:@]*)$")
end
local checkInternet
checkInternet = function()
  if not (isAvailable("internet")) then
    log.fatal("This command requires an internet card to run!")
  end
  request = require("internet").request
end
local downloadPackageJSON
downloadPackageJSON = function(name)
  log.info("Downloading... ")
  local result, response = pcall(request(HEL_URL .. "packages/" .. name))
  if result then
    log.info("success.")
    return response
  else
    log.info("failed.")
    return log.fatal("HTTP request failed: " .. tostring(response))
  end
end
local parsePackageJSON
parsePackageJSON = function(json, version)
  return unimplemented("JSON parsing")
end
local installPackage
installPackage = function(source, name, version)
  if not (name) then
    log.fatal("Incorrect package name!")
  end
  local package
  if empty(source or source == "hel") then
    checkInternet()
    package = parsePackageJSON(downloadPackageJSON(name), version)
  elseif source == "local" then
    package = unimplemented("local install")
  elseif source == "pastebin" then
    package = unimplemented("pastebin fetching")
  elseif source == "direct" then
    package = unimplemented("direct downloading")
  else
    package = log.fatal("Unknown source format: '" .. tostring(source) .. "'!")
  end
  return unimplemented("package installation")
end
local removePackage
removePackage = function(source, name, version)
  return unimplemented("remove package")
end
local process
process = function()
  local _exp_0 = args[1]
  if "install" == _exp_0 then
    if #args < 2 then
      log.fatal("No package(s) was provided!")
    end
    for i = 2, #args do
      installPackage(parsePackageName(args[i]))
    end
  elseif "remove" == _exp_0 then
    if #args < 2 then
      log.fatal("No package(s) was provided!")
    end
    for i = 2, #args do
      removePackage(parsePackageName(args[i]))
    end
  else
    return printUsage()
  end
end
parseArguments(...)
process()
return 0
