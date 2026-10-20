unit unVisitas;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.DateUtils, System.Math, System.Sensors, System.Sensors.Components,
  System.Permissions,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.ListView,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.ListBox, Data.DB, FireDAC.Comp.Client;

type
  TfrmVisitas = class(TForm)
    LayoutRoot: TLayout;
    BackgroundRect: TRectangle;
    TopBar: TRectangle;
    LbTitulo: TLabel;
    LbSubtitulo: TLabel;
    CardBusca: TRectangle;
    LbBuscar: TLabel;
    EdBuscar: TEdit;
    LbModoBusca: TLabel;
    CbModoBusca: TComboBox;
    LbPeriodo: TLabel;
    CbPeriodo: TComboBox;
    LbStatus: TLabel;
    CbStatus: TComboBox;
    BtnBuscar: TImage;
    CardProximo: TRectangle;
    LbProximoTitulo: TLabel;
    LbProximoValor: TLabel;
    LbProximoSub: TLabel;
    CardAVisitar: TRectangle;
    LbAVisitarTitulo: TLabel;
    LbAVisitarValor: TLabel;
    LbAVisitarSub: TLabel;
    CardRealizadas: TRectangle;
    LbRealizadasTitulo: TLabel;
    LbRealizadasValor: TLabel;
    LbRealizadasSub: TLabel;
    CardComVenda: TRectangle;
    LbComVendaTitulo: TLabel;
    LbComVendaValor: TLabel;
    LbComVendaSub: TLabel;
    CardSemVenda: TRectangle;
    LbSemVendaTitulo: TLabel;
    LbSemVendaValor: TLabel;
    LbSemVendaSub: TLabel;
    CardLista: TRectangle;
    LbListaTitulo: TLabel;
    LvRoteiro: TListView;
    lbottom: TLayout;
    LyVoltar: TLayout;
    ImgVoltar: TImage;
    LyCheckin: TLayout;
    BtnCheckin: TRectangle;
    LbCheckin: TLabel;
    LyHistorico: TLayout;
    BtnHistorico: TRectangle;
    LbHistorico: TLabel;
    LyMapa: TLayout;
    BtnMapa: TRectangle;
    LbMapa: TLabel;
    LyRota: TLayout;
    BtnRota: TRectangle;
    LbRota: TLabel;
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnBuscarClick(Sender: TObject);
    procedure BtnBuscarTap(Sender: TObject; const Point: TPointF);
    procedure ImgVoltarClick(Sender: TObject);
    procedure BtnCheckinClick(Sender: TObject);
    procedure BtnHistoricoClick(Sender: TObject);
    procedure BtnMapaClick(Sender: TObject);
    procedure BtnRotaClick(Sender: TObject);
    procedure LvRoteiroItemClick(const Sender: TObject; const AItem: TListViewItem);
  private
    FAtualizandoFiltros: Boolean;
    FClienteProximo: Integer;
    FDistanciaProximo: Double;
    FLocationSensor: TLocationSensor;
    FHasCurrentLocation: Boolean;
    FCurrentLatitude: Double;
    FCurrentLongitude: Double;
    FLastListLatitude: Double;
    FLastListLongitude: Double;
    FLastListTick: Cardinal;
    FLocationRefreshTimer: TTimer;
    FLocationPermissionRequested: Boolean;
    procedure PopularFiltros;
    procedure ApplyResponsiveLayout;
    procedure ListarRoteiro;
    procedure AtualizarTecladoBusca;
    procedure EnsureLocationSensor;
    procedure StartLocationSensor;
    procedure LocationSensorLocationChanged(Sender: TObject; const OldLocation, NewLocation: TLocationCoord2D);
    procedure LocationRefreshTimerTimer(Sender: TObject);
    procedure QueueLocationRefresh;
    {$IFDEF ANDROID}
    function HasLocationPermission: Boolean;
    procedure RequestLocationPermission;
    procedure LocationPermissionResult(Sender: TObject; const APermissions: TClassicStringDynArray; const AGrantResults: TClassicPermissionStatusDynArray);
    procedure LocationPermissionRationale(Sender: TObject; const APermissions: TClassicStringDynArray; const APostRationaleProc: TProc);
    {$ENDIF}
    function SafeFieldAsString(AQuery: TFDQuery; const ACampo: string): string;
    function SafeFieldAsFloat(AQuery: TFDQuery; const ACampo: string): Double;
    function ObterUltimaLocalizacao(var ALatitude, ALongitude: Double): Boolean;
    function DistanciaMetros(ALat1, ALon1, ALat2, ALon2: Double): Double;
    function TextoDistancia(ADistancia: Double): string;
    function TextoKmRodado(AKm: Double): string;
    function KmRodadoHoje: Double;
    function CodRepresentanteAtual: Integer;
    function PeriodoSqlFiltro: string;
    function TextoPeriodo: string;
  public
    procedure DesativarGpsLocal;
  end;

var
  frmVisitas: TfrmVisitas;

implementation

{$R *.fmx}

uses
  unDMApp, unFuncoes, unAndroidComboFix, unVisitaCheckin, unVisitaHistorico, unPrincipal
  {$IFDEF ANDROID}
  , Androidapi.Helpers, Androidapi.JNI.Os, Androidapi.JNI.JavaTypes,
  Androidapi.JNI.GraphicsContentViewText, Androidapi.JNI.Net, unVisitasMapa
  {$ENDIF};

function TfrmVisitas.SafeFieldAsString(AQuery: TFDQuery; const ACampo: string): string;
begin
  if Assigned(AQuery.FindField(ACampo)) then
    Result := AQuery.FieldByName(ACampo).AsString
  else
    Result := '';
end;

function TfrmVisitas.SafeFieldAsFloat(AQuery: TFDQuery; const ACampo: string): Double;
begin
  if Assigned(AQuery.FindField(ACampo)) then
    Result := AQuery.FieldByName(ACampo).AsFloat
  else
    Result := 0;
end;

function TfrmVisitas.DistanciaMetros(ALat1, ALon1, ALat2, ALon2: Double): Double;
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

function TfrmVisitas.TextoDistancia(ADistancia: Double): string;
begin
  if ADistancia = MaxDouble then
    Exit('Sem GPS');

  if ADistancia < 1000 then
    Result := FormatFloat('0', ADistancia) + ' m'
  else
    Result := FormatFloat('0.0', ADistancia / 1000) + ' km';
end;

function TfrmVisitas.TextoKmRodado(AKm: Double): string;
begin
  Result := FormatFloat('#,##0.0', AKm) + ' km';
end;

function TfrmVisitas.KmRodadoHoje: Double;
var
  Q: TFDQuery;
  LCodRep: Integer;
  LHasLast: Boolean;
  LLastLat: Double;
  LLastLon: Double;
  LLat: Double;
  LLon: Double;
  LDist: Double;
