unit unPedidosDigitados;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.JSON, System.DateUtils, System.IOUtils,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.ListView,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.DialogService, FMX.DialogService.Async,
  Data.DB, FireDAC.Comp.Client
  {$IF Defined(MSWINDOWS)}
  , Winapi.Windows, Winapi.ShellAPI
  {$ENDIF}
  ;

type
  TfrmPedidosDigitados = class(TForm)
    LayoutRoot: TLayout;
    BackgroundRect: TRectangle;
    TopBar: TRectangle;
    LbTitulo: TLabel;
    CardBusca: TRectangle;
    LbBuscar: TLabel;
    EdBuscar: TEdit;
    LvPedidos: TListView;
    LayoutRodape: TLayout;
    BtnEditar: TRectangle;
    LbBtnEditar: TLabel;
    BtnExcluir: TRectangle;
    LbBtnExcluir: TLabel;
    BtnImprimir: TRectangle;
    LbBtnImprimir: TLabel;
    BtnCompartilhar: TRectangle;
    LbBtnCompartilhar: TLabel;
    Image1: TImage;
    BtnVoltar: TImage;
    procedure FormShow(Sender: TObject);
    procedure BtnBuscarClick(Sender: TObject);
    procedure LvPedidosItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure BtnVoltarClick(Sender: TObject);
    procedure BtnEditarClick(Sender: TObject);
    procedure BtnExcluirClick(Sender: TObject);
    procedure BtnImprimirClick(Sender: TObject);
    procedure BtnCompartilharClick(Sender: TObject);
  private
    function JsonFieldAsString(const AJsonText, AField: string): string;
    function JsonFieldAsFloat(const AJsonText, AField: string): Double;
    function BuscarNomeClientePorCodigo(const ACodCliente: Integer): string;
    function TotalLiquidoPedido(const APedidoId: Integer): Double;
    function PedidoSelecionadoId: Integer;
    function FornecedorFromApiBaseUrl(const AUrl: string): string;
    function ClienteConsumidorFinal(const ACodCliente: Integer): Boolean;
    function BuscarNomeRepresentante(const AId: Integer): string;
    function BuscarNomeFop(const AId: Integer): string;
    function BuscarNomePrazo(const AId: Integer): string;
    procedure EditarPedido(const APedidoId: Integer);
    procedure ImprimirPedido(const APedidoId: Integer);
    procedure CompartilharPedido(const APedidoId: Integer);
    procedure ApplyResponsiveLayout;
    procedure CarregarPedidos;
    procedure ExcluirPedidoDigitado(const APedidoId: Integer);
  protected
    procedure Resize; override;
  public
  end;

var
  frmPedidosDigitados: TfrmPedidosDigitados;

implementation

{$R *.fmx}

uses
  unDMApp, unPedido, unFuncoes, unPrincipal
{$IFDEF ANDROID}
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

  LAuthority := TAndroidHelper.Context.getPackageName.concat(StringToJString('.provider'));
  try
    Result := TJcontent_FileProvider.JavaClass.getUriForFile(TAndroidHelper.Context, LAuthority, LFile);
    Exit;
  except
  end;

  LAuthority := TAndroidHelper.Context.getPackageName.concat(StringToJString('.fileprovider'));
  try
    Result := TJcontent_FileProvider.JavaClass.getUriForFile(TAndroidHelper.Context, LAuthority, LFile);
    Exit;
  except
    Result := TJnet_Uri.JavaClass.parse(StringToJString('file://' + AFileName));
  end;
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

function TfrmPedidosDigitados.FornecedorFromApiBaseUrl(const AUrl: string): string;
var
  LUrl: string;
begin
  LUrl := Trim(AUrl);
  if SameText(LUrl, 'http://plasfan.ddns.com.br:9000') then
    Exit('PLASFAN');
  if SameText(LUrl, 'http://plasfan.ddns.com.br:9004') then
    Exit('FILHO DO CRIADOR');
  Result := LUrl;
end;

function TfrmPedidosDigitados.ClienteConsumidorFinal(const ACodCliente: Integer): Boolean;
var
  Q: TFDQuery;
