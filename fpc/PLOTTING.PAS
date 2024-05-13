program Plotting_Reloaded;
{$H+}

(*
 - menu background
 
 - smoother tile movement and tile return to MC
 - level complete polishing: pop remaining tiles, bonus/time counters, score counter

 - exit ingame dialog
 - intro - 1994 character bounce on letters
 - music :) 
*)

uses
  {System units}
  SysUtils,
  Logger,
  SDL,
  SDLUtils,
  SDL_ttf,
  SDL_gfx,
  SDL_mixer,

  {Game Units}
  PlottingUtils,
  game,
  StrUtils,
  Audio;

{ Global constants }
const
  WINDOW_TITLE    =  'Plotting Reloaded';

  FPS     = 25;

  INIT_DELAY     = 2500;
  CREDITS_DELAY  = 10000;
  CURSOR_DELAY   = 5000;
  DEFINE_DELAY   = 5000;
  MENU_TOPSCORE_DELAY = 15000;
  TOPSCORE_DELAY = 10000;

{ Global Variables }
var
  AppDone   : Boolean;
  SrcRect   : TSDL_Rect;
  DestRect  : TSDL_Rect;
  flags     : UInt32;

  LastTick  : Integer;
  FrameCounter : Integer;

  DefKeyIndex : Integer;
  
  ScreenToVideoRect : TSDL_Rect;

procedure LoadImages;
var
  i : integer;
  tempStr : string[255];
begin
  ImageList[0]  := LoadImage( 'data/BF.bmp' );
  ImageList[2]  := LoadImage( 'data/TAITO.bmp' );
  ImageList[3]  := LoadImage( 'data/BFW.bmp' );
  ImageList[4]  := LoadImage( 'data/OCEAN.bmp' );

  ImageList[SPR_HUD_WATCH_UP]   := LoadImage( 'data/HUD_CEAS01.bmp' );
  SetTransparentSurface(ImageList[SPR_HUD_WATCH_UP]);
  
  ImageList[SPR_HUD_WATCH_DOWN] := LoadImage( 'data/HUD_CEAS02.bmp' );
  SetTransparentSurface(ImageList[SPR_HUD_WATCH_DOWN]);

  ImageList[10] := LoadImage( 'data/CHR_1.bmp' );
  ImageList[11] := LoadImage( 'data/CHR_2.bmp' );
  ImageList[12] := LoadImage( 'data/CHR_3.bmp' );
  ImageList[13] := LoadImage( 'data/CHR_4.bmp' );

  ImageList[14] := LoadImage( 'data/ITEM_BARREL.bmp' );
  ImageList[15] := LoadImage( 'data/ITEM_SMILIE.bmp' );
  ImageList[16] := LoadImage( 'data/ITEM_HEART.bmp' );
  ImageList[17] := LoadImage( 'data/ITEM_SANDGLASS.bmp' );
  ImageList[18] := LoadImage( 'data/ITEM_GREEN_ARCH.bmp' );
  ImageList[19] := LoadImage( 'data/ITEM_WALL.bmp' );
  ImageList[20] := LoadImage( 'data/ITEM_YANG.bmp' );
  ImageList[21] := LoadImage( 'data/ITEM_THUNDER.bmp' );
  ImageList[22] := LoadImage( 'data/ITEM_EMPTY.bmp' );
  ImageList[23] := LoadImage( 'data/ITEM_DEVIL.bmp' );
  ImageList[24] := LoadImage( 'data/ARROW_DOWN.bmp' );
  ImageList[25] := LoadImage( 'data/ARROW_RIGHT.bmp' );

  for i := 26 to 40 do
    begin
      str(i - 25, tempStr);

      if (i - 25 > 9) then begin
        tempStr := '0' + tempStr;
      end
      else begin
        tempStr := '00' + tempStr;
      end;

      tempStr := 'data/BOOM' + tempStr + '.bmp';

      ImageList[i]  := LoadImage( tempStr );

      SDL_SetColorKey(ImageList[i], SDL_SRCCOLORKEY or SDL_RLEACCEL,
        SDL_MapRGB(ImageList[i]^.format, 255, 0, 255));
    end;

  for i := 10 to 13 do
    begin
      SDL_SetColorKey(ImageList[i], SDL_SRCCOLORKEY or SDL_RLEACCEL,
        SDL_MapRGB(ImageList[i]^.format, 255, 0, 255));
    end;

  { barrel }
  SDL_SetColorKey(ImageList[14], SDL_SRCCOLORKEY or SDL_RLEACCEL,
    SDL_MapRGB(ImageList[i]^.format, 255, 0, 255));
    
  SDL_SetColorKey(ImageList[24], SDL_SRCCOLORKEY or SDL_RLEACCEL,
    SDL_MapRGB(ImageList[i]^.format, 255, 0, 255));

  SDL_SetColorKey(ImageList[25], SDL_SRCCOLORKEY or SDL_RLEACCEL,
    SDL_MapRGB(ImageList[i]^.format, 255, 0, 255));

  ImageList[SPR_CHR2_10x] := zoomSurface(ImageList[SPR_CHR2], 10, 10, SMOOTHING_OFF);

  for i := 0 to PATTERN_COUNT - 1 do
  begin
      str(i, tempStr);
      ImageList[SPR_PATTERN_000 + i] := LoadImage( 'data/pattern00' + tempStr + '.bmp' );
      SetTransparentSurface(ImageList[SPR_PATTERN_000 + i]);
  end;

