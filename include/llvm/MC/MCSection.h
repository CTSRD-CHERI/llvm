//===- MCSection.h - Machine Code Sections ----------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file declares the MCSection class.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_MC_MCSECTION_H
#define LLVM_MC_MCSECTION_H

#include "llvm/ADT/StringRef.h"
#include "llvm/MC/SectionKind.h"
#include "llvm/Support/Compiler.h"

namespace llvm {
class MCAsmInfo;
class MCContext;
class MCExpr;
class MCSymbol;
class raw_ostream;

/// Instances of this class represent a uniqued identifier for a section in the
/// current translation unit.  The MCContext class uniques and creates these.
class MCSection {
public:
  enum SectionVariant { SV_COFF = 0, SV_ELF, SV_MachO };

private:
  MCSection(const MCSection &) = delete;
  void operator=(const MCSection &) = delete;

  MCSymbol *Begin;
  mutable MCSymbol *End;

protected:
  MCSection(SectionVariant V, SectionKind K, MCSymbol *Begin)
      : Begin(Begin), End(nullptr), Variant(V), Kind(K) {}
  SectionVariant Variant;
  SectionKind Kind;

public:
  virtual ~MCSection();

  SectionKind getKind() const { return Kind; }

  SectionVariant getVariant() const { return Variant; }

  MCSymbol *getBeginSymbol() const { return Begin; }
  MCSymbol *getEndSymbol(MCContext &Ctx) const;
  bool hasEnded() const;

  virtual void PrintSwitchToSection(const MCAsmInfo &MAI, raw_ostream &OS,
                                    const MCExpr *Subsection) const = 0;

  /// Return true if a .align directive should use "optimized nops" to fill
  /// instead of 0s.
  virtual bool UseCodeAlign() const = 0;

  /// Check whether this section is "virtual", that is has no actual object
  /// file contents.
  virtual bool isVirtualSection() const = 0;
};

} // end namespace llvm

#endif
