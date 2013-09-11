//===-- MipsSEISelLowering.cpp - MipsSE DAG Lowering Interface --*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Subclass of MipsTargetLowering specialized for mips32/64.
//
//===----------------------------------------------------------------------===//
#include "MipsSEISelLowering.h"
#include "MipsRegisterInfo.h"
#include "MipsTargetMachine.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Target/TargetInstrInfo.h"

using namespace llvm;

static cl::opt<bool>
EnableMipsTailCalls("enable-mips-tail-calls", cl::Hidden,
                    cl::desc("MIPS: Enable tail calls."), cl::init(false));

static cl::opt<bool> NoDPLoadStore("mno-ldc1-sdc1", cl::init(false),
                                   cl::desc("Expand double precision loads and "
                                            "stores to their single precision "
                                            "counterparts"));

MipsSETargetLowering::MipsSETargetLowering(MipsTargetMachine &TM)
  : MipsTargetLowering(TM) {
  // Set up the register classes

  clearRegisterClasses();

  addRegisterClass(MVT::i32, &Mips::GPR32RegClass);

  if (IsGP64bit)
    addRegisterClass(MVT::i64, &Mips::GPR64RegClass);

  if (Subtarget->hasDSP()) {
    MVT::SimpleValueType VecTys[2] = {MVT::v2i16, MVT::v4i8};

    for (unsigned i = 0; i < array_lengthof(VecTys); ++i) {
      addRegisterClass(VecTys[i], &Mips::DSPRRegClass);

      // Expand all builtin opcodes.
      for (unsigned Opc = 0; Opc < ISD::BUILTIN_OP_END; ++Opc)
        setOperationAction(Opc, VecTys[i], Expand);

      setOperationAction(ISD::ADD, VecTys[i], Legal);
      setOperationAction(ISD::SUB, VecTys[i], Legal);
      setOperationAction(ISD::LOAD, VecTys[i], Legal);
      setOperationAction(ISD::STORE, VecTys[i], Legal);
      setOperationAction(ISD::BITCAST, VecTys[i], Legal);
    }

    // Expand all truncating stores and extending loads.
    unsigned FirstVT = (unsigned)MVT::FIRST_VECTOR_VALUETYPE;
    unsigned LastVT = (unsigned)MVT::LAST_VECTOR_VALUETYPE;

    for (unsigned VT0 = FirstVT; VT0 <= LastVT; ++VT0) {
      for (unsigned VT1 = FirstVT; VT1 <= LastVT; ++VT1)
        setTruncStoreAction((MVT::SimpleValueType)VT0,
                            (MVT::SimpleValueType)VT1, Expand);

      setLoadExtAction(ISD::SEXTLOAD, (MVT::SimpleValueType)VT0, Expand);
      setLoadExtAction(ISD::ZEXTLOAD, (MVT::SimpleValueType)VT0, Expand);
      setLoadExtAction(ISD::EXTLOAD, (MVT::SimpleValueType)VT0, Expand);
    }

    setTargetDAGCombine(ISD::SHL);
    setTargetDAGCombine(ISD::SRA);
    setTargetDAGCombine(ISD::SRL);
    setTargetDAGCombine(ISD::SETCC);
    setTargetDAGCombine(ISD::VSELECT);
  }

  if (Subtarget->hasDSPR2())
    setOperationAction(ISD::MUL, MVT::v2i16, Legal);

  if (Subtarget->hasMSA()) {
    addMSAIntType(MVT::v16i8, &Mips::MSA128BRegClass);
    addMSAIntType(MVT::v8i16, &Mips::MSA128HRegClass);
    addMSAIntType(MVT::v4i32, &Mips::MSA128WRegClass);
    addMSAIntType(MVT::v2i64, &Mips::MSA128DRegClass);
    addMSAFloatType(MVT::v8f16, &Mips::MSA128HRegClass);
    addMSAFloatType(MVT::v4f32, &Mips::MSA128WRegClass);
    addMSAFloatType(MVT::v2f64, &Mips::MSA128DRegClass);
  }

  if (!Subtarget->mipsSEUsesSoftFloat()) {
    addRegisterClass(MVT::f32, &Mips::FGR32RegClass);

    // When dealing with single precision only, use libcalls
    if (!Subtarget->isSingleFloat()) {
      if (Subtarget->isFP64bit())
        addRegisterClass(MVT::f64, &Mips::FGR64RegClass);
      else
        addRegisterClass(MVT::f64, &Mips::AFGR64RegClass);
    }
  }

  setOperationAction(ISD::SMUL_LOHI,          MVT::i32, Custom);
  setOperationAction(ISD::UMUL_LOHI,          MVT::i32, Custom);
  setOperationAction(ISD::MULHS,              MVT::i32, Custom);
  setOperationAction(ISD::MULHU,              MVT::i32, Custom);

  if (IsGP64bit) {
    setOperationAction(ISD::MULHS,            MVT::i64, Custom);
    setOperationAction(ISD::MULHU,            MVT::i64, Custom);
    setOperationAction(ISD::MUL,              MVT::i64, Custom);
  }

  setOperationAction(ISD::INTRINSIC_WO_CHAIN, MVT::i64, Custom);
  setOperationAction(ISD::INTRINSIC_W_CHAIN,  MVT::i64, Custom);

  setOperationAction(ISD::SDIVREM, MVT::i32, Custom);
  setOperationAction(ISD::UDIVREM, MVT::i32, Custom);
  setOperationAction(ISD::SDIVREM, MVT::i64, Custom);
  setOperationAction(ISD::UDIVREM, MVT::i64, Custom);
  setOperationAction(ISD::ATOMIC_FENCE,       MVT::Other, Custom);
  setOperationAction(ISD::LOAD,               MVT::i32, Custom);
  setOperationAction(ISD::STORE,              MVT::i32, Custom);

  setTargetDAGCombine(ISD::ADDE);
  setTargetDAGCombine(ISD::SUBE);
  setTargetDAGCombine(ISD::MUL);

  setOperationAction(ISD::INTRINSIC_WO_CHAIN, MVT::Other, Custom);
  setOperationAction(ISD::INTRINSIC_W_CHAIN, MVT::Other, Custom);
  setOperationAction(ISD::INTRINSIC_VOID, MVT::Other, Custom);

  if (NoDPLoadStore) {
    setOperationAction(ISD::LOAD, MVT::f64, Custom);
    setOperationAction(ISD::STORE, MVT::f64, Custom);
  }

  computeRegisterProperties();
}

const MipsTargetLowering *
llvm::createMipsSETargetLowering(MipsTargetMachine &TM) {
  return new MipsSETargetLowering(TM);
}

