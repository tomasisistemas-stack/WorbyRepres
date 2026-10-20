unit unVisitaHistoricoMapa;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math, System.DateUtils,
  System.IOUtils, Data.DB, FireDAC.Comp.Client, FireDAC.Comp.DataSet, FireDAC.Stan.Param,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.WebBrowser;

type
  TfrmVisitaHistoricoMapa = class(TForm)
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
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnVoltarClick(Sender: TObject);
    procedure BtnAtualizarClick(Sender: TObject);
    procedure TimerAtualizacaoTimer(Sender: TObject);
  private
    FPeriodo: string;
    FAtualizando: Boolean;
    FMapaAtivo: Boolean;
    procedure ApplyLayout;
    function FloatJs(AValue: Double): string;
    function FileUrl(const AFileName: string): string;
    procedure AbrirHtmlMapa(const AHtml: string);
  public
    procedure CarregarRastreamento(const APeriodo: string);
  end;

var
  frmVisitaHistoricoMapa: TfrmVisitaHistoricoMapa;

implementation

{$R *.fmx}

uses
  unDMApp, unFuncoes
  {$IFDEF ANDROID}
  , Androidapi.Helpers, Androidapi.JNI.JavaTypes, Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNIBridge
  {$ENDIF};

function LerConsultaMapa(AQuery: TFDQuery): TFDMemTable;
{$IFDEF ANDROID}
var
  LDb: JSQLiteDatabase;
  LCursor: JCursor;
  LArgs: TJavaObjectArray<JString>;
  I: Integer;
  LName: string;
{$ENDIF}
begin
  Result := TFDMemTable.Create(nil);
  try
    {$IFDEF ANDROID}
    // Usa o mesmo motor SQLite do servico, sem cache do FireDAC.
    LDb := TJSQLiteDatabase.JavaClass.openDatabase(
      StringToJString(AQuery.Connection.Params.Values['Database']), nil,
      TJSQLiteDatabase.JavaClass.OPEN_READONLY);
    try
      LArgs := TJavaObjectArray<JString>.Create(AQuery.Params.Count);
      try
        for I := 0 to AQuery.Params.Count - 1 do
          LArgs.Items[I] := StringToJString(AQuery.Params[I].AsString);
        LCursor := LDb.rawQuery(StringToJString(AQuery.SQL.Text), LArgs);
        try
          for I := 0 to LCursor.getColumnCount - 1 do
          begin
            LName := JStringToString(LCursor.getColumnName(I));
            if SameText(LName, 'latitude') or SameText(LName, 'longitude') then
              Result.FieldDefs.Add(LName, ftFloat)
            else
              Result.FieldDefs.Add(LName, ftWideString, 255);
          end;
          Result.CreateDataSet;
          while LCursor.moveToNext do
          begin
            Result.Append;
            for I := 0 to LCursor.getColumnCount - 1 do
              if not LCursor.isNull(I) then
                if Result.Fields[I].DataType = ftFloat then
                  Result.Fields[I].AsFloat := LCursor.getDouble(I)
                else
                  Result.Fields[I].AsString := JStringToString(LCursor.getString(I));
            Result.Post;
          end;
          Result.First;
        finally
          LCursor.close;
        end;
      finally
        LArgs.Free;
      end;
    finally
      LDb.close;
    end;
    {$ELSE}
    AQuery.Open;
    Result.CopyDataSet(AQuery, [coStructure, coRestart, coAppend]);
    Result.First;
    {$ENDIF}
  except
    Result.Free;
    raise;
  end;
end;

function TfrmVisitaHistoricoMapa.FloatJs(AValue: Double): string;
var
  LFormat: TFormatSettings;
begin
  LFormat := TFormatSettings.Create;
  LFormat.DecimalSeparator := '.';
  Result := FormatFloat('0.########', AValue, LFormat);
end;

function TfrmVisitaHistoricoMapa.FileUrl(const AFileName: string): string;
begin
  Result := 'file:///' + StringReplace(AFileName, '\', '/', [rfReplaceAll]);
end;

procedure TfrmVisitaHistoricoMapa.AbrirHtmlMapa(const AHtml: string);
var
  LFileName: string;
begin
  LFileName := System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetDocumentsPath,
    'worby_visitas_historico_mapa_' + FormatDateTime('yyyymmddhhnnsszzz', Now) + '.html');
  TFile.WriteAllText(LFileName, AHtml, TEncoding.UTF8);
  try WebMapa.Navigate('about:blank'); except end;
  WebMapa.Navigate(FileUrl(LFileName));
