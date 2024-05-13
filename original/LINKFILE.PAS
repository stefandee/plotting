program linker;
{for plotting files}
var fs,fd:file;
    b:array[1..20000] of byte;
    size:word;
begin
assign(fd,'plotting.dat');
rewrite(fd,1);

assign(fs,'plotthi.top');
reset(fs,1);
size:=filesize(fs);
blockread(fs,b,size);
close(fs);
blockwrite(fd,b,size);

assign(fs,'zsprite.jeu');
reset(fs,1);
size:=filesize(fs);
blockread(fs,b,size);
close(fs);
blockwrite(fd,b,size);

assign(fs,'orig.jeu');
reset(fs,1);
size:=filesize(fs);
blockread(fs,b,size);
close(fs);
blockwrite(fd,b,size);

assign(fs,'plwtch.jeu');
reset(fs,1);
size:=filesize(fs);
blockread(fs,b,size);
close(fs);
blockwrite(fd,b,size);

assign(fs,'pllev.jeu');
reset(fs,1);
size:=filesize(fs);
blockread(fs,b,size);
close(fs);
blockwrite(fd,b,size);

assign(fs,'sprites.jeu');
reset(fs,1);
size:=filesize(fs);
blockread(fs,b,size);
close(fs);
blockwrite(fd,b,size);

close(fd);
end.