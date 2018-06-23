# NOTE: Assertions have been autogenerated by utils/update_mca_test_checks.py
# RUN: llvm-mca -mtriple=x86_64-unknown-unknown -mcpu=znver1 -instruction-tables < %s | FileCheck %s

emms

movd        %eax, %mm2
movd        (%rax), %mm2

movd        %mm0, %ecx
movd        %mm0, (%rax)

movq        %rax, %mm2
movq        (%rax), %mm2

movq        %mm0, %rcx
movq        %mm0, (%rax)

packsswb    %mm0, %mm2
packsswb    (%rax), %mm2

packssdw    %mm0, %mm2
packssdw    (%rax), %mm2

packuswb    %mm0, %mm2
packuswb    (%rax), %mm2

paddb       %mm0, %mm2
paddb       (%rax), %mm2

paddd       %mm0, %mm2
paddd       (%rax), %mm2

paddsb      %mm0, %mm2
paddsb      (%rax), %mm2

paddsw      %mm0, %mm2
paddsw      (%rax), %mm2

paddusb     %mm0, %mm2
paddusb     (%rax), %mm2

paddusw     %mm0, %mm2
paddusw     (%rax), %mm2

paddw       %mm0, %mm2
paddw       (%rax), %mm2

pand        %mm0, %mm2
pand        (%rax), %mm2

pandn       %mm0, %mm2
pandn       (%rax), %mm2

pcmpeqb     %mm0, %mm2
pcmpeqb     (%rax), %mm2

pcmpeqd     %mm0, %mm2
pcmpeqd     (%rax), %mm2

pcmpeqw     %mm0, %mm2
pcmpeqw     (%rax), %mm2

pcmpgtb     %mm0, %mm2
pcmpgtb     (%rax), %mm2

pcmpgtd     %mm0, %mm2
pcmpgtd     (%rax), %mm2

pcmpgtw     %mm0, %mm2
pcmpgtw     (%rax), %mm2

pmaddwd     %mm0, %mm2
pmaddwd     (%rax), %mm2

pmulhw      %mm0, %mm2
pmulhw      (%rax), %mm2

pmullw      %mm0, %mm2
pmullw      (%rax), %mm2

por         %mm0, %mm2
por         (%rax), %mm2

pslld       $1, %mm2
pslld       %mm0, %mm2
pslld       (%rax), %mm2

psllq       $1, %mm2
psllq       %mm0, %mm2
psllq       (%rax), %mm2

psllw       $1, %mm2
psllw       %mm0, %mm2
psllw       (%rax), %mm2

psrad       $1, %mm2
psrad       %mm0, %mm2
psrad       (%rax), %mm2

psraw       $1, %mm2
psraw       %mm0, %mm2
psraw       (%rax), %mm2

psrld       $1, %mm2
psrld       %mm0, %mm2
psrld       (%rax), %mm2

psrlq       $1, %mm2
psrlq       %mm0, %mm2
psrlq       (%rax), %mm2

psrlw       $1, %mm2
psrlw       %mm0, %mm2
psrlw       (%rax), %mm2

psubb       %mm0, %mm2
psubb       (%rax), %mm2

psubd       %mm0, %mm2
psubd       (%rax), %mm2

psubsb      %mm0, %mm2
psubsb      (%rax), %mm2

psubsw      %mm0, %mm2
psubsw      (%rax), %mm2

psubusb     %mm0, %mm2
psubusb     (%rax), %mm2

psubusw     %mm0, %mm2
psubusw     (%rax), %mm2

psubw       %mm0, %mm2
psubw       (%rax), %mm2

punpckhbw   %mm0, %mm2
punpckhbw   (%rax), %mm2

punpckhdq   %mm0, %mm2
punpckhdq   (%rax), %mm2

punpckhwd   %mm0, %mm2
punpckhwd   (%rax), %mm2

punpcklbw   %mm0, %mm2
punpcklbw   (%rax), %mm2

punpckldq   %mm0, %mm2
punpckldq   (%rax), %mm2

punpcklwd   %mm0, %mm2
punpcklwd   (%rax), %mm2

pxor        %mm0, %mm2
pxor        (%rax), %mm2

# CHECK:      Instruction Info:
# CHECK-NEXT: [1]: #uOps
# CHECK-NEXT: [2]: Latency
# CHECK-NEXT: [3]: RThroughput
# CHECK-NEXT: [4]: MayLoad
# CHECK-NEXT: [5]: MayStore
# CHECK-NEXT: [6]: HasSideEffects