end;

procedure TfrmVisitaHistoricoMapa.ApplyLayout;
var
  LLandscape: Boolean;
  LSafe: Single;
  LTop: Single;
  LBottom: Single;
begin
  if (Width <= 0) or (Height <= 0) then Exit;
  LLandscape := Width > Height;
  LSafe := AndroidBottomSafeMargin(LLandscape);
  LTop := IfThen(LLandscape, 86, 112);
  LBottom := IfThen(LLandscape, 52, 70);
  TopBar.SetBounds(0, 0, Width, LTop);
  LbTitulo.SetBounds(24, IfThen(LLandscape, 12, 30), Width - 48, 34);
  LbSubtitulo.SetBounds(26, LbTitulo.Position.Y + 36, Width - 52, 40);
  LbSubtitulo.TextSettings.Font.Size := 12;
  BottomBar.SetBounds(0, Height - LBottom - LSafe, Width, LBottom);
  BtnVoltar.SetBounds(18, IfThen(LLandscape, 6, 12), 128, 42);
  BtnAtualizar.SetBounds(Max(164, Width - 152), IfThen(LLandscape, 6, 12), 134, 42);
  WebMapa.SetBounds(0, TopBar.Height, Width, Max(120, BottomBar.Position.Y - TopBar.Height));
end;

procedure TfrmVisitaHistoricoMapa.CarregarRastreamento(const APeriodo: string);
var
  Q: TFDQuery;
  LConnection: TFDConnection;
  QAtual: TFDQuery;
  LRows: TFDMemTable;
  LCurrentRows: TFDMemTable;
  LRep: Integer;
  LAno: Integer;
  LMes: Integer;
  LInicio: TDateTime;
  LFim: TDateTime;
  LPoints: TStringBuilder;
  LHtml: TStringBuilder;
  LLat: Double;
  LLon: Double;
  LDataHora: string;
  LCount: Integer;
  LAtualLatitude: Double;
  LAtualLongitude: Double;
  LAtualDataHora: string;
  LTemLocalizacaoAtual: Boolean;
  LPeriodoDia: Boolean;