void MipsSETargetLowering::
addMSAIntType(MVT::SimpleValueType Ty, const TargetRegisterClass *RC) {
  addRegisterClass(Ty, RC);

  // Expand all builtin opcodes.
  for (unsigned Opc = 0; Opc < ISD::BUILTIN_OP_END; ++Opc)
    setOperationAction(Opc, Ty, Expand);

  setOperationAction(ISD::BITCAST, Ty, Legal);
  setOperationAction(ISD::LOAD, Ty, Legal);
  setOperationAction(ISD::STORE, Ty, Legal);

  setOperationAction(ISD::ADD, Ty, Legal);
  setOperationAction(ISD::CTLZ, Ty, Legal);
  setOperationAction(ISD::MUL, Ty, Legal);
  setOperationAction(ISD::SDIV, Ty, Legal);
  setOperationAction(ISD::SHL, Ty, Legal);
  setOperationAction(ISD::SRA, Ty, Legal);
  setOperationAction(ISD::SRL, Ty, Legal);
  setOperationAction(ISD::SUB, Ty, Legal);
  setOperationAction(ISD::UDIV, Ty, Legal);
}

void MipsSETargetLowering::
addMSAFloatType(MVT::SimpleValueType Ty, const TargetRegisterClass *RC) {
  addRegisterClass(Ty, RC);

  // Expand all builtin opcodes.
  for (unsigned Opc = 0; Opc < ISD::BUILTIN_OP_END; ++Opc)
    setOperationAction(Opc, Ty, Expand);

  setOperationAction(ISD::LOAD, Ty, Legal);
  setOperationAction(ISD::STORE, Ty, Legal);
  setOperationAction(ISD::BITCAST, Ty, Legal);

  if (Ty != MVT::v8f16) {
    setOperationAction(ISD::FADD,  Ty, Legal);
    setOperationAction(ISD::FDIV,  Ty, Legal);
    setOperationAction(ISD::FLOG2, Ty, Legal);
    setOperationAction(ISD::FMUL,  Ty, Legal);
    setOperationAction(ISD::FRINT, Ty, Legal);
    setOperationAction(ISD::FSQRT, Ty, Legal);
    setOperationAction(ISD::FSUB,  Ty, Legal);
  }
}

bool
MipsSETargetLowering::allowsUnalignedMemoryAccesses(EVT VT, bool *Fast) const {
  MVT::SimpleValueType SVT = VT.getSimpleVT().SimpleTy;

  switch (SVT) {
  case MVT::i64:
  case MVT::i32:
    if (Fast)
      *Fast = true;
    return true;
  default:
    return false;
  }
}

SDValue MipsSETargetLowering::LowerOperation(SDValue Op,
                                             SelectionDAG &DAG) const {
  switch(Op.getOpcode()) {
  case ISD::LOAD:  return lowerLOAD(Op, DAG);
  case ISD::STORE: return lowerSTORE(Op, DAG);
  case ISD::SMUL_LOHI: return lowerMulDiv(Op, MipsISD::Mult, true, true, DAG);
  case ISD::UMUL_LOHI: return lowerMulDiv(Op, MipsISD::Multu, true, true, DAG);
  case ISD::MULHS:     return lowerMulDiv(Op, MipsISD::Mult, false, true, DAG);
  case ISD::MULHU:     return lowerMulDiv(Op, MipsISD::Multu, false, true, DAG);
  case ISD::MUL:       return lowerMulDiv(Op, MipsISD::Mult, true, false, DAG);
  case ISD::SDIVREM:   return lowerMulDiv(Op, MipsISD::DivRem, true, true, DAG);
  case ISD::UDIVREM:   return lowerMulDiv(Op, MipsISD::DivRemU, true, true,
                                          DAG);
  case ISD::INTRINSIC_WO_CHAIN: return lowerINTRINSIC_WO_CHAIN(Op, DAG);
  case ISD::INTRINSIC_W_CHAIN:  return lowerINTRINSIC_W_CHAIN(Op, DAG);
  case ISD::INTRINSIC_VOID:     return lowerINTRINSIC_VOID(Op, DAG);
  }

  return MipsTargetLowering::LowerOperation(Op, DAG);
}

// selectMADD -
// Transforms a subgraph in CurDAG if the following pattern is found:
//  (addc multLo, Lo0), (adde multHi, Hi0),
// where,
//  multHi/Lo: product of multiplication
//  Lo0: initial value of Lo register
//  Hi0: initial value of Hi register
// Return true if pattern matching was successful.
static bool selectMADD(SDNode *ADDENode, SelectionDAG *CurDAG) {
  // ADDENode's second operand must be a flag output of an ADDC node in order
  // for the matching to be successful.
  SDNode *ADDCNode = ADDENode->getOperand(2).getNode();

  if (ADDCNode->getOpcode() != ISD::ADDC)
    return false;

  SDValue MultHi = ADDENode->getOperand(0);
  SDValue MultLo = ADDCNode->getOperand(0);
  SDNode *MultNode = MultHi.getNode();
  unsigned MultOpc = MultHi.getOpcode();

  // MultHi and MultLo must be generated by the same node,
  if (MultLo.getNode() != MultNode)
    return false;

  // and it must be a multiplication.
  if (MultOpc != ISD::SMUL_LOHI && MultOpc != ISD::UMUL_LOHI)
    return false;

  // MultLo amd MultHi must be the first and second output of MultNode
  // respectively.
  if (MultHi.getResNo() != 1 || MultLo.getResNo() != 0)
    return false;

  // Transform this to a MADD only if ADDENode and ADDCNode are the only users
  // of the values of MultNode, in which case MultNode will be removed in later
  // phases.
  // If there exist users other than ADDENode or ADDCNode, this function returns
  // here, which will result in MultNode being mapped to a single MULT
  // instruction node rather than a pair of MULT and MADD instructions being
  // produced.
  if (!MultHi.hasOneUse() || !MultLo.hasOneUse())
    return false;

  SDLoc DL(ADDENode);

  // Initialize accumulator.
  SDValue ACCIn = CurDAG->getNode(MipsISD::InsertLOHI, DL, MVT::Untyped,
                                  ADDCNode->getOperand(1),
                                  ADDENode->getOperand(1));

  // create MipsMAdd(u) node
  MultOpc = MultOpc == ISD::UMUL_LOHI ? MipsISD::MAddu : MipsISD::MAdd;

  SDValue MAdd = CurDAG->getNode(MultOpc, DL, MVT::Untyped,
                                 MultNode->getOperand(0),// Factor 0
                                 MultNode->getOperand(1),// Factor 1
                                 ACCIn);

  // replace uses of adde and addc here
  if (!SDValue(ADDCNode, 0).use_empty()) {
    SDValue LoIdx = CurDAG->getConstant(Mips::sub_lo, MVT::i32);
    SDValue LoOut = CurDAG->getNode(MipsISD::ExtractLOHI, DL, MVT::i32, MAdd,
                                    LoIdx);
    CurDAG->ReplaceAllUsesOfValueWith(SDValue(ADDCNode, 0), LoOut);
  }
  if (!SDValue(ADDENode, 0).use_empty()) {
    SDValue HiIdx = CurDAG->getConstant(Mips::sub_hi, MVT::i32);
    SDValue HiOut = CurDAG->getNode(MipsISD::ExtractLOHI, DL, MVT::i32, MAdd,
                                    HiIdx);
    CurDAG->ReplaceAllUsesOfValueWith(SDValue(ADDENode, 0), HiOut);
  }

  return true;
}

