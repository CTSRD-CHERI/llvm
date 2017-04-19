# RUN: llvm-mc -filetype=obj -triple mips-unknown-linux     -mcpu=mips1                              %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,BE,O32,NAN1985,MIPS1 %s
# RUN: llvm-mc -filetype=obj -triple mips-unknown-linux     -mcpu=mips2                              %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,BE,O32,NAN1985,MIPS2 %s
# RUN: llvm-mc -filetype=obj -triple mips-unknown-linux     -mcpu=mips3                              %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,BE,O32,NAN1985,MIPS3,32BITMODE %s
# RUN: llvm-mc -filetype=obj -triple mips-unknown-linux     -mcpu=mips4                              %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,BE,O32,NAN1985,MIPS4,32BITMODE %s
# RUN: llvm-mc -filetype=obj -triple mips-unknown-linux     -mcpu=mips5                              %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,BE,O32,NAN1985,MIPS5,32BITMODE %s
# RUN: llvm-mc -filetype=obj -triple mips-unknown-linux                                              %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,BE,O32,NAN1985,MIPS32R1 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux                                            %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,O32,NAN1985,MIPS32R1 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux                                            %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,O32,NAN1985,MIPS32R1 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux   -mcpu=mips32r2                           %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,O32,NAN1985,MIPS32R2 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux   -mcpu=mips32r3                           %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,O32,NAN1985,MIPS32R3 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux   -mcpu=mips32r5                           %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,O32,NAN1985,MIPS32R5 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux   -mcpu=mips32r2           -mattr=+nan2008 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,O32,NAN2008,MIPS32R2 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux   -mcpu=mips32r3           -mattr=+nan2008 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,O32,NAN2008,MIPS32R3 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux   -mcpu=mips32r5           -mattr=+nan2008 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,O32,NAN2008,MIPS32R5 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux   -mcpu=mips32r6                           %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,O32,NAN2008,MIPS32R6 %s
# RUN: llvm-mc -filetype=obj -triple mips64-unknown-linux   -mcpu=mips1    -mabi=o32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,BE,O32,NAN1985,MIPS1 %s
# RUN: llvm-mc -filetype=obj -triple mips64-unknown-linux   -mcpu=mips2    -mabi=o32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,BE,O32,NAN1985,MIPS2 %s
# RUN: llvm-mc -filetype=obj -triple mips64-unknown-linux   -mcpu=mips3    -mabi=o32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,BE,O32,NAN1985,MIPS3,32BITMODE %s
# RUN: llvm-mc -filetype=obj -triple mips64-unknown-linux   -mcpu=mips4    -mabi=o32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,BE,O32,NAN1985,MIPS4,32BITMODE %s
# RUN: llvm-mc -filetype=obj -triple mips64-unknown-linux   -mcpu=mips5    -mabi=o32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,BE,O32,NAN1985,MIPS5,32BITMODE %s
# RUN: llvm-mc -filetype=obj -triple mips64-unknown-linux                  -mabi=o32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,BE,O32,NAN1985,MIPS32R1 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux                -mabi=o32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,O32,NAN1985,MIPS32R1 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux                -mabi=o32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,O32,NAN1985,MIPS32R1 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux -mcpu=mips32r2 -mabi=o32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,O32,NAN1985,MIPS32R2 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux -mcpu=mips32r3 -mabi=o32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,O32,NAN1985,MIPS32R3 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux -mcpu=mips32r5 -mabi=o32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,O32,NAN1985,MIPS32R5 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux -mcpu=mips32r2 -mabi=o32 -mattr=+nan2008 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,O32,NAN2008,MIPS32R2 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux -mcpu=mips32r3 -mabi=o32 -mattr=+nan2008 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,O32,NAN2008,MIPS32R3 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux -mcpu=mips32r5 -mabi=o32 -mattr=+nan2008 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,O32,NAN2008,MIPS32R5 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux -mcpu=mips32r6 -mabi=o32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,O32,NAN2008,MIPS32R6 %s

