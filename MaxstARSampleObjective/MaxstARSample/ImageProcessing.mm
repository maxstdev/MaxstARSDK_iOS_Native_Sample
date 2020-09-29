//
//  ImageProcessing.m
//  NeonObjective
//
//  Created by Kimseunglee on 2018. 1. 10..
//  Copyright © 2018년 Maxst. All rights reserved.
//

#import "ImageProcessing.h"
#include <arm_neon.h>
#import <Accelerate/Accelerate.h>

@implementation ImageProcessing

+ (void) timeCheck:(void (^)(void))block
{
    NSDate *methodStart = [NSDate date];
    block();
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    NSLog(@"executionTime = %f", executionTime);
}

+ (void) ImgUtil_ConvertBGRA888ToY8:(unsigned char*) pyaImg_Data_BGRA8888 Width:(int) piWidth Height:(int) piHeight dest:(unsigned char*) pyaImg_Data_Y8 {
    int tiStrideSrc = piWidth * 4;
    
    int tiR, tiG, tiB;
    int tiV;
    for(int y = 0; y < piHeight; y++)
    {
        for(int x = 0; x < piWidth; x++)
        {
            tiB = pyaImg_Data_BGRA8888[y * tiStrideSrc + x * 4 + 0];
            tiG = pyaImg_Data_BGRA8888[y * tiStrideSrc + x * 4 + 1];
            tiR = pyaImg_Data_BGRA8888[y * tiStrideSrc + x * 4 + 2];
            
            tiV = (77 * tiR + 150 * tiG + 29 * tiB) / 256;    //YUV color space
            
            pyaImg_Data_Y8[y * piWidth + x] = (unsigned char)tiV;
        }
    }
}

+ (void) neon_convert_bgra_to_grayscale:(uint8_t *) __restrict dest source:(uint8_t *) __restrict src pixelSize:(int) numPixels {
    int i;
    uint8x8_t rfac = vdup_n_u8 (77);
    uint8x8_t gfac = vdup_n_u8 (151);
    uint8x8_t bfac = vdup_n_u8 (28);
    int n = numPixels >> 3;

    // Convert per eight pixels
    for (i = 0; i < n; i++)
    {
        uint16x8_t  temp;
        uint8x8x4_t rgb  = vld4_u8 (src);
        uint8x8_t result;

        temp = vmull_u8 (rgb.val[0],      bfac);
        temp = vmlal_u8 (temp,rgb.val[1], gfac);
        temp = vmlal_u8 (temp,rgb.val[2], rfac);

        result = vshrn_n_u16 (temp, 8);
        vst1_u8 (dest, result);
        src  += 8 * 4;
        dest += 8;
    }
}

+ (void) ImgUtil_ConvertY8ToBGRA:(unsigned char*) pyaImg_Data_Y8 Width:(int) piWidth Height:(int) piHeight dest:(unsigned char*) pyaImg_Data_BGRA8888
{
    unsigned char* bgra = pyaImg_Data_BGRA8888;
    unsigned char* gray = pyaImg_Data_Y8;
    
    for(int i = 0; i < piWidth * piHeight; i++) {
        bgra[0] = gray[0];
        bgra[1] = gray[0];
        bgra[2] = gray[0];
        bgra[3] = 1;
        
        bgra += 4;
        gray += 1;
        
    }
}

+ (void) neon_convert_grayscale_to_bgra:(uint8_t *) __restrict dest source:(uint8_t *) __restrict src pixelSize:(int) numPixels {
    int i;
    int n = numPixels >> 3;
    uint8x8_t afac = vdup_n_u8 (1);

    // Convert per eight pixels
    for (i = 0; i < n; i++)
    {
        uint8x8x4_t rgba = vld4_u8 (dest);
        uint8x8_t grayscale = vld1_u8 (src);
        rgba.val[0] = grayscale;
        rgba.val[1] = grayscale;
        rgba.val[2] = grayscale;
        rgba.val[3] = afac;

        vst4_u8 (dest, rgba);
        dest += 8*4;
        src += 8;
    }
}

