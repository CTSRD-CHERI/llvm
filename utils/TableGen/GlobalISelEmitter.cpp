//===- GlobalISelEmitter.cpp - Generate an instruction selector -----------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
/// \file
/// This tablegen backend emits code for use by the GlobalISel instruction
/// selector. See include/llvm/CodeGen/TargetGlobalISel.td.
///
/// This file analyzes the patterns recognized by the SelectionDAGISel tablegen
/// backend, filters out the ones that are unsupported, maps
/// SelectionDAG-specific constructs to their GlobalISel counterpart
/// (when applicable: MVT to LLT;  SDNode to generic Instruction).
///
/// Not all patterns are supported: pass the tablegen invocation
/// "-warn-on-skipped-patterns" to emit a warning when a pattern is skipped,
/// as well as why.
///
/// The generated file defines a single method:
///     bool <Target>InstructionSelector::selectImpl(MachineInstr &I) const;
/// intended to be used in InstructionSelector::select as the first-step
/// selector for the patterns that don't require complex C++.
///
/// FIXME: We'll probably want to eventually define a base
/// "TargetGenInstructionSelector" class.
///
//===----------------------------------------------------------------------===//

#include "CodeGenDAGPatterns.h"
#include "llvm/ADT/Optional.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/CodeGen/MachineValueType.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/TableGen/Error.h"
#include "llvm/TableGen/Record.h"
#include "llvm/TableGen/TableGenBackend.h"
#include <string>
using namespace llvm;

#define DEBUG_TYPE "gisel-emitter"

STATISTIC(NumPatternTotal, "Total number of patterns");
STATISTIC(NumPatternSkipped, "Number of patterns skipped");
STATISTIC(NumPatternEmitted, "Number of patterns emitted");

static cl::opt<bool> WarnOnSkippedPatterns(
    "warn-on-skipped-patterns",
    cl::desc("Explain why a pattern was skipped for inclusion "
             "in the GlobalISel selector"),
    cl::init(false));

namespace {

class GlobalISelEmitter {
public:
  explicit GlobalISelEmitter(RecordKeeper &RK);
  void run(raw_ostream &OS);

private:
  const RecordKeeper &RK;
  const CodeGenDAGPatterns CGP;
  const CodeGenTarget &Target;

  /// Keep track of the equivalence between SDNodes and Instruction.
  /// This is defined using 'GINodeEquiv' in the target description.
  DenseMap<Record *, const CodeGenInstruction *> NodeEquivs;

  void gatherNodeEquivs();
  const CodeGenInstruction *findNodeEquiv(Record *N);

  struct SkipReason {
    std::string Reason;
  };

  /// Analyze pattern \p P, possibly emitting matching code for it to \p OS.
  /// Otherwise, return a reason why this pattern was skipped for emission.
  Optional<SkipReason> runOnPattern(const PatternToMatch &P,
                                    raw_ostream &OS);
};

} // end anonymous namespace

//===- Helper functions ---------------------------------------------------===//

/// Convert an MVT to an equivalent LLT if possible, or the invalid LLT() for
/// MVTs that don't map cleanly to an LLT (e.g., iPTR, *any, ...).
static Optional<std::string> MVTToLLT(MVT::SimpleValueType SVT) {
  std::string TyStr;
  raw_string_ostream OS(TyStr);
  MVT VT(SVT);
  if (VT.isVector() && VT.getVectorNumElements() != 1) {
    OS << "LLT::vector(" << VT.getVectorNumElements() << ", "
       << VT.getScalarSizeInBits() << ")";
  } else if (VT.isInteger() || VT.isFloatingPoint()) {
    OS << "LLT::scalar(" << VT.getSizeInBits() << ")";
  } else {
    return None;
  }
  OS.flush();
  return TyStr;
}

static bool isTrivialOperatorNode(const TreePatternNode *N) {
  return !N->isLeaf() && !N->hasAnyPredicate() && !N->getTransformFn();
}

//===- Matchers -----------------------------------------------------------===//

struct MatchAction {
  virtual ~MatchAction() {}
  virtual void emit(raw_ostream &OS) const = 0;
};

