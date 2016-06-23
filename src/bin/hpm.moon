import isAvailable from require "component"
import parse from require "shell"

import exit from os
import write, stderr from io

--------------------------------------------------------------------------------

-- Variables
options, args = {}, {}

-- Constants
HEL_URL = "http://hel-roottree.rhcloud.com/"
USAGE   = "Usage: hpm [-vq] <command>
  -q: Quiet mode - no error messages.
  -v: Verbose mode - many useful logs.

Available commands:
  install <package>...  Download package from Hel Repository, and install it into the system.
  remove <package>...   Remove all package files from the system.
  help                  Show this message

Aviable package formats:
  [hel:]<name>[@version]  Install package from HEL Package Repository.
"

--------------------------------------------------------------------------------

-- Logging functions
log = (level, message) ->
  switch level
    when "fatal"
      print "[ )x ] " .. tostring message unless options.q
    when "error"
      print "[ ): ] " .. tostring message unless options.q
    when "info"
      print "[ (: ] " .. tostring message if options.v

error = (message) ->
  log "fatal", message
  exit 1

assert        = (statement, message) -> error message unless statement
unimplemented = (what) -> error (tostring what) .. ": Not implemented yet!"
printUsage    = ->
  write USAGE
  exit 0

--------------------------------------------------------------------------------

installCMD = () ->
  if #args < 2
    error "No package(s) was provided!"
  else
    unimplemented "install"

removeCMD = () ->
  if #args < 2
    error "No package(s) was provided!"
  else
    unimplemented "remove"

-- Parse command line arguments
parseCLI = (...) ->
  args, options = parse ...

  if #args < 1
    printUsage!

-- Commands implementation
parsePackageJSON = (json) ->
  unimplemented "JSON parsing"

-- Process given command
process = ->
  switch args[1]
    when "install"
      installCMD!
    when "remove"
      removeCMD!
    when "help"
      printUsage!
    else
      printUsage!

--------------------------------------------------------------------------------
parseCLI ...
process!