// selectMSUB -
// Transforms a subgraph in CurDAG if the following pattern is found:
//  (addc Lo0, multLo), (sube Hi0, multHi),
// where,
//  multHi/Lo: product of multiplication
//  Lo0: initial value of Lo register
//  Hi0: initial value of Hi register
// Return true if pattern matching was successful.
static bool selectMSUB(SDNode *SUBENode, SelectionDAG *CurDAG) {
  // SUBENode's second operand must be a flag output of an SUBC node in order
  // for the matching to be successful.
  SDNode *SUBCNode = SUBENode->getOperand(2).getNode();

  if (SUBCNode->getOpcode() != ISD::SUBC)
    return false;

  SDValue MultHi = SUBENode->getOperand(1);
  SDValue MultLo = SUBCNode->getOperand(1);
  SDNode *MultNode = MultHi.getNode();
  unsigned MultOpc = MultHi.getOpcode();

  // MultHi and MultLo must be generated by the same node,
  if (MultLo.getNode() != MultNode)
    return false;

  // and it must be a multiplication.
  if (MultOpc != ISD::SMUL_LOHI && MultOpc != ISD::UMUL_LOHI)
    return false;

  // MultLo amd MultHi must be the first and second output of MultNode
  // respectively.
  if (MultHi.getResNo() != 1 || MultLo.getResNo() != 0)
    return false;

  // Transform this to a MSUB only if SUBENode and SUBCNode are the only users
  // of the values of MultNode, in which case MultNode will be removed in later
  // phases.
  // If there exist users other than SUBENode or SUBCNode, this function returns
  // here, which will result in MultNode being mapped to a single MULT
  // instruction node rather than a pair of MULT and MSUB instructions being
  // produced.
  if (!MultHi.hasOneUse() || !MultLo.hasOneUse())
    return false;

  SDLoc DL(SUBENode);

  // Initialize accumulator.
  SDValue ACCIn = CurDAG->getNode(MipsISD::InsertLOHI, DL, MVT::Untyped,
                                  SUBCNode->getOperand(0),
                                  SUBENode->getOperand(0));

  // create MipsSub(u) node
  MultOpc = MultOpc == ISD::UMUL_LOHI ? MipsISD::MSubu : MipsISD::MSub;

  SDValue MSub = CurDAG->getNode(MultOpc, DL, MVT::Glue,
                                 MultNode->getOperand(0),// Factor 0
                                 MultNode->getOperand(1),// Factor 1
                                 ACCIn);

  // replace uses of sube and subc here
  if (!SDValue(SUBCNode, 0).use_empty()) {
    SDValue LoIdx = CurDAG->getConstant(Mips::sub_lo, MVT::i32);
    SDValue LoOut = CurDAG->getNode(MipsISD::ExtractLOHI, DL, MVT::i32, MSub,
                                    LoIdx);
    CurDAG->ReplaceAllUsesOfValueWith(SDValue(SUBCNode, 0), LoOut);
  }
  if (!SDValue(SUBENode, 0).use_empty()) {
    SDValue HiIdx = CurDAG->getConstant(Mips::sub_hi, MVT::i32);
    SDValue HiOut = CurDAG->getNode(MipsISD::ExtractLOHI, DL, MVT::i32, MSub,
                                    HiIdx);
    CurDAG->ReplaceAllUsesOfValueWith(SDValue(SUBENode, 0), HiOut);
  }

  return true;
}

static SDValue performADDECombine(SDNode *N, SelectionDAG &DAG,
                                  TargetLowering::DAGCombinerInfo &DCI,
                                  const MipsSubtarget *Subtarget) {
  if (DCI.isBeforeLegalize())
    return SDValue();

  if (Subtarget->hasMips32() && N->getValueType(0) == MVT::i32 &&
      selectMADD(N, &DAG))
    return SDValue(N, 0);

  return SDValue();
}

static SDValue performSUBECombine(SDNode *N, SelectionDAG &DAG,
                                  TargetLowering::DAGCombinerInfo &DCI,
                                  const MipsSubtarget *Subtarget) {
  if (DCI.isBeforeLegalize())
    return SDValue();

  if (Subtarget->hasMips32() && N->getValueType(0) == MVT::i32 &&
      selectMSUB(N, &DAG))
    return SDValue(N, 0);

  return SDValue();
}

static SDValue genConstMult(SDValue X, uint64_t C, SDLoc DL, EVT VT,
                            EVT ShiftTy, SelectionDAG &DAG) {
  // Clear the upper (64 - VT.sizeInBits) bits.
  C &= ((uint64_t)-1) >> (64 - VT.getSizeInBits());

  // Return 0.
  if (C == 0)
    return DAG.getConstant(0, VT);

  // Return x.
  if (C == 1)
    return X;

  // If c is power of 2, return (shl x, log2(c)).
  if (isPowerOf2_64(C))
    return DAG.getNode(ISD::SHL, DL, VT, X,
                       DAG.getConstant(Log2_64(C), ShiftTy));

  unsigned Log2Ceil = Log2_64_Ceil(C);
  uint64_t Floor = 1LL << Log2_64(C);
  uint64_t Ceil = Log2Ceil == 64 ? 0LL : 1LL << Log2Ceil;

  // If |c - floor_c| <= |c - ceil_c|,
  // where floor_c = pow(2, floor(log2(c))) and ceil_c = pow(2, ceil(log2(c))),
  // return (add constMult(x, floor_c), constMult(x, c - floor_c)).
  if (C - Floor <= Ceil - C) {
    SDValue Op0 = genConstMult(X, Floor, DL, VT, ShiftTy, DAG);
    SDValue Op1 = genConstMult(X, C - Floor, DL, VT, ShiftTy, DAG);
    return DAG.getNode(ISD::ADD, DL, VT, Op0, Op1);
  }

  // If |c - floor_c| > |c - ceil_c|,
  // return (sub constMult(x, ceil_c), constMult(x, ceil_c - c)).
  SDValue Op0 = genConstMult(X, Ceil, DL, VT, ShiftTy, DAG);
  SDValue Op1 = genConstMult(X, Ceil - C, DL, VT, ShiftTy, DAG);
  return DAG.getNode(ISD::SUB, DL, VT, Op0, Op1);
}

static SDValue performMULCombine(SDNode *N, SelectionDAG &DAG,
                                 const TargetLowering::DAGCombinerInfo &DCI,
                                 const MipsSETargetLowering *TL) {
  EVT VT = N->getValueType(0);

  if (ConstantSDNode *C = dyn_cast<ConstantSDNode>(N->getOperand(1)))
    if (!VT.isVector())
      return genConstMult(N->getOperand(0), C->getZExtValue(), SDLoc(N),
                          VT, TL->getScalarShiftAmountTy(VT), DAG);

  return SDValue(N, 0);
}

