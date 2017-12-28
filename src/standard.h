/****************************************************************************
 *                                                                          *
 *                         GNAT COMPILER COMPONENTS                         *
 *                                                                          *
 *                             S T A N D A R D                              *
 *                                                                          *
 *                              C Header File                               *
 *                                                                          *
 *                       Copyright (C) 2015-2017, AdaCore                   *
 *                                                                          *
 * GNAT is free software;  you can  redistribute it  and/or modify it under *
 * terms of the  GNU General Public License as published  by the Free Soft- *
 * ware  Foundation;  either version 3,  or (at your option) any later ver- *
 * sion.  GNAT is distributed in the hope that it will be useful, but WITH- *
 * OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY *
 * or FITNESS FOR A PARTICULAR PURPOSE.                                     *
 *                                                                          *
 * As a special exception under Section 7 of GPL version 3, you are granted *
 * additional permissions described in the GCC Runtime Library Exception,   *
 * version 3.1, as published by the Free Software Foundation.               *
 *                                                                          *
 * In particular,  you can freely  distribute your programs  built with the *
 * GNAT Pro compiler, including any required library run-time units,  using *
 * any licensing terms  of your choosing.  See the AdaCore Software License *
 * for full details.                                                        *
 *                                                                          *
 * GNAT was originally developed  by the GNAT team at  New York University. *
 * Extensive contributions were provided by Ada Core Technologies Inc.      *
 *                                                                          *
 ****************************************************************************/

#ifndef STANDARD_H
#define STANDARD_H

#include <Arduino.h>

/* stdint.h is only guaranteed to be there starting with C99 */
#if __STDC_VERSION__ >= 199901L
#include <stdint.h>   /* for [u]int*_t */
#endif

#include <string.h>  /* for memcpy(), memcmp() */
#include <math.h>    /* for fabs*(), isfinite(), powl() and for Ada.Numerics */

#ifndef __USE_ISOC99
#define __USE_ISOC99 /* for enabling llabs() */
#endif
#include <stdlib.h>  /* for *abs(), malloc() */

#if __STDC_VERSION__ >= 199901L
#include <stdbool.h>

#define GNAT_INLINE inline
//typedef bool boolean;

#else

#define GNAT_INLINE
//typedef unsigned char boolean;

#ifndef false
#define false 0
#endif

#ifndef true
#define true 1
#endif
#endif

#ifdef INT8_MIN  /* stdint.h supported */
typedef uint8_t unsigned_8;
typedef uint16_t unsigned_16;
typedef uint32_t unsigned_32;
typedef uint64_t unsigned_64;

typedef int8_t integer_8;
typedef int16_t integer_16;
typedef int32_t integer_32;
typedef int64_t integer_64;

typedef intptr_t integer_ptr_t;
#else
typedef unsigned char unsigned_8;
typedef unsigned short unsigned_16;
typedef unsigned unsigned_32;
typedef unsigned long long unsigned_64;

typedef signed char integer_8;
typedef short integer_16;
typedef int integer_32;
typedef long long integer_64;

typedef long integer_ptr_t;
#endif

typedef int integer;

typedef int natural;
typedef int positive;

typedef signed char short_short_integer;
typedef short short_integer;
typedef long long_integer;
typedef long long long_long_integer;
typedef long long universal_integer;

typedef float short_float;
typedef double long_float;
typedef long double long_long_float;
typedef long double universal_real;

typedef unsigned char character;
typedef unsigned_16 wide_character;
typedef unsigned_32 wide_wide_character;

typedef character *access_character;
typedef character *string;
typedef wide_character *wide_string;
typedef wide_wide_character *wide_wide_string;

typedef integer_32 duration;

typedef void *_void_ptr;
extern void __gnat_last_chance_handler (const _void_ptr msg, integer line);
//extern void __gnat_last_chance_handler_impl(const _void_ptr msg, const char* file, const char* func, int line);
//#define __gnat_last_chance_handler(msg, line) __gnat_last_chance_handler_impl(msg, __FILE__, __func__, __LINE__)

/* Fat pointer of unidimensional unconstrained arrays */
typedef struct {
  void *all;
  integer_ptr_t first;
  integer_ptr_t last;
} _fatptr_UNCarray;

static GNAT_INLINE _fatptr_UNCarray
_fatptr_UNCarray_CONS (void *all, integer_ptr_t first, integer_ptr_t last)
{
  _fatptr_UNCarray fatptr;
  fatptr.all   = all;
  fatptr.first = first;
  fatptr.last  = last;
  return fatptr;
}

#endif /* STANDARD_H */