end;

procedure RenderBFW;
begin
  SrcRect.x := 0;
  SrcRect.y := 0;
  SrcRect.w := ImageList[3]^.w;
  SrcRect.h := ImageList[3]^.h;

  DestRect := SrcRect;
  DestRect.x := DestRect.x + (Screen^.w - DestRect.w) div 2;
  DestRect.y := DestRect.y + (Screen^.h - DestRect.h) div 2;

  SDL_BlitSurface(ImageList[3], @SrcRect, Screen, @DestRect);
end;

procedure RenderMenuBkg;
const
  title = 'PLOTTING';
var
    strTitleW, strTitleH : Integer;
begin
  SetFontColor($FF, $FF, $0);
  SetFont(FontBig);

  PutImage(11, Screen^.h - 50, SPR_ITEM_WALL, 0);
  PutImage(52, Screen^.h - 50, SPR_ITEM_SANDGLASS, 0);
  PutImage(93, Screen^.h - 50, SPR_ITEM_TAITO, 0);
  PutImage(11, Screen^.h - 91, SPR_ITEM_BARREL, 0);
  PutImage(52, Screen^.h - 91, SPR_ITEM_THUNDER, 0);
  PutImage(11, Screen^.h - 133, SPR_ITEM_HEART, 0);
  PutImage(Screen^.w - 50, Screen^.h - 50,  SPR_ITEM_WALL, 0);
  PutImage(Screen^.w - 92, Screen^.h - 50,  SPR_ITEM_BARREL, 0);
  PutImage(Screen^.w - 133, Screen^.h - 50, SPR_ITEM_THUNDER, 0);
  PutImage(Screen^.w - 50, Screen^.h - 91,  SPR_ITEM_YANG, 0);
  PutImage(Screen^.w - 92, Screen^.h - 91,  SPR_ITEM_COMMIE, 0);
  PutImage(Screen^.w - 50, Screen^.h - 133, SPR_ITEM_TAITO, 0);


  OutTextXY(SCREEN_WIDTH div 2, 165, title, HCENTER or BOTTOM, DEFAULT_BIG_FONT_SIZE);

  TextSize(title, strTitleW, strTitleH);

  {PutImage(Screen^.w - 51, 165, SPR_CHR2, BOTTOM);}
  PutImage((SCREEN_WIDTH + strTitleW) div 2 + 10, 150, SPR_CHR2, BOTTOM);
end;

