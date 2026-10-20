unit ServiceGeoWorker;

interface

uses
  System.SysUtils, System.JSON, System.Net.HttpClient,
  FireDAC.Comp.Client;

type
  TServiceGeoWorker = class
  private const
    CEarthRadiusMeters = 6371000.0;
    CVisitRadiusMeters = 100.0;
    CVisitMinMinutes = 30.0;
    CMinLocationChangeMeters = 1.0;
  private
    FConnection: TFDConnection;
    FHttp: THTTPClient;
    FBusy: Boolean;
    function BuildUrl(const AEndpoint: string): string;
    function DatabaseFileName: string;
    function DistanceMeters(ALat1, ALon1, ALat2, ALon2: Double): Double;
    function GetApiBaseUrl: string;
    function GetCodRepresentante: Integer;
    function GetScalarInt64(const ASql: string; const AParams: array of Variant): Int64;
    procedure EnsureConnection;
    procedure EnsureDatabase;
    procedure ExecSQL(const ASql: string; const AParams: array of Variant);
    procedure PostJsonObject(const AEndpoint: string; ABody: TJSONObject);
  public
    destructor Destroy; override;
    function RepresentantePermiteGps: Boolean;
    procedure RegistrarGeolocalizacao(ALatitude, ALongitude, AVelocidadeKmh: Double);
    procedure EnviarPendentesBackground;
  end;

implementation

uses
  System.Classes, System.IOUtils, System.Math,
  FireDAC.Stan.Def, FireDAC.Stan.Async, FireDAC.Stan.Param, FireDAC.Phys,
  FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.DApt,
  FireDAC.FMXUI.Wait, Data.DB, Androidapi.Log;

procedure LogGeoWorker(const AText: string);
var
  LText: UTF8String;
begin
  LText := UTF8String(AText);
  __android_log_write(android_LogPriority.ANDROID_LOG_INFO, 'WorbyRepresGPS', MarshaledAString(LText));
end;

function TServiceGeoWorker.BuildUrl(const AEndpoint: string): string;
var
  LBase: string;
  LEndpoint: string;
begin
  LBase := Trim(GetApiBaseUrl);
  LEndpoint := Trim(AEndpoint);
  while (LBase <> '') and (LBase[Length(LBase)] = '/') do
    Delete(LBase, Length(LBase), 1);
  while (LEndpoint <> '') and (LEndpoint[1] = '/') do
    Delete(LEndpoint, 1, 1);
  if LBase = '' then
    Exit('');
  Result := LBase + '/' + LEndpoint;
end;

function TServiceGeoWorker.DatabaseFileName: string;
begin
  Result := TPath.Combine(TPath.GetDocumentsPath, 'WorbyRep');
  if not TDirectory.Exists(Result) then
    TDirectory.CreateDirectory(Result);
  Result := TPath.Combine(Result, 'db.sqllite');
end;

destructor TServiceGeoWorker.Destroy;
begin
  FHttp.Free;
  FConnection.Free;
  inherited;
end;

function TServiceGeoWorker.DistanceMeters(ALat1, ALon1, ALat2, ALon2: Double): Double;
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

procedure TServiceGeoWorker.EnsureConnection;
begin
  if not Assigned(FConnection) then
  begin
    FConnection := TFDConnection.Create(nil);
    FConnection.LoginPrompt := False;
    FConnection.Params.Clear;
    FConnection.Params.Add('DriverID=SQLite');
  FConnection.Params.Add('Database=' + DatabaseFileName);
    FConnection.Params.Values['LockingMode'] := 'Normal';
    FConnection.Params.Values['Synchronous'] := 'Normal';
    FConnection.Params.Values['BusyTimeout'] := '5000';
  end;

  if not FConnection.Connected then
  begin
    LogGeoWorker('SQLite open: ' + DatabaseFileName);
    FConnection.Connected := True;
    EnsureDatabase;
    LogGeoWorker('SQLite open ok');
  end;

  if not Assigned(FHttp) then
  begin
    FHttp := THTTPClient.Create;
    FHttp.ConnectionTimeout := 5000;
    FHttp.ResponseTimeout := 10000;
  end;
end;