static SDValue performDSPShiftCombine(unsigned Opc, SDNode *N, EVT Ty,
                                      SelectionDAG &DAG,
                                      const MipsSubtarget *Subtarget) {
  // See if this is a vector splat immediate node.
  APInt SplatValue, SplatUndef;
  unsigned SplatBitSize;
  bool HasAnyUndefs;
  unsigned EltSize = Ty.getVectorElementType().getSizeInBits();
  BuildVectorSDNode *BV = dyn_cast<BuildVectorSDNode>(N->getOperand(1));

  if (!BV ||
      !BV->isConstantSplat(SplatValue, SplatUndef, SplatBitSize, HasAnyUndefs,
                           EltSize, !Subtarget->isLittle()) ||
      (SplatBitSize != EltSize) ||
      (SplatValue.getZExtValue() >= EltSize))
    return SDValue();

  return DAG.getNode(Opc, SDLoc(N), Ty, N->getOperand(0),
                     DAG.getConstant(SplatValue.getZExtValue(), MVT::i32));
}

static SDValue performSHLCombine(SDNode *N, SelectionDAG &DAG,
                                 TargetLowering::DAGCombinerInfo &DCI,
                                 const MipsSubtarget *Subtarget) {
  EVT Ty = N->getValueType(0);

  if ((Ty != MVT::v2i16) && (Ty != MVT::v4i8))
    return SDValue();

  return performDSPShiftCombine(MipsISD::SHLL_DSP, N, Ty, DAG, Subtarget);
}

static SDValue performSRACombine(SDNode *N, SelectionDAG &DAG,
                                 TargetLowering::DAGCombinerInfo &DCI,
                                 const MipsSubtarget *Subtarget) {
  EVT Ty = N->getValueType(0);

  if ((Ty != MVT::v2i16) && ((Ty != MVT::v4i8) || !Subtarget->hasDSPR2()))
    return SDValue();

  return performDSPShiftCombine(MipsISD::SHRA_DSP, N, Ty, DAG, Subtarget);
}


static SDValue performSRLCombine(SDNode *N, SelectionDAG &DAG,
                                 TargetLowering::DAGCombinerInfo &DCI,
                                 const MipsSubtarget *Subtarget) {
  EVT Ty = N->getValueType(0);

  if (((Ty != MVT::v2i16) || !Subtarget->hasDSPR2()) && (Ty != MVT::v4i8))
    return SDValue();

  return performDSPShiftCombine(MipsISD::SHRL_DSP, N, Ty, DAG, Subtarget);
}

static bool isLegalDSPCondCode(EVT Ty, ISD::CondCode CC) {
  bool IsV216 = (Ty == MVT::v2i16);

  switch (CC) {
  case ISD::SETEQ:
  case ISD::SETNE:  return true;
  case ISD::SETLT:
  case ISD::SETLE:
  case ISD::SETGT:
  case ISD::SETGE:  return IsV216;
  case ISD::SETULT:
  case ISD::SETULE:
  case ISD::SETUGT:
  case ISD::SETUGE: return !IsV216;
  default:          return false;
  }
}

static SDValue performSETCCCombine(SDNode *N, SelectionDAG &DAG) {
  EVT Ty = N->getValueType(0);

  if ((Ty != MVT::v2i16) && (Ty != MVT::v4i8))
    return SDValue();

  if (!isLegalDSPCondCode(Ty, cast<CondCodeSDNode>(N->getOperand(2))->get()))
    return SDValue();

  return DAG.getNode(MipsISD::SETCC_DSP, SDLoc(N), Ty, N->getOperand(0),
                     N->getOperand(1), N->getOperand(2));
}

static SDValue performVSELECTCombine(SDNode *N, SelectionDAG &DAG) {
  EVT Ty = N->getValueType(0);

  if ((Ty != MVT::v2i16) && (Ty != MVT::v4i8))
    return SDValue();

  SDValue SetCC = N->getOperand(0);

  if (SetCC.getOpcode() != MipsISD::SETCC_DSP)
    return SDValue();

  return DAG.getNode(MipsISD::SELECT_CC_DSP, SDLoc(N), Ty,
                     SetCC.getOperand(0), SetCC.getOperand(1), N->getOperand(1),
                     N->getOperand(2), SetCC.getOperand(2));
}

SDValue
MipsSETargetLowering::PerformDAGCombine(SDNode *N, DAGCombinerInfo &DCI) const {
  SelectionDAG &DAG = DCI.DAG;
  SDValue Val;

  switch (N->getOpcode()) {
  case ISD::ADDE:
    return performADDECombine(N, DAG, DCI, Subtarget);
  case ISD::SUBE:
    return performSUBECombine(N, DAG, DCI, Subtarget);
  case ISD::MUL:
    return performMULCombine(N, DAG, DCI, this);
  case ISD::SHL:
    return performSHLCombine(N, DAG, DCI, Subtarget);
  case ISD::SRA:
    return performSRACombine(N, DAG, DCI, Subtarget);
  case ISD::SRL:
    return performSRLCombine(N, DAG, DCI, Subtarget);
  case ISD::VSELECT:
    return performVSELECTCombine(N, DAG);
  case ISD::SETCC: {
    Val = performSETCCCombine(N, DAG);
    break;
  }
  }

  if (Val.getNode())
    return Val;

  return MipsTargetLowering::PerformDAGCombine(N, DCI);
}

MachineBasicBlock *
MipsSETargetLowering::EmitInstrWithCustomInserter(MachineInstr *MI,
                                                  MachineBasicBlock *BB) const {
  switch (MI->getOpcode()) {
  default:
    return MipsTargetLowering::EmitInstrWithCustomInserter(MI, BB);
  case Mips::BPOSGE32_PSEUDO:
    return emitBPOSGE32(MI, BB);
  case Mips::SNZ_B_PSEUDO:
    return emitMSACBranchPseudo(MI, BB, Mips::BNZ_B);
  case Mips::SNZ_H_PSEUDO:
    return emitMSACBranchPseudo(MI, BB, Mips::BNZ_H);
  case Mips::SNZ_W_PSEUDO:
    return emitMSACBranchPseudo(MI, BB, Mips::BNZ_W);
  case Mips::SNZ_D_PSEUDO:
    return emitMSACBranchPseudo(MI, BB, Mips::BNZ_D);
  case Mips::SNZ_V_PSEUDO:
    return emitMSACBranchPseudo(MI, BB, Mips::BNZ_V);
  case Mips::SZ_B_PSEUDO:
    return emitMSACBranchPseudo(MI, BB, Mips::BZ_B);
  case Mips::SZ_H_PSEUDO:
    return emitMSACBranchPseudo(MI, BB, Mips::BZ_H);
  case Mips::SZ_W_PSEUDO:
    return emitMSACBranchPseudo(MI, BB, Mips::BZ_W);
  case Mips::SZ_D_PSEUDO:
    return emitMSACBranchPseudo(MI, BB, Mips::BZ_D);
  case Mips::SZ_V_PSEUDO:
    return emitMSACBranchPseudo(MI, BB, Mips::BZ_V);
  }
}

bool MipsSETargetLowering::
isEligibleForTailCallOptimization(const MipsCC &MipsCCInfo,
                                  unsigned NextStackOffset,
                                  const MipsFunctionInfo& FI) const {
  if (!EnableMipsTailCalls)
    return false;

  // Return false if either the callee or caller has a byval argument.
  if (MipsCCInfo.hasByValArg() || FI.hasByvalArg())
    return false;

  // Return true if the callee's argument area is no larger than the
  // caller's.
  return NextStackOffset <= FI.getIncomingArgSize();
}

