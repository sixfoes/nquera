# nquera
nquera is a Neovim plugin for executing system queries like MongoDB, Curl, RedShift and anything later


## Installation

Use [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "sixfoes/nquera",
  config = function()
    require("nquera").setup({
      split_type = "new", --new, vertical, horizontal
      queries = {
        Mongo = { command = "mongosh {URI} --eval {buffer}" },
        Curl = { command = "Not Applicable" },
        Redshift = { command = "node script.js {buffer}" }
      }
    })
  end
}
```

## Usage
- `:N{command name}` → Runs the current buffer as a {command} query.

- `:NMongo` → Runs the current buffer as a MongoDB query.
- `:NCurl` → Runs the current buffer as a system command.
- `:NRedshift` → Runs the current buffer as a Redshift query.


## Environment Variables
nquera reads `.env` from the project or home directory or global.
Set `Mongo_URI`, `Redshift_URI`, etc.

Enjoy!
