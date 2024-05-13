unit game;
interface
uses graph,crt,dos,tcv;
var fis:file;
procedure level1;
implementation
var ox,oy,aox,aoy,hit,remains:integer;
    m:string;
    hold:sb;
    holds,intermed:gam;
    g1:gam;
procedure putt(g:string;coordx,coordy:integer);forward;
procedure putmatr(g:gam);forward;
procedure verify;forward;
procedure change(g:string);forward;
function addscore:boolean;forward;
function check:boolean;forward;
procedure level1;
var ch:char;
    i,j,ang:integer;
    tim,m,s,time,manv,strtime:word;
    scores:string;
    r:registers;
label retn,pr2,retn1,retn2;
begin
assign(fis,'plotting.dat');
reset(fis,1);
seek(fis,(level-1)*sizeof(g1)+4352+6656+1600+168);
blockread(fis,g1,sizeof(g1));
if level div 6=int(level div 6) then dec(qualify);
settextstyle(1,0,0);
setusercharsize(1,2,1,1);
setcolor(white);
str(qualify,scores);
outtextxy(570,320,scores);
gettime(manv,m,s,manv);
time:=m*60+s;
strtime:=time;
ang:=90;
ox:=1;
oy:=1;
new(hold);
hold:=thunder;
holds[1,1]:='t';
putmatr(g1);
putimage((oy-1)*40+10,(ox-1)*40+20,spr3^,0);
putimage(oy*40+10,(ox-1)*40+20,hold^,0);
setlinestyle(0,1,0);
repeat
retn:{ch:=port[$60];
asm mov ax,$0c02
    int $21
end;}
if keypressed then ch:=readkey
              else ch:=#0;

if ch=up then begin
                r.ah:=$0c;
                r.al:=0;
                msdos(r);
                putimage((oy-1)*40+10,(ox-1)*40+20,spr1^,0);
                delay(100);
                putimage((oy-1)*40+10,(ox-1)*40+20,spc^,0);
                putimage(oy*40+10,(ox-1)*40+20,spc^,0);
                dec(ox);
                verify;
                putimage((oy-1)*40+10,(ox-1)*40+20,spr3^,0);
                putimage(oy*40+10,(ox-1)*40+20,hold^,0);
                end;
if ch=down then begin
                r.ah:=$0c;
                r.al:=0;
                msdos(r);
                putimage((oy-1)*40+10,(ox-1)*40+20,spr1^,0);
                delay(100);
                putimage((oy-1)*40+10,(ox-1)*40+20,spc^,0);
                putimage(oy*40+10,(ox-1)*40+20,spc^,0);
                inc(ox);
                verify;
                putimage((oy-1)*40+10,(ox-1)*40+20,spr3^,0);
                putimage(oy*40+10,(ox-1)*40+20,hold^,0);
                end;
if ch=fire then begin
                r.ah:=$0c;
                r.al:=0;
                msdos(r);
                putimage((oy-1)*40+10,(ox-1)*40+20,spr4^,0);
                delay(80);
                putimage((oy-1)*40+10,(ox-1)*40+20,spr3^,0);
                delay(80);
                putimage((oy-1)*40+10,(ox-1)*40+20,spr2^,0);
                delay(80);
                putimage((oy-1)*40+10,(ox-1)*40+20,spr3^,0);
                hit:=0;
                aox:=ox;
                aoy:=oy+1;
                while aoy <= 12 do begin
                putimage((aoy-1)*40+10,(aox-1)*40+20,hold^,0);
                delay(30);
                putimage((aoy-1)*40+10,(aox-1)*40+20,spc^,0);
                if (g1[aox,aoy]='b') or (g1[aox,aoy]='w') then begin
                                                               putt(g1[aox,aoy],aox-1,aoy-1);
                                                               putimage(oy*40+10,(ox-1)*40+20,hold^,0);
                                                               dec(aoy);
                                                               if addscore=true then exit;
                                                               goto pr2;
                                                               end;
                if g1[aox,aoy]='t' then begin
                                        g1[aox,aoy]:=holds[1,1];
                                        setcolor(0);
                                        str(lives,scores);
                                        outtextxy(540,170,' : '+scores);
                                        inc(lives,1);
                                        str(lives,scores);
                                        setcolor(15);
                                        outtextxy(540,170,' : '+scores);
                                        end;
                if (g1[aox,aoy]='c')    then begin
                                        g1[aox,aoy]:=holds[1,1];
                                        inc(time,10);
                                        end;
                if (g1[aox,aoy]<>' ') and (g1[aox,aoy]<>holds[1,1]) and (holds[1,1]<>'t') then begin
                                                                    putt(g1[aox,aoy],aox-1,aoy-1);
                                                                    putimage(oy*40+10,(ox-1)*40+20,hold^,0);
                                                                    if addscore=true then exit;
                                                                    if check=true then exit;
                                                                    goto retn;
                                                                    end;
                if (g1[aox,aoy]=holds[1,1]) or ((holds[1,1]='t') and (g1[aox,aoy]<>' ')) then begin
                                          inc(hit);
                                          if holds[1,1]='t' then begin
                                                            holds[1,1]:=g1[aox,aoy];
                                                            change(holds[1,1]);
                                                            end;
                                          putimage((aoy-1)*40+10,(aox-1)*40+20,boom1^,0);
                                          delay(60);
                                          putimage((aoy-1)*40+10,(aox-1)*40+20,boom2^,0);
                                          delay(60);
                                          putimage((aoy-1)*40+10,(aox-1)*40+20,boom3^,0);
                                          delay(60);
                                          for i:=aox downto 2 do begin
                                                                   if (g1[i-1,aoy]<>'b') and (g1[i-1,aoy]<>'w') then begin
                                                                   putt(g1[i-1,aoy],i-1,aoy-1);
                                                                   g1[i,aoy]:=g1[i-1,aoy];
                                                                   putt(' ',i-2,aoy-1);
                                                                   g1[i-1,aoy]:=' ';
                                                                   end
                                                                   else goto retn1;

                                          end;

