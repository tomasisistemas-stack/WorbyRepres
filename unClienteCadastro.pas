unit unClienteCadastro;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.JSON, System.Net.HttpClient, System.Net.URLClient, Data.DB,
  FireDAC.Comp.Client, FireDAC.Stan.Param,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.ListBox,
  FMX.ScrollBox, FMX.Memo;

type
  TfrmClienteCadastro = class(TForm)
    LayoutRoot: TLayout;
    BackgroundRect: TRectangle;
    TopBar: TRectangle;
    LbTitulo: TLabel;
    ScrollBox: TVertScrollBox;
    CardDados: TRectangle;
    LbDados: TLabel;
    LbTipoPessoa: TLabel;
    CbTipoPessoa: TComboBox;
    LbCpfCnpj: TLabel;
    EdCpfCnpj: TEdit;
    ImgBuscarCpfCnpj: TImage;
    LbInscricaoEstadual: TLabel;
    EdInscricaoEstadual: TEdit;
    LbCodClienteInfo: TLabel;
    LbRazaoSocial: TLabel;
    EdRazaoSocial: TEdit;
    LbCep: TLabel;
    EdCep: TEdit;
    ImgBuscarCep: TImage;
    CardEndereco: TRectangle;
    LbEnderecoTitulo: TLabel;
    LbEndereco: TLabel;
    EdEndereco: TEdit;
    LbNumero: TLabel;
    EdNumero: TEdit;
    LbComplemento: TLabel;
    EdComplemento: TEdit;
    LbBairro: TLabel;
    EdBairro: TEdit;
    LbCodCidade: TLabel;
    EdCodCidade: TEdit;
    ImgBuscarCidade: TImage;
    LbNomeCidade: TLabel;
    LbUfCidade: TLabel;
    CardContato: TRectangle;
    LbContatoTitulo: TLabel;
    LbTelefone: TLabel;
    EdTelefone: TEdit;
    LbEmail: TLabel;
    EdEmail: TEdit;
    LbEmailEndNfe: TLabel;
    EdEmailEndNfe: TEdit;
    LyRodape: TLayout;
    LyCancelar: TLayout;
    BtnCancelar: TRectangle;
    LbCancelar: TLabel;
    LyGravar: TLayout;
    BtnGravar: TRectangle;
    LbGravar: TLabel;
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure BtnCancelarClick(Sender: TObject);
    procedure BtnGravarClick(Sender: TObject);
    procedure CbTipoPessoaChange(Sender: TObject);
    procedure EdCpfCnpjExit(Sender: TObject);
    procedure EdCpfCnpjChangeTracking(Sender: TObject);
    procedure EdCepExit(Sender: TObject);
    procedure EdCodCidadeExit(Sender: TObject);
    procedure ImgBuscarCidadeClick(Sender: TObject);
    procedure ImgBuscarCpfCnpjClick(Sender: TObject);
    procedure ImgBuscarCepClick(Sender: TObject);
  private
    FCodClienteApi: Integer;
    FRazaoSocial: string;
    FFantasia: string;
    FMaskingDoc: Boolean;
    FFormActive: Boolean;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormHide(Sender: TObject);
    procedure ApplyResponsiveLayout;
    procedure AtualizarMascaraDocumento;
    function OnlyDigits(const AValue: string): string;
    function FormatarDocumento(const AValue: string; const ATipoPessoa: string): string;
    function JsonString(AObj: TJSONObject; const AName: string): string;
    function BuscarClienteNaApi(const ACnpj: string): TJSONObject;
    function BuscarClienteReceitaWs(const ACnpj: string): TJSONObject;
    function BuscarEnderecoPorCep(const ACep: string): TJSONObject;
    procedure PreencherEnderecoPorJson(AJson: TJSONObject; const AOrigem: string);
    procedure PreencherEnderecoPorCepJson(AJson: TJSONObject);
    function MontarClienteJson: TJSONObject;
    function EnviarClienteApi(ACliente: TJSONObject): TJSONObject;
    function BuscarCodCidadeLocal(const ACidade, AUf: string): Integer;
    procedure CarregarCidadePorCodigo(const ACodCidade: Integer);
    function BuscarRepresentanteLocal: Integer;
    procedure SalvarClienteLocal(ACodCliente: Integer; ACliente: TJSONObject);
  public
    procedure SelecionarCidade(const ACodCidade: Integer; const ANome, AUf: string);
  end;

var
  frmClienteCadastro: TfrmClienteCadastro;

implementation

{$R *.fmx}

uses
  unDMApp,
  unFuncoes,
  unCidadeBusca,
  unPrincipal,
  unAndroidComboFix;


procedure TfrmClienteCadastro.FormShow(Sender: TObject);
begin
  FFormActive := True;
  if Assigned(dmApp) then
    dmApp.SetAppState('cliente_cadastro', 0, '');
  OnClose := FormClose;
  OnHide := FormHide;
  UseAndroidSafeComboPicker([CbTipoPessoa]);
  LbCodClienteInfo.Text := 'Codigo: --';
  EdCpfCnpj.OnChangeTracking := EdCpfCnpjChangeTracking;
  ApplyResponsiveLayout;
  AtualizarMascaraDocumento;
