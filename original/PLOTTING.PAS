program PROJECT;
{using files sans,litt,lcom,trip,egavga-obj,same public names}
uses tcv,game,graph,crt,dos;

var m:string;
    r:registers;

procedure egavga;external;
{$L c:\bin\bp\bgi\egavga}
procedure sans;external;
{$L  c:\bin\bp\bgi\sans.obj}
procedure trip;external;
{$L  c:\bin\bp\bgi\trip.obj}
procedure litt;external;
{$L  c:\bin\bp\bgi\litt.obj}
procedure lcom;external;
{$L  c:\bin\bp\bgi\lcom.obj}

procedure DELS;
var i,j:integer;
begin
setcolor(0);
for i:=0 to 4 do begin
j:=i;
repeat
line(0,j,210,j);
delay(10);
inc(j,5);
until j>=160;
end;
end;
procedure PALREC;
var i:integer;
begin
for i:=1 to 16 do begin
setrgbpalette(vgacolors[i,1],vgacolors[i,2],vgacolors[i,3],vgacolors[i,4]);
setpalette(i-1,i-1);
end;
end;
procedure FILL16;
{const ox1:integer=0;
      ox2:integer=0;
      flag1:integer=0;
      flag2:integer=0;
      usec:integer=1;               }
var oy1,oy2,ox1,ox2,flag1,flag2,usec:integer;
begin
oy1:=getmaxy;
oy2:=getmaxy;
ox1:=0;
ox2:=0;
flag1:=0;
flag2:=0;
usec:=1;
setcolor(usec);
repeat
if flag1=0 then inc(ox1)
           else dec(oy1);
if flag2=0 then dec(oy2)
           else inc(ox2);
if (ox1=getmaxx) and (flag1=0) then flag1:=3;
if (oy2=0) and (flag2=0) then flag2:=3;
moveto(ox2,oy2);
lineto(ox1,oy1);
if (ox1+oy1)/20=int((ox1+oy1)/20) then begin
                                        inc(usec);
                                        if usec>15 then usec:=1;
                                        setcolor(usec);
                                        end;

until oy1=0;
end;
procedure DEFILL(x1,y1,x2,y2:integer);
var c,x2i,y2i,x1i,y1i:integer;
begin
y1i:=y1;
x1i:=x1;
x2i:=x2;
y2i:=y2;
setcolor(0);
setlinestyle(0,0,3);
repeat
inc(x1);
dec(y2);
dec(x2);
inc(y1);
if x2i>x1 then line(x1,y1i,x2,y2i);
if y2i>y1 then line(x1i,y1,x2i,y2);
until (x2i<x1) and (y2i<y1);
end;
procedure FONDU;
var i,j   : integer;
    pal : array[1..16,1..3] of byte;
    reg : registers;
begin
for i:=1 to 16 do
    begin
     pal[i,1]:=vgacolors[i,1];
     pal[i,2]:=vgacolors[i,2];
     pal[i,3]:=vgacolors[i,3];
    end;
for i:=64 downto 0 do
    begin
    for j:=1 to 16 do
    begin
     if pal[j,1]>0 then dec(pal[j,1]);
     if pal[j,2]>0 then dec(pal[j,2]);
     if pal[j,3]>0 then dec(pal[j,3]);
    end;
    Reg.ah := $10;
    Reg.al := $12;
    Reg.bx := 0;
    Reg.cx := 16;
    Reg.dx := ofs (Pal);
    Reg.es := seg (Pal);
    intr ($10, Reg);
    delay(25);
   end;
cleardevice;
end;
procedure CHKINT;
var varf:searchrec;
    res:text;
    i:integer;
    s:string;
