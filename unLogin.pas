unit unLogin;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Math,
  System.JSON,
  FireDAC.Comp.Client,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.ListBox,
  FMX.Ani, unFuncoes;

type
  TfrmLogin = class(TForm)
    LayoutRoot: TLayout;
    BackgroundRect: TRectangle;
    TopBar: TRectangle;
    Card: TRectangle;
    LbSubtitulo: TLabel;
    CbBaseUrl: TComboBox;
    EdLogin: TEdit;
    EdSenha: TEdit;
    BtnEntrar: TRectangle;
    LbBtnEntrar: TLabel;
    LbStatus: TLabel;
    RectAnimation1: TRectAnimation;
    lbottom: TLayout;
    lySaidas: TLayout;
    rSaidas: TRectangle;
    ImSaidas: TImage;
    lbSaidas: TLabel;
    lySair: TLayout;
    rSair: TRectangle;
    imSair: TImage;
    lbSair: TLabel;
    Layout1: TLayout;
    Image1: TImage;
    procedure BtnEntrarClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure imSairClick(Sender: TObject);
    procedure CbBaseUrlChange(Sender: TObject);
  private
    FAutoSessionChecked: Boolean;
    FLbVersao: TLabel;
    procedure EnsureVersionLabel;
    procedure AtualizarStatus(const AText: string; AError: Boolean = False);
    function BaseUrlSelecionada: string;
    function RotuloParaApiUrl(const ARotuloOuUrl: string): string;
    function ApiUrlParaRotulo(const AUrl: string): string;
    procedure ApplyOrientationLayout;
    procedure EnsurePrincipalForm;
    procedure MostrarPrincipalOuRestaurar;
    function NormalizeApiError(const AMessage: string): string;
    function HasLocalData: Boolean;
    function GetCachedUser(const ALogin: string): TJSONObject;
    function GetSavedPassword: string;
    function SessionBaseMatchesSelectedBase: Boolean;
    function IsManualLogoutPending: Boolean;
  public
  end;

var
  frmLogin: TfrmLogin;

implementation

{$R *.fmx}
{$R *.LgXhdpiPh.fmx ANDROID}
{$R *.LgXhdpiTb.fmx ANDROID}
{$R *.NmXhdpiPh.fmx ANDROID}

uses
  unDMApp,
  unPrincipal,
  unPedido,
  unPedidoItem,
  unClientes,
  unPedidosDigitados,
  unPedidosEnviados,
  unFormaPgto,
  unPrazoPgto,
  unClienteCadastro,
  unCidadeBusca,
  unAndroidComboFix;

procedure TfrmLogin.EnsureVersionLabel;
begin
  if not Assigned(FLbVersao) then
  begin
    FLbVersao := TLabel.Create(Self);
    FLbVersao.Parent := lbottom;
    FLbVersao.Align := TAlignLayout.None;
    FLbVersao.StyledSettings := [];
    FLbVersao.TextSettings.Font.Size := 11;
    FLbVersao.TextSettings.FontColor := $FF6B7280;
    FLbVersao.TextSettings.HorzAlign := TTextAlign.Leading;
    FLbVersao.TextSettings.VertAlign := TTextAlign.Center;
    FLbVersao.HitTest := False;
  end;
  FLbVersao.Text := 'Versao ' + AppVersionName;
  FLbVersao.Visible := True;
  FLbVersao.BringToFront;
end;
procedure TfrmLogin.AtualizarStatus(const AText: string; AError: Boolean);
begin
  LbStatus.Text := AText;
  if AError then
    LbStatus.TextSettings.FontColor := $FFB42318
  else
    LbStatus.TextSettings.FontColor := $FF1D2939;
end;

function TfrmLogin.BaseUrlSelecionada: string;
begin
  if CbBaseUrl.ItemIndex >= 0 then
    Result := CbBaseUrl.Items[CbBaseUrl.ItemIndex]
  else
    Result := Trim(CbBaseUrl.Text);

  Result := RotuloParaApiUrl(Result);

//  Result := 'http://localhost:9000';

end;

function TfrmLogin.RotuloParaApiUrl(const ARotuloOuUrl: string): string;
var
  LValor: string;
begin
  LValor := Trim(ARotuloOuUrl);
  if SameText(LValor, 'PLASFAN') then
    Exit('http://plasfan.ddns.com.br:9004');
  if SameText(LValor, 'FILHO DO CRIADOR') then
    Exit('http://plasfan.ddns.com.br:9000');
  Result := LValor;
