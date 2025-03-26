# zstd-ffi

* Compress and decompress files

```lua
compressor = require("zstd.compressor").new()
compressor:compress_file("file")

-- with compress level and dictionary
compressor = require("zstd.compressor").new({ clevel = 10, dictionary = "dictionary" })
compressor:compress_file("file")

decompressor = require("zstd.decompressor").new()
decompressor:decompress_file("file.zst")

-- with dictionary
decompressor = require("zstd.decompressor").new({ dictionary = "dictionary" })
decompressor:decompress_file("file.zst")
```