# Default ABI for MIPS64 is N64 as opposed to GCC/GAS (N32)
# RUN: llvm-mc -filetype=obj -triple mips-unknown-linux     -mcpu=mips3    -mabi=n32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,BE,N32,NAN1985,MIPS3 %s
# RUN: llvm-mc -filetype=obj -triple mips-unknown-linux     -mcpu=mips4    -mabi=n32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,BE,N32,NAN1985,MIPS4 %s
# RUN: llvm-mc -filetype=obj -triple mips-unknown-linux     -mcpu=mips5    -mabi=n32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,BE,N32,NAN1985,MIPS5 %s
# RUN: llvm-mc -filetype=obj -triple mips-unknown-linux                    -mabi=n32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,BE,N32,NAN1985,MIPS64R1 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux                  -mabi=n32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,N32,NAN1985,MIPS64R1 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux   -mcpu=mips64r2 -mabi=n32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,N32,NAN1985,MIPS64R2 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux   -mcpu=mips64r3 -mabi=n32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,N32,NAN1985,MIPS64R3 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux   -mcpu=mips64r5 -mabi=n32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,N32,NAN1985,MIPS64R5 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux   -mcpu=mips64r2 -mabi=n32 -mattr=+nan2008 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,N32,NAN2008,MIPS64R2 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux   -mcpu=mips64r3 -mabi=n32 -mattr=+nan2008 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,N32,NAN2008,MIPS64R3 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux   -mcpu=mips64r5 -mabi=n32 -mattr=+nan2008 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,N32,NAN2008,MIPS64R5 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux   -mcpu=mips64r6 -mabi=n32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,N32,NAN2008,MIPS64R6 %s
# RUN: llvm-mc -filetype=obj -triple mips64-unknown-linux   -mcpu=mips3    -mabi=n32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,BE,N32,NAN1985,MIPS3 %s
# RUN: llvm-mc -filetype=obj -triple mips64-unknown-linux   -mcpu=mips4    -mabi=n32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,BE,N32,NAN1985,MIPS4 %s
# RUN: llvm-mc -filetype=obj -triple mips64-unknown-linux   -mcpu=mips5    -mabi=n32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,BE,N32,NAN1985,MIPS5 %s
# RUN: llvm-mc -filetype=obj -triple mips64-unknown-linux                  -mabi=n32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,BE,N32,NAN1985,MIPS64R1 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux                -mabi=n32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,N32,NAN1985,MIPS64R1 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux -mcpu=mips64r2 -mabi=n32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,N32,NAN1985,MIPS64R2 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux -mcpu=mips64r3 -mabi=n32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,N32,NAN1985,MIPS64R3 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux -mcpu=mips64r5 -mabi=n32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,N32,NAN1985,MIPS64R5 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux -mcpu=mips64r2 -mabi=n32 -mattr=+nan2008 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,N32,NAN2008,MIPS64R2 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux -mcpu=mips64r3 -mabi=n32 -mattr=+nan2008 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,N32,NAN2008,MIPS64R3 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux -mcpu=mips64r5 -mabi=n32 -mattr=+nan2008 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,N32,NAN2008,MIPS64R5 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux -mcpu=mips64r6 -mabi=n32                 %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF32,LE,N32,NAN2008,MIPS64R6 %s

# Default ABI for MIPS64 is N64 as opposed to GCC/GAS (N32)
# RUN: llvm-mc -filetype=obj -triple mips-unknown-linux     -mcpu=mips3    -mabi=n64                 -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,BE,N64,NAN1985,MIPS3    %s
# RUN: llvm-mc -filetype=obj -triple mips-unknown-linux     -mcpu=mips4    -mabi=n64                 -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,BE,N64,NAN1985,MIPS4    %s
# RUN: llvm-mc -filetype=obj -triple mips-unknown-linux     -mcpu=mips5    -mabi=n64                 -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,BE,N64,NAN1985,MIPS5    %s
# RUN: llvm-mc -filetype=obj -triple mips-unknown-linux                    -mabi=n64                 -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,BE,N64,NAN1985,MIPS64R1 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux                  -mabi=n64                 -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,LE,N64,NAN1985,MIPS64R1 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux   -mcpu=mips64r2 -mabi=n64                 -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,LE,N64,NAN1985,MIPS64R2 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux   -mcpu=mips64r3 -mabi=n64                 -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,LE,N64,NAN1985,MIPS64R3 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux   -mcpu=mips64r5 -mabi=n64                 -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,LE,N64,NAN1985,MIPS64R5 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux   -mcpu=mips64r2 -mabi=n64 -mattr=+nan2008 -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,LE,N64,NAN2008,MIPS64R2 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux   -mcpu=mips64r3 -mabi=n64 -mattr=+nan2008 -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,LE,N64,NAN2008,MIPS64R3 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux   -mcpu=mips64r5 -mabi=n64 -mattr=+nan2008 -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,LE,N64,NAN2008,MIPS64R5 %s
# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux   -mcpu=mips64r6 -mabi=n64                 -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,LE,N64,NAN2008,MIPS64R6 %s
# RUN: llvm-mc -filetype=obj -triple mips64-unknown-linux   -mcpu=mips3    -mabi=n64                 -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,BE,N64,NAN1985,MIPS3    %s
# RUN: llvm-mc -filetype=obj -triple mips64-unknown-linux   -mcpu=mips4    -mabi=n64                 -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,BE,N64,NAN1985,MIPS4    %s
# RUN: llvm-mc -filetype=obj -triple mips64-unknown-linux   -mcpu=mips5    -mabi=n64                 -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,BE,N64,NAN1985,MIPS5    %s
# RUN: llvm-mc -filetype=obj -triple mips64-unknown-linux                                            -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,BE,N64,NAN1985,MIPS64R1 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux                                          -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,LE,N64,NAN1985,MIPS64R1 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux -mcpu=mips64r2                           -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,LE,N64,NAN1985,MIPS64R2 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux -mcpu=mips64r3                           -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,LE,N64,NAN1985,MIPS64R3 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux -mcpu=mips64r5                           -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,LE,N64,NAN1985,MIPS64R5 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux -mcpu=mips64r2           -mattr=+nan2008 -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,LE,N64,NAN2008,MIPS64R2 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux -mcpu=mips64r3           -mattr=+nan2008 -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,LE,N64,NAN2008,MIPS64R3 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux -mcpu=mips64r5           -mattr=+nan2008 -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,LE,N64,NAN2008,MIPS64R5 %s
# RUN: llvm-mc -filetype=obj -triple mips64el-unknown-linux -mcpu=mips64r6                           -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,LE,N64,NAN2008,MIPS64R6 %s

