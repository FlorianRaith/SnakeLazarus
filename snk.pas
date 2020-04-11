unit Snk;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, RstrFld, Graphics;

type


  TRGB = record
    R, G, B: integer;
  end;


  TPunkt = record
    X, Y: integer;
    Farbe: TRGB;
  end;


  TSnake = class
  private
    { private declarations }
    fTeile: array of TPunkt;
    fFeld: TRasterFeld;
    fFehler: boolean;
    fAmR, fAmG, fAmB: integer;
    function GetKopf: TPunkt;
    function ZufaelligeFarbe(): TRGB;
    procedure FehlerTest();
    procedure Bewegen();
  public
    { public delcarations }
    constructor Erstelle(X, Y: integer; Feld: TRasterFeld);
    procedure HochBewegen();
    procedure RunterBewegen();
    procedure RechtsBewegen();
    procedure LinksBewegen();
    procedure Wachsen();
    procedure Rendern();
    procedure AI(EssenX, EssenY: integer);
    function Kollidiert(X, y: integer): boolean;

    property Kopf: TPunkt read GetKopf;
    property Fehler: boolean read fFehler;
  end;



  TEssen = class
  private
    fX, fY: integer;
    fFeld: TRasterFeld;
    fFarbe: TRGB;
  public
    constructor Erstelle(X, Y: integer; Feld: TRasterFeld);
    procedure Einsammeln(Snake: TSnake);
    procedure Rendern();

    property X: integer read fX;
    property Y: integer read fY;
  end;


implementation


//--- S N A K E ---//


constructor TSnake.Erstelle(X, Y: integer; Feld: TRasterFeld);
var Punkt: TPunkt;
var Farbe1, Farbe2: TRGB;
begin


  fFeld := Feld;
  fFehler := False;

  Farbe1 := ZufaelligeFarbe();
  Farbe2 := ZufaelligeFarbe();

  fAmR := (Farbe2.R - Farbe1.R) div 15;
  fAmG := (Farbe2.G - Farbe1.G) div 15;
  fAmB := (Farbe2.B - Farbe1.B) div 15;

  Punkt.X := X;
  Punkt.Y := Y;
  Punkt.Farbe := Farbe1;

  SetLength(fTeile, 1);
  fTeile[0] := Punkt;

end;



function TSnake.GetKopf: TPunkt;
begin
  GetKopf := fTeile[0];
end;



function TSnake.ZufaelligeFarbe(): TRGB;
var Farbe: TRGB;
begin
  Farbe.R := Random(205) + 50;
  Farbe.G := Random(205) + 50;
  Farbe.B := Random(205) + 50;
  ZufaelligeFarbe := Farbe;
end;



procedure TSnake.HochBewegen();
begin
  Bewegen();
  Dec(fTeile[0].Y);
  FehlerTest();
  if fFehler then Inc(fTeile[0].Y)
end;



procedure TSnake.RunterBewegen();
begin
  Bewegen();
  Inc(fTeile[0].Y);
  FehlerTest();
  if fFehler then Dec(fTeile[0].Y)
end;



procedure TSnake.RechtsBewegen();
begin
  Bewegen();
  Inc(fTeile[0].X);
  FehlerTest();
  if fFehler then Dec(fTeile[0].X)
end;



procedure TSnake.LinksBewegen();
begin
  Bewegen();
  Dec(fTeile[0].X);
  FehlerTest();
  if fFehler then Inc(fTeile[0].X)
end;



procedure TSnake.FehlerTest();
begin
  if (fTeile[0].X < 0) or (fTeile[0].X >= fFeld.FeldBreite) or (fTeile[0].Y < 0) or (fTeile[0].Y >= fFeld.FeldHoehe) then begin
       fFehler := true;
       Exit;
  end;

  if Kollidiert(fTeile[0].X, fTeile[0].Y) then begin
    fFehler := true;
    Exit;
  end;

  fFehler := false;
end;


procedure TSnake.Bewegen();
var i: integer;
begin
  if Length(fTeile) = 1 then exit;

  for i := (Length(fTeile) - 1) downto 1 do begin
    fTeile[i].X := fTeile[i - 1].X;
    fTeile[i].Y := fTeile[i - 1].Y;
  end;
end;



