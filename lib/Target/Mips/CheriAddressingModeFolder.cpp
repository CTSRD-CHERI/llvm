#include "llvm/CodeGen/MachineDominators.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineLoopInfo.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/Support/CommandLine.h"
#include "Mips.h"
#include "MipsInstrInfo.h"
#include "MipsTargetMachine.h"

using namespace llvm;

static cl::opt<bool> DisableAddressingModeFolder(
    "disable-cheri-addressing-mode-folder", cl::init(false),
    cl::desc("Allow redundant capability manipulations"), cl::Hidden);

namespace {
struct CheriAddressingModeFolder : public MachineFunctionPass {
  static char ID;
  const MipsInstrInfo *InstrInfo = nullptr;

  CheriAddressingModeFolder() : MachineFunctionPass(ID) {
  }
  CheriAddressingModeFolder(MipsTargetMachine &TM) : MachineFunctionPass(ID) {
    InstrInfo = TM.getSubtargetImpl()->getInstrInfo();
  }
  void getAnalysisUsage(AnalysisUsage &AU) const override {
    AU.setPreservesCFG();
    AU.addRequired<MachineLoopInfo>();
    AU.addRequired<MachineDominatorTree>();
    AU.addPreserved<MachineLoopInfo>();
    MachineFunctionPass::getAnalysisUsage(AU);
  }

  bool tryToFoldAdd(unsigned Op, unsigned vreg, MachineRegisterInfo &RI,
      MachineInstr *&AddInst, int64_t &offset) {
    AddInst = RI.getUniqueVRegDef(vreg);
    // If we can't uniquely identify the definition, give up.
    if (AddInst == 0)
      return false;
    unsigned reg;
    int64_t off;
    // If this is an add-immediate then we can possibly fold it
    switch (AddInst->getOpcode()) {
    case Mips::DADDi:
    case Mips::DADDiu:
      // Don't try to fold in things that have relocations yet
      if (!AddInst->getOperand(2).isImm())
        return false;
      reg = AddInst->getOperand(1).getReg();
      off = AddInst->getOperand(2).getImm();
      break;
    default:
      return false;
    }
    // We potentially could fold non-zero adds, but we'll leave them for now.
    if (reg != Mips::ZERO_64)
      return false;
    off += offset;
    // If the result is too big to fit in the offset field, give up
    if (!IsValidOffset(Op, off))
      return false;
    offset = off;
    return true;
  }
  bool IsValidOffset(unsigned Op, int immediate) {
    switch (Op) {
      default:
        llvm_unreachable("No MIPS equivalent");
      case Mips::CAPLOAD8:
      case Mips::CAPSTORE8:
      case Mips::CAPLOADU8:
      case Mips::CAPLOADU832:
      case Mips::CAPLOAD832:
        return isShiftedInt<8,0>(immediate);
      case Mips::CAPLOAD16:
      case Mips::CAPLOADU16:
      case Mips::CAPSTORE16:
      case Mips::CAPLOAD1632:
      case Mips::CAPLOADU1632:
        return isShiftedInt<8,1>(immediate);
      case Mips::CAPLOAD32:
      case Mips::CAPLOADU32:
      case Mips::CAPSTORE32:
      case Mips::CAPLOAD3264:
        return isShiftedInt<8,2>(immediate);
      case Mips::CAPLOAD64:
      case Mips::CAPSTORE64:
        return isShiftedInt<8,3>(immediate);
      case Mips::LOADCAP:
      case Mips::STORECAP:
        return isShiftedInt<11,4>(immediate);
    }
  }
  unsigned MipsOpForCHERIOp(unsigned Op) {
    switch (Op) {
      default:
        llvm_unreachable("No MIPS equivalent");
      case Mips::CAPLOAD8: return Mips::LB64;
      case Mips::CAPLOADU8: return Mips::LBu64;
      case Mips::CAPLOAD16: return Mips::LH64;
      case Mips::CAPLOADU16: return Mips::LHu64;
      case Mips::CAPLOAD32: return Mips::LW;
      case Mips::CAPLOADU32: return Mips::LWu;
      case Mips::CAPLOAD832: return Mips::LB;
      case Mips::CAPLOADU832: return Mips::LBu;
      case Mips::CAPLOAD1632: return Mips::LH;
      case Mips::CAPLOADU1632: return Mips::LHu;
      case Mips::CAPLOAD3264: return Mips::LW64;
      case Mips::CAPLOAD64: return Mips::LD;
      case Mips::CAPSTORE8: return Mips::SB64;
      case Mips::CAPSTORE16: return Mips::SH64;
      case Mips::CAPSTORE32: return Mips::SW64;
      case Mips::CAPSTORE64: return Mips::SD;
    }
  }