end;

procedure TfrmClienteCadastro.FormResize(Sender: TObject);
begin
  ApplyResponsiveLayout;
end;

procedure TfrmClienteCadastro.BtnCancelarClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmClienteCadastro.BtnGravarClick(Sender: TObject);
var
  LCliente: TJSONObject;
  LResposta: TJSONObject;
  LCodCliente: Integer;
begin
  if OnlyDigits(EdCpfCnpj.Text) = '' then
  begin
    ShowMessage('Informe o CPF/CNPJ.');
    EdCpfCnpj.SetFocus;
    Exit;
  end;

  if Trim(EdRazaoSocial.Text) = '' then
  begin
    ShowMessage('Informe a Razao Social/Nome.');
    EdRazaoSocial.SetFocus;
    Exit;
  end;

  if Trim(EdInscricaoEstadual.Text) = '' then
  begin
    ShowMessage('Informe a Inscricao Estadual. Caso nao tenha, preencha como ISENTA.');
    EdInscricaoEstadual.SetFocus;
    Exit;
  end;

  if Trim(EdCep.Text) = '' then
  begin
    ShowMessage('Informe o CEP.');
    EdCep.SetFocus;
    Exit;
  end;

  if Trim(EdEndereco.Text) = '' then
  begin
    ShowMessage('Informe o endereco.');
    EdEndereco.SetFocus;
    Exit;
  end;

  if StrToIntDef(OnlyDigits(EdCodCidade.Text), 0) <= 0 then
  begin
    ShowMessage('Informe o codigo da cidade.');
    EdCodCidade.SetFocus;
    Exit;
  end;

  LCliente := MontarClienteJson;
  try
    LResposta := EnviarClienteApi(LCliente);
    if not Assigned(LResposta) then
      Exit;

    try
      LCodCliente := LResposta.GetValue<Integer>('cod_cliente', 0);
    finally
      LResposta.Free;
    end;

    if LCodCliente <= 0 then
      raise Exception.Create('API nao retornou o codigo do cliente.');

    SalvarClienteLocal(LCodCliente, LCliente);
    FCodClienteApi := LCodCliente;
    LbCodClienteInfo.Text := 'Codigo: ' + FCodClienteApi.ToString;
    ShowMessage('Cliente gravado com sucesso.');
    Close;
  finally
    LCliente.Free;
  end;
end;

procedure TfrmClienteCadastro.CbTipoPessoaChange(Sender: TObject);
begin
  AtualizarMascaraDocumento;
  EdCpfCnpjChangeTracking(EdCpfCnpj);
end;

procedure TfrmClienteCadastro.EdCpfCnpjChangeTracking(Sender: TObject);
var
  LDigits: string;
  LMasked: string;
  LIsCnpj: Boolean;

  procedure AddPart(const ASep: string; const AStart, ACount: Integer);
  var
    LPart: string;
  begin
    LPart := Copy(LDigits, AStart, ACount);
    if LPart = '' then
      Exit;
    if (LMasked <> '') and (ASep <> '') then
      LMasked := LMasked + ASep;
    LMasked := LMasked + LPart;
  end;
begin
  if FMaskingDoc then
    Exit;

  FMaskingDoc := True;
  try
    LIsCnpj := CbTipoPessoa.ItemIndex = 0;
    LDigits := OnlyDigits(EdCpfCnpj.Text);

    if LIsCnpj then
    begin
      if Length(LDigits) > 14 then
        LDigits := Copy(LDigits, 1, 14);
      AddPart('', 1, 2);
      AddPart('.', 3, 3);
      AddPart('.', 6, 3);
      AddPart('/', 9, 4);
      AddPart('-', 13, 2);
    end
    else
    begin
      if Length(LDigits) > 11 then
        LDigits := Copy(LDigits, 1, 11);
      AddPart('', 1, 3);
      AddPart('.', 4, 3);
      AddPart('.', 7, 3);
      AddPart('-', 10, 2);
    end;

    if EdCpfCnpj.Text <> LMasked then
    begin
      EdCpfCnpj.Text := LMasked;
      TThread.Queue(nil,
        procedure
        begin
          if not (csDestroying in ComponentState) then
          begin
            EdCpfCnpj.SelStart := Length(EdCpfCnpj.Text);
            EdCpfCnpj.SelLength := 0;
          end;
        end);
    end;
  finally
    FMaskingDoc := False;
  end;
end;

procedure TfrmClienteCadastro.EdCpfCnpjExit(Sender: TObject);
var
  LCnpj: string;
  LJson: TJSONObject;