function TSnake.Kollidiert(X, y: integer): boolean;
var i: integer;
begin
  for i := 1 to (Length(fTeile) - 1) do begin
    if (fTeile[i].X = X) and (fTeile[i].Y = Y) then begin
      Kollidiert := True;
      Exit;
    end;
  end;
  Kollidiert := False;
end;

procedure TSnake.Wachsen();
var Punkt: TPunkt;
var Farbe, NeueFarbe: TRGB;
begin
  SetLength(fTeile, Length(fTeile) + 1);
  Punkt.X := -1;
  Punkt.Y := -1;

  if Length(fTeile) mod 15 = 0 then begin
    NeueFarbe := ZufaelligeFarbe();

    fAmR := (NeueFarbe.R - fTeile[Length(fTeile) - 2].Farbe.R) div 15;
    fAmG := (NeueFarbe.G - fTeile[Length(fTeile) - 2].Farbe.G) div 15;
    fAmB := (NeueFarbe.B - fTeile[Length(fTeile) - 2].Farbe.B) div 15;
  end;

  Farbe.R := fTeile[Length(fTeile) - 2].Farbe.R + fAmR;
  Farbe.G := fTeile[Length(fTeile) - 2].Farbe.G + fAmG;
  Farbe.B := fTeile[Length(fTeile) - 2].Farbe.B + fAmB;

  Punkt.Farbe := Farbe;

  fTeile[Length(fTeile) - 1] := Punkt;
end;


procedure TSnake.Rendern();
var i: integer;
begin
  for i := (Length(fTeile) - 1) downto 0 do
    fFeld.Rechteck(fTeile[i].X, fTeile[i].Y, RGBToColor(fTeile[i].Farbe.R, fTeile[i].Farbe.G, fTeile[i].Farbe.B));
end;

var AiHor: boolean;

