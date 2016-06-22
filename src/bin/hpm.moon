import isAvailable from require "component"
import request from require "internet"
import parse from require "shell"

options = {}

-- Logging functions
log = (message) -> if not options.q then io.write message
error = (message) -> if not options.q then io.stderr\write message


-- Check requirements
if not isAvailable "internet"
  error "This program requires an internet card to run."
  return


-- Parse command line arguments
args, options = parse ...

if #args < 1
  log "Usage: hpm [-q] <command> [<package>]\n"
  log " -q: Quiet mode - no status messages.\n"
  log "\n"
  log "Available commands:\n"
  log " install <package>: Downloads package from\n"
  log "     Hel Repository, and install it into\n"
  log "     the system.\n"
  log " remove <package>: Removes all package\n"
  log "     files from the system.\n"
  return


-- Commands implementation
install = (package) ->
  if not package
    error "No package name was provided!"
  else
    error "install: Not implemented yet."

remove = (package) ->
  if not package
    error "No package name was provided!"
  else
    error "remove: Not implemented yet."


-- Process given command
switch args[1]
  when "install"
    install args[2]
  when "remove"
    remove args[2]