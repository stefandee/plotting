program sh;
uses graph;
type scrbuf=array[1..32767] of byte;
     sb=^scrbuf;
var f:file;
    i:integer;
    put:sb;
    gd,gm,saved:integer;
begin
gd:=detect;
initgraph(gd,gm,'');
assign(f,'c:\tp60\mine\s_ceas02.jeu');
reset(f);
new(put);
for i:=1 to 30 do begin
blockread(f,put^,19,saved);
putimage(100,100,put^,0);
readln;
end;
readln;
close(f);
dispose(put);
end.