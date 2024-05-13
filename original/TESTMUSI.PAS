program testmusic;
{$M 65520,0,100000}
uses dos,crt;
begin
swapvectors;
exec('intromod.exe','plotting.bin spacecru.mod -2 -q');
swapvectors;
writeln('error :',doserror);
repeat until readkey=#13;
end.