begin
  Result := 0;
  LHasLast := False;
  LLastLat := 0;
  LLastLon := 0;
  LCodRep := CodRepresentanteAtual;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    try
      Q.SQL.Text := 'select coalesce(km_rodado, 0) from representante_km_diario ' +
        'where cod_representante = :cod_rep and data = date(''now'', ''localtime'')';
      Q.ParamByName('cod_rep').AsInteger := LCodRep;
      Q.Open;
      if not Q.Eof then
      begin
        Result := Q.Fields[0].AsFloat;
        Exit;
      end;
    except
      // Bancos antigos ainda podem nao ter o resumo diario.
    end;
    Q.Close;
    Q.SQL.Text :=
      'select latitude, longitude from representante_localizacao ' +
      ' where date(datahora) = date(''now'', ''localtime'') ';
    if LCodRep > 0 then
      Q.SQL.Text := Q.SQL.Text + ' and cod_representante = :cod_rep ';
    Q.SQL.Text := Q.SQL.Text + ' order by datahora, id';
    if LCodRep > 0 then
      Q.ParamByName('cod_rep').AsInteger := LCodRep;
    Q.Open;

    while not Q.Eof do
    begin
      LLat := Q.FieldByName('latitude').AsFloat;
      LLon := Q.FieldByName('longitude').AsFloat;
      if (LLat <> 0) and (LLon <> 0) then
      begin
        if LHasLast then
        begin
          LDist := DistanciaMetros(LLastLat, LLastLon, LLat, LLon);
          if (LDist >= 5) and (LDist <= 100000) then
            Result := Result + (LDist / 1000);
        end;
        LLastLat := LLat;
        LLastLon := LLon;
        LHasLast := True;
      end;
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmVisitas.EnsureLocationSensor;
begin
  if not Assigned(FLocationRefreshTimer) then
  begin
    FLocationRefreshTimer := TTimer.Create(Self);
    FLocationRefreshTimer.Enabled := False;
    FLocationRefreshTimer.Interval := 10000;
    FLocationRefreshTimer.OnTimer := LocationRefreshTimerTimer;
  end;

  if not Assigned(FLocationSensor) then
  begin
    FLocationSensor := TLocationSensor.Create(Self);
    FLocationSensor.OnLocationChanged := LocationSensorLocationChanged;
  FLocationSensor.Distance := 1;
    FLocationSensor.Accuracy := 10;
  end;
end;

procedure TfrmVisitas.StartLocationSensor;
begin
  EnsureLocationSensor;
  try
    LbProximoValor.Text := 'GPS ativo';
    LbProximoSub.Text := 'aguardando posicao';
    if Assigned(FLocationSensor) and (not FLocationSensor.Active) then
      FLocationSensor.Active := True;
    QueueLocationRefresh;
  except
    on E: Exception do
    begin
      LbProximoValor.Text := 'Erro no GPS';
      LbProximoSub.Text := E.Message;
    end;
  end;
end;

procedure TfrmVisitas.DesativarGpsLocal;
begin
  if Assigned(FLocationRefreshTimer) then
    FLocationRefreshTimer.Enabled := False;

  if Assigned(FLocationSensor) then
  begin
    try
      FLocationSensor.Active := False;
    except
    end;
  end;

  FHasCurrentLocation := False;
  LbProximoValor.Text := 'GPS desativado';
  LbProximoSub.Text := 'representante sem rastreio';
end;

procedure TfrmVisitas.LocationSensorLocationChanged(Sender: TObject; const OldLocation,
  NewLocation: TLocationCoord2D);
begin
  if (NewLocation.Latitude = 0) and (NewLocation.Longitude = 0) then
    Exit;

  FCurrentLatitude := NewLocation.Latitude;
  FCurrentLongitude := NewLocation.Longitude;
  FHasCurrentLocation := True;

  if Assigned(FLocationRefreshTimer) then
  begin
    FLocationRefreshTimer.Enabled := False;
    FLocationRefreshTimer.Interval := 500;
    FLocationRefreshTimer.Enabled := True;
  end
  else
    QueueLocationRefresh;
end;

procedure TfrmVisitas.QueueLocationRefresh;
begin
  if Assigned(FLocationRefreshTimer) and (not FLocationRefreshTimer.Enabled) then
    FLocationRefreshTimer.Enabled := True;
end;

procedure TfrmVisitas.LocationRefreshTimerTimer(Sender: TObject);
var
  LNowTick: Cardinal;
  LMoved: Double;
  LLatitude: Double;
  LLongitude: Double;
begin
  if Assigned(FLocationRefreshTimer) then
    FLocationRefreshTimer.Enabled := False;

  if not ObterUltimaLocalizacao(LLatitude, LLongitude) then
  begin
    if Assigned(FLocationRefreshTimer) and Visible then
    begin
      FLocationRefreshTimer.Interval := 3000;
      FLocationRefreshTimer.Enabled := True;
    end;
    Exit;
  end;

  FCurrentLatitude := LLatitude;
  FCurrentLongitude := LLongitude;
  FHasCurrentLocation := True;

  LNowTick := TThread.GetTickCount;
  if (FLastListTick <> 0) and (FLastListLatitude <> 0) and (FLastListLongitude <> 0) then
  begin
    LMoved := DistanciaMetros(FLastListLatitude, FLastListLongitude, FCurrentLatitude, FCurrentLongitude);
    if LMoved < 25 then
    begin
      LbProximoSub.Text := 'GPS atualizado';
      if Assigned(FLocationRefreshTimer) and Visible then
      begin
        FLocationRefreshTimer.Interval := 10000;
        FLocationRefreshTimer.Enabled := True;
      end;
      Exit;
    end;
  end;

  FLastListTick := LNowTick;
  FLastListLatitude := FCurrentLatitude;
  FLastListLongitude := FCurrentLongitude;
  ListarRoteiro;

  if Assigned(FLocationRefreshTimer) and Visible then
  begin
    FLocationRefreshTimer.Interval := 10000;
    FLocationRefreshTimer.Enabled := True;
  end;
end;

{$IFDEF ANDROID}
function TfrmVisitas.HasLocationPermission: Boolean;
begin
  Result := True;
  if TJBuild_VERSION.JavaClass.SDK_INT >= 23 then
    Result :=
      (TAndroidHelper.Context.checkSelfPermission(
        TJManifest_permission.JavaClass.ACCESS_FINE_LOCATION) = 0) or
      (TAndroidHelper.Context.checkSelfPermission(
        TJManifest_permission.JavaClass.ACCESS_COARSE_LOCATION) = 0);
end;

procedure TfrmVisitas.RequestLocationPermission;
begin
  if FLocationPermissionRequested then
    Exit;

  FLocationPermissionRequested := True;
  TPermissionsService.DefaultService.RequestPermissions(
    [JStringToString(TJManifest_permission.JavaClass.ACCESS_COARSE_LOCATION),
     JStringToString(TJManifest_permission.JavaClass.ACCESS_FINE_LOCATION)],
    LocationPermissionResult,
    LocationPermissionRationale);
end;