procedure RenderOriginal;
begin
  SetFont(FontMenu);
  SetFontColor($AF, $AF, $AF);

  outtextxy(Screen^.w div 2, 270,'original from', HCENTER);
  putimage(Screen^.w div 2, 300, SPR_TAITO, HCENTER);

  outtextxy(Screen^.w div 2, 345, 'and', HCENTER);
  putimage(Screen^.w div 2, 370, SPR_OCEAN, HCENTER);
end;

procedure RenderCredits;
begin
  SetFont(FontMenu);

  SetFontColor($FF, $FF, $FF);
  outtextxy(Screen^.w div 2, 50, 'Developed by', HCENTER);

  Putimage(Screen^.w div 2, 70, SPR_BF, HCENTER);

  SetFontColor($FF, $FF, $FF);
  outtextxy(Screen^.w div 2, 110,'Programming&Additional Graphics', HCENTER);

  SetFontColor($0, $7F, $FF);
  outtextxy(Screen^.w div 2, 130,'Stefan ''Phane'' Dicu', HCENTER);

  SetFontColor($FF, $FF, $FF);
  outtextxy(Screen^.w div 2, 160,'Graphics&Additional Programming', HCENTER);

  SetFontColor($0, $7F, $FF);
  outtextxy(Screen^.w div 2, 180, 'Alex ''Alecsei'' Mazilu', HCENTER);  
  
  (*SetFontColor($FF, $FF, $FF);
  outtextxy(Screen^.w div 2, 210,'Sound Effects', HCENTER);

  SetFontColor($0, $7F, $FF);
  outtextxy(Screen^.w div 2, 230, 'LittleRobotSoundFactory, Aesterial Arts', HCENTER);*)
  
  RenderOriginal;
end;

procedure RenderKeyboardControls;
begin
  RenderMenuBkg;
  SetFont(FontMenu);
  
  { light cyan }
  SetFontColor($0, $FF, $FF);

  { options }
  OutTextXY(Screen^.w div 2, 250, '1. Use Default Keys', HCENTER);
  OutTextXY(Screen^.w div 2, 275, '2. Redefine keys', HCENTER);
    
  { render the current keyboard setup }
  SetFontColor($0, $7F, $7F);
  OutTextXY(Screen^.w div 2, 305, AnsiProperCase(SDL_GetKeyName(upKey), StdWordDelims) + ' to move up', HCENTER);
  OutTextXY(Screen^.w div 2, 325, AnsiProperCase(SDL_GetKeyName(downKey), StdWordDelims) + ' to move down', HCENTER);
  OutTextXY(Screen^.w div 2, 345, AnsiProperCase(SDL_GetKeyName(fireKey), StdWordDelims) + ' to fire', HCENTER);
  OutTextXY(Screen^.w div 2, 365, AnsiProperCase(SDL_GetKeyName(holdKey), StdWordDelims) + ' to pause the game', HCENTER);
  OutTextXY(Screen^.w div 2, 385, 'ESC to exit game', HCENTER);
end;

procedure RenderMenuRedefine;
const
  KEY_FUNCTION_LIST : array[0..3] of string = ('UP: ', 'DOWN: ', 'FIRE: ', 'PAUSE: ');
var
  i : Integer;
  MaxKeyIndex : Integer;
  m : string;
begin
  RenderMenuBkg;

  SetFont(FontMenu);

  SetFontColor($0, $7F, $7F);
  OutTextXY(Screen^.w div 2, 250, 'Redefine Keys', HCENTER);

  SetFontColor($0, $FF, $FF);

  MaxKeyIndex := DefKeyIndex;

  if (MaxKeyIndex > 3) then
   MaxKeyIndex := 3;

  for i := 0 to MaxKeyIndex do
  begin
    m := '';

    { TODO: get the name of the game }
    if (i = DefKeyIndex) then m := '?'
    else
      begin
        case i  of
          0: m := SDL_GetKeyName(upKey);
          1: m := SDL_GetKeyName(downKey);
          2: m := SDL_GetKeyName(fireKey);
          3: m := SDL_GetKeyName(holdKey);
        end;
      end;

    outtextxy(Screen^.w div 2, 275 + 20 * i, KEY_FUNCTION_LIST[i] + m, HCENTER);
  end;

  if (DefKeyIndex >= 4) then
  begin
    outtextxy(Screen^.w div 2, 375, 'ESC to quit game', HCENTER);
  end;

