# MicFix
Fixes microphone audio breaking during and after cutscenes.

The way it works is by executing the `stopsound` command on all players after a camera sequence is started/stopped.

This doesn't completely fix the problem. I still rarely get broken audio but I don't what causes it. I think it might be something to do with observer mode and/or teleporting.
