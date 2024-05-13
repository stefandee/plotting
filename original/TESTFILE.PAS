type top=array[1..8] of string[20];
var f:file;
    t:top;
    i:integer;
BEGIN
assign(f,'plotthi.top');
reset(f,1);
blockread(f,t,sizeof(top));
close(f);
for i:=1 to 8 do
    writeln(t[i]);
readln;
end.