begin
setcolor(blue);
setfillstyle(1,blue);
rectangle(getmaxx div 2-80,getmaxy div 2-15,getmaxx div 2+80,getmaxy div 2+15);
floodfill(getmaxx div 2,getmaxy div 2,blue);
setcolor(yellow);
settextstyle(2,0,0);
outtextxy(getmaxx div 2-76,getmaxy div 2-4,'CHECKING INTEGRITY OF GAME');
findfirst('plotting.dat',$3f,varf);
if doserror<>0 then begin
                    closegraph;
                    writeln('File plotting.dat is missing.To get complete version,call 623755 for Phane.');
                    halt;
                    end;
{assign(res,'resource.dat');
reset(res);
for i:=1 to 9 do begin
readln(res,s);
if s<>'' then findfirst(s,$3f,varf);
delay(100);
if doserror<>0 then begin
                    closegraph;
                    writeln('File ',s,' is missing.To get complete version,call 623755 for Phane.');
                    halt;
                    end;
end;
close(res);}
end;
procedure CHKPARAM;
begin
if (paramstr(1)='freeze') or (paramstr(2)='freeze') or (paramstr(1)='FREEZE') or (paramstr(2)='FREEZE') then inftime:=true;
if (paramstr(1)='blast') or (paramstr(2)='blast') or (paramstr(1)='BLAST') or (paramstr(2)='BLAST') then inflives:=true;
end;

procedure TOPSCORE;
const chars:string[35]='ABCDEFGHIJKLMNOPQRSTUVXYWZ._- !?&%*';
      msg:array[1..5] of string=('Great !','New high score','Please type your name in',
                                 'The Plotters','Never give up so easy :-)');
type top=array[1..8] of string[20];
     zsprite=array[1..40,1..40] of byte;
var zs:zsprite;
    toparray:top;
    i,j,v:longint;
    onchar,cod,stopx,coordx,posn,c:integer;
    ch:char;
    letter:pointer;
    s,s1:string;
procedure verify;
begin
if onchar>35 then onchar:=1;
if onchar<1  then onchar:=35;
end;
label 1;
begin
fondu;
palrec;
stopx:=212;
posn:=0;
onchar:=1;
assign(fis,'plotting.dat');
reset(fis,1);
seek(fis,0);
blockread(fis,toparray,sizeof(top));
seek(fis,168);
blockread(fis,zs,sizeof(zsprite));
close(fis);
cleardevice;
for i:=1 to 8 do begin
val(copy(toparray[i],14,8),v,c);
if v<=score then begin
                putimage(60,230,spr3^,0);
        settextstyle(7,0,0);
        setcolor(white);
        outtextxy(112,220,chars[onchar]);
        setcolor(lightred);
	     outtextxy(getmaxx div 2-textwidth(msg[1]) div 2,50,msg[1]);
	     outtextxy(getmaxx div 2-textwidth(msg[2]) div 2,100,msg[2]);
	     setcolor(lightblue);
	     outtextxy(getmaxx div 2-textwidth(msg[3]) div 2,150,msg[3]);
	     for j:=8 downto i+1 do toparray[j]:=toparray[j-1];
	     setcolor(red);
	     s:='';
	     repeat
        if keypressed then ch:=readkey
              else ch:=#0;
        if ch=up then begin
              setcolor(black);
              outtextxy(112,220,chars[onchar]);
              inc(onchar);
              verify;
              setcolor(white);
              outtextxy(112,220,chars[onchar]);
              end;
        if ch=down then begin
              setcolor(black);
              outtextxy(112,220,chars[onchar]);
              dec(onchar);
              verify;
              setcolor(white);
              outtextxy(112,220,chars[onchar]);
              end;
        if ch=fire then begin
              putimage(60,230,spr4^,0);
              delay(180);
              putimage(60,230,spr3^,0);
              delay(180);
              putimage(60,230,spr2^,0);
              delay(180);
              putimage(60,230,spr3^,0);
              s:=s+chars[onchar];
              getmem(letter,imagesize(112,220,112+30{textwidth(chars[onchar])},220+60{textheight(chars[onchar])}));
              getimage(112,220,112+30{textwidth(chars[onchar])},220+60{textheight(chars[onchar])},letter^);
              coordx:=112;
              repeat
              putimage(coordx,220,letter^,xorput);
              delay(50);
              putimage(coordx,220,letter^,xorput);
              inc(coordx,20);
              until coordx>stopx;
              stopx:=coordx+20{textwidth(chars[onchar])+5};
              putimage(coordx,220,letter^,xorput);
              inc(posn);
              freemem(letter,imagesize(112,220,112+textwidth(chars[onchar]),220+textheight(chars[onchar])));
              end;
	     until posn>9;
	     str(score,s1);
	     s:=s+'    '+s1;
	     toparray[i]:=s;
        goto 1;
	     end;
