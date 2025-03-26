local ffi = require "ffi"

local ffi_new = ffi.new
local ffi_load = ffi.load
local ffi_str = ffi.string
local ffi_typeof = ffi.typeof
local table_insert = table.insert
local table_concat = table.concat
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

function _M.new()
  local stream, err = init_stream()
  if not stream then
    return nil, err
  end

  return setmetatable({
    stream = stream,
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
  local file_in = io.open(file_i, "rb")
  local file_out = io.open(file_o or gsub(file_i, "%.zst", ""), "wb")

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
