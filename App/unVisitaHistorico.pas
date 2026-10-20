unit unVisitaHistorico;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.DateUtils, System.Math, System.IOUtils, Data.DB, FireDAC.Comp.Client,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.ListBox,
  FMX.ListView, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base
  {$IF Defined(MSWINDOWS)}
  , Winapi.Windows, Winapi.ShellAPI
  {$ENDIF}
  ;

type
  TfrmVisitaHistorico = class(TForm)
    LayoutRoot: TLayout;
    BackgroundRect: TRectangle;
    TopBar: TRectangle;
    LbTitulo: TLabel;
    LbSubtitulo: TLabel;
    CardFiltro: TRectangle;
    LbBuscar: TLabel;
    EdBuscar: TEdit;
    CbPeriodo: TComboBox;
    BtnBuscar: TImage;
    CardResumo: TRectangle;
    LbResumoTitulo: TLabel;
    LbTotalVisitasTitulo: TLabel;
    LbTotalVisitasValor: TLabel;
    LbComVendaTitulo: TLabel;
    LbComVendaValor: TLabel;
    LbSemVendaTitulo: TLabel;
    LbSemVendaValor: TLabel;
    CardLista: TRectangle;
    LbListaTitulo: TLabel;
    LvHistorico: TListView;
    lbottom: TLayout;
    LyVoltar: TLayout;
    ImgVoltar: TImage;
    BtnCompartilhar: TRectangle;
    LbCompartilhar: TLabel;
    BtnImprimir: TRectangle;
    BtnMapa: TRectangle;
    LbMapa: TLabel;
    LbImprimir: TLabel;
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnBuscarClick(Sender: TObject);
    procedure ImgVoltarClick(Sender: TObject);
    procedure BtnCompartilharClick(Sender: TObject);
    procedure BtnImprimirClick(Sender: TObject);
    procedure BtnMapaClick(Sender: TObject);
  private
    FAtualizandoFiltros: Boolean;
    procedure PopularPeriodo;
    procedure ApplyResponsiveLayout;
    procedure ListarHistorico;
    function PeriodoSqlFiltro: string;
    function SafeFieldAsString(AQuery: TFDQuery; const ACampo: string): string;
    function SafeFieldAsFloat(AQuery: TFDQuery; const ACampo: string): Double;
    function FormatarDataHora(const AValor: string): string;
    function DistanciaMetros(ALat1, ALon1, ALat2, ALon2: Double): Double;
    function TextoKmRodado(AKm: Double): string;
    function CodRepresentanteAtual: Integer;
    function NomeRepresentanteAtual: string;
    function KmRodadoPeriodo(const APeriodo: string): Double;
    function CorTimeline(const AStatusVisita, AVendeu: string; AValor: Double): string;
    function TextoTimeline(const AStatusVisita, AVendeu: string; AValor: Double): string;
    function GerarRelatorioHtmlPdf(ACompartilhar: Boolean): string;
  public
  end;

var
  frmVisitaHistorico: TfrmVisitaHistorico;

implementation

{$R *.fmx}

uses
  unDMApp, unFuncoes, unAndroidComboFix
{$IFDEF ANDROID}
  , unVisitaHistoricoMapa
  , Androidapi.Helpers
  , Androidapi.JNI.JavaTypes
  , Androidapi.JNI.GraphicsContentViewText
  , Androidapi.JNI.Net
  , Androidapi.JNI.Os
  , Androidapi.JNI.Support
  , Androidapi.IOUtils
  , FMX.Helpers.Android
{$ENDIF}
  ;

{$IFDEF ANDROID}
function BuildContentUriForPdf(const AFileName: string): Jnet_Uri;
var
  LFile: JFile;
  LAuthority: JString;
begin
  LFile := TJFile.JavaClass.init(StringToJString(AFileName));

  LAuthority := TAndroidHelper.Context.getPackageName.concat(StringToJString('.fileprovider'));
  try
    Result := TJcontent_FileProvider.JavaClass.getUriForFile(TAndroidHelper.Context, LAuthority, LFile);
    Exit;
  except
  end;

  LAuthority := TAndroidHelper.Context.getPackageName.concat(StringToJString('.provider'));
  Result := TJcontent_FileProvider.JavaClass.getUriForFile(TAndroidHelper.Context, LAuthority, LFile);
end;
{$ENDIF}

function GetPdfOutputDir: string;
begin
{$IFDEF ANDROID}
  Result := System.IOUtils.TPath.GetDocumentsPath;
{$ELSE}
  Result := ExtractFilePath(ParamStr(0));
{$ENDIF}
end;

function TfrmVisitaHistorico.SafeFieldAsString(AQuery: TFDQuery; const ACampo: string): string;
begin
  if Assigned(AQuery.FindField(ACampo)) then
    Result := AQuery.FieldByName(ACampo).AsString
  else
    Result := '';
end;

