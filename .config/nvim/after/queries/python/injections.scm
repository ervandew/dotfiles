; extends

; inject sql highlighting into python files using db.(execute|get|select)
(call
  (attribute
    object: (identifier) @_obj (#eq? @_obj "db")
    attribute: (identifier) @_attr (#match? @_attr "(delete|execute|get|insert|select|update)")
  )
  (argument_list (string (string_content) @injection.content))
  (#set! injection.language "sql")
)

; ditto, but accounting for the string using the % operator
(call
  (attribute
    object: (identifier) @_obj (#eq? @_obj "db")
    attribute: (identifier) @_attr (#match? @_attr "(delete|execute|get|insert|select|update)")
  )
  (argument_list
    (binary_operator
    (string (string_content) @injection.content)))
  (#set! injection.language "sql")
)