end;
1:delay(300);
cleardevice;
for i:=1 to 40 do
for j:=1 to 40 do begin
setfillstyle(1,zs[i,j]);
bar(getmaxx div 2-200+10*(j-1),10*(i-1),getmaxx div 2-200+10*j,10*i);
end;
setcolor(white);
settextstyle(3,0,0);
setusercharsize(1,1,1,1);
outtextxy(getmaxx div 2-textwidth(msg[4]) div 2,0,msg[4]);
settextstyle(3,0,0);
setusercharsize(1,1,1,1);
outtextxy(getmaxx div 2-textwidth(msg[5]) div 2,getmaxy-90,msg[5]);
for i:=1 to 8 do begin
setcolor(black);
outtextxy(getmaxx div 2-textwidth(toparray[i]) div 2+3,70+(i-1)*25+3,toparray[i]);
setcolor(lightcyan);
outtextxy(getmaxx div 2-textwidth(toparray[i]) div 2,70+(i-1)*25,toparray[i]);
end;
assign(fis,'plotting.dat');
reset(fis,1);
seek(fis,0);
blockwrite(fis,toparray,sizeof(toparray));
close(fis);
repeat
until readkey=#13;
fondu;
palrec;
end;
procedure PRESENT;
const txtpr:array[1..3] of string=('Once upon a time...','It was a big soft fun,',
                                   'Called Plotting.');
var i,j:integer;
procedure flash;
var i:integer;
begin
setbkcolor(0);
setcolor(15);
setlinestyle(0,0,3);
lIne(300,0,340,60);line(302,0,340,60);line(298,0,339,60);
delay(100);
setpalette(0,0);
delay(50);
line(340,60,280,120);line(339,60,280,120);
delay(100);
setpalette(0,15);
delay(10);
line(280,120,360,180);line(280,120,270,160);
delay(200);
line(270,160,320,180);line(270,160,240,200);
setpalette(0,0);
delay(100);
setpalette(0,15);
delay(10);
line(320,180,300,240);line(240,200,230,270);line(360,180,390,240);line(360,180,350,250);
setpalette(0,0);
delay(100);
setpalette(0,15);
delay(60);
line(300,240,280,260);line(230,270,280,330);line(390,240,450,280);line(350,250,380,300);
line(300,240,320,275);line(230,270,200,300);line(390,240,375,300);line(350,250,325,330);
setpalette(0,0);
delay(100);
for i:=1 to 3 do begin
                   setrgbpalette(15,0,0,0);
                   delay(100);
                   setrgbpalette(15,0,63,63);
                   delay(10);
                 end;
delay(200);
for i:=63 downto 0 do setrgbpalette(15,i,i,i);cleardevice;
setrgbpalette(15,63,63,63);
end;
begin
settextstyle(1,0,0);
setrgbpalette(green,0,0,0);
for i:=1 to 3 do begin;
flash;
setcolor(green);
outtextxy(getmaxx div 2-150,getmaxy div 2,txtpr[i]);
for j:=1 to 40 do begin
setrgbpalette(green,0,j,0);
delay(50);
end;
delay(2000);
for j:=40 downto 1 do begin
setrgbpalette(green,0,j,0);
delay(40);
end;
cleardevice;
end;
palrec;
end;
procedure PRESENT1;
type  scrb=array[1..2432] of byte;
      buff=^scrb;
const a:string='PLOTTING';
var i,j,posx,posy,tox:integer;
    ch:char;
    timemax:longint;
    ocean,taito,b,f:buff;
    r:registers;
    hi,mi,si,s1i:word;
    time,timei:longint;