# CHECK:      [1]    [2]    [3]    [4]    [5]    [6]    Instructions:
# CHECK-NEXT:  1      2     0.25    *      *      *     emms
# CHECK-NEXT:  1      3     1.00                        movd	%eax, %mm2
# CHECK-NEXT:  1      8     0.50    *                   movd	(%rax), %mm2
# CHECK-NEXT:  1      2     1.00                        movd	%mm0, %ecx
# CHECK-NEXT:  1      1     0.50           *      *     movd	%mm0, (%rax)
# CHECK-NEXT:  1      3     1.00                        movq	%rax, %mm2
# CHECK-NEXT:  1      8     0.50    *                   movq	(%rax), %mm2
# CHECK-NEXT:  1      2     1.00                        movq	%mm0, %rcx
# CHECK-NEXT:  1      1     0.50           *            movq	%mm0, (%rax)
# CHECK-NEXT:  1      1     0.50                        packsswb	%mm0, %mm2
# CHECK-NEXT:  1      1     0.50    *                   packsswb	(%rax), %mm2
# CHECK-NEXT:  1      1     0.50                        packssdw	%mm0, %mm2
# CHECK-NEXT:  1      1     0.50    *                   packssdw	(%rax), %mm2
# CHECK-NEXT:  1      1     0.50                        packuswb	%mm0, %mm2
# CHECK-NEXT:  1      1     0.50    *                   packuswb	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        paddb	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   paddb	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        paddd	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   paddd	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        paddsb	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   paddsb	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        paddsw	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   paddsw	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        paddusb	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   paddusb	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        paddusw	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   paddusw	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        paddw	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   paddw	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        pand	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   pand	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        pandn	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   pandn	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        pcmpeqb	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   pcmpeqb	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        pcmpeqd	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   pcmpeqd	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        pcmpeqw	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   pcmpeqw	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        pcmpgtb	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   pcmpgtb	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        pcmpgtd	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   pcmpgtd	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        pcmpgtw	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   pcmpgtw	(%rax), %mm2
# CHECK-NEXT:  1      4     1.00                        pmaddwd	%mm0, %mm2
# CHECK-NEXT:  1      11    1.00    *                   pmaddwd	(%rax), %mm2
# CHECK-NEXT:  1      4     1.00                        pmulhw	%mm0, %mm2
# CHECK-NEXT:  1      11    1.00    *                   pmulhw	(%rax), %mm2
# CHECK-NEXT:  1      4     1.00                        pmullw	%mm0, %mm2
# CHECK-NEXT:  1      11    1.00    *                   pmullw	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        por	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   por	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        pslld	$1, %mm2
# CHECK-NEXT:  1      1     0.25                        pslld	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   pslld	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        psllq	$1, %mm2
# CHECK-NEXT:  1      1     0.25                        psllq	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   psllq	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        psllw	$1, %mm2
# CHECK-NEXT:  1      1     0.25                        psllw	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   psllw	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        psrad	$1, %mm2
# CHECK-NEXT:  1      1     0.25                        psrad	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   psrad	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        psraw	$1, %mm2
# CHECK-NEXT:  1      1     0.25                        psraw	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   psraw	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        psrld	$1, %mm2
# CHECK-NEXT:  1      1     0.25                        psrld	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   psrld	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        psrlq	$1, %mm2
# CHECK-NEXT:  1      1     0.25                        psrlq	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   psrlq	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        psrlw	$1, %mm2
# CHECK-NEXT:  1      1     0.25                        psrlw	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   psrlw	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        psubb	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   psubb	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        psubd	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   psubd	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        psubsb	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   psubsb	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        psubsw	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   psubsw	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        psubusb	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   psubusb	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        psubusw	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   psubusw	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        psubw	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   psubw	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        punpckhbw	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   punpckhbw	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        punpckhdq	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   punpckhdq	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        punpckhwd	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   punpckhwd	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        punpcklbw	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   punpcklbw	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        punpckldq	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   punpckldq	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        punpcklwd	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   punpcklwd	(%rax), %mm2
# CHECK-NEXT:  1      1     0.25                        pxor	%mm0, %mm2
# CHECK-NEXT:  1      8     0.50    *                   pxor	(%rax), %mm2

