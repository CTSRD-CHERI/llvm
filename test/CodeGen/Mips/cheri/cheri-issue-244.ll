; RUN: %cheri_purecap_llc %s -o /dev/null

%struct.b = type { i32 addrspace(200)* }

@e = local_unnamed_addr addrspace(200) global %struct.b { i32 addrspace(200)* bitcast (i32 () addrspace(200)* @c to i32 addrspace(200)*) }, align 32

; Function Attrs: nounwind
define internal i32 @c() addrspace(200) #0 {
entry:
  %call = tail call addrspace(200) i32 (...) @dladdr(i8 addrspace(200)* inreg bitcast (i32 () addrspace(200)* @c to i8 addrspace(200)*)) #2
  ret i32 undef
}

declare i32 @dladdr(...) addrspace(200) #1

attributes #0 = { nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="cheri" "target-features"="+cheri,+soft-float" "unsafe-fp-math"="false" "use-soft-float"="true" }
attributes #1 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="cheri" "target-features"="+cheri,+soft-float" "unsafe-fp-math"="false" "use-soft-float"="true" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1}
!llvm.ident = !{!2}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"PIC Level", i32 1}
!2 = !{!"clang version 5.0.0 "}