retn1:if (aoy+1<=12) then if (g1[aox,aoy+1]<>'w') and (g1[aox,aoy+1]<>'b') and (g1[aox,aoy+1]<>' ') and (g1[aox,aoy+1]<>'c')
and (g1[aox,aoy+1]<>'t') then if (holds[1,1]<>'t') then begin
                          intermed[1,1]:=g1[aox,aoy+1];
                          g1[aox,aoy+1]:=holds[1,1];
                          holds[1,1]:=intermed[1,1];
                          change(holds[1,1]);
                          end;
                                          putt(g1[aox,aoy],aox-1,aoy-1);
                                          putt(holds[1,1],ox-1,oy);
                                          end;

                inc(aoy);
                end;
                dec(aoy);
                putt(' ',aox-1,aoy-1);
                g1[aox,aoy]:=' ';
                if addscore=true then exit;
               pr2:while aox<=10 do begin
                putimage((aoy-1)*40+10,(aox-1)*40+20,hold^,0);
                delay(30);
                putimage((aoy-1)*40+10,(aox-1)*40+20,spc^,0);
                if g1[aox,aoy]='w' then begin
                                          putt(g1[aox,aoy],aox-1,aoy-1);
                                          putimage(oy*40+10,(ox-1)*40+20,hold^,0);
                                          if addscore=true then exit;
                                          if check=true then exit;
                                          goto retn;
                                          end;
                if g1[aox,aoy]='t' then begin
                                        g1[aox,aoy]:=holds[1,1];
                                        setcolor(0);
                                        str(lives,scores);
                                        outtextxy(540,170,' : '+scores);
                                        inc(lives);
                                        str(lives,scores);
                                        setcolor(15);
                                        outtextxy(540,170,' : '+scores);
                                        end;
                if g1[aox,aoy]='c' then begin
                                        g1[aox,aoy]:=holds[1,1];
                                        inc(time,10);
                                        end;
                if (g1[aox,aoy]<>' ') and (g1[aox,aoy]<>holds[1,1]) and (holds[1,1]<>'t') then begin
                                                                    putt(g1[aox,aoy],aox-1,aoy-1);
                                                                    putimage(oy*40+10,(ox-1)*40+20,hold^,0);
                                                                    if addscore=true then exit;
                                                                    if check=true then exit;
                                                                    goto retn;
                                                                    end;
                if (g1[aox,aoy]=holds[1,1]) or ((holds[1,1]='t') and (g1[aox,aoy]<>' ')) then begin
                                            inc(hit);
                                            if holds[1,1]='t' then begin
                                                            holds[1,1]:=g1[aox,aoy];
                                                            change(holds[1,1]);
                                                            end;
                                            putimage((aoy-1)*40+10,(aox-1)*40+20,boom1^,0);
                                            delay(50);
                                            putimage((aoy-1)*40+10,(aox-1)*40+20,boom2^,0);
                                            delay(50);
                                            putimage((aoy-1)*40+10,(aox-1)*40+20,boom3^,0);
                                            delay(50);
                                            for i:=aox downto 2 do begin
                                                                   if (g1[i-1,aoy]<>'b') and (g1[i-1,aoy]<>'w') then begin
                                                                   putt(g1[i-1,aoy],i-1,aoy-1);
                                                                   g1[i,aoy]:=g1[i-1,aoy];
                                                                   putt(' ',i-2,aoy-1);
                                                                   g1[i-1,aoy]:=' ';
                                                                   end
                                                                   else goto retn2;

                                          end;
