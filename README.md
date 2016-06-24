# Hel Package Manager

Command-line package manager for OpenOS (OpenComputers).
Allows to easily download and install programs from [Hel Repository](https://github.com/MoonlightOwl/hel).
Alternative app sources are supported: Pastebin, Gist, GitHub, direct links. 

Also you can define your own way of package dustribution, via custom hpm modules.

HPM is in very early development stage, so feel free to contribute.

## Features
 * OpenSource ;)
 * Small & Fast
 * Configurable & Extendable
 * Cool

## Usage
```
Usage: hpm [-vq] <command>
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
```

## Download
You can find the last development build here, in the `/build` directory.
