return {
  { import = "lazyvim.plugins.extras.lang.go" },
  -- lang.go's nvim-dap-go / neotest-golang specs only take effect once these
  -- are enabled (they're written as "optional" extensions of them)
  { import = "lazyvim.plugins.extras.dap.core" },
  { import = "lazyvim.plugins.extras.test.core" },
}