label rep,mnu,again;
begin
cleardevice;
assign(fis,'plotting.dat');
reset(fis,1);
seek(fis,168+1600);
new(taito);
new(ocean);
new(b);
new(f);
blockread(fis,taito^,19*128);
blockread(fis,ocean^,19*128);
blockread(fis,b^,6*128);
blockread(fis,f^,8*128);
settextstyle(1,0,0);
setrgbpalette(green,0,0,0);
again:settextstyle(1,0,0);
palrec;
fill16;
defill(10,10,getmaxx-10,getmaxy-10);
setusercharsize(4,1,3,1);
setcolor(yellow);
outtextxy(24,190-textheight('P'),a);
putimage(11,getmaxy-50,wall^,0);
putimage(52,getmaxy-50,clp^,0);
putimage(93,getmaxy-50,ataito^,0);
putimage(11,getmaxy-91,barell^,0);
putimage(52,getmaxy-91,thunder^,0);
putimage(11,getmaxy-133,heart^,0);
putimage(getmaxx-50,getmaxy-50,wall^,0);
putimage(getmaxx-92,getmaxy-50,barell^,0);
putimage(getmaxx-133,getmaxy-50,thunder^,0);
putimage(getmaxx-50,getmaxy-91,pgram^,0);
putimage(getmaxx-92,getmaxy-91,sc^,0);
putimage(getmaxx-50,getmaxy-133,ataito^,0);
posx:=24;
tox:=24;
posy:=190-textheight('P');
for j:= 1 to length(a) do begin
putimage(tox,posy,spr3^,0);
for i:=3 downto 1 do begin
setcolor(yellow);
setusercharsize(4,1,i,1);
posy:=190-textheight(a[j])-(4-i)*9;
putimage(posx,posy,spr3^,0);
outtextxy(tox,190-textheight(a[j]),a[j]);
delay(100);
setcolor(black);
setusercharsize(4,1,i,1);
putimage(posx,posy,spc^,0);
outtextxy(tox,190-textheight(a[j]),a[j]);
if keypressed then begin
                   setcolor(yellow);
                   setusercharsize(4,1,3,1);
                   {posx:=posx+11;}
                   outtextxy(24,190-textheight(a[j]),a);
                   putimage(getmaxx-51,150,spr1^,0);
                   delay(60);
                   putimage(getmaxx-51,150,spr3^,0);
                   goto mnu;
                   end;
end;
setcolor(yellow);
outtextxy(tox,190-textheight(a[j]),a[j]);
putimage(tox,posy,spr1^,0);
delay(90);
putimage(tox,posy,spr2^,0);
delay(90);
putimage(tox,posy,spc^,0);
for i:=1 to 3 do begin
setcolor(yellow);
setusercharsize(4,1,i,1);
posx:=posx+11;
putimage(posx,posy,spr2^,0);
outtextxy(tox,190-textheight(a[j]),a[j]);
delay(100);
setcolor(black);
setusercharsize(4,1,i,1);
putimage(posx,posy,spc^,0);
outtextxy(tox,190-textheight(a[j]),a[j]);
dec(posy,23);
if keypressed then begin
                   setcolor(yellow);
                   setusercharsize(4,1,3,1);
                   {posx:=posx+11;}
                   outtextxy(24,190-textheight(a[j]),a);
                   putimage(getmaxx-51,150,spr1^,0);
                   delay(60);
                   putimage(getmaxx-51,150,spr3^,0);
                   goto mnu;
                   end;

end;
setcolor(yellow);
outtextxy(tox,190-textheight(a[j]),a[j]);
tox:=tox+textwidth(a[j]);
posx:=tox;
posy:=190-textheight('P');
end;
putimage(getmaxx-51,150,spr1^,0);
delay(60);
putimage(getmaxx-51,150,spr3^,0);
setcolor(white);
settextstyle(0,0,0);
setviewport(getmaxx div 2-100,250,getmaxx div 2+100,360,clipoff);
outtextxy(100-39,1,'original from');
putimage(50,13,taito^,0);
outtextxy(100-9,75,'and');
putimage(50,88,ocean^,0);

gettime(hi,mi,si,s1i);
timei:=hi*3600+mi*60+si;
repeat
if keypressed then begin
                   dels;
                   goto mnu;
                   end;
gettime(hi,mi,si,s1i);
time:=hi*3600+mi*60+si;
until time-timei>6;

dels;
setcolor(white);
outtextxy(61,1,'PC conversion by');
setcolor(lightblue);
putimage(40,13,b^,0);
putimage(110,13,f^,0);
setcolor(white);
outtextxy(76,60,'Codes by');
setcolor(lightblue);
outtextxy(49,70,'Karg(Phane)');
setcolor(white);
outtextxy(64,88,'Graphics by');
setcolor(lightblue);
outtextxy(79,98,'Alecsei');

gettime(hi,mi,si,s1i);
timei:=hi*3600+mi*60+si;
repeat
if keypressed then begin
                   dels;
                   goto mnu;
                   end;
