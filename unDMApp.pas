unit unDMApp;

interface

uses
  System.Classes,
  System.JSON,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.NetEncoding,
  System.SysUtils,
  System.IOUtils,
  System.StrUtils,
  System.Generics.Collections,
  System.Variants,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.DApt,
  FireDAC.DApt.Intf,
  FireDAC.Phys,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.Async,
  FireDAC.Stan.Def,
  FireDAC.Stan.Error,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Pool,
  FireDAC.FMXUI.Wait, FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteWrapper.Stat,
  FireDAC.DatS, FireDAC.Comp.DataSet;

type
  TSyncProgressEvent = procedure(const ATable: string; AInserted, ATotal: Integer; AIsNewTable: Boolean) of object;
  TdmApp = class(TDataModule)
    FDConnection: TFDConnection;
    FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink;
    QExec: TFDQuery;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    FHttp: THTTPClient;
    FOnSyncProgress: TSyncProgressEvent;
    FRequestLogOk: Integer;
    FSkipConnectionCheck: Integer;
    FLastVendas1NumDocs: TStringList;
    function BuildUrl(const AEndpoint: string): string;
    function DatabaseFileName: string;
    function ExecuteJsonArrayRequest(const AEndpoint: string; ABody: TJSONObject): TJSONArray;
    function ExecuteJsonObjectRequest(const AEndpoint: string; ABody: TJSONObject): TJSONObject;
    function GetJsonValueCI(AObj: TJSONObject; const AName: string): TJSONValue;
    function GetApiBaseUrl: string;
    function GetScalarAsString(const ASql: string; const AParams: array of Variant): string;
    function GetScalarInt64(const ASql: string; const AParams: array of Variant): Int64;
    function NormalizeVendas1Json(const AVendas1Json: string): string;
    function IsVendas2Field(const AName: string): Boolean;
    function NormalizeVendas2ItemJson(AItemObj: TJSONObject; const ACodCliente, ACodRepresentante: Integer): TJSONObject;
    procedure AssignParamFromJson(AParam: TFDParam; AValue: TJSONValue);
    procedure AssignParamFromVariant(AParam: TFDParam; const AValue: Variant);
    procedure LogSyncSql(const ATable, ASql: string; AParams: TFDParams);
    procedure LogSyncSqlError(const ATable, ASql: string; AParams: TFDParams; const AError: string);
    procedure EnsureDatabase;
    procedure ExecSQL(const ASql: string; const AParams: array of Variant);
    procedure GetTableColumns(const ATableName: string; AColumns, ATypes: TStrings; AIncludeBlobs: Boolean = False);
    procedure LogRequest(const AMethod, AEndpoint, ARequest, AResponse: string; AStatusCode: Integer);
    function RequestLogAvailable: Boolean;
    procedure OpenConnection;
    procedure SeedConfig;
    procedure SetApiBaseUrl(const AValue: string);
    function TableExists(const ATableName: string): Boolean;
    function SqliteTypeToFieldType(const ASqliteType: string): TFieldType;
  public
    procedure AddRequestLog(const AMethod, AEndpoint, ARequest, AResponse: string; AStatusCode: Integer);
    property OnSyncProgress: TSyncProgressEvent read FOnSyncProgress write FOnSyncProgress;
    procedure ClearSyncData;
    function ShouldClearSyncData(out AReason: string): Boolean;
    function CountPendingPedidos: Integer;
    function GetSessionLogin: string;
    function ListCachedTables: TJSONArray;
    function Login(const ALogin, ASenha: string): TJSONObject;
    function QueuePedido(const AVendas1, AVendas2: string): Integer;
    function CreateOutboundPedidoDraft(const AVendas1Json, ARepresentativeCode: string): Integer;
    procedure UpdateOutboundPedidoDraft(const APedidoId: Integer; const AVendas1Json, ARepresentativeCode: string);
    function AddOutboundPedidoItem(const APedidoId: Integer; const AVendas2Json: string): Integer;
    function CountOutboundPedidoItens(const APedidoId: Integer): Integer;
    function IsDailySyncRequired(out AMessage: string): Boolean;
    function SendPendingPedidos: Integer;
    function SyncTable(const ATableName, ACodRepresentante: string; ALimit: Integer): Integer;
    function SyncAllTables(const ACodRepresentante: string): Integer;
    function SyncAllTablesSelected(const ACodRepresentante: string; const ATables: array of string): Integer;
    procedure SetSyncTableError(const ATableName, ACodRepresentante, AError: string);
    property ApiBaseUrl: string read GetApiBaseUrl write SetApiBaseUrl;
  end;

var
  dmApp: TdmApp;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

uses
  unFuncoes;