begin
  if FAtualizando then
    Exit;
  FAtualizando := True;
  FPeriodo := APeriodo;
  TimerAtualizacao.Enabled := False;
  LConnection := nil;
  Q := nil;
  LRows := nil;
  LPoints := nil;
  LHtml := nil;
  try
  LPeriodoDia := (Length(APeriodo) >= 10) and (Copy(APeriodo, 3, 1) = '/');
  if LPeriodoDia then
  begin
    LMes := StrToIntDef(Copy(APeriodo, 4, 2), MonthOf(Date));
    LAno := StrToIntDef(Copy(APeriodo, 7, 4), YearOf(Date));
    if (LMes < 1) or (LMes > 12) then LMes := MonthOf(Date);
    if LAno < 2000 then LAno := YearOf(Date);
    LInicio := EncodeDate(LAno, LMes, StrToIntDef(Copy(APeriodo, 1, 2), DayOf(Date)));
    LFim := IncDay(LInicio);
  end
  else
  begin
    LMes := StrToIntDef(Copy(APeriodo, 1, 2), MonthOf(Date));
    LAno := StrToIntDef(Copy(APeriodo, 4, 4), YearOf(Date));
    if (LMes < 1) or (LMes > 12) then LMes := MonthOf(Date);
    if LAno < 2000 then LAno := YearOf(Date);
    LInicio := EncodeDate(LAno, LMes, 1);
    LFim := IncMonth(LInicio);
  end;
  LPoints := TStringBuilder.Create;
  LHtml := TStringBuilder.Create;
  Q := TFDQuery.Create(nil);
    // Uma conexao nova evita reutilizar uma leitura anterior do banco.
    LConnection := TFDConnection.Create(nil);
    LConnection.Params.Assign(dmApp.FDConnection.Params);
    LConnection.Params.Values['OpenMode'] := 'ReadOnly';
    LConnection.LoginPrompt := False;
    {$IFNDEF ANDROID}
    LConnection.Connected := True;
    {$ENDIF}
    Q.Connection := LConnection;
    Q.SQL.Text := 'select coalesce(value, '''') from app_config where key = ''cod_representante''';
    LRows := LerConsultaMapa(Q);
    LRep := 0;
    if not LRows.Eof then
      LRep := StrToIntDef(LRows.Fields[0].AsString, 0);
    FreeAndNil(LRows);
    Q.Close;
    Q.Unprepare;
    if LRep <= 0 then Exit;
    if LPeriodoDia then
      Q.SQL.Text :=
        'select datahora, latitude, longitude from representante_localizacao ' +
        'where cod_representante = :rep and latitude <> 0 and longitude <> 0 ' +
        'and precisao_m > 0 and precisao_m <= 20 ' +
        'and (substr(datahora, 1, 10) = :data_iso or ' +
        'substr(datahora, 7, 4) || ''-'' || substr(datahora, 4, 2) || ''-'' || substr(datahora, 1, 2) = :data_iso) ' +
        'order by case when substr(datahora, 5, 1) = ''-'' then datahora ' +
        'else substr(datahora, 7, 4) || ''-'' || substr(datahora, 4, 2) || ''-'' || substr(datahora, 1, 2) || substr(datahora, 11) end, id'
    else
      Q.SQL.Text :=
        'select datahora, latitude, longitude from representante_localizacao ' +
        'where cod_representante = :rep and latitude <> 0 and longitude <> 0 ' +
        'and precisao_m > 0 and precisao_m <= 20 ' +
        'and (substr(datahora, 1, 7) = :mes_iso or substr(datahora, 4, 7) = :mes_br) ' +
        'order by case when substr(datahora, 5, 1) = ''-'' then datahora ' +
        'else substr(datahora, 7, 4) || ''-'' || substr(datahora, 4, 2) || ''-'' || substr(datahora, 1, 2) || substr(datahora, 11) end, id';
    Q.ParamByName('rep').AsInteger := LRep;
    if LPeriodoDia then
      Q.ParamByName('data_iso').AsString := FormatDateTime('yyyy-mm-dd', LInicio)
    else
    begin
      Q.ParamByName('mes_iso').AsString := FormatDateTime('yyyy-mm', LInicio);
      Q.ParamByName('mes_br').AsString := FormatDateTime('mm/yyyy', LInicio);
    end;
    LRows := LerConsultaMapa(Q);
    LCount := 0;
    while not LRows.Eof do
    begin
      LLat := LRows.FieldByName('latitude').AsFloat;
      LLon := LRows.FieldByName('longitude').AsFloat;
      LDataHora := StringReplace(LRows.FieldByName('datahora').AsString, '"', '', [rfReplaceAll]);
      if LPoints.Length > 0 then LPoints.AppendLine(',');
      LPoints.Append('  {lat:').Append(FloatJs(LLat)).
        Append(',lon:').Append(FloatJs(LLon)).
        Append(',hora:"').Append(LDataHora).Append('"}');
      Inc(LCount);
      LRows.Next;
    end;

    QAtual := TFDQuery.Create(nil);
    LCurrentRows := nil;
    try
      QAtual.Connection := LConnection;
      QAtual.SQL.Text :=
        'select datahora, latitude, longitude from representante_localizacao ' +
        'where cod_representante = :rep and latitude <> 0 and longitude <> 0 ' +
        'and precisao_m > 0 and precisao_m <= 20 ' +
        'order by id desc limit 1';
      QAtual.ParamByName('rep').AsInteger := LRep;
      LCurrentRows := LerConsultaMapa(QAtual);
      LAtualLatitude := 0;
      LAtualLongitude := 0;
      LAtualDataHora := '';
      LTemLocalizacaoAtual := not LCurrentRows.Eof;
      if LTemLocalizacaoAtual then
      begin
        LAtualLatitude := LCurrentRows.FieldByName('latitude').AsFloat;
        LAtualLongitude := LCurrentRows.FieldByName('longitude').AsFloat;
        LAtualDataHora := LCurrentRows.FieldByName('datahora').AsString;
        LTemLocalizacaoAtual := (LAtualLatitude <> 0) and (LAtualLongitude <> 0);
      end;
    finally
      LCurrentRows.Free;
      QAtual.Free;
    end;

        LHtml.AppendLine('<!doctype html><html><head><meta charset="utf-8">');
    LHtml.AppendLine('<meta name="viewport" content="width=device-width,initial-scale=1">');
    LHtml.AppendLine('<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">');
    LHtml.AppendLine('<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>');
    LHtml.AppendLine('<style>html,body,#map{height:100%;margin:0}.leaflet-popup-content{font:14px Arial}</style>');
    LHtml.AppendLine('</head><body><div id="map"></div><script>');
    LHtml.AppendLine('var pontos=[' + LPoints.ToString + '];');
    if LTemLocalizacaoAtual then
      LHtml.AppendLine('var atual={lat:' + FloatJs(LAtualLatitude) + ',lon:' + FloatJs(LAtualLongitude) + '};')
    else
      LHtml.AppendLine('var atual=null;');
    LHtml.AppendLine('var map=L.map("map").setView([0,0],2);');
    LHtml.AppendLine('L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",{maxZoom:19,attribution:"&copy; OpenStreetMap"}).addTo(map);');
    LHtml.AppendLine('if(atual){L.circleMarker([atual.lat,atual.lon],{radius:10,color:"#fff",weight:3,fillColor:"#1685d8",fillOpacity:1}).addTo(map).bindPopup("Localizacao atual");}');
    LHtml.AppendLine('if(pontos.length){var linha=pontos.map(function(p){return [p.lat,p.lon]});');
    LHtml.AppendLine('L.polyline(linha,{color:"#1685d8",weight:5,opacity:.9}).addTo(map);');
    LHtml.AppendLine('L.circleMarker(linha[0],{radius:9,color:"#fff",weight:3,fillColor:"#16a05d",fillOpacity:1}).addTo(map).bindPopup("Inicio");');
    LHtml.AppendLine('L.circleMarker(linha[linha.length-1],{radius:9,color:"#fff",weight:3,fillColor:"#e53935",fillOpacity:1}).addTo(map).bindPopup("Ultima localizacao");');
    LHtml.AppendLine('linha.forEach(function(p,i){if(i>0&&i<linha.length-1&&i%10==0)L.circleMarker(p,{radius:4,color:"#1685d8",fillColor:"#1685d8",fillOpacity:1}).addTo(map);});');
    LHtml.AppendLine('var enquadramento=linha.slice();if(atual)enquadramento.push([atual.lat,atual.lon]);map.fitBounds(enquadramento,{padding:[30,30]});}else if(atual){map.setView([atual.lat,atual.lon],15);}else{map.setView([-15.78,-47.93],4);}');
    LHtml.AppendLine('</script></body></html>');
    if LTemLocalizacaoAtual then
      LbSubtitulo.Text := 'Atualizado ' + FormatDateTime('hh:nn:ss', Now) +
        sLineBreak + 'GPS: ' + LAtualDataHora + ' | ' + IntToStr(LCount) + ' pontos'
    else
      LbSubtitulo.Text := 'Atualizado ' + FormatDateTime('hh:nn:ss', Now) +
        sLineBreak + 'Aguardando GPS com precisao de ate 20 m';
    AbrirHtmlMapa(LHtml.ToString);
  finally
    LRows.Free;
    Q.Free;
    LConnection.Free;
    LPoints.Free;
    LHtml.Free;
    FAtualizando := False;
    TimerAtualizacao.Enabled := FMapaAtivo and (FPeriodo <> '');
  end;
