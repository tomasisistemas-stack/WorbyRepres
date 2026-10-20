unit unVisitasMapa;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math,
  System.IOUtils, System.Generics.Collections,
  Data.DB, FireDAC.Comp.Client,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.WebBrowser;

type
  TfrmVisitasMapa = class(TForm)
    LayoutRoot: TLayout;
    BackgroundRect: TRectangle;
    TopBar: TRectangle;
    LbTitulo: TLabel;
    LbSubtitulo: TLabel;
    WebMapa: TWebBrowser;
    BottomBar: TLayout;
    BtnVoltar: TRectangle;
    LbVoltar: TLabel;
    BtnAtualizar: TRectangle;
    LbAtualizar: TLabel;
    TimerAtualizacao: TTimer;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BtnVoltarClick(Sender: TObject);
    procedure BtnAtualizarClick(Sender: TObject);
    procedure TimerAtualizacaoTimer(Sender: TObject);
  private
    FUltimoHtml: string;
    FUltimaLatitude: Double;
    FUltimaLongitude: Double;
    procedure ApplyLayout;
    function DistanciaMetros(ALat1, ALon1, ALat2, ALon2: Double): Double;
    function FloatJs(AValue: Double): string;
    function HtmlEscape(const AValue: string): string;
    function JsEscape(const AValue: string): string;
    function FileUrl(const AFileName: string): string;
    function ObterUltimaLocalizacao(var ALatitude, ALongitude: Double): Boolean;
    procedure AbrirHtmlMapa(const AHtml: string);
  public
    procedure CarregarClientesProximos(ARepLat, ARepLon: Double);
  end;

var
  frmVisitasMapa: TfrmVisitasMapa;

implementation

{$R *.fmx}

uses
  unDMApp, unFuncoes;

procedure TfrmVisitasMapa.ApplyLayout;
var
  LIsLandscape: Boolean;
  LBottomSafe: Single;
  LTopHeight: Single;
  LBottomHeight: Single;
begin
  if (Width <= 0) or (Height <= 0) then
    Exit;

  LIsLandscape := Width > Height;
  LBottomSafe := AndroidBottomSafeMargin(LIsLandscape);
  LTopHeight := IfThen(LIsLandscape, 62, 96);
  LBottomHeight := IfThen(LIsLandscape, 52, 70);

  TopBar.Align := TAlignLayout.None;
  TopBar.SetBounds(0, 0, Width, LTopHeight);
  LbTitulo.SetBounds(24, IfThen(LIsLandscape, 12, 30), Width - 48, 34);
  LbSubtitulo.SetBounds(26, LbTitulo.Position.Y + 31, Width - 52, 20);

  BottomBar.Align := TAlignLayout.None;
  BottomBar.SetBounds(0, Height - LBottomHeight - LBottomSafe, Width, LBottomHeight);
  BtnVoltar.SetBounds(18, IfThen(LIsLandscape, 6, 12), 128, 42);
  BtnAtualizar.SetBounds(Max(164, Width - 152), IfThen(LIsLandscape, 6, 12), 134, 42);

  WebMapa.Align := TAlignLayout.None;
  WebMapa.SetBounds(0, TopBar.Height, Width, Max(120, BottomBar.Position.Y - TopBar.Height));
end;

function TfrmVisitasMapa.DistanciaMetros(ALat1, ALon1, ALat2, ALon2: Double): Double;
const
  CEarthRadiusMeters = 6371000.0;
var
  LDLat: Double;
  LDLon: Double;
  LA: Double;
  LC: Double;
begin
  LDLat := DegToRad(ALat2 - ALat1);
  LDLon := DegToRad(ALon2 - ALon1);
  LA := Sin(LDLat / 2) * Sin(LDLat / 2) +
    Cos(DegToRad(ALat1)) * Cos(DegToRad(ALat2)) *
    Sin(LDLon / 2) * Sin(LDLon / 2);
  LC := 2 * ArcTan2(Sqrt(LA), Sqrt(1 - LA));
  Result := CEarthRadiusMeters * LC;
end;

function TfrmVisitasMapa.FloatJs(AValue: Double): string;
var
  LFormat: TFormatSettings;
begin
  LFormat := TFormatSettings.Create;
  LFormat.DecimalSeparator := '.';
  Result := FormatFloat('0.########', AValue, LFormat);
end;