const
  CSchemaSQL =
    'CREATE TABLE IF NOT EXISTS app_config (' +
    ' key TEXT PRIMARY KEY,' +
    ' value TEXT,' +
    ' updated_at TEXT DEFAULT CURRENT_TIMESTAMP' +
    ');' +
    'CREATE TABLE IF NOT EXISTS api_session (' +
    ' id INTEGER PRIMARY KEY CHECK (id = 1),' +
    ' base_url TEXT,' +
    ' login TEXT,' +
    ' senha TEXT,' +
    ' user_json TEXT,' +
    ' last_login_at TEXT,' +
    ' last_error TEXT' +
    ');' +
    'CREATE TABLE IF NOT EXISTS sync_table_state (' +
    ' table_name TEXT PRIMARY KEY,' +
    ' representative_code TEXT,' +
    ' last_sync_at TEXT,' +
    ' row_count INTEGER DEFAULT 0,' +
    ' last_error TEXT' +
    ');' +
    'CREATE TABLE IF NOT EXISTS outbound_pedido (' +
    ' id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    ' local_uuid TEXT NOT NULL UNIQUE,' +
    ' numdoc_remote INTEGER,' +
    ' representative_code TEXT,' +
    ' status TEXT NOT NULL DEFAULT ''PENDENTE'',' +
    ' vendas1_json TEXT NOT NULL,' +
    ' created_at TEXT DEFAULT CURRENT_TIMESTAMP,' +
    ' sent_at TEXT,' +
    ' last_error TEXT' +
    ');' +
    'CREATE TABLE IF NOT EXISTS outbound_pedido_item (' +
    ' id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    ' pedido_id INTEGER NOT NULL,' +
    ' item_ord INTEGER NOT NULL,' +
    ' vendas2_json TEXT NOT NULL,' +
    ' created_at TEXT DEFAULT CURRENT_TIMESTAMP,' +
    ' FOREIGN KEY (pedido_id) REFERENCES outbound_pedido(id) ON DELETE CASCADE,' +
    ' UNIQUE(pedido_id, item_ord)' +
    ');' +
    'CREATE TABLE IF NOT EXISTS request_log (' +
    ' id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    ' endpoint TEXT NOT NULL,' +
    ' method TEXT NOT NULL,' +
    ' request_json TEXT,' +
    ' response_json TEXT,' +
    ' status_code INTEGER,' +
    ' created_at TEXT DEFAULT CURRENT_TIMESTAMP' +
    ');' +
    'CREATE TABLE IF NOT EXISTS cidades (' +
    ' cod_cidade INTEGER PRIMARY KEY NOT NULL,' +
    ' cod_ibge INTEGER,' +
    ' nom_cidade TEXT,' +
    ' uf TEXT,' +
    ' cod_representante INTEGER,' +
    ' mesocod TEXT,' +
    ' microcod TEXT,' +
    ' populacao INTEGER,' +
    ' cod_supervisor INTEGER' +
    ');' +
    'CREATE TABLE IF NOT EXISTS cliente (' +
    ' cod_cliente INTEGER PRIMARY KEY NOT NULL,' +
    ' dta_cad TEXT,' +
    ' pri_compra TEXT,' +
    ' nom_cliente TEXT,' +
    ' nom_fantasia TEXT,' +
    ' endereco TEXT,' +
    ' complemento TEXT,' +
    ' proximo TEXT,' +
    ' bairro TEXT,' +
    ' cep TEXT,' +
    ' cod_cidade INTEGER,' +
    ' tip_pessoa TEXT,' +
    ' telefone TEXT,' +
    ' email TEXT,' +
    ' aviso TEXT,' +
    ' cnpj TEXT,' +
    ' ie TEXT,' +
    ' im TEXT,' +
    ' prod_rural INTEGER,' +
    ' contato TEXT,' +
    ' fone_contato TEXT,' +
    ' limite REAL,' +
    ' cpf TEXT,' +
    ' rg TEXT,' +
    ' naturalidade TEXT,' +
    ' est_civil INTEGER,' +
    ' pai TEXT,' +
    ' mae TEXT,' +
    ' tip_residencia INTEGER,' +
    ' aluguel REAL,' +
    ' empresa TEXT,' +
    ' end_tracli TEXT,' +
    ' bairro_trabalho TEXT,' +
    ' cid_trabalho INTEGER,' +
    ' fone_trabalho TEXT,' +
    ' cargo TEXT,' +
    ' salario REAL,' +
    ' nom_conjugue TEXT,' +
    ' emp_conj TEXT,' +
    ' end_emp_conj TEXT,' +
    ' cid_emp_conj INTEGER,' +
    ' fone_emp_conj TEXT,' +
    ' cargo_conj TEXT,' +
    ' nom_ref1 TEXT,' +
    ' fone_ref1 TEXT,' +
    ' obs_ref1 TEXT,' +
    ' nom_ref2 TEXT,' +
    ' fone_ref2 TEXT,' +
    ' obs_ref2 TEXT,' +
    ' cad_spc INTEGER,' +
    ' dta_cad_spc TEXT,' +
    ' dta_aniversario TEXT,' +
    ' observacoes TEXT,' +
    ' fax TEXT,' +
    ' manequim TEXT,' +
    ' calcado TEXT,' +
    ' cor_preferida TEXT,' +
    ' contato_preferido INTEGER,' +
    ' estilo INTEGER,' +
    ' contato_fone TEXT,' +
    ' contato_email TEXT,' +
    ' contato_correspondencia TEXT,' +
    ' id_antigo INTEGER,' +
    ' ponto_fidelidade REAL,' +
    ' id_representante INTEGER,' +
    ' id_fop INTEGER,' +
    ' prazo_maximo REAL,' +
    ' desconto_maximo REAL,' +
    ' cliente_bloqueado TEXT,' +
    ' status TEXT,' +
    ' cod_empresa INTEGER,' +
    ' nr_endereco TEXT,' +
    ' nfe_email TEXT,' +
    ' sincronizar_palm TEXT,' +
    ' pre_cadastro TEXT,' +
    ' email_end_nfe TEXT,' +
    ' email_adicional1 TEXT,' +
    ' email_adicional2 TEXT,' +
    ' email_adicional3 TEXT,' +
    ' celular TEXT,' +
    ' dta_aniversario_contato TEXT,' +
    ' aceita_nota_simples TEXT,' +
    ' consumidor_final TEXT,' +
    ' operadora TEXT,' +
    ' construtora TEXT,' +
    ' ultconsserasa TEXT,' +
    ' desconto_especial REAL,' +
    ' total_credito REAL,' +
    ' periodo_frequencia_visitas TEXT,' +
    ' ultima_frequencia TEXT,' +
    ' suspensao_pis_confins TEXT,' +
    ' whastapp TEXT,' +
    ' pronautica TEXT,' +
    ' proemprego TEXT,' +
    ' saldo REAL' +
    ');' +
    'CREATE TABLE IF NOT EXISTS fop (' +
    ' cod_fop INTEGER PRIMARY KEY NOT NULL,' +
    ' nom_fop TEXT,' +
    ' nivel INTEGER,' +
    ' sincronizar_palm TEXT,' +
    ' desconto REAL,' +
    ' inativo_palm TEXT,' +
    ' ativo TEXT,' +
    ' min_dias INTEGER,' +
    ' max_dias INTEGER,' +
    ' avista TEXT,' +
    ' prazo_padrao INTEGER,' +
    ' conta_padrao INTEGER,' +
    ' nao_gerar_cr TEXT' +
    ');' +
    'CREATE TABLE IF NOT EXISTS grupo_representante (' +
    ' cod_grupo INTEGER NOT NULL,' +
    ' id_representante INTEGER NOT NULL,' +
    ' desconto_maximo REAL,' +
    ' comissao_inicial_interno REAL,' +
    ' comissao_inicial_outros REAL,' +
    ' escala_comissao_interno REAL,' +
    ' escala_comissao_outros REAL,' +
    ' escala_desconto REAL,' +
    ' PRIMARY KEY (cod_grupo, id_representante)' +
    ');' +
    'CREATE TABLE IF NOT EXISTS prazo (' +
    ' id INTEGER PRIMARY KEY NOT NULL,' +
    ' prazo TEXT,' +
    ' qtd_parcelas INTEGER,' +
    ' sincronizar_palm TEXT,' +
    ' ativo TEXT,' +
    ' inativo_palm TEXT,' +
    ' desconto REAL,' +
    ' valor_minimo_pedido REAL,' +
    ' total_dias INTEGER' +
    ');' +
    'CREATE TABLE IF NOT EXISTS prazo_representante (' +
    ' id_prazo INTEGER NOT NULL,' +
    ' id_representante INTEGER NOT NULL,' +
    ' valor_minimo REAL,' +
    ' PRIMARY KEY (id_prazo, id_representante)' +
    ');' +
    'CREATE TABLE IF NOT EXISTS produto (' +
    ' cod_produto INTEGER PRIMARY KEY NOT NULL,' +
    ' nom_produto TEXT NOT NULL,' +
    ' cod_grupo INTEGER,' +
    ' unidade TEXT,' +
    ' peso REAL,' +
    ' ref_fabrica TEXT,' +
    ' cod_prateleira TEXT,' +
    ' qtd_estoque REAL,' +
    ' qtd_reservado REAL,' +
    ' qtd_estoque_min REAL,' +
    ' etiqueta_lin1 TEXT,' +
    ' etiqueta_lin2 TEXT,' +
    ' observacao TEXT,' +
    ' origem_mercadoria TEXT,' +
    ' trib_icms TEXT,' +
    ' ipi REAL,' +
    ' custo REAL,' +
    ' impostos REAL,' +
    ' geral REAL,' +
    ' outros REAL,' +
    ' lucro REAL,' +
    ' avisar_prod_desat TEXT,' +
    ' qtd_dias_desat INTEGER,' +
    ' dta_ult_atualizacao TEXT,' +
    ' custo_medio REAL,' +
    ' custo_calculado REAL,' +
    ' custo_atualizado REAL,' +
    ' qtd_ult_entrada REAL,' +
    ' qtd_ult_saida REAL,' +
    ' dta_ult_entrada TEXT,' +
    ' dta_ult_saida TEXT,' +
    ' qtd_embalagem REAL,' +
    ' preco_venda REAL,' +
    ' status TEXT,' +
    ' estoque_minimo REAL,' +
    ' grade INTEGER,' +
    ' cod_colecao INTEGER,' +
    ' calcula_preco_automatic TEXT,' +
    ' fornecedor_principal INTEGER,' +
    ' cod_empresa INTEGER,' +
    ' cod_estoque INTEGER,' +
    ' desconto_maximo REAL,' +
    ' id_marca INTEGER,' +
    ' cod_pro2 TEXT,' +
    ' icms REAL,' +
    ' margem_valor_agregado_st REAL,' +
    ' cod_fiscal_produto TEXT,' +
    ' ncm TEXT,' +
    ' estoque_maximo REAL,' +
    ' mts_rolo REAL,' +
    ' ord_pauta INTEGER,' +
    ' cont_estoque_ago_2010 REAL,' +
    ' promocao TEXT,' +
    ' perc_margem_minima REAL,' +
    ' subcategoria INTEGER,' +
    ' preco_promocao REAL,' +
    ' qtd_multipla REAL,' +
    ' sincronizar_palm TEXT,' +
    ' promocao_pacote TEXT,' +
    ' id_plano_contas INTEGER,' +
    ' grade_comissao TEXT,' +
    ' custo_total REAL,' +
    ' comissao_inicial_interno REAL,' +
    ' comissao_inicial_outros REAL,' +
    ' escala_comissao_interno REAL,' +
    ' escala_comissao_outros REAL,' +
    ' escala_desconto REAL,' +
    ' codigo_barra TEXT,' +
    ' bonificacao_apenas TEXT,' +
    ' mostrar_emb_etiqueta TEXT,' +
    ' indisponivel TEXT,' +
    ' loc_a_fila INTEGER,' +
    ' loc_a_lado INTEGER,' +
    ' loc_a_andar INTEGER,' +
    ' loc_a_box INTEGER,' +
    ' loc_padrao INTEGER,' +
    ' loc_b_andar INTEGER,' +
    ' loc_b_box INTEGER,' +
    ' revenda TEXT,' +
    ' tinta_base TEXT,' +
    ' aviso_revisao_veiculo TEXT,' +
    ' proxima_revisao INTEGER,' +
    ' tipo_revisao TEXT,' +
    ' nao_validar_margem TEXT,' +
    ' comissao_fixa REAL,' +
    ' custo_materia_prima REAL,' +
    ' custo_mao_de_obra REAL,' +
    ' cest TEXT,' +
    ' frequencia TEXT,' +
    ' potencia TEXT,' +
    ' tensao TEXT,' +
    ' corrente TEXT,' +
    ' processos BLOB,' +
    ' custosubtotal REAL,' +
    ' entst REAL,' +
    ' entfrete REAL,' +
    ' entipi REAL,' +
    ' enticms REAL,' +
    ' materia_prima TEXT,' +
    ' dta_alt_preco TEXT' +
    ');' +
    'CREATE TABLE IF NOT EXISTS subcategoria (' +
    ' id INTEGER PRIMARY KEY NOT NULL,' +
    ' subcategoria TEXT NOT NULL,' +
    ' imagem TEXT,' +
    ' categoria INTEGER,' +
    ' imagem_bd BLOB,' +
    ' alterou_imagem TEXT,' +
    ' id_marca INTEGER,' +
    ' video TEXT' +
    ');' +
    'CREATE TABLE IF NOT EXISTS produto_representante (' +
    ' cod_produto INTEGER NOT NULL,' +
    ' id_representante INTEGER NOT NULL,' +
    ' desconto_maximo REAL,' +
    ' comissao_inicial_interno REAL,' +
    ' comissao_inicial_outros REAL,' +
    ' escala_comissao_interno REAL,' +
    ' escala_comissao_outros REAL,' +
    ' escala_desconto REAL,' +
    ' qtd_promocao REAL,' +
    ' preco_promocao REAL' +
    ');' +
    'CREATE TABLE IF NOT EXISTS produto_representante_inativos (' +
    ' cod_produto INTEGER NOT NULL,' +
    ' id_representante INTEGER NOT NULL' +
    ');' +
    'CREATE TABLE IF NOT EXISTS representante (' +
    ' id INTEGER PRIMARY KEY NOT NULL,' +
    ' nom_representante TEXT,' +
    ' nom_empresa TEXT,' +
    ' endereco TEXT,' +
    ' bairro TEXT,' +
    ' cep TEXT,' +
    ' id_cidade INTEGER,' +
    ' cpf TEXT,' +
    ' rg TEXT,' +
    ' cnpj TEXT,' +
    ' ie TEXT,' +
    ' fone TEXT,' +
    ' fax TEXT,' +
    ' celular TEXT,' +
    ' nr_conta_corrente TEXT,' +
    ' nr_agencia TEXT,' +
    ' nr_banco TEXT,' +
    ' email TEXT,' +
    ' home_page TEXT,' +
    ' perc_comissao_fixa REAL,' +
    ' ativo TEXT,' +
    ' funcionario TEXT,' +
    ' web_nome TEXT,' +
    ' uf_atuacao TEXT,' +
    ' web_cidades_atuacao TEXT,' +
    ' sincronizar_palm TEXT,' +
    ' salario REAL,' +
    ' plr TEXT,' +
    ' plr_fabrica TEXT,' +
    ' supervisor TEXT,' +
    ' titular_conta TEXT,' +
    ' margem_minima REAL,' +
    ' margem_ideal REAL,' +
    ' indice_abaixo REAL,' +
    ' indice_acima REAL,' +
    ' tipo_sistema INTEGER,' +
    ' plr_valor REAL,' +
    ' comissao_fixa TEXT,' +
    ' admissao TEXT,' +
    ' demissao TEXT,' +
    ' operadora TEXT,' +
    ' obs BLOB,' +
    ' mobile INTEGER,' +
    ' tipo_comissao INTEGER,' +
    ' margem_plr REAL,' +
    ' whatsapp TEXT,' +
    ' cod_tablet INTEGER,' +
    ' somente_consumidor_final TEXT' +
    ');' +
    'CREATE TABLE IF NOT EXISTS vendas1 (' +
    ' numdoc INTEGER NOT NULL,' +
    ' hora TEXT,' +
    ' dtadoc TEXT,' +
    ' cod_cliente INTEGER,' +
    ' cod_usuario INTEGER,' +
    ' cod_empresa INTEGER NOT NULL,' +
    ' faturado INTEGER,' +
    ' consignacao INTEGER,' +
    ' orcamento INTEGER,' +
    ' entregue INTEGER,' +
    ' tot_bruto REAL,' +
    ' desconto REAL,' +
    ' tot_liquido_ant REAL,' +
    ' prazo_pgto TEXT,' +
    ' cod_fop INTEGER,' +
    ' num_cupom TEXT,' +
    ' tipo_venda TEXT,' +
    ' qtd_parcelas TEXT,' +
    ' ponto_usado REAL,' +
    ' usuario_desfaturou INTEGER,' +
    ' cod_representante INTEGER,' +
    ' cod_prazo_pgto INTEGER,' +
    ' custo_total REAL,' +
    ' lucro_medio REAL,' +
    ' dta_emissao TEXT,' +
    ' dta_saida TEXT,' +
    ' empresa_faturar INTEGER,' +
    ' nf TEXT,' +
    ' observacoes_pedido TEXT,' +
    ' observacoes_nota TEXT,' +
    ' cod_transportadora INTEGER,' +
    ' tipo_frete TEXT,' +
    ' volume_nota REAL,' +
    ' peso_nota REAL,' +
    ' cod_carga TEXT,' +
    ' vl_frete REAL,' +
    ' contato_frete TEXT,' +
    ' ped_impresso TEXT,' +
    ' dta_vencimento_consig TEXT,' +
    ' cancelado INTEGER,' +
    ' contem_avaria TEXT,' +
    ' contem_etiqueta TEXT,' +
    ' motivo_troca TEXT,' +
    ' nr_venda_original INTEGER,' +
    ' pedido TEXT,' +
    ' venda_enviada TEXT,' +
    ' credito_usado REAL,' +
    ' nr_pedido_palm TEXT,' +
    ' boleto_anexo TEXT,' +
    ' cod_fiscal TEXT,' +
    ' vlr_comissao REAL,' +
    ' vlr_bc_icms_ant REAL,' +
    ' vlr_icms_ant REAL,' +
    ' vlr_st_ant REAL,' +
    ' vlr_tot_nf_ant REAL,' +
    ' vlr_bc_icms_st REAL,' +
    ' chave_nfe TEXT,' +
    ' recibo_nfe TEXT,' +
    ' status_nfe INTEGER,' +
    ' motivo_nfe TEXT,' +
    ' digest_nfe TEXT,' +
    ' protocolo_nfe INTEGER,' +
    ' data_rec_nfe TEXT,' +
    ' justif_canc_nfe TEXT,' +
    ' cod_supervisor INTEGER,' +
    ' cod_fornecedor INTEGER,' +
    ' nfe INTEGER,' +
    ' vlr_ipi REAL,' +
    ' palm_nr_conexao INTEGER,' +
    ' sincronizar_palm TEXT,' +
    ' numdoc_ref INTEGER,' +
    ' frete_combinado TEXT,' +
    ' dt_frete_combinado TEXT,' +
    ' email_nfe INTEGER,' +
    ' email_pedido INTEGER,' +
    ' pedido_vendedor TEXT,' +
    ' usuario_checou_pedido_vendedor INTEGER,' +
    ' conta_boleto INTEGER,' +
    ' usuario_checou_frete_combinado INTEGER,' +
    ' aberto_usuario TEXT,' +
    ' maquina_usuario_aberto TEXT,' +
    ' cartacorrecao TEXT,' +
    ' avisognre TEXT,' +
    ' motivo_nfe_cancel_interno INTEGER,' +
    ' usuario_liberou_desconto TEXT,' +
    ' motivo_liberacao_desconto TEXT,' +
    ' chave_nfe_dev TEXT,' +
    ' recibo_nfe_dev TEXT,' +
    ' status_nfe_dev INTEGER,' +
    ' motivo_nfe_dev TEXT,' +
    ' digest_nfe_dev TEXT,' +
    ' protocolo_nfe_dev INTEGER,' +
    ' data_rec_nfe_dev TEXT,' +
    ' justif_canc_nfe_dev TEXT,' +
    ' nfe_dev INTEGER,' +
    ' perc_comissao REAL,' +
    ' liberar_faturamento TEXT,' +
    ' numdoc_grupo INTEGER,' +
    ' desconto_valor REAL,' +
    ' numdoc_destino INTEGER,' +
    ' valordescontoadic REAL,' +
    ' status_nfe_email TEXT,' +
    ' desconto_geral REAL,' +
    ' vlr_descoaliq_icms REAL,' +
    ' vlr_desconto_geral REAL,' +
    ' atualizar_estoque TEXT,' +
    ' processo_id INTEGER,' +
    ' xml BLOB,' +
    ' xml_dev BLOB,' +
    ' tot_liquido REAL,' +
    ' vlr_bc_icms REAL,' +
    ' vlr_icms REAL,' +
    ' vlr_st REAL,' +
    ' vlr_tot_nf REAL,' +
    ' data_mov TEXT,' +
    ' entradanaodevolucao TEXT,' +
    ' solicitar_emissor TEXT,' +
    ' status_emissor TEXT,' +
    ' status_motivo TEXT,' +
    ' tiponfe TEXT,' +
    ' nfeentradasaida TEXT,' +
    ' num_oc INTEGER,' +
    ' consumidor_final TEXT,' +
    ' PRIMARY KEY (numdoc, cod_empresa)' +
    ');' +
    'CREATE TABLE IF NOT EXISTS vendas2 (' +
    ' id INTEGER PRIMARY KEY NOT NULL,' +
    ' numdoc INTEGER,' +
    ' dtadoc TEXT,' +
    ' cod_produto INTEGER,' +
    ' cod_cliente INTEGER,' +
    ' cod_representante INTEGER,' +
    ' id_cor INTEGER,' +
    ' id_tamanho INTEGER,' +
    ' qtd REAL,' +
    ' qtd_devolvida REAL,' +
    ' devolvido TEXT,' +
    ' desconto REAL,' +
    ' volume REAL,' +
    ' cod_empresa INTEGER,' +
    ' nr_pedido_palm TEXT,' +
    ' preco_bruto REAL,' +
    ' sub_total_bruto REAL,' +
    ' vlr_comissao REAL,' +
    ' troca TEXT,' +
    ' cod_fiscal_item TEXT,' +
    ' icms_item REAL,' +
    ' vlr_icms_st_ant REAL,' +
    ' vlr_bc_st_ant REAL,' +
    ' vlr_icms_item_ant REAL,' +
    ' ncm TEXT,' +
    ' vlr_bc_ant REAL,' +
    ' ipi_item REAL,' +
    ' vlr_ipi_item REAL,' +
    ' vlr_agr_item REAL,' +
    ' trib_icms TEXT,' +
    ' cesta_basica TEXT,' +
    ' cod_supervisor TEXT,' +
    ' qtd_embalagem REAL,' +
    ' preco_custo REAL,' +
    ' perc_comissao REAL,' +
    ' promocao TEXT,' +
    ' desconto_max REAL,' +
    ' checado TEXT,' +
    ' preco_base REAL,' +
    ' desconto_valor REAL,' +
    ' nao_validar_margem TEXT,' +
    ' desconto_valor_geral REAL,' +
    ' cest TEXT,' +
    ' preco REAL,' +
    ' sub_total REAL,' +
    ' vlr_bc REAL,' +
    ' vlr_bc_st REAL,' +
    ' vlr_icms_item REAL,' +
    ' vlr_icms_st REAL' +
    ');';