void MipsSETargetLowering::
getOpndList(SmallVectorImpl<SDValue> &Ops,
            std::deque< std::pair<unsigned, SDValue> > &RegsToPass,
            bool IsPICCall, bool GlobalOrExternal, bool InternalLinkage,
            CallLoweringInfo &CLI, SDValue Callee, SDValue Chain) const {
  // T9 should contain the address of the callee function if
  // -reloction-model=pic or it is an indirect call.
  if (IsPICCall || !GlobalOrExternal) {
    unsigned T9Reg = IsN64 ? Mips::T9_64 : Mips::T9;
    RegsToPass.push_front(std::make_pair(T9Reg, Callee));
  } else
    Ops.push_back(Callee);

  MipsTargetLowering::getOpndList(Ops, RegsToPass, IsPICCall, GlobalOrExternal,
                                  InternalLinkage, CLI, Callee, Chain);
}

SDValue MipsSETargetLowering::lowerLOAD(SDValue Op, SelectionDAG &DAG) const {
  LoadSDNode &Nd = *cast<LoadSDNode>(Op);

  if (Nd.getMemoryVT() != MVT::f64 || !NoDPLoadStore)
    return MipsTargetLowering::lowerLOAD(Op, DAG);

  // Replace a double precision load with two i32 loads and a buildpair64.
  SDLoc DL(Op);
  SDValue Ptr = Nd.getBasePtr(), Chain = Nd.getChain();
  EVT PtrVT = Ptr.getValueType();

  // i32 load from lower address.
  SDValue Lo = DAG.getLoad(MVT::i32, DL, Chain, Ptr,
                           MachinePointerInfo(), Nd.isVolatile(),
                           Nd.isNonTemporal(), Nd.isInvariant(),
                           Nd.getAlignment());

  // i32 load from higher address.
  Ptr = DAG.getNode(ISD::ADD, DL, PtrVT, Ptr, DAG.getConstant(4, PtrVT));
  SDValue Hi = DAG.getLoad(MVT::i32, DL, Lo.getValue(1), Ptr,
                           MachinePointerInfo(), Nd.isVolatile(),
                           Nd.isNonTemporal(), Nd.isInvariant(),
                           std::min(Nd.getAlignment(), 4U));

  if (!Subtarget->isLittle())
    std::swap(Lo, Hi);

  SDValue BP = DAG.getNode(MipsISD::BuildPairF64, DL, MVT::f64, Lo, Hi);
  SDValue Ops[2] = {BP, Hi.getValue(1)};
  return DAG.getMergeValues(Ops, 2, DL);
}

SDValue MipsSETargetLowering::lowerSTORE(SDValue Op, SelectionDAG &DAG) const {
  StoreSDNode &Nd = *cast<StoreSDNode>(Op);

  if (Nd.getMemoryVT() != MVT::f64 || !NoDPLoadStore)
    return MipsTargetLowering::lowerSTORE(Op, DAG);

  // Replace a double precision store with two extractelement64s and i32 stores.
  SDLoc DL(Op);
  SDValue Val = Nd.getValue(), Ptr = Nd.getBasePtr(), Chain = Nd.getChain();
  EVT PtrVT = Ptr.getValueType();
  SDValue Lo = DAG.getNode(MipsISD::ExtractElementF64, DL, MVT::i32,
                           Val, DAG.getConstant(0, MVT::i32));
  SDValue Hi = DAG.getNode(MipsISD::ExtractElementF64, DL, MVT::i32,
                           Val, DAG.getConstant(1, MVT::i32));

  if (!Subtarget->isLittle())
    std::swap(Lo, Hi);

  // i32 store to lower address.
  Chain = DAG.getStore(Chain, DL, Lo, Ptr, MachinePointerInfo(),
                       Nd.isVolatile(), Nd.isNonTemporal(), Nd.getAlignment(),
                       Nd.getTBAAInfo());

  // i32 store to higher address.
  Ptr = DAG.getNode(ISD::ADD, DL, PtrVT, Ptr, DAG.getConstant(4, PtrVT));
  return DAG.getStore(Chain, DL, Hi, Ptr, MachinePointerInfo(),
                      Nd.isVolatile(), Nd.isNonTemporal(),
                      std::min(Nd.getAlignment(), 4U), Nd.getTBAAInfo());
}

SDValue MipsSETargetLowering::lowerMulDiv(SDValue Op, unsigned NewOpc,
                                          bool HasLo, bool HasHi,
                                          SelectionDAG &DAG) const {
  EVT Ty = Op.getOperand(0).getValueType();
  SDLoc DL(Op);
  SDValue Mult = DAG.getNode(NewOpc, DL, MVT::Untyped,
                             Op.getOperand(0), Op.getOperand(1));
  SDValue Lo, Hi;

  if (HasLo)
    Lo = DAG.getNode(MipsISD::ExtractLOHI, DL, Ty, Mult,
                     DAG.getConstant(Mips::sub_lo, MVT::i32));
  if (HasHi)
    Hi = DAG.getNode(MipsISD::ExtractLOHI, DL, Ty, Mult,
                     DAG.getConstant(Mips::sub_hi, MVT::i32));

  if (!HasLo || !HasHi)
    return HasLo ? Lo : Hi;

  SDValue Vals[] = { Lo, Hi };
  return DAG.getMergeValues(Vals, 2, DL);
}


static SDValue initAccumulator(SDValue In, SDLoc DL, SelectionDAG &DAG) {
  SDValue InLo = DAG.getNode(ISD::EXTRACT_ELEMENT, DL, MVT::i32, In,
                             DAG.getConstant(0, MVT::i32));
  SDValue InHi = DAG.getNode(ISD::EXTRACT_ELEMENT, DL, MVT::i32, In,
                             DAG.getConstant(1, MVT::i32));
  return DAG.getNode(MipsISD::InsertLOHI, DL, MVT::Untyped, InLo, InHi);
}

static SDValue extractLOHI(SDValue Op, SDLoc DL, SelectionDAG &DAG) {
  SDValue Lo = DAG.getNode(MipsISD::ExtractLOHI, DL, MVT::i32, Op,
                           DAG.getConstant(Mips::sub_lo, MVT::i32));
  SDValue Hi = DAG.getNode(MipsISD::ExtractLOHI, DL, MVT::i32, Op,
                           DAG.getConstant(Mips::sub_hi, MVT::i32));
  return DAG.getNode(ISD::BUILD_PAIR, DL, MVT::i64, Lo, Hi);
}