begin
  Result := False;
  if ACodCliente <= 0 then
    Exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'select consumidor_final from cliente where cod_cliente = :p0';
    Q.ParamByName('p0').AsInteger := ACodCliente;
    Q.Open;
    if not Q.IsEmpty then
      Result := SameText(Trim(Q.Fields[0].AsString), 'S');
  finally
    Q.Free;
  end;
end;

procedure TfrmPedidosDigitados.ApplyResponsiveLayout;
begin
  if not Assigned(LayoutRodape) then
    Exit;
  // Apenas em retrato: Xiaomi precisa margem extra para não cobrir o rodapé.
  if (ClientHeight > ClientWidth) and IsXiaomiDevice then
    LayoutRodape.Margins.Bottom := 50
  else
    LayoutRodape.Margins.Bottom := 8;
end;

procedure TfrmPedidosDigitados.Resize;
begin
  inherited;
  ApplyResponsiveLayout;
end;

function TfrmPedidosDigitados.JsonFieldAsString(const AJsonText, AField: string): string;
var
  LJson: TJSONValue;
  LObj: TJSONObject;
  LVal: TJSONValue;
begin
  Result := '';
  if Trim(AJsonText) = '' then
    Exit;

  LJson := TJSONObject.ParseJSONValue(AJsonText);
  try
    if LJson is TJSONObject then
    begin
      LObj := TJSONObject(LJson);
      LVal := LObj.GetValue(AField);
      if Assigned(LVal) then
        Result := LVal.Value;
    end;
  finally
    LJson.Free;
  end;
end;

function TfrmPedidosDigitados.JsonFieldAsFloat(const AJsonText, AField: string): Double;
var
  S: string;
begin
  S := JsonFieldAsString(AJsonText, AField);
  S := StringReplace(S, '.', ',', [rfReplaceAll]);
  Result := StrToFloatDef(S, 0);
end;

function TfrmPedidosDigitados.BuscarNomeClientePorCodigo(const ACodCliente: Integer): string;
var
  Q: TFDQuery;
begin
  Result := '';
  if ACodCliente <= 0 then
    Exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'select nom_cliente from cliente where cod_cliente = :p0';
    Q.ParamByName('p0').AsInteger := ACodCliente;
    Q.Open;
    if not Q.IsEmpty then
      Result := Trim(Q.Fields[0].AsString);
  finally
    Q.Free;
  end;
end;

function TfrmPedidosDigitados.TotalLiquidoPedido(const APedidoId: Integer): Double;
var
  Q: TFDQuery;
  LJson: TJSONValue;
  LObj: TJSONObject;
  LVal: TJSONValue;
begin
  Result := 0;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'select vendas2_json from outbound_pedido_item where pedido_id = :p0';
    Q.ParamByName('p0').AsInteger := APedidoId;
    Q.Open;
    while not Q.Eof do
    begin
      LJson := TJSONObject.ParseJSONValue(Q.FieldByName('vendas2_json').AsString);
      try
        if LJson is TJSONObject then
        begin
          LObj := TJSONObject(LJson);
          LVal := LObj.GetValue('total_item');
          if Assigned(LVal) then
            Result := Result + StrToFloatDef(StringReplace(LVal.Value, '.', ',', [rfReplaceAll]), 0);
        end;
      finally
        LJson.Free;
      end;
      Q.Next;
    end;
  finally
    Q.Free;
  end;

  if LvPedidos.Items.Count > 0 then
    LvPedidos.ItemIndex := 0
  else
    LvPedidos.ItemIndex := -1;
end;

procedure TfrmPedidosDigitados.CarregarPedidos;
var
  Q: TFDQuery;
  LItem: TListViewItem;
  LBusca: string;
  LNomeCliente: string;
  LData: string;
  LTotal: Double;
  LDt: TDateTime;
  LFS: TFormatSettings;
