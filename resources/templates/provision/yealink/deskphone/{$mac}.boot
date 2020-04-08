#!version:1.0.0.1
## The header above must appear as-is in the first line

include:config "y000000000000.cfg"
include:config "y_$PN.cfg"
include:config "{$mac}.cfg"

# yealink_overwrite_mode is 1 if the config lines with no value should reset to factory and 0 if they should be left as-is.
overwrite_mode = {$yealink_overwrite_mode}
