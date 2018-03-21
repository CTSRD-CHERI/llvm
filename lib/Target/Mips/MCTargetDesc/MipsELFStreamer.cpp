//===-------- MipsELFStreamer.cpp - ELF Object Output ---------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "MipsELFStreamer.h"
#include "MipsFixupKinds.h"
#include "MipsMCExpr.h"
#include "MipsOptionRecord.h"
#include "MipsTargetStreamer.h"
#include "llvm/BinaryFormat/ELF.h"
#include "llvm/MC/MCAsmBackend.h"
#include "llvm/MC/MCAssembler.h"
#include "llvm/MC/MCCodeEmitter.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCSymbolELF.h"
#include "llvm/Support/Casting.h"

using namespace llvm;

MipsELFStreamer::MipsELFStreamer(MCContext &Context,
                                 std::unique_ptr<MCAsmBackend> MAB,
                                 raw_pwrite_stream &OS,
                                 std::unique_ptr<MCCodeEmitter> Emitter)
    : MCELFStreamer(Context, std::move(MAB), OS, std::move(Emitter)) {
  RegInfoRecord = new MipsRegInfoRecord(this, Context);
  MipsOptionRecords.push_back(
      std::unique_ptr<MipsRegInfoRecord>(RegInfoRecord));
}

void MipsELFStreamer::EmitInstruction(const MCInst &Inst,
                                      const MCSubtargetInfo &STI, bool) {
  MCELFStreamer::EmitInstruction(Inst, STI);

  MCContext &Context = getContext();
  const MCRegisterInfo *MCRegInfo = Context.getRegisterInfo();

  for (unsigned OpIndex = 0; OpIndex < Inst.getNumOperands(); ++OpIndex) {
    const MCOperand &Op = Inst.getOperand(OpIndex);

    if (!Op.isReg())
      continue;

    unsigned Reg = Op.getReg();
    RegInfoRecord->SetPhysRegUsed(Reg, MCRegInfo);
  }

  createPendingLabelRelocs();
}

void MipsELFStreamer::createPendingLabelRelocs() {
  MipsTargetELFStreamer *ELFTargetStreamer =
      static_cast<MipsTargetELFStreamer *>(getTargetStreamer());

  // FIXME: Also mark labels when in MIPS16 mode.
  if (ELFTargetStreamer->isMicroMipsEnabled()) {
    for (auto *L : Labels) {
      auto *Label = cast<MCSymbolELF>(L);
      getAssembler().registerSymbol(*Label);
      Label->setOther(ELF::STO_MIPS_MICROMIPS);
    }
  }

  Labels.clear();
}

void MipsELFStreamer::EmitLabel(MCSymbol *Symbol, SMLoc Loc) {
  MCELFStreamer::EmitLabel(Symbol);
  Labels.push_back(Symbol);
}

void MipsELFStreamer::SwitchSection(MCSection *Section,
                                    const MCExpr *Subsection) {
  MCELFStreamer::SwitchSection(Section, Subsection);
  Labels.clear();
}

void MipsELFStreamer::EmitValueImpl(const MCExpr *Value, unsigned Size,
                                    SMLoc Loc) {
  MCELFStreamer::EmitValueImpl(Value, Size, Loc);
  Labels.clear();
}

void MipsELFStreamer::EmitCheriCapabilityImpl(const MCSymbol *Symbol,
                                              int64_t Offset, unsigned CapSize,
                                              SMLoc Loc) {
  visitUsedSymbol(*Symbol);
  MCContext &Context = getContext();

  const MCSymbolRefExpr *SRE =
      MCSymbolRefExpr::create(Symbol, MCSymbolRefExpr::VK_None, Context);
  const MCBinaryExpr *CapExpr = MCBinaryExpr::createAdd(
      MipsMCExpr::create(MipsMCExpr::MEK_CHERI_CAP, SRE, Context),
      MCConstantExpr::create(Offset, Context), Context);

  const unsigned ByteAlignment = CapSize;
  insert(new MCAlignFragment(ByteAlignment, 0, 1, ByteAlignment));
  // Update the maximum alignment on the current section if necessary.
  MCSection *CurSec = getCurrentSectionOnly();
  if (ByteAlignment > CurSec->getAlignment())
    CurSec->setAlignment(ByteAlignment);

  MCDataFragment *DF = new MCDataFragment();
  MCFixup cheriFixup =
      MCFixup::create(0, CapExpr, MCFixupKind(Mips::fixup_CHERI_CAPABILITY));
  DF->getFixups().push_back(cheriFixup);
  DF->getContents().resize(DF->getContents().size() + CapSize, 0xca);
  insert(DF);
}

void MipsELFStreamer::EmitCheriIntcap(int64_t Value, unsigned CapSize, SMLoc) {
  assert(CapSize == 32 || CapSize == 16);
  if (Value == 0) {
    EmitZeros(CapSize);
  } else {
    // TODO: we should probably move the CHERI capability encoding somewhere else.
    // Maybe to BinaryFormat or Object?
    EmitIntValue(0, 8);
    EmitIntValue(Value, 8);
    if (CapSize == 32) {
      EmitIntValue(0, 8);
      EmitIntValue(0, 8);
    }
  }
}

void MipsELFStreamer::EmitMipsOptionRecords() {
  for (const auto &I : MipsOptionRecords)
    I->EmitMipsOptionRecord();
}

MCELFStreamer *llvm::createMipsELFStreamer(
    MCContext &Context, std::unique_ptr<MCAsmBackend> MAB,
    raw_pwrite_stream &OS, std::unique_ptr<MCCodeEmitter> Emitter,
    bool RelaxAll) {
  return new MipsELFStreamer(Context, std::move(MAB), OS, std::move(Emitter));
}