procedure TServiceGeoWorker.EnsureDatabase;

  function TableExists(const ATableName: string): Boolean;
  var
    LQuery: TFDQuery;
  begin
    Result := False;
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := FConnection;
      LQuery.SQL.Text := 'select 1 from sqlite_master where type = ''table'' and lower(name) = lower(:p0) limit 1';
      LQuery.ParamByName('p0').AsString := ATableName;
      LQuery.Open;
      Result := not LQuery.IsEmpty;
    finally
      LQuery.Free;
    end;
  end;

  procedure AddColumnIfMissing(const ATableName, AColumnName, AColumnSql: string);
  var
    LQuery: TFDQuery;
    LFound: Boolean;
  begin
    if not TableExists(ATableName) then
      Exit;

    LFound := False;
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := FConnection;
      LQuery.SQL.Text := 'pragma table_info("' + ATableName + '")';
      LQuery.Open;
      while not LQuery.Eof do
      begin
        if SameText(LQuery.FieldByName('name').AsString, AColumnName) then
        begin
          LFound := True;
          Break;
        end;
        LQuery.Next;
      end;
    finally
      LQuery.Free;
    end;

    if not LFound then
    begin
      FConnection.ExecSQL('alter table "' + ATableName + '" add column ' + AColumnSql);
      LogGeoWorker('EnsureDatabase add column ' + ATableName + '.' + AColumnName);
    end;
  end;

begin
  FConnection.ExecSQL(
    'create table if not exists app_config (' +
    'key text primary key, value text, updated_at text default current_timestamp)');
  FConnection.ExecSQL(
    'create table if not exists api_session (' +
    'id integer primary key check (id = 1), base_url text, login text, senha text, ' +
    'user_json text, last_login_at text, last_error text)');
  FConnection.ExecSQL(
    'create table if not exists representante_localizacao (' +
    'id integer primary key autoincrement, cod_representante integer not null, ' +
    'datahora text not null, velocidade real, latitude real not null, longitude real not null, ' +
    'enviado text default ''N'', sent_at text, last_error text)');
  FConnection.ExecSQL(
    'create table if not exists cliente_visitas (' +
    'cod_cliente integer not null, data text not null, vendeu text, enviado text default ''N'', ' +
    'motivo_n_venda blob, valor_pedido real, datahora text not null, cod_representante integer, ' +
    'status_visita text, sent_at text, last_error text, primary key(cod_cliente, datahora))');

  AddColumnIfMissing('cliente', 'latitude', 'latitude real');
  AddColumnIfMissing('cliente', 'longitude', 'longitude real');
  AddColumnIfMissing('cliente_visitas', 'enviado', 'enviado text default ''N''');
  AddColumnIfMissing('cliente_visitas', 'sent_at', 'sent_at text');
  AddColumnIfMissing('cliente_visitas', 'last_error', 'last_error text');
  AddColumnIfMissing('cliente_visitas', 'motivo_n_venda', 'motivo_n_venda blob');
  AddColumnIfMissing('cliente_visitas', 'status_visita', 'status_visita text');
  AddColumnIfMissing('representante_localizacao', 'enviado', 'enviado text default ''N''');
  AddColumnIfMissing('representante_localizacao', 'sent_at', 'sent_at text');
  AddColumnIfMissing('representante_localizacao', 'last_error', 'last_error text');
end;

procedure TServiceGeoWorker.ExecSQL(const ASql: string; const AParams: array of Variant);
var
  LQuery: TFDQuery;
  I: Integer;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := ASql;
    for I := 0 to High(AParams) do
      LQuery.Params[I].Value := AParams[I];
    LQuery.ExecSQL;
  finally
    LQuery.Free;
  end;
end;

procedure TServiceGeoWorker.EnviarPendentesBackground;
var
  LQuery: TFDQuery;
  LBody: TJSONObject;
