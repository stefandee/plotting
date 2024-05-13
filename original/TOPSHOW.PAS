procedure TOPSHOW;
var f:text;
    s:array[1..4] of string;
    alls,a:string;
    i,j,k,decr,endx,endy:integer;
    p,p1:pointer;
label ending,os;
begin
assign(f,'mine\score.jeu');
reset(f);
endy:=200;
endx:=200;
for i:=15 downto 11 do begin
readln(f,s[1]);
readln(f,s[2]);
readln(f,s[3]);
readln(f,s[4]);
alls:=s[1]+'   '+s[2]+'   '+s[3]+'   '+s[4];
setrgbpalette(i,0,15+(15-i)*4,0);
setcolor(i);
setusercharsize(1,1,1,1);
settextstyle(3,0,0);
outtextxy(getmaxx div 2-textwidth(alls) div 2,50,alls);
getmem(p,imagesize(getmaxx div 2-textwidth(alls) div 2,50,getmaxx div 2+textwidth(alls) div 2,85));
getimage(getmaxx div 2-textwidth(alls) div 2,50,getmaxx div 2+textwidth(alls) div 2,85,p^);
j:=50;
repeat
inc(j,3);
putimage(getmaxx div 2-textwidth(alls) div 2,j,p^,0);
if keypressed then goto ending;
putimage(getmaxx div 2-textwidth(alls) div 2,j,p^,0);
until j>endy;
dec(endy,25);
end;
dispose(p);
dispose(p1);
a:='TOP SCORERS';
setcolor(lightblue);
settextstyle(4,0,0);
setusercharsize(1,1,1,1);
for i:=1 to length(a) do begin
if a[i]=' ' then goto os;
outtextxy(getmaxx-textwidth(a[i])-4,0,a[i]);
getmem(p,imagesize(getmaxx-textwidth(a[i])-7,0,getmaxx,60));
getimage(getmaxx-textwidth(a[i])-7,0,getmaxx,60,p^);
j:=getmaxx-textwidth(a[i])-6;
repeat
dec(j,2);
putimage(j,0,p^,0);
putimage(j,0,p^,0);
until j<endx;
for k:=1 to 20 do begin
putimage(endx+2,0,p^,0);
if keypressed then goto ending;
putimage(endx,0,p^,0);
putimage(endx-1,0,p^,0);
end;
os:inc(endx,textwidth(a[i])+6);
end;
setusercharsize(1,1,1,1);
settextstyle(3,0,0);
setrgbpalette(1,0,0,0);
setcolor(1);
outtextxy(getmaxx div 2-150,400,'Tough job...eeh!?');
setusercharsize(2,3,2,3);
setrgbpalette(58,0,0,0);
setcolor(lightgreen);
outtextxy(50,50,'rank');
outtextxy(50+textwidth('rank      '),50,'level');
outtextxy(50+textwidth('rank      level      '),50,'challenger');
outtextxy(50++textwidth('rank      level        challenger     '),50,'score');
for i:=0 to 63 do begin
delay(34);
setrgbpalette(1,0,0,i);
setrgbpalette(58,0,i,0);
end;
repeat
until keypressed;
ending:fondu;
palrec;
end;