procedure TOPSCORE;
type hiscr=array[1..10] of string[23];
     zbase=array[0..29,0..59] of byte;
const msg:array[1..7] of string=('Great !','New high score','Please type your name commander',
                                 'The Defenders','Your memory','is','unforgetable');
var f:file of hiscr;
    c,posn:integer;
    f1:file of zbase;
    hs:hiscr;
    zb:zbase;
    v:longint;
    s,s1:string;
label 1;{daca s-a gasit o intrare in top,se scrie numele si se iese}
begin
cleardevice;
assign(f,'c:\tp60\arma\defender.arm');
reset(f);
read(f,hs);
assign(f1,'c:\tp60\arma\zbase.ARM');
reset(f1);
read(f1,zb);
posn:=0;
for i:=1 to 10 do begin
val(copy(hs[i],16,7),v,c);
if v<=score then begin
        for j:=0 to 29 do
        for k:=0 to 59 do begin
        setfillstyle(1,zb[j,k]);
        bar(k*10+20,j*16,k*10+10+20,j*16+16);
        end;
	     settextstyle(7,0,0);
	     setcolor(white);
	     outtextxy(getmaxx div 2-textwidth(msg[1]) div 2,50,msg[1]);
	     outtextxy(getmaxx div 2-textwidth(msg[2]) div 2,100,msg[2]);
	     setcolor(lightblue);
	     outtextxy(getmaxx div 2-textwidth(msg[3]) div 2,150,msg[3]);
	     for j:=10 downto i do hs[j]:=hs[j-1];
	     setcolor(red);
	     s:='';
	     repeat
	     if keypressed then begin
		        key:=readkey;
		        if (upcase(key)<='Z') and (upcase(key)>=' ') then begin
				       inc(posn);
				       s:=s+upcase(key);
				       outtextxy(getmaxx div 2-100+20*posn,200,upcase(key));
				       end;
              if key=#13 then begin
                              for j:=posn to 9 do s:=s+' ';
                              posn:=10;
                              end;
		        end
		   else key:=#0;
	     until posn>9;
	     str(score,s1);
	     s:=s+'      '+s1;
	     hs[i]:=s;
        goto 1;
	     end;
end;
1:delay(300);
cleardevice;
for j:=0 to 29 do
for k:=0 to 59 do begin
setfillstyle(1,zb[j,k]);
bar(k*10+20,j*16,k*10+10+20,j*16+16);
end;
setcolor(white);
settextstyle(7,0,0);
setusercharsize(1,1,3,2);
outtextxy(getmaxx div 2-textwidth(msg[4]) div 2,0,msg[4]);
settextstyle(3,0,0);
setusercharsize(1,1,1,1);
outtextxy(getmaxx div 2-textwidth(msg[5]) div 2,getmaxy-90,msg[5]);
outtextxy(getmaxx div 2-textwidth(msg[6]) div 2,getmaxy-70,msg[6]);
outtextxy(getmaxx div 2-textwidth(msg[7]) div 2,getmaxy-50,msg[7]);
for i:=1 to 10 do begin
setcolor(black);
outtextxy(getmaxx div 2-textwidth(hs[i]) div 2+3,70+(i-1)*25+3,hs[i]);
setcolor(lightcyan);
outtextxy(getmaxx div 2-textwidth(hs[i]) div 2,70+(i-1)*25,hs[i]);
end;
seek(f,0);
write(f,hs);
repeat
until readkey=#13;
end;