end;

procedure TfrmVisitaHistoricoMapa.FormShow(Sender: TObject);
begin
  FMapaAtivo := True;
  ApplyLayout;
  TimerAtualizacao.Enabled := FPeriodo <> '';
  if FPeriodo <> '' then CarregarRastreamento(FPeriodo);
end;

procedure TfrmVisitaHistoricoMapa.FormResize(Sender: TObject);
begin
  ApplyLayout;
end;

procedure TfrmVisitaHistoricoMapa.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FMapaAtivo := False;
  TimerAtualizacao.Enabled := False;
  try WebMapa.Navigate('about:blank'); except end;
  Action := TCloseAction.caFree;
  frmVisitaHistoricoMapa := nil;
end;

procedure TfrmVisitaHistoricoMapa.BtnVoltarClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmVisitaHistoricoMapa.BtnAtualizarClick(Sender: TObject);
begin
  if FPeriodo <> '' then CarregarRastreamento(FPeriodo);
end;

procedure TfrmVisitaHistoricoMapa.TimerAtualizacaoTimer(Sender: TObject);
begin
  if FMapaAtivo and (FPeriodo <> '') and (not FAtualizando) then
    try
      CarregarRastreamento(FPeriodo);
    except
      on E: Exception do
        LbSubtitulo.Text := 'Falha ao atualizar: ' + E.Message;
    end;
end;

end.