raw_ostream &operator<<(raw_ostream &S, const MatchAction &A) {
  A.emit(S);
  return S;
}

template <class PredicateTy> class PredicateListMatcher {
private:
  typedef std::vector<std::unique_ptr<PredicateTy>> PredicateVec;
  PredicateVec Predicates;

public:
  /// Construct a new operand predicate and add it to the matcher.
  template <class Kind, class... Args>
  Kind &addPredicate(Args&&... args) {
    Predicates.emplace_back(
        llvm::make_unique<Kind>(std::forward<Args>(args)...));
    return *static_cast<Kind *>(Predicates.back().get());
  }

  typename PredicateVec::const_iterator predicates_begin() const { return Predicates.begin(); }
  typename PredicateVec::const_iterator predicates_end() const { return Predicates.end(); }
  iterator_range<typename PredicateVec::const_iterator> predicates() const {
    return make_range(predicates_begin(), predicates_end());
  }

  /// Emit a C++ expression that tests whether all the predicates are met.
  template <class... Args>
  void emitCxxPredicatesExpr(raw_ostream &OS, Args &&... args) const {
    if (Predicates.empty()) {
      OS << "true";
      return;
    }

    StringRef Separator = "";
    for (const auto &Predicate : predicates()) {
      OS << Separator << "(";
      Predicate->emitCxxPredicateExpr(OS, std::forward<Args>(args)...);
      OS << ")";
      Separator = " && ";
    }
  }
};

/// Generates code to check a predicate of an operand.
///
/// Typical predicates include:
/// * Operand is a particular register.
/// * Operand is assigned a particular register bank.
/// * Operand is an MBB.
class OperandPredicateMatcher {
public:
  virtual ~OperandPredicateMatcher() {}

  /// Emit a C++ expression that checks the predicate for the OpIdx operand of
  /// the instruction given in InsnVarName.
  virtual void emitCxxPredicateExpr(raw_ostream &OS,
                                    const StringRef InsnVarName,
                                    unsigned OpIdx) const = 0;
};

/// Generates code to check that an operand is a particular LLT.
class LLTOperandMatcher : public OperandPredicateMatcher {
protected:
  std::string Ty;

public:
  LLTOperandMatcher(std::string Ty) : Ty(Ty) {}

  void emitCxxPredicateExpr(raw_ostream &OS, const StringRef InsnVarName,
                            unsigned OpIdx) const override {
    OS << "MRI.getType(" << InsnVarName << ".getOperand(" << OpIdx
       << ").getReg()) == (" << Ty << ")";
  }
};

/// Generates code to check that an operand is in a particular register bank.
class RegisterBankOperandMatcher : public OperandPredicateMatcher {
protected:
  const CodeGenRegisterClass &RC;

public:
  RegisterBankOperandMatcher(const CodeGenRegisterClass &RC) : RC(RC) {}

  void emitCxxPredicateExpr(raw_ostream &OS, const StringRef InsnVarName,
                            unsigned OpIdx) const override {
    OS << "(&RBI.getRegBankFromRegClass(" << RC.getQualifiedName()
       << "RegClass) == RBI.getRegBank(" << InsnVarName << ".getOperand("
       << OpIdx << ").getReg(), MRI, TRI))";
  }
};

/// Generates code to check that an operand is a basic block.
class MBBOperandMatcher : public OperandPredicateMatcher {
public:
  void emitCxxPredicateExpr(raw_ostream &OS, const StringRef InsnVarName,
                            unsigned OpIdx) const override {
    OS << InsnVarName << ".getOperand(" << OpIdx << ").isMBB()";
  }
};

/// Generates code to check that a set of predicates match for a particular
/// operand.
class OperandMatcher : public PredicateListMatcher<OperandPredicateMatcher> {
protected:
  unsigned OpIdx;

public:
  OperandMatcher(unsigned OpIdx) : OpIdx(OpIdx) {}

