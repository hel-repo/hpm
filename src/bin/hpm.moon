import isAvailable from require "component"
import request from require "internet"
import parse from require "shell"

import exit from os

--------------------------------------------------------------------------------

-- Vatiables
options = {}

-- Constants
HEL_URL = "http://hel-roottree.rhcloud.com/"
USAGE = "Usage: hpm [-vqQ] <command> [<package>]
  -q: Quiet mode - no error messages.

Available commands:
  install <package>: Downloads package from
      Hel Repository, and install it into
      the system.
  remove <package>: Removes all package
      files from the system.
"

--------------------------------------------------------------------------------

-- Logging functions
log = (message) -> if not options.q then io.write message
error = (message) -> if not options.q then io.stderr\write message
assert = (statement, message) -> if not statement
  if not options.q then error message
  return

-- Check requirements
checkSystem = ->
  unless isAvailable "internet"
    error "This program requires an internet card to run."
    exit!


-- Parse command line arguments
parseCLI = ->
  args, options = parse ...

  if #args < 1
    print USAGE
    exit!

-- Commands implementation
parsePackageJSON = (json) ->
  error "JSON parsing: Not implemented yet."

install = (package) ->
  unless package
    error "No package name was provided!"
  else
    log "Downloading... "
    result, response = pcall request HEL_URL .. "packages/" .. package
    if result
      log "success.\n"
      parsePackageJSON response
    else
      log "failed.\n"
      error "HTTP request failed: " .. tostring(response) .. "\n"

remove = (package) ->
  unless package
    error "No package name was provided!"
  else
    error "remove: Not implemented yet."

-- Process given command
process = ->
  switch args[1]
    when "install"
      install args[2]
    when "remove"
      remove args[2]

--------------------------------------------------------------------------------
checkSystem!
parseCLI!
process!
