unit game;

interface

uses
  SDL,
  SDLUtils,
  PlottingUtils,
  Math,
  Audio,
  Music;

procedure InitGame;
procedure RenderGame;
procedure UpdateGame;
procedure InitLevelTitle;

var
  Score          : longint;
  TopScoreIndex  : integer;
  LevelBackground : PSDL_Surface;

implementation

type
  TMCState = (
    MC_STATE_IDLE,
    MC_STATE_PUSH1,
    MC_STATE_PUSH2,
    MC_STATE_PUSH_END,
    MC_STATE_WAIT_ZAP,
    MC_STATE_JUMP,
    MC_STATE_FALL,
    MC_STATE_LAND
  );

  TGameOutcome = (
    GO_WIN,
    GO_DIE, { indeed :) }
    GO_TIME_UP
  );

  TArrowOrientation = (
    AO_RIGHT,
    AO_DOWN
  );

  TGamePlayState = (
    GPS_INIT,
    GPS_PLAY,
    GPS_END
  );

  TAutoMsg = record
    enabled   : boolean;
    text      : string;
    box       : boolean;
    timeDelay : integer;
    timeSnap  : integer;
  end;

  TArrowParam = record
    x, y : integer;
    visible : boolean;
    orient : TArrowOrientation;
  end;

  TExplosion = record
    active      : boolean;
    x, y        : integer;
    frame       : integer;
    timeSnap    : integer;
    {columnShift : boolean;}
  end;

const
  { 90 seconds for each level to complete }
  LEVEL_TIME = 90000;

  { time warning threshold }
  LEVEL_WARN_TIME = 15000;

  LEVEL_TITLE_DELAY = 20000;

  MAX_EXPLOSIONS = 120;
  
  MAX_EXPLOSION_FRAMES = 15;
  
  PLAY_AREA_X_OFFSET = 40;
  
  PLAY_AREA_Y_OFFSET = 40;
  
  PLAY_AREA_X_TILES = 12;
  
  PLAY_AREA_Y_TILES = 10;
  
  TILE_SIZE_X = 40;
  
  TILE_SIZE_Y = 40;
  
  { tile types }  
  TILE_WILDCARD = 't';
  TILE_EXTRA_LIFE = 't';
  TILE_BONUS_TIME = 'c';
  TILE_WALL = 'w';
  TILE_BARREL = 'b';
  TILE_EMPTY = ' ';
  
  { scoring }
  SCORE_TILE_ZAP = 600;
  SCORE_REMAINING = 1000;
  SCORE_POINTS_PER_SECOND = 10;

var
  LevelDef : TLevelDef;
  ox, oy, aox, aoy, aodx, aody, hit, remains:integer;
  bonusScoreTiles, bonusScoreTime : integer;
  g1, holds : gam;
  lives, level, qualify:integer;
  ArrowParam : TArrowParam;

  TileHeld       : Integer;
  MCState        : TMCState;
  LastGetTicks   : Integer;
  ElapsedTime    : Integer;    
  {MCPosX, MCPosY, MCSpeedX, MCSpeedY : real;}
  MCAnimTimeSnap : Integer;
  Paused         : boolean;
  AutoMsg        : TAutoMsg;
  GameOutcome    : TGameOutcome;
  GamePlayState  : TGamePlayState;
  TimerWarningAudioTriggered: boolean;

  Explosions     : array[1..MAX_EXPLOSIONS] of TExplosion;

procedure RenderTile(g:string;coordx,coordy:integer);forward;
procedure RenderPlayfield(g:gam);forward;
procedure RenderHUD; forward;
procedure RenderMC; forward;
procedure RenderExplosions; forward;

procedure UpdateZap; forward;
procedure UpdateExplosions; forward;

procedure SetupLevel; forward;
procedure VerifyMCMove;forward;
function  ComputeRemains: Integer; forward;
{procedure change(g:string);forward;}
function  Addscore:boolean;forward;
function  Check:boolean;forward;
procedure ComputeArrowParam; forward;
procedure AddExplosion(x, y : integer); forward;
procedure ResetExplosions; forward;
function IsNormalTile(tile : char) : boolean; forward;
function IsEmptyTile(tile : char) : boolean; forward;
function IsSpecialTile(tile : char) : boolean; forward;
procedure TransitionToMenu; forward;

procedure SetMCState(state : TMCState);
begin
  MCState := state;
  MCAnimTimeSnap := SDL_GetTicks();
end;

procedure InitZap;
begin
  hit := 0;
  aox := ox;
  aoy := oy + 1;
  aodx := 0;
  aody := 1;
end;

procedure InitLevelBackground;
var
  DestRect : TSDL_Rect;
  x, y : Integer;
  tileW, tileH : Integer;
  patternIndex : Integer;
begin
  tileW := ImageList[SPR_ITEM_WALL]^.w;
  tileH := ImageList[SPR_ITEM_WALL]^.h;
  
  for x := 0 to (Screen^.w div tileW) do
  begin
    for y := 0 to (Screen^.h div tileH) do
    begin
      DestRect.x := x * tileW;
      DestRect.y := y * tileH;
      DestRect.w := tileW;
      DestRect.h := tileH;
    
      SDL_BlitSurface(ImageList[SPR_ITEM_WALL], nil, LevelBackground, @DestRect);   
      {Putimage(x * tileW, y * tileH, SPR_ITEM_WALL, 0)}
    end;
  end;

  {game area background}
  Draw_FillRect(LevelBackground, PLAY_AREA_X_OFFSET, PLAY_AREA_Y_OFFSET, PLAY_AREA_X_TILES * TILE_SIZE_X, PLAY_AREA_Y_TILES * TILE_SIZE_Y, $000000);

  patternIndex := (level - 1) mod PATTERN_COUNT + SPR_PATTERN_000;
  
  for x := 0 to PLAY_AREA_X_TILES - 1 do
  begin
      for y := 0 to PLAY_AREA_Y_TILES - 1 do
      begin
        DestRect.x := x * TILE_SIZE_X + PLAY_AREA_X_OFFSET;
        DestRect.y := y * TILE_SIZE_Y + PLAY_AREA_Y_OFFSET;
        DestRect.w := TILE_SIZE_X;
        DestRect.h := TILE_SIZE_Y;
      
        SDL_BlitSurface(ImageList[patternIndex], nil, LevelBackground, @DestRect);  
      end;
  end;
  
  {erase for clock area}
  Draw_FillRect(LevelBackground, 600, PLAY_AREA_Y_OFFSET, 160, 120, $000000);
