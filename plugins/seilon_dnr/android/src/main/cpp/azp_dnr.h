// android/src/main/cpp/azp_dnr.h
#ifndef AZP_H_
#define AZP_H_

#include "stdint.h"

typedef enum {
    errAZP_NoError = 0,           // No error
    errAZP_NotReady,              // Not ready
    errAZP_InvalidParam,          // Invalid parameter
    errAZP_InvalidLicense,        // Invalid license
    errAZP_BufferOverflow,        // Buffer overflow
    errAZP_BufferTooSmall,        // Buffer too small
} AZP_STATUS;

typedef struct {
    int8_t *buffer1;              // Pointer to the first buffer
    int8_t *buffer2;              // Pointer to the second buffer
    int32_t buffer1_size;         // Size of the first buffer
    int32_t buffer2_size;         // Size of the second buffer
    int32_t sample_rate;          // Sample rate
} azp_dnr_pram_t;

/// @brief DNR initialization
/// @param pram Configuration parameters
/// @return License status
AZP_STATUS AI_DNR_init(azp_dnr_pram_t *pram);

/// @brief DNR processing
/// @param audio Q31 input and output
/// @return License status
AZP_STATUS AI_DNR_Processing(int32_t *audio);

/// @brief Get version number
/// @return If not licensed, returns NULL
char *AI_DNR_Version();

/// @brief Get the size of the working buffers
/// @param buf_size Size of the first buffer
/// @param buf_size2 Size of the second buffer
void getBufferSize(int32_t *buf_size, int32_t *buf_size2);

/// @brief Set the noise reduction depth
/// @param dB Range (-200 to 0 dB)
/// -200: Maximum noise reduction
/// 0: No noise reduction
void setNoisy_mix_factor(float dB);

#endif // AZP_H_