begin
  if not FFormActive then
    Exit;

  FCodClienteApi := 0;
  LbCodClienteInfo.Text := 'Codigo: --';
  FRazaoSocial := '';
  FFantasia := '';

  if CbTipoPessoa.ItemIndex <> 0 then
    Exit;

  LCnpj := OnlyDigits(EdCpfCnpj.Text);
  if LCnpj = '' then
    Exit;
  if Length(LCnpj) <> 14 then
  begin
    ShowMessage('CNPJ invalido.');
    EdCpfCnpj.SetFocus;
    Exit;
  end;

  LJson := BuscarClienteNaApi(LCnpj);
  if Assigned(LJson) then
  try
    PreencherEnderecoPorJson(LJson, 'api');
    Exit;
  finally
    LJson.Free;
  end;

  LJson := BuscarClienteReceitaWs(LCnpj);
  if Assigned(LJson) then
  try
    FCodClienteApi := 0;
    LbCodClienteInfo.Text := 'Codigo: --';
    PreencherEnderecoPorJson(LJson, 'receitaws');
  finally
    LJson.Free;
  end;
end;

procedure TfrmClienteCadastro.EdCepExit(Sender: TObject);
var
  LCep: string;
  LJson: TJSONObject;
begin
  if not FFormActive then
    Exit;

  LCep := OnlyDigits(EdCep.Text);
  if LCep = '' then
    Exit;
  if Length(LCep) <> 8 then
  begin
    ShowMessage('CEP invalido.');
    EdCep.SetFocus;
    Exit;
  end;

  LJson := BuscarEnderecoPorCep(LCep);
  if Assigned(LJson) then
  try
    PreencherEnderecoPorCepJson(LJson);
  finally
    LJson.Free;
  end;
end;
procedure TfrmClienteCadastro.EdCodCidadeExit(Sender: TObject);
begin
  CarregarCidadePorCodigo(StrToIntDef(OnlyDigits(EdCodCidade.Text), 0));
end;

procedure TfrmClienteCadastro.ImgBuscarCidadeClick(Sender: TObject);
begin
  if not Assigned(frmCidadeBusca) then
    Application.CreateForm(TfrmCidadeBusca, frmCidadeBusca);
  frmCidadeBusca.Show;
end;

procedure TfrmClienteCadastro.ImgBuscarCpfCnpjClick(Sender: TObject);
begin
  EdCpfCnpjExit(EdCpfCnpj);
end;

procedure TfrmClienteCadastro.ImgBuscarCepClick(Sender: TObject);
begin
  EdCepExit(EdCep);
end;

procedure TfrmClienteCadastro.SelecionarCidade(const ACodCidade: Integer; const ANome, AUf: string);
begin
  if ACodCidade > 0 then
    EdCodCidade.Text := ACodCidade.ToString
  else
    EdCodCidade.Text := '';
  LbNomeCidade.Text := Trim(ANome);
  LbUfCidade.Text := Trim(AUf);
end;


function TfrmClienteCadastro.OnlyDigits(const AValue: string): string;
var
  C: Char;
begin
  Result := '';
  for C in AValue do
    if C in ['0'..'9'] then
      Result := Result + C;
end;
function TfrmClienteCadastro.FormatarDocumento(const AValue: string; const ATipoPessoa: string): string;
var
  LDigits: string;
begin
  LDigits := OnlyDigits(AValue);
  Result := LDigits;

  if SameText(ATipoPessoa, 'F') then
  begin
    if Length(LDigits) = 11 then
      Result := Copy(LDigits, 1, 3) + '.' +
        Copy(LDigits, 4, 3) + '.' +
        Copy(LDigits, 7, 3) + '-' +
        Copy(LDigits, 10, 2);
  end
  else
  begin
    if Length(LDigits) = 14 then
      Result := Copy(LDigits, 1, 2) + '.' +
        Copy(LDigits, 3, 3) + '.' +
        Copy(LDigits, 6, 3) + '/' +
        Copy(LDigits, 9, 4) + '-' +
        Copy(LDigits, 13, 2);
  end;
end;
function TfrmClienteCadastro.JsonString(AObj: TJSONObject; const AName: string): string;
var
  LValue: TJSONValue;
  LPair: TJSONPair;
begin
  Result := '';
  if not Assigned(AObj) then
    Exit;

  LValue := AObj.GetValue(AName);
  if not Assigned(LValue) then
  begin
    for LPair in AObj do
      if SameText(LPair.JsonString.Value, AName) then
      begin
        LValue := LPair.JsonValue;
        Break;
      end;
  end;

  if Assigned(LValue) and not (LValue is TJSONNull) then
    Result := Trim(LValue.Value);
end;

function TfrmClienteCadastro.BuscarEnderecoPorCep(const ACep: string): TJSONObject;
var
  LHttp: THTTPClient;
  LResponse: IHTTPResponse;
  LValue: TJSONValue;
  LObj: TJSONObject;
  LText: string;