+ (void) gaussian_3x3:(int) width Height:(int) height Stride:(int) stride Source:(unsigned char *) src Dest:(unsigned char *) dst  {
    const int upLeft = -width - 1;
    const int up = -width;
    const int upRight = -width + 1;
    const int left = -1;
    const int right = 1;
    const int downLeft = width - 1;
    const int down = width;
    const int downRight = width + 1;
    
    for (int i = 1; i < height - 1; i++)
    {
        unsigned char *iSrc = src + i*stride + 1;
        unsigned char *iDst = dst + i*stride + 1;
        
        for (int j = 1; j < width - 1; j++)
        {
            iDst[0] = (
                       ((int)iSrc[0] << 2) +
                       ((int)iSrc[up] << 1) +
                       ((int)iSrc[left] << 1) +
                       ((int)iSrc[right] << 1) +
                       ((int)iSrc[down] << 1) +
                       (int)iSrc[downLeft] +
                       (int)iSrc[upLeft] +
                       (int)iSrc[upRight] +
                       (int)iSrc[downRight])
            >> 4;
            
            iSrc++;
            iDst++;
        }
    }
}

+ (void) boxblur:(int) width Height:(int) height Stride:(int) stride Source:(unsigned char *) src Dest:(unsigned char *) dst  {
    const int upLeft = -width - 1;
    const int up = -width;
    const int upRight = -width + 1;
    const int left = -1;
    const int right = 1;
    const int downLeft = width - 1;
    const int down = width;
    const int downRight = width + 1;
    
    for (int i = 1; i < height - 1; i++)
    {
        unsigned char *iSrc = src + i*stride + 1;
        unsigned char *iDst = dst + i*stride + 1;
        
        for (int j = 1; j < width - 1; j++)
        {
            iDst[0] = (
                       ((int)iSrc[0] * 1) +
                       ((int)iSrc[up] * 1) +
                       ((int)iSrc[left] * 1) +
                       ((int)iSrc[right] * 1) +
                       ((int)iSrc[down] * 1) +
                       (int)iSrc[downLeft] * 1 +
                       (int)iSrc[upLeft] * 1 +
                       (int)iSrc[upRight] * 1 +
                       (int)iSrc[downRight] * 1 )
            / 9;
            
            iSrc++;
            iDst++;
        }
    }
}

+ (void) edgeDection1:(int) width Height:(int) height Stride:(int) stride Source:(unsigned char *) src Dest:(unsigned char *) dst  {
    const int upLeft = -width - 1;
    const int up = -width;
    const int upRight = -width + 1;
    const int left = -1;
    const int right = 1;
    const int downLeft = width - 1;
    const int down = width;
    const int downRight = width + 1;
    
    for (int i = 1; i < height - 1; i++)
    {
        unsigned char *iSrc = src + i*stride + 1;
        unsigned char *iDst = dst + i*stride + 1;
        
        for (int j = 1; j < width - 1; j++)
        {
            int temp =
            (((int)iSrc[0] * 0) +
             ((int)iSrc[up] * 0) +
             ((int)iSrc[left] * 0) +
             ((int)iSrc[right] * 0) +
             ((int)iSrc[down] * 0) +
             ((int)iSrc[upLeft] * 1) +
             ((int)iSrc[upRight] * -1) +
             ((int)iSrc[downLeft] * -1) +
             ((int)iSrc[downRight] * 1) );
            
            if (temp < 0) {
                temp = 0;
            } else if (temp > 255) {
                temp = 255;
            }
            
            iDst[0] = temp;
            
            iSrc++;
            iDst++;
        }
    }
}

