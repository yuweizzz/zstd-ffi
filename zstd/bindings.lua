local ffi = require("ffi")

local bindings = ffi.cdef [[
typedef struct ZSTD_inBuffer_s {
  const void* src;
  size_t size;
  size_t pos;
} ZSTD_inBuffer;

typedef struct ZSTD_outBuffer_s {
  void*  dst;
  size_t size;
  size_t pos;
} ZSTD_outBuffer;

typedef struct ZSTD_CCtx_s ZSTD_CCtx;
typedef ZSTD_CCtx ZSTD_CStream;
ZSTD_CStream* ZSTD_createCStream(void);
size_t ZSTD_initCStream(ZSTD_CStream* zcs, int compressionLevel);
size_t ZSTD_freeCStream(ZSTD_CStream* zcs);
size_t ZSTD_CStreamInSize(void);
size_t ZSTD_CStreamOutSize(void);
size_t ZSTD_compressStream(ZSTD_CStream* zcs, ZSTD_outBuffer* output, ZSTD_inBuffer* input);
size_t ZSTD_endStream(ZSTD_CStream* zcs, ZSTD_outBuffer* output);

typedef struct ZSTD_DCtx_s ZSTD_DCtx;
typedef ZSTD_DCtx ZSTD_DStream;
ZSTD_DStream* ZSTD_createDStream(void);
size_t ZSTD_initDStream(ZSTD_DStream* zds);
size_t ZSTD_freeDStream(ZSTD_DStream* zds);
size_t ZSTD_DStreamInSize(void); 
size_t ZSTD_DStreamOutSize(void);
size_t ZSTD_decompressStream(ZSTD_DStream* zds, ZSTD_outBuffer* output, ZSTD_inBuffer* input);

const char* ZSTD_versionString(void);
unsigned ZSTD_isError(size_t result);
const char* ZSTD_getErrorName(size_t result);
int ZSTD_maxCLevel(void);
int ZSTD_defaultCLevel(void);
]]

return bindings