begin
  Result := nil;
  if not FFormActive then
    Exit;

  LHttp := THTTPClient.Create;
  try
    LHttp.ConnectionTimeout := 8000;
    LHttp.ResponseTimeout := 15000;
    try
      LResponse := LHttp.Get('https://viacep.com.br/ws/' + ACep + '/json/');
      if (LResponse.StatusCode < 200) or (LResponse.StatusCode >= 300) then
      begin
        ShowMessage('Endereco nao encontrado.');
        Exit;
      end;

      LText := LResponse.ContentAsString(TEncoding.UTF8);
      LValue := TJSONObject.ParseJSONValue(LText);
      if not (LValue is TJSONObject) then
      begin
        LValue.Free;
        ShowMessage('Endereco nao encontrado.');
        Exit;
      end;

      LObj := TJSONObject(LValue);
      if SameText(JsonString(LObj, 'erro'), 'true') then
      begin
        LObj.Free;
        ShowMessage('Endereco nao encontrado.');
        Exit;
      end;

      Result := LObj;
    except
      on E: Exception do
        ShowMessage(E.Message);
    end;
  finally
    LHttp.Free;
  end;
end;

function TfrmClienteCadastro.BuscarClienteNaApi(const ACnpj: string): TJSONObject;
var
  LHttp: THTTPClient;
  LResponse: IHTTPResponse;
  LRequest: TStringStream;
  LBody: TJSONObject;
  LValue: TJSONValue;
  LUrl: string;
  LText: string;
begin
  Result := nil;
  if not FFormActive then
    Exit;

  LUrl := Trim(dmApp.ApiBaseUrl);
  if LUrl.EndsWith('/') then
    Delete(LUrl, Length(LUrl), 1);
  LUrl := LUrl + '/api/cliente/documento';

  LBody := TJSONObject.Create;
  LHttp := THTTPClient.Create;
  try
    LHttp.ConnectionTimeout := 8000;
    LHttp.ResponseTimeout := 20000;
    LBody.AddPair('documento', ACnpj);
    LRequest := TStringStream.Create(LBody.ToJSON, TEncoding.UTF8);
    try
      try
        LResponse := LHttp.Post(LUrl, LRequest);
        if LResponse.StatusCode = 404 then
          Exit(nil);
        if (LResponse.StatusCode < 200) or (LResponse.StatusCode >= 300) then
          Exit(nil);

        LText := LResponse.ContentAsString(TEncoding.UTF8);
        LValue := TJSONObject.ParseJSONValue(LText);
        if LValue is TJSONObject then
        begin
          Result := TJSONObject(LValue);
          Result.AddPair('_origem', 'api');
        end
        else
          LValue.Free;
      except
        Result := nil;
      end;
    finally
      LRequest.Free;
    end;
  finally
    LHttp.Free;
    LBody.Free;
  end;
end;

function TfrmClienteCadastro.BuscarClienteReceitaWs(const ACnpj: string): TJSONObject;
var
  LHttp: THTTPClient;
  LResponse: IHTTPResponse;
  LValue: TJSONValue;
  LObj: TJSONObject;
  LUrl: string;
  LKey: string;
  LText: string;
begin
  Result := nil;
  if not FFormActive then
    Exit;

  LUrl := 'http://www.receitaws.com.br/v1/cnpj/' + ACnpj;
  LHttp := THTTPClient.Create;
  try
    LHttp.ConnectionTimeout := 8000;
    LHttp.ResponseTimeout := 20000;
    try
      LResponse := LHttp.Get(LUrl);
      if (LResponse.StatusCode < 200) or (LResponse.StatusCode >= 300) then
        Exit;
      LText := LResponse.ContentAsString(TEncoding.UTF8);
      LValue := TJSONObject.ParseJSONValue(LText);
      if not (LValue is TJSONObject) then
      begin
        LValue.Free;
        Exit;
      end;

      LObj := TJSONObject(LValue);
      if not SameText(JsonString(LObj, 'status'), 'OK') then
      begin
        ShowMessage(JsonString(LObj, 'message'));
        LObj.Free;
        Exit;
      end;

      LObj.AddPair('_origem', 'receitaws');
      Result := LObj;
    except
      on E: Exception do
        ShowMessage(E.Message);
    end;
  finally
    LHttp.Free;
  end;
end;

procedure TfrmClienteCadastro.PreencherEnderecoPorJson(AJson: TJSONObject; const AOrigem: string);
var
  LCepJson: TJSONObject;