function TfrmVisitasMapa.HtmlEscape(const AValue: string): string;
begin
  Result := StringReplace(AValue, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
end;

function TfrmVisitasMapa.JsEscape(const AValue: string): string;
begin
  Result := StringReplace(AValue, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&#39;', [rfReplaceAll]);
  Result := StringReplace(Result, #13#10, ' ', [rfReplaceAll]);
  Result := StringReplace(Result, #10, ' ', [rfReplaceAll]);
  Result := StringReplace(Result, #13, ' ', [rfReplaceAll]);
end;

function TfrmVisitasMapa.FileUrl(const AFileName: string): string;
begin
  Result := 'file:///' + StringReplace(AFileName, '\', '/', [rfReplaceAll]);
end;

procedure TfrmVisitasMapa.AbrirHtmlMapa(const AHtml: string);
var
  LFileName: string;
begin
  FUltimoHtml := AHtml;
  LFileName := System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetDocumentsPath,
    'worby_visitas_mapa_' + FormatDateTime('yyyymmddhhnnsszzz', Now) + '.html');
  System.IOUtils.TFile.WriteAllText(LFileName, AHtml, TEncoding.UTF8);
  WebMapa.Navigate(FileUrl(LFileName));
end;

function TfrmVisitasMapa.ObterUltimaLocalizacao(var ALatitude, ALongitude: Double): Boolean;
var
  Q: TFDQuery;
begin
  Result := False;
  ALatitude := 0;
  ALongitude := 0;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text :=
      'select latitude, longitude ' +
      '  from representante_localizacao ' +
      ' where latitude is not null and longitude is not null ' +
      '   and latitude <> 0 and longitude <> 0 ' +
      ' order by id desc limit 1';
    Q.Open;
    if not Q.Eof then
    begin
      ALatitude := Q.FieldByName('latitude').AsFloat;
      ALongitude := Q.FieldByName('longitude').AsFloat;
      Result := (ALatitude <> 0) and (ALongitude <> 0);
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmVisitasMapa.CarregarClientesProximos(ARepLat, ARepLon: Double);
var
  Q: TFDQuery;
  LLat: Double;
  LLon: Double;
  LNome: string;
  LDist: Double;
  LDistTexto: string;
  LCor: string;
  LMarkers: TStringBuilder;
  LHtml: TStringBuilder;
begin
  if (ARepLat = 0) and (ARepLon = 0) then
    Exit;

  FUltimaLatitude := ARepLat;
  FUltimaLongitude := ARepLon;

  LMarkers := TStringBuilder.Create;
  LHtml := TStringBuilder.Create;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text :=
      'select c.cod_cliente, c.nom_cliente, coalesce(c.nom_fantasia, '''') as nom_fantasia, ' +
      '       coalesce(cd.nom_cidade, '''') || case when coalesce(cd.uf, '''') <> '''' then ''-'' || cd.uf else '''' end as cidade_desc, ' +
      '       c.latitude, c.longitude ' +
      '  from cliente c ' +
      '  left join cidades cd on cd.cod_cidade = c.cod_cidade ' +
      ' where coalesce(c.status, '''') <> ''I'' ' +
      '   and c.latitude is not null and c.longitude is not null ' +
      '   and c.latitude <> 0 and c.longitude <> 0 ' +
      ' order by ((c.latitude - :latref) * (c.latitude - :latref)) + ((c.longitude - :lonref) * (c.longitude - :lonref)) ' +
      ' limit 100';
    Q.ParamByName('latref').AsFloat := ARepLat;
    Q.ParamByName('lonref').AsFloat := ARepLon;
    Q.Open;

    while not Q.Eof do
    begin
      LLat := Q.FieldByName('latitude').AsFloat;
      LLon := Q.FieldByName('longitude').AsFloat;
      LDist := DistanciaMetros(ARepLat, ARepLon, LLat, LLon);
      if LDist < 1000 then
        LDistTexto := FormatFloat('0', LDist) + ' m'
      else
        LDistTexto := FormatFloat('0.0', LDist / 1000) + ' km';
      if LDist < 100 then
        LCor := '#006B3C'
      else
        LCor := '#D32F2F';

      LNome := HtmlEscape(Q.FieldByName('cod_cliente').AsString + ' - ' + Q.FieldByName('nom_cliente').AsString);
      if Trim(Q.FieldByName('nom_fantasia').AsString) <> '' then
        LNome := LNome + '<br>' + HtmlEscape(Q.FieldByName('nom_fantasia').AsString);
      LNome := LNome + '<br>' + HtmlEscape(Q.FieldByName('cidade_desc').AsString + ' | GPS: ' + LDistTexto);

      if LMarkers.Length > 0 then
        LMarkers.AppendLine(',');
      LMarkers.Append('  {lat: ').Append(FloatJs(LLat)).
        Append(', lon: ').Append(FloatJs(LLon)).
        Append(', color: ''').Append(LCor).Append('''').
        Append(', title: ''').Append(JsEscape(LNome)).Append('''}');
      Q.Next;
    end;

    LHtml.AppendLine('<!doctype html>');
    LHtml.AppendLine('<html><head><meta charset="utf-8">');
    LHtml.AppendLine('<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">');
    LHtml.AppendLine('<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">');
    LHtml.AppendLine('<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>');
    LHtml.AppendLine('<style>html,body,#map{height:100%;margin:0} .leaflet-popup-content{font:14px Arial,sans-serif;line-height:1.35} .pin-wrap{background:transparent;border:0} .pin{width:25px;height:25px;border:2px solid #fff;border-radius:50% 50% 50% 0;box-shadow:0 2px 5px rgba(0,0,0,.55);transform:rotate(-45deg);position:relative} .pin span{position:absolute;width:9px;height:9px;left:6px;top:6px;border-radius:50%;background:#fff;opacity:.9} .rep-dot-wrap{background:transparent;border:0} .rep-dot{width:22px;height:22px;background:#1685d8;border:4px solid #fff;border-radius:50%;box-shadow:0 2px 6px rgba(0,0,0,.6)}</style>');
    LHtml.AppendLine('</head><body><div id="map"></div><script>');
    LHtml.Append('var repLat=').Append(FloatJs(ARepLat)).Append('; var repLon=').Append(FloatJs(ARepLon)).AppendLine(';');
    LHtml.AppendLine('var map=L.map("map").setView([repLat,repLon],15);');
    LHtml.AppendLine('L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",{maxZoom:19,attribution:"&copy; OpenStreetMap"}).addTo(map);');
    LHtml.AppendLine('var repIcon=L.divIcon({className:"rep-dot-wrap",html:"<div class=''rep-dot''></div>",iconSize:[30,30],iconAnchor:[15,15]});');
    LHtml.AppendLine('L.marker([repLat,repLon],{icon:repIcon}).addTo(map).bindPopup("Sua localizacao");');
    LHtml.AppendLine('var clientes=[');
    LHtml.Append(LMarkers.ToString);
    LHtml.AppendLine('];');
    LHtml.AppendLine('var boundsFoco=L.latLngBounds([[repLat,repLon]]);');
    LHtml.AppendLine('clientes.forEach(function(c){');
    LHtml.AppendLine('  L.marker([c.lat,c.lon],{icon:L.divIcon({className:''pin-wrap'',html:''<div class="pin" style="background:''+c.color+''"><span></span></div>'',iconSize:[29,36],iconAnchor:[14,36],popupAnchor:[0,-32]})}).addTo(map).bindPopup(c.title);');
    LHtml.AppendLine('});');
    LHtml.AppendLine('clientes.slice(0,5).forEach(function(c){ boundsFoco.extend([c.lat,c.lon]); });');
    LHtml.AppendLine('if(clientes.length>0){ map.fitBounds(boundsFoco,{padding:[36,36],maxZoom:17}); }');
    LHtml.AppendLine('</script></body></html>');

    AbrirHtmlMapa(LHtml.ToString);
  finally
    Q.Free;
    LHtml.Free;
    LMarkers.Free;
  end;
end;

procedure TfrmVisitasMapa.TimerAtualizacaoTimer(Sender: TObject);
begin
  if (not Visible) or (csDestroying in ComponentState) then
    Exit;
  BtnAtualizarClick(Sender);
end;
procedure TfrmVisitasMapa.FormShow(Sender: TObject);
begin
  ApplyLayout;
  TimerAtualizacao.Enabled := True;
  if FUltimoHtml <> '' then
    AbrirHtmlMapa(FUltimoHtml);
end;

procedure TfrmVisitasMapa.FormResize(Sender: TObject);
begin
  ApplyLayout;
end;

procedure TfrmVisitasMapa.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  TimerAtualizacao.Enabled := False;
  try
    WebMapa.Navigate('about:blank');
  except
  end;
  FUltimoHtml := '';
  Action := TCloseAction.caFree;
  frmVisitasMapa := nil;
end;

procedure TfrmVisitasMapa.BtnVoltarClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmVisitasMapa.BtnAtualizarClick(Sender: TObject);
var
  LLat: Double;
  LLon: Double;
begin
  if ObterUltimaLocalizacao(LLat, LLon) then
  begin
    CarregarClientesProximos(LLat, LLon);
    Exit;
  end;

  if (FUltimaLatitude <> 0) or (FUltimaLongitude <> 0) then
    CarregarClientesProximos(FUltimaLatitude, FUltimaLongitude);
end;

end.