begin
  EnsureConnection;
  if BuildUrl('api/geolocalizacao') = '' then
  begin
    LogGeoWorker('EnviarPendentes: API base vazia');
    Exit;
  end;

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text :=
      'select id, cod_representante, datahora, velocidade, latitude, longitude ' +
      'from representante_localizacao where coalesce(enviado, ''N'') <> ''S'' order by id limit 100';
    LQuery.Open;
    while not LQuery.Eof do
    begin
      LBody := TJSONObject.Create;
      try
        LBody.AddPair('id', TJSONNumber.Create(LQuery.FieldByName('id').AsLargeInt));
        LBody.AddPair('cod_representante', TJSONNumber.Create(LQuery.FieldByName('cod_representante').AsInteger));
        LBody.AddPair('datahora', LQuery.FieldByName('datahora').AsString);
        LBody.AddPair('velocidade', TJSONNumber.Create(LQuery.FieldByName('velocidade').AsFloat));
        LBody.AddPair('latitude', TJSONNumber.Create(LQuery.FieldByName('latitude').AsFloat));
        LBody.AddPair('longitude', TJSONNumber.Create(LQuery.FieldByName('longitude').AsFloat));
        LogGeoWorker('Post geolocalizacao id=' + LQuery.FieldByName('id').AsString);
        PostJsonObject('api/geolocalizacao', LBody);
        ExecSQL(
          'update representante_localizacao set enviado = ''S'', sent_at = datetime(''now''), last_error = null where id = :p0',
          [LQuery.FieldByName('id').AsLargeInt]);
      except
        on E: Exception do
        begin
          LogGeoWorker('Post geolocalizacao erro id=' + LQuery.FieldByName('id').AsString + ': ' + E.Message);
          ExecSQL('update representante_localizacao set last_error = :p0 where id = :p1',
            [E.Message, LQuery.FieldByName('id').AsLargeInt]);
        end;
      end;
      LBody.Free;
      LQuery.Next;
    end;
    LQuery.Close;

    LQuery.SQL.Text :=
      'select cod_cliente, data, vendeu, motivo_n_venda, valor_pedido, datahora, cod_representante, status_visita ' +
      'from cliente_visitas where coalesce(enviado, ''N'') <> ''S'' order by datahora limit 100';
    LQuery.Open;
    while not LQuery.Eof do
    begin
      LBody := TJSONObject.Create;
      try
        LBody.AddPair('cod_cliente', TJSONNumber.Create(LQuery.FieldByName('cod_cliente').AsInteger));
        LBody.AddPair('data', LQuery.FieldByName('data').AsString);
        LBody.AddPair('vendeu', LQuery.FieldByName('vendeu').AsString);
        LBody.AddPair('motivo_n_venda', LQuery.FieldByName('motivo_n_venda').AsString);
        LBody.AddPair('valor_pedido', TJSONNumber.Create(LQuery.FieldByName('valor_pedido').AsFloat));
        if Trim(LQuery.FieldByName('status_visita').AsString) <> '' then
          LBody.AddPair('status_visita', LQuery.FieldByName('status_visita').AsString)
        else if SameText(Trim(LQuery.FieldByName('vendeu').AsString), 'S') then
          LBody.AddPair('status_visita', 'Venda')
        else
          LBody.AddPair('status_visita', 'PROXIMIDADE');
        LBody.AddPair('datahora', LQuery.FieldByName('datahora').AsString);
        LBody.AddPair('cod_representante', TJSONNumber.Create(LQuery.FieldByName('cod_representante').AsInteger));
        PostJsonObject('api/cliente_visita', LBody);
        ExecSQL(
          'update cliente_visitas set enviado = ''S'', sent_at = datetime(''now''), last_error = null where cod_cliente = :p0 and datahora = :p1',
          [LQuery.FieldByName('cod_cliente').AsInteger, LQuery.FieldByName('datahora').AsString]);
      except
        on E: Exception do
          ExecSQL('update cliente_visitas set last_error = :p0 where cod_cliente = :p1 and datahora = :p2',
            [E.Message, LQuery.FieldByName('cod_cliente').AsInteger, LQuery.FieldByName('datahora').AsString]);
      end;
      LBody.Free;
      LQuery.Next;
    end;
  finally
    LQuery.Free;
  end;
end;

function TServiceGeoWorker.GetApiBaseUrl: string;
var
  LQuery: TFDQuery;
  LValue: string;
begin
  Result := '';
  LValue := '';
  EnsureConnection;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := 'select value from app_config where key = :p0';
    LQuery.ParamByName('p0').AsString := 'api_base_url';
    LQuery.Open;
    if not LQuery.IsEmpty then
      LValue := Trim(LQuery.Fields[0].AsString);
    LQuery.Close;

    if LValue = '' then
    begin
      LQuery.SQL.Text := 'select base_url from api_session where id = 1';
      LQuery.Open;
      if not LQuery.IsEmpty then
        LValue := Trim(LQuery.Fields[0].AsString);
    end;

    if SameText(LValue, 'PLASFAN') then
      Result := 'http://plasfan.ddns.com.br:9004'
{    else if SameText(LValue, 'PLASFAN - TESTES') then
      Result := 'http://plasfan.ddns.com.br:9004'}
    else
      Result := LValue;
  finally
    LQuery.Free;
  end;
end;

