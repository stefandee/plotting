unit PlottingUtils;

interface

uses
  SDL,
  Logger,
  SysUtils,
  SDLUtils,
  SDL_ttf,
  fpjson,
  jsonparser,
  jsonConf,
  Math;

const
  MAX_TOP_SCORERS = 8;

type
  TTopScore = record
    entryName  : string[255];
    entryValue : integer;
  end;

  gam = array[1..10] of string[12];
  
  TLevelDef = record
    tiles: gam;
	qualify: integer;
  end;

  TTopScores = array[1..MAX_TOP_SCORERS] of TTopScore;

  {TTopScores=array[1..8] of string[20];}
  TImageList = array[0..64] of PSDL_Surface;

  TGameStates = (
    GS_INIT,
    GS_INTRO,
    GS_ORIGINAL,
    GS_CREDITS,
    GS_MENU,
    GS_MENU_CURSOR,
    GS_MENU_DEFINE_KEYS,
    GS_GAME,
    GS_EXIT,
    GS_NONE,
    GS_TRANS_BY_RECT,
    GS_TOPSCORE,
    GS_GAME_FINISHED,
    GS_ENTER_TOPSCORE,
	GS_KEYBOARD_CONTROLS
    );

  TBounceMC = record
    baseX, baseY : real;
    speedX, speedY : real;
    speedXStart, speedYStart: real;
    x, y : real;
  end;

  TTransByRectParam = record
    size : Integer;
    maxSize : Integer;
    nextState : TGameStates;
  end;

const
  Inflives:boolean = false;
  Inftime:boolean  = false;
  CheatStartLevel: integer = 1;

const
  SCREEN_WIDTH    =  853;
  SCREEN_HEIGHT   =  480;
  SCREEN_BPP      =  32;

  DEFAULT_MENU_FONT_SIZE = 14;
  DEFAULT_BIG_FONT_SIZE = 88;

  HCENTER = $01;
  VCENTER = $02;
  RIGHT   = $04;
  BOTTOM  = $08;

  MAX_LIVES = 3;
  MAX_LEVELS = 8;

  MAX_BOUNCE_MC = 10;

{ sprite index }
const
  SETTINGS_FILE_NAME = 'settings.json';

  SPR_OCEAN = 2;
  SPR_TAITO = 4;
  SPR_BF    = 0;

  SPR_HUD_WATCH_UP   = 8;
  SPR_HUD_WATCH_DOWN = 9;

  SPR_ITEM_BARREL = 14;
  SPR_ITEM_COMMIE = 15;
  SPR_ITEM_HEART  = 16;
  SPR_ITEM_SANDGLASS = 17;
  SPR_ITEM_TAITO = 18;
  SPR_ITEM_WALL = 19;
  SPR_ITEM_YANG = 20;
  SPR_ITEM_THUNDER = 21;
  SPR_ITEM_EMPTY = 22;
  SPR_ITEM_DEVIL = 23;

  SPR_CHR1 = 10;
  SPR_CHR2 = 11;
  SPR_CHR3 = 12;
  SPR_CHR4 = 13;

  SPR_ARROW_DOWN = 24;
  SPR_ARROW_RIGHT = 25;

  SPR_BOOM1 = 26;
  SPR_CHR2_10x = 41;
  
  SPR_PATTERN_000 = 42;  
  PATTERN_COUNT = 3;
  
var
  ImageList   : TImageList;
  Text        : PSDL_Surface;
  Transition  : PSDL_Surface;

  event       : TSDL_EVENT;

  {graphics}
  Screen      : PSDL_Surface;
  VideoScreen : PSDL_Surface;
  ResolutionWidth  : Integer;
  ResolutionHeight : Integer;
  Fullscreen       : Boolean;

  { keys }
  upKey,downKey, holdKey, fireKey : Integer;

  { TODO: move to separate unit - Font }
  FontMenu    : PTTF_Font;
  FontBig     : PTTF_Font;

  state       : TGameStates;
  TimeSnap    : Integer;
  TopScores   : TTopScores;

  BounceMC    : array[1..MAX_BOUNCE_MC] of TBounceMC;

  function  IsKeyDown:Boolean;
  function  KeyDown:Integer;
  function  KeyDownUnicode:Integer;
  function  LoadImage( Filename: string ) : PSDL_SURFACE;
  procedure PutImage(x, y, imgIndex, align : Integer);
  procedure ClearScreen(color : Integer);
  procedure SetFontColor(r, g, b : Integer);
  procedure SetFont(font : PTTF_Font);
  procedure OutTextXY(x, y : Integer; str : string; align : integer; size : integer = DEFAULT_MENU_FONT_SIZE);
  procedure OutTextXYWithShadow(x, y, shadowXOffset, shadowYOffset : Integer; str : string; align : integer; r, g, b : Integer; shadowR, shadowG, shadowB : Integer);
  procedure Draw_FillRect(dest : PSDL_Surface; x, y, w, h : Integer; color : UInt32);
  procedure SetTransparentSurface(Surface : PSDL_Surface);
  procedure TransByRect;
  procedure StartTransByRect(size, maxSize : Integer; nextstate : TGameStates);
  procedure TextSize(str : string; out w: Integer; out h : Integer);

  function ReadTopScores: boolean;
  function WriteTopScores: boolean;
  function GenerateTopScores: boolean;
  function IsTopScore(score : longint): boolean;
  function AddTopScore (score : longint) : integer;

  procedure InitGameFinished;

  procedure RenderBounceMC(i : integer);
  procedure UpdateBounceMC(i : integer);
  
  procedure SetDefaultSettings;

  procedure LoadSettings;
  procedure SaveSettings;
  procedure TerminateApplication;
  
  function Clamp(n : integer; lower: integer; upper: integer): integer;

