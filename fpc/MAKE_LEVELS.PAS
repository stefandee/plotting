program Make_Levels;

uses plottingutils;

const
  (*
	s = smilie
	a = gate (taito)
	p = pentagram (x)
	h = heart (square)
	y = yin/yang (O)
	
    t = extra live
	c = time bonus  
  *)

  levels : array[1..MAX_LEVELS] of TLevelDef =
  (
    { Level 01 }
    (
      tiles: (
        '        wwww',
        '         www',
        '          ww',
        '           w',
        '            ',
        '            ',
        '        hhhp',
        '        pppy',
        '        aaaa',
        '        yyyh'
      );

      qualify: 3
    ),
	
    { Level 02 }
    (
      tiles: (
        '        wwww',
        '         www',
        '          ww',
        '           w',
        '            ',
        '            ',
        '        yyyp',
        '        ppph',
        '        yyya',
        '        pppy'
      );

      qualify: 3
    ),
	
    { Level 03 }
    (
      tiles: (
        '        wwww',
        '         www',
        '          ww',
        '           w',
        '            ',
        '            ',
        '        yyyy',
        '        yaaa',
        '        yyyy',
        '        yhpa'
      );

      qualify: 3
    ),
	
    { Level 04 }
    (
      tiles: (
        '        wwww',
        '         www',
        '          ww',
        '           w',
        '            ',
        '            ',
        '        ypyp',
        '        ypyp',
        '        pypy',
        '        pyah'
      );

      qualify: 3
    ),
	
    { Level 05 }
    (
      tiles: (
        '        wwww',
        '         www',
        '          ww',
        '           w',
        '            ',
        '            ',
        '        yahp',
        '        pyah',
        '        pyah',
        '        pyah'
      );

      qualify: 3
    ),
	
    { Level 06 }
    (
      tiles: (
        '        wwww',
        '         www',
        '          ww',
        '           w',
        '            ',
        '       ayahp',
        '       ypahp',
        '       aaaaa',
        '       pyaha',
        '       hhpaa'
      );

      qualify: 9
    ),

    { Level 07 }
    (
      tiles: (
        '        wwww',
        '         www',
        '          ww',
        '           w',
        '       thyaa',
        '       ahasp',
        '       psysa',
        '       sappa',
        '       hhyyp',
        '       ayhsp'
      );

      qualify: 9
    ),

    { Level 08 }
    (
      tiles: (
        '       wwwww',
        '        www ',
        '         b  ',
        '            ',
        '            ',
        '       ahsy ',
        '        as  ',
        '        py  ',
        '       saty ',
        '      ahaspy'
      );

      qualify: 9
    )	
  );

var
  f:file of TLevelDef;
  i:Integer;

begin
  assign(f,'data/Levels');
  rewrite(f);

  for i:=Low(Levels) to High(Levels) do
    begin
      write(f, Levels[i]);
    end;

  close(f);
end.