end;

procedure RenderMenu;
begin
  RenderMenuBkg;

  SetFont(FontMenu);

  { cyan? }
  (*SetFontColor($0, $7F, $7F);
  OutTextXY(Screen^.w div 2, 251, 'Menu', HCENTER);*)

  { light cyan }
  SetFontColor($0, $FF, $FF);

  { menu options}
  OutTextXY(Screen^.w div 2, 250, '1. New Game', HCENTER);
  OutTextXY(Screen^.w div 2, 275, '2. Keyboard Controls', HCENTER);
  OutTextXY(Screen^.w div 2, 300, '3. Credits', HCENTER);
  OutTextXY(Screen^.w div 2, 325, '4. Top Scores', HCENTER);

  { red }
  SetFontColor($FF, $00, $00);

  { cheats info }
  if inflives = true then
    OutTextXY(Screen^.w div 2, 375,'Infinite lives is on ', HCENTER)
  else
    OutTextXY(Screen^.w div 2, 375,'Infinite lives is off ', HCENTER);

  if inftime = true then
    OutTextXY(Screen^.w div 2, 390, 'Infinite time is on ', HCENTER)
  else
    OutTextXY(Screen^.w div 2, 390, 'Infinite time is off', HCENTER);

  SetFontColor($FF, $FF, $FF);
  if (FrameCounter mod 12 > 3) then
    OutTextXY(Screen^.w div 2, 415, 'ESC TO EXIT', HCENTER);
end;

procedure RenderExit;
begin
  OutTextXY(Screen^.w div 2, Screen^.h div 2, 'Thanks for playing Blueflower''s Plotting.', HCENTER or VCENTER);
  OutTextXY(Screen^.w div 2, Screen^.h div 2 + 18, 'See you in hell ;)', HCENTER or VCENTER);
end;

procedure RenderTopScores;

var
  i      : Integer;
  tmpStr : string;
begin
  { render a zoomed main character as background }
  SrcRect.x := 0;
  SrcRect.y := 0;
  SrcRect.w := ImageList[SPR_CHR2]^.w;
  SrcRect.h := ImageList[SPR_CHR2]^.h;

  DestRect.x := Screen^.w div 2 - 10 * ImageList[SPR_CHR2]^.w div 2;
  DestRect.y := Screen^.h div 2 - 10 * ImageList[SPR_CHR2]^.h div 2;
  DestRect.w := 10 * ImageList[SPR_CHR2]^.w;
  DestRect.h := 10 * ImageList[SPR_CHR2]^.h;

  {SDL_ZoomSurface(ImageList[SPR_CHR2], @SrcRect, Screen, @DestRect);}
  PutImage(trunc(DestRect.x), trunc(DestRect.y), SPR_CHR2_10x, 0);

  { render the top }
  SetFont(FontMenu);

  SetFontColor($FF, $FF, $FF);
  OutTextXY(Screen^.w div 2, 20, 'The Great Plotters', HCENTER, 24);

  SetFontColor($FF, $0, $0);
  OutTextXY(Screen^.w div 2, Screen^.h - 100, 'Never give up so easy!', HCENTER);

  for i := 1 to 8 do
  begin
    { score - right aligned }
    str(TopScores[i].entryValue, tmpStr);

    { shadow }
    SetFontColor(0, 0, 0);
    OutTextXY(Screen^.w div 2 + 150 + 3, 70 + (i-1) * 25 + 3, tmpStr, RIGHT);

    { actual value }
    SetFontColor($0, $FF, $FF);
    OutTextXY(Screen^.w div 2 + 150, 70 + (i-1) * 25, tmpStr, RIGHT);

    { name - left aligned }
    { shadow }
    SetFontColor(0, 0, 0);
    OutTextXY(Screen^.w div 2 - 150 + 3, 70 + (i-1) * 25 + 3, TopScores[i].entryName, 0);

    { actual value }
    SetFontColor($0, $FF, $FF);
    OutTextXY(Screen^.w div 2 - 150, 70 + (i-1) * 25, TopScores[i].entryName, 0);
  end;
