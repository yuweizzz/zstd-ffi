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

* Compressing Response

```lua
location / {
    header_filter_by_lua_block {
        local accept_zstd
        local encoding = ngx.var.http_content_encoding
        if encoding then
            accept_zstd = false
            return
        end
        local accept_encoding = ngx.var.http_accept_encoding
        if accept_encoding then
            if string.find(accept_encoding, "zstd") then
                accept_zstd = true
            end
        end
        if accept_zstd then
            local compressor, err = require("zstd.compressor").new()
            if not err then
                ngx.header.content_length = nil
                ngx.header["Content-Encoding"] = "zstd"
                ngx.ctx.accept_zstd = accept_zstd
                ngx.ctx.compressor = compressor
            end
        end
    }

    body_filter_by_lua_block {
        if not ngx.ctx.accept_zstd then
            return
        end
        local chunk, eof = ngx.arg[1], ngx.arg[2]
        local compressor = ngx.ctx.compressor
        if type(chunk) == "string" and chunk ~= "" then
            local encode_chunk = compressor:compress(chunk)
            ngx.arg[1] = encode_chunk
        end

        if eof then
            local end_chunk = compressor:end_stream()
            ngx.arg[1] = ngx.arg[1] .. end_chunk
            compressor:free()
        end
    }
}
```