// This function expands mips intrinsic nodes which have 64-bit input operands
// or output values.
//
// out64 = intrinsic-node in64
// =>
// lo = copy (extract-element (in64, 0))
// hi = copy (extract-element (in64, 1))
// mips-specific-node
// v0 = copy lo
// v1 = copy hi
// out64 = merge-values (v0, v1)
//
static SDValue lowerDSPIntr(SDValue Op, SelectionDAG &DAG, unsigned Opc) {
  SDLoc DL(Op);
  bool HasChainIn = Op->getOperand(0).getValueType() == MVT::Other;
  SmallVector<SDValue, 3> Ops;
  unsigned OpNo = 0;

  // See if Op has a chain input.
  if (HasChainIn)
    Ops.push_back(Op->getOperand(OpNo++));

  // The next operand is the intrinsic opcode.
  assert(Op->getOperand(OpNo).getOpcode() == ISD::TargetConstant);

  // See if the next operand has type i64.
  SDValue Opnd = Op->getOperand(++OpNo), In64;

  if (Opnd.getValueType() == MVT::i64)
    In64 = initAccumulator(Opnd, DL, DAG);
  else
    Ops.push_back(Opnd);

  // Push the remaining operands.
  for (++OpNo ; OpNo < Op->getNumOperands(); ++OpNo)
    Ops.push_back(Op->getOperand(OpNo));

  // Add In64 to the end of the list.
  if (In64.getNode())
    Ops.push_back(In64);

  // Scan output.
  SmallVector<EVT, 2> ResTys;

  for (SDNode::value_iterator I = Op->value_begin(), E = Op->value_end();
       I != E; ++I)
    ResTys.push_back((*I == MVT::i64) ? MVT::Untyped : *I);

  // Create node.
  SDValue Val = DAG.getNode(Opc, DL, ResTys, &Ops[0], Ops.size());
  SDValue Out = (ResTys[0] == MVT::Untyped) ? extractLOHI(Val, DL, DAG) : Val;

  if (!HasChainIn)
    return Out;

  assert(Val->getValueType(1) == MVT::Other);
  SDValue Vals[] = { Out, SDValue(Val.getNode(), 1) };
  return DAG.getMergeValues(Vals, 2, DL);
}

static SDValue lowerMSABinaryIntr(SDValue Op, SelectionDAG &DAG, unsigned Opc) {
  SDLoc DL(Op);
  SDValue LHS = Op->getOperand(1);
  SDValue RHS = Op->getOperand(2);
  EVT ResTy = Op->getValueType(0);

  SDValue Result = DAG.getNode(Opc, DL, ResTy, LHS, RHS);

  return Result;
}

static SDValue lowerMSABranchIntr(SDValue Op, SelectionDAG &DAG, unsigned Opc) {
  SDLoc DL(Op);
  SDValue Value = Op->getOperand(1);
  EVT ResTy = Op->getValueType(0);

  SDValue Result = DAG.getNode(Opc, DL, ResTy, Value);

  return Result;
}

static SDValue lowerMSAUnaryIntr(SDValue Op, SelectionDAG &DAG, unsigned Opc) {
  SDLoc DL(Op);
  SDValue Value = Op->getOperand(1);
  EVT ResTy = Op->getValueType(0);

  SDValue Result = DAG.getNode(Opc, DL, ResTy, Value);

  return Result;
}

SDValue MipsSETargetLowering::lowerINTRINSIC_WO_CHAIN(SDValue Op,
                                                      SelectionDAG &DAG) const {
  switch (cast<ConstantSDNode>(Op->getOperand(0))->getZExtValue()) {
  default:
    return SDValue();
  case Intrinsic::mips_shilo:
    return lowerDSPIntr(Op, DAG, MipsISD::SHILO);
  case Intrinsic::mips_dpau_h_qbl:
    return lowerDSPIntr(Op, DAG, MipsISD::DPAU_H_QBL);
  case Intrinsic::mips_dpau_h_qbr:
    return lowerDSPIntr(Op, DAG, MipsISD::DPAU_H_QBR);
  case Intrinsic::mips_dpsu_h_qbl:
    return lowerDSPIntr(Op, DAG, MipsISD::DPSU_H_QBL);
  case Intrinsic::mips_dpsu_h_qbr:
    return lowerDSPIntr(Op, DAG, MipsISD::DPSU_H_QBR);
  case Intrinsic::mips_dpa_w_ph:
    return lowerDSPIntr(Op, DAG, MipsISD::DPA_W_PH);
  case Intrinsic::mips_dps_w_ph:
    return lowerDSPIntr(Op, DAG, MipsISD::DPS_W_PH);
  case Intrinsic::mips_dpax_w_ph:
    return lowerDSPIntr(Op, DAG, MipsISD::DPAX_W_PH);
  case Intrinsic::mips_dpsx_w_ph:
    return lowerDSPIntr(Op, DAG, MipsISD::DPSX_W_PH);
  case Intrinsic::mips_mulsa_w_ph:
    return lowerDSPIntr(Op, DAG, MipsISD::MULSA_W_PH);
  case Intrinsic::mips_mult:
    return lowerDSPIntr(Op, DAG, MipsISD::Mult);
  case Intrinsic::mips_multu:
    return lowerDSPIntr(Op, DAG, MipsISD::Multu);
  case Intrinsic::mips_madd:
    return lowerDSPIntr(Op, DAG, MipsISD::MAdd);
  case Intrinsic::mips_maddu:
    return lowerDSPIntr(Op, DAG, MipsISD::MAddu);
  case Intrinsic::mips_msub:
    return lowerDSPIntr(Op, DAG, MipsISD::MSub);
  case Intrinsic::mips_msubu:
    return lowerDSPIntr(Op, DAG, MipsISD::MSubu);
  case Intrinsic::mips_addv_b:
  case Intrinsic::mips_addv_h:
  case Intrinsic::mips_addv_w:
  case Intrinsic::mips_addv_d:
    return lowerMSABinaryIntr(Op, DAG, ISD::ADD);
  case Intrinsic::mips_bnz_b:
  case Intrinsic::mips_bnz_h:
  case Intrinsic::mips_bnz_w:
  case Intrinsic::mips_bnz_d:
    return lowerMSABranchIntr(Op, DAG, MipsISD::VALL_NONZERO);
  case Intrinsic::mips_bnz_v:
    return lowerMSABranchIntr(Op, DAG, MipsISD::VANY_NONZERO);
  case Intrinsic::mips_bz_b:
  case Intrinsic::mips_bz_h:
  case Intrinsic::mips_bz_w:
  case Intrinsic::mips_bz_d:
    return lowerMSABranchIntr(Op, DAG, MipsISD::VALL_ZERO);
  case Intrinsic::mips_bz_v:
    return lowerMSABranchIntr(Op, DAG, MipsISD::VANY_ZERO);
  case Intrinsic::mips_div_s_b:
  case Intrinsic::mips_div_s_h:
  case Intrinsic::mips_div_s_w:
  case Intrinsic::mips_div_s_d:
    return lowerMSABinaryIntr(Op, DAG, ISD::SDIV);
  case Intrinsic::mips_div_u_b:
  case Intrinsic::mips_div_u_h:
  case Intrinsic::mips_div_u_w:
  case Intrinsic::mips_div_u_d:
    return lowerMSABinaryIntr(Op, DAG, ISD::UDIV);
  case Intrinsic::mips_fadd_w:
  case Intrinsic::mips_fadd_d:
    return lowerMSABinaryIntr(Op, DAG, ISD::FADD);
  case Intrinsic::mips_fdiv_w:
  case Intrinsic::mips_fdiv_d:
    return lowerMSABinaryIntr(Op, DAG, ISD::FDIV);
  case Intrinsic::mips_flog2_w:
  case Intrinsic::mips_flog2_d:
    return lowerMSAUnaryIntr(Op, DAG, ISD::FLOG2);
  case Intrinsic::mips_fmul_w:
  case Intrinsic::mips_fmul_d:
    return lowerMSABinaryIntr(Op, DAG, ISD::FMUL);
  case Intrinsic::mips_frint_w:
  case Intrinsic::mips_frint_d:
    return lowerMSAUnaryIntr(Op, DAG, ISD::FRINT);
  case Intrinsic::mips_fsqrt_w:
  case Intrinsic::mips_fsqrt_d:
    return lowerMSAUnaryIntr(Op, DAG, ISD::FSQRT);
  case Intrinsic::mips_fsub_w:
  case Intrinsic::mips_fsub_d:
    return lowerMSABinaryIntr(Op, DAG, ISD::FSUB);
  case Intrinsic::mips_mulv_b:
  case Intrinsic::mips_mulv_h:
  case Intrinsic::mips_mulv_w:
  case Intrinsic::mips_mulv_d:
    return lowerMSABinaryIntr(Op, DAG, ISD::MUL);
  case Intrinsic::mips_nlzc_b:
  case Intrinsic::mips_nlzc_h:
  case Intrinsic::mips_nlzc_w:
  case Intrinsic::mips_nlzc_d:
    return lowerMSAUnaryIntr(Op, DAG, ISD::CTLZ);
  case Intrinsic::mips_sll_b:
  case Intrinsic::mips_sll_h:
  case Intrinsic::mips_sll_w:
  case Intrinsic::mips_sll_d:
    return lowerMSABinaryIntr(Op, DAG, ISD::SHL);
  case Intrinsic::mips_sra_b:
  case Intrinsic::mips_sra_h:
  case Intrinsic::mips_sra_w:
  case Intrinsic::mips_sra_d:
    return lowerMSABinaryIntr(Op, DAG, ISD::SRA);
  case Intrinsic::mips_srl_b:
  case Intrinsic::mips_srl_h:
  case Intrinsic::mips_srl_w:
  case Intrinsic::mips_srl_d:
    return lowerMSABinaryIntr(Op, DAG, ISD::SRL);
  case Intrinsic::mips_subv_b:
  case Intrinsic::mips_subv_h:
  case Intrinsic::mips_subv_w:
  case Intrinsic::mips_subv_d:
    return lowerMSABinaryIntr(Op, DAG, ISD::SUB);
  }
}