end;

procedure RenderEnterTopScore;
var
  i : integer;
  tmpStr : string[255];
begin
  { render a zoomed main character as background }
  SrcRect.x := 0;
  SrcRect.y := 0;
  SrcRect.w := ImageList[SPR_CHR2]^.w;
  SrcRect.h := ImageList[SPR_CHR2]^.h;

  DestRect.x := Screen^.w div 2 - 10 * ImageList[SPR_CHR2]^.w div 2;
  DestRect.y := Screen^.h div 2 - 10 * ImageList[SPR_CHR2]^.h div 2;
  DestRect.w := 10 * ImageList[SPR_CHR2]^.w;
  DestRect.h := 10 * ImageList[SPR_CHR2]^.h;

  {SDL_ZoomSurface(ImageList[SPR_CHR2], @SrcRect, Screen, @DestRect);}
  PutImage(trunc(DestRect.x), trunc(DestRect.y), SPR_CHR2_10x, 0);

  { render the top }
  SetFont(FontMenu);

  SetFontColor($FF, $FF, $FF);
  OutTextXY(Screen^.w div 2, 20, 'The Great Plotters', HCENTER);

  SetFontColor($FF, $0, $0);
  OutTextXY(Screen^.w div 2, Screen^.h - 100, 'Never give up so easy :)', HCENTER);

  for i := 1 to 8 do
  begin
    { score - right aligned }
    str(TopScores[i].entryValue, tmpStr);

    { shadow }
    SetFontColor(0, 0, 0);
    OutTextXY(Screen^.w div 2 + 150 + 3, 70 + (i-1) * 25 + 3, tmpStr, RIGHT);

    { actual value }
    if TopScoreIndex = i then SetFontColor($FF, $00, $00)
    else SetFontColor($0, $FF, $FF);

    OutTextXY(Screen^.w div 2 + 150, 70 + (i-1) * 25, tmpStr, RIGHT);

    { name - left aligned }
    tmpStr := TopScores[i].entryName;

    if ((FrameCounter mod 12 > 3) and (TopScoreIndex = i))
      then tmpStr := tmpStr + '?';

    { shadow }
    SetFontColor(0, 0, 0);
    OutTextXY(Screen^.w div 2 - 150 + 3, 70 + (i-1) * 25 + 3, tmpStr, 0);

    { actual value }
    if TopScoreIndex = i then SetFontColor($FF, $00, $00)
    else SetFontColor($0, $FF, $FF);

    OutTextXY(Screen^.w div 2 - 150, 70 + (i-1) * 25, tmpStr, 0);
  end;
end;

procedure UpdateGameFinished;
var
  i : integer;
begin
  for i:= 1 to MAX_BOUNCE_MC do
    begin
      UpdateBounceMC(i);
    end;

  if (IsKeyDown) then begin
    if (IsTopScore(Score)) then begin
      TopScoreIndex := AddTopScore(score);
      StartTransByRect(2, 12, GS_ENTER_TOPSCORE);
    end
    else begin
      StartTransByRect(2, 12, GS_MENU);
    end;
  end;
end;

procedure RenderGameFinished;
var
  i : integer;
begin
  for i:= 1 to MAX_BOUNCE_MC do
    begin
      PutImage(trunc(BounceMC[i].baseX), trunc(BounceMC[i].baseY) + 40, SPR_ITEM_BARREL, 0);

      RenderBounceMC(i);
    end;

  SetFont(FontBig);
  SetFontColor($FF, $FF, $FF);
  OutTextXY(Screen^.w div 2, Screen^.h div 2, 'YOU DID IT!', HCENTER or VCENTER);

  SetFont(FontMenu);
  SetFontColor($FF, $00, $00);
  OutTextXY(Screen^.w div 2, Screen^.h div 2 + 30, '...because there are no more levels', HCENTER or VCENTER);
