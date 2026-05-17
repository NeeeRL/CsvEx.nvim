# CsvEx.nvim

## how to use in lazynvim(dev)

```
return {
  dir = "~/tekito/CsvEx.nvim/",
  name = "csvex",
  ft = "csv", -- CSVファイルを開いた時だけ遅延ロード
  opts = {
    initial_mode = "normal",
    -- insert_enter_to_save = true,
    bar_position = "bottom",

    highlights = {
      CsvexSeparator = { fg = "#f5c2e7", bold = true }, -- つながる縦線
      CsvexBorder = { fg = "#f5c2e7", bold = true }, -- 上下のフタ
      CsvexFormulaBar = { bg = "#1e1e2e", fg = "#cdd6f4" }, -- 数式バーの中身
    },
  },
}

```

## opts_default
```
  -- insert or normal
  initial_mode = "normal",

  -- true or false
  insert_enter_to_save = false,

  -- bottom or top
  bar_position = "bottom",
```

