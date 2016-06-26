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
local modules = { }
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
local getModuleBy
getModuleBy = function(source)
  local _exp_0 = source
  if "" == _exp_0 then
    return modules.hel
  elseif "hel" == _exp_0 then
    return modules.hel
  else
    return modules.default
  end
end
local callModuleMethod
callModuleMethod = function(mod, name, ...)
  mod = mod or modules.default
  if mod[name] then
    return mod[name](mod, ...)
  else
    return modules.default[name](modules.default, ...)
  end
end
modules.default = {
  install = function()
    return log.fatal("Incorrect source was provided! No default 'install' implementation.")
  end,
  remove = function()
    return unimplemented("default removal")
  end,
  upgrade = function()
    return unimplemented("default upgrade")
  end
}
modules.hel = {
  URL = "http://hel-roottree.rhcloud.com/",
  downloadPackageJSON = function(self, name)
    log.info("Downloading... ")
    local result, response = pcall(request(self.URL .. "packages/" .. name))
    if result then
      log.info("success.")
      return response
    else
      log.info("failed.")
      return log.fatal("HTTP request failed: " .. tostring(response))
    end
  end,
  parsePackageJSON = function(self, json, version)
    return unimplemented("JSON parsing")
  end,
  install = function(self, name, version)
    checkInternet()
    local json = self:downloadPackageJSON(name)
    log.info("JSON data was downloaded: " .. json)
    local data = self:parsePackageJSON(json, version)
    return unimplemented("installation from hel")
  end
}
modules["local"] = { }
local installPackage
installPackage = function(source, name, meta)
  if not (name) then
    log.fatal("Incorrect package name!")
  end
  return callModuleMethod(getModuleBy(source), "install", name, meta)
end
local removePackage
removePackage = function(source, name, meta)
  if not (name) then
    log.fatal("Incorrect package name!")
  end
  return unimplemented("package removal")
end
local parseArguments
parseArguments = function(...)
  args, options = parse(...)
  if #args < 1 then
    return printUsage()
  end
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