end;

procedure Render;
begin
  case state of
    GS_INIT: RenderBFW;
    GS_MENU: RenderMenu;
    GS_TRANS_BY_RECT: TransByRect;
    GS_EXIT: RenderExit;
    GS_CREDITS: RenderCredits;
    GS_MENU_DEFINE_KEYS: RenderMenuRedefine;
    GS_TOPSCORE: RenderTopScores;
    GS_GAME: RenderGame;
    GS_GAME_FINISHED: RenderGameFinished;
    GS_ENTER_TOPSCORE: RenderEnterTopScore;
    GS_KEYBOARD_CONTROLS: RenderKeyboardControls;
  end;
end;

procedure UpdateEnterTopScore;
var
  localKeyDownUnicode : Integer;
begin
  if (IsKeyDown) then
    begin
      case KeyDown of
        SDLK_RETURN,
        SDLK_ESCAPE:
          begin
            if length(TopScores[TopScoreIndex].entryName) = 0 then
            begin
              TopScores[TopScoreIndex].entryName := 'Player ' + IntToStr(TopScoreIndex);
            end;
          
            WriteTopScores;
            TimeSnap := SDL_GetTicks();
            StartTransByRect(2, 12, GS_TOPSCORE);
            exit;
          end;

        SDLK_BACKSPACE:
          begin
            if (length(TopScores[TopScoreIndex].entryName) >= 1) then begin
              TopScores[TopScoreIndex].entryName := copy(TopScores[TopScoreIndex].entryName, 1, length(TopScores[TopScoreIndex].entryName) - 1);
            end;
          end;

        else
          begin
            localKeyDownUnicode := KeyDownUnicode; 
            
            if (length(TopScores[TopScoreIndex].entryName) < 13) and (localKeyDownUnicode >= $20) and (localKeyDownUnicode <= $7F) then begin
              TopScores[TopScoreIndex].entryName := TopScores[TopScoreIndex].entryName + Chr(localKeyDownUnicode);
              TopScores[TopScoreIndex].entryName := copy(TopScores[TopScoreIndex].entryName, 1, 13);
            end;
          end;
      end;
    end;
end;

