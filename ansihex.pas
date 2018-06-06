{
   ====================================================================
   ANSIHex                                                         xqtr
   ====================================================================
    
   For contact look at Another Droid BBS [andr01d.zapto.org:9999],
   FSXNet and ArakNet.
   
   --------------------------------------------------------------------
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
   MA 02110-1301, USA.
   
}

Program ANSIHex;

{$Mode objfpc}
{$warnings off}
{$packrecords 1}

Uses 
  xCrt,
  xStrings,
  xFileIO,
  SysUtils,
  xMenuInput,
  Classes;
  
Const
  Alpha = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  
Type
  RecItem = Record
    Name : String[30];
    Typ  : String[30];
    Size : Integer;
    Color : String[6];
  End;
  
Var
  Fi : file of byte;
  Fo : Text;
  Ft : Text;
  Rec : Array Of RecItem;
  CountRead : Integer;
  Buff: array[1..15] of Byte;
  Index : Integer;
  Lines : Integer = 0;
  Hex   : String;
  Ascii : String;
  idx   : integer;
  Line : String;
  ri   : Integer;
  rs   : Integer;
  cl   : string;
  bytesread : integer =0;
  i:byte;
  des:string[9];
  FileName:String = '';
  inFile:boolean = false;
  sbytes:integer = 0;
  header:boolean = false;
  bg:boolean = false;
  
Procedure ShowHelp;
Begin
  Writeln('ANSI Hex Dump - A Colorful HEX dump :P');
  writeln;
  writeln('USAGE:');
  writeln(' ansihex <binary_file> [record_description_file] [-h] [-b <size>] [-o <filename>');
  writeln;
  writeln(' binary_file       : The file to display');
  writeln(' record_description_file');
  writeln('                   : A text file that contains the record structure');
  writeln('                     in Pascal format, without the record header or');
  writeln('                     end word. See examples beelow.');
  writeln(' -h                : Display record header');
  writeln(' -b n              : Display only n bytes from the source file');
  writeln(' -o filename       : Save the output to an ANSI file');
  writeln;
  writeln('TIPS');
  writeln('  [] If you are using another language, other than Pascal and want to use');
  writeln('  the program, but you don''t know the variable types, instead of writing the');
  writeln('  variable type you can simply put the number of bytes, that the specific');
  writeln('  record field uses. For example, instead of "PeerIP     : String[15];"');
  writeln('  you can also write "PeerIP     : 16;"');
  writeln;
  writeln('  [] You can choose your own color to highlight all or specific fields.');
  writeln('  Just add the color number after the ending ; in each line. You can use');
  writeln('  two values, one for the foreground and one for the background. Example:');
  writeln('  "Address    : String[30];|17|14" will display the field in yellow text and');
  writeln('  blue background,');
  writeln;
  writeln('  [] Lines that begin with //, # or are empty are ignored.');
  writeln;
  writeln('  [] A + sign is displayed in the right side when a new record begins.');
  writeln;
  writeln('EXAMPLES:');
  writeln('  A sample record description file, saved to a text file.');
  writeln;
  writeln('  //RecLastOn = Record');
  writeln('  DateTime   : LongInt;');
  writeln('  NewUser    : Boolean;');
  writeln('  PeerIP     : String[15];');
  writeln('  PeerHost   : String[50];|15');
  writeln('  Node       : Byte;');
  writeln('  CallNum    : LongInt;');
  writeln('  Handle     : String[30];');
  writeln('  City       : String[25];');
  writeln('  Address    : String[30];');
  writeln('  Gender     : Char;');
  writeln('  EmailAddr  : String[35];');
  writeln('  UserInfo   : String[30];');
  writeln('  OptionData : Array[1..10] of String[60];');
  writeln('  Reserved   : 53;');
  writeln('  //End');
  writeln;
  writeln(' hexdump input.bin record.txt -h -b 500');
  writeln('   This will display the first 500 bytes of the file and also show the');
  writeln('   record data, colors, size.');
  writeln;
  writeln(' hexdump input.bin record.txt -h -o output.ans');
  writeln('   This will save the output to output.ans as long with the header.');
  writeln;
  writeln('                     Written by XQTR of Another Droid BBS');
  writeln('                             andr01d.zapto.org:9999');
  writeln;
  
End;

Function Pipe2Ansi (Col: String) : String;
Var
  CurFG  : Byte;
  CurBG  : Byte;
  Prefix : String[2];
  Color  : Byte;
