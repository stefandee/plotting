{ 
  Source code from https://github.com/martincameron/micromod
  Restructured into a unit format.
  Adapted to work with SDL_mixer 
}
  
Unit Music;

Interface

Uses 
	SysUtils, 
	SDL, 
	Micromod, 
	SDL_mixer, 
	SDLUtils,
	Logger;

Procedure LoadModule( FileName : String );
Procedure PrintModuleInfo;
Procedure PlayModule;
Procedure StopModule;
function IsModulePlaying: boolean;

Implementation

Const SAMPLING_FREQ  : LongInt = 22050; { 48khz. }
Const NUM_CHANNELS   : LongInt = 2;     { Stereo. }
Const BUFFER_SAMPLES : LongInt = 65536; { 256k buffer. }

Const EXIT_FAILURE   : Integer = 1;

Var Semaphore : PSDL_Sem;
Var MixBuffer : Array Of SmallInt;
Var SamplesRemaining, MixIndex, MixLength : LongInt;
var ModuleLoaded: boolean;

Procedure LoadModule( FileName : String );
	Var ModuleFile : File;
	Var ModuleData : Array Of ShortInt;
	Var FileLength, ReadLength, ReturnCode: LongInt;
Begin
    ModuleLoaded := false;

	If Not FileExists( FileName ) Then Begin
		Log.LogError( 'File Not Found: ' + FileName, 'Main' );
		Halt( EXIT_FAILURE );
	End;
	FileMode := fmOpenRead;
	Assign( ModuleFile, FileName );
	Reset( ModuleFile, 1 );
	SetLength( ModuleData, 1084 );
	BlockRead( ModuleFile, ModuleData[ 0 ], 1084, ReadLength );
	If ReadLength < 1084 Then Begin
		Log.LogError( 'Unable to read module header!', 'Main' );
		Halt( EXIT_FAILURE );
	End;
	FileLength := MicromodCalculateFileLength( ModuleData );
	If FileLength = MICROMOD_ERROR_MODULE_FORMAT_NOT_SUPPORTED Then Begin
		Log.LogError( 'Module format not supported!', 'Main' );
		Halt( EXIT_FAILURE );
	End;
	SetLength( ModuleData, FileLength );
	BlockRead( ModuleFile, ModuleData[ 1084 ], FileLength - 1084, ReadLength );
	Close( ModuleFile );
	If ReadLength + 1084 < FileLength Then
		WriteLn( 'Module File Has Been Truncated! Should Be ' + IntToStr( FileLength ) );
	ReturnCode := MicromodInit( ModuleData, SAMPLING_FREQ, False );
	If ReturnCode <> 0 Then Begin
		Log.LogError( 'Unable to initialize replay! ' + IntToStr( ReturnCode ), 'Main' );
		Halt( EXIT_FAILURE );
	End;
	
	ModuleLoaded := true;
End;

Procedure PrintModuleInfo;
Var
	Idx : LongInt;
	InstrumentName : String;
Begin
	if not ModuleLoaded then exit;

	WriteLn( 'Song Name: ' + MicromodGetSongName );
	For Idx := 1 To 31 Do Begin
		InstrumentName := TrimRight( MicromodGetInstrumentName( Idx ) );
		If Length( InstrumentName ) > 0 Then Begin
			Write( 'Instrument ' );
			If Idx < 10 Then Write( ' ' );
			WriteLn( IntToStr( Idx ) + ': ' + InstrumentName );
		End;
	End;
End;

function GetAudioForSDLMixer( UserData : Pointer; OutputBuffer : PUInt8; Length : LongInt ): pointer; CDecl;
Var
	OutOffset, OutRemain, Count : LongInt;
Begin
	OutOffset := 0;
	Length := Length Div 4;
	While OutOffset < Length Do Begin
		OutRemain := Length - OutOffset;
		Count := MixLength - MixIndex;
		If Count > OutRemain Then Count := OutRemain;
		Move( MixBuffer[ MixIndex * 2 ], OutputBuffer[ OutOffset * 4 ], Count * 2 * SizeOf( SmallInt ) );
		MixIndex := MixIndex + Count;
		If MixIndex >= MixLength Then Begin
			{ Get more audio from replay. }
			MixLength := MicromodGetAudio( MixBuffer );
			MixIndex := 0;
			{ Notify main thread if song has finished. }
			SamplesRemaining := SamplesRemaining - MixLength;
			If SamplesRemaining <= 0 Then SDL_SemPost( Semaphore );
		End;
		OutOffset := OutOffset + Count;
	End;
End;

Procedure PlayModule;
Var
	AudioSpec : TSDL_AudioSpec;
	music_pos: ^longint;
  audio_rate : Integer; 
  audio_channels : Integer;
  audio_format : UInt16;
Begin
	if not ModuleLoaded then 
	begin
	    Log.LogWarning('PlayModule: no module was loaded', 'Music');
		exit;
	end;

	{ Calculate Duration. }
	SamplesRemaining := MicromodCalculateSongDuration;
	{WriteLn( 'Duration: ' + IntToStr( SamplesRemaining Div SAMPLING_FREQ ) + ' Seconds.' );}
	Log.LogStatus( 'Module duration: ' + IntToStr( SamplesRemaining Div SAMPLING_FREQ ) + ' Seconds.', 'Music' );
	

	{ Initialise Mix Buffer. }
	SetLength( MixBuffer, SAMPLING_FREQ * 2 Div 5 );

    { Open the audio device }
	{if (Mix_OpenAudio(SAMPLING_FREQ, AUDIO_S16SYS, NUM_CHANNELS, BUFFER_SAMPLES) < 0) then
	begin
		writeln(Format('Couldn''t open audio: %s', [SDL_GetError]));
		Halt(4);
	end;}

	new(music_pos);
	music_pos^ := 0;
	Mix_HookMusic(@GetAudioForSDLMixer, music_pos);

    (*
	{ Open Audio Device. }
	FillChar( AudioSpec, SizeOf( TSDL_AudioSpec ), 0 );
	AudioSpec.freq := SAMPLING_FREQ;
	AudioSpec.format := AUDIO_S16SYS;
	AudioSpec.channels := NUM_CHANNELS;
	AudioSpec.samples := BUFFER_SAMPLES;
	AudioSpec.callback := @GetAudio;
	AudioSpec.userdata := Nil;
	if SDL_OpenAudio( @AudioSpec, Nil ) <> 0 Then Begin
		WriteLn( 'Couldn''t open audio device: ' + SDL_GetError() );
		Halt( EXIT_FAILURE );
	End;

	{ Begin playback. }
	SDL_PauseAudio( 0 );
	*)

	{ Wait for playback to finish. }
		
	
	if Semaphore <> nil then SDL_DestroySemaphore(Semaphore);
	
	Semaphore := SDL_CreateSemaphore( 0 );
	
	{if SDL_SemWait( Semaphore ) <> 0 Then WriteLn( 'SDL_SemWait() failed.' );}

End;

function IsModulePlaying: boolean;
begin
	IsModulePlaying := ModuleLoaded and (SamplesRemaining > 0);
end;

procedure StopModule;
begin
	if not ModuleLoaded then exit;
	
	Mix_HookMusic(nil, nil);
end;

begin
	ModuleLoaded := false;
end.