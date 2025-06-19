---@param config {type?:string, args?:string[]|fun():string[]?}
local function get_args(config)
  local args = type(config.args) == 'function' and (config.args() or {}) or config.args or {} --[[@as string[] | string ]]
  local args_str = type(args) == 'table' and table.concat(args, ' ') or args --[[@as string]]

  config = vim.deepcopy(config)
  ---@cast args string[]
  config.args = function()
    local new_args = vim.fn.expand(vim.fn.input('Run with args: ', args_str)) --[[@as string]]
    if config.type and config.type == 'java' then
      ---@diagnostic disable-next-line: return-type-mismatch
      return new_args
    end
    return require('dap.utils').splitstr(new_args)
  end
  return config
end

---@param name string
local function get_opts(name)
  local plugin = require('lazy.core.config').spec.plugins[name]
  if not plugin then
    return {}
  end
  local Plugin = require 'lazy.core.plugin'
  return Plugin.values(plugin, 'opts', false)
end

return {
  {
    'mfussenegger/nvim-dap',
    recommended = true,
    desc = 'Debugging support. Requires language specific adapters to be configured. (see lang extras)',

    dependencies = {
      'rcarriga/nvim-dap-ui',
      -- virtual text for the debugger
      {
        'theHamsta/nvim-dap-virtual-text',
        opts = {},
      },
      {
        'Joakker/lua-json5',
        build = './install.sh',
        lazy = true, -- Optional: Set to false if you want it to load immediately
      },
    },

    -- stylua: ignore
    keys = {
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Run/Continue" },
      { "<leader>da", function() require("dap").continue({ before = get_args }) end, desc = "Run with Args" },
      { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
      { "<leader>dg", function() require("dap").goto_() end, desc = "Go to Line (No Execute)" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
      { "<leader>dj", function() require("dap").down() end, desc = "Down" },
      { "<leader>dk", function() require("dap").up() end, desc = "Up" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
      { "<leader>do", function() require("dap").step_out() end, desc = "Step Out" },
      { "<leader>dO", function() require("dap").step_over() end, desc = "Step Over" },
      { "<leader>dP", function() require("dap").pause() end, desc = "Pause" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>ds", function() require("dap").session() end, desc = "Session" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
    },

    config = function()
      -- load mason-nvim-dap here, after all adapters have been setup
      if require('lazy.core.config').spec.plugins['mason-nvim-dap.nvim'] ~= nil then
        require('mason-nvim-dap').setup(get_opts 'mason-nvim-dap.nvim')
      end

      vim.api.nvim_set_hl(0, 'DapStoppedLine', { default = true, link = 'Visual' })

      local dap_icons = {
        Stopped = { '󰁕 ', 'DiagnosticWarn', 'DapStoppedLine' },
        Breakpoint = ' ',
        BreakpointCondition = ' ',
        BreakpointRejected = { ' ', 'DiagnosticError' },
        LogPoint = '.>',
      }

      for name, sign in pairs(dap_icons) do
        sign = type(sign) == 'table' and sign or { sign }
        vim.fn.sign_define('Dap' .. name, { text = sign[1], texthl = sign[2] or 'DiagnosticInfo', linehl = sign[3], numhl = sign[3] })
      end

      -- -- setup dap config by VsCode launch.json file
      -- local vscode = require 'dap.ext.vscode'
      -- local json = require 'plenary.json'
      -- vscode.json_decode = function(str)
      --   return vim.json.decode(json.json_strip_comments(str))
      -- end
      require('dap.ext.vscode').json_decode = require('json5').parse
    end,
  },

  -- fancy UI for the debugger
  {
    'rcarriga/nvim-dap-ui',
    dependencies = { 'nvim-neotest/nvim-nio' },
    -- stylua: ignore
    keys = {
      { "<leader>du", function() require("dapui").toggle({ }) end, desc = "Dap UI" },
      { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = {"n", "v"} },
    },
    opts = {},
    config = function(_, opts)
      local dap = require 'dap'
      local dapui = require 'dapui'
      dapui.setup(opts)
      dap.listeners.after.event_initialized['dapui_config'] = function()
        dapui.open {}
      end
      dap.listeners.before.event_terminated['dapui_config'] = function()
        dapui.close {}
      end
      dap.listeners.before.event_exited['dapui_config'] = function()
        dapui.close {}
      end
    end,
  },

  -- mason.nvim integration
  {
    'jay-babu/mason-nvim-dap.nvim',
    dependencies = 'mason.nvim',
    cmd = { 'DapInstall', 'DapUninstall' },
    opts = {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {
        function(config)
          -- all sources with no handler get passed here

          -- Keep original functionality
          require('mason-nvim-dap').default_setup(config)
        end,
        python = function(config)
          config.adapters = {
            type = 'executable',
            command = '/usr/bin/python3',
            args = {
              '-m',
              'debugpy.adapter',
            },
          }
          require('mason-nvim-dap').default_setup(config) -- don't forget this!
        end,
        cppdbg = function(config)
          -- Set the path to OpenDebugAD7 (the cpptools adapter)
          config.adapters = {
            type = 'executable',
            command = vim.fn.stdpath 'data' .. '/mason/packages/cpptools/extension/debugAdapters/bin/OpenDebugAD7',
            args = {},
          }

          -- Define the debugging configurations for cppdbg (C++ debugging with GDB/LLDB)
          config.configurations = {
            {
              name = 'Launch GDB Remote Debug Session',
              type = 'cppdbg', -- This should be cppdbg as it's the GDB/LLDB debugger adapter
              request = 'launch',

              -- Instead of local program, connect to remote gdbserver
              miDebuggerServerAddress = 'localhost:2345', -- Specify the gdbserver address
              miDebuggerPath = '/usr/bin/gdb',

              -- The program to launch remotely; replace with your program
              program = function()
                return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
              end,

              -- Working directory for the debugger to use
              cwd = '${workspaceFolder}',

              stopAtEntry = true,

              -- GDB Setup Commands
              setupCommands = {
                {
                  text = '-enable-pretty-printing',
                  description = 'Enable GDB pretty printing',
                  ignoreFailures = false,
                },
              },

              -- Optional: Additional GDB options
              launchCompleteCommand = 'exec-run', -- To make sure the GDB session connects and runs
              externalConsole = false, -- Set to true if you want to open a new terminal for output
              MIMode = 'gdb',
            },
          }

          -- Apply the configuration to mason-nvim-dap
          require('mason-nvim-dap').default_setup(config)
        end,
      },

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        'cppdbg',
        -- 'python',
        -- 'bash',
      },
    },
    -- mason-nvim-dap is loaded when nvim-dap loads
    config = function(_, opts)
      require('mason-nvim-dap').setup(opts)
    end,
  },
}