end;

procedure SetupLevel;
var
  f : file;
begin
  assign(f, 'data/Levels');
  reset(f, 1);
  seek(f, (level-1) * sizeof(LevelDef));
  blockread(f, LevelDef, sizeof(LevelDef));
  close(f);

  qualify := LevelDef.qualify;
  g1 := LevelDef.tiles;

  { every 6 levels increase the difficulty }
  { if (level div 6) = (int(level div 6)) then dec(qualify);}

  InitLevelBackground;

  MCState    := MC_STATE_IDLE;
  TileHeld   := SPR_ITEM_THUNDER;
  {ang        := 90;}
  ox         := 1;
  oy         := 1;
  holds[1,1]   := TILE_WILDCARD;
  hit := 0;
  
  bonusScoreTiles := 0;
  bonusScoreTime := 0;
  
  LastGetTicks := SDL_GetTicks();
  ElapsedTime  := 0;

  remains    := ComputeRemains;

  ComputeArrowParam;

  ResetExplosions;
  TimerWarningAudioTriggered := false;
end;

procedure InitGame;
begin
  { settings }
  lives   := MAX_LIVES;
  level   := CheatStartLevel;
  qualify := 10;
  score   := 0;
  bonusScoreTiles := 0;
  bonusScoreTime := 0;

  { load the first level }
  SetupLevel;

  Paused := false;

  AutoMsg.enabled := false;
  GameOutcome     := GO_WIN;
  GamePlayState   := GPS_INIT;
  TimerWarningAudioTriggered := false;

  StopModule;
  InitLevelTitle;
end;

procedure UpdateGame;
var
  key : Integer;
begin
  key := KeyDown;

  if AutoMsg.enabled then begin
    if (SDL_GetTicks() - AutoMsg.timeSnap > AutoMsg.timeDelay) then begin
      AutoMsg.enabled := false;
    end;
  end;

  case GamePlayState of
    GPS_INIT:
      begin
        if (IsKeyDown or (SDL_GetTicks() - TimeSnap > LEVEL_TITLE_DELAY)) then
        begin
          GamePlayState := GPS_PLAY;
		  LoadModule(MUSIC_GAME_FILE_NAME);
		  PlayModule;
        end;
      end;

    GPS_PLAY:
      begin
        
        if key = holdKey then
          Paused := not Paused;

        if Paused then 
        begin
          LastGetTicks := SDL_GetTicks();
          exit;
        end;

        case MCState of
          MC_STATE_IDLE:
            begin
              if (key = upKey) then
              begin
                dec(ox);
                PlayAudioOneShot(SND_MOVE);
                VerifyMCMove;
                ComputeArrowParam;
              end;

              if (key = downKey) then
              begin
                inc(ox);
                PlayAudioOneShot(SND_MOVE);
                VerifyMCMove;
                ComputeArrowParam;
              end;

              if (key = fireKey) then
              begin
                PlayAudioOneShot(SND_SHOOT);
                SetMCState(MC_STATE_PUSH1);
              end;
            end;

          MC_STATE_PUSH1:
            begin
              if (SDL_GetTicks() - MCAnimTimeSnap > 50) then begin
                SetMCState(MC_STATE_PUSH2);
              end;
            end;

          MC_STATE_PUSH2:
            begin
              if (SDL_GetTicks() - MCAnimTimeSnap > 50) then begin
                SetMCState(MC_STATE_PUSH_END);
              end;
            end;

          MC_STATE_PUSH_END:
            begin
              if (SDL_GetTicks() - MCAnimTimeSnap > 50) then begin
                InitZap;
                SetMCState(MC_STATE_WAIT_ZAP);
              end;
            end;

          MC_STATE_WAIT_ZAP:
            begin
              UpdateZap;
            end;
        end;

        if (key = SDLK_ESCAPE) then
        begin
          { TODO: transition + quit dialog :) }
		  TransitionToMenu;
        end;

        UpdateExplosions;

        ElapsedTime += SDL_GetTicks() - LastGetTicks;
        LastGetTicks := SDL_GetTicks();

        if ElapsedTime > LEVEL_TIME then begin
		  StopModule;	
		
          GamePlayState := GPS_END;

          dec(lives);

          if (lives = 0) then GameOutcome := GO_DIE
          else GameOutcome := GO_TIME_UP;
        end;

      end;

    GPS_END:
      begin
        if (IsKeyDown) then begin
          case GameOutcome of
            GO_WIN:
              begin
                inc(level);

                if (level > MAX_LEVELS) then begin
                  InitGameFinished;
                  StartTransByRect(2, 12, GS_GAME_FINISHED);
                end
                else begin
                  SetupLevel;

                  Paused := false;

                  AutoMsg.enabled := false;
                  GamePlayState   := GPS_INIT;

                  InitLevelTitle;
                end;
              end;

            GO_DIE:
              begin
                { if we have a top score, let the player enter it's name;
                  otherwise exit to main menu }
                if (IsTopScore(Score)) then begin
                  TopScoreIndex := AddTopScore(score);
                  StartTransByRect(2, 12, GS_ENTER_TOPSCORE);
                end
                else begin
		          TransitionToMenu;
                end;
              end;

            GO_TIME_UP:
              begin
				PlayModule;
			  
                { restart this level }
                SetupLevel;

                Paused := false;

                AutoMsg.enabled := false;
                GamePlayState   := GPS_PLAY;

                InitLevelTitle;
              end;
          end;
        end;
      end;
  end;
