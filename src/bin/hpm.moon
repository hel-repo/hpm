import isAvailable from require "component"
import parse from require "shell"

import exit from os
import write, stderr from io


--------------------------------------------------------------------------------

-- Variables
options, args = {}, {}  -- command-line arguments
request = nil           -- internet request method (call checkInternet to instantiate)
modules = {}            -- distribution modules

-- Constants
USAGE   = "Usage: hpm [-vq] <command>
  -q: Quiet mode - no console output.
  -v: Verbose mode - show additional info.
  
Available commands:
  install <package> [...]   Download package[s] from Hel Repository, and install it into the system.
  remove <package> [...]    Remove all package[s] files from the system.
  help                      Show this message.
  
Available package formats:
  [hel:]<name>[@<version>]  Package from Hel Package Repository (default option).
  local:<path>              Get package from local file system.
  pastebin:<id>             Download source code from given Pastebin page.
  direct:<url>              Fetch file from <url>.
"


-- Logging functions -----------------------------------------------------------

log =
  fatal: (message) -> 
    stderr\write "[ x( ] " .. tostring message unless options.q
    exit 1
  error: (message) -> stderr\write "[ :( ] " .. tostring message unless options.q
  info: (message) -> print "[ :) ] " .. tostring message if options.v

assert = (statement, message) -> log.fatal message unless statement

unimplemented = (what) -> log.fatal (tostring what) .. ": Not implemented yet!"

printUsage = ->
  write USAGE
  exit 0


-- Helper methods --------------------------------------------------------------

-- Check if given string contains something useful
empty = (str) -> not str or #str < 1

-- Return (source, name, meta) from "[<source>:]<name>[@<meta>]" string
parsePackageName = (value) ->
  value\match("^([^:]-):?([^:@]+)@?([^:@]*)$")

-- Check for internet availability
checkInternet = ->
  log.fatal "This command requires an internet card to run!" unless isAvailable "internet"
  request = require("internet").request

-- Try to find module corresponding to source string
-- TODO: implement custom modules loading
getModuleBy = (source) ->
  switch source
    when "" then modules.hel
    when "hel" then modules.hel
    else modules.default

-- Call module operation (with fallback to default module)
callModuleMethod = (mod, name, ...) ->
  mod = mod or modules.default
  if mod[name] then mod[name](mod, ...)
  else modules.default[name](modules.default, ...)


-- Distribution modules --------------------------------------------------------
--
-- Each module must provide several methods:
-- Required:
--   install(self, name, meta)    -- install files from given package data
--                                -- must return 'package manifest'
--                                -- (installed package description table)
-- Optional:
--   remove(self, manifest)       -- remove files
--   upgrade(self, m_from, m_to)  -- replace one package version with another
--
-- Omitted methods will be replaced with default implementations

-- Default module
modules.default = {
  install: -> log.fatal "Incorrect source was provided! No default 'install' implementation."
  remove: -> unimplemented "default removal"
  upgrade: -> unimplemented "default upgrade"
}

-- Hel Repository module
modules.hel = {
  -- Repository API root url
  URL: "http://hel-roottree.rhcloud.com/"

  -- Download JSON from repository
  downloadPackageJSON: (self, name) ->
    log.info "Downloading... "
    result, response = pcall request @URL .. "packages/" .. name
    if result
      log.info "success."
      return response
    else
      log.info "failed."
      log.fatal "HTTP request failed: " .. tostring(response)

  -- Get package data from JSON, and return as a table
  parsePackageJSON: (self, json, version) ->
    unimplemented "JSON parsing"

  -- Get package from repository, parse, and install
  install: (self, name, version) ->
    checkInternet!
    json = @downloadPackageJSON name
    log.info "JSON data was downloaded: " .. json
    data = @parsePackageJSON json, version
    unimplemented "installation from hel"
}

-- Local-install module
modules.local = {

}


-- Commands implementation -----------------------------------------------------

installPackage = (source, name, meta) ->
  log.fatal "Incorrect package name!" unless name
  callModuleMethod getModuleBy(source), "install", name, meta

removePackage = (source, name, meta) ->
  log.fatal "Incorrect package name!" unless name
  unimplemented "package removal"


-- App working -----------------------------------------------------------------

-- Parse command line arguments
parseArguments = (...) ->
  args, options = parse ...
  printUsage! if #args < 1

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

-- Run!
parseArguments ...
process!
0