+ (void) edgeDection2:(int) width Height:(int) height Stride:(int) stride Source:(unsigned char *) src Dest:(unsigned char *) dst  {
    const int upLeft = -width - 1;
    const int up = -width;
    const int upRight = -width + 1;
    const int left = -1;
    const int right = 1;
    const int downLeft = width - 1;
    const int down = width;
    const int downRight = width + 1;
    
    for (int i = 1; i < height - 1; i++)
    {
        unsigned char *iSrc = src + i*stride + 1;
        unsigned char *iDst = dst + i*stride + 1;
        
        for (int j = 1; j < width - 1; j++)
        {
            int temp =
            (((int)iSrc[0] * -4) +
             ((int)iSrc[up] * 1) +
             ((int)iSrc[left] * 1) +
             ((int)iSrc[right] * 1) +
             ((int)iSrc[down] * 1) +
             ((int)iSrc[upLeft] * 0) +
             ((int)iSrc[upRight] * 0) +
             ((int)iSrc[downLeft] * 0) +
             ((int)iSrc[downRight] * 0) );
            
            if (temp < 0) {
                temp = 0;
            } else if (temp > 255) {
                temp = 255;
            }
            
            iDst[0] = temp;
            
            iSrc++;
            iDst++;
        }
    }
}

+ (void) edgeDection3:(int) width Height:(int) height Stride:(int) stride Source:(unsigned char *) src Dest:(unsigned char *) dst  {
    const int upLeft = -width - 1;
    const int up = -width;
    const int upRight = -width + 1;
    const int left = -1;
    const int right = 1;
    const int downLeft = width - 1;
    const int down = width;
    const int downRight = width + 1;
    
    for (int i = 1; i < height - 1; i++)
    {
        unsigned char *iSrc = src + i*stride + 1;
        unsigned char *iDst = dst + i*stride + 1;
        
        for (int j = 1; j < width - 1; j++)
        {
            int temp = (
                        ((int)iSrc[0] * 8) +
                        ((int)iSrc[up] * -1) +
                        ((int)iSrc[left] * -1) +
                        ((int)iSrc[right] * -1) +
                        ((int)iSrc[down] * -1) +
                        (int)iSrc[downLeft] * -1 +
                        (int)iSrc[upLeft] * -1 +
                        (int)iSrc[upRight] * -1 +
                        (int)iSrc[downRight] * -1 );
            
            if (temp < 0) {
                temp = 0;
            } else if (temp > 255) {
                temp = 255;
            }
            
            iDst[0] = temp;
            
            iSrc++;
            iDst++;
        }
    }
}

+ (void) sharpen:(int) width Height:(int) height Stride:(int) stride Source:(unsigned char *) src Dest:(unsigned char *) dst  {
    const int upLeft = -width - 1;
    const int up = -width;
    const int upRight = -width + 1;
    const int left = -1;
    const int right = 1;
    const int downLeft = width - 1;
    const int down = width;
    const int downRight = width + 1;
    
    for (int i = 1; i < height - 1; i++)
    {
        unsigned char *iSrc = src + i*stride + 1;
        unsigned char *iDst = dst + i*stride + 1;
        
        for (int j = 1; j < width - 1; j++)
        {
            int temp = (
                        ((int)iSrc[0] * 5) +
                        ((int)iSrc[up] * -1) +
                        ((int)iSrc[left] * -1) +
                        ((int)iSrc[right] * -1) +
                        ((int)iSrc[down] * -1) +
                        (int)iSrc[downLeft] * 0 +
                        (int)iSrc[upLeft] * 0 +
                        (int)iSrc[upRight] * 0 +
                        (int)iSrc[downRight] * 0 );
            
            if (temp < 0) {
                temp = 0;
            } else if (temp > 255) {
                temp = 255;
            }
            
            iDst[0] = temp;
            
            iSrc++;
            iDst++;
        }
    }
}