  /// Emit a C++ expression that tests whether the instruction named in
  /// InsnVarName matches all the predicate and all the operands.
  void emitCxxPredicateExpr(raw_ostream &OS, const StringRef InsnVarName) const {
    OS << "(";
    emitCxxPredicatesExpr(OS, InsnVarName, OpIdx);
    OS << ")";
  }
};

/// Generates code to check a predicate on an instruction.
///
/// Typical predicates include:
/// * The opcode of the instruction is a particular value.
/// * The nsw/nuw flag is/isn't set.
class InstructionPredicateMatcher {
public:
  virtual ~InstructionPredicateMatcher() {}

  /// Emit a C++ expression that tests whether the instruction named in
  /// InsnVarName matches the predicate.
  virtual void emitCxxPredicateExpr(raw_ostream &OS,
                                    const StringRef InsnVarName) const = 0;
};

/// Generates code to check the opcode of an instruction.
class InstructionOpcodeMatcher : public InstructionPredicateMatcher {
protected:
  const CodeGenInstruction *I;

public:
  InstructionOpcodeMatcher(const CodeGenInstruction *I) : I(I) {}

  void emitCxxPredicateExpr(raw_ostream &OS,
                            const StringRef InsnVarName) const override {
    OS << InsnVarName << ".getOpcode() == " << I->Namespace
       << "::" << I->TheDef->getName();
  }
};

/// Generates code to check that a set of predicates and operands match for a
/// particular instruction.
///
/// Typical predicates include:
/// * Has a specific opcode.
/// * Has an nsw/nuw flag or doesn't.
class InstructionMatcher
    : public PredicateListMatcher<InstructionPredicateMatcher> {
protected:
  std::vector<OperandMatcher> Operands;

public:
  /// Add an operand to the matcher.
  OperandMatcher &addOperand(unsigned OpIdx) {
    Operands.emplace_back(OpIdx);
    return Operands.back();
  }

  /// Emit a C++ expression that tests whether the instruction named in
  /// InsnVarName matches all the predicates and all the operands.
  void emitCxxPredicateExpr(raw_ostream &OS, const StringRef InsnVarName) const {
    emitCxxPredicatesExpr(OS, InsnVarName);
    for (const auto &Operand : Operands) {
      OS << " && (";
      Operand.emitCxxPredicateExpr(OS, InsnVarName);
      OS << ")";
    }
  }
};

struct MutateOpcode : public MatchAction {
  MutateOpcode(const CodeGenInstruction *I) : I(I) {}
  const CodeGenInstruction *I;

  virtual void emit(raw_ostream &OS) const {
    OS << "I.setDesc(TII.get(" << I->Namespace << "::" << I->TheDef->getName()
       << "));";
  }
};

/// Generates code to check that a match rule matches.
///
/// This currently supports a single match position but could be extended to
/// support multiple positions to support div/rem fusion or load-multiple
/// instructions.
class RuleMatcher {
  const PatternToMatch &P;

  std::vector<std::unique_ptr<InstructionMatcher>> Matchers;

public:
  std::vector<std::unique_ptr<MatchAction>> Actions;

  RuleMatcher(const PatternToMatch &P) : P(P) {}

  InstructionMatcher &addInstructionMatcher() {
    Matchers.emplace_back(new InstructionMatcher());
    return *Matchers.back();
  }

  void emit(raw_ostream &OS) {
    if (Matchers.empty())
      llvm_unreachable("Unexpected empty matcher!");

    OS << "  // Src: " << *P.getSrcPattern() << "\n"
       << "  // Dst: " << *P.getDstPattern() << "\n";

    // The representation supports rules that require multiple roots such as:
    //    %ptr(p0) = ...
    //    %elt0(s32) = G_LOAD %ptr
    //    %1(p0) = G_ADD %ptr, 4
    //    %elt1(s32) = G_LOAD p0 %1
    // which could be usefully folded into:
    //    %ptr(p0) = ...
    //    %elt0(s32), %elt1(s32) = TGT_LOAD_PAIR %ptr
    // on some targets but we don't need to make use of that yet.
    assert(Matchers.size() == 1 && "Cannot handle multi-root matchers yet");
    OS << "  if (";
    Matchers.front()->emitCxxPredicateExpr(OS, "I");
    OS << ") {\n";

    for (auto &MA : Actions)
      OS << "    " << *MA << "\n";

    OS << "    constrainSelectedInstRegOperands(I, TII, TRI, RBI);\n";
    OS << "    return true;\n";
    OS << "  }\n";
  }
};