begin
  LFS := TFormatSettings.Create('pt-BR');
  LBusca := LowerCase(Trim(EdBuscar.Text));
  LvPedidos.Items.Clear;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text :=
      'select id, vendas1_json, created_at, status ' +
      'from outbound_pedido ' +
      'where status in (''PENDENTE'', ''ERRO'') ' +
      'order by id desc';
    Q.Open;
    while not Q.Eof do
    begin
      LNomeCliente := JsonFieldAsString(Q.FieldByName('vendas1_json').AsString, 'nom_cliente');
      if (LBusca = '') or (Pos(LBusca, LowerCase(LNomeCliente)) > 0) then
      begin
        LData := Q.FieldByName('created_at').AsString;
        if TryISO8601ToDate(LData, LDt, True) then
          LData := FormatDateTime('dd/mm/yyyy', LDt);

        LTotal := TotalLiquidoPedido(Q.FieldByName('id').AsInteger);

        LItem := LvPedidos.Items.Add;
        LItem.Tag := Q.FieldByName('id').AsInteger;
        LItem.Text := LNomeCliente;
        LItem.Detail := Format('Data: %s  |  Total Líquido: R$ %s',
          [LData, FormatFloat('#,###,##0.00', LTotal, LFS)]);
      end;
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmPedidosDigitados.ExcluirPedidoDigitado(const APedidoId: Integer);
var
  Q: TFDQuery;
begin
  if APedidoId <= 0 then
    Exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'delete from outbound_pedido_item where pedido_id = :p0';
    Q.ParamByName('p0').AsInteger := APedidoId;
    Q.ExecSQL;

    Q.SQL.Text := 'delete from outbound_pedido where id = :p0';
    Q.ParamByName('p0').AsInteger := APedidoId;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

function TfrmPedidosDigitados.PedidoSelecionadoId: Integer;
begin
  Result := 0;
  if (LvPedidos.ItemIndex >= 0) and (LvPedidos.ItemIndex < LvPedidos.Items.Count) then
    Result := LvPedidos.Items[LvPedidos.ItemIndex].Tag;
end;

function TfrmPedidosDigitados.BuscarNomeRepresentante(const AId: Integer): string;
var
  Q: TFDQuery;
begin
  Result := '';
  if AId <= 0 then Exit;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'select nom_representante from representante where id = :p0';
    Q.ParamByName('p0').AsInteger := AId;
    Q.Open;
    if not Q.IsEmpty then
      Result := Trim(Q.Fields[0].AsString);
  finally
    Q.Free;
  end;
end;

function TfrmPedidosDigitados.BuscarNomeFop(const AId: Integer): string;
var
  Q: TFDQuery;
begin
  Result := '';
  if AId <= 0 then Exit;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'select nom_fop from fop where cod_fop = :p0';
    Q.ParamByName('p0').AsInteger := AId;
    Q.Open;
    if not Q.IsEmpty then
      Result := Trim(Q.Fields[0].AsString);
  finally
    Q.Free;
  end;
end;

function TfrmPedidosDigitados.BuscarNomePrazo(const AId: Integer): string;
var
  Q: TFDQuery;
begin
  Result := '';
  if AId <= 0 then Exit;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'select prazo from prazo where id = :p0';
    Q.ParamByName('p0').AsInteger := AId;
    Q.Open;
    if not Q.IsEmpty then
      Result := Trim(Q.Fields[0].AsString);
  finally
    Q.Free;
  end;
end;

procedure TfrmPedidosDigitados.EditarPedido(const APedidoId: Integer);
begin
  if APedidoId <= 0 then
    Exit;

  if not Assigned(frmPedido) then
    Application.CreateForm(TfrmPedido, frmPedido);

  frmPedido.CarregarPedidoDigitado(APedidoId);
  frmPedido.Show;
  Close;
end;