+ (void) neon_sharpen:(int) width Height:(int) height Stride:(int) stride Source:(unsigned char *) src Dest:(unsigned char *) dst {
    uint8x16_t cur_vec;
    uint16x8_t high_sum, low_sum;
    int8x16_t top = vdupq_n_s16(-1);
    uint8x16_t center = vdupq_n_u16(5);
    for (int i = 1; i < height - 1; i++)
    {
        unsigned char *isrc = src + i*stride + 1;
        unsigned char *idst = dst + i*stride + 1;
        for (int j = 1; j < width - 1; j += 16)
        {
            high_sum = vdupq_n_u16(0);
            low_sum = vdupq_n_u16(0);
            
            // top left
            //            cur_vec = vld1q_u8(isrc - stride - 1);
            //            high_sum = vaddq_u16(high_sum, vmovl_u8(vget_high_u8(cur_vec)));
            //            low_sum = vaddq_u16(low_sum, vmovl_u8(vget_low_u8(cur_vec)));
            
            // top
            cur_vec = vld1q_u8(isrc - stride);
            high_sum = vaddq_u16(high_sum, vmulq_u16(vmovl_u8(vget_high_u8(cur_vec)), top));
            low_sum = vaddq_u16(low_sum, vmulq_u16(vmovl_u8(vget_low_u8(cur_vec)), top));
            
            //            // top right
            //            cur_vec = vld1q_u8(isrc - stride + 1);
            //            high_sum = vaddq_u16(high_sum, vmovl_u8(vget_high_u8(cur_vec)));
            //            low_sum = vaddq_u16(low_sum, vmovl_u8(vget_low_u8(cur_vec)));
            
            // left
            cur_vec = vld1q_u8(isrc - 1);
            high_sum = vaddq_u16(high_sum, vmulq_u16(vmovl_u8(vget_high_u8(cur_vec)), top));
            low_sum = vaddq_u16(low_sum, vmulq_u16(vmovl_u8(vget_low_u8(cur_vec)), top));
            
            // center
            cur_vec = vld1q_u8(isrc);
            high_sum = vaddq_u16(high_sum, vmulq_u16(vmovl_u8(vget_high_u8(cur_vec)), center));
            low_sum = vaddq_u16(low_sum, vmulq_u16(vmovl_u8(vget_low_u8(cur_vec)), center));
            
            // right
            cur_vec = vld1q_u8(isrc + 1);
            high_sum = vaddq_u16(high_sum, vmulq_u16(vmovl_u8(vget_high_u8(cur_vec)), top));
            low_sum = vaddq_u16(low_sum, vmulq_u16(vmovl_u8(vget_low_u8(cur_vec)), top));
            
            //            // bottom left
            //            cur_vec = vld1q_u8(isrc + stride - 1);
            //            high_sum = vaddq_u16(high_sum, vmovl_u8(vget_high_u8(cur_vec)));
            //            low_sum = vaddq_u16(low_sum, vmovl_u8(vget_low_u8(cur_vec)));
            
            // bottom
            cur_vec = vld1q_u8(isrc + stride);
            high_sum = vaddq_u16(high_sum, vmulq_u16(vmovl_u8(vget_high_u8(cur_vec)), top));
            low_sum = vaddq_u16(low_sum, vmulq_u16(vmovl_u8(vget_low_u8(cur_vec)), top));
            
            //            // bottom right
            //            cur_vec = vld1q_u8(isrc + stride + 1);
            //            high_sum = vaddq_u16(high_sum, vmovl_u8(vget_high_u8(cur_vec)));
            //            low_sum = vaddq_u16(low_sum, vmovl_u8(vget_low_u8(cur_vec)));
            
            //            high_sum = vshrq_n_u16(high_sum, 4);
            //            low_sum = vshrq_n_u16(low_sum, 4);
            
            cur_vec = vcombine_u8(vmovn_u16(low_sum), vmovn_u16(high_sum));
            
            vst1q_u8(idst, cur_vec);
            
            isrc += 16;
            idst += 16;
        }
    }
}

+ (void) vImage_sharpen:(int) width Height:(int) height Stride:(int) stride Source:(unsigned char *) src Dest:(unsigned char *) dst {
    const int16_t kernel[] = {0, -1, 0, -1, 5, -1, 0, -1, 0}; // 1
    
    vImage_Buffer vImageSrc = { src, (vImagePixelCount)height, (vImagePixelCount)width, (size_t)width }; // 2
    vImage_Buffer vImageDest = { dst, vImageSrc.height, vImageSrc.width, vImageSrc.rowBytes }; // 3
    vImage_Error err;
    
    err = vImageConvolve_Planar8(&vImageSrc, &vImageDest, NULL, 0, 0, kernel, 3, 3, 0, 0, kvImageBackgroundColorFill);
}

