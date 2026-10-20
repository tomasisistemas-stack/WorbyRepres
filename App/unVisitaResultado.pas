unit unVisitaResultado;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.DateUtils, System.JSON,
  System.Math, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Edit,
  FMX.Memo, FMX.Memo.Types, FMX.ScrollBox, FMX.ListBox, FireDAC.Comp.Client;

type
  TfrmVisitaResultado = class(TForm)
    LayoutRoot: TLayout;
    BackgroundRect: TRectangle;
    TopBar: TRectangle;
    LbTitulo: TLabel;
    LbSubtitulo: TLabel;
    CardCliente: TRectangle;
    LbClienteTitulo: TLabel;
    LbClienteNome: TLabel;
    LbTempoAtendimento: TLabel;
    CardStatus: TRectangle;
    LbStatusTitulo: TLabel;
    CbStatusVisita: TComboBox;
    CardObs: TRectangle;
    LbObsTitulo: TLabel;
    MemoObs: TMemo;
    lbottom: TLayout;
    BtnCancelar: TRectangle;
    LayoutCancelar: TLayout;
    LbCancelar: TLabel;
    BtnSalvar: TRectangle;
    LbSalvar: TLabel;
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure CbStatusVisitaChange(Sender: TObject);
    procedure BtnSalvarClick(Sender: TObject);
    procedure BtnCancelarClick(Sender: TObject);
  private
    FCodCliente: Integer;
    FNomeCliente: string;
    FInicio: TDateTime;
    FValorPedido: Double;
    function CodRepresentanteAtual: Integer;
    function StatusVisitaAtual: string;
    function JsonFloat(AObj: TJSONObject; const AName: string; ADefault: Double = 0): Double;
    function ObterValorPedidoClienteHoje: Double;
    procedure ApplyResponsiveLayout;
    procedure AtualizarStatus;
    procedure SalvarVisita;
  public
    procedure SetResultado(ACodCliente: Integer; const ANomeCliente: string; AInicio: TDateTime);
  end;

var
  frmVisitaResultado: TfrmVisitaResultado;

implementation

{$R *.fmx}

uses
  unDMApp, unFuncoes;

procedure TfrmVisitaResultado.SetResultado(ACodCliente: Integer; const ANomeCliente: string; AInicio: TDateTime);
begin
  FCodCliente := ACodCliente;
  FNomeCliente := ANomeCliente;
  if AInicio > 0 then
    FInicio := AInicio
  else
    FInicio := Now;
  CbStatusVisita.Items.Clear;
  CbStatusVisita.Items.Add('Prospecção');
  CbStatusVisita.Items.Add('Venda');
  CbStatusVisita.Items.Add('Relacionamento');
  CbStatusVisita.Items.Add('Pós-venda');
  CbStatusVisita.Items.Add('Cobrança');
  CbStatusVisita.Items.Add('Visita impossibilitada');
  CbStatusVisita.ItemIndex := 1;
  MemoObs.Lines.Clear;
  LbClienteNome.Text := FNomeCliente;
  LbTempoAtendimento.Text := 'Tempo em atendimento: ' + IntToStr(MinutesBetween(Now, FInicio)) + ' min';
  AtualizarStatus;
end;

function TfrmVisitaResultado.CodRepresentanteAtual: Integer;
begin
  Result := 0;
  try
    Result := StrToIntDef(Trim(dmApp.FDConnection.ExecSQLScalar(
      'select coalesce(value, '''') from app_config where key = ''cod_representante''')), 0);
  except
    Result := 0;
  end;
end;

function TfrmVisitaResultado.StatusVisitaAtual: string;
begin
  Result := 'Venda';
  if Assigned(CbStatusVisita) and (CbStatusVisita.ItemIndex >= 0) then
    Result := CbStatusVisita.Items[CbStatusVisita.ItemIndex];
end;

function TfrmVisitaResultado.JsonFloat(AObj: TJSONObject; const AName: string; ADefault: Double): Double;
var
  LValue: TJSONValue;
  LText: string;
  LFS: TFormatSettings;
