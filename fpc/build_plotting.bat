fpc -Mobjfpc -S2 -Sg -Sc -Sh -XS -Xt -FU./obj PLOTTING.PAS
@if %ERRORLEVEL% GEQ 1 EXIT /B %ERRORLEVEL%
plotting.exe