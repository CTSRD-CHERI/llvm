#include "llvm/Pass.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstVisitor.h"
#include "llvm/Transforms/Utils/Local.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"

#include <unordered_map>

using namespace llvm;
using std::pair;

namespace {
class CheriLoadStoreReplacement: public ModulePass,
                                 public InstVisitor<CheriLoadStoreReplacement> {
  llvm::SmallVector<LoadInst*, 16> Loads;
  llvm::SmallVector<StoreInst*, 16> Stores;

  virtual const char *getPassName() const {
    return "CHERI MIPS load/store instruction replacement";
  }

  public:
    static char ID;
    CheriLoadStoreReplacement() : ModulePass(ID) {}

    // InstVisitor functions to accumulate the load/store instructions found in
    // this BB, to be batch-processed at the end (to avoid invalidating the
    // iterator while we're using it).
    void visitLoadInst(LoadInst &LI) {
      // Filter out instructions that won't require introducing a cast.
      if (LI.getPointerOperand()->getType()->getPointerAddressSpace() == 200) {
        return;
      }

      Loads.push_back(&LI);
    }
    void visitStoreInst(StoreInst &SI) {
      if (SI.getPointerOperand()->getType()->getPointerAddressSpace() == 200) {
        return;
      }

      Stores.push_back(&SI);
    }

    virtual bool runOnModule(Module &M) override {
      LLVMContext &C = M.getContext();
      IRBuilder<> B(C);

      // Retype all globals into address space 200.
      for (Module::global_iterator GVI = M.global_begin(), E = M.global_end();
           GVI != E; ) {
        GlobalVariable *GV = GVI++;

        if (GV->getType()->getPointerAddressSpace() == 200) {
          continue;
        }

        // Build the replacement global variable. The constructor expects the
        // pointee type (and GVs are always pointer types), hence the
        // slightly unintuitive getContainedType call.
        GlobalVariable *Replacement = new GlobalVariable(
            GV->getType()->getContainedType(0), GV->isConstant(),
            GV->getLinkage(), GV->getInitializer(), GV->getName(),
            GV->getThreadLocalMode(), 200, GV->isExternallyInitialized());
        Replacement->dump();

        // Fixup the uses of the GV to point to the replacement. We can't
        // use replaceAllUsesWith because the type has changed.
        for (User *U : GV->users()) {
          U->dump();
          if (LoadInst *LI = dyn_cast<LoadInst>(U)) {
            LoadInst *newInstruction = new LoadInst(Replacement, LI->getName(),
                LI->isVolatile(), LI->getAlignment(), LI->getOrdering(),
                LI->getSynchScope(), LI);

            LI->replaceAllUsesWith(newInstruction);
            LI->eraseFromParent();
          } else if (StoreInst *SI = dyn_cast<StoreInst>(U)) {
            StoreInst *newInstruction = new StoreInst(SI->getValueOperand(),
                Replacement, SI->isVolatile(), SI->getAlignment(),
                SI->getOrdering(), SI->getSynchScope(), SI);

            SI->replaceAllUsesWith(newInstruction);
            SI->eraseFromParent();
          } else if (!isa<GetElementPtrInst>(U)) { // TODO: Support GEP.
            llvm_unreachable("Unexpected global use type!");
          }
        }

        GV->eraseFromParent();
        M.getGlobalList().push_back(Replacement);
      }

      // Next, cast the pointer arguments of all loads/stores into addrspace
      // 200.
      Loads.clear();
      Stores.clear();

      visit(M);

      if (Loads.empty() && Stores.empty()) {
        return false;
      }

      for (LoadInst *LI : Loads) {
        // Cast the pointer argument to addrspace 200.
        Value *newLoadArgument = insertPointerArgumentCast(LI, 0, B);

        // Replace the load with a new one that uses the result of the cast.
        LoadInst *newInstruction = new LoadInst(newLoadArgument, LI->getName(),
            LI->isVolatile(), LI->getAlignment(), LI->getOrdering(),
            LI->getSynchScope(), LI);
        LI->replaceAllUsesWith(newInstruction);
        LI->eraseFromParent();
      }

      for (StoreInst *SI : Stores) {
        Value *newStoreArgument = insertPointerArgumentCast(SI, 1, B);

        StoreInst *newInstruction = new StoreInst(SI->getValueOperand(),
            newStoreArgument, SI->isVolatile(), SI->getAlignment(),
            SI->getOrdering(), SI->getSynchScope(), SI);
        SI->replaceAllUsesWith(newInstruction);
        SI->eraseFromParent();
      }

      return true;
    }

    // For a load or store instruction I, insert an address space cast for its
    // pointer argument to addrspace 200 and return the corresponding Value.
    Value *insertPointerArgumentCast(Instruction *I, int pointerOperandIndex, IRBuilder<> B) {
      Value *pointerOperand = I->getOperand(pointerOperandIndex);

      // Convert the pointer type to its equivalent in addrspace 200.
      Type *pointeeType = pointerOperand->getType()->getContainedType(0);
      PointerType *newPointerType = PointerType::get(pointeeType, 200);

      // Insert an addrspace cast for the argument before instruction I and
      // return it.
      B.SetInsertPoint(I);
      return B.CreateAddrSpaceCast(pointerOperand, newPointerType);
    }
};

} // anonymous namespace

char CheriLoadStoreReplacement::ID;

namespace llvm {
  ModulePass *createCheriLoadStoreReplacement(void) {
    return new CheriLoadStoreReplacement();
  }
}