# RUN: llvm-mc -filetype=obj -triple mipsel-unknown-linux   -mcpu=octeon   -mabi=n64                 -position-independent %s -o - | llvm-readobj -h | FileCheck --check-prefixes=ALL,ELF64,LE,N64,NAN1985,OCTEON   %s

# ALL:        ElfHeader {
# ALL-NEXT:     Ident {
# ALL-NEXT:       Magic: (7F 45 4C 46)
# ELF32-NEXT:     Class: 32-bit (0x1)
# ELF64-NEXT:     Class: 64-bit (0x2)
# LE-NEXT:        DataEncoding: LittleEndian (0x1)
# BE-NEXT:        DataEncoding: BigEndian (0x2)
# ALL-NEXT:       FileVersion: 1
# ALL-NEXT:       OS/ABI: SystemV (0x0)
# ALL-NEXT:       ABIVersion: 0
# ALL-NEXT:       Unused: (00 00 00 00 00 00 00)
# ALL-NEXT:     }
# ALL-NEXT:     Type: Relocatable (0x1)
# ALL-NEXT:     Machine: EM_MIPS (0x8)
# ALL-NEXT:     Version: 1
# ALL-NEXT:     Entry: 0x0
# ALL-NEXT:     ProgramHeaderOffset: 0x0
# ALL-NEXT:     SectionHeaderOffset:
# ALL-NEXT:     Flags [
# 32BITMODE-NEXT: EF_MIPS_32BITMODE (0x100)
# N32-NEXT:       EF_MIPS_ABI2 (0x20)
# O32-NEXT:       EF_MIPS_ABI_O32 (0x1000)

# MIPS2-NEXT:     EF_MIPS_ARCH_2  (0x10000000)
# MIPS3-NEXT:     EF_MIPS_ARCH_3  (0x20000000)
# MIPS4-NEXT:     EF_MIPS_ARCH_4  (0x30000000)
# MIPS5-NEXT:     EF_MIPS_ARCH_5  (0x40000000)
# MIPS32R1-NEXT:  EF_MIPS_ARCH_32 (0x50000000)
# MIPS32R2-NEXT:  EF_MIPS_ARCH_32R2 (0x70000000)
# The R2 flag is reused for R3 and R5.
# MIPS32R3-NEXT:  EF_MIPS_ARCH_32R2 (0x70000000)
# MIPS32R5-NEXT:  EF_MIPS_ARCH_32R2 (0x70000000)
# MIPS32R6-NEXT:  EF_MIPS_ARCH_32R6 (0x90000000)
# MIPS64R1-NEXT:  EF_MIPS_ARCH_64 (0x60000000)
# MIPS64R2-NEXT:  EF_MIPS_ARCH_64R2 (0x80000000)
# The R2 flag is reused for R3 and R5.
# MIPS64R3-NEXT:  EF_MIPS_ARCH_64R2 (0x80000000)
# MIPS64R5-NEXT:  EF_MIPS_ARCH_64R2 (0x80000000)
# MIPS64R6-NEXT:  EF_MIPS_ARCH_64R6 (0xA0000000)
# OCTEON-NEXT:    EF_MIPS_ARCH_64R2 (0x80000000)

# ALL-NEXT:       EF_MIPS_CPIC (0x4)

# OCTEON-NEXT:    EF_MIPS_MACH_OCTEON (0x8B0000)

# NAN2008-NEXT:   EF_MIPS_NAN2008 (0x400)
# N64-NEXT:       EF_MIPS_PIC (0x2)
# ALL-NEXT:     ]
