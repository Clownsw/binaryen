;; NOTE: Assertions have been generated by update_lit_checks.py and should not be edited.

;; Run in both TNH and non-TNH mode.

;; RUN: wasm-opt %s --vacuum --traps-never-happen -all -S -o - | filecheck %s --check-prefix=YESTNH
;; RUN: wasm-opt %s --vacuum                      -all -S -o - | filecheck %s --check-prefix=NO_TNH

(module
  (memory 1 1)

  ;; YESTNH:      (type $struct (struct (field (mut i32))))
  ;; NO_TNH:      (type $struct (struct (field (mut i32))))
  (type $struct (struct (field (mut i32))))

  ;; YESTNH:      (func $drop (type $i32_anyref_=>_none) (param $x i32) (param $y anyref)
  ;; YESTNH-NEXT:  (nop)
  ;; YESTNH-NEXT: )
  ;; NO_TNH:      (func $drop (type $i32_anyref_=>_none) (param $x i32) (param $y anyref)
  ;; NO_TNH-NEXT:  (drop
  ;; NO_TNH-NEXT:   (i32.load
  ;; NO_TNH-NEXT:    (local.get $x)
  ;; NO_TNH-NEXT:   )
  ;; NO_TNH-NEXT:  )
  ;; NO_TNH-NEXT:  (drop
  ;; NO_TNH-NEXT:   (ref.as_non_null
  ;; NO_TNH-NEXT:    (local.get $y)
  ;; NO_TNH-NEXT:   )
  ;; NO_TNH-NEXT:  )
  ;; NO_TNH-NEXT:  (drop
  ;; NO_TNH-NEXT:   (ref.as_func
  ;; NO_TNH-NEXT:    (local.get $y)
  ;; NO_TNH-NEXT:   )
  ;; NO_TNH-NEXT:  )
  ;; NO_TNH-NEXT:  (drop
  ;; NO_TNH-NEXT:   (ref.as_data
  ;; NO_TNH-NEXT:    (local.get $y)
  ;; NO_TNH-NEXT:   )
  ;; NO_TNH-NEXT:  )
  ;; NO_TNH-NEXT:  (drop
  ;; NO_TNH-NEXT:   (ref.as_i31
  ;; NO_TNH-NEXT:    (local.get $y)
  ;; NO_TNH-NEXT:   )
  ;; NO_TNH-NEXT:  )
  ;; NO_TNH-NEXT:  (drop
  ;; NO_TNH-NEXT:   (unreachable)
  ;; NO_TNH-NEXT:  )
  ;; NO_TNH-NEXT: )
  (func $drop (param $x i32) (param $y anyref)
    ;; A load might trap, normally, but if traps never happen then we can
    ;; remove it.
    (drop
      (i32.load (local.get $x))
    )

    ;; A trap on a null value can also be ignored.
    (drop
      (ref.as_non_null
        (local.get $y)
      )
    )

    ;; Other ref.as* as well.
    (drop
      (ref.as_func
        (local.get $y)
      )
    )
    (drop
      (ref.as_data
        (local.get $y)
      )
    )
    (drop
      (ref.as_i31
        (local.get $y)
      )
    )

    ;; Ignore unreachable code.
    (drop
      (unreachable)
    )
  )

  ;; Other side effects prevent us making any changes.
  ;; YESTNH:      (func $other-side-effects (type $i32_=>_i32) (param $x i32) (result i32)
  ;; YESTNH-NEXT:  (drop
  ;; YESTNH-NEXT:   (call $other-side-effects
  ;; YESTNH-NEXT:    (i32.const 1)
  ;; YESTNH-NEXT:   )
  ;; YESTNH-NEXT:  )
  ;; YESTNH-NEXT:  (local.set $x
  ;; YESTNH-NEXT:   (i32.const 2)
  ;; YESTNH-NEXT:  )
  ;; YESTNH-NEXT:  (i32.const 1)
  ;; YESTNH-NEXT: )
  ;; NO_TNH:      (func $other-side-effects (type $i32_=>_i32) (param $x i32) (result i32)
  ;; NO_TNH-NEXT:  (drop
  ;; NO_TNH-NEXT:   (call $other-side-effects
  ;; NO_TNH-NEXT:    (i32.const 1)
  ;; NO_TNH-NEXT:   )
  ;; NO_TNH-NEXT:  )
  ;; NO_TNH-NEXT:  (drop
  ;; NO_TNH-NEXT:   (block (result i32)
  ;; NO_TNH-NEXT:    (local.set $x
  ;; NO_TNH-NEXT:     (i32.const 2)
  ;; NO_TNH-NEXT:    )
  ;; NO_TNH-NEXT:    (i32.load
  ;; NO_TNH-NEXT:     (local.get $x)
  ;; NO_TNH-NEXT:    )
  ;; NO_TNH-NEXT:   )
  ;; NO_TNH-NEXT:  )
  ;; NO_TNH-NEXT:  (i32.const 1)
  ;; NO_TNH-NEXT: )
  (func $other-side-effects (param $x i32) (result i32)
    ;; A call has all manner of other side effects.
    (drop
      (call $other-side-effects (i32.const 1))
    )

    ;; Add to the load an additional specific side effect, of writing to a
    ;; local. We can remove the load, but not the write to a local.
    (drop
      (block (result i32)
        (local.set $x (i32.const 2))
        (i32.load (local.get $x))
      )
    )

    (i32.const 1)
  )

  ;; A helper function for the above, that returns nothing.
  ;; YESTNH:      (func $return-nothing (type $none_=>_none)
  ;; YESTNH-NEXT:  (nop)
  ;; YESTNH-NEXT: )
  ;; NO_TNH:      (func $return-nothing (type $none_=>_none)
  ;; NO_TNH-NEXT:  (nop)
  ;; NO_TNH-NEXT: )
  (func $return-nothing)

  ;; YESTNH:      (func $partial (type $ref|$struct|_=>_ref?|$struct|) (param $x (ref $struct)) (result (ref null $struct))
  ;; YESTNH-NEXT:  (local $y (ref null $struct))
  ;; YESTNH-NEXT:  (local.set $y
  ;; YESTNH-NEXT:   (local.get $x)
  ;; YESTNH-NEXT:  )
  ;; YESTNH-NEXT:  (local.set $y
  ;; YESTNH-NEXT:   (local.get $x)
  ;; YESTNH-NEXT:  )
  ;; YESTNH-NEXT:  (local.get $y)
  ;; YESTNH-NEXT: )
  ;; NO_TNH:      (func $partial (type $ref|$struct|_=>_ref?|$struct|) (param $x (ref $struct)) (result (ref null $struct))
  ;; NO_TNH-NEXT:  (local $y (ref null $struct))
  ;; NO_TNH-NEXT:  (drop
  ;; NO_TNH-NEXT:   (struct.get $struct 0
  ;; NO_TNH-NEXT:    (local.tee $y
  ;; NO_TNH-NEXT:     (local.get $x)
  ;; NO_TNH-NEXT:    )
  ;; NO_TNH-NEXT:   )
  ;; NO_TNH-NEXT:  )
  ;; NO_TNH-NEXT:  (drop
  ;; NO_TNH-NEXT:   (struct.get $struct 0
  ;; NO_TNH-NEXT:    (local.tee $y
  ;; NO_TNH-NEXT:     (local.get $x)
  ;; NO_TNH-NEXT:    )
  ;; NO_TNH-NEXT:   )
  ;; NO_TNH-NEXT:  )
  ;; NO_TNH-NEXT:  (local.get $y)
  ;; NO_TNH-NEXT: )
  (func $partial (param $x (ref $struct)) (result (ref null $struct))
    (local $y (ref null $struct))
    ;; The struct.get's side effect can be ignored due to tnh, and the value is
    ;; dropped anyhow, so we can remove it. We cannot remove the local.tee
    ;; inside it, however, so we must only vacuum out the struct.get and
    ;; nothing more. (In addition, a drop of a tee will become a set.)
    (drop
      (struct.get $struct 0
        (local.tee $y
          (local.get $x)
        )
      )
    )
    ;; Similar, but with an eqz on the outside, which can also be removed.
    (drop
      (i32.eqz
        (struct.get $struct 0
          (local.tee $y
            (local.get $x)
          )
        )
      )
    )
    (local.get $y)
  )

  ;; YESTNH:      (func $toplevel (type $none_=>_none)
  ;; YESTNH-NEXT:  (nop)
  ;; YESTNH-NEXT: )
  ;; NO_TNH:      (func $toplevel (type $none_=>_none)
  ;; NO_TNH-NEXT:  (unreachable)
  ;; NO_TNH-NEXT: )
  (func $toplevel
    ;; A removable side effect at the top level of a function. We can turn this
    ;; into a nop.
    (unreachable)
  )

  ;; YESTNH:      (func $drop-loop (type $none_=>_none)
  ;; YESTNH-NEXT:  (nop)
  ;; YESTNH-NEXT: )
  ;; NO_TNH:      (func $drop-loop (type $none_=>_none)
  ;; NO_TNH-NEXT:  (drop
  ;; NO_TNH-NEXT:   (loop $loop (result i32)
  ;; NO_TNH-NEXT:    (br_if $loop
  ;; NO_TNH-NEXT:     (i32.const 1)
  ;; NO_TNH-NEXT:    )
  ;; NO_TNH-NEXT:    (i32.const 10)
  ;; NO_TNH-NEXT:   )
  ;; NO_TNH-NEXT:  )
  ;; NO_TNH-NEXT: )
  (func $drop-loop
    ;; A loop has effects, since it might infinite loop (and hit a timeout trap
    ;; eventually), so we do not vacuum it out unless we are ignoring traps.
    (drop
      (loop $loop (result i32)
        (br_if $loop
          (i32.const 1)
        )
        (i32.const 10)
      )
    )
  )

  ;; YESTNH:      (func $loop-effects (type $none_=>_none)
  ;; YESTNH-NEXT:  (drop
  ;; YESTNH-NEXT:   (loop $loop (result i32)
  ;; YESTNH-NEXT:    (drop
  ;; YESTNH-NEXT:     (i32.atomic.load
  ;; YESTNH-NEXT:      (i32.const 0)
  ;; YESTNH-NEXT:     )
  ;; YESTNH-NEXT:    )
  ;; YESTNH-NEXT:    (br_if $loop
  ;; YESTNH-NEXT:     (i32.const 1)
  ;; YESTNH-NEXT:    )
  ;; YESTNH-NEXT:    (i32.const 10)
  ;; YESTNH-NEXT:   )
  ;; YESTNH-NEXT:  )
  ;; YESTNH-NEXT: )
  ;; NO_TNH:      (func $loop-effects (type $none_=>_none)
  ;; NO_TNH-NEXT:  (drop
  ;; NO_TNH-NEXT:   (loop $loop (result i32)
  ;; NO_TNH-NEXT:    (drop
  ;; NO_TNH-NEXT:     (i32.atomic.load
  ;; NO_TNH-NEXT:      (i32.const 0)
  ;; NO_TNH-NEXT:     )
  ;; NO_TNH-NEXT:    )
  ;; NO_TNH-NEXT:    (br_if $loop
  ;; NO_TNH-NEXT:     (i32.const 1)
  ;; NO_TNH-NEXT:    )
  ;; NO_TNH-NEXT:    (i32.const 10)
  ;; NO_TNH-NEXT:   )
  ;; NO_TNH-NEXT:  )
  ;; NO_TNH-NEXT: )
  (func $loop-effects
    ;; As above, but the loop also has an atomic load effect. That prevents
    ;; optimization.
    (drop
      (loop $loop (result i32)
        (drop
          (i32.atomic.load
            (i32.const 0)
          )
        )
        (br_if $loop
          (i32.const 1)
        )
        (i32.const 10)
      )
    )
  )
)
