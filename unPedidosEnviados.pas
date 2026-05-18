unit unPedidosEnviados;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.JSON, System.DateUtils, System.IOUtils,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.ListView,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  Data.DB, FireDAC.Comp.Client, FireDAC.Comp.DataSet
  {$IF Defined(MSWINDOWS)}
  , Winapi.Windows, Winapi.ShellAPI
  {$ENDIF}
  ;

type
  TfrmPedidosEnviados = class(TForm)
    LayoutRoot: TLayout;
    BackgroundRect: TRectangle;
    TopBar: TRectangle;
    CardBusca: TRectangle;
    LbBuscar: TLabel;
    EdBuscar: TEdit;
    LayoutRodape: TLayout;
    LbTitulo: TLabel;
    BtnVoltar: TImage;
    BtnCompartilhar: TRectangle;
    LbBtnCompartilhar: TLabel;
    BtnImprimir: TRectangle;
    LbBtnImprimir: TLabel;
    BtnBuscar: TImage;
    LyListView: TLayout;
    LvPedidos: TListView;
    procedure FormShow(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure BtnBuscarClick(Sender: TObject);
    procedure BtnVoltarClick(Sender: TObject);
    procedure BtnImprimirClick(Sender: TObject);
    procedure BtnCompartilharClick(Sender: TObject);
  private
    function FornecedorFromApiBaseUrl(const AUrl: string): string;
    function ClienteConsumidorFinal(const ACodCliente: Integer): Boolean;
    function JsonFieldAsString(const AJsonText, AField: string): string;
    function JsonFieldAsFloat(const AJsonText, AField: string): Double;
    function FormatarDataHora(const AValue: string): string;
    function BuscarNomeClientePorCodigo(const ACodCliente: Integer): string;
    function BuscarNomeRepresentante(const AId: Integer): string;
    function BuscarNomeFop(const AId: Integer): string;
    function BuscarNomePrazo(const AId: Integer): string;
    function TotalLiquidoPedido(const APedidoId: Integer): Double;
    function PedidoSelecionadoId: Integer;
    procedure ImprimirPedido(const APedidoId: Integer);
    procedure ApplyResponsiveLayout;
    procedure CarregarPedidos;
  public
  protected
    procedure Resize; override;
  end;

var
  frmPedidosEnviados: TfrmPedidosEnviados;

implementation

{$R *.fmx}

uses
  unDMApp, unPrincipal, unFuncoes
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

function TfrmPedidosEnviados.FornecedorFromApiBaseUrl(const AUrl: string): string;
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

procedure TfrmPedidosEnviados.ApplyResponsiveLayout;
begin
  if not Assigned(LayoutRodape) then
    Exit;

  if (ClientHeight > ClientWidth) and IsXiaomiDevice then
    LayoutRodape.Margins.Bottom := 50
  else
    LayoutRodape.Margins.Bottom := 8;
end;

procedure TfrmPedidosEnviados.Resize;
begin
  inherited;
  ApplyResponsiveLayout;
end;

function TfrmPedidosEnviados.JsonFieldAsString(const AJsonText, AField: string): string;
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

function TfrmPedidosEnviados.JsonFieldAsFloat(const AJsonText, AField: string): Double;
var
  S: string;
begin
  S := JsonFieldAsString(AJsonText, AField);
  S := StringReplace(S, '.', ',', [rfReplaceAll]);
  Result := StrToFloatDef(S, 0);
end;

function TfrmPedidosEnviados.TotalLiquidoPedido(const APedidoId: Integer): Double;
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
end;

function TfrmPedidosEnviados.PedidoSelecionadoId: Integer;
begin
  Result := 0;
  if Assigned(LvPedidos.Selected) then
    Result := LvPedidos.Selected.Tag;
end;

procedure TfrmPedidosEnviados.ImprimirPedido(const APedidoId: Integer);
var
  QPedido, QItens: TFDQuery;
  LVenda1, LVenda2: string;
  LRep, LCli, LData, LHora, LFop, LPrazo, LDtRef: string;
  LTot: Double;
  LFS: TFormatSettings;
  LPdfFile: string;
  LDt: TDateTime;
  LConteudo: TStringList;
  LRepId, LFopId, LPrazoId: Integer;
  LFornecedor: string;
  LCodCliente: Integer;
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

      LOffsets[1] := StreamPos;
      AddRaw('1 0 obj<< /Type /Catalog /Pages 2 0 R >>endobj');

      LOffsets[2] := StreamPos;
      AddRaw('2 0 obj<< /Type /Pages /Kids [3 0 R] /Count 1 >>endobj');

      LOffsets[3] := StreamPos;
      AddRaw('3 0 obj<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>endobj');

      LOffsets[4] := StreamPos;
      AddRaw(Format('4 0 obj<< /Length %d >>stream', [LContentLen]));
      AddRaw(StringReplace(LContent, sLineBreak, #10, [rfReplaceAll]));
      AddRaw('endstream endobj');

      LOffsets[5] := StreamPos;
      AddRaw('5 0 obj<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>endobj');

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

    {LRepId := QPedido.FieldByName('representative_code').AsInteger;
    LRep := BuscarNomeRepresentante(LRepId);}
    LRep := frmPrincipal.FRepNome;

    LFopId := StrToIntDef(JsonFieldAsString(LVenda1, 'id_fop'), 0);
    LFop   := BuscarNomeFop(LFopId);

    LPrazoId := StrToIntDef(JsonFieldAsString(LVenda1, 'id_prazo'), 0);
    LPrazo   := BuscarNomePrazo(LPrazoId);

    LDtRef := Trim(QPedido.FieldByName('dt_ref').AsString);
    if TryISO8601ToDate(StringReplace(LDtRef, ' ', 'T', []), LDt, True) or
       TryISO8601ToDate(LDtRef, LDt, True) then
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
    LConteudo.Add('CLIENTE.......: ' + JsonFieldAsString(LVenda1, 'cod_cliente') + ' - ' + LCli);
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

    LFopId := StrToIntDef(JsonFieldAsString(LVenda1, 'codfop'), 0);
    if LFopId <= 0 then LFopId := StrToIntDef(JsonFieldAsString(LVenda1, 'id_fop'), 0);
    if LFopId <= 0 then LFopId := StrToIntDef(JsonFieldAsString(LVenda1, 'cod_fop'), 0);
    LPrazoId := StrToIntDef(JsonFieldAsString(LVenda1, 'codprazo'), 0);
    if LPrazoId <= 0 then LPrazoId := StrToIntDef(JsonFieldAsString(LVenda1, 'id_prazo'), 0);
    if LPrazoId <= 0 then LPrazoId := StrToIntDef(JsonFieldAsString(LVenda1, 'cod_prazo'), 0);

    LFop := BuscarNomeFop(LFopId);
    if LFop = '' then
      LFop := IntToStr(LFopId);
    LPrazo := BuscarNomePrazo(LPrazoId);
    if LPrazo = '' then
      LPrazo := IntToStr(LPrazoId);

    LConteudo.Add(StringOfChar('-', 95));
    LConteudo.Add(PadRight('CONDICAO DE PAGTO.: ' + LFop + ' - ' + LPrazo, 68) + PadLeft('TOTAL: ' + FormatFloat('#,###,##0.00', LTot, LFS), 25));


    LPdfFile := IncludeTrailingPathDelimiter(System.IOUtils.TPath.GetDocumentsPath) +
      Format('pedido_enviado_%d.pdf', [APedidoId]);
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
{$IFNDEF MSWINDOWS}
{$IFNDEF ANDROID}
    ShowMessage('PDF gerado em: ' + LPdfFile);
{$ENDIF}
{$ENDIF}
  finally
    LConteudo.Free;
    QItens.Free;
    QPedido.Free;
  end;
end;

function TfrmPedidosEnviados.FormatarDataHora(const AValue: string): string;
var
  S: string;
  D: TDateTime;
begin
  S := Trim(AValue);
  if S = '' then
    Exit('');

  // SQLite costuma vir como 'yyyy-mm-dd hh:nn:ss'
  if TryISO8601ToDate(StringReplace(S, ' ', 'T', []), D, True) or
     TryISO8601ToDate(S, D, True) then
    Exit(FormatDateTime('dd/mm/yyyy hh:nn:ss', D));

  // fallback: mantém texto original se não conseguir converter
  Result := S;
end;

function TfrmPedidosEnviados.BuscarNomeClientePorCodigo(const ACodCliente: Integer): string;
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

function TfrmPedidosEnviados.ClienteConsumidorFinal(const ACodCliente: Integer): Boolean;
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

function TfrmPedidosEnviados.BuscarNomeRepresentante(const AId: Integer): string;
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

function TfrmPedidosEnviados.BuscarNomeFop(const AId: Integer): string;
var
  Q: TFDQuery;
  LCols: TStringList;
  LNomeCampo: string;
  LIdCampo: string;
begin
  Result := '';
  if AId <= 0 then Exit;
  LCols := TStringList.Create;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'PRAGMA table_info("fop")';
    Q.Open;
    while not Q.Eof do
    begin
      LCols.Add(LowerCase(Trim(Q.FieldByName('name').AsString)));
      Q.Next;
    end;
    Q.Close;

    if LCols.IndexOf('id') >= 0 then
      LIdCampo := 'id'
    else if LCols.IndexOf('cod_fop') >= 0 then
      LIdCampo := 'cod_fop'
    else if LCols.IndexOf('codigo') >= 0 then
      LIdCampo := 'codigo'
    else
      LIdCampo := LCols[0];

    if LCols.IndexOf('fop') >= 0 then
      LNomeCampo := 'fop'
    else if LCols.IndexOf('descricao') >= 0 then
      LNomeCampo := 'descricao'
    else if LCols.IndexOf('nome') >= 0 then
      LNomeCampo := 'nome'
    else if LCols.IndexOf('nom_fop') >= 0 then
      LNomeCampo := 'nom_fop'
    else
      LNomeCampo := 'id';

    Q.SQL.Text := Format('select %s as nome from fop where %s = :p0', [LNomeCampo, LIdCampo]);
    Q.ParamByName('p0').AsInteger := AId;
    Q.Open;
    if not Q.IsEmpty then
      Result := Trim(Q.FieldByName('nome').AsString);
  finally
    LCols.Free;
    Q.Free;
  end;
end;

function TfrmPedidosEnviados.BuscarNomePrazo(const AId: Integer): string;
var
  Q: TFDQuery;
  LCols: TStringList;
  LNomeCampo: string;
  LIdCampo: string;
begin
  Result := '';
  if AId <= 0 then Exit;
  LCols := TStringList.Create;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'PRAGMA table_info("prazo")';
    Q.Open;
    while not Q.Eof do
    begin
      LCols.Add(LowerCase(Trim(Q.FieldByName('name').AsString)));
      Q.Next;
    end;
    Q.Close;

    if LCols.IndexOf('id') >= 0 then
      LIdCampo := 'id'
    else if LCols.IndexOf('cod_prazo') >= 0 then
      LIdCampo := 'cod_prazo'
    else if LCols.IndexOf('codigo') >= 0 then
      LIdCampo := 'codigo'
    else
      LIdCampo := LCols[0];

    if LCols.IndexOf('prazo') >= 0 then
      LNomeCampo := 'prazo'
    else if LCols.IndexOf('descricao') >= 0 then
      LNomeCampo := 'descricao'
    else if LCols.IndexOf('nome') >= 0 then
      LNomeCampo := 'nome'
    else
      LNomeCampo := LIdCampo;

    Q.SQL.Text := Format('select %s as nome from prazo where %s = :p0', [LNomeCampo, LIdCampo]);
    Q.ParamByName('p0').AsInteger := AId;
    Q.Open;
    if not Q.IsEmpty then
      Result := Trim(Q.FieldByName('nome').AsString);
  finally
    LCols.Free;
    Q.Free;
  end;
end;

procedure TfrmPedidosEnviados.CarregarPedidos;
var
  Q: TFDQuery;
  LItem: TListViewItem;
  LBusca: string;
  LNomeCliente: string;
  LData: string;
  LTotal: Double;
  LDt: TDateTime;
  LFS: TFormatSettings;
  LCodCliente: Integer;
begin
  LFS := TFormatSettings.Create('pt-BR');
  LBusca := LowerCase(Trim(EdBuscar.Text));
  LvPedidos.Items.BeginUpdate;
  try
    LvPedidos.Items.Clear;

    Q := TFDQuery.Create(nil);
    try
      Q.Connection := dmApp.FDConnection;
      Q.SQL.Text :=
        'select id, vendas1_json, coalesce(sent_at, created_at) as dt_ref, numdoc_remote ' +
        'from outbound_pedido ' +
        'where upper(trim(coalesce(status, ''''))) = ''ENVIADO'' ' +
        'order by dt_ref desc';
      Q.Open;
      while not Q.Eof do
      begin
        LNomeCliente := Trim(JsonFieldAsString(Q.FieldByName('vendas1_json').AsString, 'nom_cliente'));
        if LNomeCliente = '' then
        begin
          LCodCliente := StrToIntDef(JsonFieldAsString(Q.FieldByName('vendas1_json').AsString, 'cod_cliente'), 0);
          LNomeCliente := BuscarNomeClientePorCodigo(LCodCliente);
        end;
        if LNomeCliente = '' then
          LNomeCliente := 'Pedido ' + Q.FieldByName('id').AsString;

        if (LBusca = '') or (Pos(LBusca, LowerCase(LNomeCliente)) > 0) then
        begin
          LData := FormatarDataHora(Q.FieldByName('dt_ref').AsString);

          LTotal := TotalLiquidoPedido(Q.FieldByName('id').AsInteger);

          LItem := LvPedidos.Items.Add;
          LItem.Tag := Q.FieldByName('id').AsInteger;
          LItem.Text := LNomeCliente;
          LItem.Detail := Format(
            'Data/hora de envio: %s  |  Pedido: %s' + sLineBreak + 'Total Liquido: R$ %s',
            [LData,
             Q.FieldByName('numdoc_remote').AsString,
             FormatFloat('#,###,##0.00', LTotal, LFS)]
          );
        end;
        Q.Next;
      end;
      if LvPedidos.Items.Count = 0 then
      begin
        LItem := LvPedidos.Items.Add;
        LItem.Text := 'Nenhum pedido enviado';
        LItem.Detail := 'Sem registros para os filtros atuais';
        LItem.Tag := 0;
      end;
    finally
      Q.Free;
    end;
  finally
    LvPedidos.Items.EndUpdate;
  end;
end;

procedure TfrmPedidosEnviados.FormShow(Sender: TObject);
begin
  LbTitulo.Text := 'Pedidos Enviados';
  //LvPedidos.ItemAppearanceClassName := 'ListItem';
  BtnCompartilhar.OnClick := BtnCompartilharClick;
  LbBtnCompartilhar.OnClick := BtnCompartilharClick;
  ApplyResponsiveLayout;
  CarregarPedidos;
end;

procedure TfrmPedidosEnviados.FormActivate(Sender: TObject);
begin
  CarregarPedidos;
end;

procedure TfrmPedidosEnviados.BtnBuscarClick(Sender: TObject);
begin
  CarregarPedidos;
end;

procedure TfrmPedidosEnviados.BtnVoltarClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmPedidosEnviados.BtnImprimirClick(Sender: TObject);
var
  LId: Integer;
begin
  LId := PedidoSelecionadoId;
  if LId <= 0 then
  begin
    ShowMessage('Selecione um pedido enviado para imprimir.');
    Exit;
  end;
  ImprimirPedido(LId);
end;

procedure TfrmPedidosEnviados.BtnCompartilharClick(Sender: TObject);
var
  LId: Integer;
  LPdfFile: string;
{$IFDEF ANDROID}
  LIntent: JIntent;
  LUri: Jnet_Uri;
{$ENDIF}
begin
  LId := PedidoSelecionadoId;
  if LId <= 0 then
  begin
    ShowMessage('Selecione um pedido enviado para compartilhar.');
    Exit;
  end;

  LPdfFile := IncludeTrailingPathDelimiter(System.IOUtils.TPath.GetDocumentsPath) +
    Format('pedido_enviado_%d.pdf', [LId]);
  if not FileExists(LPdfFile) then
    ImprimirPedido(LId);

  if not FileExists(LPdfFile) then
  begin
    ShowMessage('Falha ao gerar PDF para compartilhamento.');
    Exit;
  end;

{$IFDEF ANDROID}
  LUri := BuildContentUriForPdf(LPdfFile);
  LIntent := TJIntent.Create;
  LIntent.setAction(TJIntent.JavaClass.ACTION_SEND);
  LIntent.setType(StringToJString('application/pdf'));
  LIntent.putExtra(TJIntent.JavaClass.EXTRA_STREAM, JParcelable(LUri));
  LIntent.addFlags(TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION);
  TAndroidHelper.Activity.startActivity(
    TJIntent.JavaClass.createChooser(LIntent, StrToJCharSequence('Compartilhar PDF'))
  );
{$ELSE}
  ShowMessage('Compartilhamento implementado para Android.');
{$ENDIF}
end;

end.

