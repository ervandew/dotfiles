; eg function foo
(function_declaration name: (identifier) @func)

; eg function M.foo
(function_declaration name: (dot_index_expression) @func)

; eg: foo = function(...)
(assignment_statement
  (variable_list name: (identifier)) @func
  (expression_list value: (function_definition))
)

; eg: M.foo = function(...)
(assignment_statement
  (variable_list name: (dot_index_expression)) @func
  (expression_list value: (function_definition))
)

; eg: { foo = function()... }
(field
  name: (identifier) @func
  value: (function_definition)
)