function TServiceGeoWorker.GetCodRepresentante: Integer;
var
  LQuery: TFDQuery;
  LJsonValue: TJSONValue;
  LUserObj: TJSONObject;
  LUserInner: TJSONObject;
  LRepVal: TJSONValue;
  LUserJson: string;

  function TryValue(const AName: string): Integer;
  begin
    Result := 0;
    if Assigned(LUserInner) then
    begin
      LRepVal := LUserInner.GetValue(AName);
      if Assigned(LRepVal) then
        Result := StrToIntDef(Trim(LRepVal.Value), 0);
    end;
  end;
begin
  Result := 0;
  LUserJson := '';
  EnsureConnection;

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text :=
      'select value from app_config where key = ''cod_representante'' ' +
      'and trim(coalesce(value, '''')) <> '''' limit 1';
    try
      LQuery.Open;
      if not LQuery.IsEmpty then
        Result := StrToIntDef(Trim(LQuery.Fields[0].AsString), 0);
    except
      Result := 0;
    end;
    LQuery.Close;

    if Result > 0 then
    begin
      LogGeoWorker('GetCodRepresentante=' + Result.ToString + ' origem=app_config');
      Exit;
    end;

    LQuery.SQL.Text :=
      'select representative_code from sync_table_state ' +
      'where table_name = ''representante'' and trim(coalesce(representative_code, '''')) <> '''' limit 1';
    try
      LQuery.Open;
      if not LQuery.IsEmpty then
        Result := StrToIntDef(Trim(LQuery.Fields[0].AsString), 0);
    except
      Result := 0;
    end;
    LQuery.Close;

    if Result <= 0 then
    begin
      LQuery.SQL.Text := 'select user_json from api_session where id = 1';
      LQuery.Open;
      if not LQuery.IsEmpty then
        LUserJson := Trim(LQuery.Fields[0].AsString);
      LQuery.Close;

      if LUserJson <> '' then
      begin
        LJsonValue := TJSONObject.ParseJSONValue(LUserJson);
        try
          if LJsonValue is TJSONObject then
          begin
            LUserObj := TJSONObject(LJsonValue);
            LUserInner := nil;
            if LUserObj.GetValue('user') is TJSONObject then
              LUserInner := LUserObj.GetValue('user') as TJSONObject
            else
              LUserInner := LUserObj;

            Result := TryValue('cod_representante');
            if Result <= 0 then
              Result := TryValue('id_representante');
            if Result <= 0 then
              Result := TryValue('id');
            if Result <= 0 then
              Result := TryValue('cod_tablet');
          end;
        finally
          LJsonValue.Free;
        end;
      end;
    end;

    if Result <= 0 then
    begin
      LQuery.SQL.Text := 'select id from representante where id is not null order by id limit 1';
      try
        LQuery.Open;
        if not LQuery.IsEmpty then
          Result := LQuery.Fields[0].AsInteger;
      except
        Result := 0;
      end;
    end;
    LogGeoWorker('GetCodRepresentante=' + Result.ToString);
  finally
    LQuery.Free;
  end;
end;

function TServiceGeoWorker.RepresentantePermiteGps: Boolean;
var
  LCodRepresentante: Integer;
  LFuncionario: string;
  LQuery: TFDQuery;
begin
  Result := False;
  try
    EnsureConnection;
    LCodRepresentante := GetCodRepresentante;
    if LCodRepresentante <= 0 then
    begin
      LogGeoWorker('RepresentantePermiteGps=False sem cod_representante');
      Exit;
    end;

    LFuncionario := '';
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := FConnection;
      try
        LQuery.SQL.Text :=
          'select coalesce(funcionario, '''') as funcionario ' +
          'from representante where id = :p0 or cod_tablet = :p0 limit 1';
        LQuery.ParamByName('p0').AsInteger := LCodRepresentante;
        LQuery.Open;
        if not LQuery.IsEmpty then
          LFuncionario := Trim(LQuery.FieldByName('funcionario').AsString);
      except
        on E: Exception do
        begin
          LFuncionario := '';
          LogGeoWorker('RepresentantePermiteGps representante erro: ' + E.ClassName + ' - ' + E.Message);
        end;
      end;

      if LFuncionario = '' then
      begin
        try
          LQuery.Close;
          LQuery.SQL.Text := 'select coalesce(value, '''') as funcionario from app_config where key = ''representante_funcionario'' limit 1';
          LQuery.Open;
          if not LQuery.IsEmpty then
            LFuncionario := Trim(LQuery.FieldByName('funcionario').AsString);
          LogGeoWorker('RepresentantePermiteGps funcionario app_config=' + LFuncionario);
        except
          on E: Exception do
            LogGeoWorker('RepresentantePermiteGps app_config erro: ' + E.ClassName + ' - ' + E.Message);
        end;
      end;
    finally
      LQuery.Free;
    end;

    Result := SameText(LFuncionario, '1') or SameText(LFuncionario, '4');
    LogGeoWorker('RepresentantePermiteGps=' + BoolToStr(Result, True) +
      ' rep=' + LCodRepresentante.ToString + ' funcionario=' + LFuncionario);
  except
    on E: Exception do
    begin
      Result := False;
      LogGeoWorker('RepresentantePermiteGps erro: ' + E.ClassName + ' - ' + E.Message);
    end;
  end;
