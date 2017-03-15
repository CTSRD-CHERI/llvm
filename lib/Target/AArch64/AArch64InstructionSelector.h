//===- AArch64InstructionSelector --------------------------------*- C++ -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
/// \file
/// This file declares the targeting of the InstructionSelector class for
/// AArch64.
//===----------------------------------------------------------------------===//

#ifdef LLVM_BUILD_GLOBAL_ISEL

#ifndef LLVM_LIB_TARGET_AARCH64_AARCH64INSTRUCTIONSELECTOR_H
#define LLVM_LIB_TARGET_AARCH64_AARCH64INSTRUCTIONSELECTOR_H

#include "llvm/CodeGen/GlobalISel/InstructionSelector.h"
#include "llvm/CodeGen/MachineOperand.h"

namespace llvm {

class AArch64InstrInfo;
class AArch64RegisterBankInfo;
class AArch64RegisterInfo;
class AArch64Subtarget;
class AArch64TargetMachine;
class MachineOperand;

class MachineFunction;
class MachineRegisterInfo;

class AArch64InstructionSelector : public InstructionSelector {
public:
  AArch64InstructionSelector(const AArch64TargetMachine &TM,
                             const AArch64Subtarget &STI,
                             const AArch64RegisterBankInfo &RBI);

  bool select(MachineInstr &I) const override;

private:
  bool selectVaStartAAPCS(MachineInstr &I, MachineFunction &MF,
                          MachineRegisterInfo &MRI) const;
  bool selectVaStartDarwin(MachineInstr &I, MachineFunction &MF,
                           MachineRegisterInfo &MRI) const;

  /// tblgen-erated 'select' implementation, used as the initial selector for
  /// the patterns that don't require complex C++.
  bool selectImpl(MachineInstr &I) const;

  bool selectArithImmed(MachineOperand &Root, MachineOperand &Result1,
                        MachineOperand &Result2) const;

  const AArch64TargetMachine &TM;
  const AArch64Subtarget &STI;
  const AArch64InstrInfo &TII;
  const AArch64RegisterInfo &TRI;
  const AArch64RegisterBankInfo &RBI;

// We declare the temporaries used by selectImpl() in the class to minimize the
// cost of constructing placeholder values.
#define GET_GLOBALISEL_TEMPORARIES_DECL
#include "AArch64GenGlobalISel.inc"
#undef GET_GLOBALISEL_TEMPORARIES_DECL
};

} // end namespace llvm

#endif // LLVM_LIB_TARGET_AARCH64_AARCH64INSTRUCTIONSELECTOR_H
#endif // LLVM_BUILD_GLOBAL_ISEL