end;

function TfrmLogin.ApiUrlParaRotulo(const AUrl: string): string;
var
  LUrl: string;
begin
  LUrl := Trim(AUrl);
  if SameText(LUrl, 'http://plasfan.ddns.com.br:9004') then
    Exit('PLASFAN');
  if SameText(LUrl, 'http://plasfan.ddns.com.br:9000') then
    Exit('FILHO DO CRIADOR');
  Result := LUrl;
end;

procedure TfrmLogin.EnsurePrincipalForm;
begin
  if not Assigned(frmPrincipal) then
    Application.CreateForm(TfrmPrincipal, frmPrincipal);
  if not Assigned(frmClientes) then
    Application.CreateForm(TfrmClientes, frmClientes);
  if not Assigned(frmPedido) then
    Application.CreateForm(TfrmPedido, frmPedido);
  if not Assigned(frmPedidoItem) then
    Application.CreateForm(TfrmPedidoItem, frmPedidoItem);
  if not Assigned(frmPedidosDigitados) then
    Application.CreateForm(TfrmPedidosDigitados, frmPedidosDigitados);
  if not Assigned(frmPedidosEnviados) then
    Application.CreateForm(TfrmPedidosEnviados, frmPedidosEnviados);
  if not Assigned(frmFormaPgto) then
    Application.CreateForm(TfrmFormaPgto, frmFormaPgto);
  if not Assigned(frmPrazoPgto) then
    Application.CreateForm(TfrmPrazoPgto, frmPrazoPgto);
  if not Assigned(frmClienteCadastro) then
    Application.CreateForm(TfrmClienteCadastro, frmClienteCadastro);
  if not Assigned(frmCidadeBusca) then
    Application.CreateForm(TfrmCidadeBusca, frmCidadeBusca);
end;

procedure TfrmLogin.MostrarPrincipalOuRestaurar;
var
  LScreen: string;
  LExtraJson: string;
  LPedidoId: Integer;
begin
  EnsurePrincipalForm;
  frmPrincipal.Show;
  Application.ProcessMessages;

  if Assigned(dmApp) and dmApp.GetAppState(LScreen, LPedidoId, LExtraJson) then
  begin
    if (SameText(LScreen, 'pedido') or SameText(LScreen, 'pedido_item')) and (LPedidoId > 0) then
    begin
      if not Assigned(frmPedido) then
        Application.CreateForm(TfrmPedido, frmPedido);
      frmPedido.CarregarPedidoDigitado(LPedidoId);
      if frmPedido.outboundPedidoId = LPedidoId then
      begin
        if SameText(LScreen, 'pedido_item') then
          frmPedido.RestaurarPedidoItem(LExtraJson)
        else
          frmPedido.Show;
        Hide;
        Exit;
      end;
      dmApp.ClearAppState(LScreen);
    end
    else
      dmApp.ClearAppState(LScreen);
  end;

  Hide;
end;
procedure TfrmLogin.CbBaseUrlChange(Sender: TObject);
begin
  if not SessionBaseMatchesSelectedBase then
  begin
    EdLogin.Text := '';
    EdSenha.Text := '';
    AtualizarStatus('');
  end;
end;

procedure TfrmLogin.BtnEntrarClick(Sender: TObject);
var
  LResponse: TJSONObject;
  LMsg: string;
  LCached: TJSONObject;
  LSenha: string;
  LSenhaSalva: string;