implementation

var
  FontCurrent : PTTF_Font = nil;
  FontColor   : TSDL_Color;
  TransByRectParam : TTransByRectParam;

function LoadImage( Filename: string ) : PSDL_SURFACE;
var
  image: PSDL_SURFACE;
begin
  //image := nil;
  image := SDL_LoadBMP( PChar( FileName ) );
  if image <> nil then
    Result := image
  else
  begin
    Result := nil;
    Log.LogError( Format( 'Unable to Load Image : %s', [SDL_GetError]
      ),
      'LoadImage' );
  end;
end; // LoadImage

procedure SetTransparentSurface(Surface : PSDL_Surface);
begin
  SDL_SetColorKey(
	Surface, 
	SDL_SRCCOLORKEY or SDL_RLEACCEL,
    SDL_MapRGB(Surface^.format, 255, 0, 255)
  );
end;

procedure PutImage(x, y, imgIndex, align : Integer);
var
  DestRect : TSDL_Rect;
begin
 if (align and HCENTER <> 0) then
 begin
   x := x - ImageList[imgIndex]^.w div 2;
 end;

 if (align and VCENTER <> 0) then
 begin
   y := y - ImageList[imgIndex]^.h div 2;
 end;

 if (align and RIGHT <> 0) then
 begin
   x := x - ImageList[imgIndex]^.w;
 end;

 if (align and BOTTOM <> 0) then
 begin
   y := y - ImageList[imgIndex]^.h;
 end;

 DestRect.x := x;
 DestRect.y := y;
 DestRect.w := ImageList[imgIndex]^.w;
 DestRect.h := ImageList[imgIndex]^.h;

 SDL_BlitSurface(ImageList[imgIndex], nil, Screen, @DestRect);
end;

procedure ClearScreen(color : Integer);
begin
  SDL_FillRect(Screen, Nil, color);
end;

procedure SetFontColor(r, g, b : Integer);
begin
  FontColor.r := r;
  FontColor.g := g;
  FontColor.b := b;
end;

procedure SetFont(font : PTTF_Font);
begin
  FontCurrent := font;
end;

procedure OutTextXYWithShadow(x, y, shadowXOffset, shadowYOffset : Integer; str : string; align : integer; r, g, b : Integer; shadowR, shadowG, shadowB : Integer);
begin
  SetFontColor(r, g, b);
  OutTextXY(x + shadowXOffset, y + shadowYOffset, str, align);
  SetFontColor($FF, $FF, $FF);
  OutTextXY(x, y, str, align);
end;

procedure OutTextXY(x, y : Integer; str : string; align : integer; size : integer = DEFAULT_MENU_FONT_SIZE);
var
  DestRect : SDL_Rect;
  strW, strH : Integer;
begin
 if (FontCurrent = nil) then exit;

 TTF_SizeText(FontCurrent, PChar(str), strW, strH);

 if (align and HCENTER <> 0) then
 begin
   x := x - strW div 2;
 end;

 if (align and VCENTER <> 0) then
 begin
   y := y - strH div 2;
 end;

 if (align and RIGHT <> 0) then
 begin
   x := x - strW;
 end;

 if (align and BOTTOM <> 0) then
 begin
   y := y - strH;
 end;

  // TODO get the font according to the size
  // TTF_SetFontSize(size);

 { get the surface }
 Text := TTF_RenderText_Solid(FontCurrent, PChar(str), FontColor);

 if (Text = nil) then exit;

 { dump to screen the text }
 {SrcRect.x := x;
 SrcRect.y := y;
 SrcRect.w := Text^.w;
 SrcRect.h := Text^.h;}

 DestRect.x := x;
 DestRect.y := y;
 DestRect.w := Text^.w;
 DestRect.h := Text^.h;

 //SDL_BlitSurface(Text, @SrcRect, Screen, @DestRect);
 SDL_BlitSurface(Text, nil, Screen, @DestRect);
 //SDL_ZoomSurface(Text, @SrcRect, Screen, @DestRect);
