if not exist ./obj mkdir obj

fpc -Mobjfpc -S2 -Sg -Sc -Sh -XS -Xt -FU./obj SDLModPlayer.PAS
@if %ERRORLEVEL% GEQ 1 EXIT /B %ERRORLEVEL%