retn2:if (aox+1<=10) then if (g1[aox+1,aoy]<>'w') and (g1[aox+1,aoy]<>'b') and (g1[aox+1,aoy]<>' ') and (g1[aox+1,aoy]<>' ')
and (g1[aox+1,aoy]<>'c') and (g1[aox+1,aoy]<>'t') then if (holds[1,1]<>'t') then begin
 intermed[1,1]:=g1[aox+1,aoy];
 g1[aox+1,aoy]:=holds[1,1];
 holds[1,1]:=intermed[1,1];
 change(holds[1,1]);
 end;
                                          putt(g1[aox,aoy],aox-1,aoy-1);
                                          putt(holds[1,1],ox-1,oy);
                                          end;
                inc(aox);
                end;
                putimage(oy*40+10,(ox-1)*40+20,hold^,0);
                if addscore=true then exit;
                if check=true then exit;
                end;
gettime(manv,m,s,manv);
tim:=60*m+s;
if inftime=false then begin
                         settextstyle(1,0,0);
                         setusercharsize(3,4,1,1);
                         if tim-strtime>=180 then begin
                         if inflives=false then begin
                                                setcolor(0);
                                                str(lives,scores);
                                                outtextxy(540,170,' : '+scores);
                                                setcolor(15);
                                                dec(lives);
                                                str(lives,scores);
                                                outtextxy(540,170,' : '+scores);
                                                end;
                         if lives=0 then begin
                                         setcolor(black);
                                         outtextxy(getmaxx div 2-160,getmaxy div 2-20,'Game over');
                                         setcolor(lightred);
                                         outtextxy(getmaxx div 2-160,getmaxy div 2-20,'Game over');
                                         delay(2000);
                                         exitcode:=1;
                                         exit;
                                         end;
                         setcolor(black);
                         outtextxy(getmaxx div 2-160,getmaxy div 2-20,'Time up!');
                         setcolor(lightred);
                         outtextxy(getmaxx div 2-160,getmaxy div 2-20,'Time up !');
                         delay(2000);
                         exitcode:=2;
                         exit;
                         end;
                         setcolor(14);
                         if tim>=time then while tim-time>=2 do begin
                         inc(time);
                         setfillstyle(1,14);
                         dec(ang,2);
                         if ang >= 0 then begin
                                              pieslice(545,65,ang,90,24);
                                            end
                                       else begin
                                              pieslice(545,65,360+ang,360,24);
                                            end;

                         
                         end;
                         end;
