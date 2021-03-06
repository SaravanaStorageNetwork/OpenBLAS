/***************************************************************************
Copyright (c) 2016, The OpenBLAS Project
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:
1. Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in
the documentation and/or other materials provided with the
distribution.
3. Neither the name of the OpenBLAS project nor the names of
its contributors may be used to endorse or promote products
derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A00 PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE OPENBLAS PROJECT OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*****************************************************************************/

#define ASSEMBLER
#include "common.h"

#define	M	x0
#define	N	x1
#define	BETA    d0
#define	LDC     x6
#define	C00	x7

#define	A01	x8
#define	A02	x9
#define	A03	x10
#define	A04	x11

#define beta0		d11
#define betaV0		v11.d[0]
#define I	x16

#define prfm_size 640
#define calc_size 128

/**************************************************************************************
* Macro definitions
**************************************************************************************/

.macro SAVE_REGS
	add	sp, sp, #-(11 * 16)
	stp	d8, d9, [sp, #(0 * 16)]
	stp	d10, d11, [sp, #(1 * 16)]
	stp	d12, d13, [sp, #(2 * 16)]
	stp	d14, d15, [sp, #(3 * 16)]
	stp	d16, d17, [sp, #(4 * 16)]
	stp	x18, x19, [sp, #(5 * 16)]
	stp	x20, x21, [sp, #(6 * 16)]
	stp	x22, x23, [sp, #(7 * 16)]
	stp	x24, x25, [sp, #(8 * 16)]
	stp	x26, x27, [sp, #(9 * 16)]
	str	x28, [sp, #(10 * 16)]
.endm

.macro RESTORE_REGS
	ldp	d8, d9, [sp, #(0 * 16)]
	ldp	d10, d11, [sp, #(1 * 16)]
	ldp	d12, d13, [sp, #(2 * 16)]
	ldp	d14, d15, [sp, #(3 * 16)]
	ldp	d16, d17, [sp, #(4 * 16)]
	ldp	x18, x19, [sp, #(5 * 16)]
	ldp	x20, x21, [sp, #(6 * 16)]
	ldp	x22, x23, [sp, #(7 * 16)]
	ldp	x24, x25, [sp, #(8 * 16)]
	ldp	x26, x27, [sp, #(9 * 16)]
	ldr	x28, [sp, #(10 * 16)]
	add	sp, sp, #(11*16)
.endm

/**************************************************************************************
* End of macro definitions
**************************************************************************************/

	PROLOGUE

	.align 5

	ldr LDC, [sp]
	SAVE_REGS

.Lgemm_beta_BEGIN:

	fmov beta0, BETA
	cmp  N, #0
	ble	.Lgemm_beta_L999

.Lgemm_beta_01:

	lsl LDC, LDC, #3

	.align 5
.Lgemm_beta_02:

	mov	A01, C00
	add     C00, C00, LDC
	asr	I, M, #4
	cmp     I, #0
	ble .Lgemm_beta_04
	add	A02, A01, #32
	add	A03, A02, #32
	add	A04, A03, #32

	.align 5
.Lgemm_beta_03:

	ldp	q0, q1, [A01]
	ldp	q2, q3, [A02]
	ldp	q4, q5, [A03]
	ldp	q6, q7, [A04]
 
	fmul v0.2d, v0.2d, betaV0
	fmul v1.2d, v1.2d, betaV0

	fmul v2.2d, v2.2d, betaV0
	fmul v3.2d, v3.2d, betaV0

	prfm    PLDL1KEEP, [A01, prfm_size]

	fmul v4.2d, v4.2d, betaV0
	fmul v5.2d, v5.2d, betaV0

	prfm    PLDL1KEEP, [A03, prfm_size]

	fmul v6.2d, v6.2d, betaV0
	fmul v7.2d, v7.2d, betaV0

	st1	{v0.2d, v1.2d}, [A01]
	add	A01, A01, calc_size
	st1	{v2.2d, v3.2d}, [A02]
	add	A02, A02, calc_size
	st1	{v4.2d, v5.2d}, [A03]
	add	A03, A03, calc_size
	st1	{v6.2d, v7.2d}, [A04]
	add	A04, A04, calc_size

	subs    I , I , #1
	bne	.Lgemm_beta_03

	.align 5
.Lgemm_beta_04:

	and	I, M , #15	// M%16
	cmp	I, #0
	ble	.Lgemm_beta_06

	.align 5
.Lgemm_beta_05:

	ldr	d12, [A01]
	fmul	d12, d12, beta0
	str	d12, [A01]
	add	A01, A01, #8

	subs	I , I , #1
	bne	.Lgemm_beta_05

	.align 5
.Lgemm_beta_06:

	subs	N , N, #1	// N--
	bne	.Lgemm_beta_02

	.align 5
.Lgemm_beta_L999:

	mov	x0, #0
	RESTORE_REGS
	ret

	EPILOGUE