function TfrmVisitaHistorico.SafeFieldAsFloat(AQuery: TFDQuery; const ACampo: string): Double;
begin
  if Assigned(AQuery.FindField(ACampo)) then
    Result := AQuery.FieldByName(ACampo).AsFloat
  else
    Result := 0;
end;

function TfrmVisitaHistorico.FormatarDataHora(const AValor: string): string;
begin
  Result := Trim(AValor);
  if Result = '' then
    Exit;

  if (Length(Result) >= 16) and (Copy(Result, 5, 1) = '-') then
    Result := Copy(Result, 9, 2) + '/' + Copy(Result, 6, 2) + '/' + Copy(Result, 1, 4) + ' ' + Copy(Result, 12, 5);
end;

function TfrmVisitaHistorico.DistanciaMetros(ALat1, ALon1, ALat2, ALon2: Double): Double;
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

function TfrmVisitaHistorico.TextoKmRodado(AKm: Double): string;
begin
  Result := FormatFloat('#,##0.0', AKm) + ' km';
end;

function TfrmVisitaHistorico.CorTimeline(const AStatusVisita, AVendeu: string; AValor: Double): string;
var
  LStatus: string;
begin
  LStatus := UpperCase(Trim(AStatusVisita));
  if (UpperCase(Trim(AVendeu)) = 'S') or (AValor > 0) or (Pos('VENDA', LStatus) > 0) then
    Result := '#119C6A'
  else if (Pos('IMPOSSIBILITADA', LStatus) > 0) or (Pos('SEM VENDA', LStatus) > 0) then
    Result := '#E03131'
  else if (Pos('COBRANCA', LStatus) > 0) or (Pos('COBRAN', LStatus) > 0) then
    Result := '#2F6BFF'
  else
    Result := '#667085';
end;

function TfrmVisitaHistorico.TextoTimeline(const AStatusVisita, AVendeu: string; AValor: Double): string;
begin
  if (UpperCase(Trim(AVendeu)) = 'S') or (AValor > 0) then
  begin
    if AValor > 0 then
      Result := 'Venda registrada | R$ ' + FormatFloat('#,##0.00', AValor)
    else
      Result := 'Venda registrada';
  end
  else
    Result := Trim(AStatusVisita);

  if Result = '' then
    Result := 'Sem venda';
end;

function TfrmVisitaHistorico.CodRepresentanteAtual: Integer;
begin
  Result := 0;
  try
    Result := StrToIntDef(Trim(dmApp.FDConnection.ExecSQLScalar(
      'select coalesce(value, '''') from app_config where key = ''cod_representante''')), 0);
  except
    Result := 0;
  end;
end;

function TfrmVisitaHistorico.NomeRepresentanteAtual: string;
var
  Q: TFDQuery;
  LCodRep: Integer;