gettime(hi,mi,si,s1i);
time:=hi*3600+mi*60+si;
until time-timei>6;
{delay(3500);}
dels;
mnu:
r.ah:=$0c;
r.al:=0;
msdos(r);
time:=0;
timemax:=10000000;{case computer!}
setviewport(getmaxx div 2-100,250,getmaxx div 2+100,360,clipoff);
settextstyle(2,0,0);
setusercharsize(2,1,2,1);
setcolor(cyan);
outtextxy(60,1,'Options:');
setcolor(lightcyan);
outtextxy(50,26,'1.Keyboard');
outtextxy(50,51,'2.Cursor keys');
outtextxy(50,76,'3.Start action');
setusercharsize(1,1,2,1);
setcolor(red);
if inflives=true then outtextxy(53,100,'Infinite lives is on ')
                 else outtextxy(53,100,'Infinite lives is off ');
if inftime=true then outtextxy(56,115,'Infinite time is on ')
                else outtextxy(56,115,'Infinite time is off');
repeat
if keypressed then ch:=readkey
              else ch:=#0;
if ch='1' then begin
                 dels;
                 setusercharsize(1,1,1,1);
                 setcolor(lightblue);
                 outtextxy(35,140,'ESC to abort game');
                 setusercharsize(2,1,2,1);
                 setcolor(cyan);
                 outtextxy(30,0,'Redefine keys');
                 setcolor(lightcyan);
                 outtextxy(60,40,'up  :');
                 up:=readkey;
                 setcolor(lightblue);
                 outtextxy(115,40,up);
                 setcolor(lightcyan);
                 outtextxy(60,60,'down:');
                 down:=readkey;
                 setcolor(lightblue);
                 outtextxy(115,60,down);
                 setcolor(lightcyan);
                 outtextxy(60,80,'fire:');
                 fire:=readkey;
                 setcolor(lightblue);
                 outtextxy(115,80,fire);
                 {setcolor(lightcyan);
                 outtextxy(60,100,'hold:');
                 hold:=readkey;
                 setcolor(lightblue);
                 outtextxy(115,100,hold);}
                 delay(3500);
                 dels;
                 goto mnu;
              end;
if ch=#27 then begin
               closegraph;
               clrscr;
               writeln('Thanks for playing Blueflower''s Plotting.');
               writeln('See you in hell.');
               halt(0);
               end;
if ch='2' then begin
                 dels;
                 setcolor(cyan);
                 settextstyle(2,0,0);
                 setusercharsize(1,1,2,1);
                 outtextxy(0,20,'Arrows keys for up and down');
                 outtextxy(0,60,'enter as fire+space as hold');
                 up:=#72;
                 down:=#80;
                 fire:=#13;
                 hold:=#32;
                 delay(3500);
                 dels;
                 goto mnu;
               end;

inc(time);
if time>timemax then begin
                     setviewport(0,0,getmaxx,getmaxy,clipoff);
                     fondu;
                     palrec;
                     topscore;
                     time:=0;
                     goto again;
                     end;
until ch='3';
setviewport(0,0,getmaxx,getmaxy,clipoff);
fondu;
palrec;
close(fis);
dispose(ocean);
dispose(taito);
dispose(b);
dispose(f);

end;
procedure showfield;
var m:string;
    w1:sb;
    rd:integer;
begin
fill16;
defill(10,20,10+40*12,20+40*10);
defill(500,20,590,110);
assign(fis,'plotting.dat');
reset(fis,1);
getmem(w1,imagesize(0,0,90,90));
seek(fis,6656+1600+168);
blockread(fis,w1^,17*128,rd);
putimage(500,20,w1^,0);
blockread(fis,w1^,17*128,rd);
putimage(500,65,w1^,0);
freemem(w1,imagesize(0,0,90,90));
close(fis);
setlinestyle(0,1,0);
defill(500,120,590,160);
settextstyle(1,0,0);
setusercharsize(1,2,1,1);
setcolor(15);
outtextxy(500,120,'remain :');
defill(500,170,590,210);
putimage(500,170,thunder^,0);
setusercharsize(3,4,1,1);
setcolor(15);
str(lives,m);
outtextxy(540,170,' : '+m);
defill(500,220,590,310);
setcolor(15);
outtextxy(500,220,'score:');
defill(500,320,590,360);
settextstyle(1,0,0);
setusercharsize(1,2,1,1);
setcolor(15);
outtextxy(500,320,'qualify:');
end;

