local plinko = require('plinko')

if #arg < 1 then
    print("plinko <script.lua> <args>")
else
    plinko.run_file(table.remove(arg, 1))
end
