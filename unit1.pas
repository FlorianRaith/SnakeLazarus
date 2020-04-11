unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, RstrFld, Snk, dateutils, LCLType;

type

  { TForm1 }

  TForm1 = class(TForm)
    AIRestarter: TTimer;
    BSpielStarten: TButton;
    LErklaerung: TLabel;
    procedure BSpielStartenClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormKeyPress(Sender: TObject; var Key: char);
    procedure FormPaint(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure SpielSchleife(Sender: TObject);
    procedure RestarteAI(Sender: TObject);
    procedure RenderStats();
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  SpielFeld: TRasterFeld;
  Snake: TSnake;
  Essen: TEssen;
  Punkte: integer;
  Rendern, Laden, HandleResize: boolean;
  Breite, Hoehe: integer;
  AI, Neustarten: boolean;

implementation

{$R *.lfm}

{ TForm1 }



procedure TForm1.BSpielStartenClick(Sender: TObject);
var StartInterval: integer;
begin
  Randomize;
  ControlStyle := [csOpaque];
  Refresh;

  if SpielFeld <> nil then begin
    SpielFeld.StoppeRenderSchleife();
    FreeAndNil(SpielFeld);
  end;

  if AIRestarter <> nil then begin
    AIRestarter.Enabled := false;
    FreeAndNil(AIRestarter);
  end;

  if Breite = 0 then Breite := 29;
  if Hoehe = 0 then Hoehe := 29;

  SpielFeld := TRasterFeld.Erstelle(29, Breite, Hoehe, Self);
  SpielFeld.Mitte := false;
  SpielFeld.FormAnFeldAnpassen();

  if Snake <> nil then FreeAndNil(Snake);
  Snake := TSnake.Erstelle(SpielFeld.FeldBreite div 2, SpielFeld.FeldHoehe div 2, SpielFeld);
  if Essen <> nil then FreeAndNil(Essen);
  Essen := TEssen.Erstelle(3, 3, SpielFeld);

  Punkte := 0;
  Rendern := true;
  Laden := true;
  Neustarten := false;

  BSpielStarten.Visible := false;
  LErklaerung.Visible := false;

  if AI then StartInterval := 50
  else StartInterval := 300;

  SpielFeld.StarteSpielSchleife(StartInterval, @SpielSchleife);
  SpielFeld.StarteRenderSchleife();
end;


// 0: oben, 1: unten, 2: links, 3: rechts
var Richtung: integer;


procedure TForm1.SpielSchleife(Sender: TObject);
begin
  Laden := false;
  HandleResize := true;

  if (Snake.Kopf.X = Essen.X) and (Snake.Kopf.Y = Essen.Y) then begin
    Essen.Einsammeln(Snake);
    if SpielFeld.Interval > 170 then SpielFeld.Interval := SpielFeld.Interval - 10
    else if SpielFeld.Interval > 50 then SpielFeld.Interval := SpielFeld.Interval - 3
    else if SpielFeld.Interval > 10 then SpielFeld.Interval := SpielFeld.Interval - 1;
    inc(Punkte);
  end;

  if not AI then begin
    case Richtung of
      0: Snake.HochBewegen();
      1: Snake.RunterBewegen();
      2: Snake.LinksBewegen();
      3: Snake.RechtsBewegen();
    end;
  end else Snake.AI(Essen.X, Essen.Y);


  if (Snake.Fehler) or (Neustarten) then begin
    SpielFeld.StoppeSpielSchleife();

    BSpielStarten.Caption := 'Spiel neustarten';
    BSpielStarten.Left := (Width div 2) - (BSpielStarten.Width div 2);
    BSpielStarten.Top := (Height div 2) + 35;
    BSpielStarten.Visible := true;

    if AI then begin
       AIRestarter := TTimer.Create(Self);
       AIRestarter.Interval := 4000;
       AIRestarter.OnTimer := @RestarteAI;
    end;
  end;


end;



procedure TForm1.RestarteAI(Sender: TObject);
begin
  AIRestarter.Enabled := False;
  FreeAndNil(AIRestarter);
  BSpielStartenClick(nil);
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: char);
begin
  case Key of
    'w': Richtung := 0;
    's': Richtung := 1;
    'a': Richtung := 2;
    'd': Richtung := 3;
  end;

  if SpielFeld = nil then Exit;

  case Key of
    'i': SpielFeld.Interval := SpielFeld.Interval - 1;
    'k': SpielFeld.Interval := SpielFeld.Interval + 1;
    'r': Neustarten := true;
  end;

  if Snake = nil then Exit;

  case Key of
    'o': Snake.Wachsen();
    'm': AI := not AI;
  end;
end;



procedure TForm1.FormPaint(Sender: TObject);
begin
  if not Rendern then Exit;

  if Laden then begin
    SpielFeld.Loeschen();
    RenderStats();
    Exit;
  end;

  SpielFeld.Loeschen();
  if not (Snake.Fehler) or (Neustarten) then Essen.Rendern();
  Snake.Rendern();

  if (Snake.Fehler) or (Neustarten) then begin

    Canvas.Font.Height := 50;
    Canvas.Brush.Color := clBlack;
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut((Width div 2) - (Canvas.TextWidth('Game Over') div 2), (Height div 2) - 25, 'Game Over');

  end;

  RenderStats();
end;



procedure TForm1.RenderStats();
var Geschwindigkeit: real;
begin
  with Canvas.Font do begin
    Name := 'Arial';
    Color := clWhite;
    Height := 20;
  end;

  if SpielFeld = nil then Geschwindigkeit := 0.0
  else Geschwindigkeit := (1000 /  SpielFeld.Interval);

  Canvas.Brush.Style := bsClear;
  Canvas.TextOut(10, 10, 'Punkte: ' + IntToStr(Punkte));
  Canvas.TextOut(100, 10, 'Geschwindigkeit: ' + FloatToStrF(Geschwindigkeit, ffNumber, 8, 2) + ' Raster/Sekunde');;

end;



procedure TForm1.FormResize(Sender: TObject);
begin
  if not HandleResize then Exit;

  SpielFeld.FeldBreite := Width div SpielFeld.RasterGroesse;
  SpielFeld.FeldHoehe := Height div SpielFeld.RasterGroesse;

  Breite := SpielFeld.FeldBreite;
  Hoehe := SpielFeld.FeldHoehe;

  SpielFeld.FormAnFeldAnpassen();

  BSpielStarten.Left := (Width div 2) - (BSpielStarten.Width div 2);
  BSpielStarten.Top := (Height div 2) + 35;
end;



procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  Rendern := false;
  if SpielFeld <> nil then begin
     SpielFeld.StoppeRenderSchleife();
     SpielFeld.StoppeSpielSchleife();
     FreeAndNil(SpielFeld);
  end;
  if Snake <> nil then FreeAndNil(Snake);
  if Essen <> nil then FreeAndNil(Essen);
end;





end.

