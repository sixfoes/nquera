
-- lua/nquera/query.lua
local M = {}
local home_dir = vim.fn.expand('~')
local env_file = vim.fn.expand('./.env')

M.default_split_type = "new"

-- Function to read .env file
function M.load_env_file()
  local env_vars = {}
  local file = io.open(env_file, "r")

  if not file then
    file = io.open(home_dir .. '/.env', "r")
  end

  if file then
    for line in file:lines() do
      if line ~= "" and not line:match("^#") then
        local key, value = line:match("^([^=]+)=(.*)$")
        if key and value then
          env_vars[key] = value
        end
      end
    end
    file:close()
  end

  return env_vars
end

-- Load environment variables
local env_vars = M.load_env_file()
M.queries = {}

-- Get buffer content (selected text or full buffer)
local function get_buffer_content(args)
  local text = nil

  if args.range > 0 then
    local ls, cs = unpack(vim.api.nvim_buf_get_mark(0, "<"))
    local le, ce = unpack(vim.api.nvim_buf_get_mark(0, ">"))
    ls, le = ls - 1, le - 1

    local lines = vim.api.nvim_buf_get_text(0, ls, cs, le, ce, {})
    text = #lines > 0 and table.concat(lines, "\n") or nil
  end

  if not text then
    text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  end

  return text
end

-- Replace placeholders in commands
local function replace_placeholders(command, buffer_content, query_type)
  command = command:gsub("{buffer}", vim.fn.shellescape(buffer_content))

  -- Auto-detect URI from env using pattern "query_type_URI"
  local uri_env_var = query_type .. "_URI"
  local uri_value = env_vars[uri_env_var] or ""

  return command:gsub("{URI}", vim.fn.shellescape(uri_value))
end


-- Execute query
function M.send_query(query_type, args)
  local query = M.queries[query_type]
  if not query then
    vim.api.nvim_err_writeln("Error: Unknown query type: " .. query_type)
    return
  end

  local buffer_content = get_buffer_content(args)

  local final_command
  if query.command == "Not Applicable" then
    -- Execute buffer content as the system command
    final_command = buffer_content
  else
    -- Replace placeholders and execute as predefined query
    final_command = replace_placeholders(query.command, buffer_content, query_type)
  end

  -- Execute command and capture output
  local output = vim.fn.systemlist(final_command)

  -- Open buffer for results
  local timestamp = os.date("%Y-%m-%d_%H-%M-%S")
  local output_buf_name = query_type .. " Result " .. timestamp
  local output_buf = M.open_buffer(M.default_split_type, output_buf_name)
  vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, output)
end

-- Open output buffer in split/new
function M.open_buffer(split_type, buf_name)
  -- First, split the window (vertical or horizontal)
  if split_type == "vertical" then
    vim.cmd("vsplit")
  elseif split_type == "horizontal" then
    vim.cmd("split")
  end

  -- After splitting, create a new buffer in the new window
  vim.cmd("enew")  -- Create a new buffer
  local output_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(output_buf, buf_name)

  -- Return the buffer handle for further manipulation
  return output_buf
end


-- Open output buffer in split/new
function M.open_buffer_bak(split_type, buf_name)
  local output_buf

  if split_type == "new" then
    -- For "new", replace the content of the current window with the query results
    output_buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_name(output_buf, buf_name)
  else
    -- Create a new buffer for "vertical" or "horizontal" splits
    vim.cmd("enew")
    output_buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_name(output_buf, buf_name)

    -- Split based on the user's preference
    if split_type == "vertical" then
      vim.cmd("vsplit")
    elseif split_type == "horizontal" then
      vim.cmd("split")
    end
  end

  -- Set focus to the new buffer (this is key for splits)
  vim.api.nvim_set_current_buf(output_buf)

  return output_buf
end

-- Plugin setup function
function M.setup(config)
  M.default_split_type = config.split_type or M.default_split_type

  for query_type, query_config in pairs(config.queries or {}) do
    M.queries[query_type] = {
      command = query_config.command,
      keymap = query_config.keymap
    }

    -- Register user command using query type name (e.g., NMongo, NCurl)
    vim.api.nvim_create_user_command(
      'N' .. query_type,
      function(opts)
        M.send_query(query_type, opts)
      end,
      { range = true }
    )

    -- Bind keymap if provided
    if query_config.keymap then
      vim.api.nvim_set_keymap('n', query_config.keymap, ':N' .. query_type .. '<CR>', { noremap = true, silent = true })
    end
  end
end

return M