begin
  if not FFormActive then
    Exit;

  if SameText(AOrigem, 'api') then
  begin
    FCodClienteApi := StrToIntDef(JsonString(AJson, 'cod_cliente'), 0);
    if FCodClienteApi > 0 then
      LbCodClienteInfo.Text := 'Codigo: ' + FCodClienteApi.ToString
    else
      LbCodClienteInfo.Text := 'Codigo: --';
    FRazaoSocial := JsonString(AJson, 'nom_cliente');
    FFantasia := JsonString(AJson, 'nom_fantasia');
    EdRazaoSocial.Text := FRazaoSocial;
    EdInscricaoEstadual.Text := JsonString(AJson, 'ie');
    EdCep.Text := JsonString(AJson, 'cep');
    EdEndereco.Text := JsonString(AJson, 'endereco');
    EdNumero.Text := JsonString(AJson, 'nr_endereco');
    EdComplemento.Text := JsonString(AJson, 'complemento');
    EdBairro.Text := JsonString(AJson, 'bairro');
    EdTelefone.Text := JsonString(AJson, 'telefone');
    EdEmail.Text := JsonString(AJson, 'email');
    EdEmailEndNfe.Text := JsonString(AJson, 'email_end_nfe');

    if (Trim(EdEndereco.Text) = '') and (Length(OnlyDigits(EdCep.Text)) = 8) then
    begin
      LCepJson := BuscarEnderecoPorCep(OnlyDigits(EdCep.Text));
      if Assigned(LCepJson) then
      try
        PreencherEnderecoPorCepJson(LCepJson);
      finally
        LCepJson.Free;
      end;
    end;

    if StrToIntDef(JsonString(AJson, 'cod_ibge'), 0) > 0 then
    begin
      CarregarCidadePorCodigo(StrToIntDef(JsonString(AJson, 'cod_ibge'), 0));
      if StrToIntDef(OnlyDigits(EdCodCidade.Text), 0) <= 0 then
        SelecionarCidade(StrToIntDef(JsonString(AJson, 'cod_cidade'), 0), JsonString(AJson, 'nom_cidade'), JsonString(AJson, 'uf'));
    end
    else
      SelecionarCidade(StrToIntDef(JsonString(AJson, 'cod_cidade'), 0), JsonString(AJson, 'nom_cidade'), JsonString(AJson, 'uf'));
    Exit;
  end;

  FRazaoSocial := JsonString(AJson, 'nome');
  FFantasia := JsonString(AJson, 'fantasia');
  EdRazaoSocial.Text := FRazaoSocial;

  EdCep.Text := JsonString(AJson, 'cep');
  EdEndereco.Text := JsonString(AJson, 'logradouro');
  EdNumero.Text := JsonString(AJson, 'numero');
  EdComplemento.Text := JsonString(AJson, 'complemento');
  EdBairro.Text := JsonString(AJson, 'bairro');
  EdTelefone.Text := JsonString(AJson, 'telefone');
  EdEmail.Text := JsonString(AJson, 'email');
  if Trim(EdEmailEndNfe.Text) = '' then
    EdEmailEndNfe.Text := EdEmail.Text;
  LCepJson := BuscarEnderecoPorCep(OnlyDigits(EdCep.Text));
  if Assigned(LCepJson) then
  try
    PreencherEnderecoPorCepJson(LCepJson);
  finally
    LCepJson.Free;
  end;
  if StrToIntDef(OnlyDigits(EdCodCidade.Text), 0) <= 0 then
    SelecionarCidade(BuscarCodCidadeLocal(JsonString(AJson, 'municipio'), JsonString(AJson, 'uf')), JsonString(AJson, 'municipio'), JsonString(AJson, 'uf'));
end;

procedure TfrmClienteCadastro.PreencherEnderecoPorCepJson(AJson: TJSONObject);
begin
  if (not FFormActive) or (not Assigned(AJson)) then
    Exit;

  EdCep.Text := JsonString(AJson, 'cep');
  EdEndereco.Text := JsonString(AJson, 'logradouro');
  EdComplemento.Text := JsonString(AJson, 'complemento');
  EdBairro.Text := JsonString(AJson, 'bairro');
  CarregarCidadePorCodigo(StrToIntDef(JsonString(AJson, 'ibge'), 0));
  if StrToIntDef(OnlyDigits(EdCodCidade.Text), 0) <= 0 then
    SelecionarCidade(BuscarCodCidadeLocal(JsonString(AJson, 'localidade'), JsonString(AJson, 'uf')), JsonString(AJson, 'localidade'), JsonString(AJson, 'uf'));
end;


function TfrmClienteCadastro.MontarClienteJson: TJSONObject;
var
  LTipo: string;
  LDoc: string;
  LRep: Integer;
  LCodIbge: Integer;
begin
  Result := TJSONObject.Create;
  if CbTipoPessoa.ItemIndex = 1 then
    LTipo := 'F'
  else
    LTipo := 'J';

  LDoc := FormatarDocumento(EdCpfCnpj.Text, LTipo);
  Result.AddPair('cod_cliente', TJSONNumber.Create(FCodClienteApi));
  Result.AddPair('tip_pessoa', LTipo);
  if LTipo = 'F' then
    Result.AddPair('cpf', LDoc)
  else
    Result.AddPair('cnpj', LDoc);

  FRazaoSocial := Trim(EdRazaoSocial.Text);
  if FRazaoSocial = '' then
    FRazaoSocial := LDoc;
  Result.AddPair('nom_cliente', FRazaoSocial);
  Result.AddPair('nom_fantasia', FFantasia);
  Result.AddPair('ie', Trim(EdInscricaoEstadual.Text));
  Result.AddPair('cep', OnlyDigits(EdCep.Text));
  Result.AddPair('endereco', Trim(EdEndereco.Text));
  Result.AddPair('nr_endereco', Trim(EdNumero.Text));
  Result.AddPair('complemento', Trim(EdComplemento.Text));
  Result.AddPair('bairro', Trim(EdBairro.Text));
  Result.AddPair('telefone', Trim(EdTelefone.Text));
  Result.AddPair('email', Trim(EdEmail.Text));
  Result.AddPair('email_end_nfe', Trim(EdEmailEndNfe.Text));
  Result.AddPair('nom_cidade', Trim(LbNomeCidade.Text));
  Result.AddPair('uf', Trim(LbUfCidade.Text));
  Result.AddPair('cod_cidade', TJSONNumber.Create(StrToIntDef(OnlyDigits(EdCodCidade.Text), 0)));
  LCodIbge := 0;
  with TFDQuery.Create(nil) do
  try
    Connection := dmApp.FDConnection;
    if not Connection.Connected then
      Connection.Connected := True;
    SQL.Text := 'select cod_ibge from cidades where cod_cidade = :p0 limit 1';
    ParamByName('p0').AsInteger := StrToIntDef(OnlyDigits(EdCodCidade.Text), 0);
    Open;
    if not IsEmpty then
      LCodIbge := Fields[0].AsInteger;
  finally
    Free;
  end;
  if LCodIbge > 0 then
    Result.AddPair('cod_ibge', TJSONNumber.Create(LCodIbge));
  LRep := 0;
  if Assigned(frmPrincipal) then
    LRep := frmPrincipal.id_representante;
  if LRep <= 0 then
    LRep := BuscarRepresentanteLocal;
  if LRep > 0 then
    Result.AddPair('id_representante', TJSONNumber.Create(LRep));
