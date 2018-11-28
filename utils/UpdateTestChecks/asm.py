import re
import sys

from . import common

if sys.version_info[0] > 2:
  class string:
    expandtabs = str.expandtabs
else:
  import string

# RegEx: this is where the magic happens.

##### Assembly parser

ASM_FUNCTION_X86_RE = re.compile(
    r'^_?(?P<func>[^:]+):[ \t]*#+[ \t]*@(?P=func)\n(?:\s*.Lfunc_begin[^:\n]*:\n)?[^:]*?'
    r'(?P<body>^##?[ \t]+[^:]+:.*?)\s*'
    r'^\s*(?:[^:\n]+?:\s*\n\s*\.size|\.cfi_endproc|\.globl|\.comm|\.(?:sub)?section|#+ -- End function)',
    flags=(re.M | re.S))

ASM_FUNCTION_ARM_RE = re.compile(
        r'^(?P<func>[0-9a-zA-Z_]+):\n' # f: (name of function)
        r'\s+\.fnstart\n' # .fnstart
        r'(?P<body>.*?)\n' # (body of the function)
        r'.Lfunc_end[0-9]+:', # .Lfunc_end0: or # -- End function
        flags=(re.M | re.S))

ASM_FUNCTION_AARCH64_RE = re.compile(
     r'^_?(?P<func>[^:]+):[ \t]*\/\/[ \t]*@(?P=func)\n'
     r'(?:[ \t]+.cfi_startproc\n)?'  # drop optional cfi noise 
     r'(?P<body>.*?)\n'
     # This list is incomplete
     r'.Lfunc_end[0-9]+:\n',
     flags=(re.M | re.S))

ASM_FUNCTION_AMDGPU_RE = re.compile(
    r'^_?(?P<func>[^:]+):[ \t]*;+[ \t]*@(?P=func)\n[^:]*?'
    r'(?P<body>.*?)\n' # (body of the function)
    # This list is incomplete
    r'.Lfunc_end[0-9]+:\n',
    flags=(re.M | re.S))

ASM_FUNCTION_MIPS_RE = re.compile(
    r'^_?(?P<func>[^:]+):[ \t]*#+[ \t]*@(?P=func)\n[^:]*?' # f: (name of func)
    r'(?:^[ \t]+\.(frame|f?mask|set).*?\n)+'  # Mips+LLVM standard asm prologue
    r'(?P<body>.*?)\n'                        # (body of the function)
    r'(?:^[ \t]+\.(set|end).*?\n)+'           # Mips+LLVM standard asm epilogue
    r'(\$|\.L)func_end[0-9]+:\n',             # $func_end0: (mips32 - O32) or
                                              # .Lfunc_end0: (mips64 - NewABI)
    flags=(re.M | re.S))

ASM_FUNCTION_PPC_RE = re.compile(
    r'^_?(?P<func>[^:]+):[ \t]*#+[ \t]*@(?P=func)\n'
    r'.*?'
    r'\.Lfunc_begin[0-9]+:\n'
    r'(?:[ \t]+.cfi_startproc\n)?'
    r'(?:\.Lfunc_[gl]ep[0-9]+:\n(?:[ \t]+.*?\n)*)*'
    r'(?P<body>.*?)\n'
    # This list is incomplete
    r'(?:^[ \t]*(?:\.long[ \t]+[^\n]+|\.quad[ \t]+[^\n]+)\n)*'
    r'.Lfunc_end[0-9]+:\n',
    flags=(re.M | re.S))

ASM_FUNCTION_RISCV_RE = re.compile(
    r'^_?(?P<func>[^:]+):[ \t]*#+[ \t]*@(?P=func)\n[^:]*?'
    r'(?P<body>^##?[ \t]+[^:]+:.*?)\s*'
    r'.Lfunc_end[0-9]+:\n',
    flags=(re.M | re.S))

ASM_FUNCTION_SPARC_RE = re.compile(
    r'^_?(?P<func>[^:]+):[ \t]*!+[ \t]*@(?P=func)\n'
    r'(?P<body>.*?)\s*'
    r'.Lfunc_end[0-9]+:\n',
    flags=(re.M | re.S))

