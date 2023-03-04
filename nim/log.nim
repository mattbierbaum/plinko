type LogFunction* = proc(txt: string): void

proc simple_echo(txt: string): void = echo txt
var log_func: proc(txt: string): void = simple_echo

proc set_logger*(logger: LogFunction): void = log_func = logger
proc echo*(txt: string): void = log_func(txt)