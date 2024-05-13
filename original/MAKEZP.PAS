program mzp;
uses graph;
type buffer=array[1..896] of byte;
     buf=^buffer;
     matr=array[1..40,1..40] of byte;
var f:file;
    pass:buf;
    f1:file of matr;
    zp:matr;
    i,j,gd,gm:integer;
begin
gd:=detect;
initgraph(gd,gm,'c:\tp60');
new(pass);
assign(f,'sprites.jeu');
reset(f,896);
blockread(f,pass^,1,gm);
putimage(0,0,pass^,0);
for i:=0 to 39 do
for j:=0 to 39 do
zp[i+1,j+1]:=getpixel(j,i);
assign(f1,'zsprite.jeu');
rewrite(f1);
write(f1,zp);
close(f1);
close(f);
end.