end;

procedure TextSize(str : string; out w: Integer; out h : Integer);
begin
 TTF_SizeText(FontCurrent, PChar(str), w, h);
end;


procedure Draw_FillRect(dest : PSDL_Surface; x, y, w, h : Integer; color : UInt32);
var
  DestRect: TSDL_Rect;
begin
  DestRect.x := x;
  DestRect.y := y;
  DestRect.w := w;
  DestRect.h := h;

  SDL_FillRect(dest, @DestRect, color);
end;


function IsKeyDown:Boolean;
begin
  IsKeyDown := (event.type_ = SDL_KEYDOWN);
end;

function KeyDown:Integer;
begin
  if (IsKeyDown)
    then KeyDown := event.key.keysym.sym
    else KeyDown := SDLK_UNKNOWN;
end;

function KeyDownUnicode:Integer;
begin
  if (IsKeyDown)
    then KeyDownUnicode := event.key.keysym.unicode
    else KeyDownUnicode := SDLK_UNKNOWN;
end;

procedure TransByRect;
var
  Rect : TSDL_Rect;
  x, y : Integer;
begin
  SDL_BlitSurface(Transition, nil, Screen, nil);

  for x := 0 to (Screen^.w div TransByRectParam.maxSize) do
  begin
    for y := 0 to (Screen^.h div TransByRectParam.maxSize) do
    begin
      Rect.x := x * TransByRectParam.maxSize+ TransByRectParam.maxSize div 2 - TransByRectParam.size div 2;
      Rect.y := y * TransByRectParam.maxSize + TransByRectParam.maxSize div 2 - TransByRectParam.size div 2;
      Rect.w := TransByRectParam.size;
      Rect.h := TransByRectParam.size;
      SDL_FillRect(Screen, @Rect, $000000);
    end;
  end;

  inc(TransByRectParam.size);

  if (TransByRectParam.size >= TransByRectParam.maxSize) then
  begin
    state := TransByRectParam.nextState;
    TimeSnap := SDL_GetTicks();
  end;
end;

procedure StartTransByRect(size, maxSize : Integer; nextstate : TGameStates);
begin
  state := GS_TRANS_BY_RECT;
  TransByRectParam.size := size;
  TransByRectParam.maxSize := maxSize;
  TransByRectParam.nextState := nextstate;
end;

function ReadTopScores: boolean;
var
  f : file of TTopScores;
begin
  assign(f,'data/HighScores');

  {$I-}
  reset(f, 1);
  {$I+}

  if IOResult <> 0 then begin
    ReadTopScores := false;
    exit;
  end;

  read(f, TopScores);
  close(f);

  ReadTopScores := true;
end;

function WriteTopScores: boolean;
var
  f : file of TTopScores;
begin
  assign(f,'data/HighScores');
  rewrite(f);
  write(f, TopScores);
  close(f);

  WriteTopScores := true;
end;

function GenerateTopScores: boolean;
begin
  TopScores[1].entryName  := 'PHANE';
  TopScores[1].entryValue := 100000;

  TopScores[2].entryName := 'ALECSEI';
  TopScores[2].entryValue := 99999;

  TopScores[3].entryName := 'BFW SOFT';
  TopScores[3].entryValue := 80000;

  TopScores[4].entryName := 'AT LEAST';
  TopScores[4].entryValue := 70000;

  TopScores[5].entryName:='PAIN LASTS';
  TopScores[5].entryValue := 60000;

  TopScores[6].entryName:='NO WAY PUNK';
  TopScores[6].entryValue := 50000;

  TopScores[7].entryName:='THIS TOP IS';
  TopScores[7].entryValue := 40000;

  TopScores[8].entryName:='OUT OF TOUCH';
  TopScores[8].entryValue := 30000;

  WriteTopScores;

  GenerateTopScores := true;
end;

function IsTopScore(score : longint): boolean;
var
  i : integer;
begin
  IsTopScore := false;

  for i:=1 to 8 do
    begin
      if TopScores[i].entryValue <= score then begin
        IsTopScore := true;
        exit;
      end;
    end;
end;

function AddTopScore (score : longint) : integer;
var
  i, j : integer;
begin
  AddTopScore := -1;

  if not IsTopScore(score) then
    exit;

  for i:=1 to 8 do
    begin
      if TopScores[i].entryValue <= score then begin
        for j := 8 downto i + 1 do
          begin
            TopScores[j] := TopScores[j - 1];
          end;

        TopScores[i].entryName  := '';
        TopScores[i].entryValue := score;

        AddTopScore := i;

        exit;
      end;
    end;
end;

procedure InitGameFinished;
var
  i : integer;
