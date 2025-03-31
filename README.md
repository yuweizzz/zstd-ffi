# zstd-ffi

* Compress and decompress files

```lua
file_path_to_compress = "file_path_to_compress"
file_path_to_decompress = "file_path_to_decompress"  -- normally named like "file.zst"
dictionary_file_path = "dictionary_file_path"

-- compress file
compressor = require("zstd.compressor").new()
compressor:compress_file(file_path_to_compress)

-- decompress file
decompressor = require("zstd.decompressor").new()
decompressor:decompress_file(file_path_to_decompress)

-- compress with compress level and dictionary
dict = io.open(dictionary_file_path, "rb")
dict_data = dict:read("*a")
dict:close()
compressor = require("zstd.compressor").new({ clevel = 10, dictionary = dict_data })
compressor:compress_file(file_path_to_compress)

-- use raw dictionary, make sure the used dictionary without zstd dictionary id and magic number
compressor = require("zstd.compressor").new({ clevel = 10, dictionary = dict_data, use_raw = true })
compressor:compress_file(file_path_to_compress)
```

* Compressing Response

```lua
location / {
    header_filter_by_lua_block {
        local accept_zstd
        if ngx.var.http_content_encoding then
            return
        end

        local accept_encoding = ngx.var.http_accept_encoding
        if accept_encoding and string.find(accept_encoding, "zstd") then
            accept_zstd = true
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

todo: use `ZSTDLIB_API` to instead of `options.use_raw`.