begin
  if Trim(BaseUrlSelecionada) = '' then
  begin
    AtualizarStatus('Informe a URL da API.', True);
    Exit;
  end;

  if Trim(EdLogin.Text) = '' then
  begin
    AtualizarStatus('Informe o login.', True);
    Exit;
  end;

  dmApp.ApiBaseUrl := Trim(BaseUrlSelecionada);

  LSenha := Trim(EdSenha.Text);
  LSenhaSalva := Trim(GetSavedPassword);
  if (LSenha = '') and (LSenhaSalva <> '') then
  begin
    LSenha := LSenhaSalva;
    EdSenha.Text := LSenha;
  end;

  if LSenha = '' then
  begin
    AtualizarStatus('Informe a senha.', True);
    Exit;
  end;

  if HasLocalData then
  begin
    LCached := GetCachedUser(Trim(EdLogin.Text));
    if Assigned(LCached) then
    begin
      try
        if (LSenhaSalva <> '') and SameText(LSenha, LSenhaSalva) then
        begin
          dmApp.SetAppConfigValue('login_saida_manual', '0');
          EnsurePrincipalForm;
          frmPrincipal.AtualizarContextoUsuario(LCached);
          MostrarPrincipalOuRestaurar;
          Exit;
        end;
      finally
        LCached.Free;
      end;
    end;
  end;

  AtualizarStatus('Autenticando no WorbyRepRest...');
  try
    LResponse := dmApp.Login(Trim(EdLogin.Text), LSenha);
    try
      dmApp.SetAppConfigValue('login_saida_manual', '0');
      EnsurePrincipalForm;
      frmPrincipal.AtualizarContextoUsuario(LResponse);
      MostrarPrincipalOuRestaurar;
    finally
      LResponse.Free;
    end;
  except
    on E: Exception do
    begin
      LMsg := NormalizeApiError(E.Message);
      if SameText(LMsg, 'Usuario ou senha invalidos') then
        LMsg := 'Usuário e Senha Inválidos';
      AtualizarStatus(LMsg, True);
    end;
  end;
end;

procedure TfrmLogin.FormShow(Sender: TObject);
var
  LAtual: string;
  LCached: TJSONObject;
  LLogin: string;
begin
  UseAndroidSafeComboPicker([CbBaseUrl]);
  CbBaseUrl.OnChange := nil;
  CbBaseUrl.Items.Clear;
  CbBaseUrl.Items.Add('PLASFAN');
  LAtual := ApiUrlParaRotulo(dmApp.ApiBaseUrl);
  CbBaseUrl.Items.Add('FILHO DO CRIADOR');
  CbBaseUrl.ItemIndex := CbBaseUrl.Items.IndexOf(LAtual);
  if CbBaseUrl.ItemIndex < 0 then
    CbBaseUrl.ItemIndex := 0;
  CbBaseUrl.OnChange := CbBaseUrlChange;
  if SessionBaseMatchesSelectedBase then
  begin
    EdLogin.Text := dmApp.GetSessionLogin;
    EdSenha.Text := GetSavedPassword;
  end
  else
  begin
    EdLogin.Text := '';
    EdSenha.Text := '';
  end;
  AtualizarStatus('');
  ApplyOrientationLayout;

  if (not IsManualLogoutPending) and Assigned(frmPrincipal) and (frmPrincipal.id_representante > 0) then
  begin
    dmApp.SetAppConfigValue('login_saida_manual', '0');
    MostrarPrincipalOuRestaurar;
    Exit;
  end;

  if not IsManualLogoutPending then
  begin
    if not FAutoSessionChecked then
      FAutoSessionChecked := True;
    LLogin := Trim(EdLogin.Text);
    LCached := GetCachedUser(LLogin);
    if Assigned(LCached) then
    begin
      try
        EnsurePrincipalForm;
        frmPrincipal.AtualizarContextoUsuario(LCached);
        if frmPrincipal.id_representante > 0 then
        begin
          dmApp.SetAppConfigValue('login_saida_manual', '0');
          MostrarPrincipalOuRestaurar;
          Exit;
        end;
      finally
        LCached.Free;
      end;
    end;
  end;
end;

procedure TfrmLogin.FormResize(Sender: TObject);
begin
  ApplyOrientationLayout;
end;

procedure TfrmLogin.ApplyOrientationLayout;
var
  LIsLandscape: Boolean;
  LIsTablet: Boolean;
  LScale: Single;
  LBottomMargin: Single;
  LRightSafe: Single;
  LCardW: Single;
  LCardH: Single;
  LHeaderH: Single;
  LHeaderY: Single;
  LContentTop: Single;
  LContentBottom: Single;
  LContentH: Single;
  LBaseCardW: Single;
  LBaseCardH: Single;
  LInputW: Single;
  LInputX: Single;
  LRightX: Single;
  LRightW: Single;
  LLabel: TLabel;