+ (void) halfImage:(int) width Height:(int) height Stride:(int) stride DestStride:(int) destStride Source:(unsigned char *) src Dest:(unsigned char *) dst {
    int halfStride = destStride;
    int halfHeight = height >> 1;
    int halfWidth = width >> 1;
    for (int r = 0; r < halfHeight; r++)
    {
        unsigned char *pSrcRow = src + r * 2 * stride;
        unsigned char *pDstRow = dst + r*halfStride;
        for (int c = 0; c < halfWidth; c++)
        {
            pDstRow[0] = (unsigned char)(((int)pSrcRow[0] + pSrcRow[1] + pSrcRow[width] + pSrcRow[width + 1]) >> 2);
            pSrcRow += 2;
            pDstRow++;
        }
    }
}

+ (void) neon_halfImage:(int) width Height:(int) height Stride:(int) stride DestStride:(int) destStride Source:(unsigned char *) src Dest:(unsigned char *) dst {
    uint8x16_t currVec, nextVec;
    uint16x8_t sumVec = vdupq_n_u16(0);
    uint8x8_t convertedVec;
    
    // Load 16 bytes at once
    int sw = width >> 4;
    
    unsigned char * pSrc = src;
    unsigned char * pDst = dst;
    
    /* Image resize of 1/2 width and 1/2 height of original image.
     ** Final size is 1/4 of original image size. Right 1 shift means 1 / 2 */
    int sh = height >> 1;
    
    for (int i = 0; i < sh; i++)
    {
        for (int j = 0; j < sw; j++)
        {
            // 8bit * 16 pack ( 128 bit) loading : 1st row
            currVec = vld1q_u8((const uint8_t *)pSrc);
            
            // 8bit * 16 pack ( 128 bit ) loading : 2nd row
            nextVec = vld1q_u8((const uint8_t *)(pSrc + stride));
            
            // Add and shift right 1 bit ( divided by 2)
            currVec = vhaddq_u8(currVec, nextVec);  // vhadd -> Vr[i]:=(Va[i]+Vb[i])>>1, VHADD.U8 q0,q0,q0
            
            // Add next pack and unpack as 16 bit
            sumVec = vpaddlq_u8(currVec); // uint16x8_t vpaddlq_u8(uint8x16_t a);   // VPADDL.U8 q0,q0
            
            // shift right 1 bit ( divided by 2)
            sumVec = vshrq_n_u16(sumVec, 1); // uint16x8_t vshrq_n_u16(uint16x8_t a, __constrange(1,16) int b); // VSHR.U16 q0,q0,#16
            
            // pack to 8 bit data from 16 bit data
            convertedVec = vmovn_u16(sumVec); // uint8x8_t  vmovn_u16(uint16x8_t a);  // VMOVN.I16 d0,q0
            
            // Store to memory
            vst1_u8(pDst, convertedVec);
            
            pSrc += 16;
            pDst += 8;
        }
        
        // Skip next row
        pSrc = (src + stride * (i + 1) * 2);
        pDst = (dst + (stride / 2) * (i + 1));
    }
}

+ (void) vImage_halfImage:(int) width Height:(int) height Stride:(int) stride DestStride:(int) destStride Source:(unsigned char *) src Dest:(unsigned char *) dst {
    vImage_Buffer vImageSrc = { src, (vImagePixelCount)height, (vImagePixelCount)width, (size_t)width }; // 2
    vImage_Buffer vImageDest = { dst, vImageSrc.height >> 1, vImageSrc.width >> 1, vImageSrc.rowBytes >> 1 }; // 3
    vImage_Error err;
    
    err = vImageScale_Planar8(&vImageSrc, &vImageDest, NULL, kvImageNoFlags);
}

+ (void) vImage_gaussian_3x3:(int) width Height:(int) height Stride:(int) stride Source:(unsigned char *) src Dest:(unsigned char *) dst {
    const int16_t kernel[] = {1, 2, 1, 2, 4, 2, 1, 2, 1}; // 1
    
    vImage_Buffer vImageSrc = { src, (vImagePixelCount)height, (vImagePixelCount)width, (size_t)width }; // 2
    vImage_Buffer vImageDest = { dst, vImageSrc.height, vImageSrc.width, vImageSrc.rowBytes }; // 3
    vImage_Error err;
    
    err = vImageConvolve_Planar8(&vImageSrc, &vImageDest, NULL, 0, 0, kernel, 3, 3, 16, 0, kvImageBackgroundColorFill);
}

