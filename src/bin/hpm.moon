import isAvailable from require "component"
import parse from require "shell"

import exit from os
import write, stderr from io

--------------------------------------------------------------------------------

-- Variables
options, args = {}, {}
request = nil

-- Constants
HEL_URL = "http://hel-roottree.rhcloud.com/"
USAGE   = "Usage: hpm [-vq] <command>
  -q: Quiet mode - no error messages.
  -v: Verbose mode - show additional info.

Available commands:
  install <package>...  Download package from Hel Repository, and install it into the system.
  remove <package>...   Remove all package files from the system.
  help                  Show this message

Aviable package formats:
  [hel:]<name>[@version]  Install package from HEL Package Repository.
"

--------------------------------------------------------------------------------

-- Logging functions
log =
  fatal: (message) -> 
    stderr\write "[ x( ] " .. tostring message unless options.q
    exit 1,
  error: (message) -> stderr\write "[ :( ] " .. tostring message unless options.q,
  info: (message) -> print "[ :) ] " .. tostring message if options.v

assert = (statement, message) -> log.fatal message unless statement

unimplemented = (what) -> log.fatal (tostring what) .. ": Not implemented yet!"

printUsage = ->
  write USAGE
  exit 0

-- Check if given string contains something useful
empty = (str) -> not str or #str < 1

--------------------------------------------------------------------------------

-- Parse command line arguments
parseArguments = (...) ->
  args, options = parse ...
  printUsage! if #args < 1

-- Return (source, name, version) from "[<source>:]<name>[@<version>]" string
parsePackageName = (value) ->
  value\match("^([^:]-):?([^:@]+)@?([^:@]*)$")

-- Check for internet availability
checkInternet = ->
  log.fatal "This command requires an internet card to run!" unless isAvailable "internet"
  request = require("internet").request

-- Download JSON from repository
downloadPackageJSON = (name) ->
  log.info "Downloading... "
  result, response = pcall request HEL_URL .. "packages/" .. name
  if result
    log.info "success."
    return response
  else
    log.info "failed."
    log.fatal "HTTP request failed: " .. tostring(response)

-- Get package data from JSON, and return as a table
parsePackageJSON = (json, version) ->
  unimplemented "JSON parsing"

--------------------------------------------------------------------------------

-- Commands implementation
installPackage = (source, name, version) ->
  log.fatal "Incorrect package name!" unless name
  package = if empty source or source == "hel"
    checkInternet!
    parsePackageJSON downloadPackageJSON(name), version
  elseif source == "local"
    unimplemented "local install"
  elseif source == "pastebin"
    unimplemented "pastebin fetching"
  elseif source == "gist"
    unimplemented "gist fetching"
  elseif source == "github"
    unimplemented "github fetching"
  elseif source == "direct"
    unimplemented "direct downloading"
  else
    log.fatal "Unknown source format: '#{source}'!"
  unimplemented "package installation"

removePackage = (source, name, version) ->
  unimplemented "remove package"

--------------------------------------------------------------------------------

-- Process given command and arguments
process = ->
  switch args[1]
    when "install"
      log.fatal "No package(s) was provided!" if #args < 2
      for i = 2, #args do installPackage parsePackageName args[i]
    when "remove"
      log.fatal "No package(s) was provided!" if #args < 2
      for i = 2, #args do removePackage parsePackageName args[i]
    else
      printUsage!

--------------------------------------------------------------------------------

-- Run!
parseArguments ...
process!
0
