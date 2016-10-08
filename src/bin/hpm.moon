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
        Version concat {tostring x for x in {@major, @minor, @patch}}, '.'
      else
        Version concat {tostring x for x in {@major + 1, 0, 0}}, '.'

    next_minor: =>
      if @prerelease and @patch == 0
        Version concat {tostring x for x in {@major, @minor, @patch}}, '.'
      else
        Version concat {tostring x for x in {@major, @minor + 1, 0}}, '.'

    next_patch: =>
      if @prerelease
        Version concat {tostring x for x in {@major, @minor, @patch}}, '.'
      else
        Version concat {tostring x for x in {@major, @minor, @patch + 1}}, '.'

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
          if a == nil and b == nil
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

    @reSpec: (s) ->
      chr, v = s\match '^(.*)(%d.*)$'
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
      @kind .. @spec

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
      concat {tostring spec for spec in *@specs}, ','

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
import exists, makeDirectory, concat, remove, copy, list from require "filesystem"
import serialize, unserialize from require "serialization"

import exit from os
import write, stderr from io
import insert from table


-- Rename some imports
listFiles = list

-- Variables
options, args = {}, {}  -- command-line arguments
request = nil           -- internet request method (call checkInternet to instantiate)
modules = {}            -- distribution modules

-- Constants
DIST_PATH = "/etc/hpm/dist/"     -- there will be stored manifests of installed packages
MODULE_PATH = "/etc/hpm/module/" -- there will be placed custom source modules
USAGE = "Usage: hpm [-vq] <command>
  -q: Quiet mode - no console output.
  -v: Verbose mode - show additional info.

Available commands:
  install <package> [...]   Download package[s] from the Hel Repository, and install it to the system.
  remove <package> [...]    Remove package[s] from the system.
  save <package> [...]      Download package[s] without installation to the current directory.
  list                      Show list of installed packages.
  help                      Show this message.

Available package formats:
  [hel:]<name>[@<version>]  Package from the Hel Package Repository (default option).
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

-- Check if an element is in the table
isin = (v, tbl) ->
  for k, value in pairs tbl do
    if value == v then
      return true, k
  return false

-- Check if given string contains something useful
empty = (str) -> not str or #str < 1

-- Return (source, name, meta) from "[<source>:]<name>[@<meta>]" string
parsePackageName = (value) ->
  value\match("^([^:]-):?([^:@]+)@?([^:@]*)$")

-- Check for internet availability
checkInternet = ->
  log.fatal "This command requires an internet card to run!" unless isAvailable "internet"
  request = request or require("internet").request

-- Return download stream, for something
download = (url) ->
  checkInternet!
  pcall request, url

-- Load available modules
loadCustomModules = ->
  if not exists MODULE_PATH
    result, reason = makeDirectory MODULE_PATH
    if not result
      return false, "Failed to create '#{MODULE_PATH}' directory for custom modules: #{reason}"
  list = try listFiles MODULE_PATH
  for file in list
    name = file\match("^(.+)%..+$")
    mod = dofile concat MODULE_PATH, file
    modules[name] = mod if mod
  true

-- Try to find module corresponding to the 'source' string
getModuleBy = (source) ->
  source = if not source or source == "" then "hel" else source
  modules[source] or modules.default

-- Call module operation (with fallback to default module)
callModuleMethod = (mod, name, ...) ->
  mod = mod or modules.default
  if mod[name] then mod[name](mod, ...)
  else modules.default[name](modules.default, ...)

-- Save manifest to dist-data folder
saveManifest = (manifest, path, name) ->
  if not manifest
    return false, "'nil' given"

  path = path or DIST_PATH
  name = name or manifest.name
  if not exists path
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
loadManifest = (name, path) ->
  path = path or concat DIST_PATH, name
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
--   save(self, name, meta)       -- download package without installation
--
-- Omitted methods will be replaced with default implementations

-- Default module
modules.default = {
  install: -> log.fatal "Incorrect source is provided! No default 'install' implementation."

  remove: (manifest) =>
    if manifest
      if manifest.files
        for i, file in pairs(manifest.files)
          path = concat file.dir, file.name
          result, reason = remove path
          return false, "Failed to remove '#{path}' file: #{reason}" unless result
      removeManifest manifest.name
    else
      false, "Package can't be removed: the manifest is empty."

  save: -> log.fatal "Incorrect source is provided! No default 'save' implementation."
}

