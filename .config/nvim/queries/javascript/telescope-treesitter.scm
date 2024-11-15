; eg. function foo()
(function_declaration name: (identifier) @func)

; eg: foo = function()
(assignment_expression
  left: (identifier) @func
  right: (function_expression)
)

; eg: var foo = function()
(variable_declarator
  name: (identifier) @func
  value: (function_expression)
)

; eg: { foo = function() }
(pair
  key: (property_identifier) @func
  value: (function_expression)
)

; eg:
;  (function($) {
;    foo = function()
;  });
(assignment_expression
  left: (member_expression) @func
  right: (function_expression)
)

; eg: class Foo
(class_declaration name: (identifier) @cls)

; eg:
;   class Foo {
;     foo(){
;       ...
;     }
;   }
(method_definition name: (property_identifier) @meth)