procedure Update;
begin
  case state of
    GS_INIT:
      begin
      { handle keys }
      if (IsKeyDown) then
        begin
          StartTransByRect(2, 12, GS_MENU);
        end
      else if (SDL_GetTicks() - TimeSnap > INIT_DELAY) then
        begin
          StartTransByRect(2, 12, GS_MENU);
        end;
      end;

    GS_CREDITS:
      begin
      { handle keys }
      if (IsKeyDown) then
        begin
          StartTransByRect(2, 12, GS_MENU);
        end
      else if (SDL_GetTicks() - TimeSnap > CREDITS_DELAY) then
        begin
          StartTransByRect(2, 12, GS_MENU);
        end;
      end;

    GS_MENU:
      begin
        case KeyDown of
          { play game }
          SDLK_1:
            begin
              InitGame;

              InitLevelTitle;
              state := GS_GAME;
              TimeSnap := SDL_GetTicks();
            end;

          { keyboard controls }
          SDLK_2:
            begin
              state := GS_KEYBOARD_CONTROLS;
              TimeSnap := SDL_GetTicks();
            end;

          { play game }
          (*
          SDLK_3:
            begin
              state := GS_MENU_DEFINE_KEYS;
              DefKeyIndex := 0;
            end;*)
            
          { credits }
          SDLK_3:
            begin
              StartTransByRect(2, 12, GS_CREDITS);
            end;
            
          { top scores }
          SDLK_4:
            begin
              StartTransByRect(2, 12, GS_TOPSCORE);
              
              { code to test top score name input }
              (*
              TopScoreIndex := AddTopScore(TopScores[8].entryValue + 1);
              StartTransByRect(2, 12, GS_ENTER_TOPSCORE);
              *)
            end;

          { quit game }
          SDLK_ESCAPE:
            begin
              StartTransByRect(2, 12, GS_EXIT);
            end;
        end;

        if (SDL_GetTicks() - TimeSnap > MENU_TOPSCORE_DELAY) and
           (State = GS_MENU) then
        begin
          state := GS_TOPSCORE;
          TimeSnap := SDL_GetTicks();
        end;
      end;

    GS_EXIT:
      begin
      if (IsKeyDown) then
        begin
          AppDone := true;
        end;
      end;

    GS_MENU_DEFINE_KEYS:
      begin
        case (DefKeyIndex) of
          0:
            begin
              upKey := KeyDown;

              if (upKey <> SDLK_UNKNOWN) then
                inc(DefKeyIndex);
            end;
          1:
            begin
              downKey := KeyDown;

              if (downKey <> SDLK_UNKNOWN) then
                inc(DefKeyIndex);
            end;
          2:
            begin
              fireKey := KeyDown;

              if (fireKey <> SDLK_UNKNOWN) then
                inc(DefKeyIndex);
            end;
          3:
            begin
              holdKey := KeyDown;

              if (holdKey <> SDLK_UNKNOWN) then
                begin
                  TimeSnap := SDL_GetTicks();
                  inc(DefKeyIndex);
				  SaveSettings;
                end;
            end;
          4:
            begin
             if (IsKeyDown or (SDL_GetTicks() - TimeSnap > DEFINE_DELAY)) then
               begin
                 state := GS_KEYBOARD_CONTROLS;
                 TimeSnap := SDL_GetTicks();
               end;
            end;
        end;
      end;

    GS_TOPSCORE:
      begin
       if (IsKeyDown or (SDL_GetTicks() - TimeSnap > TOPSCORE_DELAY)) then
       begin
         state := GS_MENU;
         TimeSnap := SDL_GetTicks();
       end;
      end;

    GS_GAME:
      begin
        UpdateGame;
      end;

    GS_GAME_FINISHED:
      begin
        UpdateGameFinished;
      end;

    GS_ENTER_TOPSCORE:
      begin
        UpdateEnterTopScore;
      end;
      
    GS_KEYBOARD_CONTROLS:     
      begin
        if IsKeyDown then
        begin
          case KeyDown of
            SDLK_ESCAPE:
              begin
                StartTransByRect(2, 12, GS_MENU);
              end;
              
            SDLK_1:
              begin
                SetDefaultSettings;
                StartTransByRect(2, 12, GS_MENU);
				SaveSettings;
              end;            
              
            SDLK_2:
              begin
                DefKeyIndex := 0;
                StartTransByRect(2, 12, GS_MENU_DEFINE_KEYS);
              end;
          end;    
        end;        
      end;
  end;
end;