Begin
  If bg then begin
    bg:=false;
    result:=#27 + '[40m';
  end else
    Result := '';
  While Length(Col)>1 Do Begin
  Color := Str2Int(Copy(Col,2,2));
  
    Case Color of
      00: Result := Result+#27 + '[0;'+  '30m';
      01: Result := Result+#27 + '[0;'+  '34m';
      02: Result := Result+#27 + '[0;'+  '32m';
      03: Result := Result+#27 + '[0;'+  '36m';
      04: Result := Result+#27 + '[0;'+  '31m';
      05: Result := Result+#27 + '[0;'+  '35m';
      06: Result := Result+#27 + '[0;'+  '33m';
      07: Result := Result+#27 + '[0;37m';
      
      08: Result := Result+#27 + '[1;30m';
      09: Result := Result+#27 + '[1;34m';
      10: Result := Result+#27 + '[1;32m';
      11: Result := Result+#27 + '[1;36m';
      12: Result := Result+#27 + '[1;31m';
      13: Result := Result+#27 + '[1;35m';
      14: Result := Result+#27 + '[1;33m';
      15: Result := Result+#27 + '[1;37m';
      16: Begin Result := Result+#27 + '[40m'; bg:=true;end;
      17: Begin Result := Result+#27 + '[41m'; bg:=true;end;
      18: Begin Result := Result+#27 + '[42m'; bg:=true;end;
      19: Begin Result := Result+#27 + '[43m'; bg:=true;end;
      20: Begin Result := Result+#27 + '[44m'; bg:=true;end;
      21: Begin Result := Result+#27 + '[45m'; bg:=true;end;
      22: Begin Result := Result+#27 + '[46m'; bg:=true;end;
      23: Begin Result := Result+#27 + '[47m'; bg:=true;end;
    End;
    Delete(Col,1,3);
  End;
  
End;
  
Procedure LoadRecord;
Var
  L : String;
  Ignore : Boolean = False;
  s : byte;
  ss:string;
  q : byte;
  ci : byte = 2;
  tsize : integer = 0;
  a1,a2,ad:integer;
  ars:word = 0;