begin
  Result := '';
  try
    Result := Trim(dmApp.FDConnection.ExecSQLScalar(
      'select coalesce(value, '''') from app_config where key = ''nom_representante'''));
  except
    Result := '';
  end;

  if Result <> '' then
    Exit;

  LCodRep := CodRepresentanteAtual;
  if LCodRep <= 0 then
    Exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'select coalesce(nom_representante, '''') nom_representante from representante where id = :id';
    Q.ParamByName('id').AsInteger := LCodRep;
    Q.Open;
    if not Q.Eof then
      Result := Trim(Q.FieldByName('nom_representante').AsString);
  finally
    Q.Free;
  end;
end;

function TfrmVisitaHistorico.KmRodadoPeriodo(const APeriodo: string): Double;
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
    Q.SQL.Text :=
      'select latitude, longitude from representante_localizacao ' +
      ' where 1 = 1 ';
    if LCodRep > 0 then
      Q.SQL.Text := Q.SQL.Text + ' and cod_representante = :cod_rep ';
    if APeriodo <> '' then
      Q.SQL.Text := Q.SQL.Text + ' and date(datahora) = :data_ref ';
    Q.SQL.Text := Q.SQL.Text +
      ' order by datahora, id';

    if LCodRep > 0 then
      Q.ParamByName('cod_rep').AsInteger := LCodRep;
    if APeriodo <> '' then
      Q.ParamByName('data_ref').AsString := APeriodo;
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

procedure TfrmVisitaHistorico.PopularPeriodo;
var
  I: Integer;
  LHoje: TDateTime;
  LDiasMes: Integer;
begin
  FAtualizandoFiltros := True;
  try
    LHoje := Date;
    LDiasMes := DaysInAMonth(YearOf(LHoje), MonthOf(LHoje));
    CbPeriodo.Items.Clear;
    for I := 1 to LDiasMes do
      CbPeriodo.Items.Add(FormatDateTime('dd/mm/yyyy', EncodeDate(YearOf(LHoje), MonthOf(LHoje), I)));
    CbPeriodo.ItemIndex := DayOf(LHoje) - 1;
  finally
    FAtualizandoFiltros := False;
  end;
end;

function TfrmVisitaHistorico.PeriodoSqlFiltro: string;
var
  LPeriodo: string;
  LData: TDateTime;
begin
  Result := '';
  if Assigned(CbPeriodo) and (CbPeriodo.ItemIndex >= 0) then
  begin
    LPeriodo := Trim(CbPeriodo.Items[CbPeriodo.ItemIndex]);
    if TryStrToDate(LPeriodo, LData) then
      Result := FormatDateTime('yyyy-mm-dd', LData);
  end;
end;


procedure TfrmVisitaHistorico.ApplyResponsiveLayout;
var
  LIsLandscape: Boolean;
  LPad: Single;
  LGap: Single;
  LBottomSafe: Single;
  LContentW: Single;
  LContentX: Single;
  LTop: Single;
  LFooterH: Single;
  LResumoW: Single;
  LListaX: Single;
  LListaW: Single;
  LBtnW: Single;
  LBtnH: Single;
  LBtnGap: Single;
begin
  if (Width <= 0) or (Height <= 0) then
    Exit;

  LIsLandscape := Width > Height;
  LPad := IfThen(LIsLandscape, 28, 18);
  LGap := IfThen(LIsLandscape, 12, 14);
  LBottomSafe := AndroidBottomSafeMargin(LIsLandscape);

  TopBar.Align := TAlignLayout.None;
  TopBar.SetBounds(0, 0, Width, IfThen(LIsLandscape, 62, 104));
  LbTitulo.SetBounds(26, IfThen(LIsLandscape, 12, 32), Width - 52, 34);
  LbTitulo.TextSettings.Font.Size := IfThen(LIsLandscape, 23, 30);
  LbSubtitulo.SetBounds(28, LbTitulo.Position.Y + 30, Width - 56, 20);
  LbSubtitulo.TextSettings.Font.Size := IfThen(LIsLandscape, 12, 14);

  LFooterH := IfThen(LIsLandscape, 52, 74);
  lbottom.Align := TAlignLayout.None;
  lbottom.SetBounds(0, Height - LFooterH - LBottomSafe, Width, LFooterH);
  LyVoltar.SetBounds(12, 0, 96, lbottom.Height);
  LBtnW := IfThen(LIsLandscape, 142, 92);
  LBtnH := IfThen(LIsLandscape, 40, 42);
  LBtnGap := IfThen(LIsLandscape, 12, 8);
  BtnCompartilhar.SetBounds(Width - LBtnW - 14, (lbottom.Height - LBtnH) / 2, LBtnW, LBtnH);
  BtnImprimir.SetBounds(BtnCompartilhar.Position.X - LBtnW - LBtnGap, BtnCompartilhar.Position.Y, LBtnW, LBtnH);
  BtnMapa.SetBounds(BtnImprimir.Position.X - LBtnW - LBtnGap, BtnImprimir.Position.Y, LBtnW, LBtnH);

  LContentW := Width - (LPad * 2);
  if LContentW > 920 then
    LContentW := 920;
  LContentX := (Width - LContentW) / 2;
  LTop := TopBar.Height + LGap;

  CardFiltro.Align := TAlignLayout.None;
  CardFiltro.SetBounds(LContentX, LTop, LContentW, IfThen(LIsLandscape, 82, 150));
  LbBuscar.SetBounds(20, 10, 240, 20);
  if LIsLandscape then
  begin
    EdBuscar.SetBounds(20, 38, Max(200, CardFiltro.Width - 454), 30);
    CbPeriodo.SetBounds(CardFiltro.Width - 424, 38, 170, 32);
    BtnBuscar.SetBounds(CardFiltro.Width - 62, 32, 42, 42);
  end
  else
  begin
    EdBuscar.SetBounds(20, 38, CardFiltro.Width - 40, 30);
    CbPeriodo.SetBounds(20, 86, 170, 32);
    BtnBuscar.SetBounds(CardFiltro.Width - 62, 82, 42, 42);
  end;

  LTop := CardFiltro.Position.Y + CardFiltro.Height + LGap;

  if LIsLandscape then
  begin
    LResumoW := Max(250, LContentW * 0.34);
    CardResumo.SetBounds(LContentX, LTop, LResumoW, lbottom.Position.Y - LTop - 8);
    LListaX := CardResumo.Position.X + CardResumo.Width + LGap;
    LListaW := LContentW - LResumoW - LGap;
    CardLista.SetBounds(LListaX, LTop, LListaW, CardResumo.Height);
  end
  else
  begin
    CardResumo.SetBounds(LContentX, LTop, LContentW, 100);
    CardLista.SetBounds(LContentX, CardResumo.Position.Y + CardResumo.Height + LGap,
      LContentW, lbottom.Position.Y - (CardResumo.Position.Y + CardResumo.Height + LGap + 8));
  end;

  LbResumoTitulo.SetBounds(18, 12, CardResumo.Width - 36, 20);
  LbTotalVisitasTitulo.SetBounds(18, IfThen(LIsLandscape, 45, 42), CardResumo.Width * 0.45, 18);
  LbTotalVisitasValor.SetBounds(18, LbTotalVisitasTitulo.Position.Y + 20, CardResumo.Width * 0.45, 28);
  LbComVendaTitulo.SetBounds(CardResumo.Width * 0.38, LbTotalVisitasTitulo.Position.Y, CardResumo.Width * 0.28, 18);
  LbComVendaValor.SetBounds(LbComVendaTitulo.Position.X, LbTotalVisitasValor.Position.Y, CardResumo.Width * 0.28, 28);
  LbSemVendaTitulo.SetBounds(CardResumo.Width * 0.68, LbTotalVisitasTitulo.Position.Y, CardResumo.Width * 0.28, 18);
  LbSemVendaValor.SetBounds(LbSemVendaTitulo.Position.X, LbTotalVisitasValor.Position.Y, CardResumo.Width * 0.28, 28);

  LbListaTitulo.SetBounds(14, 10, CardLista.Width - 28, 22);
  LvHistorico.SetBounds(8, 36, CardLista.Width - 16, CardLista.Height - 42);
  if LvHistorico.Height < 100 then
    LvHistorico.Height := 100;
  LvHistorico.ItemAppearance.ItemHeight := IfThen(LIsLandscape, 52, 56);
  LvHistorico.ItemAppearance.ItemEditHeight := LvHistorico.ItemAppearance.ItemHeight;
  LvHistorico.ItemAppearanceObjects.ItemObjects.Text.Font.Size := IfThen(LIsLandscape, 10, 11);
  LvHistorico.ItemAppearanceObjects.ItemObjects.Text.Height := 34;
  LvHistorico.ItemAppearanceObjects.ItemObjects.Text.PlaceOffset.X := 28;
  LvHistorico.ItemAppearanceObjects.ItemObjects.Text.PlaceOffset.Y := 6;
  LvHistorico.ItemAppearanceObjects.ItemObjects.Text.Width := LvHistorico.Width - 58;
  LvHistorico.ItemAppearanceObjects.ItemObjects.Text.WordWrap := True;
  LvHistorico.ItemAppearanceObjects.ItemObjects.Detail.Font.Size := IfThen(LIsLandscape, 8, 9);
  LvHistorico.ItemAppearanceObjects.ItemObjects.Detail.Height := 20;
  LvHistorico.ItemAppearanceObjects.ItemObjects.Detail.PlaceOffset.X := 28;
  LvHistorico.ItemAppearanceObjects.ItemObjects.Detail.PlaceOffset.Y := 32;
  LvHistorico.ItemAppearanceObjects.ItemObjects.Detail.Width := LvHistorico.Width - 58;
  LvHistorico.ItemAppearanceObjects.ItemObjects.Detail.WordWrap := False;
  LvHistorico.ItemAppearanceObjects.ItemObjects.Image.Visible := True;
  LvHistorico.ItemAppearanceObjects.ItemObjects.Image.Width := 18;
  LvHistorico.ItemAppearanceObjects.ItemObjects.Image.Height := LvHistorico.ItemAppearance.ItemHeight;
  LvHistorico.ItemAppearanceObjects.ItemObjects.Image.PlaceOffset.X := 4;
  LvHistorico.ItemAppearanceObjects.ItemObjects.Image.PlaceOffset.Y := 0;
  LvHistorico.ItemAppearanceObjects.ItemObjects.Accessory.Visible := False;
end;

procedure TfrmVisitaHistorico.ListarHistorico;
var
  Q: TFDQuery;
  LSql: string;
  LBusca: string;
  LPeriodo: string;
  LItem: TListViewItem;
  LTotal: Integer;
  LComVenda: Integer;
  LSemVenda: Integer;
  LVendeu: string;
  LStatusVisita: string;
  LValor: Double;
  LDataHora: string;
  LNome: string;
  LKmRodado: Double;
  LResumoLinha: string;
  LCor: string;
  procedure PintarMarcador(AItem: TListViewItem; const ACor: string);
  var
    LColor: TAlphaColor;
  begin
    if ACor = '#119C6A' then
      LColor := $FF119C6A
    else if ACor = '#E03131' then
      LColor := $FFE03131
    else if ACor = '#2F6BFF' then
      LColor := $FF2F6BFF
    else
      LColor := $FF667085;

    AItem.Bitmap.SetSize(18, LvHistorico.ItemAppearance.ItemHeight);
    AItem.Bitmap.Clear(TAlphaColors.Null);
    if AItem.Bitmap.Canvas.BeginScene then
    try
      AItem.Bitmap.Canvas.Stroke.Kind := TBrushKind.Solid;
      AItem.Bitmap.Canvas.Stroke.Color := $FFD9E2EF;
      AItem.Bitmap.Canvas.Stroke.Thickness := 1;
      AItem.Bitmap.Canvas.DrawLine(PointF(6, 0), PointF(6, AItem.Bitmap.Height), 1);
      AItem.Bitmap.Canvas.Fill.Color := LColor;
      AItem.Bitmap.Canvas.FillEllipse(RectF(1, 12, 11, 22), 1);
    finally
      AItem.Bitmap.Canvas.EndScene;
    end;
  end;
begin
  LTotal := 0;
  LComVenda := 0;
  LSemVenda := 0;
  LvHistorico.Items.Clear;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    LBusca := UpperCase(Trim(EdBuscar.Text));
    LPeriodo := PeriodoSqlFiltro;
    LKmRodado := KmRodadoPeriodo(LPeriodo);

    LSql :=
      'select v.cod_cliente, coalesce(c.nom_cliente, ''CLIENTE '' || v.cod_cliente) nom_cliente, ' +
      '       coalesce(v.vendeu, '''') vendeu, coalesce(v.enviado, '''') enviado, ' +
      '       coalesce(v.status_visita, '''') status_visita, ' +
      '       coalesce(v.valor_pedido, 0) valor_pedido, coalesce(v.datahora, '''') datahora, coalesce(v.data, '''') data ' +
      '  from cliente_visitas v ' +
      '  left join cliente c on c.cod_cliente = v.cod_cliente ' +
      ' where 1 = 1 ';

    if LPeriodo <> '' then
      LSql := LSql +
        ' and (date(v.datahora) = :data_ref ' +
        '   or substr(v.data, 1, 10) = :data_ref ' +
        '   or substr(v.data, 7, 4) || ''-'' || substr(v.data, 4, 2) || ''-'' || substr(v.data, 1, 2) = :data_ref) ';

    if LBusca <> '' then
      LSql := LSql + ' and (upper(coalesce(c.nom_cliente, '''')) like :busca or cast(v.cod_cliente as text) like :busca) ';

    LSql := LSql + ' order by v.datahora desc limit 300';
    Q.SQL.Text := LSql;

    if LPeriodo <> '' then
      Q.ParamByName('data_ref').AsString := LPeriodo;
    if LBusca <> '' then
      Q.ParamByName('busca').AsString := '%' + LBusca + '%';

    Q.Open;
    while not Q.Eof do
    begin
      Inc(LTotal);
      LVendeu := UpperCase(Trim(SafeFieldAsString(Q, 'vendeu')));
      if LVendeu = 'S' then
        Inc(LComVenda)
      else
        Inc(LSemVenda);

      LNome := SafeFieldAsString(Q, 'nom_cliente');
      LValor := SafeFieldAsFloat(Q, 'valor_pedido');
      LDataHora := FormatarDataHora(SafeFieldAsString(Q, 'datahora'));
      LStatusVisita := Trim(SafeFieldAsString(Q, 'status_visita'));
      if LStatusVisita = '' then
      begin
        if LVendeu = 'S' then
          LStatusVisita := 'Venda'
        else
          LStatusVisita := 'Sem venda';
      end;

      LItem := LvHistorico.Items.Add;
      LResumoLinha := TextoTimeline(LStatusVisita, LVendeu, LValor);
      LCor := CorTimeline(LStatusVisita, LVendeu, LValor);
      PintarMarcador(LItem, LCor);
      LItem.Text := Copy(LDataHora, 1, 5) + ' ' + Copy(LDataHora, 12, 5) + sLineBreak + LNome;
      LItem.Detail := LResumoLinha;
      Q.Next;
    end;
  finally
    Q.Free;
  end;

  LbTotalVisitasValor.Text := IntToStr(LTotal);
  LbComVendaValor.Text := IntToStr(LComVenda);
  LbSemVendaValor.Text := IntToStr(LSemVenda);
  LbListaTitulo.Text := 'Historico - ' + IntToStr(LTotal) + ' visitas | ' + TextoKmRodado(LKmRodado);
end;

procedure TfrmVisitaHistorico.FormShow(Sender: TObject);
begin
  UseAndroidSafeComboPicker([CbPeriodo]);
  PopularPeriodo;
  ApplyResponsiveLayout;
  ListarHistorico;
end;

procedure TfrmVisitaHistorico.FormResize(Sender: TObject);
begin
  ApplyResponsiveLayout;
end;

procedure TfrmVisitaHistorico.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
  frmVisitaHistorico := nil;
end;

procedure TfrmVisitaHistorico.BtnBuscarClick(Sender: TObject);
begin
  if FAtualizandoFiltros then
    Exit;

  ListarHistorico;
end;

function TfrmVisitaHistorico.GerarRelatorioHtmlPdf(ACompartilhar: Boolean): string;
var
  Q: TFDQuery;
  LSql: string;
  LBusca: string;
  LPeriodo: string;
  LDataTitulo: string;
  LHtmlFile: string;
  LPdfFile: string;
  LHtml: TStringList;
  LConteudo: TStringList;
  LTotal: Integer;
  LComVenda: Integer;
  LSemVenda: Integer;
  LVendeu: string;
  LStatusVisita: string;
  LValor: Double;
  LDataHora: string;
  LNome: string;
  LKmRodado: Double;
  LResumoLinha: string;
  LCor: string;
  LNomeArquivo: string;
  LRepresentante: string;
  LPdfContent: string;
  LY: Integer;
{$IFDEF ANDROID}
  LIntent: JIntent;
  LUri: Jnet_Uri;
{$ENDIF}
  function HtmlEncode(const S: string): string;
  begin
    Result := StringReplace(S, '&', '&amp;', [rfReplaceAll]);
    Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
    Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
    Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  end;
  function EscPDF(const S: string): string;
  begin
    Result := StringReplace(S, '\', '\\', [rfReplaceAll]);
    Result := StringReplace(Result, '(', '\(', [rfReplaceAll]);
    Result := StringReplace(Result, ')', '\)', [rfReplaceAll]);
  end;
  procedure AddPdfText(var AContent: string; AX, AY, ASize: Integer; const AText: string; ABold: Boolean = False);
  begin
    if ABold then
      AContent := AContent + Format('BT /F2 %d Tf 1 0 0 1 %d %d Tm (%s) Tj ET', [ASize, AX, AY, EscPDF(AText)]) + sLineBreak
    else
      AContent := AContent + Format('BT /F1 %d Tf 1 0 0 1 %d %d Tm (%s) Tj ET', [ASize, AX, AY, EscPDF(AText)]) + sLineBreak;
  end;
  procedure AddPdfColor(var AContent: string; const AHexColor: string);
  begin
    if AHexColor = '#119C6A' then
      AContent := AContent + '0.067 0.612 0.416 rg' + sLineBreak
    else if AHexColor = '#E03131' then
      AContent := AContent + '0.878 0.192 0.192 rg' + sLineBreak
    else if AHexColor = '#2F6BFF' then
      AContent := AContent + '0.184 0.420 1 rg' + sLineBreak
    else
      AContent := AContent + '0.400 0.439 0.522 rg' + sLineBreak;
  end;
  procedure SaveTextAsPdf(const AFileName: string; ALines: TStrings);
  var
    I: Integer;
    LStream: TStringList;
    LContent: string;
    LContentLen: Integer;
    LOffsets: array[1..6] of Integer;
    procedure AddRaw(const S: string);
    begin
      LStream.Add(S);
    end;
    function StreamPos: Integer;
    var
      J: Integer;
    begin
      Result := 0;
      for J := 0 to LStream.Count - 1 do
        Inc(Result, Length(AnsiString(LStream[J])) + 2);
    end;
  begin
    LStream := TStringList.Create;
    try
      LContent := ALines.Text;
      LContentLen := Length(AnsiString(StringReplace(LContent, sLineBreak, #10, [rfReplaceAll])));

      AddRaw('%PDF-1.4');
      LOffsets[1] := StreamPos; AddRaw('1 0 obj<< /Type /Catalog /Pages 2 0 R >>endobj');
      LOffsets[2] := StreamPos; AddRaw('2 0 obj<< /Type /Pages /Kids [3 0 R] /Count 1 >>endobj');
      LOffsets[3] := StreamPos; AddRaw('3 0 obj<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R /F2 6 0 R >> >> >>endobj');
      LOffsets[4] := StreamPos;
      AddRaw(Format('4 0 obj<< /Length %d >>stream', [LContentLen]));
      AddRaw(StringReplace(LContent, sLineBreak, #10, [rfReplaceAll]));
      AddRaw('endstream endobj');
      LOffsets[5] := StreamPos; AddRaw('5 0 obj<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>endobj');
      LOffsets[6] := StreamPos; AddRaw('6 0 obj<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>endobj');
      AddRaw('xref');
      AddRaw('0 7');
      AddRaw('0000000000 65535 f ');
      for I := 1 to 6 do
        AddRaw(Format('%.10d 00000 n ', [LOffsets[I]]));
      AddRaw('trailer<< /Size 7 /Root 1 0 R >>');
      AddRaw(Format('startxref%s%d', [sLineBreak, StreamPos]));
      AddRaw('%%EOF');
      LStream.SaveToFile(AFileName, TEncoding.ASCII);
    finally
      LStream.Free;
    end;
  end;
begin
  Result := '';
  LPeriodo := PeriodoSqlFiltro;
  LBusca := UpperCase(Trim(EdBuscar.Text));
  LKmRodado := KmRodadoPeriodo(LPeriodo);
  LRepresentante := NomeRepresentanteAtual;
  LTotal := 0;
  LComVenda := 0;
  LSemVenda := 0;
  LDataTitulo := LPeriodo;
  if LDataTitulo <> '' then
    LDataTitulo := Copy(LDataTitulo, 9, 2) + '/' + Copy(LDataTitulo, 6, 2) + '/' + Copy(LDataTitulo, 1, 4)
  else
    LDataTitulo := FormatDateTime('dd/mm/yyyy', Date);

  LNomeArquivo := 'visitas_historico_' + FormatDateTime('yyyymmdd_hhnnss', Now);
  LHtmlFile := IncludeTrailingPathDelimiter(GetPdfOutputDir) + LNomeArquivo + '.html';
  LPdfFile := IncludeTrailingPathDelimiter(GetPdfOutputDir) + LNomeArquivo + '.pdf';
  LHtml := TStringList.Create;
  LConteudo := TStringList.Create;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    LSql :=
      'select v.cod_cliente, coalesce(c.nom_cliente, ''CLIENTE '' || v.cod_cliente) nom_cliente, ' +
      '       coalesce(v.vendeu, '''') vendeu, coalesce(v.enviado, '''') enviado, ' +
      '       coalesce(v.status_visita, '''') status_visita, ' +
      '       coalesce(v.valor_pedido, 0) valor_pedido, coalesce(v.datahora, '''') datahora, coalesce(v.data, '''') data ' +
      '  from cliente_visitas v ' +
      '  left join cliente c on c.cod_cliente = v.cod_cliente ' +
      ' where 1 = 1 ';

    if LPeriodo <> '' then
      LSql := LSql +
        ' and (date(v.datahora) = :data_ref ' +
        '   or substr(v.data, 1, 10) = :data_ref ' +
        '   or substr(v.data, 7, 4) || ''-'' || substr(v.data, 4, 2) || ''-'' || substr(v.data, 1, 2) = :data_ref) ';

    if LBusca <> '' then
      LSql := LSql + ' and (upper(coalesce(c.nom_cliente, '''')) like :busca or cast(v.cod_cliente as text) like :busca) ';

    LSql := LSql + ' order by v.datahora desc limit 300';
    Q.SQL.Text := LSql;
    if LPeriodo <> '' then
      Q.ParamByName('data_ref').AsString := LPeriodo;
    if LBusca <> '' then
      Q.ParamByName('busca').AsString := '%' + LBusca + '%';
    Q.Open;

    LHtml.Add('<!doctype html><html><head><meta charset="utf-8">');
    LHtml.Add('<style>');
    LHtml.Add('body{font-family:Arial,sans-serif;color:#101828;margin:24px;}');
    LHtml.Add('h1{font-size:22px;margin:0 0 4px;} .sub{color:#667085;margin-bottom:18px;}');
    LHtml.Add('.timeline{border-left:2px solid #d9e2ef;margin-left:8px;padding-left:16px;}');
    LHtml.Add('.item{position:relative;margin:0 0 18px 0;page-break-inside:avoid;}');
    LHtml.Add('.dot{position:absolute;left:-22px;top:3px;width:10px;height:10px;border-radius:50%;background:#667085;}');
    LHtml.Add('.dt{font-size:12px;color:#667085;font-weight:bold;margin-bottom:2px;}');
    LHtml.Add('.cli{font-size:14px;font-weight:bold;color:#101828;}');
    LHtml.Add('.det{font-size:12px;color:#667085;margin-top:2px;}');
    LHtml.Add('.resumo{margin:16px 0 18px;font-weight:bold;}');
    LHtml.Add('</style></head><body>');
    LHtml.Add('<h1>Linha do tempo</h1>');
    LHtml.Add('<div class="sub">Periodo: ' + HtmlEncode(LDataTitulo) + '</div>');
    if LRepresentante <> '' then
      LHtml.Add('<div class="sub">Representante: ' + HtmlEncode(LRepresentante) + '</div>');
    LHtml.Add('<div class="timeline">');

    LPdfContent := '';
    AddPdfText(LPdfContent, 36, 800, 18, 'Linha do tempo', True);
    AddPdfText(LPdfContent, 36, 780, 10, 'Periodo: ' + LDataTitulo);
    if LRepresentante <> '' then
      AddPdfText(LPdfContent, 36, 766, 10, 'Representante: ' + LRepresentante);
    LPdfContent := LPdfContent + '0.851 0.886 0.937 RG 1 w 48 170 m 48 744 l S' + sLineBreak;
    LY := 730;

    while not Q.Eof do
    begin
      Inc(LTotal);
      LVendeu := UpperCase(Trim(SafeFieldAsString(Q, 'vendeu')));
      if LVendeu = 'S' then
        Inc(LComVenda)
      else
        Inc(LSemVenda);

      LNome := SafeFieldAsString(Q, 'nom_cliente');
      LValor := SafeFieldAsFloat(Q, 'valor_pedido');
      LDataHora := FormatarDataHora(SafeFieldAsString(Q, 'datahora'));
      LStatusVisita := Trim(SafeFieldAsString(Q, 'status_visita'));
      if LStatusVisita = '' then
      begin
        if LVendeu = 'S' then
          LStatusVisita := 'Venda'
        else
          LStatusVisita := 'Sem venda';
      end;

      LResumoLinha := TextoTimeline(LStatusVisita, LVendeu, LValor);
      LCor := CorTimeline(LStatusVisita, LVendeu, LValor);
      LHtml.Add('<div class="item"><span class="dot" style="background:' + LCor + '"></span>');
      LHtml.Add('<div class="dt">' + HtmlEncode(Copy(LDataHora, 1, 5) + ' ' + Copy(LDataHora, 12, 5)) + '</div>');
      LHtml.Add('<div class="cli">' + HtmlEncode(LNome) + '</div>');
      LHtml.Add('<div class="det">' + HtmlEncode(LResumoLinha) + '</div></div>');

      if LY > 170 then
      begin
        AddPdfColor(LPdfContent, LCor);
        LPdfContent := LPdfContent + Format('44 %d 8 8 re f', [LY - 2]) + sLineBreak;
        LPdfContent := LPdfContent + '0.400 0.439 0.522 rg' + sLineBreak;
        AddPdfText(LPdfContent, 64, LY, 9, Copy(LDataHora, 1, 5) + ' ' + Copy(LDataHora, 12, 5), True);
        LPdfContent := LPdfContent + '0.063 0.094 0.157 rg' + sLineBreak;
        AddPdfText(LPdfContent, 64, LY - 14, 11, Copy(SafeFieldAsString(Q, 'cod_cliente') + ' - ' + LNome, 1, 72), True);
        LPdfContent := LPdfContent + '0.400 0.439 0.522 rg' + sLineBreak;
        AddPdfText(LPdfContent, 64, LY - 28, 9, Copy(LResumoLinha, 1, 90));
        Dec(LY, 38);
      end;
      Q.Next;
    end;

    LHtml.Add('</div>');
    LHtml.Add('<div class="resumo">Total: ' + IntToStr(LTotal) +
      ' &nbsp; Com venda: ' + IntToStr(LComVenda) +
      ' &nbsp; Sem venda: ' + IntToStr(LSemVenda) +
      ' &nbsp; Km rodado: ' + HtmlEncode(TextoKmRodado(LKmRodado)) + '</div>');
    LHtml.Add('</body></html>');
    LHtml.SaveToFile(LHtmlFile, TEncoding.UTF8);
    Result := LPdfFile;

    LPdfContent := LPdfContent + '0.063 0.094 0.157 rg' + sLineBreak;
    Dec(LY, 14);
    if LY < 120 then
      LY := 120;
    AddPdfText(LPdfContent, 64, LY, 10,
      'Total: ' + IntToStr(LTotal) +
      ' | Com venda: ' + IntToStr(LComVenda) +
      ' | Sem venda: ' + IntToStr(LSemVenda) +
      ' | Km rodado: ' + TextoKmRodado(LKmRodado), True);
    LConteudo.Text := LPdfContent;
    SaveTextAsPdf(LPdfFile, LConteudo);

{$IFDEF MSWINDOWS}
    if ACompartilhar then
      ShellExecute(0, 'open', 'explorer.exe', PChar('/select,"' + LPdfFile + '"'), nil, SW_SHOWNORMAL)
    else
      ShellExecute(0, 'open', PChar(LPdfFile), nil, nil, SW_SHOWNORMAL);
{$ENDIF}
{$IFDEF ANDROID}
    LUri := BuildContentUriForPdf(LPdfFile);
    LIntent := TJIntent.Create;
    if ACompartilhar then
    begin
      LIntent.setAction(TJIntent.JavaClass.ACTION_SEND);
      LIntent.setType(StringToJString('application/pdf'));
      LIntent.putExtra(TJIntent.JavaClass.EXTRA_STREAM, JParcelable(LUri));
      LIntent.addFlags(TJIntent.JavaClass.FLAG_ACTIVITY_NEW_TASK);
      LIntent.addFlags(TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION);
      TAndroidHelper.Activity.startActivity(
        TJIntent.JavaClass.createChooser(LIntent, StrToJCharSequence('Compartilhar historico'))
      );
    end
    else
    begin
      LIntent.setAction(TJIntent.JavaClass.ACTION_VIEW);
      LIntent.setDataAndType(LUri, StringToJString('application/pdf'));
      LIntent.addFlags(TJIntent.JavaClass.FLAG_ACTIVITY_NEW_TASK);
      LIntent.addFlags(TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION);
      TAndroidHelper.Activity.startActivity(LIntent);
    end;
{$ENDIF}
  finally
    Q.Free;
    LConteudo.Free;
    LHtml.Free;
  end;
end;

procedure TfrmVisitaHistorico.BtnMapaClick(Sender: TObject);
begin
  {$IFDEF ANDROID}
  if not Assigned(frmVisitaHistoricoMapa) then
    Application.CreateForm(TfrmVisitaHistoricoMapa, frmVisitaHistoricoMapa);
  frmVisitaHistoricoMapa.Show;
  frmVisitaHistoricoMapa.CarregarRastreamento(CbPeriodo.Text);
  {$ENDIF}
end;
procedure TfrmVisitaHistorico.BtnCompartilharClick(Sender: TObject);
begin
  GerarRelatorioHtmlPdf(True);
end;

procedure TfrmVisitaHistorico.BtnImprimirClick(Sender: TObject);
begin
  GerarRelatorioHtmlPdf(False);
end;
procedure TfrmVisitaHistorico.ImgVoltarClick(Sender: TObject);
begin
  Close;
end;

end.