end;
function TServiceGeoWorker.GetScalarInt64(const ASql: string; const AParams: array of Variant): Int64;
var
  LQuery: TFDQuery;
  I: Integer;
begin
  Result := 0;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := ASql;
    for I := 0 to High(AParams) do
      LQuery.Params[I].Value := AParams[I];
    LQuery.Open;
    if not LQuery.IsEmpty then
      Result := LQuery.Fields[0].AsLargeInt;
  finally
    LQuery.Free;
  end;
end;

procedure TServiceGeoWorker.PostJsonObject(const AEndpoint: string; ABody: TJSONObject);
var
  LRequest: TStringStream;
  LResponse: IHTTPResponse;
  LUrl: string;
begin
  LUrl := BuildUrl(AEndpoint);
  if LUrl = '' then
    Exit;

  LRequest := TStringStream.Create(ABody.ToJSON, TEncoding.UTF8);
  try
    LResponse := FHttp.Post(LUrl, LRequest);
    if (LResponse.StatusCode < 200) or (LResponse.StatusCode >= 300) then
      raise Exception.CreateFmt('HTTP %d: %s',
        [LResponse.StatusCode, LResponse.ContentAsString(TEncoding.UTF8)]);
  finally
    LRequest.Free;
  end;
end;

procedure TServiceGeoWorker.RegistrarGeolocalizacao(ALatitude, ALongitude, AVelocidadeKmh: Double);
var
  LCodRepresentante: Integer;
  LDataHora: string;
  LData: string;
  LLastLocationQuery: TFDQuery;
  LClienteQuery: TFDQuery;
  LLastLat: Double;
  LLastLon: Double;
  LCodCliente: Integer;
  LClienteLat: Double;
  LClienteLon: Double;
  LDistance: Double;
  LNearestCliente: Integer;
  LNearestDistance: Double;
  LRecentVisits: Int64;
  LShouldRegisterLocation: Boolean;
  LVisitInserted: Boolean;
  LClienteCount: Integer;
