if not exist ./obj mkdir obj

fpc -Mobjfpc -S2 -Sg -Sc -Sh -XS -Xt -FU./obj MAKE_LEVELS.PAS
@if %ERRORLEVEL% GEQ 1 EXIT /B %ERRORLEVEL%

MAKE_LEVELS.exe