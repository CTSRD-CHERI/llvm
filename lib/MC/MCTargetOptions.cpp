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

static cl::opt<CheriCapabilityTableABI> CapTableABI(
    "cheri-cap-table-abi", cl::desc("ABI to use for :"),
    cl::init(CheriCapabilityTableABI::Legacy),
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
  return CapTableABI != CheriCapabilityTableABI::Legacy;
}

CheriCapabilityTableABI MCTargetOptions::cheriCapabilityTableABI() {
  return CapTableABI;
}

static cl::opt<CheriCapabilityTlsABI> CapTlsABI(
    "cheri-cap-tls-abi", cl::desc("ABI to use for :"),
    cl::values(clEnumValN(CheriCapabilityTlsABI::Legacy, "legacy",
                          "Disable capability TLS and use the legacy ABI"),
               clEnumValN(CheriCapabilityTlsABI::CapEquiv, "cap-equiv",
                          "Use a capability equivalent of the normal ABI")));

bool MCTargetOptions::cheriUsesCapabilityTls() {
  return cheriCapabilityTlsABI() != CheriCapabilityTlsABI::Legacy &&
         cheriUsesCapabilityTable();
}

CheriCapabilityTlsABI MCTargetOptions::cheriCapabilityTlsABI() {
  if (!cheriUsesCapabilityTable())
    return CheriCapabilityTlsABI::Legacy;
  // For cap-table default to CapEquiv unless there is an explicit =legacy set.
  if (CapTlsABI.getNumOccurrences() > 0)
    return CapTlsABI;
  return CheriCapabilityTlsABI::CapEquiv;
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
