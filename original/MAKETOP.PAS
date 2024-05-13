PROGRAM mt;
type top=array[1..8] of string[20];
const topscr:top=( 'PHANE         100000',
                   'ALECSEI        90000',
                   'BFW SOFT       80000',
                   'AT LEAST       70000',
                   'PAIN LASTS     60000',
                   'NO WAY PUNK    50000',
                   'THIS TOP IS    40000',
                   'OUT OF TOUCH   30000');
VAR fil:file of top;
begin
assign(fil,'plotthi.top');
rewrite(fil);
write(fil,topscr);
close(fil);
end.