# CHECK:      Resources:
# CHECK-NEXT: [0]   - ZnAGU0
# CHECK-NEXT: [1]   - ZnAGU1
# CHECK-NEXT: [2]   - ZnALU0
# CHECK-NEXT: [3]   - ZnALU1
# CHECK-NEXT: [4]   - ZnALU2
# CHECK-NEXT: [5]   - ZnALU3
# CHECK-NEXT: [6]   - ZnDivider
# CHECK-NEXT: [7]   - ZnFPU0
# CHECK-NEXT: [8]   - ZnFPU1
# CHECK-NEXT: [9]   - ZnFPU2
# CHECK-NEXT: [10]  - ZnFPU3
# CHECK-NEXT: [11]  - ZnMultiplier

# CHECK:      Resource pressure per iteration:
# CHECK-NEXT: [0]    [1]    [2]    [3]    [4]    [5]    [6]    [7]    [8]    [9]    [10]   [11]
# CHECK-NEXT: 24.00  24.00   -      -      -      -      -     27.25  24.25  28.25  21.25   -

# CHECK:      Resource pressure by instruction:
# CHECK-NEXT: [0]    [1]    [2]    [3]    [4]    [5]    [6]    [7]    [8]    [9]    [10]   [11]   Instructions:
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     emms
# CHECK-NEXT:  -      -      -      -      -      -      -      -      -     1.00    -      -     movd	%eax, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -      -      -      -      -      -     movd	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -      -      -     1.00    -      -     movd	%mm0, %ecx
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -      -      -      -      -      -     movd	%mm0, (%rax)
# CHECK-NEXT:  -      -      -      -      -      -      -      -      -     1.00    -      -     movq	%rax, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -      -      -      -      -      -     movq	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -      -      -     1.00    -      -     movq	%mm0, %rcx
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -      -      -      -      -      -     movq	%mm0, (%rax)
# CHECK-NEXT:  -      -      -      -      -      -      -      -     0.50   0.50    -      -     packsswb	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -      -     0.50   0.50    -      -     packsswb	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -      -     0.50   0.50    -      -     packssdw	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -      -     0.50   0.50    -      -     packssdw	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -      -     0.50   0.50    -      -     packuswb	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -      -     0.50   0.50    -      -     packuswb	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     paddb	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     paddb	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     paddd	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     paddd	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     paddsb	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     paddsb	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     paddsw	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     paddsw	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     paddusb	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     paddusb	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     paddusw	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     paddusw	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     paddw	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     paddw	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     pand	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     pand	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     pandn	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     pandn	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     pcmpeqb	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     pcmpeqb	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     pcmpeqd	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     pcmpeqd	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     pcmpeqw	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     pcmpeqw	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     pcmpgtb	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     pcmpgtb	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     pcmpgtd	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     pcmpgtd	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     pcmpgtw	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     pcmpgtw	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     1.00    -      -      -      -     pmaddwd	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     1.00    -      -      -      -     pmaddwd	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     1.00    -      -      -      -     pmulhw	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     1.00    -      -      -      -     pmulhw	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     1.00    -      -      -      -     pmullw	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     1.00    -      -      -      -     pmullw	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     por	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     por	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     pslld	$1, %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     pslld	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     pslld	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     psllq	$1, %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     psllq	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     psllq	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     psllw	$1, %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     psllw	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     psllw	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     psrad	$1, %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     psrad	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     psrad	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     psraw	$1, %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     psraw	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     psraw	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     psrld	$1, %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     psrld	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     psrld	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     psrlq	$1, %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     psrlq	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     psrlq	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     psrlw	$1, %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     psrlw	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     psrlw	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     psubb	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     psubb	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     psubd	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     psubd	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     psubsb	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     psubsb	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     psubsw	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     psubsw	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     psubusb	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     psubusb	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     psubusw	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     psubusw	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     psubw	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     psubw	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     punpckhbw	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     punpckhbw	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     punpckhdq	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     punpckhdq	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     punpckhwd	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     punpckhwd	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     punpcklbw	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     punpcklbw	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     punpckldq	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     punpckldq	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     punpcklwd	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     punpcklwd	(%rax), %mm2
# CHECK-NEXT:  -      -      -      -      -      -      -     0.25   0.25   0.25   0.25    -     pxor	%mm0, %mm2
# CHECK-NEXT: 0.50   0.50    -      -      -      -      -     0.25   0.25   0.25   0.25    -     pxor	(%rax), %mm2