end;

function TfrmClienteCadastro.EnviarClienteApi(ACliente: TJSONObject): TJSONObject;
var
  LHttp: THTTPClient;
  LResponse: IHTTPResponse;
  LRequest: TStringStream;
  LValue: TJSONValue;
  LUrl: string;
  LText: string;
begin
  Result := nil;
  if not FFormActive then
    Exit;

  LUrl := Trim(dmApp.ApiBaseUrl);
  if LUrl.EndsWith('/') then
    Delete(LUrl, Length(LUrl), 1);
  LUrl := LUrl + '/api/cliente';

  LHttp := THTTPClient.Create;
  LHttp.ConnectionTimeout := 8000;
  LHttp.ResponseTimeout := 20000;
  LRequest := TStringStream.Create(ACliente.ToJSON, TEncoding.UTF8);
  try
    LHttp.CustomHeaders['Content-Type'] := 'application/json';
    LResponse := LHttp.Post(LUrl, LRequest);
    LText := LResponse.ContentAsString(TEncoding.UTF8);
    if (LResponse.StatusCode < 200) or (LResponse.StatusCode >= 300) then
      raise Exception.Create('HTTP ' + LResponse.StatusCode.ToString + ': ' + LText);

    LValue := TJSONObject.ParseJSONValue(LText);
    if LValue is TJSONObject then
      Result := TJSONObject(LValue)
    else
    begin
      LValue.Free;
      raise Exception.Create('Resposta invalida da API.');
    end;
  finally
    LRequest.Free;
    LHttp.Free;
  end;
end;

function TfrmClienteCadastro.BuscarCodCidadeLocal(const ACidade, AUf: string): Integer;
var
  Q: TFDQuery;
begin
  Result := 0;
  if (Trim(ACidade) = '') or (Trim(AUf) = '') then
    Exit;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    if not Q.Connection.Connected then
      Q.Connection.Connected := True;
    Q.SQL.Text := 'select cod_cidade from cidades where upper(nom_cidade) = upper(:cidade) and upper(uf) = upper(:uf) limit 1';
    Q.ParamByName('cidade').AsString := Trim(ACidade);
    Q.ParamByName('uf').AsString := Trim(AUf);
    Q.Open;
    if not Q.IsEmpty then
      Result := Q.Fields[0].AsInteger;
  finally
    Q.Free;
  end;
end;

procedure TfrmClienteCadastro.CarregarCidadePorCodigo(const ACodCidade: Integer);
var
  Q: TFDQuery;
begin
  if ACodCidade <= 0 then
    Exit;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    if not Q.Connection.Connected then
      Q.Connection.Connected := True;
    Q.SQL.Text := 'select cod_cidade, nom_cidade, uf from cidades where cod_cidade = :p0 or cod_ibge = :p0 limit 1';
    Q.ParamByName('p0').AsInteger := ACodCidade;
    Q.Open;
    if not Q.IsEmpty then
      SelecionarCidade(Q.FieldByName('cod_cidade').AsInteger, Q.FieldByName('nom_cidade').AsString, Q.FieldByName('uf').AsString);
  finally
    Q.Free;
  end;
end;


function TfrmClienteCadastro.BuscarRepresentanteLocal: Integer;
var
  Q: TFDQuery;
begin
  Result := 0;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    if not Q.Connection.Connected then
      Q.Connection.Connected := True;
    Q.SQL.Text := 'select id from representante limit 1';
    Q.Open;
    if not Q.IsEmpty then
      Result := Q.Fields[0].AsInteger;
  finally
    Q.Free;
  end;
end;

procedure TfrmClienteCadastro.SalvarClienteLocal(ACodCliente: Integer; ACliente: TJSONObject);
var
  Q: TFDQuery;
  LTipo: string;
  LDoc: string;
  LCodCidade: Integer;
  LRep: Integer;