static SDValue lowerMSALoadIntr(SDValue Op, SelectionDAG &DAG, unsigned Intr) {
  SDLoc DL(Op);
  SDValue ChainIn = Op->getOperand(0);
  SDValue Address = Op->getOperand(2);
  SDValue Offset  = Op->getOperand(3);
  EVT ResTy = Op->getValueType(0);
  EVT PtrTy = Address->getValueType(0);

  Address = DAG.getNode(ISD::ADD, DL, PtrTy, Address, Offset);

  return DAG.getLoad(ResTy, DL, ChainIn, Address, MachinePointerInfo(), false,
                     false, false, 16);
}

SDValue MipsSETargetLowering::lowerINTRINSIC_W_CHAIN(SDValue Op,
                                                     SelectionDAG &DAG) const {
  unsigned Intr = cast<ConstantSDNode>(Op->getOperand(1))->getZExtValue();
  switch (Intr) {
  default:
    return SDValue();
  case Intrinsic::mips_extp:
    return lowerDSPIntr(Op, DAG, MipsISD::EXTP);
  case Intrinsic::mips_extpdp:
    return lowerDSPIntr(Op, DAG, MipsISD::EXTPDP);
  case Intrinsic::mips_extr_w:
    return lowerDSPIntr(Op, DAG, MipsISD::EXTR_W);
  case Intrinsic::mips_extr_r_w:
    return lowerDSPIntr(Op, DAG, MipsISD::EXTR_R_W);
  case Intrinsic::mips_extr_rs_w:
    return lowerDSPIntr(Op, DAG, MipsISD::EXTR_RS_W);
  case Intrinsic::mips_extr_s_h:
    return lowerDSPIntr(Op, DAG, MipsISD::EXTR_S_H);
  case Intrinsic::mips_mthlip:
    return lowerDSPIntr(Op, DAG, MipsISD::MTHLIP);
  case Intrinsic::mips_mulsaq_s_w_ph:
    return lowerDSPIntr(Op, DAG, MipsISD::MULSAQ_S_W_PH);
  case Intrinsic::mips_maq_s_w_phl:
    return lowerDSPIntr(Op, DAG, MipsISD::MAQ_S_W_PHL);
  case Intrinsic::mips_maq_s_w_phr:
    return lowerDSPIntr(Op, DAG, MipsISD::MAQ_S_W_PHR);
  case Intrinsic::mips_maq_sa_w_phl:
    return lowerDSPIntr(Op, DAG, MipsISD::MAQ_SA_W_PHL);
  case Intrinsic::mips_maq_sa_w_phr:
    return lowerDSPIntr(Op, DAG, MipsISD::MAQ_SA_W_PHR);
  case Intrinsic::mips_dpaq_s_w_ph:
    return lowerDSPIntr(Op, DAG, MipsISD::DPAQ_S_W_PH);
  case Intrinsic::mips_dpsq_s_w_ph:
    return lowerDSPIntr(Op, DAG, MipsISD::DPSQ_S_W_PH);
  case Intrinsic::mips_dpaq_sa_l_w:
    return lowerDSPIntr(Op, DAG, MipsISD::DPAQ_SA_L_W);
  case Intrinsic::mips_dpsq_sa_l_w:
    return lowerDSPIntr(Op, DAG, MipsISD::DPSQ_SA_L_W);
  case Intrinsic::mips_dpaqx_s_w_ph:
    return lowerDSPIntr(Op, DAG, MipsISD::DPAQX_S_W_PH);
  case Intrinsic::mips_dpaqx_sa_w_ph:
    return lowerDSPIntr(Op, DAG, MipsISD::DPAQX_SA_W_PH);
  case Intrinsic::mips_dpsqx_s_w_ph:
    return lowerDSPIntr(Op, DAG, MipsISD::DPSQX_S_W_PH);
  case Intrinsic::mips_dpsqx_sa_w_ph:
    return lowerDSPIntr(Op, DAG, MipsISD::DPSQX_SA_W_PH);
  case Intrinsic::mips_ld_b:
  case Intrinsic::mips_ld_h:
  case Intrinsic::mips_ld_w:
  case Intrinsic::mips_ld_d:
  case Intrinsic::mips_ldx_b:
  case Intrinsic::mips_ldx_h:
  case Intrinsic::mips_ldx_w:
  case Intrinsic::mips_ldx_d:
   return lowerMSALoadIntr(Op, DAG, Intr);
  }
}