BEGIN
 SetDefaultSettings;
 LoadSettings;

 { video flags }
 flags := SDL_DOUBLEBUF or SDL_SWSURFACE;
 if (FullScreen) then flags := flags or SDL_FULLSCREEN;

 if (SDL_Init(SDL_INIT_VIDEO or SDL_INIT_AUDIO) < 0) then
 begin
   Log.LogError(Format('Could not initialize SDL: %s',
     [SDL_GetError]), 'Main');
     TerminateApplication;
   exit;
 end;

 InitAudio;
 LoadAudio;

 { init the ttf rendering }
 if (TTF_Init() < 0) then
 begin
   Log.LogError(Format('Could not initialize TTF: %s',
     [SDL_GetError]), 'Main');
     TerminateApplication;
 end;

 { load the fonts }
 FontMenu := TTF_OpenFont('data/atwriter.ttf', DEFAULT_MENU_FONT_SIZE);

 if (FontMenu = nil) then
 begin
   Log.LogError(Format('Could not load menu font: %s',
     [SDL_GetError]), 'Main');
     TerminateApplication;
 end;

 TTF_SetFontStyle(FontMenu, TTF_STYLE_NORMAL);

 FontBig := TTF_OpenFont('data/fontbig2.ttf', DEFAULT_BIG_FONT_SIZE);

 if (FontBig = nil) then
 begin
   Log.LogError(Format('Could not load big font: %s',
     [SDL_GetError]), 'Main');
     TerminateApplication;
 end;

 TTF_SetFontStyle(FontBig, TTF_STYLE_NORMAL);

 SetFont(FontMenu);
 SetFontColor($FF, $FF, $FF);

 { set the title bar in environments that support it }
 SDL_WM_SetCaption( WINDOW_TITLE, nil);

 VideoScreen := SDL_SetVideoMode(ResolutionWidth, ResolutionHeight, SCREEN_BPP, flags);
 if (VideoScreen = nil) then
 begin
   Log.LogError(Format('Could not set video mode: %s',
     [SDL_GetError]), 'Main');
   TerminateApplication;
 end;
 
 { SDL2 only - set scaling filter }
 (*
 SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, 'linear');  
  
 { set logical resolution }
 if SDL_RenderSetLogicalSize(sdlRenderer, SCREEN_WIDTH, SCREEN_HEIGHT) <> 0 then
   Halt;
 *)
	
 { Enable Unicode translation }
 SDL_EnableUNICODE( 1 ); 

 Screen := SDL_CreateRGBSurface(0, SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_BPP, VideoScreen^.format^.RMask, VideoScreen^.format^.GMask, VideoScreen^.format^.BMask, VideoScreen^.format^.AMask);
 Transition := SDL_CreateRGBSurface(0, Screen^.w, Screen^.h, SCREEN_BPP, VideoScreen^.format^.RMask, VideoScreen^.format^.GMask, VideoScreen^.format^.BMask, VideoScreen^.format^.AMask);
 LevelBackground := SDL_CreateRGBSurface(0, Screen^.w, Screen^.h, SCREEN_BPP, VideoScreen^.format^.RMask, VideoScreen^.format^.GMask, VideoScreen^.format^.BMask, VideoScreen^.format^.AMask);

 if (not ReadTopScores) then
 begin
   Log.LogError('Cannot read the top scores file', 'Main');
   GenerateTopScores;
 end;

 { hide Mouse Cursor }
 SDL_SHOWCURSOR(0);

 { load graphic assets }
 LoadImages;

 state := GS_INIT;
 TimeSnap := SDL_GetTicks();
 AppDone  := false;

 FrameCounter := 0;
 LastTick := SDL_GetTicks();

 while ( not AppDone ) do
 begin
   if (SDL_GetTicks()  - LastTick < 1000 / FPS) then
     continue;

   LastTick := SDL_GetTicks();
   inc(FrameCounter);

   ClearScreen($000000);

   { handle the events }
   while ( SDL_PollEvent( @event ) = 1 ) do
   begin
     case event.type_ of
       SDL_QUITEV :
       begin
         AppDone := true;
       end;

       (*
       SDL_KEYDOWN :
       begin
         { handle key presses }
         HandleKeyPress( @event.key.keysym );
       end;
       *)

       SDL_MOUSEMOTION :
       begin
         {
         MouseX := event.motion.x;
         MouseY := event.motion.y;
         }
       end;
     end;
   end;

   Update;
   Render;

   ScreenToVideoRect.x := (VideoScreen^.w - Screen^.w) div 2;
   ScreenToVideoRect.y := (VideoScreen^.h - Screen^.h) div 2;
   ScreenToVideoRect.w := Screen^.w;
   ScreenToVideoRect.h := Screen^.h;
   SDL_BlitSurface(Screen, nil, VideoScreen, @ScreenToVideoRect);

   { show me! }
   SDL_Flip(VideoScreen);

   { save the screen to surface }
   SDL_BlitSurface(Screen, nil, Transition, nil);

   event.type_ := 0;

 end;

  TerminateApplication;

END.
