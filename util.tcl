proc clog2 {num} {
    set value 0
    while {[expr 2 ** $value] < $num} {
        incr value
    }
    return $value
}

# https://wiki.tcl-lang.org/page/Templates+and+subst
proc substify {in {var OUT}} {
    set pos 0  
    foreach pair [regexp -line -all -inline -indices {^%.*$} $in] {
        lassign $pair from to
        set s [string range $in $pos [expr {$from-2}]]
        append script "append $var \[" [list subst $s] "]\n" \
                                    [string range $in [expr {$from+1}] $to] "\n"
        set pos [expr {$to+2}]
    }
    set s [string range $in $pos end]
    append script "append $var \[" [list subst $s] "]\n"
}

proc range2mask {high low} {
    set mask 0
    for {set i $low} {$i <= $high} {incr i} {
        set mask [expr $mask | (1 << $i)]
    }
    return $mask
}