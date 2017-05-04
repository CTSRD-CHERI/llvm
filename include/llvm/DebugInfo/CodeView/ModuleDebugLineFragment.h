//===- ModuleDebugLineFragment.h --------------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_DEBUGINFO_CODEVIEW_MODULEDEBUGLINEFRAGMENT_H
#define LLVM_DEBUGINFO_CODEVIEW_MODULEDEBUGLINEFRAGMENT_H

#include "llvm/DebugInfo/CodeView/Line.h"
#include "llvm/DebugInfo/CodeView/ModuleDebugFragment.h"
#include "llvm/Support/BinaryStreamArray.h"
#include "llvm/Support/BinaryStreamReader.h"
#include "llvm/Support/Error.h"

namespace llvm {
namespace codeview {

// Corresponds to the `CV_DebugSLinesHeader_t` structure.
struct LineFragmentHeader {
  support::ulittle32_t RelocOffset;  // Code offset of line contribution.
  support::ulittle16_t RelocSegment; // Code segment of line contribution.
  support::ulittle16_t Flags;        // See LineFlags enumeration.
  support::ulittle32_t CodeSize;     // Code size of this line contribution.
};

// Corresponds to the `CV_DebugSLinesFileBlockHeader_t` structure.
struct LineBlockFragmentHeader {
  support::ulittle32_t NameIndex; // Offset of FileChecksum entry in File
                                  // checksums buffer.  The checksum entry then
                                  // contains another offset into the string
                                  // table of the actual name.
  support::ulittle32_t NumLines;  // Number of lines
  support::ulittle32_t BlockSize; // Code size of block, in bytes.
  // The following two variable length arrays appear immediately after the
  // header.  The structure definitions follow.
  // LineNumberEntry   Lines[NumLines];
  // ColumnNumberEntry Columns[NumLines];
};

// Corresponds to `CV_Line_t` structure
struct LineNumberEntry {
  support::ulittle32_t Offset; // Offset to start of code bytes for line number
  support::ulittle32_t Flags;  // Start:24, End:7, IsStatement:1
};

// Corresponds to `CV_Column_t` structure
struct ColumnNumberEntry {
  support::ulittle16_t StartColumn;
  support::ulittle16_t EndColumn;
};

struct LineColumnEntry {
  support::ulittle32_t NameIndex;
  FixedStreamArray<LineNumberEntry> LineNumbers;
  FixedStreamArray<ColumnNumberEntry> Columns;
};

class LineColumnExtractor {
public:
  typedef const LineFragmentHeader ContextType;

  static Error extract(BinaryStreamRef Stream, uint32_t &Len,
                       LineColumnEntry &Item, const LineFragmentHeader *Header);
};

class ModuleDebugLineFragmentRef final : public ModuleDebugFragmentRef {
  friend class LineColumnExtractor;
  typedef VarStreamArray<LineColumnEntry, LineColumnExtractor> LineInfoArray;
  typedef LineInfoArray::Iterator Iterator;

public:
  ModuleDebugLineFragmentRef();

  static bool classof(const ModuleDebugFragmentRef *S) {
    return S->kind() == ModuleDebugFragmentKind::Lines;
  }

  Error initialize(BinaryStreamReader Reader);

  Iterator begin() const { return LinesAndColumns.begin(); }
  Iterator end() const { return LinesAndColumns.end(); }

  const LineFragmentHeader *header() const { return Header; }

  bool hasColumnInfo() const;

private:
  const LineFragmentHeader *Header = nullptr;
  LineInfoArray LinesAndColumns;
};

class ModuleDebugLineFragment final : public ModuleDebugFragment {
  struct Block {
    Block(uint32_t ChecksumBufferOffset)
        : ChecksumBufferOffset(ChecksumBufferOffset) {}

    uint32_t ChecksumBufferOffset;
    std::vector<LineNumberEntry> Lines;
    std::vector<ColumnNumberEntry> Columns;
  };

public:
  ModuleDebugLineFragment();

  static bool classof(const ModuleDebugFragment *S) {
    return S->kind() == ModuleDebugFragmentKind::Lines;
  }

  void createBlock(uint32_t ChecksumBufferOffset);
  void addLineInfo(uint32_t Offset, const LineInfo &Line);
  void addLineAndColumnInfo(uint32_t Offset, const LineInfo &Line,
                            uint32_t ColStart, uint32_t ColEnd);

  uint32_t calculateSerializedLength() override;
  Error commit(BinaryStreamWriter &Writer) override;

  void setRelocationAddress(uint16_t Segment, uint16_t Offset);
  void setCodeSize(uint32_t Size);
  void setFlags(LineFlags Flags);

  bool hasColumnInfo() const;

private:
  uint16_t RelocOffset = 0;
  uint16_t RelocSegment = 0;
  uint32_t CodeSize = 0;
  LineFlags Flags = LF_None;
  std::vector<Block> Blocks;
};
}
}

#endif
