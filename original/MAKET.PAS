program ed;
uses graph;
type scrbuf=array[1..34] of byte;
     sb=^scrbuf;
var gd,gm,i,size,saved:integer;
    f:file;
    onf:sb;
begin
gd:=detect;
initgraph(gd,gm,'');
assign(f,'sprites.sss');
rewrite(f);
for i:=0 to 15 do
begin
setcolor(i);
rectangle(0,0,5,5);
setfillstyle(1,i);
floodfill(1,1,i);
size:=imagesize(0,0,6,6);
getmem(onf,size);
getimage(0,0,5,5,onf^);
blockwrite(f,onf^,size div 128+1,saved);
readln;
end;
cleardevice;
setcolor(3);
circle(3,3,2);
getimage(0,0,5,5,onf^);
blockwrite(f,onf^,size div 128+1,saved);
readln;
end.