until ch=#27;
exitcode:=4;
settextstyle(1,0,0);
setusercharsize(1,1,1,1);
setcolor(black);
outtextxy(getmaxx div 2-160,getmaxy div 2-20,'Game aborted...');
setcolor(lightred);
outtextxy(getmaxx div 2-160,getmaxy div 2-20,'Game aborted...');
delay(2000);
end;
procedure PUTT(g:string;coordx,coordy:integer);
begin;
if g='w' then putimage(10+40*coordy,20+40*coordx,wall^,0);
if g='b' then putimage(10+40*coordy,20+40*coordx,barell^,0);
if g='t' then putimage(10+40*coordy,20+40*coordx,thunder^,0);
if g='s' then putimage(10+40*coordy,20+40*coordx,sc^,0);
if g='a' then putimage(10+40*coordy,20+40*coordx,ataito^,0);
if g='p' then putimage(10+40*coordy,20+40*coordx,pgram^,0);
if g='h' then putimage(10+40*coordy,20+40*coordx,heart^,0);
if g='y' then putimage(10+40*coordy,20+40*coordx,yang^,0);
if g='c' then putimage(10+40*coordy,20+40*coordx,clp^,0);
if g=' ' then putimage(10+40*coordy,20+40*coordx,spc^,0);
end;
procedure PUTMATR(g:gam);
var i,j:integer;
begin;
remains:=0;
for i:=0 to 9 do begin
for j:=0 to 11 do begin
if (g1[i+1,j+1]<>' ') and (g1[i+1,j+1]<>'w') and (g1[i+1,j+1]<>'b') then inc(remains);
putt(g1[i+1,j+1],i,j);
end;
end;
settextstyle(1,0,0);
setusercharsize(1,2,1,1);
setcolor(white);
str(remains,m);
outtextxy(570,120,m);
end;
procedure VERIFY;
begin
if ox<1 then ox:=1;
if ox>10 then ox:=10;
end;
procedure CHANGE(g:string);
begin
{if g='w' then hold:=wall;
if g='b' then hold:=barell;}
if g='t' then hold:=thunder;
if g='s' then hold:=sc;
if g='a' then hold:=ataito;
if g='p' then hold:=pgram;
if g='h' then hold:=heart;
if g='y' then hold:=yang;
{if g='c' then hold:=clp;}
end;
function ADDSCORE:boolean;
var coord:integer;
begin
addscore:=false;
if hit>0 then begin
settextstyle(1,0,0);
setusercharsize(1,2,1,1);
setcolor(black);
str(remains,m);
outtextxy(570,120,m);
dec(remains,hit);
setcolor(white);
str(remains,m);
outtextxy(570,120,m);
setcolor(0);
str(score,m);
outtextxy(500,260,m);
score:=score+600*hit;
setcolor(15);
str(score,m);
outtextxy(500,260,m);
settextstyle(1,0,0);
setusercharsize(3,2,3,2);
str(600*hit,m);
setcolor(yellow);
outtextxy(110,70,m);
delay(160);
setcolor(black);
outtextxy(110,70,m);
if remains<=qualify then begin
                         setcolor(yellow);
                         settextstyle(1,0,0);
                         setusercharsize(1,2,1,2);
                         outtextxy(120,50,'CONGRATULATION !');
                         outtextxy(120,75,'STAGE    CLEARED');
                         outtextxy(120,90,'BONUS  :');
                         str((qualify-remains+1)*600,m);
                         setcolor(lightgreen);
                         outtextxy(191,90,' '+m);
                         setusercharsize(1,2,1,1);
                         setcolor(black);
                         str(score,m);
                         outtextxy(500,260,m);
                         inc(score,(qualify-remains+1)*600);
                         setcolor(white);
                         str(score,m);
                         outtextxy(500,260,m);
                         coord:=20+40*9;
                         putimage((oy-1)*40+10,(ox-1)*40+20,spc^,0);
                         putimage(oy*40+10,(ox-1)*40+20,spc^,0);
                         putimage(10,coord,spr3^,0);
                         repeat
                         putimage(10,coord,spr3^,0);
                         delay(50);
                         putimage(10,coord,spr2^,0);
                         delay(50);
                         putimage(10,coord,spc^,0);
                         repeat
                         putimage(10,coord,spr1^,xorput);
                         delay(40);
                         putimage(10,coord,spr1^,xorput);
                         dec(coord,20);
                         until coord<=240;
                         repeat
                         putimage(10,coord,spr1^,xorput);
                         delay(40);
                         putimage(10,coord,spr1^,xorput);
                         inc(coord,20);
                         until coord>=380;
                         until keypressed;
                         exitcode:=0;
                         addscore:=true;
                         end;

hit:=0;
end;
end;
function CHECK:boolean;
var i,j,k:integer;
    m:string;
label checkok,other;
begin
check:=false;
for j:=10 downto 2 do begin
for i:=col[level] to 12 do begin
if (g1[j,i]=holds[1,1])  then begin
                              if i=col[level] then goto checkok;
                              for k:=col[level] to i-1 do
                              if g1[j,k]<>' ' then goto other;
                              goto checkok;
                              end;
other:if (g1[j,i]=holds[1,1]) and (g1[j-1,i]=' ') then begin
                                                 if i=12 then goto checkok;
                                                 for k:=j downto 1 do
                                                 if (g1[k,i+1]='b') or (g1[k,i+1]='w') then goto checkok;
                                                 end;
end;
end;
settextstyle(1,0,0);
setusercharsize(1,1,1,1);
setcolor(yellow);
outtextxy(110,70,'MISSED !');
delay(240);
setcolor(0);
outtextxy(110,70,'MISSED !');
holds[1,1]:='t';
change(holds[1,1]);
putimage(oy*40+10,(ox-1)*40+20,hold^,0);
if inflives=false then begin
                       setusercharsize(3,4,1,1);
                       setcolor(0);
                       str(lives,m);
                       outtextxy(540,170,' : '+m);
                       dec(lives);
                       if lives=0 then begin
                                         setusercharsize(1,1,1,1);
                                         setcolor(lightred);
                                         outtextxy(getmaxx div 2-160,getmaxy div 2-20,'Game over');
                                         delay(2000);
                                         setcolor(black);
                                         outtextxy(getmaxx div 2-160,getmaxy div 2-20,'Game over');
                                         exitcode:=1;
                                         check:=true;
                                         goto checkok;
                                         end;
                       setusercharsize(3,4,1,1);
                       str(lives,m);
                       setcolor(15);
                       outtextxy(540,170,' : '+m);
                       end;
checkok:end;
end.