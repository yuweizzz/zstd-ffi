# zstd-ffi

FFI-based facebook [Zstandard](https://github.com/facebook/zstd) binding for LuaJIT.

Table of Contents
=================

- [Installation](#installation)
- [Methods](#methods)
  - [zstd.compressor.new](#zstd-compressor-new)
  - [zstd.compressor.version](#zstd-compressor-version)
  - [zstd.compressor:free](#zstd-compressor-free)
  - [zstd.compressor:load_dictionary](#zstd-compressor-load_dictionary)
  - [zstd.compressor:unload_dictionary](#zstd-compressor-unload_dictionary)
  - [zstd.compressor:compress](#zstd-compressor-compress)
  - [zstd.compressor:end_stream](#zstd-compressor-end_stream)
  - [zstd.compressor:compress_file](#zstd-compressor-compress_file)
  - [zstd.decompressor.new](#zstd-decompressor-new)
  - [zstd.decompressor.version](#zstd-decompressor-version)
  - [zstd.decompressor:free](#zstd-decompressor-free)
  - [zstd.decompressor:load_dictionary](#zstd-decompressor-load_dictionary)
  - [zstd.decompressor:unload_dictionary](#zstd-decompressor-unload_dictionary)
  - [zstd.decompressor:decompress](#zstd-decompressor-decompress)
  - [zstd.decompressor:decompress_file](#zstd-decompressor-decompress_file)
- [Example](#example)
  - [Compress and decompress files](#compress-and-decompress-files)
  - [Compress http response](#compress-http-response)
- [Reference](#reference)
- [License](#license)

Installation
=================

Require Zstandard version above v1.5.0, to install Zstandard shared libraries, please check [here](https://github.com/facebook/zstd?tab=readme-ov-file#build-instructions).

To install this project, placing zstd/*.lua to your lua library path.

Methods
=================

### zstd.compressor.new

**syntax**: *compressor, err = zstd.compressor.new(opts?)*

The parameter `opts` accepts an optional table to constraint the behaviour of compressor.

- `opts.clevel`: set compression level, acceptable values are in the range from 1 to ZSTD_maxCLevel(22), defaults to ZSTD_defaultCLevel(3).
- `opts.dictionary`: set dictionary use to compress.
- `opts.use_raw`: set the flag to check if the dictionary matches Zstandard's specification. `false` will use the dictionary matches Zstandard's specification ONLY, `true` will use the dictionary doesn't match Zstandard's specification ONLY.

[Back to TOC](#table-of-contents)

### zstd.compressor.version

**syntax**: *version = zstd.compressor.version()*

Return the version of Zstandard shared lib.

[Back to TOC](#table-of-contents)

### zstd.compressor:free

**syntax**: *err = zstd.compressor:free()*

Free the internal stream object.

[Back to TOC](#table-of-contents)

### zstd.compressor:load_dictionary

**syntax**: *err = zstd.compressor:load_dictionary(data)*

Set a new dictionary for the compressor, the exist `use_raw` options still take effect in new dictionary. 

[Back to TOC](#table-of-contents)

### zstd.compressor:unload_dictionary

**syntax**: *err = zstd.compressor:unload_dictionary()*

Unload the compressor's dictionary.

[Back to TOC](#table-of-contents)

### zstd.compressor:compress

**syntax**: *output, err = zstd.compressor:compress(input)*

Compresses the input data into the output data.

[Back to TOC](#table-of-contents)

### zstd.compressor:end_stream

**syntax**: *output, err = zstd.compressor:end_stream()*

Pass the ZSTD_e_end flag to the internal stream.

[Back to TOC](#table-of-contents)

### zstd.compressor:compress_file

**syntax**: *err = zstd.compressor:compress_file(file)*

Compress the file and save it into a new file named with the zst suffix.

[Back to TOC](#table-of-contents)

### zstd.decompressor.new

**syntax**: *decompressor, err = zstd.decompressor.new(opts?)*

The parameter `opts` accepts an optional table to constraint the behaviour of decompressor.

- `opts.dictionary`: set dictionary use to compress.
- `opts.use_raw`: set the flag to check if the dictionary matches Zstandard's specification. `false` will use the dictionary matches Zstandard's specification ONLY, `true` will use the dictionary doesn't match Zstandard's specification ONLY.

[Back to TOC](#table-of-contents)

### zstd.decompressor.version

**syntax**: *version = zstd.decompressor.version()*

Return the version of Zstandard shared lib.

[Back to TOC](#table-of-contents)

### zstd.decompressor:free

**syntax**: *err = zstd.decompressor:free()*

Free the internal stream object.

[Back to TOC](#table-of-contents)

### zstd.decompressor:load_dictionary

**syntax**: *err = zstd.decompressor:load_dictionary(data)*

Set a new dictionary for the decompressor, the exist `use_raw` options still take effect in new dictionary. 

[Back to TOC](#table-of-contents)

### zstd.decompressor:unload_dictionary

**syntax**: *err = zstd.decompressor:unload_dictionary()*

Unload the decompressor's dictionary.

[Back to TOC](#table-of-contents)

### zstd.decompressor:decompress

**syntax**: *output, err = zstd.decompressor:decompress(input)*

Decompresses the input data into the output data.

[Back to TOC](#table-of-contents)

### zstd.decompressor:decompress_file

**syntax**: *err = zstd.decompressor:decompress_file(in_file, out_file?)*

Decompresses the file and saves it into a new file named as the parameter if the parameter is available; otherwise, it will try to name it with the original filename, removing the zst suffix.

[Back to TOC](#table-of-contents)

Example
=================

### Compress and decompress files

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

-- if the used dictionary does not match Zstandard's specification, pass the use_raw options
compressor = require("zstd.compressor").new({ clevel = 10, dictionary = dict_data, use_raw = true })
compressor:compress_file(file_path_to_compress)
```

[Back to TOC](#table-of-contents)

### Compress http response

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

[Back to TOC](#table-of-contents)

Reference
=================

- [zstd](https://github.com/facebook/zstd/blob/dev/lib/zstd.h)
- [zstd streaming compression](https://github.com/facebook/zstd/blob/dev/examples/streaming_compression.c)
- [luajit-zstd](https://github.com/sjnam/luajit-zstd)

[Back to TOC](#table-of-contents)

LICENSE
=================

[GPL-3.0 license](https://github.com/yuweizzz/zstd-ffi/blob/main/LICENSE)

[Back to TOC](#LICENSE)
