; eg function Foo(), function foo#Foo()
(function_declaration name: (identifier) @func)

; eg function s:Foo()
(function_declaration name: (scoped_identifier) @func)

; eg augroup foobar
(augroup_statement (augroup_name) @aug (#not-eq? @aug "END"))
