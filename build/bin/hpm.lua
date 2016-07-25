local isAvailable
isAvailable = require("component").isAvailable
local parse
parse = require("shell").parse
local exists, makeDirectory, concat, remove, copy, list
do
  local _obj_0 = require("filesystem")
  exists, makeDirectory, concat, remove, copy, list = _obj_0.exists, _obj_0.makeDirectory, _obj_0.concat, _obj_0.remove, _obj_0.copy, _obj_0.list
end
local serialize, unserialize
do
  local _obj_0 = require("serialization")
  serialize, unserialize = _obj_0.serialize, _obj_0.unserialize
end
local exit
exit = os.exit
local write, stderr
do
  local _obj_0 = io
  write, stderr = _obj_0.write, _obj_0.stderr
end
local insert
insert = table.insert
local semver = (function()
  local _ = [[     Copyright (c) The python-semanticversion project
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
  _ = [[  The use of the library is similar to the original one,
  check the documentation here: https://python-semanticversion.readthedocs.io/en/latest/
  ]]
  local unpack
  do
    local _obj_0 = table
    concat, insert, unpack = _obj_0.concat, _obj_0.insert, _obj_0.unpack
  end
  local toInt
  toInt = function(value)
    do
      local tn = tonumber(value)
      if tn then
        return tn, true
      else
        return value, false
      end
    end
  end
  local hasLeadingZero
  hasLeadingZero = function(value)
    return value and value[1] == '0' and tonumber(value and value ~= '0')
  end
  local baseCmp
  baseCmp = function(x, y)
    if x == y then
      return 0
    end
    if x > y then
      return 1
    end
    if x < y then
      return -1
    end
  end
  local identifierCmp
  identifierCmp = function(a, b)
    local aCmp, aInt = toInt(a)
    local bCmp, bInt = toInt(b)
    if aInt and bInt then
      return baseCmp(aCmp, bCmp)
    elseif aInt then
      return -1
    elseif bInt then
      return 1
    else
      return baseCmp(aCmp, bCmp)
    end
  end
  local identifierListCmp
  identifierListCmp = function(a, b)
    local identifierPairs
    do
      local _tbl_0 = { }
      for i = 1, #a do
        if b[i] then
          _tbl_0[a[i]] = b[i]
        end
      end
      identifierPairs = _tbl_0
    end
    for idA, idB in pairs(identifierPairs) do
      local cmpRes = identifierCmp(idA, idB)
      if cmpRes ~= 0 then
        return cmpRes
      end
    end
    return baseCmp(#a, #b)
  end
  local Version
  do
    local _class_0
    local _base_0 = {
      _coerce = function(self, value, allowNil)
        if allowNil == nil then
          allowNil = false
        end
        if value == nil and allowNil then
          return value
        end
        return tonumber(value)
      end,
      next_major = function(self)
        if self.prerelease and self.minor == 0 and self.patch == 0 then
          return Version(concat((function()
            local _tbl_0 = { }
            for x in {
              self.major,
              self.minor,
              self.patch
            } do
              local _key_0, _val_0 = tostring(x)
              _tbl_0[_key_0] = _val_0
            end
            return _tbl_0
          end)(), '.'))
        else
          return Version(concat((function()
            local _tbl_0 = { }
            for x in {
              self.major + 1,
              0,
              0
            } do
              local _key_0, _val_0 = tostring(x)
              _tbl_0[_key_0] = _val_0
            end
            return _tbl_0
          end)(), '.'))
        end
      end,
      next_minor = function(self)
        if self.prerelease and self.patch == 0 then
          return Version(concat((function()
            local _tbl_0 = { }
            for x in {
              self.major,
              self.minor,
              self.patch
            } do
              local _key_0, _val_0 = tostring(x)
              _tbl_0[_key_0] = _val_0
            end
            return _tbl_0
          end)(), '.'))
        else
          return Version(concat((function()
            local _tbl_0 = { }
            for x in {
              self.major,
              self.minor + 1,
              0
            } do
              local _key_0, _val_0 = tostring(x)
              _tbl_0[_key_0] = _val_0
            end
            return _tbl_0
          end)(), '.'))
        end
      end,
      next_patch = function(self)
        if self.prerelease then
          return Version(concat((function()
            local _tbl_0 = { }
            for x in {
              self.major,
              self.minor,
              self.patch
            } do
              local _key_0, _val_0 = tostring(x)
              _tbl_0[_key_0] = _val_0
            end
            return _tbl_0
          end)(), '.'))
        else
          return Version(concat((function()
            local _tbl_0 = { }
            for x in {
              self.major,
              self.minor,
              self.patch + 1
            } do
              local _key_0, _val_0 = tostring(x)
              _tbl_0[_key_0] = _val_0
            end
            return _tbl_0
          end)(), '.'))
        end
      end,
      coerce = function(self, versionString, partial)
        if partial == nil then
          partial = false
        end
        local baseRe
        baseRe = function(s)
          local mjr, rmn = s:match('^(%d+)(.*)$')
          if not (mjr) then
            return nil
          end
          local t = mjr
          local mnr, r = rmn:match('^%.(%d+)(.*)$')
          if mnr then
            rmn = r
            t = t .. ('.' .. mnr)
          end
          local pch
          pch, r = rmn:match('^%.(%d+)(.*)$')
          if pch then
            rmn = r
            t = t .. ('.' .. pch)
          end
          return s, t
        end
        local match, matchEnd = baseRe(versionString)
        if not (match) then
          error("Version string lacks a numerical component: " .. tostring(versionString))
        end
        local version = versionString:sub(1, #matchEnd)
        if not partial then
          while ({
            version:gsub('.', '')
          })[2] < 2 do
            version = version .. '.0'
          end
        end
        if #matchEnd == #versionString then
          return Version(version, partial)
        end
        local rest = versionString:sub(#matchEnd + 1)
        rest = rest:gsub('[^a-zA-Z0-9+.-]', '-')
        local prerelease, build = nil, nil
        if rest:sub(1, 1) == '+' then
          prerelease = ''
          build = rest:sub(2)
        elseif rest:sub(1, 1) == '.' then
          prerelease = ''
          build = rest:sub(2)
        elseif rest:sub(1, 1) == '-' then
          rest = rest:sub(2)
          do
            local p1 = rest:find('+')
            if p1 then
              prerelease, build = rest:sub(1, p1 - 1), rest:sub(p1 + 1, -1)
            else
              prerelease, build = rest, ''
            end
          end
        else
          do
            local p1 = rest:find('+')
            if p1 then
              prerelease, build = rest:sub(1, p1 - 1), rest:sub(p1 + 1, -1)
            else
              prerelease, build = rest, ''
            end
          end
        end
        build = build:gsub('+', '.')
        if prerelease and prerelease ~= '' then
          version = version .. ('-' .. prerelease)
        end
        if build and build ~= '' then
          version = version .. ('+' .. build)
        end
        return self.__class(version, partial)
      end,
      parse = function(self, versionString, partial, coerce)
        if partial == nil then
          partial = false
        end
        if coerce == nil then
          coerce = false
        end
        if not versionString or type(versionString) ~= 'string' or versionString == '' then
          error("Invalid empty version string: " .. tostring(tostring(versionString)))
        end
        local versionRe
        if partial then
          versionRe = self.__class.partialVersionRe
        else
          versionRe = self.__class.versionRe
        end
        local major, minor, patch, prerelease, build = versionRe(self.__class, versionString)
        if not major then
          error("Invalid version string: " .. tostring(versionString))
        end
        if hasLeadingZero(major) then
          error("Invalid leading zero in major: " .. tostring(versionString))
        end
        if hasLeadingZero(minor) then
          error("Invalid leading zero in minor: " .. tostring(versionString))
        end
        if hasLeadingZero(patch) then
          error("Invalid leading zero in patch: " .. tostring(versionString))
        end
        major = tonumber(major)
        minor = self:_coerce(minor, partial)
        patch = self:_coerce(patch, partial)
        if prerelease == nil then
          if partial and build == nil then
            return {
              major,
              minor,
              patch,
              nil,
              nil
            }
          else
            prerelease = { }
          end
        elseif prerelease == '' then
          prerelease = { }
        else
          do
            local _accum_0 = { }
            local _len_0 = 1
            for x in prerelease:gmatch('[^.]+') do
              _accum_0[_len_0] = x
              _len_0 = _len_0 + 1
            end
            prerelease = _accum_0
          end
          self:_validateIdentifiers(prerelease, false)
        end
        if build == nil then
          if partial then
            build = nil
          else
            build = { }
          end
        elseif build == '' then
          build = { }
        else
          do
            local _accum_0 = { }
            local _len_0 = 1
            for x in build:gmatch('[^.]+') do
              _accum_0[_len_0] = x
              _len_0 = _len_0 + 1
            end
            build = _accum_0
          end
          self:_validateIdentifiers(build, true)
        end
        return {
          major,
          minor,
          patch,
          prerelease,
          build
        }
      end,
      _validateIdentifiers = function(self, identifiers, allowLeadingZeroes)
        if allowLeadingZeroes == nil then
          allowLeadingZeroes = false
        end
        for _index_0 = 1, #identifiers do
          local item = identifiers[_index_0]
          if not item then
            error("Invalid empty identifier " .. tostring(item) .. " in " .. tostring(concat(identifiers, '.')))
          end
          if item:sub(1, 1) == '0' and tonumber(item) and item ~= '0' and not allowLeadingZeroes then
            error("Invalid leading zero in identifier " .. tostring(item))
          end
        end
      end,
      __pairs = function(self)
        return pairs({
          self.major,
          self.minor,
          self.patch,
          self.prerelease,
          self.build
        })
      end,
      __ipairs = function(self)
        return ipairs({
          self.major,
          self.minor,
          self.patch,
          self.prerelease,
          self.build
        })
      end,
      __tostring = function(self)
        local version = tostring(self.major)
        if self.minor ~= nil then
          version = version .. ('.' .. self.minor)
        end
        if self.patch ~= nil then
          version = version .. ('.' .. self.patch)
        end
        if self.prerelease and #self.prerelease > 0 or self.partial and self.prerelease and #self.prerelease == 0 and self.build == nil then
          version = version .. ('-' .. concat(self.prerelease, '.'))
        end
        if self.build and #self.build > 0 or self.partial and self.build and #self.build == 0 then
          version = version .. ('+' .. concat(self.build, '.'))
        end
        return version
      end,
      _comparsionFunctions = function(self, partial)
        if partial == nil then
          partial = false
        end
        local prereleaseCmp
        prereleaseCmp = function(a, b)
          if a and b then
            return identifierListCmp(a, b)
          elseif a then
            return -1
          elseif b then
            return 1
          else
            return 0
          end
        end
        local buildCmp
        buildCmp = function(a, b)
          if a == b then
            return 0
          else
            return 'not implemented'
          end
        end
        local makeOptional
        makeOptional = function(origCmpFun)
          local altCmpFun
          altCmpFun = function(a, b)
            if a == nil and b == nil then
              return 0
            else
              return origCmpFun(a, b)
            end
          end
          return altCmpFun
        end
        if partial then
          return {
            baseCmp,
            makeOptional(baseCmp),
            makeOptional(baseCmp),
            makeOptional(prereleaseCmp),
            makeOptional(buildCmp)
          }
        else
          return {
            baseCmp,
            baseCmp,
            baseCmp,
            prereleaseCmp,
            buildCmp
          }
        end
      end,
      __compare = function(self, other)
        local comparsionFunctions = self:_comparsionFunctions(self.partial or other.partial)
        local comparsions = {
          {
            comparsionFunctions[1],
            self.major,
            other.major
          },
          {
            comparsionFunctions[2],
            self.minor,
            other.minor
          },
          {
            comparsionFunctions[3],
            self.patch,
            other.patch
          },
          {
            comparsionFunctions[4],
            self.prerelease,
            other.prerelease
          },
          {
            comparsionFunctions[5],
            self.build,
            other.build
          }
        }
        for _index_0 = 1, #comparsions do
          local cmpField = comparsions[_index_0]
          local cmpFun, selfField, otherField = unpack(cmpField)
          local cmpRes = cmpFun(selfField, otherField)
          if cmpRes ~= 0 then
            return cmpRes
          end
        end
        return 0
      end,
      __compareHelper = function(self, other, condition, notimplTarget)
        local cmpRes = self:__compare(other)
        if cmpRes == 'not implemented' then
          return notimplTarget
        end
        return condition(cmpRes)
      end,
      __eq = function(self, other)
        local c
        c = function(x)
          return x == 0
        end
        return self:__compareHelper(other, c, false)
      end,
      __lt = function(self, other)
        local c
        c = function(x)
          return x < 0
        end
        return self:__compareHelper(other, c, false)
      end,
      __le = function(self, other)
        local c
        c = function(x)
          return x <= 0
        end
        return self:__compareHelper(other, c, false)
      end
    }
    _base_0.__index = _base_0
    _class_0 = setmetatable({
      __init = function(self, versionString, partial)
        if partial == nil then
          partial = false
        end
        local major, minor, patch, prerelease, build = unpack(self:parse(versionString, partial))
        self.major, self.minor, self.patch, self.prerelease, self.build, self.partial = major, minor, patch, prerelease, build, partial
      end,
      __base = _base_0,
      __name = "Version"
    }, {
      __index = _base_0,
      __call = function(cls, ...)
        local _self_0 = setmetatable({}, _base_0)
        cls.__init(_self_0, ...)
        return _self_0
      end
    })
    _base_0.__class = _class_0
    local self = _class_0
    self.versionRe = function(self, s)
      local mjr, mnr, pch, rmn = s:match('^(%d+)%.(%d+)%.(%d+)(.*)$')
      if not (mjr) then
        return nil
      end
      local add, r = rmn:match('^%-([0-9a-zA-z.-]+)(.*)$')
      if add then
        rmn = r
      end
      local meta
      meta, r = rmn:match('^%+([0-9a-zA-Z.-]+)(.*)$')
      if meta then
        rmn = r
      end
      if #rmn > 0 then
        return nil
      end
      return mjr, mnr, pch, add, meta
    end
    self.partialVersionRe = function(self, s)
      local mjr, rmn = s:match('^(%d+)(.*)$')
      if not (mjr) then
        return nil
      end
      local mnr, r = rmn:match('^%.(%d+)(.*)$')
      if mnr then
        rmn = r
      end
      local pch
      pch, r = rmn:match('^%.(%d+)(.*)$')
      if pch then
        rmn = r
      end
      local add
      add, r = rmn:match('^%-([0-9a-zA-Z.-]*)(.*)$')
      if add then
        rmn = r
      end
      local meta
      meta, r = rmn:match('^%+([0-9a-zA-Z.-]*)(.*)$')
      if meta then
        rmn = r
      end
      if #rmn > 0 then
        return nil
      end
      return mjr, mnr, pch, add, meta
    end
    Version = _class_0
  end
  local SpecItem
  do
    local _class_0
    local _base_0 = {
      parse = function(self, requirementString)
        if not requirementString or type(requirementString) ~= 'string' or requirementString == '' then
          error("Invalid empty requirement specification: " .. tostring(tostring(requirementString)))
        end
        if requirementString == '*' then
          return {
            self.__class.KIND_ANY,
            ''
          }
        end
        local kind, version = self.__class:reSpec(requirementString)
        if not kind then
          error("Invalid requirement specification: " .. tostring(requirementString))
        end
        kind = self.__class.KIND_ALIASES[kind] or kind
        local spec = Version(version, true)
        if spec.build ~= nil and kind ~= self.__class.KIND_EQUAL and kind ~= self.__class.KIND_NEQ then
          error("Invalid requirement specification " .. tostring(requirementString) .. ": build numbers have no ordering")
        end
        return {
          kind,
          spec
        }
      end,
      match = function(self, version)
        local _exp_0 = self.kind
        if self.__class.KIND_ANY == _exp_0 then
          return true
        elseif self.__class.KIND_LT == _exp_0 then
          return version < self.spec
        elseif self.__class.KIND_LTE == _exp_0 then
          return version <= self.spec
        elseif self.__class.KIND_EQUAL == _exp_0 then
          return version == self.spec
        elseif self.__class.KIND_GTE == _exp_0 then
          return version >= self.spec
        elseif self.__class.KIND_GT == _exp_0 then
          return version > self.spec
        elseif self.__class.KIND_NEQ == _exp_0 then
          return version ~= self.spec
        elseif self.__class.KIND_CARET == _exp_0 then
          return self.spec <= version and version < self.spec:next_major()
        elseif self.__class.KIND_TILDE == _exp_0 then
          return self.spec <= version and version < self.spec:next_minor()
        else
          return error("Unexpected match kind: " .. tostring(self.kind))
        end
      end,
      __tostring = function(self)
        return self.kind .. self.spec
      end,
      __eq = function(self, other)
        return self.kind == other.kind and self.spec == other.spec
      end
    }
    _base_0.__index = _base_0
    _class_0 = setmetatable({
      __init = function(self, requirementString)
        self.kind, self.spec = unpack(self:parse(requirementString))
      end,
      __base = _base_0,
      __name = "SpecItem"
    }, {
      __index = _base_0,
      __call = function(cls, ...)
        local _self_0 = setmetatable({}, _base_0)
        cls.__init(_self_0, ...)
        return _self_0
      end
    })
    _base_0.__class = _class_0
    local self = _class_0
    self.KIND_ANY = '*'
    self.KIND_LT = '<'
    self.KIND_LTE = '<='
    self.KIND_EQUAL = '=='
    self.KIND_SHORTEQ = '='
    self.KIND_EMPTY = ''
    self.KIND_GTE = '>='
    self.KIND_GT = '>'
    self.KIND_NEQ = '!='
    self.KIND_CARET = '^'
    self.KIND_TILDE = '~'
    self.KIND_ALIASES = {
      [self.__class.KIND_SHORTEQ] = self.__class.KIND_EQUAL,
      [self.__class.KIND_EMPTY] = self.__class.KIND_EQUAL
    }
    self.reSpec = function(s)
      local chr, v = s:match('^(.*)(%d.*)$')
      if not (chr == '<' or chr == '<=' or chr == '' or chr == '=' or chr == '==' or chr == '>=' or chr == '>' or chr == '!=' or chr == '^' or chr == '~') then
        return nil
      else
        return chr, v
      end
    end
    SpecItem = _class_0
  end
  local Spec
  do
    local _class_0
    local _base_0 = {
      parse = function(self, specsString)
        local _accum_0 = { }
        local _len_0 = 1
        for x in specsString:gmatch('[^,]+') do
          _accum_0[_len_0] = SpecItem(x)
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end,
      match = function(self, version)
        local _list_0 = self.specs
        for _index_0 = 1, #_list_0 do
          local spec = _list_0[_index_0]
          if not spec:match(version) then
            return false
          end
        end
        return true
      end,
      filter = function(self, versions)
        local i = 0
        return function()
          while true do
            i = i + 1
            local version = versions[i]
            if not (version) then
              return nil
            end
            if self:match(version) then
              return version
            end
          end
        end
      end,
      select = function(self, versions)
        local options
        do
          local _accum_0 = { }
          local _len_0 = 1
          for x in self:filter(versions) do
            _accum_0[_len_0] = x
            _len_0 = _len_0 + 1
          end
          options = _accum_0
        end
        if #options > 0 then
          local max = options[1]
          for _index_0 = 1, #options do
            local ver = options[_index_0]
            if max < ver then
              max = ver
            end
          end
          return max
        else
          return nil
        end
      end,
      __index = function(self, k)
        if self:match(k) then
          return true
        else
          return nil
        end
      end,
      __pairs = function(self)
        return pairs(self.specs)
      end,
      __ipairs = function(self)
        return ipairs(self.specs)
      end,
      __tostring = function(self)
        return concat((function()
          local _tbl_0 = { }
          local _list_0 = self.specs
          for _index_0 = 1, #_list_0 do
            local spec = _list_0[_index_0]
            local _key_0, _val_0 = tostring(spec)
            _tbl_0[_key_0] = _val_0
          end
          return _tbl_0
        end)(), ',')
      end,
      __eq = function(self, other)
        local _list_0 = self.specs
        for _index_0 = 1, #_list_0 do
          local selfSpec = _list_0[_index_0]
          local s = false
          local _list_1 = other.specs
          for _index_1 = 1, #_list_1 do
            local otherSpec = _list_1[_index_1]
            if selfSpec == otherSpec then
              s = true
              break
            end
          end
          if not s then
            return false
          end
        end
        return true
      end
    }
    _base_0.__index = _base_0
    _class_0 = setmetatable({
      __init = function(self, specsStrings)
        if type(specsStrings) == 'string' then
          specsStrings = {
            specsStrings
          }
        end
        local subspecs
        do
          local _accum_0 = { }
          local _len_0 = 1
          for _index_0 = 1, #specsStrings do
            local spec = specsStrings[_index_0]
            _accum_0[_len_0] = self:parse(spec)
            _len_0 = _len_0 + 1
          end
          subspecs = _accum_0
        end
        self.specs = { }
        for _index_0 = 1, #subspecs do
          local subspec = subspecs[_index_0]
          for _index_1 = 1, #subspec do
            local spec = subspec[_index_1]
            insert(self.specs, spec)
          end
        end
      end,
      __base = _base_0,
      __name = "Spec"
    }, {
      __index = _base_0,
      __call = function(cls, ...)
        local _self_0 = setmetatable({}, _base_0)
        cls.__init(_self_0, ...)
        return _self_0
      end
    })
    _base_0.__class = _class_0
    Spec = _class_0
  end
  local compare
  compare = function(v1, v2)
    return baseCmp(Version(v1, Version(v2)))
  end
  local match
  match = function(spec, version)
    return Spec(spec):match(Version(version))
  end
  local validate
  validate = function(versionString)
    return ({
      Version:parse(versionString)
    })[1]
  end
  return {
    Spec = Spec,
    SpecItem = SpecItem,
    Version = Version,
    compare = compare,
    match = match,
    validate = validate
  }
end)()
local listFiles = list
local options, args = { }, { }
local request = nil
local modules = { }
local DIST_PATH = "/etc/hpm/dist/"
local MODULE_PATH = "/etc/hpm/module/"
local USAGE = "Usage: hpm [-vq] <command>\n  -q: Quiet mode - no console output.\n  -v: Verbose mode - show additional info.\n  \nAvailable commands:\n  install <package> [...]   Download package[s] from Hel Repository, and install it into the system.\n  remove <package> [...]    Remove all package[s] files from the system.\n  save <package> [...]      Download package[s] without installation.\n  list                      Show list of installed packages.\n  help                      Show this message. \n  \nAvailable package formats:\n  [hel:]<name>[@<version>]  Package from Hel Package Repository (default option).\n  local:<path>              Get package from local file system.\n  pastebin:<name>@<id>      Download source code from given Pastebin page.\n  direct:<name>@<url>       Fetch file from <url>."
local log = {
  info = function(message)
    if options.v then
      return print(message)
    end
  end,
  print = function(message)
    if not (options.q) then
      return print(message)
    end
  end,
  error = function(message)
    if not (options.q) then
      return stderr:write(message .. '\n')
    end
  end,
  fatal = function(message)
    if not (options.q) then
      stderr:write(message .. '\n')
    end
    return exit(1)
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
local try
try = function(result, reason)
  if not (result) then
    log.fatal(reason)
  end
  return result
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
  request = request or require("internet").request
end
local download
download = function(url)
  checkInternet()
  return pcall(request, url)
end
local loadCustomModules
loadCustomModules = function()
  if not exists(MODULE_PATH) then
    local result, reason = makeDirectory(MODULE_PATH)
    if not result then
      return false, "Failed creating '" .. tostring(MODULE_PATH) .. "' directory for custom modules: " .. tostring(reason)
    end
  end
  list = try(listFiles(MODULE_PATH))
  for file in list do
    local name = file:match("^(.+)%..+$")
    local mod = dofile(concat(MODULE_PATH, file))
    if mod then
      modules[name] = mod
    end
  end
  return true
end
local getModuleBy
getModuleBy = function(source)
  if not source or source == "" then
    source = "hel"
  else
    source = source
  end
  return modules[source] or modules.default
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
local saveManifest
saveManifest = function(manifest, path, name)
  if not manifest then
    return false, "'nil' was given"
  end
  path = path or DIST_PATH
  name = name or manifest.name
  if not exists(path) then
    local result, reason = makeDirectory(path)
    if not result then
      return false, "Failed creating '" .. tostring(path) .. "' directory for manifest files: " .. tostring(reason)
    end
  end
  local file, reason = io.open(concat(path, name), "w")
  if file then
    file:write(serialize(manifest))
    file:close()
    return true
  else
    return false, "Failed opening file for writing: " .. tostring(reason)
  end
end
local loadManifest
loadManifest = function(name, path)
  path = path or concat(DIST_PATH, name)
  if exists(path) then
    local file, reason = io.open(path, "rb")
    if file then
      local manifest = unserialize(file:read("*all"))
      file:close()
      return manifest
    else
      return false, "Failed to open manifest for '" .. tostring(name) .. "' package: " .. tostring(reason)
    end
  else
    return false, "No manifest found for '" .. tostring(name) .. "' package"
  end
end
local removeManifest
removeManifest = function(name)
  local path = concat(DIST_PATH, name)
  if exists(path) then
    return remove(path)
  else
    return false, "No manifest found for '" .. tostring(name) .. "' package"
  end
end
modules.default = {
  install = function()
    return log.fatal("Incorrect source was provided! No default 'install' implementation.")
  end,
  remove = function(self, manifest)
    if manifest then
      if manifest.files then
        for i, file in pairs(manifest.files) do
          local path = concat(file.dir, file.name)
          local result, reason = remove(path)
          if not (result) then
            return false, "Failed removing '" .. tostring(path) .. "' file: " .. tostring(reason)
          end
        end
      end
      return removeManifest(manifest.name)
    else
      return false, "Package cannot be removed: empty manifest."
    end
  end,
  save = function()
    return log.fatal("Incorrect source was provided! No default 'save' implementation.")
  end
}
modules.hel = {
  URL = "http://hel-roottree.rhcloud.com/",
  parsePackageJSON = function(self, json, spec)
    local selectedVersion, selectedNumber = nil, nil
    local versionsString = json:match('"versions":%s*(%b{})')
    if not (versionsString) then
      log.fatal("Incorrect JSON format!\n" .. tostring(json))
    end
    local versions = { }
    for number, data in versionsString:gmatch('"(.-)":%s*(%b{})') do
      local success, v = pcall(semver.Version(number))
      if not (success) then
        log.fatal("Could not parse the version in package: " .. tostring(v))
      end
      versions[v] = data
    end
    local bestMatch = versions[spec:select((function()
      local _accum_0 = { }
      local _len_0 = 1
      for version, data in pairs(versions) do
        _accum_0[_len_0] = version
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end)())]
    if not (bestMatch) then
      log.fatal("No candidate for version specification '" .. tostring(spec) .. "' found!")
    end
    local data = {
      version = selectedNumber,
      files = { }
    }
    local files = selectedVersion:match('"files":%s*(%b{})')
    for url, file in files:gmatch('"(.-)":%s*(%b{})') do
      local dir = file:match('"dir":%s*"(.-)"')
      local name = file:match('"name":%s*"(.-)"')
      insert(data.files, {
        url = url,
        dir = dir,
        name = name
      })
    end
    return data
  end,
  install = function(self, name, specString, save)
    log.print("Creating version specification for " .. tostring(specString) .. " ...")
    local success, spec = pcall(semver.Spec(specString))
    if not (success) then
      log.fatal("Could not parse the version specification: " .. tostring(spec) .. "!")
    end
    log.print("Downloading package data ...")
    local status, response = download(self.URL .. "packages/" .. name)
    if not (status) then
      log.fatal("HTTP request error: " .. response)
    end
    local json = ""
    for chunk in response do
      json = json .. chunk
    end
    local data = self:parsePackageJSON(json, spec)
    local path
    if save then
      path = "./" .. tostring(name) .. "/"
    end
    if save and not exists(path) then
      local result
      result, response = makeDirectory(path)
      if not (result) then
        log.fatal("Failed creating '" .. tostring(path) .. "' directory for package '" .. tostring(name) .. "'! \n" .. tostring(response))
      end
    end
    for key, file in pairs(data.files) do
      local f = nil
      local result
      result, response = download(file.url)
      if result then
        log.print("Fetching '" .. tostring(file.name) .. "' ...")
        if not save then
          path = file.dir
          if not exists(path) then
            result, response = makeDirectory(path)
            if not (result) then
              log.fatal("Failed creating '" .. tostring(path) .. "' directory for '" .. tostring(file.name) .. "'! \n" .. tostring(response))
            end
          end
        end
        local reason
        result, reason = pcall(function()
          for chunk in response do
            if not f then
              f, reason = io.open(concat(path, file.name), "wb")
              assert(f, "Failed opening file for writing: " .. tostring(reason))
            end
            f:write(chunk)
          end
        end)
      end
      if f then
        f:close()
      end
      if not (result) then
        log.fatal("Failed to download '" .. tostring(file.name) .. "' from '" .. tostring(file.url) .. "'! \n" .. tostring(response))
      end
    end
    log.print("Done.")
    data.name = name
    return data
  end,
  save = function(self, name, version)
    return self:install(name, version, true)
  end
}
modules["local"] = {
  install = function(self, path, version)
    local manifest = loadManifest(path, concat(path, "manifest"))
    for key, file in pairs(manifest.files) do
      log.print("Install '" .. tostring(file.name) .. "' ... ")
      local result, reason = copy(concat(path, file.name), concat(file.dir, file.name))
      if not (result) then
        log.error("Cannot copy '" .. tostring(file.name) .. "' file: " .. tostring(reason))
      end
    end
    log.print("Done.")
    return manifest
  end
}
local removePackage
removePackage = function(source, name)
  if not (name) then
    log.fatal("Incorrect package name!")
  end
  local manifest = try(loadManifest(name))
  try(callModuleMethod(getModuleBy(source), "remove", manifest))
  return log.print("Done removal.")
end
local installPackage
installPackage = function(source, name, meta)
  if not (name) then
    log.fatal("Incorrect package name!")
  end
  local manifest, reason = loadManifest(name)
  if manifest then
    removePackage(source, name)
  end
  local result
  result, reason = saveManifest(callModuleMethod(getModuleBy(source), "install", name, meta))
  if result then
    return log.info("Manifest for '" .. tostring(name) .. "' package was saved.")
  else
    return log.error("Error saving manifest for '" .. tostring(name) .. "' package: " .. tostring(reason) .. ".")
  end
end
local savePackage
savePackage = function(source, name, meta)
  if not (name) then
    log.fatal("Incorrect package name!")
  end
  if source == "local" then
    log.fatal("No need to save already saved package...")
  end
  local result, reason = saveManifest(callModuleMethod(getModuleBy(source), "save", name, meta), "./" .. tostring(name) .. "/", "manifest")
  if result then
    return log.info("Manifest for local '" .. tostring(name) .. "' package was saved.")
  else
    return log.error("Error saving manifest for local '" .. tostring(name) .. "' package: " .. tostring(reason) .. ".")
  end
end
local printPackageList
printPackageList = function()
  list = try(listFiles(DIST_PATH))
  empty = true
  for file in list do
    local manifest = try(loadManifest(file))
    log.print(file .. (manifest.version and " @ " .. manifest.version or ""))
    empty = false
  end
  if empty then
    return log.print("No packages was installed.")
  end
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
  elseif "save" == _exp_0 then
    if #args < 2 then
      log.fatal("No package(s) was provided!")
    end
    for i = 2, #args do
      savePackage(parsePackageName(args[i]))
    end
  elseif "remove" == _exp_0 then
    if #args < 2 then
      log.fatal("No package(s) was provided!")
    end
    for i = 2, #args do
      removePackage(parsePackageName(args[i]))
    end
  elseif "list" == _exp_0 then
    return printPackageList()
  else
    return printUsage()
  end
end
parseArguments(...)
loadCustomModules()
process()
return 0
