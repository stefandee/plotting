program ml;
type gam=array[1..10] of string[12];
const g:gam=( '        wwww',
              '         www',
              '          ww',
              '           w',
              '       thyaa',
              '       ahasp',
              '       psysa',
              '       sappa',
              '       hhyyp',
              '       ayhsp');
      g1:gam=(                             '        wwww',
                                           '         www',
                                           '          ww',
                                           '           w',
                                           '            ',
                                           '       ayahp',
                                           '       ypahp',
                                           '       aaaaa',
                                           '       pyaha',
                                           '       hhpaa');
      g2:gam=(                             '       wwwww',
                                           '        www ',
                                           '         b  ',
                                           '            ',
                                           '            ',
                                           '       ahsy ',
                                           '        as  ',
                                           '        py  ',
                                           '       saty ',
                                           '      ahaspy');
var f:file of gam;
begin
assign(f,'pllev.jeu');
rewrite(f);
write(f,g1);
write(f,g);
write(f,g2);
end.