begin
  LogGeoWorker(Format('RegistrarGeolocalizacao entrada lat=%.7f lon=%.7f speed=%.2f',
    [ALatitude, ALongitude, AVelocidadeKmh], TFormatSettings.Invariant));
  if FBusy then
  begin
    LogGeoWorker('RegistrarGeolocalizacao ignorado: busy');
    Exit;
  end;
  FBusy := True;
  try
    try
      if Double.IsNan(ALatitude) or Double.IsNan(ALongitude) then
      begin
        LogGeoWorker('RegistrarGeolocalizacao ignorado: coordenada NaN');
        Exit;
      end;

      EnsureConnection;
      LCodRepresentante := GetCodRepresentante;
      if LCodRepresentante <= 0 then
      begin
        LogGeoWorker('RegistrarGeolocalizacao ignorado: cod_representante vazio');
        Exit;
      end;

      LDataHora := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
      LData := FormatDateTime('yyyy-mm-dd', Date);
      LNearestCliente := 0;
      LNearestDistance := MaxDouble;
      LVisitInserted := False;
      LClienteCount := 0;

      LShouldRegisterLocation := True;
      LLastLocationQuery := TFDQuery.Create(nil);
      try
        LLastLocationQuery.Connection := FConnection;
        LLastLocationQuery.SQL.Text :=
          'select latitude, longitude from representante_localizacao ' +
          'where cod_representante = :p0 order by id desc limit 1';
        LLastLocationQuery.ParamByName('p0').AsInteger := LCodRepresentante;
        LLastLocationQuery.Open;
        if not LLastLocationQuery.Eof then
        begin
          LLastLat := LLastLocationQuery.FieldByName('latitude').AsFloat;
          LLastLon := LLastLocationQuery.FieldByName('longitude').AsFloat;
          LShouldRegisterLocation :=
            DistanceMeters(ALatitude, ALongitude, LLastLat, LLastLon) >= CMinLocationChangeMeters;
          if not LShouldRegisterLocation then
            LogGeoWorker('RegistrarGeolocalizacao ignorado: posicao sem mudanca minima');
        end;
      finally
        LLastLocationQuery.Free;
      end;

      if LShouldRegisterLocation then
      begin
        ExecSQL(
          'insert into representante_localizacao (cod_representante, datahora, velocidade, latitude, longitude, enviado) ' +
          'values (:p0, :p1, :p2, :p3, :p4, ''N'')',
          [LCodRepresentante, LDataHora, AVelocidadeKmh, ALatitude, ALongitude]);
        LogGeoWorker('representante_localizacao inserido rep=' + LCodRepresentante.ToString + ' datahora=' + LDataHora);
      end;

      if AVelocidadeKmh < 1 then
      begin
        LClienteQuery := TFDQuery.Create(nil);
        try
          LClienteQuery.Connection := FConnection;
          LClienteQuery.SQL.Text :=
            'select cod_cliente, latitude, longitude from cliente ' +
            'where latitude is not null and longitude is not null';
          try
            LClienteQuery.Open;
          except
            on E: Exception do
            begin
              LogGeoWorker('cliente proximidade erro ao abrir consulta: ' + E.ClassName + ' - ' + E.Message);
              LClienteQuery.Close;
            end;
          end;

          while LClienteQuery.Active and (not LClienteQuery.Eof) do
          begin
            Inc(LClienteCount);
            LCodCliente := LClienteQuery.FieldByName('cod_cliente').AsInteger;
            LClienteLat := LClienteQuery.FieldByName('latitude').AsFloat;
            LClienteLon := LClienteQuery.FieldByName('longitude').AsFloat;
            LDistance := DistanceMeters(ALatitude, ALongitude, LClienteLat, LClienteLon);
            if LDistance < LNearestDistance then
            begin
              LNearestDistance := LDistance;
              LNearestCliente := LCodCliente;
            end;
            LClienteQuery.Next;
          end;
        finally
          LClienteQuery.Free;
        end;

        if (LNearestCliente > 0) and (LNearestDistance <= CVisitRadiusMeters) then
        begin
          LRecentVisits := GetScalarInt64(
            'select count(*) from cliente_visitas ' +
            'where cod_cliente = :p0 and datetime(datahora) >= datetime(:p1, ''-' +
            FormatFloat('0', CVisitMinMinutes) + ' minutes'')',
            [LNearestCliente, LDataHora]);
          if LRecentVisits = 0 then
          begin
            ExecSQL(
              'insert or ignore into cliente_visitas ' +
              '(cod_cliente, data, vendeu, enviado, valor_pedido, datahora, cod_representante, status_visita) ' +
              'values (:p0, :p1, ''N'', ''N'', 0, :p2, :p3, ''PROXIMIDADE'')',
              [LNearestCliente, LData, LDataHora, LCodRepresentante]);
            LVisitInserted := True;
            LogGeoWorker('cliente_visitas inserido cliente=' + LNearestCliente.ToString +
              ' distancia=' + FormatFloat('0.00', LNearestDistance, TFormatSettings.Invariant));
          end
          else
            LogGeoWorker('cliente_visitas ignorado: visita recente cliente=' + LNearestCliente.ToString);
        end
        else if LNearestCliente > 0 then
          LogGeoWorker('cliente_visitas nao inserido: cliente mais proximo=' + LNearestCliente.ToString +
            ' distancia=' + FormatFloat('0.00', LNearestDistance, TFormatSettings.Invariant) +
            ' clientes_com_coord=' + LClienteCount.ToString)
        else
          LogGeoWorker('cliente_visitas nao inserido: nenhum cliente com latitude/longitude');
      end
      else
        LogGeoWorker('cliente_visitas nao verificado: velocidade=' +
          FormatFloat('0.00', AVelocidadeKmh, TFormatSettings.Invariant));

      if LShouldRegisterLocation or LVisitInserted then
        LogGeoWorker('pendentes GPS/visitas mantidos no SQLite para sincronizacao');
    except
      on E: Exception do
        LogGeoWorker('RegistrarGeolocalizacao erro: ' + E.ClassName + ' - ' + E.Message);
    end;
  finally
    FBusy := False;
  end;
end;

end.

