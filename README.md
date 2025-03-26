# zstd-ffi

* Compress and decompress files

```lua
local compressor = require("zstd.compressor").new()
compressor:compress_file("file")

local decompressor = require("zstd.decompressor").new()
decompressor:decompress_file("file.zst")
```