begin
  LIsLandscape := Width > Height;
  LIsTablet := Min(Width, Height) >= 600;
  LBottomMargin := Max(92, AndroidNavigationInset(False) + 52);
  LRightSafe := 0;
  LBaseCardW := 270;
  LBaseCardH := 316;

  // Cabeçalho responsivo (evita distorção e corte da arte em diferentes telas)
  Image1.Align := TAlignLayout.Client;
  Image1.WrapMode := TImageWrapMode.Fit;
  Image1.HitTest := False;

  lySaidas.Visible := False;
  lySair.Visible := True;
  lbottom.Align := TAlignLayout.None;
  lbottom.Margins.Bottom := 0;
  lbottom.Height := 58;
  lbottom.Width := Width - LRightSafe;
  lbottom.Position.X := 0;
  lbottom.Position.Y := Height - lbottom.Height - LBottomMargin;
  if lbottom.Position.Y < 0 then
    lbottom.Position.Y := Height - lbottom.Height - 12;

  lySair.Align := TAlignLayout.MostRight;
  lySair.Width := 64;
  lySair.Height := lbottom.Height;
  rSair.Height := lySair.Height;
  EnsureVersionLabel;
  FLbVersao.SetBounds(12, (lbottom.Height - 18) / 2, Max(80, lbottom.Width - 92), 18);

  if LIsLandscape then
  begin
    LHeaderH := Height * 0.22;
    if LHeaderH < 68 then
      LHeaderH := 68;
    if LHeaderH > 118 then
      LHeaderH := 118;
    TopBar.Align := TAlignLayout.None;
    TopBar.Width := Width;
    TopBar.Position.X := 0;
    TopBar.Height := LHeaderH;
    LHeaderY := -46;
    TopBar.Position.Y := LHeaderY;
    Layout1.Margins.Top := 0;
    LbSubtitulo.Visible := False;
    LbSubtitulo.Opacity := 0;
    LbStatus.Visible := False;

    Card.Align := TAlignLayout.None;
    Card.Scale.X := 1;
    Card.Scale.Y := 1;
    Card.Width := Min(Width - 160, 520);
    if Card.Width < 420 then
      Card.Width := Min(Width - 48, 420);
    Card.Height := 176;

    LInputX := 24;
    LInputW := Card.Width - 190;
    if LInputW < 230 then
      LInputW := Card.Width - 48;
    if LInputW > 310 then
      LInputW := 310;
    LRightX := LInputX + LInputW + 24;
    LRightW := Card.Width - LRightX - 24;
    if LRightW < 120 then
    begin
      LInputW := Card.Width * 0.58;
      LRightX := LInputX + LInputW + 18;
      LRightW := Card.Width - LRightX - 24;
    end;
    CbBaseUrl.Position.X := LInputX;
    EdLogin.Position.X := LInputX;
    CbBaseUrl.Width := LInputW;
    EdLogin.Width := LInputW;
    LbStatus.Width := Card.Width - 38;

    LbSubtitulo.Position.X := LInputX;
    LbSubtitulo.Position.Y := 20;
    LLabel := FindComponent('LbBaseUrl') as TLabel;
    if Assigned(LLabel) then
    begin
      LLabel.Position.X := LInputX;
      LLabel.Position.Y := 22;
      LLabel.Width := LInputW;
    end;
    LLabel := FindComponent('LbUsuario') as TLabel;
    if Assigned(LLabel) then
    begin
      LLabel.Position.X := LInputX;
      LLabel.Position.Y := 82;
      LLabel.Width := LInputW;
    end;
    LLabel := FindComponent('LbSenha') as TLabel;
    if Assigned(LLabel) then
    begin
      LLabel.Position.X := LRightX;
      LLabel.Position.Y := 22;
      LLabel.Width := LRightW;
    end;
    CbBaseUrl.Position.Y := 44;
    EdLogin.Position.Y := 104;
    EdSenha.Position.X := LRightX;
    EdSenha.Position.Y := 44;
    EdSenha.Width := LRightW;
    BtnEntrar.Position.X := LRightX;
    BtnEntrar.Position.Y := 104;
    BtnEntrar.Width := LRightW;
    BtnEntrar.Height := 38;

    LContentTop := TopBar.Position.Y + TopBar.Height + 6;
    LContentBottom := lbottom.Position.Y - 8;
    LContentH := LContentBottom - LContentTop;

    LCardW := Card.Width;
    LCardH := Card.Height;
    if LContentH < LCardH then
    begin
      Card.Height := Max(154, LContentH);
      BtnEntrar.Position.Y := Card.Height - BtnEntrar.Height - 14;
      LCardH := Card.Height;
    end;

    Card.Position.X := (Width - LCardW) / 2;
    Card.Position.Y := LContentTop + ((LContentH - LCardH) / 2);
    if Card.Position.Y < LContentTop then
      Card.Position.Y := LContentTop;
  end
  else
  begin
    if LIsTablet then
      LHeaderH := Height * 0.15
    else
      LHeaderH := Height * 0.17;
    if LHeaderH < 104 then
      LHeaderH := 104;
    if LHeaderH > 170 then
      LHeaderH := 170;
    TopBar.Align := TAlignLayout.None;
    TopBar.Width := Width;
    TopBar.Position.X := 0;
    TopBar.Height := LHeaderH;
    TopBar.Position.Y := 0;
    Layout1.Margins.Top := 0;

    LbSubtitulo.Visible := True;
    LbSubtitulo.Opacity := 1;
    LbStatus.Visible := True;

    Card.Align := TAlignLayout.None;
    Card.Scale.X := 1;
    Card.Scale.Y := 1;
    Card.Width := Min(Width - 48, 330);
    if Card.Width < 270 then
      Card.Width := Max(Width - 32, 250);
    Card.Height := 316;

    LInputW := Card.Width - 36;
    LInputX := 18;
    LbSubtitulo.Position.X := LInputX;
    LbSubtitulo.Position.Y := 19;
    LLabel := FindComponent('LbBaseUrl') as TLabel;
    if Assigned(LLabel) then
    begin
      LLabel.Position.X := LInputX;
      LLabel.Position.Y := 54;
      LLabel.Width := LInputW;
    end;
    LLabel := FindComponent('LbUsuario') as TLabel;
    if Assigned(LLabel) then
    begin
      LLabel.Position.X := LInputX;
      LLabel.Position.Y := 120;
      LLabel.Width := LInputW;
    end;
    LLabel := FindComponent('LbSenha') as TLabel;
    if Assigned(LLabel) then
    begin
      LLabel.Position.X := LInputX;
      LLabel.Position.Y := 189;
      LLabel.Width := LInputW;
    end;
    CbBaseUrl.Position.X := LInputX;
    CbBaseUrl.Position.Y := 80;
    EdLogin.Position.X := LInputX;
    EdLogin.Position.Y := 144;
    EdSenha.Position.X := LInputX;
    EdSenha.Position.Y := 208;
    BtnEntrar.Position.X := LInputX;
    BtnEntrar.Position.Y := 263;
    BtnEntrar.Height := 42;
    CbBaseUrl.Width := LInputW;
    EdLogin.Width := LInputW;
    EdSenha.Width := LInputW;
    BtnEntrar.Width := LInputW;
    LbStatus.Width := Card.Width - 38;
    LbStatus.Position.Y := Card.Height + 4;

    LContentTop := TopBar.Height + 8;
    LContentBottom := lbottom.Position.Y - 8;
    LContentH := LContentBottom - LContentTop;
    if LContentH < Card.Height then
      Card.Position.Y := LContentTop
    else
      Card.Position.Y := LContentTop + ((LContentH - Card.Height) / 2);
    Card.Position.X := (Width - Card.Width) / 2;
  end;