procedure BFWSHOW;
type vvlbuffer=array[1..17920] of byte;
     vvlb=^vvlbuffer;
var bfw:vvlb;
begin
assign(fis,'bfw.dat');
new(bfw);
reset(fis,17920);
blockread(fis,bfw^,1);
putimage(getmaxx div 2-150,getmaxy div 2-30,bfw^,0);
dispose(bfw);
repeat until readkey=#13;
fondu;
palrec;
end;

label next,end_game;
BEGIN
if registerbgidriver(@egavga)<0 then begin
                                     clrscr;
                                     gotoxy(0,0);
                                     writeln('EXE file is damaged!');
                                     halt;
                                     end;
if registerbgifont(@sans)<0 then begin
                                     clrscr;
                                     gotoxy(0,0);
                                     writeln('EXE file is damaged!');
                                     halt;
                                     end;
if registerbgifont(@trip)<0 then begin
                                     clrscr;
                                     gotoxy(0,0);
                                     writeln('EXE file is damaged!');
                                     halt;
                                     end;
if registerbgifont(@lcom)<0 then begin
                                     clrscr;
                                     gotoxy(0,0);
                                     writeln('EXE file is damaged!');
                                     halt;
                                     end;
if registerbgifont(@litt)<0 then begin
                                     clrscr;
                                     gotoxy(0,0);
                                     writeln('EXE file is damaged!');
                                     halt;
                                     end;



gd:=vga;
gm:=vgahi;
initgraph(gd,gm,'');
if graphresult<>grok then begin
                         closegraph;
                         clrscr;
                         writeln('Sorry,graphics not available or file missing.');
                         halt(0);
                         end;
palrec;
chkint;
chkparam;

assign(fis,'plotting.dat');
reset(fis,1);
seek(fis,390+4352+6656+1600+168);
new(spr1);
new(spr2);
new(spr3);
new(spr4);
new(yang);
new(thunder);
new(ataito);
new(heart);
new(wall);
new(barell);
new(sc);
new(clp);
new(pgram);
new(boom1);
new(boom2);
new(boom3);
blockread(fis,spr1^,7*128,blocks);
blockread(fis,spr2^,7*128,blocks);
blockread(fis,spr3^,7*128,blocks);
blockread(fis,spr4^,7*128,blocks);
blockread(fis,yang^,7*128,blocks);
blockread(fis,thunder^,7*128,blocks);
blockread(fis,ataito^,7*128,blocks);
blockread(fis,heart^,7*128,blocks);
blockread(fis,wall^,7*128,blocks);
blockread(fis,barell^,7*128,blocks);
blockread(fis,sc^,7*128,blocks);
blockread(fis,clp^,7*128,blocks);
blockread(fis,pgram^,7*128,blocks);
blockread(fis,boom1^,7*128,blocks);
blockread(fis,boom2^,7*128,blocks);
blockread(fis,boom3^,7*128,blocks);
cleardevice;
new(spc);
getimage(0,0,39,39,spc^);
cleardevice;
up:='q';
down:='z';
fire:='m';
hold:='h';
{present;}
bfwshow;
checkbreak:=false;
next:score:=0;
present1;
lives:=3;
level:=1;
qualify:=10;
exitcode:=0;
showfield;
settextstyle(1,0,0);
setusercharsize(1,1,1,1);
setcolor(lightred);
str(level,m);
outtextxy(150,150,'STAGE '+m);
repeat until readkey=#13;
level1;
while level<4 do
begin
if exitcode=0 then begin
                    fondu;
                    palrec;
                    showfield;
                    settextstyle(1,0,0);
                    setusercharsize(1,1,1,1);
                    inc(level);
                    if level>3 then goto end_game;
                    setcolor(lightred);
                    str(level,m);
                    outtextxy(150,150,'STAGE '+m);
                    r.ah:=$0c;
                    r.al:=0;
                    msdos(r);
                    repeat until readkey=#13;
                    level1;
                    end;
if exitcode=1 then begin
                       topscore;
                       goto next;
                   end;
if exitcode=2 then begin
                        exitcode:=0;
                        showfield;
                        level1;
                   end;
if exitcode=4 then goto next;
end;
end_game:closegraph;
clrscr;
writeln('This is promotional version of BlueFlower''s Plotting.');
writeln('If you like it,call 623755/Romania to get more levels.');
writeln('Thank you.');
END.