procedure TSnake.AI(EssenX, EssenY: integer);
begin
  if Random(30) = 0 then AiHor := not AiHor;

  if AiHor then begin

  if Kopf.X > EssenX then begin

    if (not Kollidiert(Kopf.X - 1, Kopf.Y)) and (Kopf.X - 1 >= 0) then LinksBewegen()
    else if Random(2) = 0 then begin
      if (not Kollidiert(Kopf.X, Kopf.Y - 1)) and (Kopf.Y - 1 >= 0) then HochBewegen()
      else if (not Kollidiert(Kopf.X, Kopf.Y + 1)) and (Kopf.Y + 1 < fFeld.FeldHoehe) then RunterBewegen()
      else RechtsBewegen();
    end else begin
      if (not Kollidiert(Kopf.X, Kopf.Y + 1)) and (Kopf.Y + 1 < fFeld.FeldHoehe) then RunterBewegen()
      else if (not Kollidiert(Kopf.X, Kopf.Y - 1)) and (Kopf.Y - 1 >= 0) then HochBewegen()
      else RechtsBewegen();
    end;


  end else if Kopf.X < EssenX then begin

    if (not Kollidiert(Kopf.X + 1, Kopf.Y)) and (Kopf.X + 1 < fFeld.FeldBreite) then RechtsBewegen()
    else if Random(2) = 0 then begin
      if (not Kollidiert(Kopf.X, Kopf.Y - 1)) and (Kopf.Y - 1 >= 0) then HochBewegen()
      else if (not Kollidiert(Kopf.X, Kopf.Y + 1)) and (Kopf.Y + 1 < fFeld.FeldHoehe) then RunterBewegen()
      else LinksBewegen();
    end else begin
      if (not Kollidiert(Kopf.X, Kopf.Y + 1)) and (Kopf.Y + 1 < fFeld.FeldHoehe) then RunterBewegen()
      else if (not Kollidiert(Kopf.X, Kopf.Y - 1)) and (Kopf.Y - 1 >= 0) then HochBewegen()
      else LinksBewegen();
    end;

  end else if Kopf.Y > EssenY then begin

    if (not Kollidiert(Kopf.X, Kopf.Y - 1)) and (Kopf.Y - 1 >= 0) then HochBewegen()
    else if Random(2) = 0 then begin
      if (not Kollidiert(Kopf.X - 1, Kopf.Y)) and (Kopf.X - 1 >= 0) then LinksBewegen()
      else if (not Kollidiert(Kopf.X + 1, Kopf.Y)) and (Kopf.X + 1 < fFeld.FeldBreite) then RechtsBewegen()
      else RunterBewegen();
    end else begin
      if (not Kollidiert(Kopf.X + 1, Kopf.Y)) and (Kopf.X + 1 < fFeld.FeldBreite) then RechtsBewegen()
      else if (not Kollidiert(Kopf.X - 1, Kopf.Y)) and (Kopf.X - 1 >= 0) then LinksBewegen()
      else RunterBewegen();
    end;

  end else if Kopf.Y < EssenY then begin

    if (not Kollidiert(Kopf.X, Kopf.Y + 1)) and (Kopf.Y + 1 < fFeld.FeldHoehe) then RunterBewegen()
    else if Random(2) = 0 then begin
      if (not Kollidiert(Kopf.X - 1, Kopf.Y)) and (Kopf.X - 1 >= 0) then LinksBewegen()
      else if (not Kollidiert(Kopf.X + 1, Kopf.Y)) and (Kopf.X + 1 < fFeld.FeldBreite) then RechtsBewegen()
      else HochBewegen();
    end else begin
      if (not Kollidiert(Kopf.X + 1, Kopf.Y)) and (Kopf.X + 1 < fFeld.FeldBreite) then RechtsBewegen()
      else if (not Kollidiert(Kopf.X - 1, Kopf.Y)) and (Kopf.X - 1 >= 0) then LinksBewegen()
      else HochBewegen();
    end;

  end;


  end else begin


  if Kopf.Y > EssenY then begin

    if (not Kollidiert(Kopf.X, Kopf.Y - 1)) and (Kopf.Y - 1 >= 0) then HochBewegen()
    else if Random(2) = 0 then begin
      if (not Kollidiert(Kopf.X - 1, Kopf.Y)) and (Kopf.X - 1 >= 0) then LinksBewegen()
      else if (not Kollidiert(Kopf.X + 1, Kopf.Y)) and (Kopf.X + 1 < fFeld.FeldBreite) then RechtsBewegen()
      else RunterBewegen();
    end else begin
      if (not Kollidiert(Kopf.X + 1, Kopf.Y)) and (Kopf.X + 1 < fFeld.FeldBreite) then RechtsBewegen()
      else if (not Kollidiert(Kopf.X - 1, Kopf.Y)) and (Kopf.X - 1 >= 0) then LinksBewegen()
      else RunterBewegen();
    end;

  end else if Kopf.Y < EssenY then begin

    if (not Kollidiert(Kopf.X, Kopf.Y + 1)) and (Kopf.Y + 1 < fFeld.FeldHoehe) then RunterBewegen()
    else if Random(2) = 0 then begin
      if (not Kollidiert(Kopf.X - 1, Kopf.Y)) and (Kopf.X - 1 >= 0) then LinksBewegen()
      else if (not Kollidiert(Kopf.X + 1, Kopf.Y)) and (Kopf.X + 1 < fFeld.FeldBreite) then RechtsBewegen()
      else HochBewegen();
    end else begin
      if (not Kollidiert(Kopf.X + 1, Kopf.Y)) and (Kopf.X + 1 < fFeld.FeldBreite) then RechtsBewegen()
      else if (not Kollidiert(Kopf.X - 1, Kopf.Y)) and (Kopf.X - 1 >= 0) then LinksBewegen()
      else HochBewegen();

    end;
  end else if Kopf.X > EssenX then begin

    if (not Kollidiert(Kopf.X - 1, Kopf.Y)) and (Kopf.X - 1 >= 0) then LinksBewegen()
    else if Random(2) = 0 then begin
      if (not Kollidiert(Kopf.X, Kopf.Y - 1)) and (Kopf.Y - 1 >= 0) then HochBewegen()
      else if (not Kollidiert(Kopf.X, Kopf.Y + 1)) and (Kopf.Y + 1 < fFeld.FeldHoehe) then RunterBewegen()
      else RechtsBewegen();
    end else begin
      if (not Kollidiert(Kopf.X, Kopf.Y + 1)) and (Kopf.Y + 1 < fFeld.FeldHoehe) then RunterBewegen()
      else if (not Kollidiert(Kopf.X, Kopf.Y - 1)) and (Kopf.Y - 1 >= 0) then HochBewegen()
      else RechtsBewegen();
    end;

  end else if Kopf.X < EssenX then begin

    if (not Kollidiert(Kopf.X + 1, Kopf.Y)) and (Kopf.X + 1 < fFeld.FeldBreite) then RechtsBewegen()
    else if Random(2) = 0 then begin
      if (not Kollidiert(Kopf.X, Kopf.Y - 1)) and (Kopf.Y - 1 >= 0) then HochBewegen()
      else if (not Kollidiert(Kopf.X, Kopf.Y + 1)) and (Kopf.Y + 1 < fFeld.FeldHoehe) then RunterBewegen()
      else LinksBewegen();
    end else begin
      if (not Kollidiert(Kopf.X, Kopf.Y + 1)) and (Kopf.Y + 1 < fFeld.FeldHoehe) then RunterBewegen()
      else if (not Kollidiert(Kopf.X, Kopf.Y - 1)) and (Kopf.Y - 1 >= 0) then HochBewegen()
      else LinksBewegen();
    end;

  end;

  end;