function TdmApp.BuildUrl(const AEndpoint: string): string;
var
  LBase: string;
  LEndpoint: string;
begin
  LBase := Trim(ApiBaseUrl);
  LEndpoint := Trim(AEndpoint);
  while EndsText('/', LBase) do
    Delete(LBase, Length(LBase), 1);
  while StartsText('/', LEndpoint) do
    Delete(LEndpoint, 1, 1);
  Result := LBase + '/' + LEndpoint;
end;

function TdmApp.GetJsonValueCI(AObj: TJSONObject; const AName: string): TJSONValue;
var
  LPair: TJSONPair;
begin
  Result := nil;
  if not Assigned(AObj) then
    Exit;

  Result := AObj.GetValue(AName);
  if Assigned(Result) then
    Exit;

  for LPair in AObj do
    if SameText(LPair.JsonString.Value, AName) then
      Exit(LPair.JsonValue);
end;

procedure TdmApp.LogSyncSql(const ATable, ASql: string; AParams: TFDParams);
var
  LPath: string;
  LLine: TStringBuilder;
  I: Integer;
  LValue: string;
begin
  {$IFDEF MSWINDOWS}
  LPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'sync_sql.log');
  {$ELSE}
  // Mesmo motivo do SQLite: em Android 11+/MIUI a pasta Documents compartilhada
  // pode ser bloqueada. O log da sincronizacao fica na pasta privada do app.
  LPath := TPath.Combine(TPath.GetDocumentsPath, 'WorbyRep');
  if not TDirectory.Exists(LPath) then
    TDirectory.CreateDirectory(LPath);
  LPath := TPath.Combine(LPath, 'sync_sql.log');
  {$ENDIF}

  LLine := TStringBuilder.Create;
  try
    LLine.Append(FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    LLine.Append(' | ');
    LLine.Append(ATable);
    LLine.Append(' | ');
    LLine.Append(ASql);
    if Assigned(AParams) then
    begin
      LLine.Append(' | params: ');
      for I := 0 to AParams.Count - 1 do
      begin
        if I > 0 then
          LLine.Append('; ');
        LValue := AParams[I].AsString;
        LValue := StringReplace(LValue, #13#10, ' ', [rfReplaceAll]);
        LValue := StringReplace(LValue, #10, ' ', [rfReplaceAll]);
        LLine.Append(AParams[I].Name);
        LLine.Append('=');
        LLine.Append(LValue);
      end;
    end;
    try
      TFile.AppendAllText(LPath, LLine.ToString + sLineBreak, TEncoding.UTF8);
    except
      // Falha ao gravar log nao pode interromper a sincronizacao.
    end;
  finally
    LLine.Free;
  end;
end;

procedure TdmApp.LogSyncSqlError(const ATable, ASql: string; AParams: TFDParams; const AError: string);
begin
  LogSyncSql(ATable, ASql + ' | ERROR: ' + AError, AParams);
end;

procedure TdmApp.AssignParamFromJson(AParam: TFDParam; AValue: TJSONValue);
var
  LText: string;
  LInt: Int64;
  LFloat: Double;
  LFS: TFormatSettings;
  LBytes: TBytes;
  LDate: TDateTime;
begin
  if (AValue = nil) or (AValue is TJSONNull) then
  begin
    AParam.Clear;
    Exit;
  end;

  if AParam.DataType in [ftBlob, ftMemo, ftWideMemo] then
  begin
    LText := AValue.Value;
    try
      LBytes := TNetEncoding.Base64.DecodeStringToBytes(LText);
    except
      LBytes := TEncoding.UTF8.GetBytes(LText);
    end;
    AParam.DataType := ftBlob;
    AParam.Value := LBytes;
    Exit;
  end;

  if AValue is TJSONTrue then
  begin
    AParam.AsBoolean := True;
    Exit;
  end;

  if AValue is TJSONFalse then
  begin
    AParam.AsBoolean := False;
    Exit;
  end;

  if AValue is TJSONNumber then
  begin
    LText := TJSONNumber(AValue).ToJSON;
    if Pos('.', LText) > 0 then
    begin
      LFS := TFormatSettings.Create;
      LFS.DecimalSeparator := '.';
      if not TryStrToFloat(LText, LFloat, LFS) then
        raise Exception.Create('Numero JSON invalido: ' + LText);
      AParam.AsFloat := LFloat;
    end
    else
    begin
      if not TryStrToInt64(LText, LInt) then
        raise Exception.Create('Inteiro JSON invalido: ' + LText);
      AParam.AsLargeInt := LInt;
    end;
    Exit;
  end;

  if AValue is TJSONString then
  begin
    LText := Trim(AValue.Value);
    if LText = '' then
    begin
      AParam.Clear;
      Exit;
    end;

    case AParam.DataType of
      ftLargeInt, ftInteger, ftSmallint, ftWord, ftAutoInc:
        begin
          if TryStrToInt64(LText, LInt) then
            AParam.AsLargeInt := LInt
          else
            AParam.Clear;
          Exit;
        end;
      ftFloat, ftCurrency, ftFMTBcd, ftBCD:
        begin
          LFS := TFormatSettings.Create;
          LFS.DecimalSeparator := '.';
          if not TryStrToFloat(LText, LFloat, LFS) then
          begin
            LFS.DecimalSeparator := ',';
            if not TryStrToFloat(LText, LFloat, LFS) then
            begin
              AParam.Clear;
              Exit;
            end;
          end;
          AParam.AsFloat := LFloat;
          Exit;
        end;
      ftDate, ftDateTime, ftTimeStamp, ftTime:
        begin
          LFS := TFormatSettings.Create;
          LFS.DateSeparator := '-';
          LFS.TimeSeparator := ':';
          LFS.ShortDateFormat := 'yyyy-mm-dd';
          LFS.LongDateFormat := 'yyyy-mm-dd';
          LFS.ShortTimeFormat := 'hh:nn:ss';
          LFS.LongTimeFormat := 'hh:nn:ss';
          if TryStrToDateTime(LText, LDate, LFS) then
            AParam.AsDateTime := LDate
          else
            AParam.Clear;
          Exit;
        end;
      ftBoolean:
        begin
          if SameText(LText, 'S') or SameText(LText, '1') or SameText(LText, 'TRUE') then
            AParam.AsBoolean := True
          else if SameText(LText, 'N') or SameText(LText, '0') or SameText(LText, 'FALSE') then
            AParam.AsBoolean := False
          else
            AParam.Clear;
          Exit;
        end;
    end;
  end;

  AParam.AsString := AValue.Value;
end;

procedure TdmApp.AssignParamFromVariant(AParam: TFDParam; const AValue: Variant);
var
  Vt: Integer;
begin
  if VarIsNull(AValue) or VarIsClear(AValue) then
  begin
    AParam.DataType := ftString;
    AParam.Clear;
    Exit;
  end;

  Vt := VarType(AValue);
  case Vt of
    varSmallint, varInteger, varShortInt, varByte, varWord, varLongWord, varInt64:
      begin
        AParam.DataType := ftLargeInt;
        AParam.AsLargeInt := AValue;
      end;
    varSingle, varDouble, varCurrency:
      begin
        AParam.DataType := ftFloat;
        AParam.AsFloat := AValue;
      end;
    varBoolean:
      begin
        AParam.DataType := ftBoolean;
        AParam.AsBoolean := AValue;
      end;
    varDate:
      begin
        AParam.DataType := ftDateTime;
        AParam.AsDateTime := AValue;
      end;
  else
    AParam.DataType := ftString;
    AParam.AsString := VarToStr(AValue);
  end;
end;

function TdmApp.CountPendingPedidos: Integer;
begin
  Result := GetScalarInt64('select count(*) from outbound_pedido where coalesce(status, ''PENDENTE'') <> ''ENVIADO''', []);
end;

procedure TdmApp.ClearSyncData;
var
  LQuery: TFDQuery;
  LTable: string;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FDConnection;
    LQuery.SQL.Text := 'select table_name from sync_table_state';
    LQuery.Open;
    while not LQuery.Eof do
    begin
      LTable := LQuery.FieldByName('table_name').AsString;
      if TableExists(LTable) then
        ExecSQL('delete from "' + LTable + '"', []);
      LQuery.Next;
    end;
  finally
    LQuery.Free;
  end;
  ExecSQL('update sync_table_state set representative_code = null, last_sync_at = null, row_count = 0, last_error = null', []);
end;

function TdmApp.ShouldClearSyncData(out AReason: string): Boolean;
const
  CSyncResetVersion = '2026-04-29-1';
var
  LQuery: TFDQuery;
  LCurrentVersion: string;
  LForce: string;
  LErrCount: Int64;
begin
  Result := False;
  AReason := '';

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FDConnection;

    // forca manual: app_config.force_full_sync = 1
    LQuery.SQL.Text := 'select coalesce(value, '''') as v from app_config where key = :p0';
    LQuery.ParamByName('p0').AsString := 'force_full_sync';
    LQuery.Open;
    LForce := Trim(LQuery.FieldByName('v').AsString);
    LQuery.Close;
    if LForce = '1' then
    begin
      Result := True;
      AReason := 'force_full_sync';
      ExecSQL(
        'insert into app_config (key, value, updated_at) values (:p0, :p1, datetime(''now'')) ' +
        'on conflict(key) do update set value = excluded.value, updated_at = excluded.updated_at',
        ['force_full_sync', '0']
      );
      Exit;
    end;

    // mudanca de versao/regras da sincronizacao
    LQuery.SQL.Text := 'select coalesce(value, '''') as v from app_config where key = :p0';
    LQuery.ParamByName('p0').AsString := 'sync_reset_version';
    LQuery.Open;
    LCurrentVersion := Trim(LQuery.FieldByName('v').AsString);
    LQuery.Close;
    if not SameText(LCurrentVersion, CSyncResetVersion) then
    begin
      Result := True;
      AReason := 'sync_reset_version';
      ExecSQL(
        'insert into app_config (key, value, updated_at) values (:p0, :p1, datetime(''now'')) ' +
        'on conflict(key) do update set value = excluded.value, updated_at = excluded.updated_at',
        ['sync_reset_version', CSyncResetVersion]
      );
      Exit;
    end;

    // inconsistencias locais (erros estruturais)
    LErrCount := GetScalarInt64(
      'select count(*) from sync_table_state ' +
      'where coalesce(last_error, '''') <> '''' and (' +
      ' lower(last_error) like ''%no such column%'' or ' +
      ' lower(last_error) like ''%tabela % nao existe no sqlite%'' or ' +
      ' lower(last_error) like ''%table % has no column named%'' )',
      []
    );
    if LErrCount > 0 then
    begin
      Result := True;
      AReason := 'sync_struct_error';
      Exit;
    end;
  finally
    LQuery.Free;
  end;
end;

procedure TdmApp.DataModuleCreate(Sender: TObject);
begin
  FDConnection.DriverName := 'SQLite';
  FHttp := THTTPClient.Create;
  FLastVendas1NumDocs := TStringList.Create;
  FLastVendas1NumDocs.Sorted := True;
  FLastVendas1NumDocs.Duplicates := dupIgnore;
  FHttp.CustomHeaders['Accept-Encoding'] := 'gzip, deflate';
  FHttp.Accept := 'application/json';
  OpenConnection;
  EnsureDatabase;
  SeedConfig;
  LogRequest('DB', 'db_path', DatabaseFileName + ' | exe=' + ParamStr(0), '', 0);
  ApiBaseUrlOverride := GetApiBaseUrl;
end;

procedure TdmApp.DataModuleDestroy(Sender: TObject);
begin
  FLastVendas1NumDocs.Free;
  FHttp.Free;
end;

function TdmApp.DatabaseFileName: string;
begin
  {$IFDEF MSWINDOWS}
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), '..\db.sqllite');
  Result := TPath.GetFullPath(Result);
  {$ELSE}
  // Em Android 11+ (especialmente MIUI), pasta Documents compartilhada pode
  // bloquear criacao/escrita por scoped storage. Banco fica na pasta privada do app.
  Result := TPath.Combine(TPath.GetDocumentsPath, 'WorbyRep');
  if not TDirectory.Exists(Result) then
    TDirectory.CreateDirectory(Result);
  Result := TPath.Combine(Result, 'db.sqllite');
  {$ENDIF}
end;

procedure TdmApp.EnsureDatabase;
var
  LStatements: TStringList;
  I: Integer;
begin
  LStatements := TStringList.Create;
  try
    ExtractStrings([';'], [], PChar(CSchemaSQL), LStatements);
    for I := 0 to LStatements.Count - 1 do
      if Trim(LStatements[I]) <> '' then
        FDConnection.ExecSQL(Trim(LStatements[I]));
    try
      FDConnection.ExecSQL('alter table api_session add column senha TEXT');
    except
      // ignore if column already exists
    end;
  finally
    LStatements.Free;
  end;
end;

procedure TdmApp.GetTableColumns(const ATableName: string; AColumns, ATypes: TStrings; AIncludeBlobs: Boolean = False);
var
  LQuery: TFDQuery;
  LType: string;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FDConnection;
    LQuery.SQL.Text := 'PRAGMA table_info("' + ATableName + '")';
    LQuery.Open;
    while not LQuery.Eof do
    begin
      LType := UpperCase(Trim(LQuery.FieldByName('type').AsString));
      if (Pos('BLOB', LType) = 0) or AIncludeBlobs then
      begin
        AColumns.Add(LQuery.FieldByName('name').AsString);
        ATypes.Add(LQuery.FieldByName('type').AsString);
      end;
      LQuery.Next;
    end;
  finally
    LQuery.Free;
  end;
end;

procedure TdmApp.ExecSQL(const ASql: string; const AParams: array of Variant);
var
  LQuery: TFDQuery;
  I: Integer;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FDConnection;
    LQuery.SQL.Text := ASql;
    for I := 0 to LQuery.Params.Count - 1 do
    begin
      LQuery.Params[I].DataType := ftString;
      LQuery.Params[I].Clear;
    end;
    for I := 0 to High(AParams) do
      AssignParamFromVariant(LQuery.Params[I], AParams[I]);
    LQuery.ExecSQL;
  finally
    LQuery.Free;
  end;
end;

function TdmApp.TableExists(const ATableName: string): Boolean;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FDConnection;
    LQuery.SQL.Text := 'select 1 from sqlite_master where type = ''table'' and name = :p0';
    LQuery.ParamByName('p0').AsString := ATableName;
    LQuery.Open;
    Result := not LQuery.IsEmpty;
  finally
    LQuery.Free;
  end;
end;

function TdmApp.SqliteTypeToFieldType(const ASqliteType: string): TFieldType;
var
  LType: string;
begin
  LType := UpperCase(Trim(ASqliteType));
  if LType = '' then
    Exit(ftString);
  if (Pos('INT', LType) > 0) then
    Exit(ftLargeInt);
  if (Pos('REAL', LType) > 0) or (Pos('FLOA', LType) > 0) or (Pos('DOUB', LType) > 0) then
    Exit(ftFloat);
  if (Pos('BLOB', LType) > 0) then
    Exit(ftBlob);
  if (Pos('BOOL', LType) > 0) then
    Exit(ftBoolean);
  if (Pos('DATE', LType) > 0) or (Pos('TIME', LType) > 0) then
    Exit(ftDateTime);
  Result := ftString;
end;

function TdmApp.ExecuteJsonArrayRequest(const AEndpoint: string; ABody: TJSONObject): TJSONArray;
var
  LRequest: TStringStream;
  LResponse: IHTTPResponse;
  LText: string;
  LLogResponse: string;
  LValue: TJSONValue;
begin
  if (FSkipConnectionCheck <= 0) and (not ChecarConexao) then
    raise Exception.Create('Sem conexao com o servidor.');

  LRequest := TStringStream.Create(ABody.ToJSON, TEncoding.UTF8);
  try
    LResponse := FHttp.Post(BuildUrl(AEndpoint), LRequest);
    LText := LResponse.ContentAsString(TEncoding.UTF8);
    if SameText(AEndpoint, 'api/list') then
      LLogResponse := ''
    else
    begin
      LLogResponse := LText;
      if Length(LLogResponse) > 512 then
        LLogResponse := Copy(LLogResponse, 1, 512) + '... [len=' + Length(LText).ToString + ']';
    end;
    LogRequest('POST', AEndpoint, ABody.ToJSON, LLogResponse, LResponse.StatusCode);
    if (LResponse.StatusCode < 200) or (LResponse.StatusCode >= 300) then
      raise Exception.CreateFmt('HTTP %d: %s', [LResponse.StatusCode, LText]);
    LValue := TJSONObject.ParseJSONValue(LText);
    if not Assigned(LValue) then
      raise Exception.Create('Resposta JSON vazia para ' + AEndpoint);
    if not (LValue is TJSONArray) then
    begin
      LValue.Free;
      raise Exception.Create('Resposta JSON invalida para ' + AEndpoint);
    end;
    Result := TJSONArray(LValue);
  finally
    LRequest.Free;
  end;
end;
function TdmApp.ExecuteJsonObjectRequest(const AEndpoint: string; ABody: TJSONObject): TJSONObject;
var
  LRequest: TStringStream;
  LResponse: IHTTPResponse;
  LText: string;
  LLogResponse: string;
  LValue: TJSONValue;
begin
  if (FSkipConnectionCheck <= 0) and (not ChecarConexao) then
    raise Exception.Create('Sem conexao com o servidor.');

  LRequest := TStringStream.Create(ABody.ToJSON, TEncoding.UTF8);
  try
    LResponse := FHttp.Post(BuildUrl(AEndpoint), LRequest);
    LText := LResponse.ContentAsString(TEncoding.UTF8);
    LLogResponse := LText;
    if SameText(AEndpoint, 'api/sync_all') and (Length(LLogResponse) > 512) then
      LLogResponse := Copy(LLogResponse, 1, 512) + '... [len=' + Length(LText).ToString + ']';
    LogRequest('POST', AEndpoint, ABody.ToJSON, LLogResponse, LResponse.StatusCode);
    if (LResponse.StatusCode < 200) or (LResponse.StatusCode >= 300) then
      raise Exception.CreateFmt('HTTP %d: %s', [LResponse.StatusCode, LText]);
    LValue := TJSONObject.ParseJSONValue(LText);
    if not Assigned(LValue) then
      raise Exception.Create('Resposta JSON vazia para ' + AEndpoint);
    if not (LValue is TJSONObject) then
    begin
      LValue.Free;
      raise Exception.Create('Resposta JSON invalida para ' + AEndpoint);
    end;
    Result := TJSONObject(LValue);
  finally
    LRequest.Free;
  end;
end;

function TdmApp.GetApiBaseUrl: string;
var
  LQuery: TFDQuery;
  LValue: string;
begin
  Result := Trim(ApiBaseUrlOverride);
  if Result <> '' then
    Exit;

 // Result := 'http://plasfan.ddns.com.br:9000';
//  Result := 'http://localhost:9000';
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FDConnection;
    if not FDConnection.Connected then
      FDConnection.Connected := True;
    LQuery.SQL.Text := 'select value from app_config where key = :p0';
    LQuery.ParamByName('p0').AsString := 'api_base_url';
    LQuery.Open;
    if not LQuery.IsEmpty then
    begin
      LValue := Trim(LQuery.Fields[0].AsString);
      if SameText(LValue, 'PLASFAN') then
        Result := 'http://plasfan.ddns.com.br:9000'
      else if SameText(LValue, 'FILHO DO CRIADOR') or SameText(LValue, 'FILHO DO CRIADOR') then
        Result := 'http://plasfan.ddns.com.br:9004'
      else if LValue <> '' then
        Result := LValue;
    end;
  finally
    LQuery.Free;
  end;
end;

function TdmApp.GetScalarInt64(const ASql: string; const AParams: array of Variant): Int64;
var
  LQuery: TFDQuery;
  I: Integer;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FDConnection;
    LQuery.SQL.Text := ASql;
    for I := 0 to LQuery.Params.Count - 1 do
    begin
      LQuery.Params[I].DataType := ftString;
      LQuery.Params[I].Clear;
    end;
    for I := 0 to High(AParams) do
      AssignParamFromVariant(LQuery.Params[I], AParams[I]);
    LQuery.Open;
    Result := LQuery.Fields[0].AsLargeInt;
  finally
    LQuery.Free;
  end;
end;

function TdmApp.GetScalarAsString(const ASql: string; const AParams: array of Variant): string;
var
  LQuery: TFDQuery;
  I: Integer;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FDConnection;
    LQuery.SQL.Text := ASql;
    for I := 0 to LQuery.Params.Count - 1 do
    begin
      LQuery.Params[I].DataType := ftString;
      LQuery.Params[I].Clear;
    end;
    for I := 0 to High(AParams) do
      AssignParamFromVariant(LQuery.Params[I], AParams[I]);
    LQuery.Open;
    Result := LQuery.Fields[0].AsString;
  finally
    LQuery.Free;
  end;
end;

function TdmApp.GetSessionLogin: string;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FDConnection;
    LQuery.SQL.Text := 'select login from api_session where id = 1';
    LQuery.Open;
    Result := LQuery.Fields[0].AsString;
  finally
    LQuery.Free;
  end;
end;

function TdmApp.IsDailySyncRequired(out AMessage: string): Boolean;
const
  CRequiredTables: array[0..12] of string = (
    'representante',
    'cliente',
    'produto',
    'subcategoria',
    'vendas1',
    'vendas2',
    'fop',
    'prazo',
    'cidades',
    'produto_representante',
    'grupo_representante',
    'produto_representante_inativos',
    'prazo_representante'
  );
var
  LQuery: TFDQuery;
  I: Integer;
  LHour: Word;
  LMin: Word;
  LSec: Word;
  LMSec: Word;
begin
  Result := False;
  AMessage := '';

  DecodeTime(Now, LHour, LMin, LSec, LMSec);
  if LHour < 6 then
    Exit;

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FDConnection;
    LQuery.SQL.Text :=
      'select count(*) qtd ' +
      'from sync_table_state ' +
      'where table_name = :p0 ' +
      '  and coalesce(last_error, '''') = '''' ' +
      '  and date(last_sync_at, ''localtime'') = date(''now'', ''localtime'')';

    for I := Low(CRequiredTables) to High(CRequiredTables) do
    begin
      LQuery.Close;
      LQuery.ParamByName('p0').AsString := CRequiredTables[I];
      LQuery.Open;
      if LQuery.FieldByName('qtd').AsInteger = 0 then
        Result := True;
    end;
  finally
    LQuery.Free;
  end;

  if Result then
    AMessage := 'Sincronização diária obrigatória antes de mexer nos pedidos.';
end;

function TdmApp.ListCachedTables: TJSONArray;
var
  LQuery: TFDQuery;
  LItem: TJSONObject;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FDConnection;
    LQuery.SQL.Text :=
      'select table_name, representative_code, last_sync_at, row_count ' +
      'from sync_table_state order by table_name';
    LQuery.Open;
    Result := TJSONArray.Create;
    while not LQuery.Eof do
    begin
      LItem := TJSONObject.Create;
      LItem.AddPair('table_name', LQuery.FieldByName('table_name').AsString);
      LItem.AddPair('representative_code', LQuery.FieldByName('representative_code').AsString);
      LItem.AddPair('last_sync_at', LQuery.FieldByName('last_sync_at').AsString);
      LItem.AddPair('row_count', TJSONNumber.Create(LQuery.FieldByName('row_count').AsInteger));
      Result.AddElement(LItem);
      LQuery.Next;
    end;
  finally
    LQuery.Free;
  end;
end;

procedure TdmApp.SetSyncTableError(const ATableName, ACodRepresentante, AError: string);
begin
  ExecSQL(
    'insert into sync_table_state (table_name, representative_code, last_sync_at, row_count, last_error) values (:p0, :p1, datetime(''now''), :p2, :p3) ' +
    'on conflict(table_name) do update set representative_code = excluded.representative_code, last_sync_at = excluded.last_sync_at, row_count = excluded.row_count, last_error = excluded.last_error',
    [ATableName, ACodRepresentante, 0, AError]
  );
end;

procedure TdmApp.LogRequest(const AMethod, AEndpoint, ARequest, AResponse: string; AStatusCode: Integer);
begin
  if not RequestLogAvailable then
    Exit;
  ExecSQL(
    'insert into request_log (endpoint, method, request_json, response_json, status_code) values (:p0, :p1, :p2, :p3, :p4)',
    [AEndpoint, AMethod, ARequest, AResponse, AStatusCode]
  );
end;

function TdmApp.RequestLogAvailable: Boolean;
var
  LQuery: TFDQuery;
  LCols: TStringList;
  LName: string;
begin
  if FRequestLogOk = 1 then
    Exit(True);
  if FRequestLogOk = 0 then
    Exit(False);

  Result := False;
  LCols := TStringList.Create;
  try
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := FDConnection;
      LQuery.SQL.Text := 'PRAGMA table_info("request_log")';
      LQuery.Open;
      while not LQuery.Eof do
      begin
        LName := LQuery.FieldByName('name').AsString;
        LCols.Add(LowerCase(LName));
        LQuery.Next;
      end;
    finally
      LQuery.Free;
    end;

    Result := LCols.IndexOf('endpoint') >= 0;
    Result := Result and (LCols.IndexOf('method') >= 0);
    Result := Result and (LCols.IndexOf('request_json') >= 0);
    Result := Result and (LCols.IndexOf('response_json') >= 0);
    Result := Result and (LCols.IndexOf('status_code') >= 0);
  finally
    LCols.Free;
  end;

  if Result then
    FRequestLogOk := 1
  else
    FRequestLogOk := 0;
end;

procedure TdmApp.AddRequestLog(const AMethod, AEndpoint, ARequest, AResponse: string; AStatusCode: Integer);
begin
  try
    LogRequest(AMethod, AEndpoint, ARequest, AResponse, AStatusCode);
  except
    // ignore logging failures
  end;
end;

function TdmApp.Login(const ALogin, ASenha: string): TJSONObject;
var
  LBody: TJSONObject;
  LOldUserJson: string;
  LOldLogin: string;
  LLoginChanged: Boolean;
  LRepChanged: Boolean;
  LOldJson: TJSONValue;
  LOldObj: TJSONObject;
  LOldUserObj: TJSONObject;
  LOldUserVal: TJSONValue;
  LOldRepVal: TJSONValue;
  LNewUserObj: TJSONObject;
  LNewUserVal: TJSONValue;
  LNewRepVal: TJSONValue;
  LOldRep: Integer;
  LNewRep: Integer;
  function ExtractRepId(AObj: TJSONObject): Integer;
  var
    V: TJSONValue;
  begin
    Result := 0;
    if not Assigned(AObj) then
      Exit;
    V := AObj.GetValue('cod_representante');
    if not Assigned(V) then
      V := AObj.GetValue('id_representante');
    if Assigned(V) then
      Result := StrToIntDef(Trim(V.Value), 0);
  end;
begin
  LOldRep := 0;
  LNewRep := 0;
  LOldLogin := '';

  // usuario/representante anterior gravado na sessao local
  try
    LOldLogin := Trim(FDConnection.ExecSQLScalar('select coalesce(login, '''') from api_session where id = 1'));
  except
    LOldLogin := '';
  end;
  LOldUserJson := Trim(FDConnection.ExecSQLScalar('select coalesce(user_json, '''') from api_session where id = 1'));
  if LOldUserJson <> '' then
  begin
    LOldJson := TJSONObject.ParseJSONValue(LOldUserJson);
    try
      if LOldJson is TJSONObject then
      begin
        LOldObj := TJSONObject(LOldJson);
        LOldUserVal := LOldObj.GetValue('user');
        if LOldUserVal is TJSONObject then
        begin
          LOldUserObj := TJSONObject(LOldUserVal);
          LOldRep := ExtractRepId(LOldUserObj);
        end
        else
        begin
          LOldRepVal := LOldObj.GetValue('cod_representante');
          if Assigned(LOldRepVal) then
            LOldRep := StrToIntDef(Trim(LOldRepVal.Value), 0);
        end;
      end;
    finally
      LOldJson.Free;
    end;
  end;

  LLoginChanged := (LOldLogin <> '') and (not SameText(LOldLogin, ALogin));
  if LLoginChanged and (CountPendingPedidos > 0) then
    raise Exception.Create('Existem pedidos pendentes de envio. Sincronize antes de trocar o usu?rio.');

  LBody := TJSONObject.Create;
  try
    LBody.AddPair('login', ALogin);
    LBody.AddPair('senha', ASenha);
    Result := ExecuteJsonObjectRequest('login', LBody);
  finally
    LBody.Free;
  end;

  // representante retornado no login atual
  LNewUserVal := Result.GetValue('user');
  if LNewUserVal is TJSONObject then
  begin
    LNewUserObj := TJSONObject(LNewUserVal);
    LNewRep := ExtractRepId(LNewUserObj);
  end
  else
  begin
    LNewRepVal := Result.GetValue('cod_representante');
    if Assigned(LNewRepVal) then
      LNewRep := StrToIntDef(Trim(LNewRepVal.Value), 0);
  end;

  LLoginChanged := (LOldLogin <> '') and (not SameText(LOldLogin, ALogin));
  LRepChanged := (LOldRep > 0) and (LNewRep > 0) and (LOldRep <> LNewRep);

  if (LLoginChanged or LRepChanged) and (CountPendingPedidos > 0) then
  begin
    Result.Free;
    raise Exception.Create('Existem pedidos pendentes de envio. Sincronize antes de trocar o usu?rio.');
  end;

  // trocou representante -> limpa dados locais sincronizados e pedidos locais
  if LRepChanged then
  begin
    ClearSyncData;
    ExecSQL('delete from outbound_pedido_item', []);
    ExecSQL('delete from outbound_pedido', []);
  end;

  ExecSQL(
    'update api_session set base_url = :p0, login = :p1, senha = :p2, user_json = :p3, last_login_at = datetime(''now''), last_error = null where id = 1',
    [ApiBaseUrl, ALogin, ASenha, Result.ToJSON]
  );
end;

procedure TdmApp.OpenConnection;
var
  LDbPath: string;
  LDir: string;
  {$IFDEF ANDROID}
  LOldDbPath: string;
  {$ENDIF}
begin
  FDConnection.Connected := False;
  FDConnection.Params.Clear;
  FDConnection.Params.Add('DriverID=SQLite');
  LDbPath := DatabaseFileName;
  LDir := ExtractFilePath(LDbPath);
  if (LDir <> '') and (not TDirectory.Exists(LDir)) then
    TDirectory.CreateDirectory(LDir);

  {$IFDEF ANDROID}
  if not TFile.Exists(LDbPath) then
  begin
    try
      LOldDbPath := TPath.Combine(TPath.Combine(TPath.GetSharedDocumentsPath, 'WorbyRep'), 'db.sqllite');
      if TFile.Exists(LOldDbPath) then
        TFile.Copy(LOldDbPath, LDbPath, False);
    except
      // Se o MIUI bloquear a pasta compartilhada, cria um banco novo na pasta privada.
    end;
  end;
  {$ENDIF}

  if not TFile.Exists(LDbPath) then
    TFile.WriteAllText(LDbPath, '');
  FDConnection.Params.Add('Database=' + LDbPath);
  FDConnection.LoginPrompt := False;
  FDConnection.Connected := True;
end;

function TdmApp.NormalizeVendas1Json(const AVendas1Json: string): string;
var
  LJson: TJSONValue;
  LObj: TJSONObject;
  LPair: TJSONPair;
  LVal: TJSONValue;
begin
  Result := AVendas1Json;
  if Trim(AVendas1Json) = '' then
    Exit;

  LJson := TJSONObject.ParseJSONValue(AVendas1Json);
  try
    if not (LJson is TJSONObject) then
      Exit;

    LObj := TJSONObject(LJson);
  LPair := LObj.RemovePair('pedido_vendedor');
  if Assigned(LPair) then
    LPair.Free;
  LObj.AddPair('pedido_vendedor', '1');

  // Campo obrigatório no PostgreSQL
  LVal := LObj.GetValue('cod_empresa');
  if (not Assigned(LVal)) or (LVal is TJSONNull) or (Trim(LVal.Value) = '') then
  begin
    LPair := LObj.RemovePair('cod_empresa');
    if Assigned(LPair) then
      LPair.Free;
    LObj.AddPair('cod_empresa', TJSONNumber.Create(0));
  end;

  Result := LObj.ToJSON;
finally
  LJson.Free;
end;
end;

function TdmApp.IsVendas2Field(const AName: string): Boolean;
const
  CFields: array[0..48] of string = (
    'id', 'numdoc', 'dtadoc', 'cod_produto', 'cod_cliente', 'cod_representante',
    'id_cor', 'id_tamanho', 'qtd', 'qtd_devolvida', 'devolvido', 'desconto',
    'volume', 'cod_empresa', 'nr_pedido_palm', 'preco_bruto', 'sub_total_bruto',
    'vlr_comissao', 'troca', 'cod_fiscal_item', 'icms_item', 'vlr_icms_st_ant',
    'vlr_bc_st_ant', 'vlr_icms_item_ant', 'ncm', 'vlr_bc_ant', 'ipi_item',
    'vlr_ipi_item', 'vlr_agr_item', 'trib_icms', 'cesta_basica', 'cod_supervisor',
    'qtd_embalagem', 'preco_custo', 'perc_comissao', 'promocao', 'desconto_max',
    'checado', 'preco_base', 'desconto_valor', 'nao_validar_margem',
    'desconto_valor_geral', 'cest', 'preco', 'sub_total', 'vlr_bc',
    'vlr_bc_st', 'vlr_icms_item', 'vlr_icms_st'
  );
var
  I: Integer;
begin
  Result := False;
  for I := Low(CFields) to High(CFields) do
    if SameText(AName, CFields[I]) then
      Exit(True);
end;

function TdmApp.NormalizeVendas2ItemJson(AItemObj: TJSONObject; const ACodCliente, ACodRepresentante: Integer): TJSONObject;
var
  I: Integer;
  LNamesToRemove: TStringList;
  LName: string;
  LPair: TJSONPair;
  LPreco: Double;
  LPrecoBruto: Double;
  LQtd: Double;
  LVal: TJSONValue;
  LFS: TFormatSettings;
begin
  if not Assigned(AItemObj) then
    Exit(nil);

  Result := TJSONObject.ParseJSONValue(AItemObj.ToJSON) as TJSONObject;
  if not Assigned(Result) then
    Exit(nil);

  LNamesToRemove := TStringList.Create;
  try
    for I := 0 to Result.Count - 1 do
      if not IsVendas2Field(Result.Pairs[I].JsonString.Value) then
        LNamesToRemove.Add(Result.Pairs[I].JsonString.Value);

    for I := 0 to LNamesToRemove.Count - 1 do
    begin
      LName := LNamesToRemove[I];
      LPair := Result.RemovePair(LName);
      if Assigned(LPair) then
        LPair.Free;
    end;
  finally
    LNamesToRemove.Free;
  end;

  if not Assigned(Result.GetValue('cod_empresa')) then
    Result.AddPair('cod_empresa', TJSONNumber.Create(0));

  if (ACodCliente > 0) and not Assigned(Result.GetValue('cod_cliente')) then
    Result.AddPair('cod_cliente', TJSONNumber.Create(ACodCliente));
  if (ACodRepresentante > 0) and not Assigned(Result.GetValue('cod_representante')) then
    Result.AddPair('cod_representante', TJSONNumber.Create(ACodRepresentante));

  if (not Assigned(Result.GetValue('desconto'))) and Assigned(AItemObj.GetValue('desconto_pct')) then
    Result.AddPair('desconto', AItemObj.GetValue('desconto_pct').Clone as TJSONValue);

  if (not Assigned(Result.GetValue('volume'))) and Assigned(Result.GetValue('qtd')) then
    Result.AddPair('volume', Result.GetValue('qtd').Clone as TJSONValue);

  LPreco := 0;
  LPrecoBruto := 0;
  LQtd := 0;
  LFS := TFormatSettings.Create;
  LFS.DecimalSeparator := '.';
  LVal := Result.GetValue('preco');
  if Assigned(LVal) then
    LPreco := StrToFloatDef(StringReplace(LVal.Value, ',', '.', [rfReplaceAll]), 0, LFS);
  LVal := Result.GetValue('preco_bruto');
  if Assigned(LVal) then
    LPrecoBruto := StrToFloatDef(StringReplace(LVal.Value, ',', '.', [rfReplaceAll]), 0, LFS);
  if LPrecoBruto = 0 then
    LPrecoBruto := LPreco;
  LVal := Result.GetValue('qtd');
  if Assigned(LVal) then
    LQtd := StrToFloatDef(StringReplace(LVal.Value, ',', '.', [rfReplaceAll]), 0, LFS);
  if (not Assigned(Result.GetValue('preco_bruto'))) and (LPrecoBruto <> 0) then
    Result.AddPair('preco_bruto', TJSONNumber.Create(LPrecoBruto));
  if (not Assigned(Result.GetValue('sub_total'))) and (LPreco <> 0) and (LQtd <> 0) then
    Result.AddPair('sub_total', TJSONNumber.Create(LPreco * LQtd));
  if (not Assigned(Result.GetValue('sub_total_bruto'))) and (LPrecoBruto <> 0) and (LQtd <> 0) then
    Result.AddPair('sub_total_bruto', TJSONNumber.Create(LPrecoBruto * LQtd));
end;

function TdmApp.QueuePedido(const AVendas1, AVendas2: string): Integer;
var
  LItems: TJSONValue;
  LArray: TJSONArray;
  I: Integer;
  LUUID: string;
  LGuid: TGUID;
  LVendas1Json: string;
begin
  CreateGUID(LGuid);
  LUUID := GUIDToString(LGuid);
  LVendas1Json := NormalizeVendas1Json(AVendas1);
  ExecSQL(
    'insert into outbound_pedido (local_uuid, representative_code, vendas1_json) values (:p0, :p1, :p2)',
    [LUUID, '', LVendas1Json]
  );

  Result := GetScalarInt64('select id from outbound_pedido where local_uuid = :p0', [LUUID]);

  LItems := TJSONObject.ParseJSONValue(AVendas2);
  try
    if not (LItems is TJSONArray) then
      raise Exception.Create('vendas2 deve ser um array JSON');
    LArray := TJSONArray(LItems);
    for I := 0 to LArray.Count - 1 do
      ExecSQL(
        'insert into outbound_pedido_item (pedido_id, item_ord, vendas2_json) values (:p0, :p1, :p2)',
        [Result, I + 1, LArray.Items[I].ToJSON]
      );
  finally
    LItems.Free;
  end;
end;

function TdmApp.CreateOutboundPedidoDraft(const AVendas1Json, ARepresentativeCode: string): Integer;
var
  LUUID: string;
  LGuid: TGUID;
  LJsonNormalized: string;
begin
  CreateGUID(LGuid);
  LUUID := GUIDToString(LGuid);
  LJsonNormalized := NormalizeVendas1Json(AVendas1Json);
  ExecSQL(
    'insert into outbound_pedido (local_uuid, representative_code, vendas1_json) values (:p0, :p1, :p2)',
    [LUUID, ARepresentativeCode, LJsonNormalized]
  );
  Result := GetScalarInt64('select id from outbound_pedido where local_uuid = :p0', [LUUID]);
end;

procedure TdmApp.UpdateOutboundPedidoDraft(const APedidoId: Integer; const AVendas1Json, ARepresentativeCode: string);
begin
  if APedidoId <= 0 then
    Exit;
  ExecSQL(
    'update outbound_pedido set vendas1_json = :p0, representative_code = :p1 where id = :p2',
    [NormalizeVendas1Json(AVendas1Json), ARepresentativeCode, APedidoId]
  );
end;

function TdmApp.AddOutboundPedidoItem(const APedidoId: Integer; const AVendas2Json: string): Integer;
begin
  if APedidoId <= 0 then
    raise Exception.Create('Pedido outbound inválido.');

  Result := GetScalarInt64(
    'select coalesce(max(item_ord), 0) + 1 from outbound_pedido_item where pedido_id = :p0',
    [APedidoId]
  );

  ExecSQL(
    'insert into outbound_pedido_item (pedido_id, item_ord, vendas2_json) values (:p0, :p1, :p2)',
    [APedidoId, Result, AVendas2Json]
  );
end;

function TdmApp.CountOutboundPedidoItens(const APedidoId: Integer): Integer;
begin
  if APedidoId <= 0 then
    Exit(0);
  Result := GetScalarInt64(
    'select count(*) from outbound_pedido_item where pedido_id = :p0',
    [APedidoId]
  );
end;

function TdmApp.SendPendingPedidos: Integer;
var
  LPedidos: TFDQuery;
  LItens: TFDQuery;
  LBody: TJSONObject;
  LPedidosArray: TJSONArray;
  LPedidoObj: TJSONObject;
  LVendas1Obj: TJSONObject;
  LVendas2Array: TJSONArray;
  LResponse: TJSONObject;
  LResultados: TJSONArray;
  LResultItem: TJSONValue;
  LPedidoId: Integer;
  LNumDoc: string;
  LErro: string;
  LFoundIds: TStringList;
  I: Integer;
  LVal: TJSONValue;
  LCodCliente: Integer;
  LCodRep: Integer;
  LItemJson: TJSONValue;
  LItemObj: TJSONObject;
  LTotBruto: Double;
  LTotLiquido: Double;
  LItemSub: Double;
  LItemSubBruto: Double;
  LItemPreco: Double;
  LItemPrecoBruto: Double;
  LItemQtd: Double;
  LRepCodeStr: string;
  LFS: TFormatSettings;
  LDefaultRepCode: Integer;
  LSession: TFDQuery;
  LUserJson: TJSONValue;
  LUserObj: TJSONObject;
  LUserInner: TJSONObject;
  LRepVal: TJSONValue;
  LOrcamento: Integer;
begin
  Result := 0;
  LFS := TFormatSettings.Create;
  LFS.DecimalSeparator := '.';
  LPedidos := TFDQuery.Create(nil);
  LItens := TFDQuery.Create(nil);
  LFoundIds := TStringList.Create;
  try
    LPedidos.Connection := FDConnection;
    LItens.Connection := FDConnection;
    LPedidos.SQL.Text :=
      'select id, representative_code, vendas1_json from outbound_pedido ' +
      'where status in (''PENDENTE'', ''ERRO'') order by id';
    LPedidos.Open;

    if LPedidos.IsEmpty then
      Exit(0);

    LBody := TJSONObject.Create;
    try
      LPedidosArray := TJSONArray.Create;
      LBody.AddPair('pedidos', LPedidosArray);
      LDefaultRepCode := 0;

      LSession := TFDQuery.Create(nil);
      try
        LSession.Connection := FDConnection;

        // 1) tentativa pelo estado de sincronizacao
        LSession.SQL.Text :=
          'select representative_code from sync_table_state ' +
          'where table_name = ''representante'' and trim(coalesce(representative_code, '''')) <> '''' ' +
          'limit 1';
        LSession.Open;
        if not LSession.IsEmpty then
          LDefaultRepCode := StrToIntDef(Trim(LSession.Fields[0].AsString), 0);
        LSession.Close;

        // 2) fallback pelo user_json da sessao atual
        if LDefaultRepCode <= 0 then
        begin
          LSession.SQL.Text := 'select user_json from api_session where id = 1';
          LSession.Open;
          if (not LSession.IsEmpty) and (Trim(LSession.Fields[0].AsString) <> '') then
          begin
            LUserJson := TJSONObject.ParseJSONValue(LSession.Fields[0].AsString);
            try
              if LUserJson is TJSONObject then
              begin
                LUserObj := TJSONObject(LUserJson);
                LUserInner := nil;
                if LUserObj.GetValue('user') is TJSONObject then
                  LUserInner := LUserObj.GetValue('user') as TJSONObject
                else
                  LUserInner := LUserObj;

                if Assigned(LUserInner) then
                begin
                  LRepVal := LUserInner.GetValue('cod_representante');
                  if Assigned(LRepVal) then
                    LDefaultRepCode := StrToIntDef(Trim(LRepVal.Value), 0);
                  if LDefaultRepCode <= 0 then
                  begin
                    LRepVal := LUserInner.GetValue('id_representante');
                    if Assigned(LRepVal) then
                      LDefaultRepCode := StrToIntDef(Trim(LRepVal.Value), 0);
                  end;
                  if LDefaultRepCode <= 0 then
                  begin
                    LRepVal := LUserInner.GetValue('id');
                    if Assigned(LRepVal) then
                      LDefaultRepCode := StrToIntDef(Trim(LRepVal.Value), 0);
                  end;
                  if LDefaultRepCode <= 0 then
                  begin
                    LRepVal := LUserInner.GetValue('cod_tablet');
                    if Assigned(LRepVal) then
                      LDefaultRepCode := StrToIntDef(Trim(LRepVal.Value), 0);
                  end;
                end;
              end;
            finally
              LUserJson.Free;
            end;
          end;
          LSession.Close;
        end;

        // 3) fallback final pela tabela representante local
        if LDefaultRepCode <= 0 then
        begin
          LSession.SQL.Text := 'select id from representante where id is not null order by id limit 1';
          LSession.Open;
          if not LSession.IsEmpty then
            LDefaultRepCode := LSession.Fields[0].AsInteger;
          LSession.Close;
        end;
      finally
        LSession.Free;
      end;

      if LDefaultRepCode > 0 then
        LBody.AddPair('codRepresentante', IntToStr(LDefaultRepCode));

      while not LPedidos.Eof do
      begin
        try
          LPedidoObj := TJSONObject.Create;
          LPedidoObj.AddPair('pedido_id', TJSONNumber.Create(LPedidos.FieldByName('id').AsInteger));

          LVendas1Obj := TJSONObject.ParseJSONValue(LPedidos.FieldByName('vendas1_json').AsString) as TJSONObject;
          if not Assigned(LVendas1Obj) then
            raise Exception.Create('vendas1_json invalido');

          LOrcamento := LVendas1Obj.GetValue<Integer>('orcamento', 0);
          if LOrcamento = 1 then
          begin
            LVendas1Obj.Free;
            LPedidoObj.Free;
            LPedidos.Next;
            Continue;
          end;

          // Mapeia campos locais para nomes reais da tabela vendas1
          LVal := LVendas1Obj.GetValue('id_fop');
          if Assigned(LVal) and (not Assigned(LVendas1Obj.GetValue('cod_fop'))) then
            LVendas1Obj.AddPair('cod_fop', LVal.Clone as TJSONValue);
          LVal := LVendas1Obj.GetValue('codfop');
          if Assigned(LVal) and (not Assigned(LVendas1Obj.GetValue('cod_fop'))) then
            LVendas1Obj.AddPair('cod_fop', LVal.Clone as TJSONValue);

          LVal := LVendas1Obj.GetValue('id_prazo');
          if Assigned(LVal) and (not Assigned(LVendas1Obj.GetValue('cod_prazo_pgto'))) then
            LVendas1Obj.AddPair('cod_prazo_pgto', LVal.Clone as TJSONValue);
          LVal := LVendas1Obj.GetValue('codprazo');
          if Assigned(LVal) and (not Assigned(LVendas1Obj.GetValue('cod_prazo_pgto'))) then
            LVendas1Obj.AddPair('cod_prazo_pgto', LVal.Clone as TJSONValue);

          LVal := LVendas1Obj.GetValue('dta_pedido');
          if Assigned(LVal) and (not Assigned(LVendas1Obj.GetValue('dtadoc'))) then
            LVendas1Obj.AddPair('dtadoc', LVal.Clone as TJSONValue);

          LVal := LVendas1Obj.GetValue('hora_pedido');
          if Assigned(LVal) and (not Assigned(LVendas1Obj.GetValue('hora'))) then
            LVendas1Obj.AddPair('hora', LVal.Clone as TJSONValue);

          LVal := LVendas1Obj.GetValue('observacoes');
          if Assigned(LVal) and (not Assigned(LVendas1Obj.GetValue('observacoes_pedido'))) then
            LVendas1Obj.AddPair('observacoes_pedido', LVal.Clone as TJSONValue);

          // campo obrigatorio no servidor
          LVal := LVendas1Obj.GetValue('cod_empresa');
          if (not Assigned(LVal)) or (LVal is TJSONNull) or (Trim(LVal.Value) = '') then
          begin
            if Assigned(LVendas1Obj.GetValue('cod_empresa')) then
              LVendas1Obj.RemovePair('cod_empresa').Free;
            LVendas1Obj.AddPair('cod_empresa', TJSONNumber.Create(0));
          end;

          // defaults de campos obrigatorios/esperados
          LVal := LVendas1Obj.GetValue('cod_fop');
          if (not Assigned(LVal)) or (LVal is TJSONNull) or (Trim(LVal.Value) = '') then
          begin
            if Assigned(LVendas1Obj.GetValue('cod_fop')) then
              LVendas1Obj.RemovePair('cod_fop').Free;
            LVendas1Obj.AddPair('cod_fop', TJSONNumber.Create(0));
          end;

          LVal := LVendas1Obj.GetValue('cod_prazo_pgto');
          if (not Assigned(LVal)) or (LVal is TJSONNull) or (Trim(LVal.Value) = '') then
          begin
            if Assigned(LVendas1Obj.GetValue('cod_prazo_pgto')) then
              LVendas1Obj.RemovePair('cod_prazo_pgto').Free;
            LVendas1Obj.AddPair('cod_prazo_pgto', TJSONNumber.Create(0));
          end;

          // Remove campos locais/descricoes que nao pertencem a vendas1
          if Assigned(LVendas1Obj.GetValue('nom_cliente')) then
            LVendas1Obj.RemovePair('nom_cliente').Free;
          if Assigned(LVendas1Obj.GetValue('cidade')) then
            LVendas1Obj.RemovePair('cidade').Free;
          if Assigned(LVendas1Obj.GetValue('origem')) then
            LVendas1Obj.RemovePair('origem').Free;
          if Assigned(LVendas1Obj.GetValue('id_fop')) then
            LVendas1Obj.RemovePair('id_fop').Free;
          if Assigned(LVendas1Obj.GetValue('codfop')) then
            LVendas1Obj.RemovePair('codfop').Free;
          if Assigned(LVendas1Obj.GetValue('id_prazo')) then
            LVendas1Obj.RemovePair('id_prazo').Free;
          if Assigned(LVendas1Obj.GetValue('codprazo')) then
            LVendas1Obj.RemovePair('codprazo').Free;
          if Assigned(LVendas1Obj.GetValue('dta_pedido')) then
            LVendas1Obj.RemovePair('dta_pedido').Free;
          if Assigned(LVendas1Obj.GetValue('hora_pedido')) then
            LVendas1Obj.RemovePair('hora_pedido').Free;
          if Assigned(LVendas1Obj.GetValue('observacoes')) then
            LVendas1Obj.RemovePair('observacoes').Free;

          if Assigned(LVendas1Obj.GetValue('pedido_vendedor')) then
            LVendas1Obj.RemovePair('pedido_vendedor').Free;
          LVendas1Obj.AddPair('pedido_vendedor', '1');

          LCodCliente := LVendas1Obj.GetValue<Integer>('cod_cliente', 0);
          LCodRep := LVendas1Obj.GetValue<Integer>('cod_representante', 0);
          if LCodRep <= 0 then
            LCodRep := LVendas1Obj.GetValue<Integer>('id_representante', 0);
          if LCodRep <= 0 then
          begin
            LRepCodeStr := Trim(LPedidos.FieldByName('representative_code').AsString);
            LCodRep := StrToIntDef(LRepCodeStr, 0);
          end;
          if LCodRep <= 0 then
            LCodRep := LDefaultRepCode;

          LVendas2Array := TJSONArray.Create;
          LItens.Close;
          LItens.SQL.Text := 'select vendas2_json from outbound_pedido_item where pedido_id = :p0 order by item_ord';
          LItens.ParamByName('p0').AsInteger := LPedidos.FieldByName('id').AsInteger;
          LItens.Open;
          LTotBruto := 0;
          LTotLiquido := 0;
          while not LItens.Eof do
          begin
            LItemJson := TJSONObject.ParseJSONValue(LItens.FieldByName('vendas2_json').AsString);
            if not (LItemJson is TJSONObject) then
            begin
              LItemJson.Free;
              raise Exception.Create('vendas2_json invalido');
            end;
            LItemObj := NormalizeVendas2ItemJson(TJSONObject(LItemJson), LCodCliente, LCodRep);
            LItemJson.Free;
            if not Assigned(LItemObj) then
              raise Exception.Create('Falha ao normalizar item vendas2');
            LVendas2Array.AddElement(LItemObj);

            LItemSub := 0;
            LItemSubBruto := 0;
            LItemPreco := 0;
            LItemPrecoBruto := 0;
            LItemQtd := 0;

            LVal := LItemObj.GetValue('qtd');
            if Assigned(LVal) then
              LItemQtd := StrToFloatDef(StringReplace(LVal.Value, ',', '.', [rfReplaceAll]), 0, LFS);

            LVal := LItemObj.GetValue('sub_total');
            if Assigned(LVal) then
              LItemSub := StrToFloatDef(StringReplace(LVal.Value, ',', '.', [rfReplaceAll]), 0, LFS);
            if LItemSub = 0 then
            begin
              LVal := LItemObj.GetValue('preco');
              if Assigned(LVal) then
                LItemPreco := StrToFloatDef(StringReplace(LVal.Value, ',', '.', [rfReplaceAll]), 0, LFS);
              LItemSub := LItemPreco * LItemQtd;
            end;

            LVal := LItemObj.GetValue('sub_total_bruto');
            if Assigned(LVal) then
              LItemSubBruto := StrToFloatDef(StringReplace(LVal.Value, ',', '.', [rfReplaceAll]), 0, LFS);
            if LItemSubBruto = 0 then
            begin
              LVal := LItemObj.GetValue('preco_bruto');
              if Assigned(LVal) then
                LItemPrecoBruto := StrToFloatDef(StringReplace(LVal.Value, ',', '.', [rfReplaceAll]), 0, LFS);
              if LItemPrecoBruto = 0 then
                LItemPrecoBruto := LItemPreco;
              LItemSubBruto := LItemPrecoBruto * LItemQtd;
            end;

            LTotBruto := LTotBruto + LItemSubBruto;
            LTotLiquido := LTotLiquido + LItemSub;
            LItens.Next;
          end;

          if (LCodRep > 0) then
          begin
            if Assigned(LVendas1Obj.GetValue('cod_representante')) then
              LVendas1Obj.RemovePair('cod_representante').Free;
            LVendas1Obj.AddPair('cod_representante', TJSONNumber.Create(LCodRep));
          end;

          if Assigned(LVendas1Obj.GetValue('tot_bruto')) then
            LVendas1Obj.RemovePair('tot_bruto').Free;
          LVendas1Obj.AddPair('tot_bruto', TJSONNumber.Create(LTotBruto));

          if Assigned(LVendas1Obj.GetValue('tot_liquido')) then
            LVendas1Obj.RemovePair('tot_liquido').Free;
          LVendas1Obj.AddPair('tot_liquido', TJSONNumber.Create(LTotLiquido));

          if Assigned(LVendas1Obj.GetValue('tot_liquido_ant')) then
            LVendas1Obj.RemovePair('tot_liquido_ant').Free;
          LVendas1Obj.AddPair('tot_liquido_ant', TJSONNumber.Create(LTotLiquido));

          if LTotLiquido <= 0 then
          begin
            ExecSQL(
              'update outbound_pedido set status = :p0, last_error = :p1 where id = :p2',
              ['ERRO', 'Pedido com valor total zerado nao pode ser enviado', LPedidos.FieldByName('id').AsInteger]
            );
            LVendas2Array.Free;
            LVendas1Obj.Free;
            LPedidoObj.Free;
            LPedidos.Next;
            Continue;
          end;

          LPedidoObj.AddPair('vendas1', LVendas1Obj);
          LPedidoObj.AddPair('vendas2', LVendas2Array);
          LPedidosArray.AddElement(LPedidoObj);
        except
          on E: Exception do
            ExecSQL(
              'update outbound_pedido set status = :p0, last_error = :p1 where id = :p2',
              ['ERRO', E.Message, LPedidos.FieldByName('id').AsInteger]
            );
        end;
        LPedidos.Next;
      end;

      if LPedidosArray.Count = 0 then
        Exit(0);

      LResponse := ExecuteJsonObjectRequest('api/pedidos_digitados', LBody);
      try
        LResultados := LResponse.GetValue('resultados') as TJSONArray;
        if not Assigned(LResultados) then
          raise Exception.Create('Resposta do servidor sem array resultados');

        for I := 0 to LResultados.Count - 1 do
        begin
          LResultItem := LResultados.Items[I];
          if not (LResultItem is TJSONObject) then
            Continue;

          LPedidoId := StrToIntDef(TJSONObject(LResultItem).GetValue<string>('pedido_id', ''), 0);
          if LPedidoId <= 0 then
            LPedidoId := TJSONObject(LResultItem).GetValue<Integer>('pedido_id', 0);
          if LPedidoId <= 0 then
            Continue;

          LFoundIds.Add(IntToStr(LPedidoId));

          if SameText(TJSONObject(LResultItem).GetValue<string>('success', 'false'), 'true') then
          begin
            LNumDoc := TJSONObject(LResultItem).GetValue<string>('numdoc', '');
            ExecSQL(
              'update outbound_pedido set status = :p0, numdoc_remote = :p1, sent_at = datetime(''now''), last_error = null where id = :p2',
              ['ENVIADO', LNumDoc, LPedidoId]
            );
            Inc(Result);
          end
          else
          begin
            LErro := TJSONObject(LResultItem).GetValue<string>('error', 'Falha ao enviar pedido');
            ExecSQL(
              'update outbound_pedido set status = :p0, last_error = :p1 where id = :p2',
              ['ERRO', LErro, LPedidoId]
            );
          end;
        end;

        // marca como erro qualquer pedido que foi enviado no lote mas nao voltou no resultado
        LPedidos.First;
        while not LPedidos.Eof do
        begin
          if LFoundIds.IndexOf(IntToStr(LPedidos.FieldByName('id').AsInteger)) < 0 then
            ExecSQL(
              'update outbound_pedido set status = :p0, last_error = :p1 where id = :p2',
              ['ERRO', 'Servidor nao retornou resultado do pedido no lote', LPedidos.FieldByName('id').AsInteger]
            );
          LPedidos.Next;
        end;
      finally
        LResponse.Free;
      end;
    finally
      LBody.Free;
    end;
  finally
    LFoundIds.Free;
    LItens.Free;
    LPedidos.Free;
  end;
end;

procedure TdmApp.SeedConfig;
begin
  ExecSQL('insert or ignore into api_session (id, base_url) values (1, :p0)', ['http://localhost:9000']);
  ExecSQL('insert or ignore into app_config (key, value) values (:p0, :p1)', ['api_base_url', 'http://localhost:9000']);
  ExecSQL('insert or ignore into sync_table_state (table_name) values (:p0)', ['representante']);
  ExecSQL('insert or ignore into sync_table_state (table_name) values (:p0)', ['cliente']);
  ExecSQL('insert or ignore into sync_table_state (table_name) values (:p0)', ['produto']);
  ExecSQL('insert or ignore into sync_table_state (table_name) values (:p0)', ['subcategoria']);
  ExecSQL('insert or ignore into sync_table_state (table_name) values (:p0)', ['vendas1']);
  ExecSQL('insert or ignore into sync_table_state (table_name) values (:p0)', ['vendas2']);
  ExecSQL('insert or ignore into sync_table_state (table_name) values (:p0)', ['fop']);
  ExecSQL('insert or ignore into sync_table_state (table_name) values (:p0)', ['prazo']);
  ExecSQL('insert or ignore into sync_table_state (table_name) values (:p0)', ['cidades']);
  ExecSQL('insert or ignore into sync_table_state (table_name) values (:p0)', ['produto_representante']);
  ExecSQL('insert or ignore into sync_table_state (table_name) values (:p0)', ['grupo_representante']);
  ExecSQL('insert or ignore into sync_table_state (table_name) values (:p0)', ['produto_representante_inativos']);
  ExecSQL('insert or ignore into sync_table_state (table_name) values (:p0)', ['prazo_representante']);
end;

procedure TdmApp.SetApiBaseUrl(const AValue: string);
begin
  FDConnection.DriverName := 'SQLite';
  ApiBaseUrlOverride := AValue;
  ExecSQL(
    'insert into app_config (key, value, updated_at) values (:p0, :p1, datetime(''now'')) ' +
    'on conflict(key) do update set value = excluded.value, updated_at = excluded.updated_at',
    ['api_base_url', AValue]
  );
  ExecSQL('update api_session set base_url = :p0 where id = 1', [AValue]);
end;

function TdmApp.SyncTable(const ATableName, ACodRepresentante: string; ALimit: Integer): Integer;
var
  LArray: TJSONArray;
  LColumns: TStringList;
  LTypes: TStringList;
  LColSql: TStringList;
  LParams: TStringList;
  LQuery: TFDQuery;
  I: Integer;
  J: Integer;
  LRow: TJSONValue;
  LNumDocVal: TJSONValue;
  LOffset: Integer;
  LPageSize: Integer;
  LTotal: Integer;
  LCount: Integer;
  LTotalRemote: Integer;
  LProgressTotal: Integer;
  LDataUltSyncTabela: string;
  LIncrementalTable: Boolean;
  LShowTotalProgress: Boolean;
  LNeedCountRemote: Boolean;
  LLastProgressNotified: Integer;
  LOldJournalMode: string;
  LOldSynchronous: Int64;
  LOldTempStore: Int64;
  LOldCacheSize: Int64;
  LPerfModeApplied: Boolean;
const
  CLogEachRowSql = False;
  CProgressChunk = 100;
  function JoinList(AList: TStrings): string;
  var
    K: Integer;
  begin
    Result := '';
    for K := 0 to AList.Count - 1 do
    begin
      if K > 0 then
        Result := Result + ', ';
      Result := Result + AList[K];
    end;
  end;

  function FetchPage(AOffset, ASize: Integer): TJSONArray;
  var
    LReq: TJSONObject;
    LNumDocs: TJSONArray;
    K: Integer;
    LNumDocInt: Int64;
  begin
    LReq := TJSONObject.Create;
    try
      LReq.AddPair('table', ATableName);
      if ASize > 0 then
      begin
        LReq.AddPair('limit', TJSONNumber.Create(ASize));
        LReq.AddPair('offset', TJSONNumber.Create(AOffset));
      end;
      if ACodRepresentante <> '' then
        LReq.AddPair('codRepresentante', ACodRepresentante);
      if SameText(ATableName, 'vendas2') and (FLastVendas1NumDocs.Count > 0) then
      begin
        LNumDocs := TJSONArray.Create;
        for K := 0 to FLastVendas1NumDocs.Count - 1 do
          if TryStrToInt64(FLastVendas1NumDocs[K], LNumDocInt) and (LNumDocInt > 0) then
            LNumDocs.AddElement(TJSONNumber.Create(LNumDocInt));
        LReq.AddPair('numdocs', LNumDocs);
      end;
      if (SameText(ATableName, 'produto') or SameText(ATableName, 'subcategoria')) and
         (Trim(LDataUltSyncTabela) <> '') then
        LReq.AddPair('dataUltSincronizacao', LDataUltSyncTabela);
      Result := ExecuteJsonArrayRequest('api/list', LReq);
    finally
      LReq.Free;
    end;
  end;

  function CountRemote: Integer;
  var
    LOff: Integer;
    LArr: TJSONArray;
    LCnt: Integer;
  begin
    Result := 0;
    LOff := 0;
    repeat
      LArr := FetchPage(LOff, LPageSize);
      try
        LCnt := LArr.Count;
        Result := Result + LCnt;
      finally
        LArr.Free;
      end;
      if (ALimit > 0) or (LCnt < LPageSize) then
        Break;
      LOff := LOff + LPageSize;
    until False;
  end;
begin
  try
    Inc(FSkipConnectionCheck);
    try
    Result := 0;
    if SameText(ATableName, 'vendas1') then
      FLastVendas1NumDocs.Clear;
    LTotal := 0;
    LOffset := 0;
    {$IFDEF ANDROID}
    if SameText(ATableName, 'vendas2') then
      LPageSize := 8000
    else
      LPageSize := 5000;
    {$ELSE}
    LPageSize := 2000;
    {$ENDIF}
    LDataUltSyncTabela := '';
    LIncrementalTable := SameText(ATableName, 'produto') or SameText(ATableName, 'subcategoria');
    LShowTotalProgress := LIncrementalTable;
    if SameText(ATableName, 'produto') or SameText(ATableName, 'subcategoria') then
    begin
      LQuery := TFDQuery.Create(nil);
      try
        LQuery.Connection := FDConnection;
        LQuery.SQL.Text :=
          'select coalesce(last_sync_at, '''') as last_sync_at ' +
          'from sync_table_state where table_name = :p0';
        LQuery.ParamByName('p0').AsString := ATableName;
        LQuery.Open;
        LDataUltSyncTabela := Trim(LQuery.FieldByName('last_sync_at').AsString);
      finally
        LQuery.Free;
      end;
    end;
    LNeedCountRemote := False;
    LTotalRemote := 0;
    LLastProgressNotified := -1;

    LogRequest('SYNC_STEP', 'ENTER', ATableName, 'page=' + LPageSize.ToString, 0);

    if not TableExists(ATableName) then
      raise Exception.Create('Tabela ' + ATableName + ' nao existe no SQLite');
    LogRequest('SYNC_STEP', 'TABLE_OK', ATableName, '', 0);

    LColumns := TStringList.Create;
    LTypes := TStringList.Create;
    try
      GetTableColumns(ATableName, LColumns, LTypes, SameText(ATableName, 'subcategoria'));
      if SameText(ATableName, 'vendas2') then
      begin
        LColumns.Clear;
        LTypes.Clear;
        LColumns.Add('numdoc');            LTypes.Add('INTEGER');
        LColumns.Add('cod_produto');       LTypes.Add('INTEGER');
        LColumns.Add('qtd');               LTypes.Add('REAL');
        LColumns.Add('preco');             LTypes.Add('REAL');
        LColumns.Add('desconto');          LTypes.Add('REAL');
        LColumns.Add('cod_cliente');       LTypes.Add('INTEGER');
        LColumns.Add('cod_representante'); LTypes.Add('INTEGER');
      end;
      if LColumns.Count = 0 then
        raise Exception.Create('Tabela ' + ATableName + ' sem colunas no SQLite');
      LogRequest('SYNC_STEP', 'COLUMNS_OK', ATableName, 'cols=' + LColumns.Count.ToString, 0);

      LColSql := TStringList.Create;
      LParams := TStringList.Create;
      LQuery := TFDQuery.Create(nil);
      try
        for I := 0 to LColumns.Count - 1 do
        begin
          LColSql.Add('"' + LColumns[I] + '"');
          LParams.Add(':p' + I.ToString);
        end;

        LQuery.Connection := FDConnection;
        LQuery.SQL.Text := 'insert or replace into "' + ATableName + '" (' +
          JoinList(LColSql) + ') values (' + JoinList(LParams) + ')';
        for I := 0 to LQuery.Params.Count - 1 do
          LQuery.Params[I].DataType := SqliteTypeToFieldType(LTypes[I]);

        try
          LPerfModeApplied := False;
          if not LIncrementalTable then
          begin
            LOldJournalMode := '';
            LOldSynchronous := -1;
            LOldTempStore := -1;
            LOldCacheSize := -1;
            try
              LOldJournalMode := GetScalarAsString('PRAGMA journal_mode', []);
              LOldSynchronous := GetScalarInt64('PRAGMA synchronous', []);
              LOldTempStore := GetScalarInt64('PRAGMA temp_store', []);
              LOldCacheSize := GetScalarInt64('PRAGMA cache_size', []);
              FDConnection.ExecSQL('PRAGMA journal_mode = MEMORY');
              FDConnection.ExecSQL('PRAGMA synchronous = OFF');
              FDConnection.ExecSQL('PRAGMA temp_store = MEMORY');
              FDConnection.ExecSQL('PRAGMA cache_size = -30000');
              LPerfModeApplied := True;
            except
              // segue normal se pragma falhar
            end;
          end;

          if not LIncrementalTable then
          begin
            LogSyncSql(ATableName, 'delete from "' + ATableName + '"', nil);
            try
              FDConnection.ExecSQL('delete from "' + ATableName + '"');
            except
              on E: Exception do
              begin
                LogSyncSqlError(ATableName, 'delete from "' + ATableName + '"', nil, E.Message);
                raise;
              end;
            end;
          end;
          LogRequest('SYNC_STEP', 'CLEAR_OK', ATableName, '', 0);


        repeat
          try
            LArray := FetchPage(LOffset, LPageSize);
          except
            on E: Exception do
            begin
              SetSyncTableError(ATableName, ACodRepresentante, 'FetchPage: ' + E.Message);
              LogRequest('SYNC_STEP', 'ERROR', ATableName, 'FetchPage: ' + E.Message, 0);
              raise;
            end;
          end;
          try
            LCount := LArray.Count;

            LProgressTotal := LOffset + LCount;
            if LTotalRemote > 0 then
              LProgressTotal := LTotalRemote;

            if Assigned(FOnSyncProgress) then
              FOnSyncProgress(
                ATableName,
                0,
                LProgressTotal,
                LOffset = 0
              );

            if not FDConnection.InTransaction then
              FDConnection.StartTransaction;
            try
              for I := 0 to LArray.Count - 1 do
              begin
                LRow := LArray.Items[I];
                if not (LRow is TJSONObject) then
                  raise Exception.Create('Cada item da tabela ' + ATableName + ' deve ser um objeto JSON');

                try
                  for J := 0 to LColumns.Count - 1 do
                    AssignParamFromJson(LQuery.Params[J], GetJsonValueCI(TJSONObject(LRow), LColumns[J]));
                  if SameText(ATableName, 'vendas1') then
                  begin
                    LNumDocVal := GetJsonValueCI(TJSONObject(LRow), 'numdoc');
                    if Assigned(LNumDocVal) then
                    begin
                      if LNumDocVal is TJSONNumber then
                        FLastVendas1NumDocs.Add(IntToStr(TJSONNumber(LNumDocVal).AsInt64))
                      else
                        FLastVendas1NumDocs.Add(Trim(LNumDocVal.Value));
                    end;
                  end;
                except
                  on E: Exception do
                  begin
                    SetSyncTableError(ATableName, ACodRepresentante, 'AssignParam: ' + E.Message);
                    LogRequest('SYNC_STEP', 'ERROR', ATableName, 'AssignParam: ' + E.Message, 0);
                    raise;
                  end;
                end;

                if CLogEachRowSql then
                  LogSyncSql(ATableName, LQuery.SQL.Text, LQuery.Params);
                try
                  LQuery.ExecSQL;
                except
                  on E: Exception do
                  begin
                    LogSyncSqlError(ATableName, LQuery.SQL.Text, LQuery.Params, E.Message);
                    SetSyncTableError(ATableName, ACodRepresentante, 'ExecSQL: ' + E.Message);
                    LogRequest('SYNC_STEP', 'ERROR', ATableName, 'ExecSQL: ' + E.Message, 0);
                    raise;
                  end;
                end;

                LTotal := LTotal + 1;
                if Assigned(FOnSyncProgress) and
                   ((LTotal = 1) or
                    (LTotal = LProgressTotal) or
                    ((LTotal - LLastProgressNotified) >= CProgressChunk)) then
                begin
                  FOnSyncProgress(ATableName, LTotal, LProgressTotal, False);
                  LLastProgressNotified := LTotal;
                end;
              end;
              FDConnection.Commit;
            except
              if FDConnection.InTransaction then
                FDConnection.Rollback;
              raise;
            end;

            ExecSQL(
              'insert into sync_table_state (table_name, representative_code, last_sync_at, row_count, last_error) values (:p0, :p1, datetime(''now''), :p2, null) ' +
              'on conflict(table_name) do update set representative_code = excluded.representative_code, last_sync_at = excluded.last_sync_at, row_count = excluded.row_count, last_error = null',
              [ATableName, ACodRepresentante, LTotal]
            );
          finally
            LArray.Free;
          end;

          if (ALimit > 0) or (LCount < LPageSize) then
            Break;
          LOffset := LOffset + LPageSize;
        until False;

      except
        on e : exception do
        begin
          raise Exception.Create(e.Message);

          if FDConnection.InTransaction then
            FDConnection.Rollback;
          raise;
        end;
      end;
      if LPerfModeApplied then
      begin
        try
          if LOldJournalMode <> '' then
            FDConnection.ExecSQL('PRAGMA journal_mode = ' + LOldJournalMode);
        except
        end;
        try
          if LOldSynchronous >= 0 then
            FDConnection.ExecSQL('PRAGMA synchronous = ' + IntToStr(LOldSynchronous));
        except
        end;
        try
          if LOldTempStore >= 0 then
            FDConnection.ExecSQL('PRAGMA temp_store = ' + IntToStr(LOldTempStore));
        except
        end;
        try
          if LOldCacheSize <> 0 then
            FDConnection.ExecSQL('PRAGMA cache_size = ' + IntToStr(LOldCacheSize));
        except
        end;
      end;
    finally
      LQuery.Free;
      LParams.Free;
      LColSql.Free;
    end;
  finally
    LTypes.Free;
    LColumns.Free;
  end;

  LogRequest('SYNC_STEP', 'DONE', ATableName, 'rows=' + LTotal.ToString, 0);

  ExecSQL(
    'insert into sync_table_state (table_name, representative_code, last_sync_at, row_count, last_error) values (:p0, :p1, datetime(''now''), :p2, null) ' +
    'on conflict(table_name) do update set representative_code = excluded.representative_code, last_sync_at = excluded.last_sync_at, row_count = excluded.row_count, last_error = null',
    [ATableName, ACodRepresentante, LTotal]
  );
  Result := LTotal;
    finally
      Dec(FSkipConnectionCheck);
    end;
  except
    on E: Exception do
    begin
      SetSyncTableError(ATableName, ACodRepresentante, E.Message);
      LogRequest('SYNC_STEP', 'ERROR', ATableName, E.Message, 0);
      raise;
    end;
  end;
end;

function TdmApp.SyncAllTables(const ACodRepresentante: string): Integer;
const
  CDefaultTables: array[0..11] of string = (
    'representante',
    'cliente',
    'vendas1',
    'vendas2',
    'produto',
    'fop',
    'prazo',
    'cidades',
    'produto_representante',
    'grupo_representante',
    'produto_representante_inativos',
    'prazo_representante'
  );
var
  LBody: TJSONObject;
  LResp: TJSONObject;
  LTableName: string;
  LArrayValue: TJSONValue;
  LArray: TJSONArray;
  LColumns: TStringList;
  LTypes: TStringList;
  LColSql: TStringList;
  LParams: TStringList;
  LQuery: TFDQuery;
  I: Integer;
  J: Integer;
  LRow: TJSONValue;
  LCount: Integer;
  LTables: array of string;
  K: Integer;

  function JoinList(AList: TStrings): string;
  var
    K: Integer;
  begin
    Result := '';
    for K := 0 to AList.Count - 1 do
    begin
      if K > 0 then
        Result := Result + ', ';
      Result := Result + AList[K];
    end;
  end;

  procedure InsertArray(const ATable: string; AData: TJSONArray);
  var
    K: Integer;
    M: Integer;
  begin
    if not Assigned(AData) then
      Exit;
    if not TableExists(ATable) then
      raise Exception.Create('Tabela ' + ATable + ' nao existe no SQLite');

    LColumns.Clear;
    LTypes.Clear;
    LColSql.Clear;
    LParams.Clear;
    GetTableColumns(ATable, LColumns, LTypes, SameText(ATable, 'subcategoria'));
    if LColumns.Count = 0 then
      Exit;

    for K := 0 to LColumns.Count - 1 do
    begin
      LColSql.Add('"' + LColumns[K] + '"');
      LParams.Add(':p' + K.ToString);
    end;

    LQuery.SQL.Text := 'insert or replace into "' + ATable + '" (' +
      JoinList(LColSql) + ') values (' + JoinList(LParams) + ')';
    for K := 0 to LQuery.Params.Count - 1 do
      LQuery.Params[K].DataType := SqliteTypeToFieldType(LTypes[K]);

    if not FDConnection.InTransaction then
      FDConnection.StartTransaction;
    try
      ExecSQL('delete from "' + ATable + '"', []);
      for K := 0 to AData.Count - 1 do
      begin
        LRow := AData.Items[K];
        if not (LRow is TJSONObject) then
          raise Exception.Create('Cada item da tabela ' + ATable + ' deve ser um objeto JSON');
        for M := 0 to LColumns.Count - 1 do
          AssignParamFromJson(LQuery.Params[M], GetJsonValueCI(TJSONObject(LRow), LColumns[M]));
        LogSyncSql(ATable, LQuery.SQL.Text, LQuery.Params);
        try
          LQuery.ExecSQL;
        except
          on E: Exception do
          begin
            LogSyncSqlError(ATable, LQuery.SQL.Text, LQuery.Params, E.Message);
            raise;
          end;
        end;
      end;
      FDConnection.Commit;
    except
      if FDConnection.InTransaction then
        FDConnection.Rollback;
      raise;
    end;

    LCount := AData.Count;
    ExecSQL(
      'insert into sync_table_state (table_name, representative_code, last_sync_at, row_count, last_error) values (:p0, :p1, datetime(''now''), :p2, null) ' +
      'on conflict(table_name) do update set representative_code = excluded.representative_code, last_sync_at = excluded.last_sync_at, row_count = excluded.row_count, last_error = null',
      [ATable, ACodRepresentante, LCount]
    );
  end;

begin
  SetLength(LTables, Length(CDefaultTables));
  for K := 0 to High(CDefaultTables) do
    LTables[K] := CDefaultTables[K];
  Result := SyncAllTablesSelected(ACodRepresentante, LTables);
end;

function TdmApp.SyncAllTablesSelected(const ACodRepresentante: string; const ATables: array of string): Integer;
var
  LBody: TJSONObject;
  LResp: TJSONObject;
  LTableName: string;
  LArrayValue: TJSONValue;
  LArray: TJSONArray;
  LColumns: TStringList;
  LTypes: TStringList;
  LColSql: TStringList;
  LParams: TStringList;
  LQuery: TFDQuery;
  I: Integer;
  J: Integer;
  LRow: TJSONValue;
  LCount: Integer;
  LTablesJson: TJSONArray;

  function JoinList(AList: TStrings): string;
  var
    K: Integer;
  begin
    Result := '';
    for K := 0 to AList.Count - 1 do
    begin
      if K > 0 then
        Result := Result + ', ';
      Result := Result + AList[K];
    end;
  end;

  procedure InsertArray(const ATable: string; AData: TJSONArray);
  var
    K: Integer;
    M: Integer;
    total : integer;
  begin
    if not Assigned(AData) then
      Exit;
    if not TableExists(ATable) then
      raise Exception.Create('Tabela ' + ATable + ' nao existe no SQLite');

    LColumns.Clear;
    LTypes.Clear;
    LColSql.Clear;
    LParams.Clear;
    GetTableColumns(ATable, LColumns, LTypes, SameText(ATable, 'subcategoria'));
    if LColumns.Count = 0 then
      Exit;

    for K := 0 to LColumns.Count - 1 do
    begin
      LColSql.Add('"' + LColumns[K] + '"');
      LParams.Add(':p' + K.ToString);
    end;

    LQuery.SQL.Text := 'insert or replace into "' + ATable + '" (' +
      JoinList(LColSql) + ') values (' + JoinList(LParams) + ')';
    for K := 0 to LQuery.Params.Count - 1 do
      LQuery.Params[K].DataType := SqliteTypeToFieldType(LTypes[K]);

    if not FDConnection.InTransaction then
      FDConnection.StartTransaction;
    try
      ExecSQL('delete from "' + ATable + '"', []);

      total := AData.Count - 1;
      if total > 50 then
        Total := 50;

      for K := 0 to {AData.Count - 1} total do
      begin
        LRow := AData.Items[K];
        if not (LRow is TJSONObject) then
          raise Exception.Create('Cada item da tabela ' + ATable + ' deve ser um objeto JSON');
        for M := 0 to LColumns.Count - 1 do
          AssignParamFromJson(LQuery.Params[M], GetJsonValueCI(TJSONObject(LRow), LColumns[M]));
        LogSyncSql(ATable, LQuery.SQL.Text, LQuery.Params);
        try
          LQuery.ExecSQL;
        except
          on E: Exception do
          begin
            LogSyncSqlError(ATable, LQuery.SQL.Text, LQuery.Params, E.Message);
            raise;
          end;
        end;
      end;
      FDConnection.Commit;
    except
      if FDConnection.InTransaction then
        FDConnection.Rollback;
      raise;
    end;

    LCount := AData.Count;
    ExecSQL(
      'insert into sync_table_state (table_name, representative_code, last_sync_at, row_count, last_error) values (:p0, :p1, datetime(''now''), :p2, null) ' +
      'on conflict(table_name) do update set representative_code = excluded.representative_code, last_sync_at = excluded.last_sync_at, row_count = excluded.row_count, last_error = null',
      [ATable, ACodRepresentante, LCount]
    );
  end;

begin
  Result := 0;
  LBody := TJSONObject.Create;
  try
    if Trim(ACodRepresentante) <> '' then
      LBody.AddPair('codRepresentante', ACodRepresentante);
    LTablesJson := TJSONArray.Create;
    for I := 0 to High(ATables) do
      LTablesJson.Add(ATables[I]);
    LBody.AddPair('tables', LTablesJson);

    try
      LResp := ExecuteJsonObjectRequest('api/sync_all', LBody);
    except
      on E: Exception do
      begin
        for I := 0 to High(ATables) do
          ExecSQL(
            'insert into sync_table_state (table_name, representative_code, last_sync_at, row_count, last_error) values (:p0, :p1, datetime(''now''), :p2, :p3) ' +
            'on conflict(table_name) do update set representative_code = excluded.representative_code, last_sync_at = excluded.last_sync_at, row_count = excluded.row_count, last_error = excluded.last_error',
            [ATables[I], ACodRepresentante, 0, E.Message]
          );
        LogRequest('SYNC_STEP', 'ERROR', 'sync_all', E.Message, 0);
        Exit;
      end;
    end;
    try
      LColumns := TStringList.Create;
      LTypes := TStringList.Create;
      LColSql := TStringList.Create;
      LParams := TStringList.Create;
      LQuery := TFDQuery.Create(nil);
      try
        LQuery.Connection := FDConnection;
        for I := 0 to High(ATables) do
        begin
          LTableName := ATables[I];
          LArrayValue := LResp.GetValue(LTableName);
          if not (LArrayValue is TJSONArray) then
          begin
            ExecSQL(
              'insert into sync_table_state (table_name, representative_code, last_sync_at, row_count, last_error) values (:p0, :p1, datetime(''now''), :p2, :p3) ' +
              'on conflict(table_name) do update set representative_code = excluded.representative_code, last_sync_at = excluded.last_sync_at, row_count = excluded.row_count, last_error = excluded.last_error',
              [LTableName, ACodRepresentante, 0, 'Nao retornado pelo servidor']
            );
            LogRequest('SYNC_STEP', 'MISSING', LTableName, 'Nao retornado pelo servidor', 0);
            continue;
          end;
          LArray := TJSONArray(LArrayValue);
          try
            InsertArray(LTableName, LArray);
            Inc(Result, LArray.Count);
          except
            on E: Exception do
            begin
              ExecSQL(
                'insert into sync_table_state (table_name, representative_code, last_sync_at, row_count, last_error) values (:p0, :p1, datetime(''now''), :p2, :p3) ' +
                'on conflict(table_name) do update set representative_code = excluded.representative_code, last_sync_at = excluded.last_sync_at, row_count = excluded.row_count, last_error = excluded.last_error',
                [LTableName, ACodRepresentante, 0, E.Message]
              );
              LogRequest('SYNC_STEP', 'ERROR', LTableName, E.Message, 0);
            end;
          end;
        end;
      finally
        LQuery.Free;
        LParams.Free;
        LColSql.Free;
        LTypes.Free;
        LColumns.Free;
      end;
    finally
      LResp.Free;
    end;
  finally
    LBody.Free;
  end;
end;

end.