static SDValue lowerMSAStoreIntr(SDValue Op, SelectionDAG &DAG, unsigned Intr) {
  SDLoc DL(Op);
  SDValue ChainIn = Op->getOperand(0);
  SDValue Value   = Op->getOperand(2);
  SDValue Address = Op->getOperand(3);
  SDValue Offset  = Op->getOperand(4);
  EVT PtrTy = Address->getValueType(0);

  Address = DAG.getNode(ISD::ADD, DL, PtrTy, Address, Offset);

  return DAG.getStore(ChainIn, DL, Value, Address, MachinePointerInfo(), false,
                      false, 16);
}

SDValue MipsSETargetLowering::lowerINTRINSIC_VOID(SDValue Op,
                                                  SelectionDAG &DAG) const {
  unsigned Intr = cast<ConstantSDNode>(Op->getOperand(1))->getZExtValue();
  switch (Intr) {
  default:
    return SDValue();
  case Intrinsic::mips_st_b:
  case Intrinsic::mips_st_h:
  case Intrinsic::mips_st_w:
  case Intrinsic::mips_st_d:
  case Intrinsic::mips_stx_b:
  case Intrinsic::mips_stx_h:
  case Intrinsic::mips_stx_w:
  case Intrinsic::mips_stx_d:
    return lowerMSAStoreIntr(Op, DAG, Intr);
  }
}

MachineBasicBlock * MipsSETargetLowering::
emitBPOSGE32(MachineInstr *MI, MachineBasicBlock *BB) const{
  // $bb:
  //  bposge32_pseudo $vr0
  //  =>
  // $bb:
  //  bposge32 $tbb
  // $fbb:
  //  li $vr2, 0
  //  b $sink
  // $tbb:
  //  li $vr1, 1
  // $sink:
  //  $vr0 = phi($vr2, $fbb, $vr1, $tbb)

  MachineRegisterInfo &RegInfo = BB->getParent()->getRegInfo();
  const TargetInstrInfo *TII = getTargetMachine().getInstrInfo();
  const TargetRegisterClass *RC = &Mips::GPR32RegClass;
  DebugLoc DL = MI->getDebugLoc();
  const BasicBlock *LLVM_BB = BB->getBasicBlock();
  MachineFunction::iterator It = llvm::next(MachineFunction::iterator(BB));
  MachineFunction *F = BB->getParent();
  MachineBasicBlock *FBB = F->CreateMachineBasicBlock(LLVM_BB);
  MachineBasicBlock *TBB = F->CreateMachineBasicBlock(LLVM_BB);
  MachineBasicBlock *Sink  = F->CreateMachineBasicBlock(LLVM_BB);
  F->insert(It, FBB);
  F->insert(It, TBB);
  F->insert(It, Sink);

  // Transfer the remainder of BB and its successor edges to Sink.
  Sink->splice(Sink->begin(), BB, llvm::next(MachineBasicBlock::iterator(MI)),
               BB->end());
  Sink->transferSuccessorsAndUpdatePHIs(BB);

  // Add successors.
  BB->addSuccessor(FBB);
  BB->addSuccessor(TBB);
  FBB->addSuccessor(Sink);
  TBB->addSuccessor(Sink);

  // Insert the real bposge32 instruction to $BB.
  BuildMI(BB, DL, TII->get(Mips::BPOSGE32)).addMBB(TBB);

  // Fill $FBB.
  unsigned VR2 = RegInfo.createVirtualRegister(RC);
  BuildMI(*FBB, FBB->end(), DL, TII->get(Mips::ADDiu), VR2)
    .addReg(Mips::ZERO).addImm(0);
  BuildMI(*FBB, FBB->end(), DL, TII->get(Mips::B)).addMBB(Sink);

  // Fill $TBB.
  unsigned VR1 = RegInfo.createVirtualRegister(RC);
  BuildMI(*TBB, TBB->end(), DL, TII->get(Mips::ADDiu), VR1)
    .addReg(Mips::ZERO).addImm(1);

  // Insert phi function to $Sink.
  BuildMI(*Sink, Sink->begin(), DL, TII->get(Mips::PHI),
          MI->getOperand(0).getReg())
    .addReg(VR2).addMBB(FBB).addReg(VR1).addMBB(TBB);

  MI->eraseFromParent();   // The pseudo instruction is gone now.
  return Sink;
}

MachineBasicBlock * MipsSETargetLowering::
emitMSACBranchPseudo(MachineInstr *MI, MachineBasicBlock *BB,
                     unsigned BranchOp) const{
  // $bb:
  //  vany_nonzero $rd, $ws
  //  =>
  // $bb:
  //  bnz.b $ws, $tbb
  //  b $fbb
  // $fbb:
  //  li $rd1, 0
  //  b $sink
  // $tbb:
  //  li $rd2, 1
  // $sink:
  //  $rd = phi($rd1, $fbb, $rd2, $tbb)

  MachineRegisterInfo &RegInfo = BB->getParent()->getRegInfo();
  const TargetInstrInfo *TII = getTargetMachine().getInstrInfo();
  const TargetRegisterClass *RC = &Mips::GPR32RegClass;
  DebugLoc DL = MI->getDebugLoc();
  const BasicBlock *LLVM_BB = BB->getBasicBlock();
  MachineFunction::iterator It = llvm::next(MachineFunction::iterator(BB));
  MachineFunction *F = BB->getParent();
  MachineBasicBlock *FBB = F->CreateMachineBasicBlock(LLVM_BB);
  MachineBasicBlock *TBB = F->CreateMachineBasicBlock(LLVM_BB);
  MachineBasicBlock *Sink  = F->CreateMachineBasicBlock(LLVM_BB);
  F->insert(It, FBB);
  F->insert(It, TBB);
  F->insert(It, Sink);

  // Transfer the remainder of BB and its successor edges to Sink.
  Sink->splice(Sink->begin(), BB, llvm::next(MachineBasicBlock::iterator(MI)),
               BB->end());
  Sink->transferSuccessorsAndUpdatePHIs(BB);

  // Add successors.
  BB->addSuccessor(FBB);
  BB->addSuccessor(TBB);
  FBB->addSuccessor(Sink);
  TBB->addSuccessor(Sink);

  // Insert the real bnz.b instruction to $BB.
  BuildMI(BB, DL, TII->get(BranchOp))
    .addReg(MI->getOperand(1).getReg())
    .addMBB(TBB);

  // Fill $FBB.
  unsigned RD1 = RegInfo.createVirtualRegister(RC);
  BuildMI(*FBB, FBB->end(), DL, TII->get(Mips::ADDiu), RD1)
    .addReg(Mips::ZERO).addImm(0);
  BuildMI(*FBB, FBB->end(), DL, TII->get(Mips::B)).addMBB(Sink);

  // Fill $TBB.
  unsigned RD2 = RegInfo.createVirtualRegister(RC);
  BuildMI(*TBB, TBB->end(), DL, TII->get(Mips::ADDiu), RD2)
    .addReg(Mips::ZERO).addImm(1);

  // Insert phi function to $Sink.
  BuildMI(*Sink, Sink->begin(), DL, TII->get(Mips::PHI),
          MI->getOperand(0).getReg())
    .addReg(RD1).addMBB(FBB).addReg(RD2).addMBB(TBB);

  MI->eraseFromParent();   // The pseudo instruction is gone now.
  return Sink;
}