begin
  for i:= 1 to MAX_BOUNCE_MC do
    begin
      BounceMC[i].baseX := 20 + random(640 - 60);
      BounceMC[i].baseY := 160 + random(480 - 160 - 40);

      BounceMC[i].x := BounceMC[i].baseX;
      BounceMC[i].y := BounceMC[i].baseY;

      BounceMC[i].speedXStart := 0;
      BounceMC[i].speedYStart := -100 - random(80);

      BounceMC[i].speedX := BounceMC[i].speedXStart;
      BounceMC[i].speedY := BounceMC[i].speedYStart;
    end;
end;

procedure UpdateBounceMC(i : integer);
begin
  if (i < 0) or (i > MAX_BOUNCE_MC) then
    exit;

  BounceMC[i].speedY := BounceMC[i].speedY + 20 * 9.81 * 0.03;
  BounceMC[i].x := BounceMC[i].x + BounceMC[i].speedX * 0.03;
  BounceMC[i].y := BounceMC[i].y + BounceMC[i].speedY * 0.03;

  if (BounceMC[i].y > BounceMC[i].baseY) then begin
    BounceMC[i].speedY := BounceMC[i].speedYStart;
    BounceMC[i].y := BounceMC[i].baseY;
  end;

end;

procedure RenderBounceMC(i : integer);
begin
  if (i < 0) or (i > MAX_BOUNCE_MC) then
    exit;

  if ((BounceMC[i].y <= BounceMC[i].baseY) and (BounceMC[i].y >= BounceMC[i].baseY - 4)) then
    Putimage(trunc(BounceMC[i].x), trunc(BounceMC[i].y), SPR_CHR4, 0)
  else
    Putimage(trunc(BounceMC[i].x), trunc(BounceMC[i].y), SPR_CHR2, 0)
end;

procedure SetDefaultSettings;
begin
  upKey   := SDLK_UP;
  downKey := SDLK_DOWN;
  fireKey := SDLK_SPACE;
  holdKey := SDLK_P;
  ResolutionWidth := SCREEN_WIDTH;
  ResolutionHeight := SCREEN_HEIGHT;
  FullScreen := false;
  
  inftime  := false;
  inflives := false;
end;

procedure LoadSettings;
var
  c: TJSONConfig;
begin
  c:= TJSONConfig.Create(Nil);
  try
    //try/except to handle broken json file
    try
      c.Formatted:= true;
      c.Filename:= SETTINGS_FILE_NAME;
    except
      exit;
    end;

    upKey:= c.GetValue('/keyboard/up', SDLK_UP);
    downKey:= c.GetValue('/keyboard/down', SDLK_DOWN);
    fireKey:= c.GetValue('/keyboard/fire', SDLK_SPACE);
    holdKey:= c.GetValue('/keyboard/pause', SDLK_P);
	
    ResolutionWidth := Max(c.GetValue('/graphics/resolution/width', SCREEN_WIDTH), SCREEN_WIDTH);
    ResolutionHeight := Max(c.GetValue('/graphics/resolution/height', SCREEN_HEIGHT), SCREEN_HEIGHT);
    FullScreen := c.GetValue('/graphics/resolution/fullScreen', false);
	
    InfTime := c.GetValue('/cheats/freeze', false);
    InfLives := c.GetValue('/cheats/blast', false);	
	CheatStartLevel := Clamp(c.GetValue('/cheats/spacewarp', 1), 1, MAX_LEVELS);
  finally
    c.Free;
  end;end;

procedure SaveSettings;
var
  c: TJSONConfig;
begin
  c:= TJSONConfig.Create(Nil);
  try
    //try/except to handle broken json file
    try
      c.Formatted:= true;
      c.Filename:= SETTINGS_FILE_NAME;
    except
      exit;
    end;

    c.SetValue('/keyboard/up', upKey);
    c.SetValue('/keyboard/down', downKey);
    c.SetValue('/keyboard/fire', fireKey);
    c.SetValue('/keyboard/pause', holdKey);

    c.SetValue('/graphics/resolution/width', ResolutionWidth);
    c.SetValue('/graphics/resolution/height', ResolutionHeight);
    c.SetValue('/graphics/resolution/fullScreen', FullScreen);

    c.SetValue('/cheats/freeze', InfTime);
    c.SetValue('/cheats/blast', InfLives);
	c.SetValue('/cheats/spacewarp', CheatStartLevel);
  finally
    c.Free;
  end;
end;

procedure TerminateApplication;
var
  i : integer;
begin
  // Free Surfaces
  for i := Low(ImageList) to High(ImageList) do
    SDL_FreeSurface( ImageList[i] );
  SDL_QUIT;
  Halt(0);
end;

function Clamp(n : integer; lower: integer; upper: integer): integer;
begin
  Clamp := Math.Max(lower, Math.Min(n, upper));
end;

end.
