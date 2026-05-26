# CsvEx.nvim

A lightweight, powerful CSV viewer and editor for Neovim, designed to bring a spreadsheet-like experience to your favorite text editor.

## Features

- **Grid Visualization**: High-quality visual grid with customizable borders and separators.
- **Formula Bar Editing**: Edit cell contents in a dedicated floating window (formula bar), keeping the main grid clean and readable.
- **Smart Navigation**: Natural cell-to-cell movement using standard Vim keys (`h`, `j`, `k`, `l`).
- **Dynamic Formatting**: Automatically adjusts column widths and aligns cells for optimal readability.
- **Row & Column Management**: Effortlessly insert or delete rows and columns directly from the grid.
- **Header Awareness**: Displays current cell index and column header in the winbar.
- **Pure Data Format**: Saves CSV files in a clean, standard format without extra padding or artifacts.

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "NeeeRL/CsvEx.nvim",
  ft = "csv",
  opts = {
    -- Configuration options here (see below)
    initial_mode = "normal", 
    auto_attach = true,
  },
  config = function(_, opts)
    require("csvex").setup(opts)
  end,
}
```

## Default Keymaps

When attached to a CSV buffer, CsvEx provides the following intuitive keybindings:

| Key | Action |
| --- | --- |
| `h` / `b` | Move to previous cell |
| `l` / `w` / `e` | Move to next cell |
| `j` | Move to cell below |
| `k` | Move to cell above |
| `0` / `^` | Move to first cell in row |
| `$` | Move to last cell in row |
| `gg` | Move to top-left cell |
| `G` | Move to bottom-left cell |
| `i` / `a` / `I` / `A` / `<CR>` | Edit current cell (opens formula bar) |
| `c` | Change current cell (clears and enters edit mode) |
| `x` | Clear current cell |
| `o` | Insert row below |
| `O` | Insert row above |
| `ic` | Insert column to the right |
| `iC` | Insert column to the left |
| `dc` | Delete current column |

### Formula Bar (Floating Window)
- `<CR>`: Save and close.
- `q`: Close without saving (or if unchanged).

## Configuration

| Option | Default | Description |
| --- | --- | --- |
| `initial_mode` | `"normal"` | Initial mode in the formula bar (`"normal"` or `"insert"`). |
| `insert_enter_to_save` | `false` | If `true`, pressing `<CR>` in insert mode saves the cell. |
| `bar_position` | `"bottom"` | Position of the formula bar (`"bottom"` or `"top"`). |
| `auto_attach` | `false` | Automatically attach CsvEx when opening a `.csv` file. |
| `enable_crosshair` | `false` | Enable crosshair (row and column highlights) at the current cell. |

### Appearance (Highlights)

You can customize the following highlight groups in your `opts`:

```lua
opts = {
  highlights = {
    CsvexSeparator = { fg = "#f5c2e7", bold = true },    -- Vertical lines
    CsvexBorder = { fg = "#f5c2e7", bold = true },       -- Horizontal borders
    CsvexFormulaBar = { bg = "#1e1e2e", fg = "#cdd6f4" }, -- Formula bar content
    CsvexCursorLine = { link = "CursorLine" },           -- Current line highlight
  },
}
```

## Commands

- `:CsvexAttach`: Manually attach CsvEx to the current buffer (must be a CSV file).

## Technical Notes

### Internal Representation
To facilitate grid rendering and navigation, CsvEx temporarily inserts two spaces into empty cells while the buffer is attached. These spaces are **automatically removed** when saving the file, ensuring your data remains clean and standard-compliant (Pure Data Format).

## Acknowledgments

- Inspired by [csvview.nvim](https://github.com/hat0uma/csvview.nvim).

---

Developed by [ken](https://github.com/NeeeRL)
