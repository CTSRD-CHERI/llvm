# RUN: llvm-mc %s -triple=cheri-unknown-freebsd -show-encoding -mcpu=cheri | FileCheck %s
#
# Check that the assembler is able to handle capability get instructions.
#

# CHECK: cgetperm	$12, $c1
# CHECK: encoding: [0x48,0x0c,0x08,0x00]
	cgetperm	$t0, $c1
# CHECK: cgettype	$12, $c1
# CHECK: encoding: [0x48,0x0c,0x08,0x01]
	cgettype	$t0, $c1
# CHECK: cgetbase	$12, $c1
# CHECK: encoding: [0x48,0x0c,0x08,0x02]
	cgetbase	$t0, $c1
# CHECK: cgetlen	$12, $c1
# CHECK: encoding: [0x48,0x0c,0x08,0x03]
	cgetlen		$t0, $c1
# CHECK: cgettag	$12, $c1
# CHECK: encoding: [0x48,0x0c,0x08,0x05]
	cgettag		$t0, $c1
# CHECK: cgetunsealed	$12, $c1
# CHECK: encoding: [0x48,0x0c,0x08,0x06]
	cgetunsealed	$t0, $c1
# CHECK: cgetpcc	$12($c1)
# CHECK: encoding: [0x48,0x0c,0x08,0x07]
	cgetpcc		$t0($c1)
# CHECK: cgetcause	$t0
# CHECK: encoding: [0x48,0x0c,0x00,0x04]
	cgetcause	$t0
