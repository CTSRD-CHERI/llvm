//===-- FuzzerCLI.cpp -----------------------------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "llvm/FuzzMutate/FuzzerCLI.h"
#include "llvm/ADT/Triple.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Support/Error.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

void llvm::parseFuzzerCLOpts(int ArgC, char *ArgV[]) {
  std::vector<const char *> CLArgs;
  CLArgs.push_back(ArgV[0]);

  int I = 1;
  while (I < ArgC)
    if (StringRef(ArgV[I++]).equals("-ignore_remaining_args=1"))
      break;
  while (I < ArgC)
    CLArgs.push_back(ArgV[I++]);

  cl::ParseCommandLineOptions(CLArgs.size(), CLArgs.data());
}

void llvm::handleExecNameEncodedBEOpts(StringRef ExecName) {
  std::vector<std::string> Args{ExecName};

  auto NameAndArgs = ExecName.split("--");
  if (NameAndArgs.second.empty())
    return;

  SmallVector<StringRef, 4> Opts;
  NameAndArgs.second.split(Opts, '-');
  for (StringRef Opt : Opts) {
    if (Opt.equals("gisel")) {
      Args.push_back("-global-isel");
      // For now we default GlobalISel to -O0
      Args.push_back("-O0");
    } else if (Opt.startswith("O")) {
      Args.push_back("-" + Opt.str());
    } else if (Triple::getArchTypeForLLVMName(Opt)) {
      Args.push_back("-mtriple=" + Opt.str());
    } else {
      errs() << ExecName << ": Unknown option: " << Opt << ".\n";
      exit(1);
    }
  }
  errs() << NameAndArgs.first << ": Injected args:";
  for (int I = 1, E = Args.size(); I < E; ++I)
    errs() << " " << Args[I];
  errs() << "\n";

  std::vector<const char *> CLArgs;
  CLArgs.reserve(Args.size());
  for (std::string &S : Args)
    CLArgs.push_back(S.c_str());

  cl::ParseCommandLineOptions(CLArgs.size(), CLArgs.data());
}

int llvm::runFuzzerOnInputs(int ArgC, char *ArgV[], FuzzerTestFun TestOne,
                            FuzzerInitFun Init) {
  errs() << "*** This tool was not linked to libFuzzer.\n"
         << "*** No fuzzing will be performed.\n";
  if (int RC = Init(&ArgC, &ArgV)) {
    errs() << "Initialization failed\n";
    return RC;
  }

  for (int I = 1; I < ArgC; ++I) {
    StringRef Arg(ArgV[I]);
    if (Arg.startswith("-")) {
      if (Arg.equals("-ignore_remaining_args=1"))
        break;
      continue;
    }

    auto BufOrErr = MemoryBuffer::getFile(Arg, /*FileSize-*/ -1,
                                          /*RequiresNullTerminator=*/false);
    if (std::error_code EC = BufOrErr.getError()) {
      errs() << "Error reading file: " << Arg << ": " << EC.message() << "\n";
      return 1;
    }
    std::unique_ptr<MemoryBuffer> Buf = std::move(BufOrErr.get());
    errs() << "Running: " << Arg << " (" << Buf->getBufferSize() << " bytes)\n";
    TestOne(reinterpret_cast<const uint8_t *>(Buf->getBufferStart()),
            Buf->getBufferSize());
  }
  return 0;
}