procedure TfrmVisitas.LocationPermissionResult(Sender: TObject; const APermissions: TClassicStringDynArray;
  const AGrantResults: TClassicPermissionStatusDynArray);
var
  I: Integer;
  LGranted: Boolean;
begin
  FLocationPermissionRequested := False;
  LGranted := False;

  for I := 0 to High(AGrantResults) do
    if AGrantResults[I] = TPermissionStatus.Granted then
    begin
      LGranted := True;
      Break;
    end;

  if LGranted then
    StartLocationSensor
  else
  begin
    LbProximoValor.Text := 'Permissao negada';
    LbProximoSub.Text := 'ative localizacao';
  end;
end;

procedure TfrmVisitas.LocationPermissionRationale(Sender: TObject; const APermissions: TClassicStringDynArray;
  const APostRationaleProc: TProc);
begin
  APostRationaleProc;
end;
{$ENDIF}

function TfrmVisitas.ObterUltimaLocalizacao(var ALatitude, ALongitude: Double): Boolean;
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
      'select latitude, longitude from representante_localizacao ' +
      'order by id desc limit 1';
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

  if (not Result) and FHasCurrentLocation then
  begin
    ALatitude := FCurrentLatitude;
    ALongitude := FCurrentLongitude;
    Result := True;
  end;
end;

function TfrmVisitas.CodRepresentanteAtual: Integer;
begin
  Result := 0;
  try
    Result := StrToIntDef(Trim(dmApp.FDConnection.ExecSQLScalar(
      'select coalesce(value, '''') from app_config where key = ''cod_representante''')), 0);
  except
    Result := 0;
  end;
end;

procedure TfrmVisitas.PopularFiltros;
var
  I: Integer;
  LHoje: TDateTime;
  LDiasMes: Integer;
begin
  FAtualizandoFiltros := True;
  try
    if Assigned(CbModoBusca) then
    begin
      CbModoBusca.Items.Clear;
      CbModoBusca.Items.Add('Nome');
      CbModoBusca.Items.Add('Codigo');
      CbModoBusca.Items.Add('Fantasia');
      CbModoBusca.Items.Add('Proximidade');
      CbModoBusca.ItemIndex := 3;
    end;

    LHoje := Date;
    LDiasMes := DaysInAMonth(YearOf(LHoje), MonthOf(LHoje));
    CbPeriodo.Items.Clear;
    for I := 1 to LDiasMes do
      CbPeriodo.Items.Add(FormatDateTime('dd/mm/yyyy', EncodeDate(YearOf(LHoje), MonthOf(LHoje), I)));
    CbPeriodo.ItemIndex := DayOf(LHoje) - 1;

    CbStatus.Items.Clear;
    CbStatus.Items.Add('Pendentes');
    CbStatus.Items.Add('Visitados');
    CbStatus.Items.Add('Todos');
    CbStatus.ItemIndex := 0;
  finally
    FAtualizandoFiltros := False;
  end;
  AtualizarTecladoBusca;
end;

procedure TfrmVisitas.AtualizarTecladoBusca;
begin
  if not Assigned(EdBuscar) then
    Exit;

  if Assigned(CbModoBusca) and (CbModoBusca.ItemIndex >= 0) and
     SameText(CbModoBusca.Items[CbModoBusca.ItemIndex], 'Codigo') then
    EdBuscar.KeyboardType := TVirtualKeyboardType.NumberPad
  else
    EdBuscar.KeyboardType := TVirtualKeyboardType.Default;
end;

function TfrmVisitas.TextoPeriodo: string;
begin
  Result := '';
  if Assigned(CbPeriodo) and (CbPeriodo.ItemIndex >= 0) then
    Result := Trim(CbPeriodo.Items[CbPeriodo.ItemIndex]);
  if SameText(Result, 'TODOS') then
    Result := '';
end;

function TfrmVisitas.PeriodoSqlFiltro: string;
var
  LPeriodo: string;
  LData: TDateTime;
begin
  Result := '';
  LPeriodo := TextoPeriodo;
  if LPeriodo = '' then
    Exit;

  if TryStrToDate(LPeriodo, LData) then
    Result := FormatDateTime('yyyy-mm-dd', LData);
end;

procedure TfrmVisitas.ApplyResponsiveLayout;
var
  LIsLandscape: Boolean;
  LPad: Single;
  LGap: Single;
  LBottomSafe: Single;
  LContentW: Single;
  LTop: Single;
  LMetricW: Single;
  LCardH: Single;
  LMetricX: Single;
  LLeftW: Single;
  LRightX: Single;
  LRightW: Single;