end;

function TfrmLogin.NormalizeApiError(const AMessage: string): string;
var
  LValue: TJSONValue;
  LObj: TJSONObject;
  LErr: TJSONValue;
  LText: string;
  LStart: Integer;
begin
  Result := AMessage;
  LText := Trim(AMessage);
  if (LText = '') then
    Exit;
  if (Pos('12002', LText) > 0) or
     (Pos('TEMPO LIMITE', UpperCase(LText)) > 0) or
     (Pos('TIMEOUT', UpperCase(LText)) > 0) then
  begin
    Result := 'Tempo limite ao conectar com o servidor.';
    Exit;
  end;
  LStart := Pos('{', LText);
  if LStart = 0 then
    Exit;
  if LStart > 1 then
    LText := Copy(LText, LStart, MaxInt);

  LValue := TJSONObject.ParseJSONValue(LText);
  try
    if LValue is TJSONObject then
    begin
      LObj := TJSONObject(LValue);
      LErr := LObj.GetValue('error');
      if Assigned(LErr) then
      begin
        Result := LErr.Value;
        Exit;
      end;
    end;
  finally
    LValue.Free;
  end;
end;

function TfrmLogin.HasLocalData: Boolean;
var
  LQuery: TFDQuery;
  LCount: Int64;
begin
  Result := False;
  if not Assigned(dmApp) then
    Exit;
  if not dmApp.FDConnection.Connected then
    Exit;

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;
    LQuery.SQL.Text := 'select ifnull(sum(row_count),0) as total from sync_table_state';
    LQuery.Open;
    LCount := LQuery.FieldByName('total').AsLargeInt;
    Result := LCount > 0;
  finally
    LQuery.Free;
  end;
