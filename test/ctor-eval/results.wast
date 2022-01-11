(module
  (global $global1 (mut i32) (i32.const 1))
  (global $global2 (mut i32) (i32.const 2))
  (global $global3 (mut i32) (i32.const 3))

  (func $test1 (export "test1")
    ;; This function can be evalled. But in this test we keep this export,
    ;; so we should still see an export, but the export should do nothing since
    ;; the code has already run.
    ;;
    ;; In comparison, test3 below, with a result, will still contain a
    ;; (constant) result in the remaining export once we can handle results.

    (global.set $global1
      (i32.const 11)
    )
  )

  (func $test2 (export "test2")
    ;; As the above function, but the export is *not* kept.
    (global.set $global2
      (i32.const 12)
    )
  )

  (func $test3 (export "test3") (result i32)
    ;; The presence of a result stops us from evalling this function (at least
    ;; for now). Not even the global set will be evalled.
    (global.set $global3
      (i32.const 13)
    )
    (i32.const 42)
  )

  (func "keepalive" (result i32)
    ;; Keep everything alive to see the changes.

    ;; These should call the original $test1, not the one that is nopped out
    ;; after evalling.
    (call $test1)
    (call $test2)

    (drop
      (call $test3)
    )

    ;; Keeping these alive should show the changes to the globals (that should
    ;; contain 11, 12, and 3).
    (i32.add
      (global.get $global1)
      (global.get $global2)
    )
  )
)
