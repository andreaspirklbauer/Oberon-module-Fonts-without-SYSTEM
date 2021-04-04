MODULE Fonts; (*JG 18.11.90; PDR 8.6.12; NW 18.1.2019 / AP 1.9.20*)
  IMPORT Files;

  CONST FontFileId = 0DBH;
    FontDescSize = 568; (*excluding raster*) RasterSize = 2360; RasterExtSize = 2560;

  TYPE Font* = POINTER TO FontDesc;
    FontDesc* = RECORD
      name*: ARRAY 32 OF CHAR;
      height*, minX*, maxX*, minY*, maxY*: INTEGER;
      next*: Font;
      T: ARRAY 128 OF INTEGER;
      raster: ARRAY RasterSize OF BYTE
    END ;

    LargeFontDesc = RECORD (FontDesc) ext: ARRAY RasterExtSize OF BYTE END ;
    LargeFont = POINTER TO LargeFontDesc;
    RunRec = RECORD beg, end: BYTE END ;
    BoxRec = RECORD dx, x, y, w, h: BYTE END ;

  (* raster sizes: Syntax8 1367, Syntax10 1628, Syntax12 1688, Syntax14 1843, Syntax14b 1983,
      Syntax16 2271, Syntax20 3034, Syntac24 4274, Syntax24b 4302  *)

  VAR Default*, root*: Font;

  PROCEDURE GetPat*(fnt: Font; ch: CHAR; VAR dx, x, y, w, h, patadr: INTEGER);
    VAR pa: INTEGER; yb: BYTE;
  BEGIN pa := fnt.T[ORD(ch) MOD 80H]; patadr := ORD(fnt) + FontDescSize + pa;
    IF pa < RasterSize THEN
      dx := fnt.raster[pa-3]; x := fnt.raster[pa-2]; yb := fnt.raster[pa-1]; w := fnt.raster[pa]; h := fnt.raster[pa+1]
    ELSE dx := fnt(LargeFont).ext[pa-3-RasterSize];
      x := fnt(LargeFont).ext[pa-2-RasterSize]; yb := fnt(LargeFont).ext[pa-1-RasterSize];
      w := fnt(LargeFont).ext[pa-RasterSize]; h := fnt(LargeFont).ext[pa+1-RasterSize]
    END ;
    IF yb < 128 THEN y := yb ELSE y := yb - 256 END
  END GetPat;

  PROCEDURE This*(name: ARRAY OF CHAR): Font;
    VAR F: Font; LF: LargeFont;
      f: Files.File; R: Files.Rider;
      NofRuns, NofBoxes, height, minX, maxX, minY, maxY, b: BYTE;
      NofBytes, j, k, m, n, a: INTEGER;
      run: ARRAY 16 OF RunRec;
      box: ARRAY 512 OF BoxRec;

    PROCEDURE RdInt16(VAR R: Files.Rider; VAR b0: BYTE);
      VAR b1: BYTE;
    BEGIN Files.ReadByte(R, b0); Files.ReadByte(R, b1)
    END RdInt16;

  BEGIN F := root;
    WHILE (F # NIL) & (name # F.name) DO F := F.next END ;
    IF F = NIL THEN
      f := Files.Old(name);
      IF f # NIL THEN
        Files.Set(R, f, 0); Files.ReadByte(R, b);
        IF b = FontFileId THEN
          Files.ReadByte(R, b); (*abstraction*)
          Files.ReadByte(R, b); (*family*)
          Files.ReadByte(R, b); (*variant*)
          RdInt16(R, height); RdInt16(R, minX); RdInt16(R, maxX); RdInt16(R, minY); RdInt16(R, maxY); RdInt16(R, NofRuns);
          NofBoxes := 0; k := 0;
          WHILE k # NofRuns DO  (*read runs*)
            RdInt16(R, run[k].beg); RdInt16(R, run[k].end);
            NofBoxes := NofBoxes + run[k].end - run[k].beg;
            INC(k)
          END ;
          NofBytes := 5; j := 0;
          WHILE j # NofBoxes DO  (*read boxes*)
            RdInt16(R, box[j].dx); RdInt16(R, box[j].x); RdInt16(R, box[j].y);
            RdInt16(R, box[j].w); RdInt16(R, box[j].h);
            NofBytes := NofBytes + 5 + (box[j].w + 7) DIV 8 * box[j].h;
            INC(j)
          END ;
          IF NofBytes < RasterSize THEN NEW(F) ELSE NEW(LF); F := LF END ;
          F.name := name;
          F.height := height; F.minX := minX; F.maxX := maxX; F.maxY := maxY;
          IF minY >= 80H THEN F.minY := minY - 100H ELSE F.minY := minY END ;
          F.raster[0] := 0; F.raster[1] := 0; F.raster[2] := 0; F.raster[3] := 0; F.raster[4] := 0;
          (*null pattern for characters not in a run*)
          a := 5; j := 0; k := 0; m := 0;
          WHILE k < NofRuns DO
            WHILE (m < run[k].beg) & (m < 128) DO F.T[m] := 3; INC(m) END ;
            WHILE (m < run[k].end) & (m < 128) DO F.T[m] := a+3;
              IF a < RasterSize THEN
                F.raster[a] := box[j].dx; F.raster[a+1] := box[j].x; F.raster[a+2] := box[j].y;
                F.raster[a+3] := box[j].w; F.raster[a+4] := box[j].h
              ELSE F(LargeFont).ext[a-RasterSize] := box[j].dx;
                F(LargeFont).ext[a+1-RasterSize] := box[j].x; F(LargeFont).ext[a+2-RasterSize] := box[j].y;
                F(LargeFont).ext[a+3-RasterSize] := box[j].w; F(LargeFont).ext[a+4-RasterSize] := box[j].h
              END ;
              INC(a, 5); n := (box[j].w + 7) DIV 8 * box[j].h; (*pattern length*)
              WHILE n # 0 DO DEC(n); Files.ReadByte(R, b);
                IF a < RasterSize THEN F.raster[a] := b ELSE F(LargeFont).ext[a-RasterSize] := b END ;
                INC(a)
              END ;
              INC(j); INC(m)
            END ;
            INC(k)
          END ;
          WHILE m < 128 DO F.T[m] := 3; INC(m) END ;
          F.next := root; root := F
        ELSE (*bad file id*) F := Default
        END
      ELSE (*font file not available*) F := Default
      END
    END ;
    RETURN F
  END This;

  PROCEDURE Free*;  (*remove all but first two from font list*)
  BEGIN IF root.next # NIL THEN root.next.next := NIL END
  END Free;

BEGIN root := NIL; Default := This("Oberon10.Scn.Fnt")
END Fonts.
