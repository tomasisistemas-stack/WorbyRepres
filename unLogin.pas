unit unLogin;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
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
  private
    procedure AtualizarStatus(const AText: string; AError: Boolean = False);
    function BaseUrlSelecionada: string;
    function RotuloParaApiUrl(const ARotuloOuUrl: string): string;
    function ApiUrlParaRotulo(const AUrl: string): string;
    procedure ApplyOrientationLayout;
    function NormalizeApiError(const AMessage: string): string;
    function HasLocalData: Boolean;
    function GetCachedUser(const ALogin: string): TJSONObject;
    function GetSavedPassword: string;
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
  unPrincipal;

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
end;

function TfrmLogin.RotuloParaApiUrl(const ARotuloOuUrl: string): string;
var
  LValor: string;
begin
  LValor := Trim(ARotuloOuUrl);
  if SameText(LValor, 'PLASFAN') then
    Exit('http://plasfan.ddns.com.br:9000');
  if SameText(LValor, 'FILHO DO CRIADO') then
    Exit('http://plasfan.ddns.com.br:9004');
  Result := LValor;
end;

function TfrmLogin.ApiUrlParaRotulo(const AUrl: string): string;
var
  LUrl: string;
begin
  LUrl := Trim(AUrl);
  if SameText(LUrl, 'http://plasfan.ddns.com.br:9000') then
    Exit('PLASFAN');
  if SameText(LUrl, 'http://plasfan.ddns.com.br:9004') then
    Exit('FILHO DO CRIADO');
  Result := LUrl;
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
    if (LSenhaSalva <> '') and (not SameText(LSenha, LSenhaSalva)) then
    begin
      AtualizarStatus('Usuário e Senha Inválidos', True);
      Exit;
    end;

    LCached := GetCachedUser(Trim(EdLogin.Text));
    if Assigned(LCached) then
    begin
      try
        frmPrincipal.AtualizarContextoUsuario(LCached);
        frmPrincipal.Show;
        Hide;
        Exit;
      finally
        LCached.Free;
      end;
    end;
  end;

  dmApp.ApiBaseUrl := Trim(BaseUrlSelecionada);
  AtualizarStatus('Autenticando...');
  try
    LResponse := dmApp.Login(Trim(EdLogin.Text), LSenha);
    try
      frmPrincipal.AtualizarContextoUsuario(LResponse);
      frmPrincipal.Show;
      Hide;
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
begin
  CbBaseUrl.Items.Clear;
  CbBaseUrl.Items.Add('PLASFAN');
  CbBaseUrl.Items.Add('FILHO DO CRIADO');
  LAtual := ApiUrlParaRotulo(dmApp.ApiBaseUrl);
  if (LAtual <> '') and (CbBaseUrl.Items.IndexOf(LAtual) < 0) then
    CbBaseUrl.Items.Add(LAtual);
  CbBaseUrl.ItemIndex := CbBaseUrl.Items.IndexOf(LAtual);
  if CbBaseUrl.ItemIndex < 0 then
    CbBaseUrl.ItemIndex := 0;
  EdLogin.Text := dmApp.GetSessionLogin;
  EdSenha.Text := GetSavedPassword;
  AtualizarStatus('');
  ApplyOrientationLayout;
end;

procedure TfrmLogin.FormResize(Sender: TObject);
begin
  ApplyOrientationLayout;
end;

procedure TfrmLogin.ApplyOrientationLayout;
var
  LIsLandscape: Boolean;
  LScale: Single;
  LBottomMargin: Single;
  LCardW: Single;
  LCardH: Single;
  LHeaderH: Single;
begin
  LIsLandscape := Width > Height;

  // Cabeçalho responsivo (evita distorção e corte da arte em diferentes telas)
  Image1.Align := TAlignLayout.Client;
  Image1.WrapMode := TImageWrapMode.Fit;
  Image1.HitTest := False;

  if LIsLandscape then
  begin
    LHeaderH := Height * 0.24;
    if LHeaderH < 68 then
      LHeaderH := 68;
    if LHeaderH > 120 then
      LHeaderH := 120;
    TopBar.Height := LHeaderH;
    Layout1.Margins.Top := 0;
    LbSubtitulo.Visible := False;
    LbSubtitulo.Opacity := 0;
    LbStatus.Visible := False;

    LBottomMargin := 4;
    lbottom.Align := TAlignLayout.Bottom;
    lbottom.Margins.Bottom := LBottomMargin;
    lbottom.Height := 48;
    lbottom.Width := Width;
    lbottom.Position.X := 0;

    Card.Align := TAlignLayout.None;
    LScale := 0.78;
    LCardW := Card.Width * LScale;
    LCardH := Card.Height * LScale;
    if (Height - TopBar.Height - LBottomMargin - lbottom.Height - 24) < LCardH then
    begin
      LScale := (Height - TopBar.Height - LBottomMargin - lbottom.Height - 24) / Card.Height;
      if LScale < 0.75 then
        LScale := 0.75;
      LCardW := Card.Width * LScale;
      LCardH := Card.Height * LScale;
    end;
    Card.Scale.X := LScale;
    Card.Scale.Y := LScale;
    Card.Position.X := (Width - LCardW) / 2;
    Card.Position.Y := TopBar.Height + ((Height - TopBar.Height - LBottomMargin - lbottom.Height - LCardH) / 2);
    if Card.Position.Y < (TopBar.Height + 4) then
      Card.Position.Y := TopBar.Height + 4;
  end
  else
  begin
    LHeaderH := Height * 0.17;
    if LHeaderH < 110 then
      LHeaderH := 110;
    if LHeaderH > 170 then
      LHeaderH := 170;
    TopBar.Height := LHeaderH;
    Layout1.Margins.Top := 0;
    Card.Align := TAlignLayout.Center;
    Card.Scale.X := 1;
    Card.Scale.Y := 1;
    Card.Position.X := 0;
    Card.Position.Y := 0;
    LbSubtitulo.Visible := True;
    LbSubtitulo.Opacity := 1;
    LbStatus.Visible := True;
    Card.Height := 316;
    LbStatus.Position.Y := 320;

    lbottom.Align := TAlignLayout.MostBottom;
    if IsXiaomiDevice then
      lbottom.Margins.Bottom := 50
    else
      lbottom.Margins.Bottom := 0;
    lbottom.Height := 72;
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
begin
  Result := nil;
  if not Assigned(dmApp) or not dmApp.FDConnection.Connected then
    Exit;

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;
    LQuery.SQL.Text := 'select login, user_json from api_session where id = 1';
    LQuery.Open;
    LLogin := Trim(LQuery.FieldByName('login').AsString);
    LJson := Trim(LQuery.FieldByName('user_json').AsString);
  finally
    LQuery.Free;
  end;

  if (LJson = '') then
    Exit;
  if (ALogin <> '') and (LLogin <> '') and (not SameText(ALogin, LLogin)) then
    Exit;

  LValue := TJSONObject.ParseJSONValue(LJson);
  if LValue is TJSONObject then
    Result := TJSONObject(LValue)
  else
    LValue.Free;
end;

function TfrmLogin.GetSavedPassword: string;
begin
  Result := '';
  try
    if Assigned(dmApp) and dmApp.FDConnection.Connected then
      Result := Trim(dmApp.FDConnection.ExecSQLScalar('select senha from api_session where id = 1'));
  except
    // ignore if column missing or any error
  end;
end;

procedure TfrmLogin.imSairClick(Sender: TObject);
begin
  SairdoSistema;
end;

end.
