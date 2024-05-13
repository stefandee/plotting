UNIT tcv;
INTERFACE
uses graph,crt,dos;
type scrbuf=array[1..896] of byte;
     sb=^scrbuf;
     gam=array[1..10] of string[12];
const inflives:boolean=false;
      inftime:boolean=false;
      vgacolors:array[1..16,1..4] of integer=(
                                         {black}      (0,0,0,0),
                                         {blue}       (1,0,0,31),
                                         {green}      (2,0,31,0),
                                         {cyan}       (3,0,31,31),
                                         {red}        (4,31,0,0),
                                         {magenta}    (5,31,0,31),
                                         {brown}      (6,31,15,0),
                                         {lightgray}  (7,31,31,31),
                                         {darkgray}   (8,15,15,15),
                                         {lightblue}  (9,0,0,63),
                                         {lightgreen} (10,0,63,0),
                                         {lightcyan}  (11,0,63,63),
                                         {lightred}   (12,63,0,0),
                                         {lightmagenta}(13,63,0,63),
                                         {yellow}      (14,63,63,0),
                                         {white}       (15,63,63,63));
    col:array[1..3] of integer=(6,6,6);
var gd,gm,lives,exitcode,level,qualify:integer;
    score:longint;
    blocks:word;
    f:file;
    spr1,spr2,spr3,spr4,sc,heart,thunder,yang,ataito,clp,spc,wall,barell,pgram:sb;
    boom1,boom2,boom3:sb;
    up,down,fire,hold:char;
    leveldat:file of gam;
IMPLEMENTATION
END.