begin
  if (Width <= 0) or (Height <= 0) then
    Exit;

  LIsLandscape := Width > Height;
  LPad := 18;
  LGap := 12;
  LBottomSafe := AndroidBottomSafeMargin(LIsLandscape);

  TopBar.Align := TAlignLayout.None;
  TopBar.SetBounds(0, 0, Width, IfThen(LIsLandscape, 64, 96));
  LbTitulo.SetBounds(26, IfThen(LIsLandscape, 14, 32), Width - 52, 34);
  LbSubtitulo.SetBounds(28, LbTitulo.Position.Y + 32, Width - 56, 20);

  lbottom.Align := TAlignLayout.None;
  lbottom.SetBounds(0, Height - IfThen(LIsLandscape, 54, 76) - LBottomSafe, Width, IfThen(LIsLandscape, 54, 76));
  LyVoltar.SetBounds(12, 0, 96, lbottom.Height);
  if LIsLandscape then
  begin
    LyCheckin.SetBounds(Max(150, Width - 216), 4, 186, 46);
    LyHistorico.SetBounds(Max(112, LyCheckin.Position.X - 140), LyCheckin.Position.Y, 128, 46);
    LyMapa.SetBounds(Max(112, LyHistorico.Position.X - 92), LyCheckin.Position.Y, 82, 46);
    LyRota.SetBounds(Max(112, LyMapa.Position.X - 92), LyCheckin.Position.Y, 82, 46);
  end
  else
  begin
    LyVoltar.SetBounds(4, 0, 76, lbottom.Height);
    LyCheckin.SetBounds(Width - 124, 14, 110, 46);
    LyHistorico.SetBounds(Max(190, LyCheckin.Position.X - 70), LyCheckin.Position.Y, 64, 46);
    LyMapa.SetBounds(Max(134, LyHistorico.Position.X - 56), LyCheckin.Position.Y, 50, 46);
    LyRota.SetBounds(Max(82, LyMapa.Position.X - 54), LyCheckin.Position.Y, 50, 46);
  end;

  LContentW := Width - (LPad * 2);
  if LContentW > 760 then
    LContentW := 760;
  LTop := TopBar.Height + LGap;

  CardBusca.Align := TAlignLayout.None;
  CardBusca.SetBounds((Width - LContentW) / 2, LTop, LContentW, IfThen(LIsLandscape, 92, 188));
  LbBuscar.SetBounds(20, 9, 220, 20);
  LbModoBusca.TextSettings.Font.Size := IfThen(LIsLandscape, 9, 11);
  LbPeriodo.TextSettings.Font.Size := IfThen(LIsLandscape, 9, 11);
  LbStatus.TextSettings.Font.Size := IfThen(LIsLandscape, 9, 11);
  if LIsLandscape then
  begin
    EdBuscar.SetBounds(20, 34, Max(150, CardBusca.Width - 444), 30);
    LbModoBusca.SetBounds(CardBusca.Width - 416, 16, 118, 16);
    CbModoBusca.SetBounds(CardBusca.Width - 416, 40, 118, 32);
    LbPeriodo.SetBounds(CardBusca.Width - 292, 16, 108, 16);
    CbPeriodo.SetBounds(CardBusca.Width - 292, 40, 108, 32);
    LbStatus.SetBounds(CardBusca.Width - 178, 16, 126, 16);
    CbStatus.SetBounds(CardBusca.Width - 178, 40, 126, 32);
    BtnBuscar.SetBounds(CardBusca.Width - 38, 34, 32, 32);
  end
  else
  begin
    EdBuscar.SetBounds(20, 34, CardBusca.Width - 40, 30);
    LbModoBusca.SetBounds(20, 70, 118, 16);
    CbModoBusca.SetBounds(20, 92, 118, 32);
    LbPeriodo.SetBounds(152, 70, Max(112, CardBusca.Width - 232), 16);
    CbPeriodo.SetBounds(152, 92, 112, 32);
    LbStatus.SetBounds(20, 126, CardBusca.Width - 94, 16);
    CbStatus.SetBounds(20, 146, CardBusca.Width - 94, 32);
    BtnBuscar.SetBounds(CardBusca.Width - 58, 130, 42, 42);
  end;

  LTop := CardBusca.Position.Y + CardBusca.Height + LGap;
  if LIsLandscape then
  begin
    LMetricX := (Width - LContentW) / 2;
    LLeftW := Max(250, LContentW * 0.42);
    LRightX := LMetricX + LLeftW + LGap;
    LRightW := LContentW - LLeftW - LGap;
    LCardH := 36;

    CardProximo.SetBounds(LMetricX, LTop, LLeftW, 40);
    LbProximoTitulo.SetBounds(12, 4, 120, 14);
    LbProximoValor.SetBounds(12, 19, LLeftW - 74, 20);
    LbProximoSub.SetBounds(LLeftW - 70, 18, 62, 18);
    LbProximoTitulo.TextSettings.Font.Size := 8;
    LbProximoValor.TextSettings.Font.Size := 9;
    LbProximoSub.TextSettings.Font.Size := 8;

    LTop := CardProximo.Position.Y + CardProximo.Height + 6;
    LMetricW := (LLeftW - 8) / 2;
    CardAVisitar.SetBounds(LMetricX, LTop, LMetricW, LCardH);
    CardRealizadas.SetBounds(LMetricX + LMetricW + 8, LTop, LMetricW, LCardH);
    CardComVenda.SetBounds(LMetricX, LTop + LCardH + 6, LMetricW, LCardH);
    CardSemVenda.SetBounds(LMetricX + LMetricW + 8, LTop + LCardH + 6, LMetricW, LCardH);

    LbAVisitarTitulo.SetBounds(10, 4, LMetricW - 20, 12);
    LbAVisitarValor.SetBounds(10, 16, LMetricW - 20, 18);
    LbAVisitarSub.SetBounds(10, 29, LMetricW - 20, 8);
    LbRealizadasTitulo.SetBounds(10, 4, LMetricW - 20, 12);
    LbRealizadasValor.SetBounds(10, 16, LMetricW - 20, 18);
    LbRealizadasSub.SetBounds(10, 29, LMetricW - 20, 8);
    LbComVendaTitulo.SetBounds(10, 4, LMetricW - 20, 12);
    LbComVendaValor.SetBounds(10, 16, LMetricW - 20, 18);
    LbComVendaSub.SetBounds(10, 29, LMetricW - 20, 8);
    LbSemVendaTitulo.SetBounds(10, 4, LMetricW - 20, 12);
    LbSemVendaValor.SetBounds(10, 16, LMetricW - 20, 18);
    LbSemVendaSub.SetBounds(10, 29, LMetricW - 20, 8);

    LbAVisitarTitulo.TextSettings.Font.Size := 8;
    LbRealizadasTitulo.TextSettings.Font.Size := 8;
    LbComVendaTitulo.TextSettings.Font.Size := 8;
    LbSemVendaTitulo.TextSettings.Font.Size := 8;
    LbAVisitarValor.TextSettings.Font.Size := 13;
    LbRealizadasValor.TextSettings.Font.Size := 13;
    LbComVendaValor.TextSettings.Font.Size := 13;
    LbSemVendaValor.TextSettings.Font.Size := 13;
    LbAVisitarSub.TextSettings.Font.Size := 7;
    LbRealizadasSub.TextSettings.Font.Size := 7;
    LbComVendaSub.TextSettings.Font.Size := 7;
    LbSemVendaSub.TextSettings.Font.Size := 7;

    CardLista.Align := TAlignLayout.None;
    CardLista.SetBounds(LRightX, CardBusca.Position.Y + CardBusca.Height + LGap,
      LRightW, lbottom.Position.Y - (CardBusca.Position.Y + CardBusca.Height + LGap + 8));
    if CardLista.Height < 130 then
      CardLista.Height := 130;
    LbListaTitulo.SetBounds(14, 8, CardLista.Width - 28, 20);
    LbListaTitulo.TextSettings.Font.Size := 12;
    LvRoteiro.ItemAppearance.ItemHeight := 46;
    LvRoteiro.ItemAppearance.ItemEditHeight := LvRoteiro.ItemAppearance.ItemHeight;
    LvRoteiro.ItemAppearanceObjects.ItemObjects.Text.Font.Size := 10;
    LvRoteiro.ItemAppearanceObjects.ItemObjects.Text.Height := 16;
    LvRoteiro.ItemAppearanceObjects.ItemObjects.Text.PlaceOffset.X := -10;
    LvRoteiro.ItemAppearanceObjects.ItemObjects.Text.PlaceOffset.Y := 5;
    LvRoteiro.ItemAppearanceObjects.ItemObjects.Text.Width := CardLista.Width - 54;
    LvRoteiro.ItemAppearanceObjects.ItemObjects.Text.WordWrap := True;
    LvRoteiro.ItemAppearanceObjects.ItemEditObjects.Text.WordWrap := True;
    LvRoteiro.ItemAppearanceObjects.ItemObjects.Accessory.Visible := False;
    LvRoteiro.ItemAppearanceObjects.ItemObjects.Accessory.Width := 38;
    LvRoteiro.ItemAppearanceObjects.ItemObjects.Accessory.Height := 30;
    LvRoteiro.ItemAppearanceObjects.ItemObjects.Accessory.PlaceOffset.Y := -3;
    LvRoteiro.ItemAppearanceObjects.ItemObjects.Detail.Font.Size := 9;
    LvRoteiro.ItemAppearanceObjects.ItemObjects.Detail.Height := 30;
    LvRoteiro.ItemAppearanceObjects.ItemObjects.Detail.PlaceOffset.X := 1;
    LvRoteiro.ItemAppearanceObjects.ItemObjects.Detail.PlaceOffset.Y := 18;
    LvRoteiro.ItemAppearanceObjects.ItemObjects.Detail.Width := CardLista.Width - 54;
    LvRoteiro.ItemAppearanceObjects.ItemObjects.Detail.WordWrap := True;
    LvRoteiro.ItemAppearanceObjects.ItemEditObjects.Detail.WordWrap := True;
    LvRoteiro.SetBounds(12, 32, CardLista.Width - 24, CardLista.Height - 40);
    Exit;
  end;

  CardProximo.SetBounds((Width - LContentW) / 2, LTop, LContentW, IfThen(LIsLandscape, 44, 48));
  LbProximoTitulo.SetBounds(14, 5, 150, 16);
  LbProximoValor.SetBounds(14, 21, CardProximo.Width * 0.58, 22);
  LbProximoSub.SetBounds(CardProximo.Width * 0.58, 18, CardProximo.Width * 0.36, 22);
  LbProximoTitulo.TextSettings.Font.Size := 9;
  LbProximoValor.TextSettings.Font.Size := IfThen(LIsLandscape, 11, 10);
  LbProximoSub.TextSettings.Font.Size := 9;

  LTop := CardProximo.Position.Y + CardProximo.Height + LGap;
  LCardH := IfThen(LIsLandscape, 52, 58);
  LMetricW := (LContentW - LGap) / 2;
  LMetricX := (Width - LContentW) / 2;
  CardAVisitar.SetBounds(LMetricX, LTop, LMetricW, LCardH);
  CardRealizadas.SetBounds(CardAVisitar.Position.X + LMetricW + LGap, LTop, LMetricW, LCardH);
  CardComVenda.SetBounds(CardAVisitar.Position.X, LTop + LCardH + LGap, LMetricW, LCardH);
  CardSemVenda.SetBounds(CardRealizadas.Position.X, CardComVenda.Position.Y, LMetricW, LCardH);

  LbAVisitarTitulo.SetBounds(12, 5, LMetricW - 24, 14);
  LbAVisitarValor.SetBounds(12, 20, LMetricW - 24, 22);
  LbAVisitarSub.SetBounds(12, 41, LMetricW - 24, 13);
  LbRealizadasTitulo.SetBounds(12, 5, LMetricW - 24, 14);
  LbRealizadasValor.SetBounds(12, 20, LMetricW - 24, 22);
  LbRealizadasSub.SetBounds(12, 41, LMetricW - 24, 13);
  LbComVendaTitulo.SetBounds(12, 5, LMetricW - 24, 14);
  LbComVendaValor.SetBounds(12, 20, LMetricW - 24, 22);
  LbComVendaSub.SetBounds(12, 41, LMetricW - 24, 13);
  LbSemVendaTitulo.SetBounds(12, 5, LMetricW - 24, 14);
  LbSemVendaValor.SetBounds(12, 20, LMetricW - 24, 22);
  LbSemVendaSub.SetBounds(12, 41, LMetricW - 24, 13);

  LbAVisitarTitulo.TextSettings.Font.Size := 9;
  LbRealizadasTitulo.TextSettings.Font.Size := 9;
  LbComVendaTitulo.TextSettings.Font.Size := 9;
  LbSemVendaTitulo.TextSettings.Font.Size := 9;
  LbAVisitarValor.TextSettings.Font.Size := 17;
  LbRealizadasValor.TextSettings.Font.Size := 17;
  LbComVendaValor.TextSettings.Font.Size := 17;
  LbSemVendaValor.TextSettings.Font.Size := 17;
  LbAVisitarSub.TextSettings.Font.Size := 8;
  LbRealizadasSub.TextSettings.Font.Size := 8;
  LbComVendaSub.TextSettings.Font.Size := 8;
  LbSemVendaSub.TextSettings.Font.Size := 8;

  CardLista.Align := TAlignLayout.None;
  CardLista.SetBounds((Width - LContentW) / 2, CardComVenda.Position.Y + LCardH + LGap,
    LContentW, lbottom.Position.Y - (CardComVenda.Position.Y + LCardH + LGap + 8));
  if CardLista.Height < 130 then
    CardLista.Height := 130;
  LbListaTitulo.SetBounds(18, 10, CardLista.Width - 36, 24);
  LbListaTitulo.TextSettings.Font.Size := 14;
  if LIsLandscape then
    LvRoteiro.ItemAppearance.ItemHeight := 46
  else
    LvRoteiro.ItemAppearance.ItemHeight := 48;
  LvRoteiro.ItemAppearance.ItemEditHeight := LvRoteiro.ItemAppearance.ItemHeight;
  LvRoteiro.ItemAppearanceObjects.ItemObjects.Text.Font.Size := 10;
  LvRoteiro.ItemAppearanceObjects.ItemObjects.Text.Height := 16;
  LvRoteiro.ItemAppearanceObjects.ItemObjects.Text.PlaceOffset.X := -10;
  LvRoteiro.ItemAppearanceObjects.ItemObjects.Text.PlaceOffset.Y := 5;
  LvRoteiro.ItemAppearanceObjects.ItemObjects.Text.Width := CardLista.Width - 54;
  LvRoteiro.ItemAppearanceObjects.ItemObjects.Text.WordWrap := True;
  LvRoteiro.ItemAppearanceObjects.ItemEditObjects.Text.WordWrap := True;
  LvRoteiro.ItemAppearanceObjects.ItemObjects.Accessory.Visible := False;
  LvRoteiro.ItemAppearanceObjects.ItemObjects.Accessory.Width := 38;
  LvRoteiro.ItemAppearanceObjects.ItemObjects.Accessory.Height := 30;
  LvRoteiro.ItemAppearanceObjects.ItemObjects.Accessory.PlaceOffset.Y := -3;
  LvRoteiro.ItemAppearanceObjects.ItemObjects.Detail.Font.Size := 9;
  LvRoteiro.ItemAppearanceObjects.ItemObjects.Detail.Height := 30;
  LvRoteiro.ItemAppearanceObjects.ItemObjects.Detail.PlaceOffset.X := 1;
  LvRoteiro.ItemAppearanceObjects.ItemObjects.Detail.PlaceOffset.Y := 18;
  LvRoteiro.ItemAppearanceObjects.ItemObjects.Detail.Width := CardLista.Width - 54;
  LvRoteiro.ItemAppearanceObjects.ItemObjects.Detail.WordWrap := True;
  LvRoteiro.ItemAppearanceObjects.ItemEditObjects.Detail.WordWrap := True;
  LvRoteiro.SetBounds(12, 36, CardLista.Width - 24, CardLista.Height - 44);