begin
  if ACodCliente <= 0 then
    raise Exception.Create('Codigo do cliente invalido.');

  LTipo := ACliente.GetValue<string>('tip_pessoa', 'J');
  if SameText(LTipo, 'F') then
    LDoc := FormatarDocumento(ACliente.GetValue<string>('cpf', ''), LTipo)
  else
    LDoc := FormatarDocumento(ACliente.GetValue<string>('cnpj', ''), LTipo);
  LCodCidade := ACliente.GetValue<Integer>('cod_cidade', 0);
  LRep := ACliente.GetValue<Integer>('id_representante', 0);

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    if not Q.Connection.Connected then
      Q.Connection.Connected := True;
    Q.SQL.Text :=
      'insert or replace into cliente (' +
      'cod_cliente, dta_cad, nom_cliente, nom_fantasia, tip_pessoa, cnpj, cpf, ie, cep, endereco, nr_endereco, complemento, bairro, cod_cidade, telefone, email, email_end_nfe, id_representante, cod_empresa, status, cliente_bloqueado, pre_cadastro, sincronizar_palm, consumidor_final' +
      ') values (' +
      ':cod_cliente, :dta_cad, :nom_cliente, :nom_fantasia, :tip_pessoa, :cnpj, :cpf, :ie, :cep, :endereco, :nr_endereco, :complemento, :bairro, :cod_cidade, :telefone, :email, :email_end_nfe, :id_representante, 0, ''N'', ''N'', ''S'', ''S'', ''S'')';

    Q.ParamByName('cod_cliente').AsInteger := ACodCliente;
    Q.ParamByName('dta_cad').AsString := FormatDateTime('yyyy-mm-dd', Date);
    Q.ParamByName('nom_cliente').AsString := ACliente.GetValue<string>('nom_cliente', '');
    Q.ParamByName('nom_fantasia').AsString := ACliente.GetValue<string>('nom_fantasia', '');
    Q.ParamByName('tip_pessoa').AsString := LTipo;
    if SameText(LTipo, 'F') then
    begin
      Q.ParamByName('cnpj').DataType := ftString;
      Q.ParamByName('cnpj').Clear;
      Q.ParamByName('cpf').AsString := LDoc;
    end
    else
    begin
      Q.ParamByName('cnpj').AsString := LDoc;
      Q.ParamByName('cpf').DataType := ftString;
      Q.ParamByName('cpf').Clear;
    end;
    Q.ParamByName('ie').AsString := ACliente.GetValue<string>('ie', '');
    Q.ParamByName('cep').AsString := ACliente.GetValue<string>('cep', '');
    Q.ParamByName('endereco').AsString := ACliente.GetValue<string>('endereco', '');
    Q.ParamByName('nr_endereco').AsString := ACliente.GetValue<string>('nr_endereco', '');
    Q.ParamByName('complemento').AsString := ACliente.GetValue<string>('complemento', '');
    Q.ParamByName('bairro').AsString := ACliente.GetValue<string>('bairro', '');
    Q.ParamByName('telefone').AsString := ACliente.GetValue<string>('telefone', '');
    Q.ParamByName('email').AsString := ACliente.GetValue<string>('email', '');
    Q.ParamByName('email_end_nfe').AsString := ACliente.GetValue<string>('email_end_nfe', '');
    if LCodCidade > 0 then
      Q.ParamByName('cod_cidade').AsInteger := LCodCidade
    else
    begin
      Q.ParamByName('cod_cidade').DataType := ftInteger;
      Q.ParamByName('cod_cidade').Clear;
    end;
    if LRep > 0 then
      Q.ParamByName('id_representante').AsInteger := LRep
    else
    begin
      Q.ParamByName('id_representante').DataType := ftInteger;
      Q.ParamByName('id_representante').Clear;
    end;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure TfrmClienteCadastro.AtualizarMascaraDocumento;
begin
  if CbTipoPessoa.ItemIndex = 0 then
  begin
    LbCpfCnpj.Text := 'CNPJ';
    EdCpfCnpj.TextPrompt := '00.000.000/0000-00';
    EdCpfCnpj.MaxLength := 18;
  end
  else
  begin
    LbCpfCnpj.Text := 'CPF';
    EdCpfCnpj.TextPrompt := '000.000.000-00';
    EdCpfCnpj.MaxLength := 14;
  end;
  EdCpfCnpj.KeyboardType := TVirtualKeyboardType.NumberPad;
  EdCpfCnpj.FilterChar := '0123456789./-';
end;

procedure TfrmClienteCadastro.ApplyResponsiveLayout;
var
  LIsLandscape: Boolean;
  LIsTabletPortrait: Boolean;
  LContentW: Single;
  LX: Single;
  LBottom: Single;
  LFooterH: Single;
  LFooterW: Single;
  LBtnW: Single;
  LCardGap: Single;