procedure TfrmPedidosDigitados.ImprimirPedido(const APedidoId: Integer);
var
  QPedido, QItens: TFDQuery;
  LVenda1, LVenda2: string;
  LRep, LCli, LData, LHora, LFop, LPrazo, LDtRef: string;
  LTot: Double;
  LFS: TFormatSettings;
  LPdfFile: string;
  LDt: TDateTime;
  LConteudo: TStringList;
  LRepId, LFopId, LPrazoId, LCodCliente: Integer;
  LFornecedor: string;
{$IFDEF ANDROID}
  LIntent: JIntent;
  LUri: Jnet_Uri;
{$ENDIF}
  function PadRight(const S: string; const AWidth: Integer): string;
  begin
    Result := Copy(S + StringOfChar(' ', AWidth), 1, AWidth);
  end;
  function PadLeft(const S: string; const AWidth: Integer): string;
  begin
    if Length(S) >= AWidth then
      Result := Copy(S, 1, AWidth)
    else
      Result := StringOfChar(' ', AWidth - Length(S)) + S;
  end;
  function EscPDF(const S: string): string;
  begin
    Result := StringReplace(S, '\', '\\', [rfReplaceAll]);
    Result := StringReplace(Result, '(', '\(', [rfReplaceAll]);
    Result := StringReplace(Result, ')', '\)', [rfReplaceAll]);
  end;
  procedure SaveTextAsPdf(const AFileName: string; ALines: TStrings);
  var
    I, Y: Integer;
    LStream: TStringList;
    LContent: string;
    LContentLen: Integer;
    LOffsets: array[1..5] of Integer;
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
      LContent := 'BT /F1 10 Tf' + sLineBreak;
      Y := 810;
      for I := 0 to ALines.Count - 1 do
      begin
        LContent := LContent + Format('1 0 0 1 20 %d Tm (%s) Tj', [Y, EscPDF(ALines[I])]) + sLineBreak;
        Dec(Y, 12);
        if Y < 20 then Break;
      end;
      LContent := LContent + 'ET' + sLineBreak;
      LContentLen := Length(AnsiString(StringReplace(LContent, sLineBreak, #10, [rfReplaceAll])));

      AddRaw('%PDF-1.4');
      LOffsets[1] := StreamPos; AddRaw('1 0 obj<< /Type /Catalog /Pages 2 0 R >>endobj');
      LOffsets[2] := StreamPos; AddRaw('2 0 obj<< /Type /Pages /Kids [3 0 R] /Count 1 >>endobj');
      LOffsets[3] := StreamPos; AddRaw('3 0 obj<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>endobj');
      LOffsets[4] := StreamPos;
      AddRaw(Format('4 0 obj<< /Length %d >>stream', [LContentLen]));
      AddRaw(StringReplace(LContent, sLineBreak, #10, [rfReplaceAll]));
      AddRaw('endstream endobj');
      LOffsets[5] := StreamPos; AddRaw('5 0 obj<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>endobj');
      AddRaw('xref');
      AddRaw('0 6');
      AddRaw('0000000000 65535 f ');
      for I := 1 to 5 do
        AddRaw(Format('%.10d 00000 n ', [LOffsets[I]]));
      AddRaw('trailer<< /Size 6 /Root 1 0 R >>');
      AddRaw(Format('startxref%s%d', [sLineBreak, StreamPos]));
      AddRaw('%%EOF');
      LStream.SaveToFile(AFileName, TEncoding.ASCII);
    finally
      LStream.Free;
    end;
  end;
begin
  LFS := TFormatSettings.Create('pt-BR');
  QPedido := TFDQuery.Create(nil);
  QItens := TFDQuery.Create(nil);
  LConteudo := TStringList.Create;
  try
    QPedido.Connection := dmApp.FDConnection;
    QPedido.SQL.Text := 'select representative_code, vendas1_json, coalesce(sent_at, created_at) dt_ref, numdoc_remote from outbound_pedido where id = :p0';
    QPedido.ParamByName('p0').AsInteger := APedidoId;
    QPedido.Open;
    if QPedido.IsEmpty then Exit;

    LVenda1 := QPedido.FieldByName('vendas1_json').AsString;
    LCodCliente := StrToIntDef(JsonFieldAsString(LVenda1, 'cod_cliente'), 0);
    LCli := JsonFieldAsString(LVenda1, 'nom_cliente');
    if LCli = '' then
      LCli := BuscarNomeClientePorCodigo(LCodCliente);

    LRepId := StrToIntDef(Trim(QPedido.FieldByName('representative_code').AsString), 0);
    LRep := BuscarNomeRepresentante(LRepId);
    if LRep = '' then
      LRep := frmPrincipal.FRepNome;

    LFopId := StrToIntDef(JsonFieldAsString(LVenda1, 'id_fop'), 0);
    LPrazoId := StrToIntDef(JsonFieldAsString(LVenda1, 'id_prazo'), 0);
    LFop := BuscarNomeFop(LFopId);
    LPrazo := BuscarNomePrazo(LPrazoId);

    LDtRef := Trim(QPedido.FieldByName('dt_ref').AsString);
    if TryISO8601ToDate(StringReplace(LDtRef, ' ', 'T', []), LDt, True) or TryISO8601ToDate(LDtRef, LDt, True) then
    begin
      LData := FormatDateTime('dd/mm/yyyy', LDt);
      LHora := FormatDateTime('hh:nn', LDt);
    end
    else
    begin
      LData := LDtRef;
      LHora := '';
    end;

    QItens.Connection := dmApp.FDConnection;
    QItens.SQL.Text := 'select vendas2_json from outbound_pedido_item where pedido_id = :p0 order by item_ord';
    QItens.ParamByName('p0').AsInteger := APedidoId;
    QItens.Open;

    LTot := 0;
    LFornecedor := FornecedorFromApiBaseUrl(dmApp.ApiBaseUrl);
    if LFornecedor = '' then
      LFornecedor := 'PLASFAN';
    if SameText(LFornecedor, 'PLASFAN') and ClienteConsumidorFinal(LCodCliente) then
      LFornecedor := 'MP';

    LConteudo.Add('FORNECEDOR....: ' + LFornecedor);
    if LRepId > 0 then
      LConteudo.Add('REPRESENTANTE.: ' + LRep + ' (COD.' + IntToStr(LRepId) + ')')
    else
      LConteudo.Add('REPRESENTANTE.: ' + LRep);
    LConteudo.Add('CLIENTE.......: ' + IntToStr(LCodCliente) + ' - ' + LCli);
    LConteudo.Add('DATA..........: ' + LData + ' ' + LHora);
    LConteudo.Add('');
    LConteudo.Add(PadRight('CODIGO', 10) + PadRight('DESCRICAO', 45) + PadRight('UND', 6) + PadLeft('QTDE', 8) + PadLeft('PRECO', 12) + PadLeft('TOTAL', 12));
    LConteudo.Add(StringOfChar('-', 95));
    while not QItens.Eof do
    begin
      LVenda2 := QItens.FieldByName('vendas2_json').AsString;
      LConteudo.Add(
        PadRight(JsonFieldAsString(LVenda2, 'cod_produto'), 10) +
        PadRight(Copy(JsonFieldAsString(LVenda2, 'nom_produto'), 1, 45), 45) +
        PadRight(JsonFieldAsString(LVenda2, 'unidade'), 6) +
        PadLeft(FormatFloat('#,##0.###', JsonFieldAsFloat(LVenda2, 'qtd'), LFS), 8) +
        PadLeft(FormatFloat('#,##0.00', JsonFieldAsFloat(LVenda2, 'preco'), LFS), 12) +
        PadLeft(FormatFloat('#,##0.00', JsonFieldAsFloat(LVenda2, 'total_item'), LFS), 12)
      );
      LTot := LTot + JsonFieldAsFloat(LVenda2, 'total_item');
      QItens.Next;
    end;

    LConteudo.Add(StringOfChar('-', 95));
    LConteudo.Add(PadRight('CONDICAO DE PAGTO.: ' + LFop + ' - ' + LPrazo, 68) + PadLeft('TOTAL: ' + FormatFloat('#,###,##0.00', LTot, LFS), 25));


    LPdfFile := IncludeTrailingPathDelimiter(GetPdfOutputDir) + Format('pedido_digitado_%d.pdf', [APedidoId]);
    SaveTextAsPdf(LPdfFile, LConteudo);
{$IFDEF MSWINDOWS}
    ShellExecute(0, 'open', PChar(LPdfFile), nil, nil, SW_SHOWNORMAL);
{$ENDIF}
{$IFDEF ANDROID}
    LUri := BuildContentUriForPdf(LPdfFile);
    LIntent := TJIntent.Create;
    LIntent.setAction(TJIntent.JavaClass.ACTION_VIEW);
    LIntent.setDataAndType(LUri, StringToJString('application/pdf'));
    LIntent.addFlags(TJIntent.JavaClass.FLAG_ACTIVITY_NEW_TASK);
    LIntent.addFlags(TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION);
    TAndroidHelper.Activity.startActivity(LIntent);
{$ENDIF}
  finally
    LConteudo.Free;
    QItens.Free;
    QPedido.Free;
  end;
end;

procedure TfrmPedidosDigitados.CompartilharPedido(const APedidoId: Integer);
var
  LPdfFile: string;
{$IFDEF ANDROID}
  LIntent: JIntent;
  LUri: Jnet_Uri;
{$ENDIF}
begin
  if APedidoId <= 0 then
    Exit;

  ImprimirPedido(APedidoId);
  LPdfFile := IncludeTrailingPathDelimiter(GetPdfOutputDir) + Format('pedido_digitado_%d.pdf', [APedidoId]);
{$IFDEF ANDROID}
  LUri := BuildContentUriForPdf(LPdfFile);
  LIntent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_SEND);
  LIntent.setType(StringToJString('application/pdf'));
  LIntent.putExtra(TJIntent.JavaClass.EXTRA_STREAM, JParcelable(LUri));
  LIntent.addFlags(TJIntent.JavaClass.FLAG_ACTIVITY_NEW_TASK);
  LIntent.addFlags(TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION);
  TAndroidHelper.Activity.startActivity(TJIntent.JavaClass.createChooser(LIntent, StrToJCharSequence('Compartilhar PDF')));
{$ENDIF}
{$IFDEF MSWINDOWS}
  ShellExecute(0, 'open', PChar(LPdfFile), nil, nil, SW_SHOWNORMAL);
{$ENDIF}
end;

procedure TfrmPedidosDigitados.FormShow(Sender: TObject);
begin
  ApplyResponsiveLayout;
  CarregarPedidos;
end;

procedure TfrmPedidosDigitados.BtnBuscarClick(Sender: TObject);
begin
  CarregarPedidos;
end;


procedure TfrmPedidosDigitados.LvPedidosItemClick(const Sender: TObject; const AItem: TListViewItem);
begin
  // Apenas seleciona o item; ações ficam nos botões Editar/Excluir.
end;

procedure TfrmPedidosDigitados.BtnEditarClick(Sender: TObject);
begin
  EditarPedido(PedidoSelecionadoId);
end;

procedure TfrmPedidosDigitados.BtnExcluirClick(Sender: TObject);
var
  LPedidoId: Integer;
begin
  LPedidoId := PedidoSelecionadoId;
  if LPedidoId <= 0 then
  begin
    ShowMessage('Selecione um pedido para excluir.');
    Exit;
  end;

  TDialogServiceAsync.MessageDialog(
    'Deseja excluir este pedido digitado?',
    TMsgDlgType.mtConfirmation,
    [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
    TMsgDlgBtn.mbNo,
    0,
    procedure(const AResult: TModalResult)
    begin
      if AResult <> mrYes then
        Exit;

      ExcluirPedidoDigitado(LPedidoId);
      CarregarPedidos;
    end
  );
end;

procedure TfrmPedidosDigitados.BtnVoltarClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmPedidosDigitados.BtnImprimirClick(Sender: TObject);
var
  LPedidoId: Integer;
begin
  LPedidoId := PedidoSelecionadoId;
  if LPedidoId <= 0 then
  begin
    ShowMessage('Selecione um pedido para imprimir.');
    Exit;
  end;
  ImprimirPedido(LPedidoId);
end;

procedure TfrmPedidosDigitados.BtnCompartilharClick(Sender: TObject);
var
  LPedidoId: Integer;
begin
  LPedidoId := PedidoSelecionadoId;
  if LPedidoId <= 0 then
  begin
    ShowMessage('Selecione um pedido para compartilhar.');
    Exit;
  end;
  CompartilharPedido(LPedidoId);
end;

end.
