return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          -- always show dotfiles and gitignored files (gitignored ones are
          -- dimmed via the SnacksPickerPathIgnored highlight)
          explorer = { hidden = true, ignored = true },
        },
      },
    },
  },
}