ASM_FUNCTION_SYSTEMZ_RE = re.compile(
    r'^_?(?P<func>[^:]+):[ \t]*#+[ \t]*@(?P=func)\n'
    r'[ \t]+.cfi_startproc\n'
    r'(?P<body>.*?)\n'
    r'.Lfunc_end[0-9]+:\n',
    flags=(re.M | re.S))


SCRUB_LOOP_COMMENT_RE = re.compile(
    r'# =>This Inner Loop Header:.*|# in Loop:.*', flags=re.M)

SCRUB_X86_SHUFFLES_RE = (
    re.compile(
        r'^(\s*\w+) [^#\n]+#+ ((?:[xyz]mm\d+|mem)( \{%k\d+\}( \{z\})?)? = .*)$',
        flags=re.M))
SCRUB_X86_SPILL_RELOAD_RE = (
    re.compile(
        r'-?\d+\(%([er])[sb]p\)(.*(?:Spill|Reload))$',
        flags=re.M))
SCRUB_X86_SP_RE = re.compile(r'\d+\(%(esp|rsp)\)')
SCRUB_X86_RIP_RE = re.compile(r'[.\w]+\(%rip\)')
SCRUB_X86_LCP_RE = re.compile(r'\.LCPI[0-9]+_[0-9]+')
SCRUB_X86_RET_RE = re.compile(r'ret[l|q]')

def scrub_asm_x86(asm, args):
  # Scrub runs of whitespace out of the assembly, but leave the leading
  # whitespace in place.
  asm = common.SCRUB_WHITESPACE_RE.sub(r' ', asm)
  # Expand the tabs used for indentation.
  asm = string.expandtabs(asm, 2)
  # Detect shuffle asm comments and hide the operands in favor of the comments.
  asm = SCRUB_X86_SHUFFLES_RE.sub(r'\1 {{.*#+}} \2', asm)
  # Detect stack spills and reloads and hide their exact offset and whether
  # they used the stack pointer or frame pointer.
  asm = SCRUB_X86_SPILL_RELOAD_RE.sub(r'{{[-0-9]+}}(%\1{{[sb]}}p)\2', asm)
  # Generically match the stack offset of a memory operand.
  asm = SCRUB_X86_SP_RE.sub(r'{{[0-9]+}}(%\1)', asm)
  if getattr(args, 'x86_scrub_rip', False):
    # Generically match a RIP-relative memory operand.
    asm = SCRUB_X86_RIP_RE.sub(r'{{.*}}(%rip)', asm)
  # Generically match a LCP symbol.
  asm = SCRUB_X86_LCP_RE.sub(r'{{\.LCPI.*}}', asm)
  if getattr(args, 'extra_scrub', False):
    # Avoid generating different checks for 32- and 64-bit because of 'retl' vs 'retq'.
    asm = SCRUB_X86_RET_RE.sub(r'ret{{[l|q]}}', asm)
  # Strip kill operands inserted into the asm.
  asm = common.SCRUB_KILL_COMMENT_RE.sub('', asm)
  # Strip trailing whitespace.
  asm = common.SCRUB_TRAILING_WHITESPACE_RE.sub(r'', asm)
  return asm

def scrub_asm_amdgpu(asm, args):
  # Scrub runs of whitespace out of the assembly, but leave the leading
  # whitespace in place.
  asm = common.SCRUB_WHITESPACE_RE.sub(r' ', asm)
  # Expand the tabs used for indentation.
  asm = string.expandtabs(asm, 2)
  # Strip trailing whitespace.
  asm = common.SCRUB_TRAILING_WHITESPACE_RE.sub(r'', asm)
  return asm

def scrub_asm_arm_eabi(asm, args):
  # Scrub runs of whitespace out of the assembly, but leave the leading
  # whitespace in place.
  asm = common.SCRUB_WHITESPACE_RE.sub(r' ', asm)
  # Expand the tabs used for indentation.
  asm = string.expandtabs(asm, 2)
  # Strip kill operands inserted into the asm.
  asm = common.SCRUB_KILL_COMMENT_RE.sub('', asm)
  # Strip trailing whitespace.
  asm = common.SCRUB_TRAILING_WHITESPACE_RE.sub(r'', asm)
  return asm