-- Hel Repository module
modules.hel = {
  -- Repository API root url
  URL: "http://hel-roottree.rhcloud.com/"

  -- Get package data from JSON, and return as a table
  parsePackageJSON: (decoded, spec=semver.Spec "*") =>
    selectedVersion = nil

    versions = {}

    for number, data in pairs decoded.versions do
      v = semver.Version number
      log.fatal "Could not parse the version in package: #{v}" unless v
      versions[v] = data

    bestMatch = spec\select [version for version, data in pairs versions]
    selectedVersion = tostring bestMatch

    log.fatal "No candidate for version specification '#{spec}' found!" unless bestMatch

    data = { name: decoded.name, version: selectedVersion, files: {}, dependencies: {} }

    for url, file in pairs versions[bestMatch].files do
      dir = file.dir
      name = file.name
      insert data.files, { :url, :dir, :name }

    for depName, depData in pairs versions[bestMatch].depends do
      version = depData.version
      depType = depData.type
      insert data.dependencies, { name: depName, :version, type: depType }

    data


  getPackageSpec: (name) =>
    log.print "Downloading package data for #{name} ..."
    status, response = download @URL .. "packages/" .. name
    log.fatal "HTTP request error: " .. response unless status
    jsonData = ""
    for chunk in response do jsonData ..= chunk
    decoded = json\decode jsonData
    log.fatal "Incorrect JSON format!\n#{jsonData}" unless decoded
    decoded


  rawInstall: (pkgData, save) =>
    prefix = if save then
      concat getWorkingDirectory!, pkgData.name
    else
      "/"

    if save and not exists prefix
      result, response = makeDirectory prefix
      log.fatal "Failed creating '#{prefix}' directory for package '#{pkgData.name}'! \n#{response}" unless result
    elseif not save
      manifest = loadManifest pkgData.name
      if manifest then
        if manifest.version == tostring pkgData.version then
          log.print "'#{pkgData.name}@#{manifest.version}' is already installed, skipping..."
          return manifest
        else
          log.fatal "'#{pkgData.name}@#{pkgData.version}' was attempted to install, however, another version of the same package is already installed: '#{pkgData.name}@#{manifest.version}'"

    for key, file in pairs pkgData.files do
      f = nil
      result, response, reason = download file.url
      if result and response
        log.print "Fetching '#{file.name}' ..."

        path = prefix .. file.dir
        if not exists path
          result, response = makeDirectory path
          print path
          log.fatal "Failed to create '#{path}' directory for '#{file.name}'! \n#{response}" unless result

        result, reason = pcall ->
          for chunk in response do
            if not f then
              f, reason = io.open concat(path, file.name), "wb"
              assert f, "Failed to open file for writing: " .. tostring(reason)
            f\write(chunk)

      if f then f\close!
      log.fatal "Failed to download '#{file.name}' from '#{file.url}'! \n#{reason}" unless result

    log.print "Done."
    { name: pkgData.name, version: tostring(pkgData.version), files: pkgData.files, dependencies: pkgData.dependencies }


  -- Save package locally
  save: (name, version) =>
    @install name, version, true


  -- Get an ordered list of packages for installation, resolving dependencies.
  resolveDependencies: (name, verSpec, resolved={}, unresolved={}) =>
    insert unresolved, { :name, version: "" }
    manifest = loadManifest name
    if not manifest or verSpec\match semver.Version(manifest.version) then
      spec = @getPackageSpec name
      data = @parsePackageJSON spec, verSpec
      unresolved[#unresolved].version = data.version
      for dep in *data.dependencies do
        isResolved = false
        for pkg in *resolved do
          if pkg.pkg.name == dep.name then
            isResolved = true
            break
        if not isResolved then
          key = nil
          for k, pkg in pairs unresolved do
            if pkg.name == dep.name then
              key = k
              break
          if key then
            if unresolved[key].version == dep.version then
              log.fatal "Circular dependencies detected: '#{name}@#{tostring data.version}' depends on '#{dep.name}@#{tostring dep.version}', and '#{unresolved[key].name}@#{tostring unresolved[key].version}' depends on '#{name}@#{tostring spec.version}'."
            else
              log.fatal "Attempted to install two versions of the same package: '#{dep.name}@#{tostring dep.version}' and '#{unresolved[key].name}@#{unresolved[key].version}' when resolving dependencies for '#{name}@#{tostring spec.version}'."
          @resolveDependencies dep.name, semver.Spec(dep.version), resolved, unresolved
      insert resolved, { :spec, pkg: data }
    unresolved[#unresolved] = nil
    resolved


  -- Get all packages that depend on the given, and return a list of the dependent packages.
  getPackageDependants: (name, resolved={}, unresolved={}) =>
    insert unresolved, { :name }
    manifest = loadManifest name
    if manifest then
      insert resolved, { :name, :manifest }
      list = try listFiles DIST_PATH
      for file in list
        manifest = try loadManifest file
        for dep in *manifest.dependencies do
          if dep.name == name then
            isResolved = false
            for pkg in *resolved do
              if pkg.name == file then
                isResolved = true
                break
            if not isResolved then
              for pkg in *unresolved do
                if pkg.name == file then
                  log.fatal "Circular dependencies detected: #{file}"
              @getPackageDependants file, resolved, unresolved
    else
      log.fatal "Package #{name} is referenced as a dependant of another package, however, this package isn't installed."

    unresolved[#unresolved] = nil
    resolved


  -- Get package from repository, then parse, and install
  install: (name, specString="*", save) =>
    specString = "*" if empty(specString)
    log.print "Creating version specification for #{specString} ..."
    success, spec = pcall (() -> semver.Spec specString)
    log.fatal "Could not parse the version specification: #{spec}!" unless success

    dependencyGraph = @resolveDependencies name, spec
    manifests = {}
    for node in *dependencyGraph do
      log.print "Installing '#{node.spec.name}@#{tostring node.pkg.version}'..."
      insert manifests, @rawInstall node.pkg, save
    manifests


  -- Remove packages and its dependants
  remove: (manifest, recursiveCall=false) =>
    if recursiveCall
      return modules.default\remove manifest
    deps = @getPackageDependants manifest.name
    for dep in *deps do
      log.print "Removing '#{dep.manifest.name}@#{dep.manifest.version}' ..."
      try @remove dep.manifest, true
    true
}

-- Local-install module
modules.local = {
  install: (path, version) =>
    -- try to load data from local directory-package
    manifest = loadManifest path, concat path, "manifest"
    -- copy files to corresponding positions
    for key, file in pairs(manifest.files) do
      log.print "Install '#{file.name}' ... "
      result, reason = copy concat(path, file.name), concat(file.dir, file.name)
      log.error "Cannot copy '#{file.name}' file: #{reason}" unless result

    log.print "Done."
    { manifest }
}


-- Commands implementation -----------------------------------------------------

removePackage = (source, name) ->
  log.fatal "Incorrect package name!" unless name
  manifest = try loadManifest name
  try callModuleMethod getModuleBy(source), "remove", manifest
  log.print "Done removal."

installPackage = (source, name, meta) ->
  log.fatal "Incorrect package name!" unless name
  -- Check if this package was already installed
  manifest, reason = loadManifest name
  removePackage source, name if manifest
  -- Install
  result, reason = callModuleMethod getModuleBy(source), "install", name, meta
  if result then
    for manifest in *result do
      success, reason = saveManifest manifest
      if success
        log.info "Saved the manifest for '#{name}' package."
      else
        log.error "Couldn't save the manifest for '#{name}' package: #{reason}."
  else
    log.error "Couldn't install package: #{reason}"

savePackage = (source, name, meta) ->
  log.fatal "Incorrect package name!" unless name
  log.fatal "No need to save already saved package..." if source == "local"
  result, reason = callModuleMethod getModuleBy(source), "save", name, meta
  if result then
    for manifest in *result do
      success, reason = saveManifest result, "./#{manifest.name}/", "manifest"
      if success
        log.info "Saved the manifest for local '#{name}' package."
      else
        log.error "Couldn't save manifest for local '#{name}' package: #{reason}."
  else
    log.error "Couldn't install package: #{reason}."

printPackageList = ->
  list = try listFiles DIST_PATH
  empty = true
  for file in list
    manifest = try loadManifest file
    log.print file .. (manifest.version and " @ " .. manifest.version or "")
    empty = false
  log.print "No packages installed." if empty


-- App working -----------------------------------------------------------------

-- Parse command line arguments
parseArguments = (...) ->
  args, options = parse ...
  printUsage! if #args < 1

-- Process given command and arguments
process = ->
  switch args[1]
    when "install"
      log.fatal "No package(s) provided!" if #args < 2
      for i = 2, #args do installPackage parsePackageName args[i]
    when "save"
      log.fatal "No package(s) provided!" if #args < 2
      for i = 2, #args do savePackage parsePackageName args[i]
    when "remove"
      log.fatal "No package(s) provided!" if #args < 2
      for i = 2, #args do removePackage parsePackageName args[i]
    when "list"
      printPackageList!
    else
      printUsage!

-- Run!
parseArguments ...
loadCustomModules!
process!
0