end;

//--- E S S E N ---//


constructor TEssen.Erstelle(X, Y: integer; Feld: TRasterFeld);
begin
  fX := X;
  fY := Y;
  fFeld := Feld;
  fFarbe.R := Random(155)+50;
  fFarbe.G := Random(155)+50;
  fFarbe.B := Random(155)+50;
end;


var Ticks: real;


procedure TEssen.Einsammeln(Snake: TSnake);
begin
  fFarbe.R := Random(155)+50;
  fFarbe.G := Random(155)+50;
  fFarbe.B := Random(155)+50;
  repeat
    fX := Random(fFeld.FeldBreite);
    fY := Random(fFeld.FeldHoehe - 1) + 1;
  until (fX <> Snake.Kopf.X) and (fY <> Snake.Kopf.Y);
  Snake.Wachsen();
  Ticks := 0;
end;



procedure TEssen.Rendern();
var Amp: real;
begin
  Ticks := Ticks + 0.04;
  //if Ticks > pi * 2 then Ticks := 0;

  Amp := (abs(sin(Ticks)) / 2) + 0.5;

  fFeld.Rechteck(fX, fY, RGBToColor(round(fFarbe.R * Amp), round(fFarbe.G * Amp), round(fFarbe.B * Amp)));

  Amp := (Amp - 0.5) / 2;

  fFeld.Rechteck(fX + 1, fY, RGBToColor(round(fFarbe.R * Amp), round(fFarbe.G * Amp), round(fFarbe.B * Amp)));
  fFeld.Rechteck(fX - 1, fY, RGBToColor(round(fFarbe.R * Amp), round(fFarbe.G * Amp), round(fFarbe.B * Amp)));
  fFeld.Rechteck(fX, fY + 1, RGBToColor(round(fFarbe.R * Amp), round(fFarbe.G * Amp), round(fFarbe.B * Amp)));
  fFeld.Rechteck(fX, fY - 1, RGBToColor(round(fFarbe.R * Amp), round(fFarbe.G * Amp), round(fFarbe.B * Amp)));

  Amp := Amp / 2;

  fFeld.Rechteck(fX + 1, fY + 1, RGBToColor(round(fFarbe.R * Amp), round(fFarbe.G * Amp), round(fFarbe.B * Amp)));
  fFeld.Rechteck(fX + 1, fY - 1, RGBToColor(round(fFarbe.R * Amp), round(fFarbe.G * Amp), round(fFarbe.B * Amp)));
  fFeld.Rechteck(fX - 1, fY + 1, RGBToColor(round(fFarbe.R * Amp), round(fFarbe.G * Amp), round(fFarbe.B * Amp)));
  fFeld.Rechteck(fX - 1, fY - 1, RGBToColor(round(fFarbe.R * Amp), round(fFarbe.G * Amp), round(fFarbe.B * Amp)));

  Amp := Amp / 2;

  fFeld.Rechteck(fX + 2, fY, RGBToColor(round(fFarbe.R * Amp), round(fFarbe.G * Amp), round(fFarbe.B * Amp)));
  fFeld.Rechteck(fX - 2, fY, RGBToColor(round(fFarbe.R * Amp), round(fFarbe.G * Amp), round(fFarbe.B * Amp)));
  fFeld.Rechteck(fX, fY + 2, RGBToColor(round(fFarbe.R * Amp), round(fFarbe.G * Amp), round(fFarbe.B * Amp)));
  fFeld.Rechteck(fX, fY - 2, RGBToColor(round(fFarbe.R * Amp), round(fFarbe.G * Amp), round(fFarbe.B * Amp)));
end;


end.
