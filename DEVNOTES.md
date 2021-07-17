===== 2021-July-17
Need a place for taking notes
So I updated script_path to correcectly override the PATH/env-vars to prevent it
from finding notepad++.exe in my path... but that's replicating coverage from
nppcc_dir.t, and is actually testing to outputs that won't be in the final
version of the script; so testing something that isn't there. :-(

What script_path was _supposed_ to be testing was how the -path argument to the
script would affect it; but until I know what the real outputs are of the
script, how can I effectively test the -path option's results (or any other
option, for that matter).

Even worse, while writing this up, I saw that the Action cpanm--test is
no longer passing, even though it was before.  But I don't want to debug that
problem, since it's debugging something I put in that won't be valid in the
future.

I need to figure out what this script is really doing, and what it's output
will be, because without that design, I cannot make a reasonable test with
any expectation that it will work. :-(