end;

procedure InitLevelTitle;
begin
  BounceMC[1].baseX := 0.0;
  BounceMC[1].baseY := 250.0;

  BounceMC[1].x := BounceMC[1].baseX;
  BounceMC[1].y := BounceMC[1].baseY;

  BounceMC[1].speedXStart := 50.0;
  BounceMC[1].speedYStart := -100;

  BounceMC[1].speedX := BounceMC[1].speedXStart;
  BounceMC[1].speedY := BounceMC[1].speedYStart;
end;

procedure InitJoyBounce;
begin
  BounceMC[1].baseX := 35.0;
  BounceMC[1].baseY := Screen^.h div 2 - 15;

  BounceMC[1].x := BounceMC[1].baseX;
  BounceMC[1].y := BounceMC[1].baseY;

  BounceMC[1].speedXStart := 0.0;
  BounceMC[1].speedYStart := -150;

  BounceMC[1].speedX := BounceMC[1].speedXStart;
  BounceMC[1].speedY := BounceMC[1].speedYStart;
end;

procedure RenderLevelTitle;
var
  m : string;
  floorTileX, wallTileY, floorTileCount: integer;
begin
  { render the floor }
  floorTileCount := Round(SCREEN_WIDTH div 40);
  
  for floorTileX := 0 to floorTileCount do
  begin
    { render the wall }
    for wallTileY := 0 to 2 do	
		PutImage(floorTileX * 40, 290 - wallTileY * 40, SPR_PATTERN_000, BOTTOM);
		
	PutImage(floorTileX * 40, 290, SPR_ITEM_WALL, 0);
  end;
  
  UpdateBounceMC(1);

  if (BounceMC[1].x > Screen^.w) then BounceMC[1].x := 0.0;

  RenderBounceMC(1);

  { stage # }
  SetFont(FontMenu);

  SetFontColor($FF, $FF, $FF);

  str(level, m);
  OutTextXY(Screen^.w div 2, Screen^.h div 2 - 100, 'STAGE ' + m, HCENTER or VCENTER);
end;

procedure RenderGame;
var
  m : string;
begin
  case GamePlayState of
    GPS_INIT:
      begin
        RenderLevelTitle;
      end;

    GPS_PLAY:
      begin
        SDL_BlitSurface(LevelBackground, nil, Screen, nil);
        
        RenderHUD;
        RenderPlayfield(g1);
        RenderMC;
        RenderExplosions;

        if ArrowParam.visible and (MCState = MC_STATE_IDLE) then begin
          if ArrowParam.orient = AO_DOWN then
            Putimage((ArrowParam.y-1)*40+PLAY_AREA_X_OFFSET, (ArrowParam.x-1)*40+PLAY_AREA_Y_OFFSET, SPR_ARROW_DOWN, 0)
          else
            Putimage((ArrowParam.y-1)*40+PLAY_AREA_X_OFFSET, (ArrowParam.x-1)*40+PLAY_AREA_Y_OFFSET, SPR_ARROW_RIGHT, 0);
        end;

        if AutoMsg.enabled then begin
          if (AutoMsg.box) then begin
            Draw_FillRect(Screen, 0, Screen^.h div 2 - 60, Screen^.w, 120, $80000000);
            Draw_FillRect(Screen, 0, Screen^.h div 2 - 70, Screen^.w, 10, $80FFFF00);
            Draw_FillRect(Screen, 0, Screen^.h div 2 + 60, Screen^.w, 10, $80FFFF00);
          end;

          SetFont(FontBig);
          SetFontColor($FF, $00, $00);

          OutTextXY(Screen^.w div 2, Screen^.h div 2, AutoMsg.text, HCENTER or VCENTER);
        end;

        if Paused then begin
          Draw_FillRect(Screen, 0, Screen^.h div 2 - 60, Screen^.w, 120, $000000);
          Draw_FillRect(Screen, 0, Screen^.h div 2 - 70, Screen^.w, 10, $FFFF00);
          Draw_FillRect(Screen, 0, Screen^.h div 2 + 60, Screen^.w, 10, $FFFF00);

          SetFont(FontBig);
          SetFontColor($FF, $FF, $00);

          OutTextXY(Screen^.w div 2, Screen^.h div 2, 'PAUSED', HCENTER or VCENTER);
        end;
      end;

    GPS_END:
      begin
        SDL_BlitSurface(LevelBackground, nil, Screen, nil);
        
        RenderHUD;
        RenderPlayfield(g1);

        if (GameOutCome = GO_DIE) or (GameOutcome = GO_TIME_UP) then
          RenderMC;

        case GameOutcome of
          GO_WIN:
            begin
              Draw_FillRect(Screen, 0, Screen^.h div 2 - 70, Screen^.w, 140, $000000);
              Draw_FillRect(Screen, 0, Screen^.h div 2 - 80, Screen^.w, 10, $FFFF00);
              Draw_FillRect(Screen, 0, Screen^.h div 2 + 70, Screen^.w, 10, $FFFF00);

              SetFont(FontBig);
              SetFontColor($FF, $FF, $00);
              OutTextXY(Screen^.w div 2, Screen^.h div 2 - 20, 'AWESOME!', HCENTER or VCENTER);

              SetFont(FontMenu);
              SetFontColor($FF, $FF, $FF);
			  
              str(bonusScoreTiles, m);
              OutTextXY(Screen^.w div 2, Screen^.h div 2 + 30, 'CLEAR BONUS: ' + m, HCENTER or VCENTER);
			  
              str(bonusScoreTime, m);
              OutTextXY(Screen^.w div 2, Screen^.h div 2 + 50, 'TIME BONUS: ' + m, HCENTER or VCENTER);

              UpdateBounceMC(1);
              RenderBounceMC(1);

            end;

            GO_DIE:
              begin
                Draw_FillRect(Screen, 0, Screen^.h div 2 - 60, Screen^.w, 120, $000000);
                Draw_FillRect(Screen, 0, Screen^.h div 2 - 70, Screen^.w, 10, $FFFF00);
                Draw_FillRect(Screen, 0, Screen^.h div 2 + 60, Screen^.w, 10, $FFFF00);

                SetFont(FontBig);
                SetFontColor($FF, $00, $00);
                OutTextXY(Screen^.w div 2, Screen^.h div 2, 'GAME OVER', HCENTER or VCENTER);
              end;

            GO_TIME_UP:
              begin
                Draw_FillRect(Screen, 0, Screen^.h div 2 - 60, Screen^.w, 120, $000000);
                Draw_FillRect(Screen, 0, Screen^.h div 2 - 70, Screen^.w, 10, $FFFF00);
                Draw_FillRect(Screen, 0, Screen^.h div 2 + 60, Screen^.w, 10, $FFFF00);

                SetFont(FontBig);
                SetFontColor($FF, $FF, $00);
                OutTextXY(Screen^.w div 2, Screen^.h div 2, 'TIME''S UP!', HCENTER or VCENTER);
              end;
        end;
      end;
  end;
end;

procedure RenderHUD;
const
  BuzzOffsetX : integer = 0;
  BuzzOffsetY : integer = 0;

var
  m : string;
  i : integer;
  x, y : integer;
  color : integer;
  angleLimit : integer;
  angleBuzz : integer;
  j : real;
begin
  { alarm!!! shake the clock when there's little time left :) }
  { ...but dont shake it if the time is already up; it's annoying }
  if (ElapsedTime > LEVEL_TIME - LEVEL_WARN_TIME) and
     (GamePlayState <> GPS_END) then begin
    BuzzOffsetX := 4 * (1 - random(3));
    BuzzOffsetY := 4 * (1 - random(3));
	
	if TimerWarningAudioTriggered = false then begin
	  TimerWarningAudioTriggered := true;
	  PlayAudioOneShot(SND_TIME_WARNING);
	end;
  end;

  { render the time elapsed; need a pie draw :) }
  if (GamePlayState <> GPS_END) then begin
    angleLimit := ElapsedTime * 360 div LEVEL_TIME;
  end
  else begin
    { stop showing the time lapse }
    angleLimit := 360;
  end;

  angleBuzz  := (LEVEL_TIME - LEVEL_WARN_TIME) * 360 div LEVEL_TIME;

  for i := 90 downto 90 - angleLimit do
    begin
      color := $FFFF00;

      if (i < 90 - angleBuzz) then
        color := $FF0000;

      j := i;

      { compensate for visual artifacts by using less than 1 degree increments }
      while (j > i - 1) do
        begin
          x := round(26 * cos(j * PI / 180));
          y := round(26 * sin(j * PI / 180));

          SDL_DrawLine(Screen, 632 + 45 + BuzzOffsetX, 100 + BuzzOffsetY, 632 + 45 + x + BuzzOffsetX, 100 - y + BuzzOffsetY, color);

          j := j - 0.3;
        end;
    end;

  { render the clock }
  { TODO: buzz when there's LEVEL_WARN_TIME ms left to play }
  PutImage(632 + BuzzOffsetX, 55 + BuzzOffsetY, SPR_HUD_WATCH_UP, 0);
  PutImage(632 + BuzzOffsetX, 100 + BuzzOffsetY, SPR_HUD_WATCH_DOWN, 0);

  SetFont(FontMenu);

  str(level, m);
  OutTextXYWithShadow(600, 180, 3, 3, 'Stage: ' + m, VCENTER, $00, $00, $00, $FF, $FF, $FF);

  str(remains, m);  
  OutTextXYWithShadow(600, 220, 3, 3, 'Remain: ' + m, VCENTER, $00, $00, $00, $FF, $FF, $FF);
  
  str(qualify, m);
  OutTextXYWithShadow(600, 260, 3, 3, 'Qualify: ' + m, VCENTER, $00, $00, $00, $FF, $FF, $FF);

  str(score, m);
  OutTextXYWithShadow(600, 300, 3, 3, 'Score: ' + m, VCENTER, $00, $00, $00, $FF, $FF, $FF);
  
  PutImage(600, 360, SPR_ITEM_THUNDER, 0);
  str(lives,m);
  OutTextXYWithShadow(640, 380, 3, 3, ' x ' + m, VCENTER, $00, $00, $00, $FF, $FF, $FF);
end;

{ renders a single tile }
procedure RenderTile(g:string; coordx, coordy : integer);
begin;
  if g='w' then putimage(PLAY_AREA_X_OFFSET+40*coordy, PLAY_AREA_Y_OFFSET+40*coordx, SPR_ITEM_WALL, 0);
  if g='b' then putimage(PLAY_AREA_X_OFFSET+40*coordy, PLAY_AREA_Y_OFFSET+40*coordx, SPR_ITEM_BARREL, 0);
  if g='t' then putimage(PLAY_AREA_X_OFFSET+40*coordy, PLAY_AREA_Y_OFFSET+40*coordx, SPR_ITEM_THUNDER, 0);
  if g='s' then putimage(PLAY_AREA_X_OFFSET+40*coordy, PLAY_AREA_Y_OFFSET+40*coordx, SPR_ITEM_COMMIE, 0);
  if g='a' then putimage(PLAY_AREA_X_OFFSET+40*coordy, PLAY_AREA_Y_OFFSET+40*coordx, SPR_ITEM_TAITO, 0);
  if g='p' then putimage(PLAY_AREA_X_OFFSET+40*coordy, PLAY_AREA_Y_OFFSET+40*coordx, SPR_ITEM_DEVIL, 0);
  if g='h' then putimage(PLAY_AREA_X_OFFSET+40*coordy, PLAY_AREA_Y_OFFSET+40*coordx, SPR_ITEM_HEART, 0);
  if g='y' then putimage(PLAY_AREA_X_OFFSET+40*coordy, PLAY_AREA_Y_OFFSET+40*coordx, SPR_ITEM_YANG, 0);
  if g='c' then putimage(PLAY_AREA_X_OFFSET+40*coordy, PLAY_AREA_Y_OFFSET+40*coordx, SPR_ITEM_SANDGLASS, 0);
  {if g=' ' then putimage(PLAY_AREA_X_OFFSET+40*coordy, PLAY_AREA_Y_OFFSET+40*coordx, SPR_ITEM_EMPTY, 0);}
end;

{ renders the playfield tiles }
procedure RenderPlayfield(g:gam);
var
  i,j:integer;
begin;
  for i:=0 to 9 do
    begin
      for j:=0 to 11 do
        begin
          RenderTile(g1[i+1,j+1],i,j);
        end;
    end;
end;

procedure RenderMC;
const
  holdsTile : boolean = false;
begin
  { not the most beutiful way of doing character animation :) }
  case MCState of
    MC_STATE_IDLE:
      begin
        Putimage((oy-1)*40+PLAY_AREA_X_OFFSET, (ox-1)*40+PLAY_AREA_Y_OFFSET, SPR_CHR2, 0);

        holdsTile := true;
      end;

    MC_STATE_PUSH1:
      begin
        Putimage((oy-1)*40+PLAY_AREA_X_OFFSET, (ox-1)*40+PLAY_AREA_Y_OFFSET, SPR_CHR1, 0);

        holdsTile := true;
      end;

    MC_STATE_PUSH2:
      begin
        Putimage((oy-1)*40+PLAY_AREA_X_OFFSET, (ox-1)*40+PLAY_AREA_Y_OFFSET, SPR_CHR2, 0);

        holdsTile := true;
      end;

    MC_STATE_PUSH_END:
      begin
        Putimage((oy-1)*40+PLAY_AREA_X_OFFSET, (ox-1)*40+PLAY_AREA_Y_OFFSET, SPR_CHR3, 0);

        holdsTile := true;
      end;

    MC_STATE_WAIT_ZAP:
      begin
        Putimage((oy - 1)*40+PLAY_AREA_X_OFFSET, (ox-1)*40+PLAY_AREA_Y_OFFSET, SPR_CHR2, 0);
        PutImage((aoy - 1)*40+PLAY_AREA_X_OFFSET, (aox-1)*40+PLAY_AREA_Y_OFFSET, TileHeld, 0);

        holdsTile := false;
      end;
  end;

  { render the tile held by the MC }
  if holdsTile then begin
    PutImage(oy*40+PLAY_AREA_X_OFFSET, (ox-1)*40+PLAY_AREA_Y_OFFSET, TileHeld, 0);
  end;
end;

function ComputeRemains: Integer;
var
  i, j, r : integer;
begin
  r := 0;

  for i:=0 to 9 do
    begin
      for j:=0 to 11 do
        begin
          if (g1[i+1,j+1]<>' ') and (g1[i+1,j+1]<>'w') and (g1[i+1,j+1]<>'b') then inc(r);
        end;
    end;

  ComputeRemains := r;
end;

procedure VerifyMCMove;
begin
  if ox<1 then ox := 1;
  if ox>10 then ox := 10;
end;

procedure Change(g:string);
begin
  if g='t' then TileHeld := SPR_ITEM_THUNDER;
  if g='s' then TileHeld := SPR_ITEM_COMMIE;
  if g='a' then TileHeld := SPR_ITEM_TAITO;
  if g='p' then TileHeld := SPR_ITEM_DEVIL;
  if g='h' then TileHeld := SPR_ITEM_HEART;
  if g='y' then TileHeld := SPR_ITEM_YANG;
end;

procedure UpdateZap;
var
  current, next, hold: char;  
begin
  current := g1[aox, aoy];
  hold := holds[1, 1];

  { handle special tiles }
  if (current = TILE_EXTRA_LIFE) then begin
    AddExplosion(aox, aoy);
    g1[aox, aoy] := TILE_EMPTY;
    PlayAudioOneShot(SND_POWERUP);
    inc(lives);
  end;
  
  if (current = TILE_BONUS_TIME) then begin
    AddExplosion(aox, aoy);
    g1[aox, aoy] := TILE_EMPTY;
    PlayAudioOneShot(SND_POWERUP);
    ElapsedTime := Max(0, ElapsedTime - 10000);
  end;

  if not IsEmptyTile(current) then begin
	if hold = TILE_WILDCARD then begin	
      inc(hit);
	  
	  holds[1, 1] := current;
	  hold := current;
	  
      change(holds[1,1]);
	  
      g1[aox, aoy] := TILE_EMPTY;
      AddExplosion(aox, aoy);
      PlayAudioOneShot(SND_TILE_POP);
	end
	else if hold = current then begin
      inc(hit);
	  
      g1[aox, aoy] := TILE_EMPTY;
      AddExplosion(aox, aoy);
      PlayAudioOneShot(SND_TILE_POP);
	end 
	else begin	  
	  if hit > 0 then begin
	    holds[1, 1] := current;
        g1[aox, aoy] := hold;
		
        change(holds[1,1]);
	  end;
	  
      MCState := MC_STATE_IDLE;
	  AddScore;
	  
      exit;	  
	end;		
  end;
  
  { moving right specific logic }
  if (aody > 0) then begin
    if (aody < 12) then begin	
      next := g1[aox + aodx, aoy + aody];
	  
	  { hitting barrel or wall while moving right changes direction to down }	  
	  if (next = TILE_WALL) or (next = TILE_BARREL) then begin
	    aody := 0;
	    aodx := 1;
	  end;
    end;
  end;
  
  { moving down specific logic }
  if (aodx > 0) then begin
    if (aodx < 10) then begin
      next := g1[aox + aodx, aoy + aody];
	  
	  { hitting barrel or wall while moving down ends zapping }
      if (next = TILE_WALL) or (next = TILE_BARREL) then begin
        MCState := MC_STATE_IDLE;
	    AddScore;
	    exit;
	  end;
    end;
  end;
  
  aox := aox + aodx;
  aoy := aoy + aody;
  
  { check for horizontal end of the board and switch to move down }
  if (aoy > 12) then begin
    aoy := 12;
	aody := 0;
	aodx := 1;
  end;
  
  { check for vertical end of the board }
  if (aox > 10) then begin
    MCState := MC_STATE_IDLE;
	AddScore;
  end;

  (*
  { moving right }
  if (aody > 0) then begin

    { check ahead: bounce into a wall or barrell -> change direction downward }
    if (aoy < 12) and ((g1[aox,aoy + aody]='b') or (g1[aox,aoy + aody]='w')) then begin
      {dec(aoy);}

      {if addscore=true then exit;}

      aody := 0;
      aodx := 1;
    end;

    { lives++ tile, continue to move }
    if (g1[aox,aoy] = 't') then begin
      PlayAudioOneShot(SND_POWERUP);
      g1[aox,aoy] := holds[1,1];
      inc(lives);
    end;

    { time bonus tile, continue move }
    if (g1[aox,aoy]='c') then begin
      PlayAudioOneShot(SND_POWERUP);
	  
      g1[aox,aoy]:=holds[1,1];

      {inc(time, 10);}
      {inc(StartTimeSnap, 10000);}
      ElapsedTime := Max(0, ElapsedTime - 10000);
    end;

    { no more moves - the tile is different than the one we shot }
    if (g1[aox,aoy]<>' ') and
       (g1[aox,aoy]<>holds[1,1]) and
       (holds[1,1]<>'t') then begin

	   writeln('going right and exit due to unmatched tile ', aox, ' ', aoy, ' ', g1[aox,aoy], ' ', holds[1,1]);

      MCState := MC_STATE_IDLE;
	  
      if addscore=true then exit;
      {if check=true then exit;}

      {ComputeArrowParam;}
      exit;
    end;

    { tile zap - with a normal tile or with the wildcard/thunder }
    if ( g1[aox,aoy]=holds[1,1]) or
        ((holds[1,1]='t') and (g1[aox,aoy]<>' ')) then begin

      writeln('going right inc(hit) ', hit);
      inc(hit);

      if holds[1,1]='t' then begin
        holds[1,1]:=g1[aox,aoy];
        change(holds[1,1]);
      end;

      { TODO: explosions }
      {
      putimage((aoy-1)*40+10,(aox-1)*40+20,boom1^,0);
      delay(60);
      putimage((aoy-1)*40+10,(aox-1)*40+20,boom2^,0);
      delay(60);
      putimage((aoy-1)*40+10,(aox-1)*40+20,boom3^,0);
      delay(60);
      }

      {
      for i:=aox downto 2 do
        begin
          if (g1[i-1,aoy]<>'b') and (g1[i-1,aoy]<>'w') then begin
            g1[i, aoy]:=g1[i-1, aoy];
            {g1[i-1, aoy]:=' ';}
          end
          else break;
        end;
        }
      g1[aox, aoy] := ' ';
      AddExplosion(aox, aoy);
      PlayAudioOneShot(SND_TILE_POP);

      if (aoy+1<=12) then begin
        if (g1[aox,aoy+1]<>'w') and (g1[aox,aoy+1]<>'b') and (g1[aox,aoy+1]<>' ') and (g1[aox,aoy+1]<>'c')
           and (g1[aox,aoy+1]<>'t') then if (holds[1,1]<>'t') then begin
          intermed[1,1] := g1[aox,aoy+1];
          g1[aox,aoy+1] := holds[1,1];
          holds[1,1]    := intermed[1,1];
          change(holds[1,1]);
        end;
      end;
    end;

  end;

  { moving down" }
  if (aodx > 0) then begin
    writeln('if moving down');
  
    { check ahead: bounce into a wall or barrel -> exit }
    if (aox < 10) and ((g1[aox + aodx,aoy]='b') or (g1[aox + aodx,aoy]='w')) then begin
	
      MCState := MC_STATE_IDLE;
	  
      if addscore=true then exit;
      {if check=true then exit;}

      {goto retn;}
      {ComputeArrowParam;}
      exit;
    end;

    if g1[aox,aoy]='t' then begin
      PlayAudioOneShot(SND_POWERUP);
      g1[aox,aoy]:=holds[1,1];
      inc(lives);
    end;

    if g1[aox,aoy]='c' then begin
      PlayAudioOneShot(SND_POWERUP);
      g1[aox,aoy]:=holds[1,1];
      {inc(StartTimeSnap, 10000);}
      ElapsedTime := Max(0, ElapsedTime - 10000);
      {inc(time,10);}
    end;

    if (g1[aox,aoy]<>' ') and
       (g1[aox,aoy]<>holds[1,1]) and
       (holds[1,1]<>'t') then begin
	   
	   if (hit > 0) then begin
            intermed[1,1]:=g1[aox,aoy];
            g1[aox,aoy]:=holds[1,1];
            holds[1,1]:=intermed[1,1];
            change(holds[1,1]);
	        writeln('switch to ', holds[1,1]);
       end;	   
	   
	  writeln('going down and exit due to unmatched tile ', aox, ' ', aoy, ' ', g1[aox,aoy], ' ', holds[1,1], ' ', hit);
      MCState := MC_STATE_IDLE;
	  
      if addscore=true then exit;
      {if check=true then exit;}

      {goto retn;}
      {ComputeArrowParam;}
      exit;
    end;

    if (g1[aox,aoy]=holds[1,1]) or
       ((holds[1,1]='t') and (g1[aox,aoy]<>' ')) then begin

      inc(hit);

      if holds[1,1]='t' then begin
        holds[1,1]:=g1[aox,aoy];
        change(holds[1,1]);
      end;

      { TODO: explosions }
      {
      putimage((aoy-1)*40+10,(aox-1)*40+20,boom1^,0);
      delay(50);
      putimage((aoy-1)*40+10,(aox-1)*40+20,boom2^,0);
      delay(50);
      putimage((aoy-1)*40+10,(aox-1)*40+20,boom3^,0);
      delay(50);
      }

      {
      for i := aox downto 2 do
        begin
          if (g1[i-1,aoy]<>'b') and (g1[i-1,aoy]<>'w') then begin
            g1[i,aoy]:=g1[i-1,aoy];
            {g1[i-1,aoy]:=' ';}
          end
          else break;
        end;
        }

      g1[aox, aoy] := ' ';
      AddExplosion(aox, aoy);
      PlayAudioOneShot(SND_TILE_POP);

      writeln('next down is ', g1[aox+1,aoy]);

      if (aox+1<=10) then begin
        if (g1[aox+1,aoy]<>'w') and (g1[aox+1,aoy]<>'b') and (g1[aox+1,aoy]<>' ') and (g1[aox+1,aoy]<>' ')
           and (g1[aox+1,aoy]<>'c') and (g1[aox+1,aoy]<>'t') then begin
          if (holds[1,1]<>'t') then begin
            intermed[1,1]:=g1[aox+1,aoy];
            g1[aox+1,aoy]:=holds[1,1];
            holds[1,1]:=intermed[1,1];
            change(holds[1,1]);
          end;
        end;
      end;

    end;

  end;

  writeln(aox, ' ', aoy, ' ', holds[1,1]);

  aox := aox + aodx;
  aoy := aoy + aody;

  if (aoy > 12) then begin
    writeln('now going down');
    dec(aoy);
	inc(aox);
    {g1[aox,aoy]:=' ';}
    aody := 0;
    aodx := 1;
    {if addscore=true then exit;}
  end;

  if (aox > 10) then begin
    MCState := MC_STATE_IDLE;
	
    if addscore=true then exit;
    {if check=true then exit;}

    {ComputeArrowParam;}
  end;
  *)

end;

function AddScore:boolean;
begin
  addscore:=false;

  if hit > 0 then begin
    score:=score+SCORE_TILE_ZAP*hit;

    remains := ComputeRemains;

    if remains <= qualify then begin
	  StopModule;
      PlayAudioOneShot(SND_WIN);              
              
      GamePlayState := GPS_END;
      GameOutcome   := GO_WIN;
      MCState       := MC_STATE_JUMP;
	  
      bonusScoreTiles := (qualify - remains + 1) * SCORE_REMAINING;

	  bonusScoreTime := Math.Max(0, LEVEL_TIME - ElapsedTime) div 1000;
	  bonusScoreTime := bonusScoreTime * SCORE_POINTS_PER_SECOND;
	  
      inc(score, bonusScoreTiles);
      inc(score, bonusScoreTime);

      addscore:=true;

      InitJoyBounce;

    end;

    hit:=0;
  end;
end;

function CheckDown(tile : char; x, y: integer): boolean;
var 
  current: char;
  i: integer;
begin
  CheckDown := false;

  for i := x to 10 do 
  begin
    current := g1[i, y];
	
	{ found a tile that can be reached }
    if (current = tile) then begin
	  CheckDown := true;
	  exit;
	end;
	
	{ anything other than empty or special tiles is blocking, so exit }
	if not IsEmptyTile(current) and not IsSpecialTile(current) then exit;
  end;
end;

function CheckRight(tile : char; x, y: integer): boolean;
var 
  current: char;
  i: integer;
  
  { column to start with when switching to CheckDown - used when hitting right margin, a wall or a barrels }
  column: integer;
begin
  CheckRight := false;
  
  column := 12;

  for i := y to 12 do 
  begin
    current := g1[x, i];
	
	{ found a tile that can be reached }
    if (current = tile) then begin
	  CheckRight := true;
	  exit;
	end;
	
	{ hit an obstacle that is changing the direction, break to check down }
	if (current = TILE_WALL) or (current = TILE_BARREL) then begin
	  column := i - 1;
	  break;
	end;
	
	{ anything other than empty or special tiles is blocking, so exit }
	if not IsEmptyTile(current) and not IsSpecialTile(current) then exit;
  end;
  
  { check down }
  CheckRight := CheckDown(tile, x, column);
end;

function Check:boolean;
var
  i : integer;
begin
  Check:=false;
  
  { early exit if we're holding the wildcard }
  if holds[1,1] = TILE_WILDCARD then exit;

  for i := 1 to 10 do 
  begin
    { first column is reserved for the MC }
    if CheckRight(holds[1,1], i, 2) then exit;
  end;

  { activate the auto message }
  AutoMsg.enabled   := true;
  AutoMsg.timeSnap  := SDL_GetTicks();
  AutoMsg.timeDelay := 2000;
  AutoMsg.text      := 'MISSED!!!';
  AutoMsg.box       := true;

  holds[1,1] := TILE_WILDCARD;
  change(holds[1,1]);

  if inflives=false then begin
    dec(lives);

    if lives = 0 then begin         
      StopModule;	
      PlayAudioOneShot(SND_LOSE);
	  
      GamePlayState := GPS_END;
      GameOutcome := GO_DIE;
      Check       := true;
      exit;
    end
	else begin
      PlayAudioOneShot(SND_OUT_OF_MOVES);
	end;
  end;
end;

procedure ComputeArrowParam;
var
  x, y : integer;
begin
  x := ox;
  y := oy + 1;

  ArrowParam.visible := false;

  while y <= 12 do
    begin
      if (g1[x, y] = 'b') or (g1[x, y] = 'w') then begin
        break
      end
      else
        begin
          if g1[x, y] <> ' ' then begin
            ArrowParam.x := x;
            ArrowParam.y := y - 1;
            ArrowParam.visible := true;
            ArrowParam.orient := AO_RIGHT;
            exit;
          end;
        end;

      inc(y);
    end;

  dec(y);

  while x <= 10 do
    begin
      if (g1[x, y] = 'b') or (g1[x, y] = 'w') then
        break
      else
        begin
          if g1[x, y] <> ' ' then begin
            ArrowParam.x := x - 1;
            ArrowParam.y := y;
            ArrowParam.visible := true;
            ArrowParam.orient := AO_DOWN;
            exit;
          end;
        end;

      inc(x);
    end;
end;

procedure AddExplosion(x, y : integer);
var
  i : integer;
begin
 { search a free slot }
  for i := 1 to MAX_EXPLOSIONS do
    begin
      if (Explosions[i].active = false) then
        begin
          Explosions[i].active   := true;
          Explosions[i].x        := x;
          Explosions[i].y        := y;
          Explosions[i].frame    := 0;
          Explosions[i].timeSnap := SDL_GetTicks();
          exit;
        end;
    end;
end;

procedure RenderExplosions;
var
  i : integer;
begin
  for i := 1 to MAX_EXPLOSIONS do
    begin
      if (Explosions[i].active = true) then
        begin
          Putimage((Explosions[i].y-1)*40+PLAY_AREA_X_OFFSET, (Explosions[i].x-1)*40+PLAY_AREA_Y_OFFSET, SPR_BOOM1 + Explosions[i].frame, 0)
        end;
    end;
end;

procedure UpdateExplosions;
var
  i, j : integer;
  anyActive : boolean;
begin
  anyActive := false;

  for i := 1 to MAX_EXPLOSIONS do
    begin
      if (Explosions[i].active = true) then begin
        {if (SDL_GetTicks() - Explosions[i].timeSnap > 0) then begin}

          Explosions[i].timeSnap := SDL_GetTicks();

          inc(Explosions[i].frame);

          if (Explosions[i].frame >= MAX_EXPLOSION_FRAMES) then begin

            for j := Explosions[i].x downto 2 do
              begin
                if (g1[j-1, Explosions[i].y] <> 'b') and (g1[j-1, Explosions[i].y]<>'w') then begin
                  g1[j, Explosions[i].y] := g1[j-1, Explosions[i].y];
                end
                else break;
              end;

            Explosions[i].active := false;
          end;
        {end;}
      end;
    end;

  for i := 1 to MAX_EXPLOSIONS do
    begin
      if (Explosions[i].active = true) then begin
        anyActive := true;
        break;
      end;
    end;

  { TODO: improve: this will update each frame when there are no explosions }
  if (not anyActive) then begin
    Check;
    ComputeArrowParam;
  end;
end;

procedure ResetExplosions;
  var 
    i : Integer;
begin
  for i := 1 to MAX_EXPLOSIONS do
    begin
	  Explosions[i].active := false;
    end;
end;

function IsNormalTile(tile : char): boolean;
begin
  IsNormalTile := 
    (tile <> TILE_BARREL) and 
    (tile <> TILE_WALL) and 
    (tile <> TILE_BONUS_TIME) and 
    (tile <> TILE_EXTRA_LIFE) and 
    (tile <> TILE_EMPTY);
end;

function IsEmptyTile(tile : char): boolean;
begin
  IsEmptyTile := tile = TILE_EMPTY;
end;

function IsSpecialTile(tile : char): boolean;
begin
  IsSpecialTile := (tile = TILE_BONUS_TIME) and (tile = TILE_EXTRA_LIFE);
end;

procedure TransitionToMenu;
begin
  StartTransByRect(2, 12, GS_MENU);
		  
  StopModule;
  LoadModule(MUSIC_MENU_FILE_NAME);
  PlayModule;
end;

end.
