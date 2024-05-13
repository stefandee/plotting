program lin;
uses graph;
type scrbuf=array[1..2432] of byte;
     sb=^scrbuf;
var fis1,fis2,fis3,fisb:file;
    pass:sb;
    rd,gd,gm,i:integer;
begin
gd:=detect;
initgraph(gd,gm,'');
new(pass);
assign(fis1,'c:\tp60\mine\s_ceas01.jeu');
assign(fisb,'c:\tp60\mine\plwtch.jeu');
rewrite(fisb);
reset(fis1);
blockread(fis1,pass^,17,rd);
putimage(0,0,pass^,0);
blockwrite(fisb,pass^,17,rd);
close(fis1);
readln;
assign(fis1,'c:\tp60\mine\s_ceas02.jeu');
reset(fis1);
blockread(fis1,pass^,17,rd);
putimage(0,0,pass^,0);
blockwrite(fisb,pass^,17,rd);
close(fis1);
readln;
close(fisb);
end.