end;

procedure TfrmVisitas.ListarRoteiro;
var
  Q: TFDQuery;
  LSql: string;
  LTexto: string;
  LPeriodo: string;
  LStatus: string;
  LModoBusca: string;
  LItem: TListViewItem;
  LNome: string;
  LFantasia: string;
  LCidade: string;
  LUltVenda: string;
  LUltVendaFmt: string;
  LVisitadoHoje: string;
  LValor: Double;
  LRepLat: Double;
  LRepLon: Double;
  LGpsOk: Boolean;
  LClienteLat: Double;
  LClienteLon: Double;
  LDistancia: Double;
  LNearestDistance: Double;
  LNearestCliente: string;
  LNearbyCount: Integer;
  LAVisitar: Integer;
  LRealizadas: Integer;
  LComVenda: Integer;
  LSemVenda: Integer;
  LKmRodado: Double;
  LBoletoAtraso: Boolean;
  LBoletoAberto: Boolean;
begin
  LAVisitar := 0;
  LRealizadas := 0;
  LComVenda := 0;
  LSemVenda := 0;
  LKmRodado := KmRodadoHoje;
  LGpsOk := ObterUltimaLocalizacao(LRepLat, LRepLon);
  LNearestDistance := MaxDouble;
  LNearestCliente := '';
  LNearbyCount := 0;
  FClienteProximo := 0;
  FDistanciaProximo := MaxDouble;

  LTexto := Trim(EdBuscar.Text);
  LPeriodo := PeriodoSqlFiltro;
  LStatus := '';
  LModoBusca := 'Nome';
  if Assigned(CbModoBusca) and (CbModoBusca.ItemIndex >= 0) then
    LModoBusca := CbModoBusca.Items[CbModoBusca.ItemIndex];
  if CbStatus.ItemIndex >= 0 then
    LStatus := CbStatus.Items[CbStatus.ItemIndex];

  LSql :=
    'select c.cod_cliente, c.nom_cliente, c.nom_fantasia, c.latitude, c.longitude, ' +
    '       trim(coalesce(cid.nom_cidade, '''') || case when coalesce(cid.uf, '''') <> '''' then ''-'' || cid.uf else '''' end) as cidade, ' +
    '       max(date(coalesce(nullif(v.dta_emissao, ''''), nullif(v.dtadoc, '''')))) as ultima_venda, ' +
    '       (select max(cv.datahora) from cliente_visitas cv where cv.cod_cliente = c.cod_cliente and date(cv.datahora) = date(''now'')) as visitado_hoje, ' +
    '       (select coalesce(max(cv.valor_pedido), 0) from cliente_visitas cv where cv.cod_cliente = c.cod_cliente and date(cv.datahora) = date(''now'')) as valor_visita, ' +
     '       (select max(coalesce(cv.vendeu, '''')) from cliente_visitas cv where cv.cod_cliente = c.cod_cliente and date(cv.datahora) = date(''now'')) as vendeu, ' +
     '       case when exists (select 1 from cr1 b ' +
     '         where b.cod_cliente = c.cod_cliente ' +
     '           and trim(coalesce(b.dtarec, '''')) = '''' ' +
     '           and date(case ' +
     '             when substr(trim(b.dtaven), 5, 1) = ''-'' then substr(trim(b.dtaven), 1, 10) ' +
     '             when substr(trim(b.dtaven), 3, 1) = ''/'' then substr(trim(b.dtaven), 7, 4) || ''-'' || ' +
     '                  substr(trim(b.dtaven), 4, 2) || ''-'' || substr(trim(b.dtaven), 1, 2) ' +
     '             else trim(b.dtaven) end) < date(''now'', ''localtime'')) ' +
     '         then 1 else 0 end as boleto_atraso, ' +
     '       case when exists (select 1 from cr1 bo ' +
     '         where bo.cod_cliente = c.cod_cliente ' +
     '           and trim(coalesce(bo.dtarec, '''')) = '''') ' +
     '         then 1 else 0 end as boleto_aberto ' +
     'from cliente c ' +
    'left join cidades cid on cid.cod_cidade = c.cod_cidade ' +
    'left join vendas1 v on v.cod_cliente = c.cod_cliente ' +
    'where coalesce(c.status, '''') <> ''I'' ';

  if LTexto <> '' then
  begin
    if SameText(LModoBusca, 'Codigo') then
      LSql := LSql + ' and cast(c.cod_cliente as text) like :codigo '
    else if SameText(LModoBusca, 'Fantasia') then
      LSql := LSql + ' and upper(coalesce(c.nom_fantasia, '''')) like :busca '
    else
      LSql := LSql + ' and (upper(coalesce(c.nom_cliente, '''')) like :busca or upper(coalesce(c.nom_fantasia, '''')) like :busca or cast(c.cod_cliente as text) like :codigo) ';
  end;

  LSql := LSql +
    'group by c.cod_cliente, c.nom_cliente, c.nom_fantasia, c.latitude, c.longitude, cid.nom_cidade, cid.uf ';

  if LPeriodo <> '' then
    LSql := LSql + 'having ultima_venda is null or ultima_venda < :periodo ';

  if SameText(LModoBusca, 'Proximidade') and LGpsOk then
    LSql := LSql +
      'order by case when c.latitude is null or c.longitude is null then 1 else 0 end, ' +
      '((c.latitude - :latref) * (c.latitude - :latref)) + ((c.longitude - :lonref) * (c.longitude - :lonref)), c.nom_cliente limit 100'
  else
    LSql := LSql +
      'order by case when ultima_venda is null then 0 else 1 end, ultima_venda, c.nom_cliente limit 100';

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := LSql;
    if LTexto <> '' then
    begin
      if SameText(LModoBusca, 'Codigo') then
        Q.ParamByName('codigo').AsString := LTexto + '%'
      else if SameText(LModoBusca, 'Fantasia') then
        Q.ParamByName('busca').AsString := '%' + UpperCase(LTexto) + '%'
      else
      begin
        Q.ParamByName('busca').AsString := '%' + UpperCase(LTexto) + '%';
        Q.ParamByName('codigo').AsString := LTexto + '%';
      end;
    end;
    if LPeriodo <> '' then
      Q.ParamByName('periodo').AsString := LPeriodo;
    if SameText(LModoBusca, 'Proximidade') and LGpsOk then
    begin
      Q.ParamByName('latref').AsFloat := LRepLat;
      Q.ParamByName('lonref').AsFloat := LRepLon;
    end;
    Q.Open;

    LvRoteiro.Items.BeginUpdate;
    try
      LvRoteiro.Items.Clear;
      while not Q.Eof do
      begin
        LVisitadoHoje := SafeFieldAsString(Q, 'visitado_hoje');
        LValor := SafeFieldAsFloat(Q, 'valor_visita');

        if SameText(LStatus, 'Pendentes') and (LVisitadoHoje <> '') then
        begin
          Q.Next;
          Continue;
        end;
        if SameText(LStatus, 'Visitados') and (LVisitadoHoje = '') then
        begin
          Q.Next;
          Continue;
        end;

        Inc(LAVisitar);
        if LVisitadoHoje <> '' then
        begin
          Inc(LRealizadas);
          if SameText(SafeFieldAsString(Q, 'vendeu'), 'S') or (LValor > 0) then
            Inc(LComVenda)
          else
            Inc(LSemVenda);
        end;

        LNome := SafeFieldAsString(Q, 'nom_cliente');
        LFantasia := SafeFieldAsString(Q, 'nom_fantasia');
        LCidade := SafeFieldAsString(Q, 'cidade');
        LDistancia := MaxDouble;
        if LGpsOk and (not Q.FieldByName('latitude').IsNull) and (not Q.FieldByName('longitude').IsNull) then
        begin
          LClienteLat := Q.FieldByName('latitude').AsFloat;
          LClienteLon := Q.FieldByName('longitude').AsFloat;
          if (LClienteLat <> 0) and (LClienteLon <> 0) then
          begin
            LDistancia := DistanciaMetros(LRepLat, LRepLon, LClienteLat, LClienteLon);
            if LDistancia < LNearestDistance then
            begin
              LNearestDistance := LDistancia;
              LNearestCliente := SafeFieldAsString(Q, 'cod_cliente') + ' - ' + LNome;
              FClienteProximo := StrToIntDef(SafeFieldAsString(Q, 'cod_cliente'), 0);
              FDistanciaProximo := LDistancia;
            end;
            if LDistancia <= 100 then
              Inc(LNearbyCount);
          end;
        end;
        LUltVenda := SafeFieldAsString(Q, 'ultima_venda');
        if LUltVenda <> '' then
          LUltVendaFmt := Copy(LUltVenda, 9, 2) + '/' + Copy(LUltVenda, 6, 2) + '/' + Copy(LUltVenda, 1, 4)
        else
          LUltVendaFmt := 'Sem venda';

        LItem := LvRoteiro.Items.Add;
        LItem.TagString := SafeFieldAsString(Q, 'cod_cliente');
        if LDistancia = MaxDouble then
          LItem.Tag := -1
        else
          LItem.Tag := Round(LDistancia);
        LItem.Text := SafeFieldAsString(Q, 'cod_cliente') + ' - ' + LNome;
        if LFantasia <> '' then
          LItem.Detail := LFantasia + sLineBreak + LCidade + ' | Ult. venda: ' + LUltVendaFmt + ' | GPS: ' + TextoDistancia(LDistancia)
        else
          LItem.Detail := LCidade + ' | Ult. venda: ' + LUltVendaFmt + ' | GPS: ' + TextoDistancia(LDistancia);

        LBoletoAtraso := SafeFieldAsString(Q, 'boleto_atraso') = '1';
        LBoletoAberto := SafeFieldAsString(Q, 'boleto_aberto') = '1';
        if LBoletoAtraso then
        begin
          if Assigned(LItem.Objects.TextObject) then
            LItem.Objects.TextObject.TextColor := TAlphaColor($FFFF0000);
          if Assigned(LItem.Objects.DetailObject) then
            LItem.Objects.DetailObject.TextColor := TAlphaColor($FFFF0000);
        end
        else if LBoletoAberto then
        begin
          if Assigned(LItem.Objects.TextObject) then
            LItem.Objects.TextObject.TextColor := TAlphaColor($FF008000);
          if Assigned(LItem.Objects.DetailObject) then
            LItem.Objects.DetailObject.TextColor := TAlphaColor($FF008000);
        end;

        Q.Next;
      end;
    finally
      LvRoteiro.Items.EndUpdate;
    end;
  finally
    Q.Free;
  end;

  if not LGpsOk then
  begin
    LbProximoValor.Text := 'GPS sem posicao';
    LbProximoSub.Text := 'aguardando rastreio';
  end
  else if LNearestCliente = '' then
  begin
    LbProximoValor.Text := 'Sem clientes com GPS';
    LbProximoSub.Text := 'sincronize coordenadas';
  end
  else
  begin
    LbProximoValor.Text := LNearestCliente;
    if LNearbyCount > 0 then
      LbProximoSub.Text := TextoDistancia(LNearestDistance) + ' | ' + LNearbyCount.ToString + ' ate 100m'
    else
      LbProximoSub.Text := TextoDistancia(LNearestDistance);
  end;

  LbAVisitarValor.Text := LAVisitar.ToString;
  LbAVisitarSub.Text := 'clientes no roteiro';
  LbRealizadasValor.Text := LRealizadas.ToString;
  if LAVisitar > 0 then
    LbRealizadasSub.Text := FormatFloat('0.0', (LRealizadas / LAVisitar) * 100) + '%'
  else
    LbRealizadasSub.Text := '0,0%';
  LbComVendaValor.Text := LComVenda.ToString;
  LbComVendaSub.Text := 'com pedido/valor';
  LbSemVendaValor.Text := LSemVenda.ToString;
  LbSemVendaSub.Text := 'sem venda';
  LbListaTitulo.Text := 'Roteiro de visitas - hoje: ' + TextoKmRodado(LKmRodado);


  ///FClienteProximo := 7088;
end;

procedure TfrmVisitas.FormShow(Sender: TObject);
begin
  OnClose := FormClose;
  EdBuscar.OnChange := BtnBuscarClick;
  CbModoBusca.OnChange := BtnBuscarClick;
  CbPeriodo.OnChange := BtnBuscarClick;
  CbStatus.OnChange := BtnBuscarClick;
  LvRoteiro.OnItemClick := LvRoteiroItemClick;
  UseAndroidSafeComboPicker([CbModoBusca, CbPeriodo, CbStatus]);
  PopularFiltros;
  ApplyResponsiveLayout;
  {$IFDEF ANDROID}
  if Assigned(frmPrincipal) then
    frmPrincipal.AtivarGpsTelaVisitas;

  if HasLocationPermission then
    StartLocationSensor
  else
  begin
    LbProximoValor.Text := 'Solicitando GPS';
    LbProximoSub.Text := 'aguarde permissao';
    RequestLocationPermission;
  end;
  {$ELSE}
  StartLocationSensor;
  {$ENDIF}
  ListarRoteiro;
end;

procedure TfrmVisitas.FormResize(Sender: TObject);
begin
  ApplyResponsiveLayout;
end;

procedure TfrmVisitas.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  DesativarGpsLocal;
  Action := TCloseAction.caFree;
  frmVisitas := nil;
end;

procedure TfrmVisitas.BtnBuscarClick(Sender: TObject);
begin
  AtualizarTecladoBusca;
  if FAtualizandoFiltros then
    Exit;
  ListarRoteiro;
end;

procedure TfrmVisitas.BtnBuscarTap(Sender: TObject; const Point: TPointF);
begin
  BtnBuscarClick(Sender);
end;

procedure TfrmVisitas.LvRoteiroItemClick(const Sender: TObject; const AItem: TListViewItem);
begin
  if not Assigned(AItem) then
    Exit;

  FClienteProximo := StrToIntDef(AItem.TagString, 0);
  if AItem.Tag >= 0 then
    FDistanciaProximo := AItem.Tag
  else
    FDistanciaProximo := MaxDouble;

  LbProximoValor.Text := AItem.Text;
  if FDistanciaProximo = MaxDouble then
    LbProximoSub.Text := 'Sem GPS'
  else
    LbProximoSub.Text := TextoDistancia(FDistanciaProximo);
end;

procedure TfrmVisitas.ImgVoltarClick(Sender: TObject);
begin
  Close;
end;


procedure TfrmVisitas.BtnHistoricoClick(Sender: TObject);
begin
  if not Assigned(frmVisitaHistorico) then
    Application.CreateForm(TfrmVisitaHistorico, frmVisitaHistorico);
  frmVisitaHistorico.Show;
end;

procedure TfrmVisitas.BtnMapaClick(Sender: TObject);
var
  LLat: Double;
  LLon: Double;
begin
  {$IFNDEF ANDROID}
  ShowMessage('Mapa disponivel no Android.');
  Exit;
  {$ELSE}
  if FHasCurrentLocation then
  begin
    LLat := FCurrentLatitude;
    LLon := FCurrentLongitude;
  end
  else if not ObterUltimaLocalizacao(LLat, LLon) then
  begin
    ShowMessage('GPS sem posicao para abrir o mapa.');
    Exit;
  end;

  if not Assigned(frmVisitasMapa) then
    Application.CreateForm(TfrmVisitasMapa, frmVisitasMapa);
  frmVisitasMapa.Show;
  frmVisitasMapa.CarregarClientesProximos(LLat, LLon);
  {$ENDIF}
end;

procedure TfrmVisitas.BtnRotaClick(Sender: TObject);
var
  LCodCliente: Integer;
  Q: TFDQuery;
  LLat: Double;
  LLon: Double;
  LFormat: TFormatSettings;
  LLatStr: string;
  LLonStr: string;
  LUrl: string;
  {$IFDEF ANDROID}
  LIntent: JIntent;
  {$ENDIF}
begin
  LCodCliente := FClienteProximo;
  if (LCodCliente <= 0) and Assigned(LvRoteiro.Selected) then
    LCodCliente := StrToIntDef(LvRoteiro.Selected.TagString, 0);

  if LCodCliente <= 0 then
  begin
    ShowMessage('Selecione um cliente no roteiro.');
    Exit;
  end;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text :=
      'select latitude, longitude from cliente ' +
      ' where cod_cliente = :p0 ' +
      '   and latitude is not null and longitude is not null ' +
      '   and latitude <> 0 and longitude <> 0';
    Q.ParamByName('p0').AsInteger := LCodCliente;
    Q.Open;
    if Q.Eof then
    begin
      ShowMessage('Cliente selecionado sem coordenadas GPS.');
      Exit;
    end;

    LLat := Q.FieldByName('latitude').AsFloat;
    LLon := Q.FieldByName('longitude').AsFloat;
  finally
    Q.Free;
  end;

  LFormat := TFormatSettings.Create;
  LFormat.DecimalSeparator := '.';
  LLatStr := FormatFloat('0.########', LLat, LFormat);
  LLonStr := FormatFloat('0.########', LLon, LFormat);

  {$IFNDEF ANDROID}
  ShowMessage('Rota disponivel no Android: ' + LLatStr + ', ' + LLonStr);
  {$ELSE}
  if Assigned(frmVisitasMapa) then
    frmVisitasMapa.Close;

  try
    LUrl := 'https://www.waze.com/ul?ll=' + LLatStr + ',' + LLonStr + '&navigate=yes&utm_source=WorbyRepres';
    LIntent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_VIEW, TJnet_Uri.JavaClass.parse(StringToJString(LUrl)));
    LIntent.addFlags(TJIntent.JavaClass.FLAG_ACTIVITY_NEW_TASK);
    TAndroidHelper.Activity.startActivity(LIntent);
  except
    try
      LUrl := 'waze://?ll=' + LLatStr + ',' + LLonStr + '&navigate=yes';
      LIntent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_VIEW, TJnet_Uri.JavaClass.parse(StringToJString(LUrl)));
      LIntent.addFlags(TJIntent.JavaClass.FLAG_ACTIVITY_NEW_TASK);
      TAndroidHelper.Activity.startActivity(LIntent);
    except
      try
        LUrl := 'google.navigation:q=' + LLatStr + ',' + LLonStr + '&mode=d';
        LIntent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_VIEW, TJnet_Uri.JavaClass.parse(StringToJString(LUrl)));
        LIntent.addFlags(TJIntent.JavaClass.FLAG_ACTIVITY_NEW_TASK);
        TAndroidHelper.Activity.startActivity(LIntent);
      except
        try
          LUrl := 'geo:0,0?q=' + LLatStr + ',' + LLonStr;
          LIntent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_VIEW, TJnet_Uri.JavaClass.parse(StringToJString(LUrl)));
          LIntent.addFlags(TJIntent.JavaClass.FLAG_ACTIVITY_NEW_TASK);
          TAndroidHelper.Activity.startActivity(LIntent);
        except
          try
            LUrl := 'https://www.google.com/maps/dir/?api=1&destination=' + LLatStr + ',' + LLonStr + '&travelmode=driving';
            LIntent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_VIEW, TJnet_Uri.JavaClass.parse(StringToJString(LUrl)));
            LIntent.addFlags(TJIntent.JavaClass.FLAG_ACTIVITY_NEW_TASK);
            TAndroidHelper.Activity.startActivity(LIntent);
          except
            on E: Exception do
              ShowMessage('Nao foi possivel abrir a rota: ' + E.Message);
          end;
        end;
      end;
    end;
  end;
  {$ENDIF}
end;

procedure TfrmVisitas.BtnCheckinClick(Sender: TObject);
var
  LLat: Double;
  LLon: Double;
begin

  if (FClienteProximo <= 0) or (FDistanciaProximo = MaxDouble) then
  begin
    ShowMessage('Sem cliente proximo pelo GPS.');
    Exit;
  end;

  if FDistanciaProximo > 200 then
  begin
    ShowMessage('Cliente mais proximo esta a ' + TextoDistancia(FDistanciaProximo) + '. Aproxime ate 200 m para registrar.');
    Exit;
  end;

  if FHasCurrentLocation then
  begin
    LLat := FCurrentLatitude;
    LLon := FCurrentLongitude;
  end
  else if not ObterUltimaLocalizacao(LLat, LLon) then
  begin
    LLat := 0;
    LLon := 0;
  end;

  if not Assigned(frmVisitaCheckin) then
    Application.CreateForm(TfrmVisitaCheckin, frmVisitaCheckin);
  frmVisitaCheckin.SetCheckin(FClienteProximo, FDistanciaProximo, LLat, LLon, 0, 0);
  frmVisitaCheckin.Show;
end;

end.
