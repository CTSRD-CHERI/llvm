//===-- PureCapABICalls.cpp -----------------------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the passes that transform PCC-relative calls into
// direct calls (so that they can be inlined) and then back again (so that we
// generate the correct code).
//
//===----------------------------------------------------------------------===//

#include "llvm/ADT/StringSwitch.h"
#include "llvm/IR/CallSite.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstVisitor.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/CHERICap.h"

using namespace llvm;
using namespace PatternMatch;

namespace {
class CHERICapFoldIntrinsics : public ModulePass {
  Function *IncOffset;
  Function *SetOffset;
  Function *GetOffset;
  Function *GetBase;
  Function *GetAddress;
  Function *GetLength;
  Function *GetType;
  Function *GetPerms;
  Function *GetTag;
  Function *GetSealed;

  bool Modified;

  template <typename Infer>
  void foldGet(Function *Intrinsic, Infer infer, int NullValue = 0) {
    // Calling eraseFromParent() inside the following loop causes iterators
    // to be invalidated and crashes -> collect and erase instead
    std::vector<CallInst *> ToErase;
    for (Value *Use : Intrinsic->users()) {
      CallInst *CI = cast<CallInst>(Use);
      if (Value *Replacement = infer(CI->getOperand(0), CI, NullValue)) {
        CI->replaceAllUsesWith(Replacement);
        // CI->eraseFromParent();
        ToErase.push_back(CI);
        Modified = true;
      }
    }
    for (CallInst *CI : ToErase) {
      CI->eraseFromParent();
    }
  }

  void foldGetIntrinisics() {
    foldGet(GetOffset, inferCapabilityOffset);
    foldGet(GetAddress, inferCapabilityAddress);

    foldGet(GetBase, inferCapabilityNonOffsetField);
    foldGet(GetPerms, inferCapabilityNonOffsetField);
    foldGet(GetTag, inferCapabilityNonOffsetField);
    foldGet(GetSealed, inferCapabilityNonOffsetField);
    // CGetType and CGetLen on a null capability now return -1
    foldGet(GetLength, inferCapabilityNonOffsetField, -1);
    foldGet(GetType, inferCapabilityNonOffsetField, -1);
  }

  static Value *inferCapabilityNonOffsetField(Value *V, CallInst *Call,
                                              int NullValue) {
    if (isa<ConstantPointerNull>(V)) {
      Type *Ty = Call->getType();
      return NullValue == 0 ? llvm::Constant::getNullValue(Ty)
                            : llvm::Constant::getAllOnesValue(Ty);
    }
    Value *Arg = nullptr;
    // ignore all setoffset/incoffset operations:
    if (match(V, m_Intrinsic<Intrinsic::cheri_cap_offset_set>(m_Value(Arg)))) {
      return inferCapabilityNonOffsetField(Arg, Call, NullValue);
    } else if (match(V, m_Intrinsic<Intrinsic::cheri_cap_offset_increment>(
                            m_Value(Arg)))) {
      return inferCapabilityNonOffsetField(Arg, Call, NullValue);
    }
    // TODO: is there anything else we can infer?
    return nullptr;
  }

  static Value *inferCapabilityOffset(Value *V, CallInst *Call, int NullValue) {
    if (isa<ConstantPointerNull>(V))
      return llvm::Constant::getNullValue(Call->getType());
    Value *Arg = nullptr;
    Value *Offset = nullptr;
    if (match(V, m_Intrinsic<Intrinsic::cheri_cap_offset_set>(
                     m_Value(), m_Value(Offset)))) {
      return Offset;
    } else if (match(V, m_Intrinsic<Intrinsic::cheri_cap_offset_increment>(
                            m_Value(Arg), m_Value(Offset)))) {
      if (Value *LHS = inferCapabilityOffset(Arg, Call, NullValue)) {
        IRBuilder<> B(cast<Instruction>(V));
        return B.CreateAdd(LHS, Offset);
      }
    }
    // TODO: is there anything else we can infer?
    return nullptr;
  }

  static Value *inferCapabilityAddress(Value *V, CallInst *Call,
                                       int NullValue) {
    Value *Offset = inferCapabilityOffset(V, Call, 0);
    Value *Base = inferCapabilityNonOffsetField(V, Call, 0);
    if (Offset && Base) {
      IRBuilder<> B(Call);
      return B.CreateAdd(Base, Offset);
    }
    return nullptr;
  }

  /// Replace get-offset, add, set-offset sequences with inc-offset
  void foldGetAddSetToInc() {
    std::vector<CallInst *> SetOffsets;
    for (Value *V : SetOffset->users())
      SetOffsets.push_back(cast<CallInst>(V));
    for (CallInst *CI : SetOffsets) {
      Value *LHS, *RHS;
      if (match(CI->getOperand(1), m_Add(m_Value(LHS), m_Value(RHS)))) {
        Value *BaseCap = CI->getOperand(0);
        Value *Add = nullptr;
        if (match(LHS, m_Intrinsic<Intrinsic::cheri_cap_offset_get>(
                           m_Specific(BaseCap))))
          Add = RHS;
        else if (match(RHS, m_Intrinsic<Intrinsic::cheri_cap_offset_get>(
                                m_Specific(BaseCap))))
          Add = LHS;
        if (Add) {
          IRBuilder<> B(CI);
          Value *Replacement = B.CreateCall(IncOffset, {BaseCap, Add});
          CI->replaceAllUsesWith(Replacement);
          Modified = true;
        }
      }
    }
  }

public:
  static char ID;
  CHERICapFoldIntrinsics() : ModulePass(ID) {}
  StringRef getPassName() const override {
    return "CHERI fold capability intrinsics";
  }
  bool runOnModule(Module &M) override {
    Modified = false;
    IncOffset =
        Intrinsic::getDeclaration(&M, Intrinsic::cheri_cap_offset_increment);
    SetOffset = Intrinsic::getDeclaration(&M, Intrinsic::cheri_cap_offset_set);
    GetOffset = Intrinsic::getDeclaration(&M, Intrinsic::cheri_cap_offset_get);
    GetBase = Intrinsic::getDeclaration(&M, Intrinsic::cheri_cap_base_get);
    GetAddress =
        Intrinsic::getDeclaration(&M, Intrinsic::cheri_cap_address_get);
    GetLength = Intrinsic::getDeclaration(&M, Intrinsic::cheri_cap_length_get);
    GetType = Intrinsic::getDeclaration(&M, Intrinsic::cheri_cap_type_get);
    GetPerms = Intrinsic::getDeclaration(&M, Intrinsic::cheri_cap_perms_get);
    GetSealed = Intrinsic::getDeclaration(&M, Intrinsic::cheri_cap_sealed_get);
    GetTag = Intrinsic::getDeclaration(&M, Intrinsic::cheri_cap_tag_get);
    foldGetAddSetToInc();
    foldGetIntrinisics();
    return Modified;
  }
  void getAnalysisUsage(AnalysisUsage &AU) const override {
    AU.setPreservesCFG();
  }
};
} // namespace

char CHERICapFoldIntrinsics::ID = 0;
INITIALIZE_PASS(CHERICapFoldIntrinsics, "cheri-fold-intrisics",
                "Remove redundant capability instructions", false, false)

Pass *llvm::createCHERICapFoldIntrinsicsPass() {
  return new CHERICapFoldIntrinsics();
}
