Program SDLModPlayer;

{$APPTYPE Console}

Uses music, crt, sdl;

Begin

	{ Initialize Replay. }
	If ParamCount > 0 Then Begin
		LoadModule( ParamStr( 1 ) );
		PrintModuleInfo;
		PlayModule;	
		
		repeat until (not IsModulePlaying) or KeyPressed;
		
		StopModule;
		SDL_Quit;		
		
	End Else Begin
		WriteLn( 'Micromod ProTracker replay in Pascal.' );
		WriteLn( 'Please specify a module file to play.' );
	End;
	
End.

