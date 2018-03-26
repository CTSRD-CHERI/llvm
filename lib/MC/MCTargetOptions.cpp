//===- lib/MC/MCTargetOptions.cpp - MC Target Options ---------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "llvm/MC/MCTargetOptions.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;


// XXXAR: TODO: probably nicer to use feature-flags instead

static cl::opt<bool> UseCheriCapTable("cheri-cap-table", cl::Hidden,
                               cl::desc("Use the new cheri cap table to load globals"));

// TODO: remove the -mllvm -cheri-cap-table flag since this is a superset
static cl::opt<CheriCapabilityTableABI> CapTableABI("cheri-cap-table-abi",
    cl::desc("ABI to use for :"), cl::init(CheriCapabilityTableABI::Legacy),
    cl::values(clEnumValN(CheriCapabilityTableABI::Legacy, "legacy",
                          "Disable capability table and use the legacy ABI"),
               clEnumValN(CheriCapabilityTableABI::PLT, "plt",
                          "Use PLT stubs to setup $cgp correctly"),
               clEnumValN(CheriCapabilityTableABI::Pcrel, "pcrel",
                          "Derive $cgp from $pcc in every function"),
               clEnumValN(CheriCapabilityTableABI::FunctionDescriptor,
                          "fn-desc",
                          "Use function descriptors to setup $cgp correctly")));

bool MCTargetOptions::cheriUsesCapabilityTable() {
  // TODO: remove UseCheriCapTable
  return UseCheriCapTable || CapTableABI != CheriCapabilityTableABI::Legacy;
}

CheriCapabilityTableABI MCTargetOptions::cheriCapabilityTableABI() {
  return CapTableABI;
}

MCTargetOptions::MCTargetOptions()
    : SanitizeAddress(false), MCRelaxAll(false), MCNoExecStack(false),
      MCFatalWarnings(false), MCNoWarn(false), MCNoDeprecatedWarn(false),
      MCSaveTempLabels(false), MCUseDwarfDirectory(false),
      MCIncrementalLinkerCompatible(false), MCPIECopyRelocations(false),
      ShowMCEncoding(false), ShowMCInst(false), AsmVerbose(false),
      PreserveAsmComments(true) {}

StringRef MCTargetOptions::getABIName() const {
  return ABIName;
}