def scrub_asm_powerpc64(asm, args):
  # Scrub runs of whitespace out of the assembly, but leave the leading
  # whitespace in place.
  asm = common.SCRUB_WHITESPACE_RE.sub(r' ', asm)
  # Expand the tabs used for indentation.
  asm = string.expandtabs(asm, 2)
  # Stripe unimportant comments
  asm = SCRUB_LOOP_COMMENT_RE.sub(r'', asm)
  # Strip trailing whitespace.
  asm = common.SCRUB_TRAILING_WHITESPACE_RE.sub(r'', asm)
  return asm


last_cap_size = None
last_frame_size = None  # type: int


def offset_to_cap_expr(offset, cap_size):
  if offset == 0:
    return "0"
  elif offset % cap_size == 0:
    return "[[@EXPR " + str(offset // cap_size) + " * $CAP_SIZE]]"
  else:
    return "[[@EXPR " + str(offset // cap_size) + " * $CAP_SIZE + " + str(offset % cap_size) + "]]"


def unchanged_match(match):
  return match.string[match.start():match.end()]


def do_clc_csc_sub(match):
  if sys.version_info >= (3, 5):
    from typing import Match
    assert isinstance(match, Match)
  insn = match.group('insn')
  reg = match.group('reg')
  offset = int(match.group('offset'))
  offset_sign = match.group('offset_sign')
  if offset_sign is None:
    offset_sign = ""
  cap_size = int(match.group('cap_size'))
  assert cap_size == 16 or cap_size == 32
  offset_str = offset_to_cap_expr(offset, cap_size)
  global last_cap_size
  last_cap_size = cap_size
  result = insn + " " + reg + ", $zero, " + offset_sign + offset_str + "($c11)"
  # print('replacing ', match.string[match.start():match.end()], 'with', result)
  return result


def do_save_load_dword_sub(match):
  if sys.version_info >= (3, 5):
    from typing import Match
    assert isinstance(match, Match)
  insn = match.group('insn')
  reg = match.group('reg')
  offset = int(match.group('offset'))
  offset_sign = match.group('offset_sign')
  if offset_sign is None:
    offset_sign = ""
  # dwords are stored after capabilities so usually this can be $STACKFRAME_SIZE - n*dword
  global last_frame_size
  if not last_frame_size:
    print("cld/csd: unknown stackframe size:" + unchanged_match(match))
  if offset >= last_frame_size:
    print("cld/csd: offset bigger than", last_frame_size, ":" + unchanged_match(match))
    return unchanged_match(match)
  difference = last_frame_size - offset
  if difference % 8 != 0:
    print("cld/csd: modulo wrong:" + unchanged_match(match))
    return unchanged_match(match)
  result = insn + " " + reg + ", $zero, " + offset_sign + "[[@EXPR STACKFRAME_SIZE - " + str(difference) + "]]($c11)"
  # print('replacing ', match.string[match.start():match.end()], 'with', result)
  return result


def do_cfi_offset_sub(match):
  cap_size = 16 if last_cap_size is None else last_cap_size
  offset_str = offset_to_cap_expr(int(match.group('offset')), cap_size)
  return ".cfi_offset " + match.group('reg') + ", -" + offset_str


def do_stackframe_size_sub(match):
  size = match.group("size")
  cfa_offset = match.group("size")
  if size != cfa_offset:
    print("WARNING: Could not match stackframe size")
    return unchanged_match(match)
  global last_frame_size
  last_frame_size = int(size)
  # assume double the size for CHERI256 stackframe:
  size_str = size + "|" + str(int(size) * 2)
  return "cincoffset $c11, $c11, -[[STACKFRAME_SIZE:" + size_str + "]]\n  .cfi_def_cfa_offset [[STACKFRAME_SIZE]]"


def scrub_asm_mips(asm, args):
  # Scrub runs of whitespace out of the assembly, but leave the leading
  # whitespace in place.
  asm = common.SCRUB_WHITESPACE_RE.sub(r' ', asm)
  # Expand the tabs used for indentation.
  asm = string.expandtabs(asm, 2)
  # Strip trailing whitespace.
  asm = common.SCRUB_TRAILING_WHITESPACE_RE.sub(r'', asm)

  # Expand .cfi offsets and clc offset to @EXPR for CHERI128/256
  stack_store_cap_re = re.compile(r'(?P<insn>csc|clc) (?P<reg>\$\w+), \$zero, (?P<offset_sign>\-)?(?P<offset>\d+)\(\$c11\) *# (?P<cap_size>16|32)\-byte Folded (Spill|Reload)')
  asm = stack_store_cap_re.sub(do_clc_csc_sub, asm)
  stackframe_size_regex = re.compile(r'cincoffset \$c11, \$c11, -(?P<size>\d+)\n *.cfi_def_cfa_offset (?P<cfa>\d+)')
  asm = stackframe_size_regex.sub(do_stackframe_size_sub, asm)
  stack_store_dword_re = re.compile(r'(?P<insn>csd|cld) (?P<reg>\$\w+), \$zero, (?P<offset_sign>\-)?(?P<offset>\d+)\(\$c11\) *# 8\-byte Folded (Spill|Reload)')
  asm = stack_store_dword_re.sub(do_save_load_dword_sub, asm)
  cfi_offset_regex = re.compile(r'\.cfi_offset (?P<reg>[$\w]+), -(?P<offset>\d+)')
  asm = cfi_offset_regex.sub(do_cfi_offset_sub, asm)
  stackframe_inc_return_regex = re.compile(r'cjr \$c17\n *cincoffset \$c11, \$c11, \d+')
  asm = stackframe_inc_return_regex.sub('cjr $c17\n  cincoffset $c11, $c11, [[STACKFRAME_SIZE]]', asm)
  return asm

def scrub_asm_riscv(asm, args):
  # Scrub runs of whitespace out of the assembly, but leave the leading
  # whitespace in place.
  asm = common.SCRUB_WHITESPACE_RE.sub(r' ', asm)
  # Expand the tabs used for indentation.
  asm = string.expandtabs(asm, 2)
  # Strip trailing whitespace.
  asm = common.SCRUB_TRAILING_WHITESPACE_RE.sub(r'', asm)
  return asm

def scrub_asm_sparc(asm, args):
  # Scrub runs of whitespace out of the assembly, but leave the leading
  # whitespace in place.
  asm = common.SCRUB_WHITESPACE_RE.sub(r' ', asm)
  # Expand the tabs used for indentation.
  asm = string.expandtabs(asm, 2)
  # Strip trailing whitespace.
  asm = common.SCRUB_TRAILING_WHITESPACE_RE.sub(r'', asm)
  return asm

def scrub_asm_systemz(asm, args):
  # Scrub runs of whitespace out of the assembly, but leave the leading
  # whitespace in place.
  asm = common.SCRUB_WHITESPACE_RE.sub(r' ', asm)
  # Expand the tabs used for indentation.
  asm = string.expandtabs(asm, 2)
  # Strip trailing whitespace.
  asm = common.SCRUB_TRAILING_WHITESPACE_RE.sub(r'', asm)
  return asm


def build_function_body_dictionary_for_triple(args, raw_tool_output, triple, prefixes, func_dict):
  target_handlers = {
      'x86_64': (scrub_asm_x86, ASM_FUNCTION_X86_RE),
      'i686': (scrub_asm_x86, ASM_FUNCTION_X86_RE),
      'x86': (scrub_asm_x86, ASM_FUNCTION_X86_RE),
      'i386': (scrub_asm_x86, ASM_FUNCTION_X86_RE),
      'aarch64': (scrub_asm_arm_eabi, ASM_FUNCTION_AARCH64_RE),
      'r600': (scrub_asm_amdgpu, ASM_FUNCTION_AMDGPU_RE),
      'amdgcn': (scrub_asm_amdgpu, ASM_FUNCTION_AMDGPU_RE),
      'arm-eabi': (scrub_asm_arm_eabi, ASM_FUNCTION_ARM_RE),
      'thumb-eabi': (scrub_asm_arm_eabi, ASM_FUNCTION_ARM_RE),
      'thumbv6': (scrub_asm_arm_eabi, ASM_FUNCTION_ARM_RE),
      'thumbv6-eabi': (scrub_asm_arm_eabi, ASM_FUNCTION_ARM_RE),
      'thumbv6t2': (scrub_asm_arm_eabi, ASM_FUNCTION_ARM_RE),
      'thumbv6t2-eabi': (scrub_asm_arm_eabi, ASM_FUNCTION_ARM_RE),
      'thumbv6m': (scrub_asm_arm_eabi, ASM_FUNCTION_ARM_RE),
      'thumbv6m-eabi': (scrub_asm_arm_eabi, ASM_FUNCTION_ARM_RE),
      'thumbv7': (scrub_asm_arm_eabi, ASM_FUNCTION_ARM_RE),
      'thumbv7-eabi': (scrub_asm_arm_eabi, ASM_FUNCTION_ARM_RE),
      'thumbv7m': (scrub_asm_arm_eabi, ASM_FUNCTION_ARM_RE),
      'thumbv7m-eabi': (scrub_asm_arm_eabi, ASM_FUNCTION_ARM_RE),
      'thumbv8-eabi': (scrub_asm_arm_eabi, ASM_FUNCTION_ARM_RE),
      'thumbv8m.base': (scrub_asm_arm_eabi, ASM_FUNCTION_ARM_RE),
      'thumbv8m.main': (scrub_asm_arm_eabi, ASM_FUNCTION_ARM_RE),
      'armv6': (scrub_asm_arm_eabi, ASM_FUNCTION_ARM_RE),
      'armv7': (scrub_asm_arm_eabi, ASM_FUNCTION_ARM_RE),
      'armv7-eabi': (scrub_asm_arm_eabi, ASM_FUNCTION_ARM_RE),
      'armeb-eabi': (scrub_asm_arm_eabi, ASM_FUNCTION_ARM_RE),
      'armv7eb-eabi': (scrub_asm_arm_eabi, ASM_FUNCTION_ARM_RE),
      'armv7eb': (scrub_asm_arm_eabi, ASM_FUNCTION_ARM_RE),
      'mips': (scrub_asm_mips, ASM_FUNCTION_MIPS_RE),
      'cheri': (scrub_asm_mips, ASM_FUNCTION_MIPS_RE),
      'powerpc64': (scrub_asm_powerpc64, ASM_FUNCTION_PPC_RE),
      'powerpc64le': (scrub_asm_powerpc64, ASM_FUNCTION_PPC_RE),
      'riscv32': (scrub_asm_riscv, ASM_FUNCTION_RISCV_RE),
      'riscv64': (scrub_asm_riscv, ASM_FUNCTION_RISCV_RE),
      'sparc': (scrub_asm_sparc, ASM_FUNCTION_SPARC_RE),
      'sparcv9': (scrub_asm_sparc, ASM_FUNCTION_SPARC_RE),
      's390x': (scrub_asm_systemz, ASM_FUNCTION_SYSTEMZ_RE),
  }
  handlers = None
  for prefix, s in target_handlers.items():
    if triple.startswith(prefix):
      handlers = s
      break
  else:
    raise KeyError('Triple %r is not supported' % (triple))

  scrubber, function_re = handlers
  common.build_function_body_dictionary(
          function_re, scrubber, [args], raw_tool_output, prefixes,
          func_dict, args.verbose)

##### Generator of assembly CHECK lines

def add_asm_checks(output_lines, comment_marker, prefix_list, func_dict, func_name):
  # Label format is based on ASM string.
  check_label_format = '{} %s-LABEL: %s:'.format(comment_marker)
  common.add_checks(output_lines, comment_marker, prefix_list, func_dict, func_name, check_label_format, True, False)