end;

function TfrmLogin.GetCachedUser(const ALogin: string): TJSONObject;
var
  LQuery: TFDQuery;
  LLogin: string;
  LJson: string;
  LValue: TJSONValue;
  LRepId: Integer;
begin
  Result := nil;
  if not Assigned(dmApp) or not dmApp.FDConnection.Connected then
    Exit;

  LLogin := '';
  LJson := '';
  LRepId := 0;

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;
    LQuery.SQL.Text := 'select base_url, login, user_json from api_session where id = 1';
    LQuery.Open;
    if LQuery.IsEmpty then
      Exit;

    if not LQuery.IsEmpty then
    begin
      if not SameText(Trim(LQuery.FieldByName('base_url').AsString), Trim(BaseUrlSelecionada)) then
        Exit;
      LLogin := Trim(LQuery.FieldByName('login').AsString);
      LJson := Trim(LQuery.FieldByName('user_json').AsString);
    end;
  finally
    LQuery.Free;
  end;

  if (ALogin <> '') and (LLogin <> '') and (not SameText(ALogin, LLogin)) then
    Exit;

  if LJson <> '' then
  begin
    LValue := TJSONObject.ParseJSONValue(LJson);
    if LValue is TJSONObject then
    begin
      Result := TJSONObject(LValue);
      Exit;
    end
    else
      LValue.Free;
  end;

  try
    LRepId := StrToIntDef(Trim(dmApp.FDConnection.ExecSQLScalar(
      'select coalesce(value, '''') from app_config where key = ''cod_representante''')), 0);
  except
    LRepId := 0;
  end;

  if LRepId <= 0 then
    Exit;

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;
    LQuery.SQL.Text :=
      'select id, coalesce(nom_representante, '''') as nom_representante ' +
      'from representante where id = :p0';
    LQuery.ParamByName('p0').AsInteger := LRepId;
    LQuery.Open;
    if LQuery.IsEmpty then
      Exit;

    Result := TJSONObject.Create;
    Result.AddPair('cod_representante', TJSONNumber.Create(LQuery.FieldByName('id').AsInteger));
    Result.AddPair('nom_representante', LQuery.FieldByName('nom_representante').AsString);
    if LLogin <> '' then
      Result.AddPair('logusu', LLogin)
    else if ALogin <> '' then
      Result.AddPair('logusu', ALogin);
  finally
    LQuery.Free;
  end;
end;
function TfrmLogin.SessionBaseMatchesSelectedBase: Boolean;
var
  LBaseSalva: string;
begin
  Result := False;
  try
    if Assigned(dmApp) and dmApp.FDConnection.Connected then
    begin
      LBaseSalva := Trim(dmApp.FDConnection.ExecSQLScalar('select coalesce(base_url, '''') from api_session where id = 1'));
      Result := (LBaseSalva <> '') and SameText(LBaseSalva, Trim(BaseUrlSelecionada));
    end;
  except
    Result := False;
  end;
end;

function TfrmLogin.GetSavedPassword: string;
begin
  Result := '';
  try
    if Assigned(dmApp) and dmApp.FDConnection.Connected and SessionBaseMatchesSelectedBase then
      Result := Trim(dmApp.FDConnection.ExecSQLScalar('select senha from api_session where id = 1'));
  except
    // ignore if column missing or any error
  end;
end;

function TfrmLogin.IsManualLogoutPending: Boolean;
var
  LValue: string;
begin
  Result := False;
  try
    if Assigned(dmApp) and dmApp.FDConnection.Connected then
    begin
      LValue := Trim(dmApp.FDConnection.ExecSQLScalar(
        'select coalesce(value, '''') from app_config where key = ''login_saida_manual'''));
      Result := SameText(LValue, '1') or SameText(LValue, 'S') or SameText(LValue, 'TRUE');
    end;
  except
    Result := False;
  end;
end;

procedure TfrmLogin.imSairClick(Sender: TObject);
begin
  SairdoSistema;
end;

end.