  template <typename T>
  void Remove(T &Instrs, MachineRegisterInfo &RI) {
    for (auto *I : Instrs)
      if (RI.use_empty(I->getOperand(0).getReg()))
        I->eraseFromBundle();
  }

  bool foldMachineFunction(MachineFunction &MF, MachineLoopInfo &MLI,
      MachineDominatorTree &MDT) {

    MachineRegisterInfo &RI = MF.getRegInfo();
    std::set<MachineInstr *> IncOffsets;
    std::set<MachineInstr *> Adds;
    llvm::SmallVector<std::pair<MachineInstr *, MachineInstr *>, 8> C0Ops;
    std::set<MachineInstr *> GetPCCs;
    bool modified = false;
    for (auto &MBB : MF)
      for (MachineInstr &I : MBB) {
        int Op = I.getOpcode();
        if (Op == Mips::CGetPCC) {
          GetPCCs.insert(&I);
          continue;
        }
        // Only look at cap-relative loads and stores
        if (!(Op == Mips::CAPLOAD8 || Op == Mips::CAPLOADU8 ||
              Op == Mips::CAPLOAD16 || Op == Mips::CAPLOADU16 ||
              Op == Mips::CAPLOAD32 || Op == Mips::CAPLOADU32 ||
              Op == Mips::CAPLOAD832 || Op == Mips::CAPLOADU832 ||
              Op == Mips::CAPLOAD1632 || Op == Mips::CAPLOADU1632 ||
              Op == Mips::CAPLOAD3264 || Op == Mips::CAPLOAD64 ||
              Op == Mips::CAPSTORE8 || Op == Mips::CAPSTORE16 ||
              Op == Mips::LOADCAP || Op == Mips::STORECAP ||
              Op == Mips::CAPSTORE32 || Op == Mips::CAPSTORE64))
          continue;
        int64_t offset = I.getOperand(2).getImm();
        // If the load is not currently at register-zero offset, we can't fix
        // it up to use relative addressing, but we may be able to modify it so
        // that it is...
        if (I.getOperand(1).getReg() != Mips::ZERO_64) {
          MachineInstr *AddInst;
          // If the register offset is a simple constant, then try to move it
          // into the memory operation
          if (tryToFoldAdd(Op, I.getOperand(1).getReg(), RI, AddInst, offset)) {
            Adds.insert(AddInst);
            I.getOperand(1).setImm(offset);
            I.getOperand(1).setReg(Mips::ZERO_64);
          } else
            continue;
        }
        // If we get to here, then the memory operation has a capability and
        // (possibly) an immediate offset, but the register offset is $zero.
        // If the capability is formed by incrementing an offset, then try to
        // pull that calculation into the memory operation.

        MachineInstr *IncOffset = RI.getUniqueVRegDef(I.getOperand(3).getReg());
        if (!IncOffset)
          continue;
        // If this is CFromPtr-relative load or store, then we may be able to
        // fold it into a MIPS load.
        if (IncOffset->getOpcode() == Mips::CFromPtr) {
          if ((Op == Mips::LOADCAP) || (Op == Mips::STORECAP))
            continue;
          if (IncOffset->getOperand(1).getReg() == Mips::C0)
            C0Ops.emplace_back(&I, IncOffset);
          continue;
        }
        // Ignore ones that are not based on a CIncOffset op
        if (IncOffset->getOpcode() != Mips::CIncOffset)
          continue;
        assert(IncOffset);

        MachineOperand Cap = IncOffset->getOperand(1);
        MachineOperand Offset = IncOffset->getOperand(2);
        assert(Cap.isReg());
        MachineInstr *AddInst;
        // If the CIncOffset is of a daddi[u] then we can potentially replace
        // both by just folding the register and immediate offsets into the
        // load / store.
        if (tryToFoldAdd(Op, Offset.getReg(), RI, AddInst, offset)) {
          // If we managed to pull the offset calculation entirely away, then
          // just use the computed immediate
          Adds.insert(AddInst);
          I.getOperand(1).setReg(Mips::ZERO_64);
          I.getOperand(2).setImm(offset);
        } else
          // If we didn't, then use the CIncOffset's register value as our
          // offset
          I.getOperand(1).setReg(Offset.getReg());
        I.getOperand(3).setReg(Cap.getReg());
        IncOffsets.insert(IncOffset);
        modified = true;
      }
    for (auto &I : C0Ops) {
      IncOffsets.insert(I.second);
      unsigned BaseReg = I.second->getOperand(2).getReg();
      // This can't be a symbolic address (yet) because we don't have
      // relocations that fit.
      MachineOperand &Offset = I.first->getOperand(2);
      // If this was the result of a daddiu, fold the immediate into the result
      // as well.
      MachineInstr *AddInst = RI.getUniqueVRegDef(BaseReg);
      if (AddInst && (AddInst->getOpcode() == Mips::DADDiu)) {
        MachineOperand &MO = AddInst->getOperand(2);
        // FIXME: We could probably fold the add into the load in some cases
        // even when it's not initially zero, as our immediate field has just
        // grown, but that's probably not the common case.
        if (Offset.isImm() && (Offset.getImm() == 0)) {
          Offset = MO;
          BaseReg = AddInst->getOperand(1).getReg();
        }
      } else
        AddInst = nullptr;
      auto InsertPoint = I.first;
      MachineBasicBlock *InsertBlock = I.first->getParent();
      // If this is a load of a GOT offset and it's in a loop then we want to
      // try to hoist it out of the loop.
      if (Offset.isGlobal()) {
        auto Loop = MLI.getLoopFor(InsertBlock);
        if (Loop) {
          auto *Preheader = Loop->getLoopPreheader();
          // If all paths to this block go through the preheader then hoist.
          // Note: It might be worth doing this recursively and pushing out of
          // nested loops.
          if (MDT.dominates(Preheader, InsertBlock))
            if (MDT.dominates(&*Preheader->getFirstTerminator(), I.first)) {
              InsertBlock = Preheader;
              InsertPoint = &*InsertBlock->getFirstTerminator();
            }
        }
      }
      auto FirstOperand = I.first->getOperand(0);
      unsigned FirstReg = FirstOperand.getReg();
      BuildMI(*InsertBlock, InsertPoint, I.first->getDebugLoc(),
          InstrInfo->get(MipsOpForCHERIOp(I.first->getOpcode())))
        .addReg(FirstReg, getDefRegState(FirstOperand.isDef()))
        .addReg(BaseReg).addOperand(Offset);
      I.first->eraseFromBundle();
      if (AddInst) {
        // If we've folded the base of the add into the load's immediate, then
        // we the add is no longer able to kill the register.
        AddInst->getOperand(1).setIsKill(false);
        Adds.insert(AddInst);
      }
      modified = true;
    }
    Remove(GetPCCs, RI);
    Remove(IncOffsets, RI);
    Remove(Adds, RI);
    return modified;
  }
  bool runOnMachineFunction(MachineFunction &MF) override {
    if (DisableAddressingModeFolder)
      return false;
    bool modified = false;
    MachineLoopInfo &MLI = getAnalysis<MachineLoopInfo>();
    MachineDominatorTree &MDT = getAnalysis<MachineDominatorTree>();
    while (foldMachineFunction(MF, MLI, MDT))
      modified = true;
    return modified;
  }
};
}
namespace llvm {
  void initializeCheriAddressingModeFolderPass(PassRegistry&);
}


char CheriAddressingModeFolder::ID;
INITIALIZE_PASS_BEGIN(CheriAddressingModeFolder, "cheriaddrmodefolder",
                    "CHERI addressing mode folder", false, false)
INITIALIZE_PASS_DEPENDENCY(MachineLoopInfo)
INITIALIZE_PASS_DEPENDENCY(MachineDominatorTree)
INITIALIZE_PASS_END(CheriAddressingModeFolder, "cheriaddrmodefolder",
                    "CHERI addressing mode folder", false, false)



MachineFunctionPass *
llvm::createCheriAddressingModeFolder(MipsTargetMachine &TM) {
  return new CheriAddressingModeFolder(TM);
}
