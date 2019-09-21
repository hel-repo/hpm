semver = (() ->
  _ = [[
     Copyright (c) The python-semanticversion project
     All rights reserved.

     Redistribution and use in source and binary forms, with or without
     modification, are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this
     list of conditions and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright notice,
     this list of conditions and the following disclaimer in the documentation
     and/or other materials provided with the distribution.

     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
     ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
     WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
     DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
     ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
     (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
     LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
     ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
     (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
     SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  ]]

  _ = [[
  The use of the library is similar to the original one,
  check the documentation here: https://python-semanticversion.readthedocs.io/en/latest/
  ]]

  import concat, insert, unpack from table

  toInt = (value) ->
    if tn = tonumber value
      tn, true
    else
      value, false

  hasLeadingZero = (value) ->
    value and value[1] == '0' and tonumber value and value != '0'

  baseCmp = (x, y) ->
    return 0 if x == y
    return 1 if x > y
    return -1 if x < y

  identifierCmp = (a, b) ->
    aCmp, aInt = toInt a
    bCmp, bInt = toInt b

    if aInt and bInt
      baseCmp aCmp, bCmp
    elseif aInt
      -1
    elseif bInt
      1
    else
      baseCmp aCmp, bCmp

  identifierListCmp = (a, b) ->
    identifierPairs = {a[i], b[i] for i = 1, #a when b[i]}
    for idA, idB in pairs identifierPairs do
      cmpRes = identifierCmp(idA, idB)
      if cmpRes != 0
        return cmpRes
    baseCmp(#a, #b)

  class Version
    @versionRe: (s) =>
      mjr, mnr, pch, rmn = s\match '^(%d+)%.(%d+)%.(%d+)(.*)$'
      return nil unless mjr
      add, r = rmn\match '^%-([0-9a-zA-z.-]+)(.*)$'
      if add
        rmn = r
      meta, r = rmn\match '^%+([0-9a-zA-Z.-]+)(.*)$'
      if meta
        rmn = r
      if #rmn > 0
        return nil
      mjr, mnr, pch, add, meta

    @partialVersionRe: (s) =>
      mjr, rmn = s\match '^(%d+)(.*)$'
      return nil unless mjr
      mnr, r = rmn\match '^%.(%d+)(.*)$'
      if mnr
        rmn = r
      pch, r = rmn\match '^%.(%d+)(.*)$'
      if pch
        rmn = r
      add, r = rmn\match '^%-([0-9a-zA-Z.-]*)(.*)$'
      if add
        rmn = r
      meta, r = rmn\match '^%+([0-9a-zA-Z.-]*)(.*)$'
      if meta
        rmn = r
      if #rmn > 0
        return nil
      mjr, mnr, pch, add, meta

    new: (versionString, partial=false) =>
      major, minor, patch, prerelease, build = unpack @parse versionString, partial

      @major, @minor, @patch, @prerelease, @build, @partial = major, minor, patch, prerelease, build, partial

    _coerce: (value, allowNil=false) =>
      return value if value == nil and allowNil
      tonumber value

    next_major: =>
      if @prerelease and @minor == 0 and @patch == 0
        Version concat [tostring x for x in *{@major, @minor, @patch}], '.'
      else
        Version concat [tostring x for x in *{@major + 1, 0, 0}], '.'

    next_minor: =>
      error "Partial version doesn't contain the minor component!" unless @minor
      if @prerelease and @patch == 0
        Version concat [tostring x for x in *{@major, @minor, @patch}], '.'
      else
        Version concat [tostring x for x in *{@major, @minor + 1, 0}], '.'

    next_patch: =>
      error "Partial version doesn't contain the patch component!" unless @patch
      if @prerelease
        Version concat [tostring x for x in *{@major, @minor, @patch}], '.'
      else
        Version concat [tostring x for x in *{@major, @minor, @patch + 1}], '.'

    coerce: (versionString, partial=false) =>
      baseRe = (s) ->
        mjr, rmn = s\match '^(%d+)(.*)$'
        return nil unless mjr
        t = mjr
        mnr, r = rmn\match '^%.(%d+)(.*)$'
        if mnr
          rmn = r
          t ..= '.' .. mnr
        pch, r = rmn\match '^%.(%d+)(.*)$'
        if pch
          rmn = r
          t ..= '.' .. pch
        s, t

      match, matchEnd = baseRe versionString
      error "Version string lacks a numerical component: #{versionString}" unless match
      version = versionString\sub 1, #matchEnd
      if not partial
        while ({version\gsub('.', '')})[2] < 2
          version ..= '.0'

      if #matchEnd == #versionString
        return Version version, partial

      rest = versionString\sub #matchEnd + 1

      rest = rest\gsub '[^a-zA-Z0-9+.-]', '-'

      prerelease, build = nil, nil

      if rest\sub(1, 1) == '+' then
        prerelease = ''
        build = rest\sub 2
      elseif rest\sub(1, 1) == '.' then
        prerelease = ''
        build = rest\sub 2
      elseif rest\sub(1, 1) == '-' then
        rest = rest\sub 2
        if p1 = rest\find '+'
          prerelease, build = rest\sub(1, p1 - 1), rest\sub(p1 + 1, -1)
        else
          prerelease, build = rest, ''
      elseif p1 = rest\find '+' then
        prerelease, build = rest\sub(1, p1 - 1), rest\sub(p1 + 1, -1)
      else
        prerelease, build = rest, ''

      build = build\gsub '+', '.'

      if prerelease and prerelease != ''
        version ..= '-' .. prerelease
      if build and build != ''
        version ..= '+' .. build

      return @@ version, partial

    parse: (versionString, partial=false, coerce=false) =>
      if not versionString or type(versionString) != 'string' or versionString == ''
        error "Invalid empty version string: #{tostring versionString}"

      versionRe = if partial
        @@partialVersionRe
      else
        @@versionRe

      major, minor, patch, prerelease, build = versionRe @@, versionString
      if not major
        error "Invalid version string: #{versionString}"

      if hasLeadingZero major
        error "Invalid leading zero in major: #{versionString}"
      if hasLeadingZero minor
        error "Invalid leading zero in minor: #{versionString}"
      if hasLeadingZero patch
        error "Invalid leading zero in patch: #{versionString}"

      major = tonumber major
      minor = @_coerce minor, partial
      patch = @_coerce patch, partial

      if prerelease == nil
        if partial and build == nil
          return {major, minor, patch, nil, nil}
        else
          prerelease = {}
      elseif prerelease == ''
        prerelease = {}
      else
        prerelease = [x for x in prerelease\gmatch '[^.]+']
        @_validateIdentifiers prerelease, false

      if build == nil
        if partial
          build = nil
        else
          build = {}
      elseif build == ''
        build = {}
      else
        build = [x for x in build\gmatch '[^.]+']
        @_validateIdentifiers build, true

      {major, minor, patch, prerelease, build}

    _validateIdentifiers: (identifiers, allowLeadingZeroes=false) =>
      for item in *identifiers do
        if not item
          error "Invalid empty identifier #{item} in #{concat identifiers, '.'}"
        if item\sub(1, 1) == '0' and tonumber(item) and item != '0' and not allowLeadingZeroes
          error "Invalid leading zero in identifier #{item}"

    __pairs: =>
      pairs {@major, @minor, @patch, @prerelease, @build}

    __ipairs: =>
      ipairs {@major, @minor, @patch, @prerelease, @build}

    __tostring: =>
      version = tostring @major
      if @minor != nil
        version ..= '.' .. @minor
      if @patch != nil
        version ..= '.' .. @patch
      if @prerelease and #@prerelease > 0 or @partial and @prerelease and #@prerelease == 0 and @build == nil
        version ..= '-' .. concat @prerelease, '.'
      if @build and #@build > 0 or @partial and @build and #@build == 0
        version ..= '+' .. concat @build, '.'
      return version

    _comparsionFunctions: (partial=false) =>
      prereleaseCmp = (a, b) ->
        if a and b
          identifierListCmp(a, b)
        elseif a
          -1
        elseif b
          1
        else
          0

      buildCmp = (a, b) ->
        if a == b
          0
        else
          'not implemented'

      makeOptional = (origCmpFun) ->
        altCmpFun = (a, b) ->
          if a == nil or b == nil
            0
          else
            origCmpFun(a, b)
        altCmpFun

      if partial
        {
          baseCmp
          makeOptional baseCmp
          makeOptional baseCmp
          makeOptional prereleaseCmp
          makeOptional buildCmp
        }
      else
        {
          baseCmp
          baseCmp
          baseCmp
          prereleaseCmp
          buildCmp
        }

    __compare: (other) =>
      comparsionFunctions = @_comparsionFunctions(@partial or other.partial)
      comparsions = {
        {comparsionFunctions[1], @major, other.major}
        {comparsionFunctions[2], @minor, other.minor}
        {comparsionFunctions[3], @patch, other.patch}
        {comparsionFunctions[4], @prerelease, other.prerelease}
        {comparsionFunctions[5], @build, other.build}
      }

      for cmpField in *comparsions do
        cmpFun, selfField, otherField = unpack cmpField
        cmpRes = cmpFun(selfField, otherField)
        if cmpRes != 0
          return cmpRes

      return 0

    __compareHelper: (other, condition, notimplTarget) =>
      cmpRes = @__compare other
      if cmpRes == 'not implemented'
        return notimplTarget
      condition cmpRes

    __eq: (other) =>
      c = (x) -> x == 0
      @__compareHelper other, c, false

    __lt: (other) =>
      c = (x) -> x < 0
      @__compareHelper other, c, false

    __le: (other) =>
      c = (x) -> x <= 0
      @__compareHelper other, c, false


  class SpecItem

    @KIND_ANY: '*'
    @KIND_LT: '<'
    @KIND_LTE: '<='
    @KIND_EQUAL: '=='
    @KIND_SHORTEQ: '='
    @KIND_EMPTY: ''
    @KIND_GTE: '>='
    @KIND_GT: '>'
    @KIND_NEQ: '!='
    @KIND_CARET: '^'
    @KIND_TILDE: '~'

    @KIND_ALIASES: {
      [@@KIND_SHORTEQ]: @@KIND_EQUAL
      [@@KIND_EMPTY]: @@KIND_EQUAL
    }

    @reSpec: (s) =>
      chr, v = s\match '^(.-)(%d.*)$'
      if not (
          chr == '<' or
          chr == '<=' or
          chr == '' or
          chr == '=' or
          chr == '==' or
          chr == '>=' or
          chr == '>' or
          chr == '!=' or
          chr == '^' or
          chr == '~')
        nil
      else
        chr, v

    new: (requirementString) =>
      @kind, @spec = unpack @parse requirementString

    parse: (requirementString) =>
      if not requirementString or type(requirementString) != 'string' or requirementString == ''
        error "Invalid empty requirement specification: #{tostring requirementString}"

      if requirementString == '*'
        return {@@KIND_ANY, ''}

      kind, version = @@reSpec requirementString
      if not kind
        error "Invalid requirement specification: #{requirementString}"

      kind = @@KIND_ALIASES[kind] or kind

      spec = Version version, true
      if spec.build != nil and kind != @@KIND_EQUAL and kind != @@KIND_NEQ
        error "Invalid requirement specification #{requirementString}: build numbers have no ordering"

      {kind, spec}

    match: (version) =>
      switch @kind
        when @@KIND_ANY
          true
        when @@KIND_LT
          version < @spec
        when @@KIND_LTE
          version <= @spec
        when @@KIND_EQUAL
          version == @spec
        when @@KIND_GTE
          version >= @spec
        when @@KIND_GT
          version > @spec
        when @@KIND_NEQ
          version != @spec
        when @@KIND_CARET
          @spec <= version and version < @spec\next_major!
        when @@KIND_TILDE
          @spec <= version and version < @spec\next_minor!
        else
          error "Unexpected match kind: #{@kind}"

    __tostring: =>
      "#{@kind}#{@spec}"

    __eq: (other) =>
      @kind == other.kind and @spec == other.spec


  class Spec
    new: (specsStrings) =>
      if type(specsStrings) == 'string'
        specsStrings = {specsStrings}
      subspecs = [@parse spec for spec in *specsStrings]
      @specs = {}
      for subspec in *subspecs
        for spec in *subspec
          insert @specs, spec

    parse: (specsString) =>
      [SpecItem x for x in specsString\gmatch '[^,]+']

    match: (version) =>
      for spec in *@specs
        if not spec\match version
          return false
      true

    filter: (versions) =>
      i = 0
      () ->
        while true do
          i += 1
          version = versions[i]
          return nil unless version
          if @match version
            return version

    select: (versions) =>
      options = [x for x in @filter versions]
      if #options > 0 then
        max = options[1]
        for ver in *options
          if max < ver
            max = ver
        max
      else
        nil

    __index: (k) =>
      if @match k
        true
      else
        nil

    __pairs: =>
      pairs @specs

    __ipairs: =>
      ipairs @specs

    __tostring: =>
      concat [tostring spec for spec in *@specs], ','

    __eq: (other) =>
      for selfSpec in *@specs
        s = false
        for otherSpec in *other.specs
          if selfSpec == otherSpec then
            s = true
            break
        if not s
          return false
      return true

  compare = (v1, v2) ->
    baseCmp Version v1, Version v2

  match = (spec, version) ->
    Spec(spec)\match Version version

  validate = (versionString) ->
    ({Version\parse versionString})[1]


  {
    :Spec
    :SpecItem
    :Version
    :compare
    :match
    :validate
  })!


import isAvailable from require "component"
import parse, getWorkingDirectory from require "shell"
shell = require "shell"
import isDirectory, exists, makeDirectory, concat, copy, lastModified from require "filesystem"
fs = require "filesystem"
import serialize, unserialize from require "serialization"
import pull from require "event"
import clearLine, getCursor, clear from require "term"

import exit from os
import write, stderr from io
import insert, unpack from table


-- Rename some imports
listFiles = fs.list

-- Variables
options, args = {}, {}  -- command-line arguments
request = nil           -- internet request method (call checkInternet to instantiate)
modules = {}            -- distribution modules
config = {}             -- configuration table (initialized by loadConfig)
env = {}                -- module environment
modulePath = "/etc/hpm/module/" -- custom source modules
distPath = "/var/lib/hpm/dist/"     -- manifests of installed packages
exitCode = 0

-- Constants
CONFIG_PATH = "/etc/hpm/hpm.cfg" -- the path to default hpm configuration file
USAGE = [[
Usage: hpm OPTIONS COMMAND
See `man hpm` for more info.]]

DEFAULT_CONFIG = [[
-- << Global settings >> -------------------------------------------------------
-- A directory where package manifests will be placed.
-- It will be created if it doesn't exist.
dist = "/var/lib/hpm/dist"

-- A place where to search for custom hpm modules.
-- It will be created if it doesn't exist.
modules = "/etc/hpm/module"

-- << Settings related to the hel module >> ------------------------------------
hel = {}

-- If set to `false`, hpm will *only* remove a package that hpm is told to
-- remove. Otherwise, all of its dependants will be also removed.
hel.remove_dependants = true

-- << Settings related to the oppm module >> -----------------------------------
oppm = {}

-- A cache file where package manifests will be stored for faster access.
oppm.cache_file = "/var/cache/hpm/oppm"

-- See hel.remove_dependants above.
oppm.remove_dependants = true

-- Connect additional GitHub repositories not present in OpenPrograms' list.
-- The format is the same as in the oppm.cfg file at OpenPrograms:
-- https://github.com/OpenPrograms/openprograms.github.io/blob/master/repos.cfg
oppm.custom_repos = {
  -- ["My-Super-Repository"] = {
  --   repo="My-GitHub-Username/my-programs"
  -- }
}
]]


-- Logging functions -----------------------------------------------------------

log =
  info: (...) -> print table.concat [tostring x for x in *{...}], "\t" if options.v
  print: (...) -> print table.concat [tostring x for x in *{...}], "\t" unless options.q
  error: (...) ->
    stderr\write table.concat([tostring x for x in *{...}], "\t") .. '\n' unless options.q
  fatal: (...) ->
    stderr\write table.concat([tostring x for x in *{...}], "\t") .. '\n' unless options.q
    exit 1

assert = (statement, message) -> log.fatal message unless statement

unimplemented = (what) -> log.fatal (tostring what) .. ": Not implemented yet!"

printUsage = ->
  write USAGE
  exit 0

try = (result, reason) ->
  log.fatal reason unless result
  result


-- Argument type-checking ------------------------------------------------------

-- v -- value, c -- converted, t -- type
checkType = (v, t, c) ->
  log.fatal "Value '#{v}' is #{type c}, however, a #{t} is expected." unless type v == t
  c

argNumber = (v) -> checkType v, "number", tonumber v

argString = (v) -> checkType v, "string", tostring v


-- Helper methods --------------------------------------------------------------

-- Check if an element is in the table
isin = (v, tbl) ->
  for k, value in pairs tbl
    if value == v
      return true, k
  return false

-- Calculate the length of table
tableLen = (tbl) ->
  result = 0
  for k, v in pairs tbl
    result += 1
  result

-- Check if given table or string contains something useful
empty = (v) ->
  if type(v) == "nil"
    true
  elseif type(v) == "string"
    not v or #v < 1
  elseif type(v) == "table"
    not v or tableLen(v) < 1
  else
    true

-- All values are true
all = (vals) ->
  for v in *vals
    if not v
      return false
  true

-- More specific fs.exist versions
existsDir = (path) -> exists(path) and isDirectory path
existsFile = (path) -> exists(path) and not isDirectory path

-- Returns "s" if amount differs from 1, "" otherwise
plural = (amount) -> amount == 1 and "" or "s"

-- The inverted version of the function above
singular = (amount) -> amount != 1 and "" or "s"

-- Choose between "are" and "is" depending on the given amount
linkingVerb = (amount) -> amount == 1 and "is" or "are"

-- Recursively adds values from head to base
deepPatch = (base, head) ->
  for k, v in pairs head
    if type(v) ~= "table" or type(base[k]) ~= "table"
      base[k] = v
    else
      deepPatch base[k], v

-- Deep copy of a table
deepCopy = (tbl) ->
  if type(tbl) ~= "table" then
    return tbl
  result = {}
  for k, v in pairs(tbl) do
    result[k] = deepCopy v

  return result

-- Returns real time if it can
getRealTime = ->
  with file = io.open "/tmp/hpm-time", "w"
    \write ""
    \close!
  result = lastModified "/tmp/hpm-time"
  fs.remove "/tmp/hpm-time"
  return result

-- Recursive remove
remove = (path) ->
  if fs.get(shell.resolve(path)).isReadOnly!
    false, "the path is readonly!"
  elseif not exists path
    false, "the filesystem node doesn't exist."
  else
    unless isDirectory(path) or fs.isLink path
      fs.remove path
    else
      for file in try listFiles path
        remove concat path, file
      fs.remove path

loadConfig = ->
  path = options.c or options.config or CONFIG_PATH
  if not existsFile path
    dirPath = fs.path path
    if not existsDir dirPath
      result, reason = makeDirectory dirPath
      if not result
        return false, "Failed to create '#{dirPath}' directory for the config file: #{reason}"
    file, reason = io.open path, "w"
    if file
      file\write DEFAULT_CONFIG
      file\close!
    else
      return false, "Failed to open config file for writing: #{reason}"
  file, reason = io.open path, "r"
  if file
    content = file\read "*all"
    file\close!
    globals = {}
    (load content, "config", "t", globals)!
    newUndecl = (base={}) ->
      setmetatable base, {
        __index: {
          get: (k, v, createNewUndecl) ->
            if type(base[k]) != "nil"
              if type(base[k]) == "table"
                return newUndecl base[k]
              return base[k]
            log.error "Attempt to access undeclared config field '#{k}'!"
            if not createNewUndecl
              v
            else
              newUndecl v
        }
      }
    config = newUndecl globals
    modulePath = config.get "modules", modulePath
    distPath = config.get "dist", distPath
    config
  else
    return false, "Failed to open config file for reading: #{reason}"

-- Check for internet availability
checkInternet = ->
  log.fatal "This command requires an internet card to run!" unless isAvailable "internet"
  request = request or require("internet").request

-- Return download stream
download = (url) ->
  checkInternet!
  pcall request, url

-- Load available modules
loadCustomModules = ->
  if not existsDir modulePath
    result, reason = makeDirectory modulePath
    if not result
      return false, "Failed to create '#{modulePath}' directory for custom modules: #{reason}"
  list = try listFiles modulePath
  for file in list
    env.name = file\match("^(.+)%..+$")
    mod = try loadfile concat(modulePath, file), "t", env
    mod!
    env.name = nil
  true

findCustomCommand = (name) ->
  command = name
  mod = if p1 = name\find ':'
    command = name\sub p1 + 1
    name\sub 1, p1 - 1
  if not mod
    candidates = {}
    for modName, mod in pairs modules
      if mod[command]
        if type(mod[command]) == "table" and mod[command].__public == true
          insert candidates, { class: mod, module: modName, method: mod[command] }
    if #candidates > 1
      -- Choose hel module there are multiple candidates
      pos = nil
      for k, mod in pairs candidates
        if mod.module == "hel"
          pos = k
          break
      if pos
        candidates = {candidates[pos]}
    if #candidates > 1
      log.print "Ambiguous choice: method #{command} is implemented in the following modules:"
      for mod in *candidates
        log.print " * #{mod.module}"
      log.print "Choose a specific module by prepending its name with a colon, e.g., #{candidates[1].module}:#{command}."
      false
    elseif #candidates == 0
      log.error "Unknown command: #{command}"
      false
    else
      mod = candidates[1].module
      log.info "Note, using #{mod}:#{command}."
      (...) -> candidates[1].method candidates[1].class, ...
  else
    if modules[mod] and empty command
      -- List module-specific methods
      modSpecMths = {}
      for k, v in pairs modules[mod]
        if type(v) == "table" and v.__public == true
          insert modSpecMths, tostring k
      log.print "Available module-specific commands: #{table.concat modSpecMths, ", "}"
      return false
    if not modules[mod] or not modules[mod][command] or modules[mod][command] and (type(modules[mod][command]) != "table" or modules[mod][command].__public != true)
      log.error "Unknown command: #{mod}:#{command}"
      false
    else
      (...) -> modules[mod][command] modules[mod], ...

-- Try to find module corresponding to the 'source' string
getModuleBy = (source) ->
  source = if not source or source == "" then "hel" else source
  modules[source] or modules.default

-- Call module operation (with fallback to default module)
callModuleMethod = (mod=modules.default, name, ...) ->
  if mod[name] then mod[name](mod, ...)
  else modules.default[name](modules.default, ...)

-- Save manifest to dist-data folder
saveManifest = (manifest, mod="hel", path=concat(distPath, mod), name=manifest.name) ->
  if not manifest
    return false, "'nil' given"

  if not existsDir path
    result, reason = makeDirectory path
    if not result
      return false, "Failed to create '#{path}' directory for manifest files: #{reason}"

  file, reason = io.open concat(path, name), "w"
  if file
    file\write serialize manifest
    file\close!
    true
  else
    false, "Failed to open file for writing: #{reason}"

-- Read package manifest from file
loadManifest = (name, path, mod="hel") ->
  path = path or concat distPath, mod, name
  if existsFile path
    file, reason = io.open path, "rb"
    if file
      manifest = try unserialize file\read "*all"
      file\close!
      manifest
    else false, "Failed to open manifest for '#{name}' package: #{reason}"
  else false, "No manifest found for '#{name}' package"

-- Delete manifest file
removeManifest = (name, mod="hel") ->
  path = concat distPath, mod, name
  if existsFile path then remove path
  else false, "No manifest found for '#{name}' package"

public = (func) ->
  setmetatable {
    __public: true
  }, {
    __call: (self, ...) -> func ...
  }

wrapResponse = (resp, file) ->
  ->
    result, chunk = pcall resp
    unless result
      false, "#{chunk}"
    else
      chunk

recv = (url, connectError="Could not download '%s': %s", downloadError="Could not download '%s': %s") ->
  result, response, reason = download url
  return false, connectError\format url, reason unless result and response
  data = ""
  for chunk, reason in wrapResponse response
    if chunk
      data ..= chunk
    else
      return false, downloadError\format url, reason
  data

confirm = ->
  unless options.y
    io.write "Press [ENTER] to continue..."
    key = select 3, pull "key_down"
    if key == 13  -- Enter
      clearLine!
      true
    else
      io.write "\n"
      false
  else
    true

pkgPlan = (plan) ->
  complexity = 0
  msg = {}
  unless empty plan.install
    m = {"Packages to INSTALL:",
         table.concat plan.install, "  "}
    insert msg, m
    complexity += #plan.install
  else
    plan.install = {}
  unless empty plan.reinstall
    m = {"Packages to REINSTALL:",
         table.concat plan.reinstall, "  "}
    insert msg, m
    complexity += #plan.reinstall
  else
    plan.reinstall = {}
  unless empty plan.upgrade
    m = {"Packages to UPGRADE:",
         table.concat plan.upgrade, "  "}
    insert msg, m
    complexity += #plan.upgrade
  else
    plan.upgrade = {}
  unless empty plan.remove
    m = {"Packages to REMOVE:",
         table.concat plan.remove, "  "}
    insert msg, m
    complexity += #plan.remove
  else
    plan.remove = {}

  do
    m = {"#{#plan.install} to INSTALL, #{#plan.reinstall} to REINSTALL, #{#plan.upgrade} to UPGRADE, #{#plan.remove} to REMOVE."}
    insert msg, m
  for num, i in pairs msg
    for num, line in pairs i
      if num == 1
        log.print line
      else
        log.print "  #{line}"
    if num != #msg
      log.print ""

  if complexity > 0
    unless confirm!
      exit 7


-- Distribution modules --------------------------------------------------------
-- Default module
modules.default = class
  @install: -> log.fatal "Incorrect source is provided! No default 'install' implementation."

  @remove: (manifest, mod="hel") =>
    if manifest
      if manifest.files
        for i, file in pairs(manifest.files)
          if file.path
            result, reason = remove file.path
            log\error "Failed to remove '#{file.path}': #{reason}" unless result
          else
            result, reason = remove concat(file.dir, file.name)
            log\error "Failed to remove '#{concat file.dir, file.name}': #{reason}" unless result
      removeManifest manifest.name, mod
    else
      false, "Package can't be removed: the manifest is empty."


-- Hel Repository module
modules.hel = class extends modules.default
  -- Repository API root url
  @URL: "https://api.fomalhaut.me/"

  -- Get package data from JSON, and return as a table
  @parsePackageJSON: (decoded, spec=semver.Spec "*") =>
    selectedVersion = nil

    versions = {}

    for number, data in pairs decoded.versions
      v = semver.Version number
      log.fatal "Could not parse the version in package: #{v}" unless v
      versions[v] = data

    success, bestMatch = pcall -> spec\select [version for version, data in pairs versions]
    log.fatal "Could not select the best version: #{bestMatch}" unless success
    selectedVersion = tostring bestMatch

    log.fatal "No candidate for version specification '#{spec}' found!" unless bestMatch

    data = { name: decoded.name, version: selectedVersion, files: {}, dependencies: {} }

    for url, file in pairs versions[bestMatch].files
      path = file.path
      insert data.files, { :url, :path }

    for depName, depData in pairs versions[bestMatch].depends
      version = depData.version
      depType = depData.type
      insert data.dependencies, { name: depName, :version, type: depType }

    data

  @getPackageSpec: (name) =>
    log.info "Downloading package data for #{name} ..."
    status, response = download @URL .. "packages/" .. name
    log.fatal "HTTP request error: " .. response unless status
    jsonData = ""
    success, reason = xpcall -> for chunk in response do jsonData ..= chunk,
      debug.traceback
    unless success
      output = {"HTTP request error.",
                "Perhaps the package #{name} doesn't exist, or the Hel Repository went down.",
                "Rerun with -v to see traceback."
                "\nError details:\n#{reason}"}
      if options.v
        table.remove output, 3
      else
        table.remove output, 4
      log.fatal table.concat output, "\n"
    decoded = json\decode jsonData
    log.fatal "Incorrect JSON format!\n#{jsonData}" unless decoded
    decoded.data

  @rawInstall: (pkgData, isManuallyInstalled=false, save=false) =>
    prefix = if save
      concat getWorkingDirectory!, pkgData.name
    else
      "/"

    if save and not existsDir prefix
      result, response = makeDirectory prefix
      log.fatal "Failed creating '#{prefix}' directory for package '#{pkgData.name}'! \n#{response}" unless result
    elseif not save
      manifest = loadManifest pkgData.name, nil, "hel"
      if manifest
        if manifest.version == tostring pkgData.version
          log.print "'#{pkgData.name}@#{manifest.version}' is already installed, skipping..."
          return manifest
        else
          log.fatal "'#{pkgData.name}@#{pkgData.version}' was attempted to install, however, another version of the same package is already installed: '#{pkgData.name}@#{manifest.version}'"

    for key, file in pairs pkgData.files
      log.info "Fetching '#{fs.name file.path}' ..."
      contents = try recv file.url

      path = concat prefix, fs.path file.path
      if not existsDir path
        result, response = makeDirectory path
        log.fatal "Failed to create '#{path}' directory for '#{fs.name file.path}'! \n#{response}" unless result

      with file, reason = io.open concat(path, fs.name file.path), "w"
        log.fatal "Could not open '#{concat path, fs.name file.path}' for writing: #{reason}" unless file
        \write contents
        \close!

    { name: pkgData.name, version: tostring(pkgData.version), files: pkgData.files, dependencies: pkgData.dependencies, manual: isManuallyInstalled }

  -- Get an ordered list of packages for installation, resolving dependencies.
  @resolveDependencies: (packages, isReinstalling, resolved={}, unresolved={}, result={}) =>
    for { :name, :version } in *packages
      isResolved = false
      for pkg in *resolved
        if pkg.pkg.name == name
          isResolved = true
          break
      unless isResolved
        insert unresolved, { :name, version: "" }
        manifest = loadManifest name, nil, "hel"
        if not manifest or not version\match semver.Version manifest.version
          spec = @getPackageSpec name
          data = @parsePackageJSON spec, version
          unresolved[#unresolved].version = data.version
          for dep in *data.dependencies
            isResolved = false
            for pkg in *resolved
              if pkg.pkg.name == dep.name
                isResolved = true
                break
            if not isResolved
              key = nil
              for k, pkg in pairs unresolved
                if pkg.name == dep.name
                  key = k
                  break
              if key
                if unresolved[key].version == dep.version
                  log.fatal "Circular dependencies detected: '#{name}@#{data.version}' depends on '#{dep.name}@#{dep.version}', and '#{unresolved[key].name}@#{unresolved[key].version}' depends on '#{name}@#{data.version}'."
                else
                  log.fatal "Attempted to install two versions of the same package: '#{dep.name}@#{dep.version}' and '#{unresolved[key].name}@#{unresolved[key].version}' when resolving dependencies for '#{name}@#{data.version}'."
              @resolveDependencies {{ name: dep.name, version: semver.Spec dep.version }}, false, resolved, unresolved, result
          insert resolved, { pkg: data }
          insert result, { pkg: data }
        else
          insert resolved, { pkg: manifest }
          insert result, { pkg: manifest } if isReinstalling
        unresolved[#unresolved] = nil
    result

  -- Get all packages that depend on the given, and return a list of the dependent packages.
  @getPackageDependants: (packages, resolved={}, unresolved={}) =>
    for name in *packages
      isResolved = false
      for pkg in *resolved
        if pkg.name == name
          isResolved = true
          break
      unless isResolved
        insert unresolved, { :name }
        manifest = loadManifest name, nil, "hel"
        if manifest
          insert resolved, { :name, :manifest }
          list = try listFiles concat distPath, "hel"
          for file in list
            manifest = try loadManifest file, nil, "hel"
            for dep in *manifest.dependencies
              if dep.name == name
                isResolved = false
                for pkg in *resolved
                  if pkg.name == file
                    isResolved = true
                    break
                if not isResolved
                  for pkg in *unresolved
                    if pkg.name == file
                      log.fatal "Circular dependencies detected: #{file}"
                  @getPackageDependants {file}, resolved, unresolved
        else
          log.fatal "Package #{name} is referenced as a dependant of another package, however, this package isn't installed."

        unresolved[#unresolved] = nil
    resolved

  @fileConflicts: (packages) =>
    if options.f or options.force
      log.info "File conflict checking skipped: --force option given."
      return true
    log.info "Checking for file conflicts..."
    conflictsDetected = false
    for pkg in *packages
      for file in *pkg.files
        if exists file.path
          log.error "'#{pkg.name}' wants to override node at '#{file.path}'"
          conflictsDetected = true
    if conflictsDetected
      log.fatal "File conflicts detected; terminating."
    return true

  @install: public (...) =>
    if options.l or options.local then
      path = shell.resolve ...
      manifest = try loadManifest path, concat path, "manifest"
      dependencyGraph = @resolveDependencies [{ :name, version: semver.Spec version } for { :name, :version } in *manifest.dependencies]

      onlyDeps = options.d or options.onlyDeps

      toInstall = {}
      for node in *dependencyGraph
        insert toInstall, "#{node.pkg.name}@#{node.pkg.version}"
      unless onlyDeps
        insert toInstall, "#{manifest.name}@#{manifest.version}"

      pkgPlan { install: toInstall }

      @fileConflicts [x.pkg for x in *dependencyGraph]

      for i = 1, #dependencyGraph, 1
        node = dependencyGraph[i]
        log.print "Installing '#{node.pkg.name}@#{node.pkg.version}'..."
        _manifest = @rawInstall node.pkg, false, false
        success, reason = saveManifest _manifest, "hel"
        if success
          log.info "Saved the manifest of '#{_manifest.name}'."
        else
          log.fatal "Couldn't save the manifest of '#{_manifest.name}': #{reason}."

      if not onlyDeps
        log.print "Installing '#{manifest.name}@#{manifest.version}'..."

        -- just copy/paste
        for key, file in pairs manifest.files
          filePath = file.path or concat file.dir, file.name
          if not existsDir fs.path filePath
            makeDirectory fs.path filePath
          result, reason = copy concat(path, file.url), filePath
          log.fatal "Cannot copy file '#{file.name}': #{reason}" unless result

        manifest.local = true
        success, reason = saveManifest manifest, "hel"
        if success
          log.info "Saved the manifest of '#{manifest.name}'."
        else
          log.fatal "Couldn't save the manifest of '#{manifest.name}': #{reason}."
      log.print "Done."
      return true

    packages = {}
    for x in *{...}
      name, version = x\match("^(.+)@(.+)$") or x
      version = "*" if empty version
      log.info "Creating version specification for #{version} ..."
      success, spec = pcall -> semver.Spec version
      log.fatal "Could not parse the version specification: #{spec}!" unless success

      insert packages, { :name, version: spec }

    reinstall = options.r or options.reinstall
    save = options.s or options.save
    dependencyGraph = @resolveDependencies packages, reinstall

    toReinstall = {}
    toInstall = {}
    for node in *dependencyGraph
      if reinstall
        found = false
        for pkg in *packages
          if pkg.name == node.pkg.name
            found = true
            break
        if found
          insert toReinstall, "#{node.pkg.name}@#{node.pkg.version}"
          continue
      insert toInstall, "#{node.pkg.name}@#{node.pkg.version}"

    pkgPlan {
      install: toInstall,
      reinstall: toReinstall
    }

    @fileConflicts [x.pkg for x in *dependencyGraph when not isin "#{x.pkg.name}@#{x.pkg.version}", toReinstall]

    if reinstall
      manifests = for pkg in *packages
        try loadManifest pkg.name, nil, "hel"
      @_remove manifests, true, false
    for node in *dependencyGraph
      log.print "Installing '#{node.pkg.name}@#{node.pkg.version}'..."
      manual = false
      for pkg in *packages
        if pkg.name == node.pkg.name
          manual = true
          break
      manifest = @rawInstall node.pkg, manual, save
      manifestPath = if save
        concat getWorkingDirectory!, manifest.name

      success, reason = saveManifest manifest, "hel", manifestPath
      if success
        log.info "Saved the manifest of '#{manifest.name}'."
      else
        log.fatal "Couldn't save the manifest of '#{manifest.name}': #{reason}."
    log.print "Done."

  @remove: public (...) =>
    packages = {...}
    manifests = {}
    for pkg in *packages
      manifest = try loadManifest pkg, nil, "hel"
      insert manifests, manifest
    @_remove manifests, false
    log.print "Done."

  -- Remove packages and its dependants
  @_remove: (manifests, noPlan=false, removeDeps=true) =>
    deps = if not config.get("hel", {}, true).get("remove_dependants", true) or not removeDeps
      [{ name: manifest.name, :manifest } for manifest in *manifests]
    else
      @getPackageDependants [manifest.name for manifest in *manifests]
    unless noPlan
      pkgPlan {
        remove: ["hel:#{node.manifest.name}@#{node.manifest.version}" for node in *deps]
      }
    for dep in *deps
      log.print "Removing '#{dep.manifest.name}@#{dep.manifest.version}' ..."
      try super\remove dep.manifest, "hel"
    true

  @upgrade: public () =>
    -- STEP 1. Get packages that can be up'd.
    --         To do so we need to send a http request for each package installed.
    installed = {}
    for file in try listFiles concat distPath, "hel"
      unless isDirectory concat distPath, "hel", file
        manifest = try loadManifest file, nil, "hel"
        insert installed, manifest unless manifest.local

    upgradable = {}
    for pkg in *installed
      success, spec = pcall @getPackageSpec, @, pkg.name
      -- we can also have local hel packages installed
      -- that would have caused an error here
      if success
        data = @parsePackageJSON spec
        pkg.latest = { :spec, :data }
        if semver.Version(pkg.latest.data.version) > semver.Version(pkg.version)
          insert upgradable, pkg

    -- STEP 2. Now let's try to run the dep resolver.
    deps = @resolveDependencies [{ name: pkg.name, version: semver.Spec pkg.latest.data.version } for pkg in *upgradable]

    -- STEP 3. As we're here, the dep resolver didn't cause a fatal error,
    --         so we can continue.
    --         Show the plan and install the packages.
    toUpgrade = ["#{pkg.name}@{#{pkg.version} => #{pkg.latest.data.version}}" for pkg in *upgradable]
    toInstall = {}
    for node in *deps
      isNew = true
      for pkg in *upgradable
        if pkg.name == node.pkg.name
          isNew = false
          break
      if isNew
        insert toInstall, "#{node.pkg.name}@#{node.pkg.version}"
    pkgPlan {
      upgrade: toUpgrade,
      install: toInstall
    }

    for node in *deps
      shouldRemove = false
      manual = false
      for pkg in *upgradable
        if pkg.name == node.pkg.name
          shouldRemove = pkg
          manual = pkg.manual
          break
      if shouldRemove
        @_remove {shouldRemove}, true, false
      log.print "Installing '#{node.pkg.name}@#{node.pkg.version}'..."
      manifest = @rawInstall node.pkg, manual, false
      success, reason = saveManifest manifest, "hel"
      if success
        log.info "Saved the manifest of '#{manifest.name}'."
      else
        log.fatal "Couldn't save the manifest of '#{manifest.name}': #{reason}."
    log.print "Done."

  @info: public (pkg, specString="*") =>
    log.fatal "Usage: hpm hel:info <package name> [<version specification>]" if empty pkg
    specString = "*" if empty(specString)
    log.print "Creating version specification for #{specString} ..."
    success, versionSpec = pcall -> semver.Spec specString
    log.fatal "Could not parse the version specification: #{versionSpec}!" unless success

    spec = @getPackageSpec pkg
    data = @parsePackageJSON spec, versionSpec

    message = {}
    insert message, "- Package name:   #{spec.name}"
    insert message, "- Description:\n#{spec.description}"
    insert message, "- Package owners: #{table.concat spec.owners, ", "}"
    insert message, "- Authors:\n#{table.concat ["  - #{x}" for x in *spec.authors], "\n"}"
    insert message, "- License:        #{spec.license}"
    insert message, "- Versions:       #{tableLen spec.versions}, latest: #{data.version}"
    insert message, "  - Files:        #{#data.files}"
    insert message, "  - Depends:      #{table.concat ["#{x.name}@#{x.version}" for x in *data.dependencies], "  "}"
    insert message, "  - Changes:\n#{spec.versions[data.version].changes}"
    insert message, "- Stats:"
    insert message, "  - Views:        #{spec.stats.views}"
    insert message, "- Creation date:  #{spec.stats.date.created} UTC"
    insert message, "- Last updated:   #{spec.stats.date["last-updated"]} UTC"

    log.print table.concat message, "\n"

  @search: public (...) =>
    offset = 0
    while true
      list = {}
      url = @URL .. "packages"
      url ..= "?offset=#{offset}"
      if ...
        url ..= "&q=" .. table.concat(['"' .. x\gsub("\"", "") .. '"' for x in *{...}], " ")\gsub "&", ""
      status, response = download url
      log.fatal "HTTP request error: " .. response unless status
      jsonData = ""
      for chunk in response do jsonData ..= chunk
      decoded = json\decode jsonData
      log.fatal "Incorrect JSON format!\n#{jsonData}" unless decoded
      list = decoded.data.list
      for pkg in *list
        log.print "#{pkg.name}: #{pkg.short_description}"
      if #list == 0 and offset == 0
        log.print "No packages found."
        break
      if decoded.data.truncated and decoded.data.sent + decoded.data.offset < decoded.data.total
        offset = decoded.data.offset + decoded.data.sent
      else
        break


modules.oppm = class extends modules.default

  @REPOS: "https://raw.githubusercontent.com/OpenPrograms/openprograms.github.io/master/repos.cfg"
  @PACKAGES: "https://raw.githubusercontent.com/%s/master/programs.cfg"
  @FILES: "https://raw.githubusercontent.com/%s/%s"
  @DIRECTORY: "https://api.github.com/repos/%s/contents/%s?ref=%s"
  @DEFAULT_CACHE_FILE = "/var/cache/hpm/oppm"

  @cacheFile: =>
    path = config.get("oppm", {}, true).get("cache_file", @DEFAULT_CACHE_FILE)
    unless existsDir fs.path path
      result, reason = makeDirectory fs.path path
      log.fatal "Could not create the cache directory at #{fs.path path}: #{reason}" unless result
    unless existsFile path
      file, reason = io.open path, "w"
      log.fatal "Could not open '#{path}' for writing: #{reason}" unless file
      file\write "{}"
      file\close!
    path

  @notifyCacheUpdate: (updated) =>
    currentTime = getRealTime!
    diff = currentTime - updated
    if diff > 24 * 60 * 60 * 1000
      log.print "Cache was last updated more than a day ago."
      log.print "Consider running hpm oppm:cache update to update it."

  @listCache: =>
    local list
    cachePath = @cacheFile!
    with file, reason = io.open cachePath, "r"
      return false, "Could not open '#{cachePath}' for reading: #{reason}" unless file
      all = \read "*all"
      list, reason = unserialize all
      return false, "Cache is malformed: #{reason}" unless list
      \close!

    if not list.updated or not list.cache
      list = { updated: 0, cache: list }

    list

  @resolveDirectory: (repo, branch, path) =>
    data = try recv @DIRECTORY\format repo, path, branch
    data = json\decode data
    return false, "Could not fetch #{repo}:#{branch}/#{path}: #{data.message}" if data.message
    [{ name: file.name, url: file.download_url, path: file.path } for file in *data when file.type == "file"]

  @updateCache: =>
    cacheFile = @cacheFile!
    oldFiles, reason = @listCache!
    unless oldFiles
      log.error "Old cache is malformed: #{oldFiles}"
      oldFiles = {}
    else
      oldFiles = oldFiles.cache

    repos, reason = recv @REPOS
    return false, "Could not fetch #{@REPOS}: #{reason}" unless repos

    repos = unserialize repos

    customRepos = {}
    for k, v in pairs deepCopy config.get("oppm", {}, true).get("custom_repos", {})
      customRepos["local/#{k}"] = v
    deepPatch repos, customRepos

    programs = {}
    for repo, repoData in pairs repos
      if repoData.repo
        log.info "Fetching '#{repo}' at '#{repoData.repo}' ..."
        result, response, reason = download @PACKAGES\format repoData.repo
        unless result and response
          log.error "Could not fetch '#{repo}' at '#{repoData.repo}': #{reason}"
          continue

        data = ""
        for result, chunk in -> pcall response
          if not result
            log.error "Could not fetch '#{repo}' at '#{repoData.repo}': #{chunk}"
            data = false
            break
          else
            break if not chunk
            data ..= chunk

        if data == false
          continue
        if empty data
          log.error "Could not fetch '#{repo}' at '#{repoData.repo}'"
          continue

        repoPrograms, reason = unserialize data
        if not repoPrograms
          log.error "Manifest '#{repo}' at '#{repoData.repo}' is malformed: #{reason}"
          continue

        for prg, prgData in pairs repoPrograms
          if prg\match "[^A-Za-z0-9._-]"
            log.error "Package name contains illegal characters: #{repo}:#{prg}!"
            continue
          insert programs, { repo: repoData.repo, name: prg, data: prgData }

    newFiles = {}
    newCache = {}

    for { :name, :repo, :data } in *programs
      if isin concat(repo, name), newFiles
        log.error "There're multiple packages under the same name: #{name}!"

      insert newCache, { pkg: name, :repo, data: { :name, :repo, :data } }

      local k
      do
        for key, v in pairs oldFiles
          if v.repo == repo and v.pkg == name
            k = key
            break
      if k
        table.remove oldFiles, k
      else
        insert newFiles, concat repo, name

    file, reason = io.open cacheFile, "w"
    return false, "Could not open '#{cacheFile}' for writing: #{reason}" unless file

    with file
      \write serialize { updated: getRealTime!, cache: newCache }
      \close!

    log.print "- #{#programs} program#{plural #programs} cached."
    log.print "- #{#newFiles} package#{plural #newFiles} #{linkingVerb #newFiles} new."
    log.print "- #{#oldFiles} package#{plural #oldFiles} no longer exist#{singular #oldFiles}."
    true

  @parseLocalPath: (prefix, lPath) =>
    if lPath\sub(1, 2) == "//"
      concat prefix, lPath\sub 3
    else
      concat prefix, "usr", lPath

  @rawInstall: (name, prefix="/", isManuallyInstalled=false, save=false) =>
    cacheList = try @listCache!
    cacheList = cacheList.cache
    stats = {
      filesInstalled: 0,
      packagesInstalled: 0
    }

    if save and not existsDir prefix
      result, reason = makeDirectory prefix
      log.fatal "Failed to create '#{prefix}' directory for package '#{name}'! \n#{reason}" unless result
    elseif not save
      manifest = loadManifest name, nil, "oppm"
      if manifest
        log.print "'#{name}' is already installed, skipping..."
        return manifest, stats
    local manifest
    for package in *cacheList
      { :pkg, :repo, :data } = package
      if pkg == name
        manifest = package
        break
    log.fatal "No such package: #{name}" unless manifest

    files = {}

    repo = manifest.repo
    for rPath, lPath in pairs manifest.data.data.files
      -- Remote file paths. Usually there's a single item, but directory
      -- contents tokens may cause population with multiple items.
      rFiles = {}
      -- Directory contents token
      if rPath\sub(1, 1) == ":"
        rFiles = @resolveDirectory repo, rPath\sub(2, rPath\find("/") - 1, nil), rPath\sub rPath\find("/") + 1
      -- Config file token
      elseif rPath\sub(1, 1) == "?"
        if exists concat(@parseLocalPath(prefix, lPath), fs.name(rPath))
          rFiles = {}
        else
          remotePath = rPath\sub(2, -1)
          rFiles = {{
            name: fs.name remotePath,
            path: remotePath,
            url: @FILES\format repo, remotePath
          }}
      else
        rFiles = {{
          name: fs.name rPath,
          path: rPath,
          url: @FILES\format repo, rPath
        }}
      local name
      for { :name, :path, :url } in *rFiles
        contents = try recv url
        localPath = @parseLocalPath prefix, lPath
        unless existsDir localPath
          makeDirectory localPath
        with file, reason = io.open concat(localPath, name), "w"
          log.fatal "Could not open file for writing: #{reason}" if not file
          \write contents
          \close!
        stats.filesInstalled += 1
        insert files, { :name, :url, dir: localPath }

    dependencies = {}
    if manifest.data.data.dependencies
      for dep in pairs manifest.data.data.dependencies
        insert dependencies, { name: dep }
    stats.packagesInstalled += 1

    {
      :name,
      :files,
      :dependencies,
      manual: isManuallyInstalled
    }, stats

  @resolveDependencies: (packages, isReinstalling, resolved={}, unresolved={}, result={}) =>
    cacheList = try @listCache!
    cacheList = cacheList.cache
    for name in *packages
      isResolved = false
      for pkg in *resolved
        if pkg == name
          isResolved = true
          break
      unless isResolved
        unresolved[name] = true
        manifest = loadManifest name, nil, "oppm"
        if not manifest
          local data
          for package in *cacheList
            { :pkg } = package
            if pkg == name
              data = package
              break
          return false, "Unknown package: #{name}" unless data
          if data.data.data.dependencies
            for dep in pairs data.data.data.dependencies
              isResolved = false
              for pkg in *resolved
                if pkg == dep
                  isResolved = true
                  break
              unless isResolved
                if unresolved[dep]
                  log.fatal "Circular dependencies detected: '#{name}' depends on '#{dep}', and '#{dep}' depends on '#{name}'."
                @resolveDependencies {dep}, false, resolved, unresolved, result
          insert result, name
        else
          if isReinstalling
            insert result, name
        insert resolved, name
        unresolved[name] = nil
    result

  @getPackageDependants: (packages, resolved={}, unresolved={}) =>
    for name in *packages
      isResolved = false
      for pkg in *resolved
        if pkg.name == name
          isResolved = true
          break
      unless isResolved
        insert unresolved, { :name }
        manifest = loadManifest name, nil, "oppm"
        if manifest
          insert resolved, { :name, :manifest }
          list = try listFiles concat distPath, "oppm"
          for file in list
            manifest = try loadManifest file, nil, "oppm"
            for dep in *manifest.dependencies
              if dep.name == name
                isResolved = false
                for pkg in *resolved
                  if pkg.name == file
                    isResolved = true
                    break
                if not isResolved
                  for pkg in *unresolved
                    if pkg.name == file
                      log.fatal "Circular dependencies detected: #{file}"
                  @getPackageDependants {file}, resolved, unresolved
        else
          log.fatal "Package #{name} is referenced as a dependant of another package, however, this package isn't installed."

        unresolved[#unresolved] = nil
    resolved

  @whatDependsOn: (name) =>
    manifest = try loadManifest name, nil, "oppm"
    result = {}
    list = try listFiles concat distPath, "oppm"
    for file in list
      manifest = try loadManifest file, nil, "oppm"
      for dep in *manifest.dependencies
        if dep.name == name
          insert result, file
    result

  @install: public (...) =>
    cacheList = try @listCache!
    @notifyCacheUpdate cacheList.updated
    packages = {...}
    reinstall = options.r or options.reinstall
    save = options.s or options.save
    dependencyGraph = try @resolveDependencies packages, reinstall
    pkgPlan {
      install: [node for node in *dependencyGraph when not reinstall or not isin node, packages]
      -- we could also do `reinstall and packages or nil`, but that would not keep the resolution order.
      reinstall: reinstall and [node for node in *dependencyGraph when isin node, packages] or nil
    }
    stats = {
      filesInstalled: 0,
      packagesInstalled: 0
    }
    if reinstall
      manifests = for name in *packages
        try loadManifest name, nil, "oppm"
      @_remove manifests, true, false
    for node in *dependencyGraph
      log.print "Installing '#{node}'..."
      prefix = if save then "./#{node}/" else "/"
      manifest, statsPart = @rawInstall node, prefix, isin(node, packages), save
      stats.filesInstalled += statsPart.filesInstalled
      stats.packagesInstalled += statsPart.packagesInstalled
      if stats.packagesInstalled != 0
        success, reason = saveManifest manifest, "oppm"
        if success
          log.info "Saved the manifest of '#{manifest.name}'."
        else
          log.fatal "Couldn't save the manifest of '#{manifest.name}': #{reason}."

    log.print "- #{stats.packagesInstalled} package#{plural stats.packagesInstalled} installed."
    log.print "- #{stats.filesInstalled} file#{plural stats.filesInstalled} installed."
    log.print "Done."

  @remove: public (...) =>
    packages = {...}
    manifests = {}
    for pkg in *packages
      manifest = try loadManifest pkg, nil, "oppm"
      insert manifests, manifest
    @_remove manifests, false
    log.print "Done."

  @_remove: (manifests, noPlan=false, removeDeps=true) =>
    deps = if not config.get("oppm", {}, true).get("remove_dependants", true) or not removeDeps
      [{ name: manifest.name, :manifest } for manifest in *manifests]
    else
      @getPackageDependants [manifest.name for manifest in *manifests]
    unless noPlan
      pkgPlan {
        remove: ["#{node.name}" for node in *deps]
      }
    for dep in *deps
      log.print "Removing '#{dep.manifest.name}' ..."
      try super\remove dep.manifest, "oppm"
    true

  @cache: public (command, ...) =>
    switch command
      when "update"
        log.print "Updating OpenPrograms program cache ..."
        try @updateCache!
        log.print "Done."
      else
        log.error "Unknown command."
        log.print "Usage: hpm oppm:cache update"

  @autoremove: public =>
    toRemove = {}
    sorted = {}
    -- Step 1. Find non-manually-installed packages that have 0 dependants
    list = try listFiles concat distPath, "oppm"
    for file in list
      manifest = try loadManifest file, nil, "oppm"
      unless manifest.manual
        deps = @getPackageDependants file
        if #deps == 1
          insert toRemove, file
          insert sorted, file

    -- Step 2. Descend and find packages that are only needed by
    --         packages found in the step 1.
    while true
      changed = false
      list = try listFiles concat distPath, "oppm"
      for file in list
        unless isin file, toRemove
          manifest = try loadManifest file, nil, "oppm"
          unless manifest.manual
            deps = @getPackageDependants file
            table.remove deps, 1
            if all [isin x.name, toRemove for x in *deps]
              for dep in *deps
                _, k = isin dep.name, sorted
                if k
                  table.remove sorted, k
              insert toRemove, file
              insert sorted, file
              changed = true
      unless changed
        break

    -- Step 3. Show the plan and remove the packages.
    pkgPlan {
      remove: if #toRemove > 0 then ["oppm:#{name}" for name in *toRemove] else nil
    }
    for name in *sorted
      @_remove {try loadManifest name, nil, "oppm"}, false

    log.print "Done."
    true

  @search: public (...) =>
    cache = try @listCache!
    @notifyCacheUpdate cache.updated
    list = try cache.cache
    found = {}
    if ...
      for { :data } in *list
        pkg = data.data
        left = {...}
        for i = #left, 1, -1 do
          phrase = left[i]
          if data.name\find phrase
            table.remove left, i
            break
          if pkg.name and pkg.name\find phrase
            table.remove left, i
            break
          if pkg.description and pkg.description\find phrase
            table.remove left, i
            break
          if pkg.note and pkg.note\find phrase
            table.remove left, i
            break
        if #left == 0
          insert found, data
    else
      found = [x.data for x in *list]

    for pkg in *found
      log.print "#{pkg.name} - #{pkg.data.name or pkg.name}: #{pkg.data.description}"

  @info: public (name) =>
    log.fatal "Usage: hpm oppm:info <package name>" if empty name
    list = try @listCache!
    list = list.cache
    package = nil
    for pkg in *list
      if pkg.pkg == name
        package = pkg
        break

    log.fatal "No such package." unless package

    log.print "- Package name: #{package.pkg}"
    log.print "                #{package.data.data.name}" if package.data.data.name
    log.print "- Description:\n#{package.data.data.description}" if package.data.data.description
    log.print "- Authors:\n#{package.data.data.authors}" if package.data.data.authors
    log.print "- Files:        #{tableLen package.data.data.files}" if package.data.data.files
    log.print "- Depends:      #{table.concat [x for x in pairs package.data.data.dependencies], "  "}" if package.data.data.dependencies
    log.print "- Note:\n#{package.data.data.note}" if package.data.data.note
    log.print "- Repository:   https://github.com/#{package.repo}"


-- Command implementation ------------------------------------------------------

printPackageList = ->
  modList = try listFiles distPath
  empty = true
  for modDir in modList
    mod = fs.name modDir
    if isDirectory concat distPath, mod
      list = try listFiles concat distPath, mod
      for file in list
        unless isDirectory concat distPath, mod, file
          manifest = try loadManifest file, nil, mod
          log.print mod .. ":" .. file .. (manifest.version and " @ " .. manifest.version or "")
          empty = false
  log.print "No packages installed." if empty


-- Main ------------------------------------------------------------------------

-- Parse command line arguments
parseArguments = (...) ->
  args, options = parse ...
  printUsage! if #args < 1

-- Process given command and arguments
process = ->
  switch args[1]
    when "list"
      printPackageList!
    when "help"
      printUsage!
    else
      if cmd = findCustomCommand args[1]
        cmd unpack [x for x in *args[2,]]

-- Set the module env
env.semver = {
  Version: semver.Version
  Spec: semver.Spec
  SpecItem: semver.SpecItem
  compare: semver.compare
  match: semver.match
  validate: semver.validate
}
env.json = json
env.CONFIG_PATH = CONFIG_PATH
env.USAGE = USAGE
env.DEFAULT_CONFIG = DEFAULT_CONFIG
env.options = options
env.args = args
env.request = request
env.modules = modules
env.config = config
env.modulePath = modulePath
env.distPath = distPath
env.exitCode = exitCode
env.log = log
env.assert = assert
env.unimplemented = unimplemented
env.printUsage = printUsage
env.try = try
env.checkType = checkType
env.argNumber = argNumber
env.argString = argString
env.isin = isin
env.tableLen = tableLen
env.empty = empty
env.all = all
env.existsDir = existsDir
env.existsFile = existsFile
env.plural = plural
env.singular = singular
env.linkingVerb = linkingVerb
env.remove = remove
env.loadConfig = loadConfig
env.checkInternet = checkInternet
env.download = download
env.findCustomCommand = findCustomCommand
env.getModuleBy = getModuleBy
env.callModuleMethod = callModuleMethod
env.saveManifest = saveManifest
env.loadManifest = loadManifest
env.removeManifest = removeManifest
env.public = public
env.wrapResponse = wrapResponse
env.recv = recv
env.confirm = confirm
env.pkgPlan = pkgPlan
env.printPackageList = printPackageList
env.parseArguments = parseArguments
env.process = process

for k, v in pairs _G
  env[k] = v

-- Run!
parseArguments ...
try loadConfig!
loadCustomModules!
process!
exitCode
