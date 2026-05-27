# CsvEx.nvim

A lightweight, high-performance CSV viewer and editor for Neovim. CsvEx transforms your text editor into a powerful spreadsheet environment without sacrificing the "pure text" nature of your data.

![Neovim](https://img.shields.io/badge/Neovim-0.10.0+-blue.svg?style=for-the-badge&logo=neovim)
![License](https://img.shields.io/badge/license-MIT-green.svg?style=for-the-badge)

## Features

-   **Grid Visualization**: Beautifully rendered grid with customizable borders and separators using virtual text.
-   **Formula Bar**: Edit cell contents in a dedicated floating window, keeping the main grid clean and readable.
-   **Smart Navigation**: Move naturally between cells using standard Vim motions (`h`, `j`, `k`, `l`, `w`, `b`, etc.).
-   **Dynamic Formatting**: Automatic column width adjustment and cell alignment for optimal readability.
-   **Grid Management**: Effortlessly insert/delete rows and columns directly from the spreadsheet view.
-   **Context Awareness**: The winbar displays your current cell index and column header for easy orientation.
-   **Pure Data Format**: Your files remain standard CSVs. Padding and artifacts are only internal and are never saved to disk.

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "NeeeRL/CsvEx.nvim",
  ft = "csv",
  opts = {
    -- Your configuration here
    auto_attach = true,
  },
  config = function(_, opts)
    require("csvex").setup(opts)
  end,
}
```

## Configuration

CsvEx comes with sensible defaults. You can customize them in the `opts` table:

| Option | Default | Description |
| :--- | :--- | :--- |
| `auto_attach` | `false` | Automatically activate CsvEx when opening a `.csv` file. |
| `initial_mode` | `"normal"` | Initial mode in the formula bar (`"normal"` or `"insert"`). |
| `insert_enter_to_save` | `false` | Save and close the formula bar when pressing `<CR>` in insert mode. |
| `bar_position` | `"bottom"` | Position of the formula bar (`"bottom"` or `"top"`). |
| `enable_crosshair` | `false` | Highlight the current row and column (crosshair effect). |

### Customizing Highlights

You can customize the appearance by overriding the default highlight groups:

```lua
opts = {
  highlights = {
    CsvexSeparator = { link = "FloatBorder" },    -- Vertical lines
    CsvexBorder = { link = "FloatBorder" },       -- Horizontal borders
    CsvexFormulaBar = { link = "NormalFloat" },   -- Formula bar content
    CsvexCursorLine = { link = "CursorLine" },    -- Current cell highlight
  },
}
```

## Default Keymaps

When CsvEx is attached to a buffer, the following keymaps are active:

### Navigation
| Key | Action |
| :--- | :--- |
| `h` / `b` | Move to previous cell |
| `l` / `w` / `e` | Move to next cell |
| `j` | Move to cell below |
| `k` | Move to cell above |
| `0` / `^` | Move to first cell in row |
| `$` | Move to last cell in row |
| `gg` | Move to top-left cell |
| `G` | Move to bottom-left cell |

### Editing
| Key | Action |
| :--- | :--- |
| `i` / `a` / `I` / `A` / `<CR>` | Edit current cell (opens formula bar) |
| `c` | Change current cell (clears and enters formula bar) |
| `x` | Clear current cell content |

### Grid Operations
| Key | Action |
| :--- | :--- |
| `o` | Insert row below |
| `O` | Insert row above |
| `ic` | Insert column to the right |
| `iC` | Insert column to the left |
| `dc` | Delete current column |

### Formula Bar (Floating Window)
-   `<CR>`: Save changes and close window.
-   `q`: Close window without saving (or if unchanged).

## Commands

-   `:CsvexAttach`: Manually attach CsvEx to the current buffer (useful if `auto_attach = false`).

## Technical Notes: Pure Data Format

CsvEx is designed to be **non-destructive**. 

Internally, Neovim requires content to exist in a buffer for the cursor to move over it. CsvEx handles empty cells by temporarily injecting two spaces while the buffer is attached. 

**Crucially, these spaces are removed during the save process.** When you save a file (`:w`), CsvEx intercepts the write command and strips all internal padding, ensuring your CSV remains a standard-compliant, clean data file.

## Acknowledgments

- Inspired by [csvview.nvim](https://github.com/hat0uma/csvview.nvim).

---

Developed with by [ken](https://github.com/NeeeRL)