+ (void) neon_gaussian_3x3:(int) width Height:(int) height Stride:(int) stride Source:(unsigned char *) src Dest:(unsigned char *) dst {
    uint8x16_t cur_vec;
    uint16x8_t high_sum, low_sum;
    for (int i = 1; i < height - 1; i++)
    {
        unsigned char *isrc = src + i*stride + 1;
        unsigned char *idst = dst + i*stride + 1;
        for (int j = 1; j < width - 1; j += 16)
        {
            high_sum = vdupq_n_u16(0);
            low_sum = vdupq_n_u16(0);
            
            // top left
            cur_vec = vld1q_u8(isrc - stride - 1);
            high_sum = vaddq_u16(high_sum, vmovl_u8(vget_high_u8(cur_vec)));
            low_sum = vaddq_u16(low_sum, vmovl_u8(vget_low_u8(cur_vec)));
            
            // top
            cur_vec = vld1q_u8(isrc - stride);
            high_sum = vaddq_u16(high_sum, vshlq_n_u16(vmovl_u8(vget_high_u8(cur_vec)), 1));
            low_sum = vaddq_u16(low_sum, vshlq_n_u16(vmovl_u8(vget_low_u8(cur_vec)), 1));
            
            // top right
            cur_vec = vld1q_u8(isrc - stride + 1);
            high_sum = vaddq_u16(high_sum, vmovl_u8(vget_high_u8(cur_vec)));
            low_sum = vaddq_u16(low_sum, vmovl_u8(vget_low_u8(cur_vec)));
            
            // left
            cur_vec = vld1q_u8(isrc - 1);
            high_sum = vaddq_u16(high_sum, vshlq_n_u16(vmovl_u8(vget_high_u8(cur_vec)), 1));
            low_sum = vaddq_u16(low_sum, vshlq_n_u16(vmovl_u8(vget_low_u8(cur_vec)), 1));
            
            // center
            cur_vec = vld1q_u8(isrc);
            high_sum = vaddq_u16(high_sum, vshlq_n_u16(vmovl_u8(vget_high_u8(cur_vec)), 2));
            low_sum = vaddq_u16(low_sum, vshlq_n_u16(vmovl_u8(vget_low_u8(cur_vec)), 2));
            
            // right
            cur_vec = vld1q_u8(isrc + 1);
            high_sum = vaddq_u16(high_sum, vshlq_n_u16(vmovl_u8(vget_high_u8(cur_vec)), 1));
            low_sum = vaddq_u16(low_sum, vshlq_n_u16(vmovl_u8(vget_low_u8(cur_vec)), 1));
            
            // bottom left
            cur_vec = vld1q_u8(isrc + stride - 1);
            high_sum = vaddq_u16(high_sum, vmovl_u8(vget_high_u8(cur_vec)));
            low_sum = vaddq_u16(low_sum, vmovl_u8(vget_low_u8(cur_vec)));
            
            // bottom
            cur_vec = vld1q_u8(isrc + stride);
            high_sum = vaddq_u16(high_sum, vshlq_n_u16(vmovl_u8(vget_high_u8(cur_vec)), 1));
            low_sum = vaddq_u16(low_sum, vshlq_n_u16(vmovl_u8(vget_low_u8(cur_vec)), 1));
            
            // bottom right
            cur_vec = vld1q_u8(isrc + stride + 1);
            high_sum = vaddq_u16(high_sum, vmovl_u8(vget_high_u8(cur_vec)));
            low_sum = vaddq_u16(low_sum, vmovl_u8(vget_low_u8(cur_vec)));
            
            high_sum = vshrq_n_u16(high_sum, 4);
            low_sum = vshrq_n_u16(low_sum, 4);
            
            cur_vec = vcombine_u8(vmovn_u16(low_sum), vmovn_u16(high_sum));
            
            vst1q_u8(idst, cur_vec);
            
            isrc += 16;
            idst += 16;
        }
    }
}
@end