begin
  Result := ADefault;
  if not Assigned(AObj) then
    Exit;

  LValue := AObj.GetValue(AName);
  if not Assigned(LValue) then
    Exit;

  LFS := TFormatSettings.Create;
  LFS.DecimalSeparator := '.';
  LText := StringReplace(Trim(LValue.Value), ',', '.', [rfReplaceAll]);
  Result := StrToFloatDef(LText, ADefault, LFS);
end;

function TfrmVisitaResultado.ObterValorPedidoClienteHoje: Double;
var
  QPedidos: TFDQuery;
  QItens: TFDQuery;
  LPedidoJson: TJSONValue;
  LPedidoObj: TJSONObject;
  LItemJson: TJSONValue;
  LItemObj: TJSONObject;
  LCodCliente: Integer;
  LQtd: Double;
  LPreco: Double;
  LDesc: Double;
  LSubTotal: Double;
begin
  Result := 0;
  if FCodCliente <= 0 then
    Exit;

  QPedidos := TFDQuery.Create(nil);
  QItens := TFDQuery.Create(nil);
  try
    QPedidos.Connection := dmApp.FDConnection;
    QItens.Connection := dmApp.FDConnection;
    QPedidos.SQL.Text :=
      'select id, vendas1_json from outbound_pedido ' +
      ' where date(created_at) = date(''now'') ' +
      '   and coalesce(status, '''') not in (''CANCELADO'', ''ERRO'') ' +
      ' order by id desc';
    QPedidos.Open;

    while not QPedidos.Eof do
    begin
      LCodCliente := 0;
      LPedidoJson := TJSONObject.ParseJSONValue(QPedidos.FieldByName('vendas1_json').AsString);
      try
        if LPedidoJson is TJSONObject then
        begin
          LPedidoObj := TJSONObject(LPedidoJson);
          if Assigned(LPedidoObj.GetValue('cod_cliente')) then
            LCodCliente := StrToIntDef(LPedidoObj.GetValue('cod_cliente').Value, 0);
        end;
      finally
        LPedidoJson.Free;
      end;

      if LCodCliente = FCodCliente then
      begin
        QItens.Close;
        QItens.SQL.Text :=
          'select vendas2_json from outbound_pedido_item where pedido_id = :p0 order by item_ord';
        QItens.ParamByName('p0').AsInteger := QPedidos.FieldByName('id').AsInteger;
        QItens.Open;
        while not QItens.Eof do
        begin
          LItemJson := TJSONObject.ParseJSONValue(QItens.FieldByName('vendas2_json').AsString);
          try
            if LItemJson is TJSONObject then
            begin
              LItemObj := TJSONObject(LItemJson);
              LSubTotal := JsonFloat(LItemObj, 'sub_total', 0);
              if LSubTotal = 0 then
              begin
                LQtd := JsonFloat(LItemObj, 'qtd', 0);
                LPreco := JsonFloat(LItemObj, 'preco', 0);
                LDesc := JsonFloat(LItemObj, 'desconto_pct', JsonFloat(LItemObj, 'desconto', 0));
                LSubTotal := LQtd * LPreco * (1 - (LDesc / 100));
              end;
              Result := Result + LSubTotal;
            end;
          finally
            LItemJson.Free;
          end;
          QItens.Next;
        end;
        Exit;
      end;

      QPedidos.Next;
    end;
  finally
    QItens.Free;
    QPedidos.Free;
  end;
end;


procedure TfrmVisitaResultado.AtualizarStatus;
begin
  FValorPedido := ObterValorPedidoClienteHoje;
  LbTempoAtendimento.Text := 'Tempo em atendimento: ' + IntToStr(MinutesBetween(Now, FInicio)) +
    ' min | Pedido: R$ ' + FormatFloat('#,##0.00', FValorPedido);
end;

procedure TfrmVisitaResultado.SalvarVisita;
var
  Q: TFDQuery;
  LDataHora: string;
  LVendeu: string;
  LStatus: string;
  LMotivo: string;
begin
  if FCodCliente <= 0 then
  begin
    ShowMessage('Cliente nao informado.');
    Exit;
  end;

  LStatus := StatusVisitaAtual;
  if Pos('PROSPEC', UpperCase(LStatus)) = 1 then
    LStatus := 'PROSPECCAO'
  else if Pos('COBRAN', UpperCase(LStatus)) = 1 then
    LStatus := 'COBRANCA'
  else if Pos('RELACIONAMENTO', UpperCase(LStatus)) = 1 then
    LStatus := 'RELACIONAMENTO'
  else if Pos('POS-VENDA', UpperCase(LStatus)) = 1 then
    LStatus := 'POS-VENDA'
  else if Pos('VISITA IMPOSSIBILITADA', UpperCase(LStatus)) = 1 then
    LStatus := 'VISITA IMPOSSIBILITADA';
  FValorPedido := ObterValorPedidoClienteHoje;
  if SameText(LStatus, 'Venda') then
    LVendeu := 'S'
  else
    LVendeu := 'N';
  LMotivo := Trim(MemoObs.Text);
  if not SameText(LStatus, 'Venda') then
    LMotivo := Trim(LStatus + ' ' + LMotivo);

  LDataHora := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
  Q := TFDQuery.Create(nil);
  try
    try
      Q.Connection := dmApp.FDConnection;
      Q.SQL.Text :=
        'insert or replace into cliente_visitas ' +
        '(cod_cliente, data, vendeu, enviado, motivo_n_venda, valor_pedido, datahora, cod_representante, status_visita) ' +
        'values (:p0, :p1, :p2, ''N'', :p3, :p4, :p5, :p6, :p7)';
      Q.ParamByName('p0').AsInteger := FCodCliente;
      Q.ParamByName('p1').AsString := FormatDateTime('yyyy-mm-dd', Date);
      Q.ParamByName('p2').AsString := LVendeu;
      Q.ParamByName('p3').AsString := LMotivo;
      Q.ParamByName('p4').AsFloat := FValorPedido;
      Q.ParamByName('p5').AsString := LDataHora;
      Q.ParamByName('p6').AsInteger := CodRepresentanteAtual;
      Q.ParamByName('p7').AsString := LStatus;
      Q.ExecSQL;
      ShowMessage('Resultado da visita salvo.');
      Close;
    except
      on E: Exception do
        ShowMessage('Erro ao salvar visita: ' + E.Message);
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmVisitaResultado.ApplyResponsiveLayout;
var
  LIsLandscape: Boolean;
  LContentW: Single;
  LPad: Single;
  LGap: Single;
  LBottomSafe: Single;
  LTop: Single;
  LX: Single;
  LRightX: Single;
  LLeftW: Single;
  LRightW: Single;
begin
  if (Width <= 0) or (Height <= 0) then
    Exit;

  LIsLandscape := Width > Height;
  LPad := 22;
  LGap := IfThen(LIsLandscape, 12, 14);
  LBottomSafe := AndroidBottomSafeMargin(LIsLandscape);

  TopBar.Align := TAlignLayout.None;
  TopBar.SetBounds(0, 0, Width, IfThen(LIsLandscape, 62, 106));
  LbTitulo.SetBounds(30, IfThen(LIsLandscape, 13, 36), Width - 60, 38);
  LbSubtitulo.SetBounds(32, LbTitulo.Position.Y + IfThen(LIsLandscape, 29, 32), Width - 64, 24);
  LbTitulo.TextSettings.Font.Size := IfThen(LIsLandscape, 22, 30);
  LbSubtitulo.TextSettings.Font.Size := IfThen(LIsLandscape, 11, 16);

  lbottom.Align := TAlignLayout.None;
  lbottom.SetBounds(0, Height - IfThen(LIsLandscape, 54, 76) - LBottomSafe,
    Width, IfThen(LIsLandscape, 54, 76));
  BtnCancelar.SetBounds(20, IfThen(LIsLandscape, 4, 10), IfThen(LIsLandscape, 184, 164), 44);
  LayoutCancelar.SetBounds(0, 0, BtnCancelar.Width, BtnCancelar.Height);
  LbCancelar.SetBounds(0, 0, LayoutCancelar.Width, LayoutCancelar.Height);
  BtnSalvar.SetBounds(Width - IfThen(LIsLandscape, 218, 198), IfThen(LIsLandscape, 4, 10),
    IfThen(LIsLandscape, 198, 178), 44);

  LContentW := Width - (LPad * 2);
  if LIsLandscape then
  begin
    if LContentW > 760 then
      LContentW := 760;
  end
  else if LContentW > 720 then
    LContentW := 720;
  LX := (Width - LContentW) / 2;
  LTop := TopBar.Height + LGap;

  if LIsLandscape then
  begin
    LLeftW := (LContentW - LGap) * 0.46;
    LRightW := LContentW - LGap - LLeftW;
    LRightX := LX + LLeftW + LGap;
    CardCliente.SetBounds(LX, LTop, LLeftW, 98);
    CardStatus.SetBounds(LRightX, LTop, LRightW, 98);
    CardObs.SetBounds(LX, CardCliente.Position.Y + CardCliente.Height + LGap,
      LLeftW, lbottom.Position.Y - (CardCliente.Position.Y + CardCliente.Height + LGap + 8));
    if CardObs.Height < 126 then
      CardObs.Height := 126;
  end
  else
  begin
    CardCliente.SetBounds(LX, LTop, LContentW, 96);
    CardStatus.SetBounds(LX, CardCliente.Position.Y + CardCliente.Height + LGap, LContentW, 158);
    CardObs.SetBounds(LX, CardStatus.Position.Y + CardStatus.Height + LGap,
      LContentW, lbottom.Position.Y - (CardStatus.Position.Y + CardStatus.Height + LGap + 8));
    if CardObs.Height < 120 then
      CardObs.Height := 120;
  end;

  LbClienteTitulo.SetBounds(26, IfThen(LIsLandscape, 18, 22), CardCliente.Width - 52, 20);
  LbClienteNome.SetBounds(26, IfThen(LIsLandscape, 42, 48), CardCliente.Width - 52, 28);
  LbTempoAtendimento.SetBounds(26, IfThen(LIsLandscape, 70, 78), CardCliente.Width - 52, 22);
  LbClienteTitulo.TextSettings.Font.Size := 12;
  LbClienteNome.TextSettings.Font.Size := IfThen(LIsLandscape, 15, 17);
  LbTempoAtendimento.TextSettings.Font.Size := 12;

  LbStatusTitulo.SetBounds(26, IfThen(LIsLandscape, 18, 18), CardStatus.Width - 52, 22);
  CbStatusVisita.SetBounds(26, IfThen(LIsLandscape, 48, 48), CardStatus.Width - 52, 38);

  if LIsLandscape then
  begin
    CbStatusVisita.SetBounds(26, 48, CardStatus.Width - 52, 34);
  end;

  LbObsTitulo.SetBounds(26, 22, CardObs.Width - 52, 22);
  MemoObs.SetBounds(26, 50, CardObs.Width - 52, IfThen(LIsLandscape, CardObs.Height - 98, CardObs.Height - 108));
  LbObsTitulo.TextSettings.Font.Size := 14;
end;

procedure TfrmVisitaResultado.FormShow(Sender: TObject);
begin
  OnClose := FormClose;
  ApplyResponsiveLayout;
  AtualizarStatus;
end;

procedure TfrmVisitaResultado.FormResize(Sender: TObject);
begin
  ApplyResponsiveLayout;
end;

procedure TfrmVisitaResultado.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
  frmVisitaResultado := nil;
end;

procedure TfrmVisitaResultado.CbStatusVisitaChange(Sender: TObject);
begin
  AtualizarStatus;
end;

procedure TfrmVisitaResultado.BtnSalvarClick(Sender: TObject);
begin
  SalvarVisita;
end;

procedure TfrmVisitaResultado.BtnCancelarClick(Sender: TObject);
begin
  Close;
end;

end.
