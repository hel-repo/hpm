local isAvailable
isAvailable = require("component").isAvailable
local request
request = require("internet").request
local parse
parse = require("shell").parse
local options = { }
local HEL_URL = "http://hel-roottree.rhcloud.com/"
local log
log = function(message)
  if not options.q then
    return io.write(message)
  end
end
local error
error = function(message)
  if not options.q then
    return io.stderr:write(message)
  end
end
local assert
assert = function(statement, message)
  if not statement then
    if not options.q then
      error(message)
    end
    return 
  end
end
if not isAvailable("internet") then
  error("This program requires an internet card to run.")
  return 
end
local args
args, options = parse(...)
if #args < 1 then
  log("Usage: hpm [-q] <command> [<package>]\n")
  log(" -q: Quiet mode - no status messages.\n")
  log("\n")
  log("Available commands:\n")
  log(" install <package>: Downloads package from\n")
  log("     Hel Repository, and install it into\n")
  log("     the system.\n")
  log(" remove <package>: Removes all package\n")
  log("     files from the system.\n")
  return 
end
local parsePackageJSON
parsePackageJSON = function(json)
  return error("JSON parsing: Not implemented yet.")
end
local install
install = function(package)
  if not package then
    return error("No package name was provided!")
  else
    log("Downloading... ")
    local result, response = pcall(request(HEL_URL .. "packages/" .. package))
    if result then
      log("success.\n")
      return parsePackageJSON(response)
    else
      log("failed.\n")
      return error("HTTP request failed: " .. tostring(response) .. "\n")
    end
  end
end
local remove
remove = function(package)
  if not package then
    return error("No package name was provided!")
  else
    return error("remove: Not implemented yet.")
  end
end
local _exp_0 = args[1]
if "install" == _exp_0 then
  return install(args[2])
elseif "remove" == _exp_0 then
  return remove(args[2])
end
