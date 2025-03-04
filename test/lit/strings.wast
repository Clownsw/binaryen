;; NOTE: Assertions have been generated by update_lit_checks.py --all-items and should not be edited.

;; Check that string types are emitted properly in the binary format.
;;
;; runs --precompute in order to verify no problems occur in the optimizer's
;; invocation of the interpreter.

;; RUN: wasm-opt %s --enable-strings --enable-reference-types --enable-gc --roundtrip --precompute -S -o - | filecheck %s

;; Check that we can roundtrip through the text format as well.

;; RUN: wasm-opt %s -all -S -o - | wasm-opt -all --precompute -S -o - | filecheck %s

(module
  (memory 10 10)

  ;; CHECK:      (type $stringref_=>_none (func (param stringref)))

  ;; CHECK:      (type $stringref_stringview_wtf8_stringview_wtf16_stringview_iter_=>_none (func (param stringref stringview_wtf8 stringview_wtf16 stringview_iter)))

  ;; CHECK:      (type $stringref_stringref_=>_none (func (param stringref stringref)))

  ;; CHECK:      (type $array (array (mut i8)))
  (type $array (array_subtype (mut i8) data))
  ;; CHECK:      (type $array16 (array (mut i16)))
  (type $array16 (array_subtype (mut i16) data))

  ;; CHECK:      (type $stringref_stringview_wtf8_stringview_wtf16_stringview_iter_stringref_stringview_wtf8_stringview_wtf16_stringview_iter_ref|string|_ref|stringview_wtf8|_ref|stringview_wtf16|_ref|stringview_iter|_=>_none (func (param stringref stringview_wtf8 stringview_wtf16 stringview_iter stringref stringview_wtf8 stringview_wtf16 stringview_iter (ref string) (ref stringview_wtf8) (ref stringview_wtf16) (ref stringview_iter))))

  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (type $stringview_wtf16_=>_none (func (param stringview_wtf16)))

  ;; CHECK:      (type $ref|$array|_ref|$array16|_=>_none (func (param (ref $array) (ref $array16))))

  ;; CHECK:      (type $stringref_ref|$array|_ref|$array16|_=>_none (func (param stringref (ref $array) (ref $array16))))

  ;; CHECK:      (global $string-const stringref (string.const "string in a global \01\ff\00\t\t\n\n\r\r\"\"\'\'\\\\"))
  (global $string-const stringref (string.const "string in a global \01\ff\00\t\09\n\0a\r\0d\"\22\'\27\\\5c"))

  ;; CHECK:      (memory $0 10 10)

  ;; CHECK:      (func $string.new (type $stringref_stringview_wtf8_stringview_wtf16_stringview_iter_stringref_stringview_wtf8_stringview_wtf16_stringview_iter_ref|string|_ref|stringview_wtf8|_ref|stringview_wtf16|_ref|stringview_iter|_=>_none) (param $a stringref) (param $b stringview_wtf8) (param $c stringview_wtf16) (param $d stringview_iter) (param $e stringref) (param $f stringview_wtf8) (param $g stringview_wtf16) (param $h stringview_iter) (param $i (ref string)) (param $j (ref stringview_wtf8)) (param $k (ref stringview_wtf16)) (param $l (ref stringview_iter))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (string.new_wtf8 utf8
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:    (i32.const 2)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (string.new_wtf8 wtf8
  ;; CHECK-NEXT:    (i32.const 3)
  ;; CHECK-NEXT:    (i32.const 4)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (string.new_wtf8 replace
  ;; CHECK-NEXT:    (i32.const 5)
  ;; CHECK-NEXT:    (i32.const 6)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (string.new_wtf16
  ;; CHECK-NEXT:    (i32.const 7)
  ;; CHECK-NEXT:    (i32.const 8)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $string.new
    (param $a stringref)
    (param $b stringview_wtf8)
    (param $c stringview_wtf16)
    (param $d stringview_iter)
    (param $e (ref null string))
    (param $f (ref null stringview_wtf8))
    (param $g (ref null stringview_wtf16))
    (param $h (ref null stringview_iter))
    (param $i (ref string))
    (param $j (ref stringview_wtf8))
    (param $k (ref stringview_wtf16))
    (param $l (ref stringview_iter))
    (drop
      (string.new_wtf8 utf8
        (i32.const 1)
        (i32.const 2)
      )
    )
    (drop
      (string.new_wtf8 wtf8
        (i32.const 3)
        (i32.const 4)
      )
    )
    (drop
      (string.new_wtf8 replace
        (i32.const 5)
        (i32.const 6)
      )
    )
    (drop
      (string.new_wtf16
        (i32.const 7)
        (i32.const 8)
      )
    )
  )

  ;; CHECK:      (func $string.const (type $none_=>_none)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (string.const "foo")
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (string.const "foo")
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (string.const "bar")
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $string.const
    (drop
      (string.const "foo")
    )
    (drop
      (string.const "foo") ;; intentionally repeat the previous one
    )
    (drop
      (string.const "bar")
    )
  )

  ;; CHECK:      (func $string.measure (type $stringref_=>_none) (param $ref stringref)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (i32.eqz
  ;; CHECK-NEXT:    (string.measure_wtf8 wtf8
  ;; CHECK-NEXT:     (local.get $ref)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (string.measure_wtf8 utf8
  ;; CHECK-NEXT:    (local.get $ref)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (string.measure_wtf16
  ;; CHECK-NEXT:    (local.get $ref)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $string.measure (param $ref stringref)
    (drop
      (i32.eqz ;; validate the output is i32
        (string.measure_wtf8 wtf8
          (local.get $ref)
        )
      )
    )
    (drop
      (string.measure_wtf8 utf8
        (local.get $ref)
      )
    )
    (drop
      (string.measure_wtf16
        (local.get $ref)
      )
    )
  )

  ;; CHECK:      (func $string.encode (type $stringref_=>_none) (param $ref stringref)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (i32.eqz
  ;; CHECK-NEXT:    (string.encode_wtf8 wtf8
  ;; CHECK-NEXT:     (local.get $ref)
  ;; CHECK-NEXT:     (i32.const 10)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (string.encode_wtf8 utf8
  ;; CHECK-NEXT:    (local.get $ref)
  ;; CHECK-NEXT:    (i32.const 20)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (string.encode_wtf16
  ;; CHECK-NEXT:    (local.get $ref)
  ;; CHECK-NEXT:    (i32.const 30)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $string.encode (param $ref stringref)
    (drop
      (i32.eqz ;; validate the output is i32
        (string.encode_wtf8 wtf8
          (local.get $ref)
          (i32.const 10)
        )
      )
    )
    (drop
      (string.encode_wtf8 utf8
        (local.get $ref)
        (i32.const 20)
      )
    )
    (drop
      (string.encode_wtf16
        (local.get $ref)
        (i32.const 30)
      )
    )
  )

  ;; CHECK:      (func $string.concat (type $stringref_stringref_=>_none) (param $a stringref) (param $b stringref)
  ;; CHECK-NEXT:  (local.set $a
  ;; CHECK-NEXT:   (string.concat
  ;; CHECK-NEXT:    (local.get $a)
  ;; CHECK-NEXT:    (local.get $b)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $string.concat (param $a stringref) (param $b stringref)
    (local.set $a ;; validate the output is a stringref
      (string.concat
        (local.get $a)
        (local.get $b)
      )
    )
  )

  ;; CHECK:      (func $string.eq (type $stringref_stringref_=>_none) (param $a stringref) (param $b stringref)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (i32.eqz
  ;; CHECK-NEXT:    (string.eq
  ;; CHECK-NEXT:     (local.get $a)
  ;; CHECK-NEXT:     (local.get $b)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $string.eq (param $a stringref) (param $b stringref)
    (drop
      (i32.eqz ;; validate the output is an i32
        (string.eq
          (local.get $a)
          (local.get $b)
        )
      )
    )
  )

  ;; CHECK:      (func $string.is_usv_sequence (type $stringref_=>_none) (param $ref stringref)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (i32.eqz
  ;; CHECK-NEXT:    (string.is_usv_sequence
  ;; CHECK-NEXT:     (local.get $ref)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $string.is_usv_sequence (param $ref stringref)
    (drop
      (i32.eqz ;; validate the output is i32
        (string.is_usv_sequence
          (local.get $ref)
        )
      )
    )
  )

  ;; CHECK:      (func $string.as (type $stringref_stringview_wtf8_stringview_wtf16_stringview_iter_=>_none) (param $a stringref) (param $b stringview_wtf8) (param $c stringview_wtf16) (param $d stringview_iter)
  ;; CHECK-NEXT:  (local.set $b
  ;; CHECK-NEXT:   (string.as_wtf8
  ;; CHECK-NEXT:    (local.get $a)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $c
  ;; CHECK-NEXT:   (string.as_wtf16
  ;; CHECK-NEXT:    (local.get $a)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $d
  ;; CHECK-NEXT:   (string.as_iter
  ;; CHECK-NEXT:    (local.get $a)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $string.as
    (param $a stringref)
    (param $b stringview_wtf8)
    (param $c stringview_wtf16)
    (param $d stringview_iter)
    (local.set $b ;; validate the output type
      (string.as_wtf8
        (local.get $a)
      )
    )
    (local.set $c
      (string.as_wtf16
        (local.get $a)
      )
    )
    (local.set $d
      (string.as_iter
        (local.get $a)
      )
    )
  )

  ;; CHECK:      (func $stringview-access (type $stringref_stringview_wtf8_stringview_wtf16_stringview_iter_=>_none) (param $a stringref) (param $b stringview_wtf8) (param $c stringview_wtf16) (param $d stringview_iter)
  ;; CHECK-NEXT:  (local $i32 i32)
  ;; CHECK-NEXT:  (local.set $i32
  ;; CHECK-NEXT:   (stringview_wtf8.advance
  ;; CHECK-NEXT:    (local.get $b)
  ;; CHECK-NEXT:    (i32.const 0)
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $i32
  ;; CHECK-NEXT:   (stringview_wtf16.get_codeunit
  ;; CHECK-NEXT:    (local.get $c)
  ;; CHECK-NEXT:    (i32.const 2)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $i32
  ;; CHECK-NEXT:   (stringview_iter.next
  ;; CHECK-NEXT:    (local.get $d)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $i32
  ;; CHECK-NEXT:   (stringview_iter.advance
  ;; CHECK-NEXT:    (local.get $d)
  ;; CHECK-NEXT:    (i32.const 3)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $i32
  ;; CHECK-NEXT:   (stringview_iter.rewind
  ;; CHECK-NEXT:    (local.get $d)
  ;; CHECK-NEXT:    (i32.const 4)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $stringview-access
    (param $a stringref)
    (param $b stringview_wtf8)
    (param $c stringview_wtf16)
    (param $d stringview_iter)
    (local $i32 i32)
    (local.set $i32 ;; validate the output type
      (stringview_wtf8.advance
        (local.get $b)
        (i32.const 0)
        (i32.const 1)
      )
    )
    (local.set $i32
      (stringview_wtf16.get_codeunit
        (local.get $c)
        (i32.const 2)
      )
    )
    (local.set $i32
      (stringview_iter.next
        (local.get $d)
      )
    )
    (local.set $i32
      (stringview_iter.advance
        (local.get $d)
        (i32.const 3)
      )
    )
    (local.set $i32
      (stringview_iter.rewind
        (local.get $d)
        (i32.const 4)
      )
    )
  )
  ;; CHECK:      (func $stringview-slice (type $stringref_stringview_wtf8_stringview_wtf16_stringview_iter_=>_none) (param $a stringref) (param $b stringview_wtf8) (param $c stringview_wtf16) (param $d stringview_iter)
  ;; CHECK-NEXT:  (local.set $a
  ;; CHECK-NEXT:   (stringview_wtf8.slice
  ;; CHECK-NEXT:    (local.get $b)
  ;; CHECK-NEXT:    (i32.const 0)
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $a
  ;; CHECK-NEXT:   (stringview_wtf16.slice
  ;; CHECK-NEXT:    (local.get $c)
  ;; CHECK-NEXT:    (i32.const 2)
  ;; CHECK-NEXT:    (i32.const 3)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $a
  ;; CHECK-NEXT:   (stringview_iter.slice
  ;; CHECK-NEXT:    (local.get $d)
  ;; CHECK-NEXT:    (i32.const 4)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $stringview-slice
    (param $a stringref)
    (param $b stringview_wtf8)
    (param $c stringview_wtf16)
    (param $d stringview_iter)
    (local.set $a ;; validate the output type
      (stringview_wtf8.slice
        (local.get $b)
        (i32.const 0)
        (i32.const 1)
      )
    )
    (local.set $a
      (stringview_wtf16.slice
        (local.get $c)
        (i32.const 2)
        (i32.const 3)
      )
    )
    (local.set $a
      (stringview_iter.slice
        (local.get $d)
        (i32.const 4)
      )
    )
  )

  ;; CHECK:      (func $string.length (type $stringview_wtf16_=>_none) (param $ref stringview_wtf16)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (i32.eqz
  ;; CHECK-NEXT:    (stringview_wtf16.length
  ;; CHECK-NEXT:     (local.get $ref)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $string.length (param $ref stringview_wtf16)
    (drop
      (i32.eqz ;; validate the output is i32
        (stringview_wtf16.length
          (local.get $ref)
        )
      )
    )
  )

  ;; CHECK:      (func $string.new.gc (type $ref|$array|_ref|$array16|_=>_none) (param $array (ref $array)) (param $array16 (ref $array16))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (string.new_wtf8_array utf8
  ;; CHECK-NEXT:    (local.get $array)
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:    (i32.const 2)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (string.new_wtf8_array wtf8
  ;; CHECK-NEXT:    (local.get $array)
  ;; CHECK-NEXT:    (i32.const 3)
  ;; CHECK-NEXT:    (i32.const 4)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (string.new_wtf8_array replace
  ;; CHECK-NEXT:    (local.get $array)
  ;; CHECK-NEXT:    (i32.const 5)
  ;; CHECK-NEXT:    (i32.const 6)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (string.new_wtf16_array
  ;; CHECK-NEXT:    (local.get $array16)
  ;; CHECK-NEXT:    (i32.const 7)
  ;; CHECK-NEXT:    (i32.const 8)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $string.new.gc (param $array (ref $array)) (param $array16 (ref $array16))
    (drop
      (string.new_wtf8_array utf8
        (local.get $array)
        (i32.const 1)
        (i32.const 2)
      )
    )
    (drop
      (string.new_wtf8_array wtf8
        (local.get $array)
        (i32.const 3)
        (i32.const 4)
      )
    )
    (drop
      (string.new_wtf8_array replace
        (local.get $array)
        (i32.const 5)
        (i32.const 6)
      )
    )
    (drop
      (string.new_wtf16_array
        (local.get $array16)
        (i32.const 7)
        (i32.const 8)
      )
    )
  )

  ;; CHECK:      (func $string.encode.gc (type $stringref_ref|$array|_ref|$array16|_=>_none) (param $ref stringref) (param $array (ref $array)) (param $array16 (ref $array16))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (i32.eqz
  ;; CHECK-NEXT:    (string.encode_wtf8_array wtf8
  ;; CHECK-NEXT:     (local.get $ref)
  ;; CHECK-NEXT:     (local.get $array)
  ;; CHECK-NEXT:     (i32.const 10)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (string.encode_wtf8_array utf8
  ;; CHECK-NEXT:    (local.get $ref)
  ;; CHECK-NEXT:    (local.get $array)
  ;; CHECK-NEXT:    (i32.const 20)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (string.encode_wtf16_array
  ;; CHECK-NEXT:    (local.get $ref)
  ;; CHECK-NEXT:    (local.get $array16)
  ;; CHECK-NEXT:    (i32.const 30)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $string.encode.gc (param $ref stringref) (param $array (ref $array)) (param $array16 (ref $array16))
    (drop
      (i32.eqz ;; validate the output is i32
        (string.encode_wtf8_array wtf8
          (local.get $ref)
          (local.get $array)
          (i32.const 10)
        )
      )
    )
    (drop
      (string.encode_wtf8_array utf8
        (local.get $ref)
        (local.get $array)
        (i32.const 20)
      )
    )
    (drop
      (string.encode_wtf16_array
        (local.get $ref)
        (local.get $array16)
        (i32.const 30)
      )
    )
  )
)
