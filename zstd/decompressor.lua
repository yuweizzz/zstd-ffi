local ffi = require "ffi"

local ffi_new = ffi.new
local ffi_load = ffi.load
local ffi_str = ffi.string
local ffi_typeof = ffi.typeof
local table_insert = table.insert
local table_concat = table.concat
local string_sub = string.sub
local string_gsub = string.gsub

require "zstd.bindings"
local zstd = ffi_load("libzstd.so.1")

local _M = {
  _VERSION = "0.0.1",
}

local mt = { __index = _M }

local arr_type = ffi_typeof("uint8_t[?]")
local ptr_zstd_inbuffer_type = ffi_typeof("ZSTD_inBuffer[1]")
local ptr_zstd_outbuffer_type = ffi_typeof("ZSTD_outBuffer[1]")

local function init_stream()
  local stream = zstd.ZSTD_createDStream()
  if not stream then
    return nil, "run ZSTD_createDStream() failed"
  end
  local res = zstd.ZSTD_initDStream(stream);
  if zstd.ZSTD_isError(res) ~= 0 then
    return nil, "run ZSTD_initDStream() failed: " .. ffi_str(zstd.ZSTD_getErrorName(res))
  end
  return stream
end

local function _load_dictionary(stream, data, use_raw)
  -- Magic_Number: 0xEC30A437, little-endian format
  local magic = string.char(55, 164, 48, 236)
  local header = string_sub(data, 1, 4)

  if not use_raw and header ~= magic then
    return "require dictionary that matches Zstandard's specification"
  end

  if use_raw and header == magic then
    return "require raw dictionary, current dictionary starting with ZSTD_MAGIC_DICTIONARY"
  end

  local res = zstd.ZSTD_DCtx_loadDictionary(stream, data, #data)
  if zstd.ZSTD_isError(res) ~= 0 then
    return "run ZSTD_DCtx_loadDictionary() failed: " .. ffi_str(zstd.ZSTD_getErrorName(res))
  end
end

function _M.new(options)
  options = options or {}

  local stream, err = init_stream()
  if not stream then
    return nil, err
  end

  -- default use dictionary that matches Zstandard's specification
  options.use_raw = options.use_raw or false
  if options.dictionary then
    local err = _load_dictionary(stream, options.dictionary, options.use_raw)
    if err then
      return nil, err
    end
  end

  return setmetatable({
    stream = stream,
    dictionary = options.dictionary,
    use_raw = options.use_raw,
  }, mt), nil
end

function _M.version()
  return ffi_str(zstd.ZSTD_versionString())
end

function _M:free()
  local res = zstd.ZSTD_freeDStream(self.stream)
  if zstd.ZSTD_isError(res) ~= 0 then
    return "run ZSTD_freeDStream() failed: " .. ffi_str(zstd.ZSTD_getErrorName(res))
  end
  return nil
end

function _M:load_dictionary(data)
  local err = _load_dictionary(self.stream, data, self.use_raw)
  if err then
    return err
  end
  self.dictionary = data
end

function _M:unload_dictionary()
  local res = zstd.ZSTD_DCtx_loadDictionary(self.stream, nil, 0)
  if zstd.ZSTD_isError(res) ~= 0 then
    return "run ZSTD_DCtx_loadDictionary() failed: " .. ffi_str(zstd.ZSTD_getErrorName(res))
  end
  self.dictionary = nil
end

function _M:decompress(data_in)
  local buff_out_size = zstd.ZSTD_DStreamOutSize()
  local buff_out = ffi_new(arr_type, buff_out_size)
  local inbuffer = ffi_new(ptr_zstd_inbuffer_type)
  local outbuffer = ffi_new(ptr_zstd_outbuffer_type)

  local data_out = {}
  inbuffer[0] = { data_in, #data_in, 0 }
  while inbuffer[0].pos < inbuffer[0].size do
    outbuffer[0] = { buff_out, buff_out_size, 0 }
    local toread = zstd.ZSTD_decompressStream(self.stream, outbuffer, inbuffer)
    if zstd.ZSTD_isError(toread) ~= 0 then
      return nil, "run ZSTD_decompressStream() failed: " .. ffi_str(zstd.ZSTD_getErrorName(toread))
    end
    table_insert(data_out, ffi_str(buff_out, outbuffer[0].pos))
  end 
  return table_concat(data_out)  
end

function _M:decompress_file(file_i, file_o)
  local ok, file_in = pcall(io.open, file_i, "rb")
  if not ok then
    error("open file failed")
  end
  local ok, file_out = pcall(io.open, file_o or string_gsub(file_i, "%.zst", ""), "wb")
  if not ok then
    error("open file failed")
  end

  local buff_in_size = tonumber(zstd.ZSTD_DStreamInSize())
  local data_in = file_in:read(buff_in_size)
  while data_in do
    local data_out, err = self:decompress(data_in)
    if err then
      error(err)
    end
    file_out:write(data_out)
    data_in = file_in:read(buff_in_size)
  end

  file_out:close()
  file_in:close()
end

return _M