begin
  if csDestroying in ComponentState then
    Exit;
  if (ClientWidth <= 0) or (ClientHeight <= 0) then
    Exit;

  LIsLandscape := ClientWidth > ClientHeight;
  LIsTabletPortrait := (not LIsLandscape) and (ClientWidth >= 430);
  LBottom := 0;
  if not LIsLandscape then
    LBottom := 50;

  LFooterH := 50;
  LCardGap := 12;

  if LIsLandscape or LIsTabletPortrait then
  begin
    if LIsLandscape then
      TopBar.Height := 64
    else
      TopBar.Height := 96;
    if LIsLandscape then
      LbTitulo.Position.Y := 30
    else
      LbTitulo.Position.Y := 53;
    LContentW := ClientWidth - 48;
    if LContentW > 920 then
      LContentW := 920;
    LX := (ClientWidth - LContentW) / 2;

    ScrollBox.Align := TAlignLayout.None;
    ScrollBox.SetBounds(LX, TopBar.Height + 8, LContentW, ClientHeight - TopBar.Height - LFooterH - LBottom - 24);

    CardDados.Align := TAlignLayout.None;
    CardEndereco.Align := TAlignLayout.None;
    CardContato.Align := TAlignLayout.None;
    if LIsLandscape or (LContentW >= 620) then
    begin
      CardDados.SetBounds(0, 0, (LContentW - LCardGap) / 2, 416);
      CardEndereco.SetBounds(CardDados.Width + LCardGap, 0, CardDados.Width, 330);
      CardContato.SetBounds(CardEndereco.Position.X, CardEndereco.Height + LCardGap, CardEndereco.Width, 230);
    end
    else
    begin
      CardDados.SetBounds(0, 0, LContentW, 416);
      CardEndereco.SetBounds(0, CardDados.Height + LCardGap, LContentW, 330);
      CardContato.SetBounds(0, CardEndereco.Position.Y + CardEndereco.Height + LCardGap, LContentW, 230);
    end;

    LyRodape.Align := TAlignLayout.None;
    LyRodape.SetBounds(LX, ClientHeight - LFooterH - LBottom - 8, LContentW, LFooterH);
    LyRodape.Margins.Bottom := 0;
  end
  else
  begin
    TopBar.Height := 128;
    LbTitulo.Position.Y := 73;
    LContentW := ClientWidth;

    ScrollBox.Align := TAlignLayout.Client;
    ScrollBox.Margins.Left := 0;
    ScrollBox.Margins.Right := 0;
    ScrollBox.Margins.Bottom := 0;

    CardDados.Align := TAlignLayout.Top;
    CardDados.Index := 0;
    CardDados.Margins.Left := 12;
    CardDados.Margins.Top := 12;
    CardDados.Margins.Right := 12;
    CardDados.Margins.Bottom := 0;
    CardDados.Position.Y := 0;
    CardDados.Height := 416;

    CardEndereco.Align := TAlignLayout.Top;
    CardEndereco.Index := 1;
    CardEndereco.Margins.Left := 12;
    CardEndereco.Margins.Top := 12;
    CardEndereco.Margins.Right := 12;
    CardEndereco.Margins.Bottom := 0;
    CardEndereco.Position.Y := CardDados.Position.Y + CardDados.Height + CardEndereco.Margins.Top;
    CardEndereco.Height := 330;

    CardContato.Align := TAlignLayout.Top;
    CardContato.Index := 2;
    CardContato.Margins.Left := 12;
    CardContato.Margins.Top := 12;
    CardContato.Margins.Right := 12;
    CardContato.Margins.Bottom := 0;
    CardContato.Position.Y := CardEndereco.Position.Y + CardEndereco.Height + CardContato.Margins.Top;
    CardContato.Height := 230;

    LyRodape.Align := TAlignLayout.MostBottom;
    LyRodape.Height := LFooterH;
    LyRodape.Margins.Bottom := LBottom;
  end;

  LFooterW := LyRodape.Width;
  if LFooterW <= 0 then
    LFooterW := LContentW;
  LBtnW := LFooterW / 2;

  LyCancelar.Align := TAlignLayout.None;
  LyCancelar.SetBounds(0, 0, LBtnW, LyRodape.Height);
  LyGravar.Align := TAlignLayout.None;
  LyGravar.SetBounds(LBtnW, 0, LFooterW - LBtnW, LyRodape.Height);

  BtnCancelar.Margins.Left := 6;
  BtnCancelar.Margins.Top := 4;
  BtnCancelar.Margins.Right := 10;
  BtnCancelar.Margins.Bottom := 4;
  BtnGravar.Margins.Left := 10;
  BtnGravar.Margins.Top := 4;
  BtnGravar.Margins.Right := 6;
  BtnGravar.Margins.Bottom := 4;
  LbCancelar.TextSettings.Font.Size := 14;
  LbGravar.TextSettings.Font.Size := 14;
end;

procedure TfrmClienteCadastro.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(dmApp) then
    dmApp.ClearAppState('cliente_cadastro');
  FormHide(Sender);
  Action := TCloseAction.caFree;
  frmClienteCadastro := nil;
end;

procedure TfrmClienteCadastro.FormHide(Sender: TObject);
begin
  FFormActive := False;
end;

end.