Begin
  AssignFile(Ft,ParamStr(2));
  Reset(ft);
  If inFile THen Begin
    AssignFile(fo,FileName);
    Rewrite(fo);
  End;
  
  writeln;
  While Not EOF(Ft) Do Begin
    ReadLn(Ft,L);
    ignore:=false;
    If strStripB(L,' ') = '' Then Ignore :=True;
    If Copy(L,1,2)='//' Then ignore:=true;
    if L[1]='#' then ignore :=true;
    s:=pos(':',L);
    q:=pos(';',L);
    if s=0 then ignore := true;
    if q=0 then ignore := true;
    If Not Ignore then Begin
      
      SetLength(Rec,Length(Rec)+1);
      Rec[high(Rec)].Name := strStripB(Copy(L,1,s-1),' ');
      Rec[high(Rec)].Typ := strStripB(Copy(L,s+1,q-s-1),' ');
      Rec[high(Rec)].Color := Copy(L,q+1,Length(l)-q);
      If strStripB(Rec[high(Rec)].Color,' ') = '' Then Begin
        Rec[high(Rec)].Color:='|'+StrPadL(Int2Str(ci),2,'0');
        ci:=ci+1;
        if ci >15 Then ci:=2;
      End;
      
      //If Pos('ARRAY',Upper(Rec[high(Rec)].Typ))>0 Then Begin
      If InString('array',Rec[high(Rec)].Typ) Then Begin
        a1:=Str2Int(StrWordBetween(Rec[high(Rec)].Typ,'[','..'));
        a2:=Str2Int(StrWordBetween(Rec[high(Rec)].Typ,'..',']'));
        ad := a2-a1+1;
        //writeln(int2str(a1));
        //writeln(int2str(a2));
        //writeln(int2str(ad));
        ss :=StrWordBetween(Upper(Rec[high(Rec)].Typ)+';','OF',';');
        ss:=strStripB(ss,' ');
        Case ss Of
          'WORD'      : ars := 2;
          'INTEGER'   : ars := 4;
          'BYTE'      : ars := 1;
          'CHAR'      : ars := 1;
          'SHORTINT'  : ars := 1;
          'SMALINT'   : ars := 2;
          'CARDINAL'  : ars := 4;
          'LONGINT'   : ars := 4;
          'LONGWORD'  : ars := 4;
          'INT64'     : ars := 8;
          'QWORD'     : ars := 8;
          'BOOLEAN'   : ars := 1;
          'REAL'      : ars := 8;
          'SINGLE'    : ars := 4;
          'DOUBLE'    : ars := 8;
          'EXTENDED'  : ars := 10;
          'COMP'      : ars := 8;
          'CURRENCY'  : ars := 8;
        Else Begin
          If InString('string[',Upper(Rec[high(Rec)].Typ)) Then begin
              //ad:=(1+Str2Int(Copy(Rec[high(Rec)].Typ,Pos('[',Rec[high(Rec)].Typ)+1,Pos(']',Rec[high(Rec)].Typ)-Pos('[',Rec[high(Rec)].Typ)-1)));
              ars:=1+str2int(strwordbetween(upper(Rec[high(Rec)].Typ)+';','STRING[','];'));
            end Else begin
              ars:= 255;
            end;
          End;
        End;
        Rec[high(Rec)].Size := ars*ad;
        tsize:=tsize+Rec[high(Rec)].Size;
      End Else Begin
        Case Upper(Rec[high(Rec)].Typ) Of
          'WORD'      : Rec[high(Rec)].Size := 2;
          'INTEGER'   : Rec[high(Rec)].Size := 4;
          'BYTE'      : Rec[high(Rec)].Size := 1;
          'CHAR'  : Rec[high(Rec)].Size := 1;
          'SHORTINT'  : Rec[high(Rec)].Size := 1;
          'SMALINT'   : Rec[high(Rec)].Size := 2;
          'CARDINAL'  : Rec[high(Rec)].Size := 4;
          'LONGINT'   : Rec[high(Rec)].Size := 4;
          'LONGWORD'  : Rec[high(Rec)].Size := 4;
          'INT64'     : Rec[high(Rec)].Size := 8;
          'QWORD'     : Rec[high(Rec)].Size := 8;
          'BOOLEAN'   : Rec[high(Rec)].Size := 1;
          'REAL'      : Rec[high(Rec)].Size := 8;
          'SINGLE'    : Rec[high(Rec)].Size := 4;
          'DOUBLE'    : Rec[high(Rec)].Size := 8;
          'EXTENDED'  : Rec[high(Rec)].Size := 10;
          'COMP'      : Rec[high(Rec)].Size := 8;
          'CURRENCY'  : Rec[high(Rec)].Size := 8;
        Else 
          If pos('STRING',Upper(Rec[high(Rec)].Typ))>0 Then Begin
            If Pos('[',Rec[high(Rec)].Typ)>0 Then Begin
              Rec[high(Rec)].size:=1+Str2Int(Copy(Rec[high(Rec)].Typ,Pos('[',Rec[high(Rec)].Typ)+1,Pos(']',Rec[high(Rec)].Typ)-Pos('[',Rec[high(Rec)].Typ)-1));
            End Else Rec[high(Rec)].size := 255;
          End Else
            Rec[high(Rec)].Size := Str2Int(Rec[high(Rec)].Typ)
        End;
        tsize:=tsize+Rec[high(Rec)].Size;
      End;
    End;
    
  End;
  If inFile THen
    System.Writeln(fo,Pipe2Ansi('|07')+
        'Total Record Size: '+
        Int2Str(tsize))
  Else
    WritePipe(Pipe2Ansi('|07')+
        'Total Record Size: '+
        Int2Str(tsize)+#13#10);
  CloseFile(ft);
  If inFile THen Begin
    system.writeln(fo,'');
    CloseFile(fo);
  End Else Writeln;
End;

Procedure ShowHeader;
Var
  l : word;
Begin
  For l := 0 to high(rec) Do begin
        If inFile THen Begin
        
          System.Writeln(fo,Pipe2Ansi('|07|16')+StrPadL(Int2Str(l),3,'.')+' '+
          StrPadR(Rec[l].Name,20,' ')+
            StrPadR(Rec[l].Typ,30,' ')+
            StrPadL(Int2Str(Rec[l].Size),8,'.')+'  '+
            //Rec[l].Color+' '+
            Pipe2Ansi(Rec[l].Color)+'####'
          )
        End
        Else Begin
        
        WritePipe('|16|07'+StrPadL(Int2Str(l),3,'.')+' '+
          StrPadR(Rec[l].Name,20,' ')+
            StrPadR(Rec[l].Typ,30,' ')+
            StrPadL(Int2Str(Rec[l].Size),8,'.')+'  '+
            //Rec[l].Color+' '+
            Rec[l].Color+'####'+#13#10
          );
        End;
  end;
End;
  
Begin
  If ParamCount<1 Then Begin
    ShowHelp;
    Exit;
  End;
  
  If Not FileExist(ParamStr(1)) Then Begin
    Writeln('Input File doesn''t exist.');
    Exit;
  End;

  If Not FileExist(ParamStr(2)) Then Begin
    SetLength(Rec,Length(Rec)+1);
    Rec[high(Rec)].Name := 'none';
    Rec[high(Rec)].Typ := 'byte';
    Rec[high(Rec)].Color := '|10';
    Rec[high(Rec)].size:=15;
    SetLength(Rec,Length(Rec)+1);
    Rec[high(Rec)].Name := 'none';
    Rec[high(Rec)].Typ := 'byte';
    Rec[high(Rec)].Color := '|11';
    Rec[high(Rec)].size:=15;
  End Else LoadRecord;
    

 { If FileExist(ParamStr(3)) Then Begin
    Write('Output File all ready exists. Overwrite?');
    If GetYN (WhereX+2, WhereY, 15+16,14+4*16,7,False) = False Then Exit;
  End;}
  
  If ParamCount>1 Then Begin
    For i := 2 to ParamCount Do
      If Upper(ParamStr(i)) = '-H' Then header:=true Else
      If Upper(ParamStr(i)) = '-O' Then Begin
        If ParamCount<i+1 Then Begin
          Writeln('Output File, not given.');
          Halt;
        End;
        InFile:=True;
        FileName:=ParamStr(i+1)
      End Else
      If Upper(ParamStr(i)) = '-B' Then Begin
        If ParamCount<i+1 Then Begin
          Writeln('Bytes option is missing.');
          Halt;
        End;
        sbytes:=Str2Int(ParamStr(i+1));
      End
  End;
  If inFile THen Begin
    AssignFile(fo,Filename);
    If FileExist(filename) then Append(fo) Else
      rewrite(fo);
  End;
  If inFile THen
    System.Writeln(fo,'FILE: '+Upper(ParamStr(1)))
  Else
    WritePipe('|16|07FILE: '+Upper(ParamStr(1))+#13#10);
  
  if header then showheader;
  
  enable_ansi_unix;
//  Fi := TFileStream.Create(ParamStr(1),fmOpenRead or fmShareDenyNone);
  AssignFile(fi,ParamStr(1));
  Reset(fi,1);
  idx := 1;
  
  TextColor(7);
  CountRead:=1;
  ri:=0;
  rs:=-1;
  
  cl:=Pipe2Ansi(Rec[ri].Color);
  Hex := cl;
  Ascii := cl;
  idx:=1;
  des:=Pipe2Ansi('|07')+'';
  
  try
    while CountRead <> 0 Do
    Begin
      for i:=1 to 14 do buff[i]:=0;
      BlockRead(fi,Buff, SizeOf(Buff),CountRead);
      bytesread:=bytesread+CountRead;
      
      For i :=1 to 15 Do Begin
        rs := rs + 1;
        If Rs=Rec[ri].size Then Begin
          rs:=0;
          ri:=ri+1;
          if ri>high(rec) Then Begin 
            ri:=0;
            des:=des+'+';
          End;
          cl:=Pipe2Ansi(Rec[ri].Color);
          
          Hex:=Hex+cl;
          Ascii:=Ascii+cl;
        End;
        //Hex := Hex + ' '+ Pipe2Ansi(Rec[ri].Color)+Int2Hex(Buff,2);
        Hex := Hex + ' '+ Int2Hex(Buff[i],2);
        If (Buff[i] < 32) Then Ascii:= Ascii + '.' Else Ascii:= Ascii + Chr(Buff[i]);
        if idx = 7 then hex:=hex+' ';
        If idx = 15 Then Begin
          idx:=0;
          Line := Pipe2Ansi('|07')+StrPadL(Int2Str(Lines),8,'.')+'d '+Hex+' '+Ascii+' '+Des;
          If inFile THen
            system.write(fo,line+#13#10)
          Else
            writepipe(line+#13#10);
          Lines := Lines + 15;
          Hex := cl;
          Ascii := cl;
          des:=Pipe2Ansi('|07')+'';

        End;
        idx:=idx+1;
      End;
      if sbytes>0 THen 
        If bytesread>=sbytes then break;
    End;
    Line := Pipe2Ansi('|07')+StrPadL(Int2Str(Lines),8,'.')+'d '+Hex+' '+Ascii+' '+Des;
    If inFile THen
      system.writeln(fo,line+#13#10)
    Else
      writePipe(line+#13#10);
  finally close(fi);
  end;
  If inFile THen CloseFile(fo);
 
End.