//===- GlobalISelEmitter class --------------------------------------------===//

void GlobalISelEmitter::gatherNodeEquivs() {
  assert(NodeEquivs.empty());
  for (Record *Equiv : RK.getAllDerivedDefinitions("GINodeEquiv"))
    NodeEquivs[Equiv->getValueAsDef("Node")] =
        &Target.getInstruction(Equiv->getValueAsDef("I"));
}

const CodeGenInstruction *GlobalISelEmitter::findNodeEquiv(Record *N) {
  return NodeEquivs.lookup(N);
}

GlobalISelEmitter::GlobalISelEmitter(RecordKeeper &RK)
    : RK(RK), CGP(RK), Target(CGP.getTargetInfo()) {}

//===- Emitter ------------------------------------------------------------===//

Optional<GlobalISelEmitter::SkipReason>
GlobalISelEmitter::runOnPattern(const PatternToMatch &P, raw_ostream &OS) {

  // Keep track of the matchers and actions to emit.
  RuleMatcher M(P);

  // First, analyze the whole pattern.
  // If the entire pattern has a predicate (e.g., target features), ignore it.
  if (!P.getPredicates()->getValues().empty())
    return SkipReason{"Pattern has a predicate"};

  // Physreg imp-defs require additional logic.  Ignore the pattern.
  if (!P.getDstRegs().empty())
    return SkipReason{"Pattern defines a physical register"};

  // Next, analyze the pattern operators.
  TreePatternNode *Src = P.getSrcPattern();
  TreePatternNode *Dst = P.getDstPattern();

  // If the root of either pattern isn't a simple operator, ignore it.
  if (!isTrivialOperatorNode(Dst))
    return SkipReason{"Dst pattern root isn't a trivial operator"};
  if (!isTrivialOperatorNode(Src))
    return SkipReason{"Src pattern root isn't a trivial operator"};

  Record *DstOp = Dst->getOperator();
  if (!DstOp->isSubClassOf("Instruction"))
    return SkipReason{"Pattern operator isn't an instruction"};

  auto &DstI = Target.getInstruction(DstOp);

  auto SrcGIOrNull = findNodeEquiv(Src->getOperator());
  if (!SrcGIOrNull)
    return SkipReason{"Pattern operator lacks an equivalent Instruction"};
  auto &SrcGI = *SrcGIOrNull;

  // The operators look good: match the opcode and mutate it to the new one.
  InstructionMatcher &InsnMatcher = M.addInstructionMatcher();
  InsnMatcher.addPredicate<InstructionOpcodeMatcher>(&SrcGI);
  M.Actions.emplace_back(new MutateOpcode(&DstI));

  // Next, analyze the children, only accepting patterns that don't require
  // any change to operands.
  if (Src->getNumChildren() != Dst->getNumChildren())
    return SkipReason{"Src/dst patterns have a different # of children"};

  unsigned OpIdx = 0;

  // Start with the defined operands (i.e., the results of the root operator).
  if (DstI.Operands.NumDefs != Src->getExtTypes().size())
    return SkipReason{"Src pattern results and dst MI defs are different"};

  for (const EEVT::TypeSet &Ty : Src->getExtTypes()) {
    Record *DstIOpRec = DstI.Operands[OpIdx].Rec;
    if (!DstIOpRec->isSubClassOf("RegisterClass"))
      return SkipReason{"Dst MI def isn't a register class"};

    auto OpTyOrNone = MVTToLLT(Ty.getConcrete());
    if (!OpTyOrNone)
      return SkipReason{"Dst operand has an unsupported type"};

    OperandMatcher &OM = InsnMatcher.addOperand(OpIdx);
    OM.addPredicate<LLTOperandMatcher>(*OpTyOrNone);
    OM.addPredicate<RegisterBankOperandMatcher>(
        Target.getRegisterClass(DstIOpRec));
    ++OpIdx;
  }

  // Finally match the used operands (i.e., the children of the root operator).
  for (unsigned i = 0, e = Src->getNumChildren(); i != e; ++i) {
    auto *SrcChild = Src->getChild(i);
    auto *DstChild = Dst->getChild(i);

    // Patterns can reorder operands.  Ignore those for now.
    if (SrcChild->getName() != DstChild->getName())
      return SkipReason{"Src/dst pattern children not in same order"};

    // The only non-leaf child we accept is 'bb': it's an operator because
    // BasicBlockSDNode isn't inline, but in MI it's just another operand.
    if (!SrcChild->isLeaf()) {
      if (DstChild->isLeaf() ||
          SrcChild->getOperator() != DstChild->getOperator())
        return SkipReason{"Src/dst pattern child operator mismatch"};

      if (SrcChild->getOperator()->isSubClassOf("SDNode")) {
        auto &ChildSDNI = CGP.getSDNodeInfo(SrcChild->getOperator());
        if (ChildSDNI.getSDClassName() == "BasicBlockSDNode") {
          InsnMatcher.addOperand(OpIdx++).addPredicate<MBBOperandMatcher>();
          continue;
        }
      }
      return SkipReason{"Src pattern child isn't a leaf node"};
    }

    if (SrcChild->getLeafValue() != DstChild->getLeafValue())
      return SkipReason{"Src/dst pattern child leaf mismatch"};

    // Otherwise, we're looking for a bog-standard RegisterClass operand.
    if (SrcChild->hasAnyPredicate())
      return SkipReason{"Src pattern child has predicate"};
    auto *ChildRec = cast<DefInit>(SrcChild->getLeafValue())->getDef();
    if (!ChildRec->isSubClassOf("RegisterClass"))
      return SkipReason{"Src pattern child isn't a RegisterClass"};

    ArrayRef<EEVT::TypeSet> ChildTypes = SrcChild->getExtTypes();
    if (ChildTypes.size() != 1)
      return SkipReason{"Src pattern child has multiple results"};

    auto OpTyOrNone = MVTToLLT(ChildTypes.front().getConcrete());
    if (!OpTyOrNone)
      return SkipReason{"Src operand has an unsupported type"};

    OperandMatcher &OM = InsnMatcher.addOperand(OpIdx);
    OM.addPredicate<LLTOperandMatcher>(*OpTyOrNone);
    OM.addPredicate<RegisterBankOperandMatcher>(
        Target.getRegisterClass(ChildRec));
    ++OpIdx;
  }

  // We're done with this pattern!  Emit the processed result.
  M.emit(OS);
  ++NumPatternEmitted;
  return None;
}

void GlobalISelEmitter::run(raw_ostream &OS) {
  // Track the GINodeEquiv definitions.
  gatherNodeEquivs();

  emitSourceFileHeader(("Global Instruction Selector for the " +
                       Target.getName() + " target").str(), OS);
  OS << "bool " << Target.getName()
     << "InstructionSelector::selectImpl"
        "(MachineInstr &I) const {\n  const MachineRegisterInfo &MRI = "
        "I.getParent()->getParent()->getRegInfo();\n";

  // Look through the SelectionDAG patterns we found, possibly emitting some.
  for (const PatternToMatch &Pat : CGP.ptms()) {
    ++NumPatternTotal;
    if (auto SkipReason = runOnPattern(Pat, OS)) {
      if (WarnOnSkippedPatterns) {
        PrintWarning(Pat.getSrcRecord()->getLoc(),
                     "Skipped pattern: " + SkipReason->Reason);
      }
      ++NumPatternSkipped;
    }
  }

  OS << "  return false;\n}\n";
}

//===----------------------------------------------------------------------===//

namespace llvm {
void EmitGlobalISel(RecordKeeper &RK, raw_ostream &OS) {
  GlobalISelEmitter(RK).run(OS);
}
} // End llvm namespace
