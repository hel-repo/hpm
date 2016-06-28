import isAvailable from require "component"
import parse from require "shell"
import exists, makeDirectory, concat, remove from require "filesystem"
import serialize, unserialize from require "serialization"

import exit from os
import write, stderr from io
import insert from table


-- Variables
options, args = {}, {}  -- command-line arguments
request = nil           -- internet request method (call checkInternet to instantiate)
modules = {}            -- distribution modules

-- Constants
DIST_PATH = "/etc/hpm"  -- there will be stored manifests of installed packages
USAGE = "Usage: hpm [-vq] <command>
  -q: Quiet mode - no console output.
  -v: Verbose mode - show additional info.
  
Available commands:
  install <package> [...]   Download package[s] from Hel Repository, and install it into the system.
  remove <package> [...]    Remove all package[s] files from the system.
  save <package> [...]      Download package[s] without installation.
  help                      Show this message. 
  
Available package formats:
  [hel:]<name>[@<version>]  Package from Hel Package Repository (default option).
  local:<path>              Get package from local file system.
  pastebin:<name>@<id>      Download source code from given Pastebin page.
  direct:<name>@<url>       Fetch file from <url>."


-- Logging functions -----------------------------------------------------------

log =
  info: (message) -> print message if options.v
  print: (message) -> print message unless options.q
  error: (message) -> stderr\write message .. '\n' unless options.q
  fatal: (message) -> 
    stderr\write message .. '\n' unless options.q
    exit 1

assert = (statement, message) -> log.fatal message unless statement

unimplemented = (what) -> log.fatal (tostring what) .. ": Not implemented yet!"

printUsage = ->
  write USAGE
  exit 0

try = (result, reason) ->
  log.fatal reason unless result
  result


-- Helper methods --------------------------------------------------------------

-- Check if given string contains something useful
empty = (str) -> not str or #str < 1

-- Return (source, name, meta) from "[<source>:]<name>[@<meta>]" string
parsePackageName = (value) ->
  value\match("^([^:]-):?([^:@]+)@?([^:@]*)$")

-- Check for internet availability
checkInternet = ->
  log.fatal "This command requires an internet card to run!" unless isAvailable "internet"
  request = request or require("internet").request

-- Download something
download = (url) ->
  checkInternet!
  pcall request, url

-- Try to find module corresponding to the 'source' string
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

-- Save manifest to dist-data folder
saveManifest = (manifest) ->
  if not exists DIST_PATH
    result, reason = makeDirectory DIST_PATH
    if not result
      return false, "Failed creating '#{DIST_PATH}' directory for manifest files: #{reason}"

  file, reason = io.open concat(DIST_PATH, manifest.name), "w"
  if file
    file\write serialize manifest
    file\close!
    true
  else
    false, "Failed opening file for writing: #{reason}"

-- Read package manifest from file
loadManifest = (name) ->
  path = concat DIST_PATH, name
  if exists path
    file, reason = io.open path, "rb"
    if file
      manifest = unserialize file\read "*all"
      file\close!
      manifest
    else false, "Failed to open manifest for '#{name }' package: #{reason}"
  else false, "No manifest found for '#{name}' package"

-- Delete manifest file
removeManifest = (name) ->
  path = concat DIST_PATH, name
  if exists path then remove path
  else false, "No manifest found for '#{name}' package"


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
--   save(self, name, meta)       -- download package without installation
--
-- Omitted methods will be replaced with default implementations

-- Default module
modules.default = {
  install: -> log.fatal "Incorrect source was provided! No default 'install' implementation."
  
  remove: (self, manifest) -> 
    if manifest
      if manifest.files
        for i, file in pairs(manifest.files)
          path = concat file.dir, file.name
          result, reason = remove path
          return false, "Failed removing '#{path}' file: #{reason}" unless result
      removeManifest manifest.name
    else
      false, "Package cannot be removed: empty manifest."
  
  upgrade: -> unimplemented "default upgrade"
}

-- Hel Repository module
modules.hel = {
  -- Repository API root url
  URL: "http://hel-roottree.rhcloud.com/"

  -- Get package data from JSON, and return as a table
  parsePackageJSON: (self, json, versionNumber) ->
    selectedVersion, selectedNumber = nil, nil
    versions = json\match '"versions":%s*(%b[])'

    for version in versions\gmatch("%b{}") do
      number = version\match '"number":%s*"(.-)"'
      if number == versionNumber then
        selectedVersion, selectedNumber = version, number
        break
      elseif selectedVersion == nil or selectedNumber < number
        selectedVersion, selectedNumber = version, number

    log.fatal "Incorrect JSON format!\n" .. json unless selectedVersion

    data = { version: selectedNumber, files: {} }
    files = selectedVersion\match '"files":%s*(%b[])'

    for file in files\gmatch("%b{}") do
      url = file\match '"url":%s*"(.-)"'
      dir = file\match '"dir":%s*"(.-)"'
      name = file\match '"name":%s*"(.-)"'
      insert data.files, { :url, :dir, :name }

    data


  -- Get package from repository, then parse, and install
  install: (self, name, version) ->
    log.print "Downloading package data ..."
    status, response = download @URL .. "packages/" .. name
    log.fatal "HTTP request error: " .. response unless status

    json = ""
    for chunk in response do json ..= chunk

    data = @parsePackageJSON json, version

    for key, file in pairs(data.files) do
      f = nil
      result, response = download file.url
      if result
        log.print "Fetching '#{file.name}' ..."

        if not exists file.dir
          result, response = makeDirectory file.dir
          log.fatal "Failed creating '#{file.path}' directory for '#{file.name}'! \n#{response}" unless result

        result, reason = pcall ->
          for chunk in response do
            if not f then
              f, reason = io.open concat(file.dir, file.name), "wb"
              assert f, "Failed opening file for writing: " .. tostring(reason)
            f\write(chunk)

      if f then f\close!
      log.fatal "Failed to download '#{file.name}' from '#{file.url}'! \n#{response}" unless result

      log.print "Done."

    data.name = name
    data
}

-- Local-install module
modules.local = {

}


-- Commands implementation -----------------------------------------------------

installPackage = (source, name, meta) ->
  log.fatal "Incorrect package name!" unless name
  if saveManifest callModuleMethod getModuleBy(source), "install", name, meta
    log.info "Manifest for '#{name}' package was saved."
  else
    log.error "Error saving manifest for '#{name}' package."

removePackage = (source, name, meta) ->
  log.fatal "Incorrect package name!" unless name
  manifest = try loadManifest name
  try callModuleMethod getModuleBy(source), "remove", manifest
  log.print "Done removal."


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
