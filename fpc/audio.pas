unit Audio;

interface

uses 
  SDL_mixer,
  Logger,
  SDL,
  SDLUtils,
  PlottingUtils,
  SysUtils;
  
type
  TSoundList = array[0..16] of PMix_Chunk;
  
const
  SND_WIN = 1;
  SND_LOSE = 2;
  SND_MOVE = 3;
  SND_SHOOT = 4;
  SND_TILE_POP = 5;
  SND_TIME_WARNING = 6;
  SND_POWERUP = 7;
  SND_OUT_OF_MOVES = 8;
  MAX_SND = 8;

  SoundFiles : array[1..MAX_SND] of string = (
    'data/270333__littlerobotsoundfactory__jingle_win_00.wav',
    'data/270334__littlerobotsoundfactory__jingle_lose_01.wav',
    'data/633247__aesterial-arts__arcade-jump-2.wav',
    'data/633250__aesterial-arts__arcade-shoot.wav',
    'data/89534__cgeffex__very-fast-bubble-pop1.wav',
    'data/450617__breviceps__8-bit-times-up.wav',
    'data/431329__someguy22__8-bit-powerup.wav',
    'data/514153__edwardszakal__beep-buzz.wav'
  );

var
  Sounds : TSoundList;  

procedure InitAudio;
procedure LoadAudio;
procedure PlayAudioOneShot(index : Integer);

implementation

procedure LoadSound(filename : String; index : Integer); forward;

procedure LoadAudio;
  var i : Integer;
begin
   for i := Low(SoundFiles) to High(SoundFiles) do
     LoadSound(SoundFiles[i], i);
end;	

procedure PlayAudioOneShot(index : Integer);
begin
  if Sounds[index] <> nil then
  begin
	Mix_PlayChannel(-1, Sounds[index], 0);
  end;
end;

procedure LoadSound(filename : String; index : Integer);
begin
	Sounds[index] := Mix_LoadWAV(PChar(filename));
	if ( Sounds[index] = nil ) then
	begin
		Log.LogError(Format('Couldn''t load %s: %s', [filename, SDL_GetError]), 'Main');
	end;
end;

procedure InitAudio;
var
  audio_rate : Integer; 
  audio_channels : Integer;
  audio_format : UInt16;
  audio_channels_str : String;
begin
	audio_rate := 44100;
	audio_format := 8;
	audio_channels := 1;

    { Open the audio device }
	if (Mix_OpenAudio(audio_rate, audio_format, audio_channels, 4096) < 0) then
	begin
		Log.LogError(Format('Couldn''t open audio: %s', [SDL_GetError]), 'Main');
		TerminateApplication;
	end
	else 
	begin
		Mix_QuerySpec(audio_rate, audio_format, audio_channels);
		
		if (audio_channels > 2) then audio_channels_str := 'surround'
		else if (audio_channels > 1) then audio_channels_str := 'stereo' else audio_channels_str := 'mono';
		
		Log.LogStatus(Format('Opened audio at %d Hz %d bit %s', [audio_rate, (audio_format and $FF), audio_channels_str]), 'Main');
		
		(*
		printf("Opened audio at %d Hz %d bit %s", audio_rate,
			(audio_format&0xFF),
			(audio_channels > 2) ? "surround" :
			(audio_channels > 1) ? "stereo" : "mono");*)
	end;
end;

end.
