unit ServiceUnit;

interface

uses
  System.Android.Service, System.Classes, System.Notification, System.Sensors,
  System.Sensors.Components, Androidapi.JNI.App,
  Androidapi.JNI.GraphicsContentViewText, Androidapi.JNI.Os;

type
  TLocationUpdated = procedure(const NewLocation: TLocationCoord2D; ASpeedKmh: Double) of object;

  TLocationTrackingModule = class(TAndroidService)
    LocationSensor: TLocationSensor;
    NotificationCenter: TNotificationCenter;
    procedure AndroidServiceCreate(Sender: TObject);
    function AndroidServiceStartCommand(const Sender: TObject; const Intent: JIntent; Flags, StartId: Integer): Integer;
    function AndroidServiceBind(const Sender: TObject; const AnIntent: JIntent): JIBinder;
    procedure AndroidServiceRebind(const Sender: TObject; const AnIntent: JIntent);
    function AndroidServiceUnBind(const Sender: TObject; const AnIntent: JIntent): Boolean;
    procedure AndroidServiceTaskRemoved(const Sender: TObject; const ARootIntent: JIntent);
    procedure LocationSensorLocationChanged(Sender: TObject; const OldLocation, NewLocation: TLocationCoord2D);
  private const
    NotificationId = 1001;
    NotificationChannelId = 'channel_id_foreground_location_tracking';
  private
    FIsRunningInForeground: Boolean;
    FNotificationManager: JNotificationManager;
    FLocation: TLocationCoord2D;
    FLocationUpdated: TLocationUpdated;
    FLastLocationHandledAt: TDateTime;
    FLastNotificationAt: TDateTime;
    FStopMonitorStarted: Boolean;
    FGeoWorkerBusy: Boolean;
    FPendingLocation: Boolean;
    FPendingLatitude: Double;
    FPendingLongitude: Double;
    FPendingSpeedKmh: Double;
    FPendingAccuracy: Double;
    FPendingSenderStarted: Boolean;
    FPendingSenderBusy: Boolean;
    FStopping: Boolean;
    FForegroundOnlyMode: Boolean;
    function GetIntent(const ClassName: string): JIntent;
    function GetNotification: JNotification;
    function GetCodRepresentanteLite(ADb: JSQLiteDatabase): Integer;
    function GetConfigValueLite(ADb: JSQLiteDatabase; const AKey: string): string;
    function GetApiBaseUrlLite(ADb: JSQLiteDatabase): string;
    function OpenDatabaseLite(const ADbPath: string): JSQLiteDatabase;
    function IsAppSyncRunning: Boolean;
    procedure ActivateLocationSensor;
    procedure QueueActivateLocationSensor;
    procedure QueueRegisterLocation(ALatitude, ALongitude, AVelocidadeKmh, AAccuracy: Double);
    procedure RegisterLocationLite(ALatitude, ALongitude, AVelocidadeKmh, AAccuracy: Double);
    procedure EnsureGeoTablesLite(ADb: JSQLiteDatabase);
    procedure StartPendingSender;
    procedure QueueSendPendingLite;
    procedure SendPendingLite;
    procedure PostJsonLite(const ABaseUrl, AEndpoint, AJson: string);
    procedure StartStopMonitor;
    procedure StartForegroundOnly(const AKeepAliveOnly: Boolean);
    procedure StartForegroundLocation;
    procedure EnsureForegroundTracking;
    procedure DisableLocationTracking;
    procedure StopLocationBySchedule;
  public const
    ActivityClassName = 'com.embarcadero.firemonkey.FMXNativeActivity';
    ServiceClassName = 'com.embarcadero.services.ForegroundLocationService';
    ActionStopLocationTracking = 'com.embarcadero.intent.action.STOP_LOCATION_TRACKING';
    ActionDisableLocationTracking = 'com.embarcadero.intent.action.DISABLE_LOCATION_TRACKING';
    ActionStartForegroundOnly = 'com.embarcadero.intent.action.START_FOREGROUND_ONLY';
  public
    property LocationUpdated: TLocationUpdated read FLocationUpdated write FLocationUpdated;
    procedure StartLocationTracking;
    procedure StopLocationTracking;
  end;

var
  LocationModule: TLocationTrackingModule;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

uses
  System.SysUtils, System.DateUtils, System.Math, Androidapi.Helpers, Androidapi.JNI.JavaTypes,
  Androidapi.JNI.Support, Androidapi.JNI.Java.Net, Androidapi.JNIBridge, Androidapi.Log, System.IOUtils;

procedure LogGPS(const AText: string);
var
  LText: UTF8String;
begin
  LText := UTF8String(AText);
  __android_log_write(android_LogPriority.ANDROID_LOG_INFO, 'WorbyRepresGPS', MarshaledAString(LText));
end;

function CanRunLocationServiceNow: Boolean;
var
  LBrasiliaNow: TDateTime;
  LTime: TTime;
begin
  try
    LBrasiliaNow := IncHour(TTimeZone.Local.ToUniversalTime(Now), -3);
  except
    LBrasiliaNow := Now;
  end;

  LTime := TimeOf(LBrasiliaNow);
  Result := (LTime >= EncodeTime(7, 30, 0, 0)) and (LTime < EncodeTime(18, 0, 0, 0));
end;

procedure TLocationTrackingModule.AndroidServiceCreate(Sender: TObject);
var
  LChannel: JNotificationChannel;
begin
  LogGPS('AndroidServiceCreate begin');
  try
    FNotificationManager := TJNotificationManager.Wrap(
      TAndroidHelper.Context.getSystemService(TJContext.JavaClass.NOTIFICATION_SERVICE));
    if (TJBuild_VERSION.JavaClass.SDK_INT >= 26) and Assigned(FNotificationManager) then
    begin
      LChannel := TJNotificationChannel.JavaClass.init(
        StringToJString(NotificationChannelId),
        StrToJCharSequence('WorbyRepres localizacao'),
        TJNotificationManager.JavaClass.IMPORTANCE_DEFAULT);
      FNotificationManager.createNotificationChannel(LChannel);
    end;
    LogGPS('Notification manager/channel ok');
  except
    on E: Exception do
      LogGPS('Notification manager/channel error: ' + E.ClassName + ' - ' + E.Message);
  end;
  if not Assigned(FNotificationManager) then
    FNotificationManager := nil;
  FLocation := TLocationCoord2D.Create(Double.NaN, Double.NaN);
  FLastLocationHandledAt := 0;
  FLastNotificationAt := 0;
  FStopMonitorStarted := False;
  FGeoWorkerBusy := False;
  FPendingLocation := False;
  FPendingLatitude := 0;
  FPendingLongitude := 0;
  FPendingSpeedKmh := 0;
  FPendingSenderStarted := False;
  FPendingSenderBusy := False;
  FStopping := False;
  FForegroundOnlyMode := False;
  try
    LocationSensor.Accuracy := 10;
    LocationSensor.Distance := 0;
    if Assigned(LocationSensor.Sensor) then
      LocationSensor.Sensor.LocationChange := TLocationChangeType.lctSmall;
  except
    on E: Exception do
      LogGPS('Configuracao de alta precisao indisponivel: ' + E.Message);
  end;
  OnTaskRemoved := AndroidServiceTaskRemoved;
  LogGPS('AndroidServiceCreate end');
end;

function TLocationTrackingModule.AndroidServiceStartCommand(const Sender: TObject; const Intent: JIntent; Flags, StartId: Integer): Integer;
begin
  LogGPS('AndroidServiceStartCommand begin');
  Result := TJService.JavaClass.START_STICKY;

  if Assigned(Intent) and (JStringToString(Intent.getAction) = ActionStopLocationTracking) then
  begin
    LogGPS('AndroidServiceStartCommand stop action');
    StopLocationTracking;
    Result := TJService.JavaClass.START_NOT_STICKY;
    Exit;
  end
  else if Assigned(Intent) and (JStringToString(Intent.getAction) = ActionDisableLocationTracking) then
  begin
    LogGPS('AndroidServiceStartCommand disable action');
    DisableLocationTracking;
    Result := TJService.JavaClass.START_NOT_STICKY;
    Exit;
  end
  else if Assigned(Intent) and (JStringToString(Intent.getAction) = ActionStartForegroundOnly) then
  begin
    LogGPS('AndroidServiceStartCommand foreground only action');
    FStopping := False;
    StartForegroundOnly(True);
    Result := TJService.JavaClass.START_STICKY;
  end
  else if CanRunLocationServiceNow then
  begin
    FStopping := False;
    EnsureForegroundTracking;
    Result := TJService.JavaClass.START_STICKY;
  end
  else
  begin
    LogGPS('AndroidServiceStartCommand bloqueado por horario');
    StopLocationTracking;
    Result := TJService.JavaClass.START_NOT_STICKY;
  end;

  LogGPS('AndroidServiceStartCommand end');
end;

function TLocationTrackingModule.AndroidServiceBind(const Sender: TObject; const AnIntent: JIntent): JIBinder;
begin
  LogGPS('AndroidServiceBind begin');
  Result := GetBinder;
  LogGPS('AndroidServiceBind end');
end;

procedure TLocationTrackingModule.AndroidServiceRebind(const Sender: TObject; const AnIntent: JIntent);
begin
  LogGPS('AndroidServiceRebind begin');
  LogGPS('AndroidServiceRebind end');
end;

function TLocationTrackingModule.AndroidServiceUnBind(const Sender: TObject; const AnIntent: JIntent): Boolean;
begin
  LogGPS('AndroidServiceUnBind begin');
  if FStopping then
  begin
    LogGPS('AndroidServiceUnBind ignorado: parada solicitada');
  end
  else if CanRunLocationServiceNow then
  begin
    EnsureForegroundTracking;
  end
  else
  begin
    LogGPS('AndroidServiceUnBind bloqueado por horario');
    StopLocationTracking;
  end;
  Result := True;
  LogGPS('AndroidServiceUnBind end');
end;

procedure TLocationTrackingModule.AndroidServiceTaskRemoved(const Sender: TObject; const ARootIntent: JIntent);
begin
  LogGPS('AndroidServiceTaskRemoved begin');
  if CanRunLocationServiceNow and (not FStopping) then
  begin
    FStopping := False;
    EnsureForegroundTracking;
  end
  else
  begin
    LogGPS('AndroidServiceTaskRemoved bloqueado por horario/parada');
    StopLocationTracking;
  end;
  LogGPS('AndroidServiceTaskRemoved end');
end;

function TLocationTrackingModule.GetIntent(const ClassName: string): JIntent;
begin
  Result := TJIntent.JavaClass.init;
  Result.setClassName(TAndroidHelper.Context.getPackageName, TAndroidHelper.StringToJString(ClassName));
end;

function TLocationTrackingModule.GetNotification: JNotification;

  function GetNotificationIconId: Integer;
  begin
    Result := TAndroidHelper.Context.getResources.getIdentifier(
      StringToJString('ic_notification'), StringToJString('drawable'), TAndroidHelper.Context.getPackageName);
    if Result = 0 then
      Result := TAndroidHelper.Context.getApplicationInfo.icon;
  end;

var
  LBuilder: JNotification_Builder;
  NotificationTitle: string;
  NotificationContent: string;
begin
  if Double.IsNan(FLocation.Latitude) or Double.IsNan(FLocation.Longitude) then
  begin
    if FForegroundOnlyMode then
      NotificationTitle := 'WorbyRepres ativo em segundo plano'
    else
      NotificationTitle := 'WorbyRepres rastreando localizacao';
    NotificationContent := '';
  end
  else
  begin
    NotificationTitle := 'WorbyRepres localizacao ativa';
    NotificationContent := Format('(%.7f, %.7f)',
      [FLocation.Latitude, FLocation.Longitude], TFormatSettings.Invariant);
  end;

  if TJBuild_VERSION.JavaClass.SDK_INT >= 26 then
    LBuilder := TJNotification_Builder.JavaClass.init(
      TAndroidHelper.Context, StringToJString(NotificationChannelId))
  else
    LBuilder := TJNotification_Builder.JavaClass.init(TAndroidHelper.Context);

  Result := LBuilder
    .setSmallIcon(GetNotificationIconId)
    .setContentTitle(StrToJCharSequence(NotificationTitle))
    .setContentText(StrToJCharSequence(NotificationContent))
    .setOngoing(True)
    .build;
end;

procedure TLocationTrackingModule.LocationSensorLocationChanged(Sender: TObject; const OldLocation, NewLocation: TLocationCoord2D);
var
  LSpeedKmh: Double;
  LAccuracy: Double;
begin
  if FStopping or not Assigned(LocationSensor.Sensor) then Exit;
  LAccuracy := LocationSensor.Sensor.ErrorRadius;
  if IsNan(LAccuracy) or IsInfinite(LAccuracy) or (LAccuracy <= 0) or
     (LAccuracy > 20) then
  begin
    LogGPS('LocationChanged descartado: precisao insuficiente metros=' + FloatToStr(LAccuracy));
    Exit;
  end;
  if IsNan(NewLocation.Latitude) or IsNan(NewLocation.Longitude) or
     (Abs(NewLocation.Latitude) > 90) or (Abs(NewLocation.Longitude) > 180) or
     ((NewLocation.Latitude = 0) and (NewLocation.Longitude = 0)) then Exit;
  if not CanRunLocationServiceNow then
  begin
    LogGPS('LocationChanged fora do horario');
    TThread.Queue(nil,
      procedure
      begin
        StopLocationBySchedule;
      end);
    Exit;
  end;

  FLocation := NewLocation;
  LSpeedKmh := 0;
  try
    if Assigned(LocationSensor.Sensor) then
      LSpeedKmh := LocationSensor.Sensor.Speed * 3.6;
    if Double.IsNan(LSpeedKmh) or (LSpeedKmh < 0) then
      LSpeedKmh := 0;
  except
    LSpeedKmh := 0;
  end;

  QueueRegisterLocation(NewLocation.Latitude, NewLocation.Longitude, LSpeedKmh, LAccuracy);
end;

procedure TLocationTrackingModule.StartLocationTracking;
begin
  LogGPS('StartLocationTracking');
  if not CanRunLocationServiceNow then
  begin
    LogGPS('StartLocationTracking fora do horario');
    StopLocationTracking;
    Exit;
  end;
  EnsureForegroundTracking;
end;

procedure TLocationTrackingModule.DisableLocationTracking;
begin
  FStopping := True;
  FForegroundOnlyMode := True;
  LogGPS('DisableLocationTracking');
  FStopMonitorStarted := False;
  FPendingSenderStarted := False;
  try
    LocationSensor.Active := False;
  except
    on E: Exception do
      LogGPS('LocationSensor disable error: ' + E.ClassName + ' - ' + E.Message);
  end;
  try
    if FIsRunningInForeground then
      JavaService.stopForeground(True);
    FIsRunningInForeground := False;
  except
    on E: Exception do
      LogGPS('disable stopForeground error: ' + E.ClassName + ' - ' + E.Message);
  end;
end;
procedure TLocationTrackingModule.StopLocationTracking;
begin
  FStopping := True;
  LogGPS('StopLocationTracking');
  FStopMonitorStarted := False;
  FPendingSenderStarted := False;
  try
    LocationSensor.Active := False;
  except
    on E: Exception do
      LogGPS('LocationSensor stop error: ' + E.ClassName + ' - ' + E.Message);
  end;
  try
    if FIsRunningInForeground then
      JavaService.stopForeground(True);
    FIsRunningInForeground := False;
  except
    on E: Exception do
      LogGPS('stopForeground error: ' + E.ClassName + ' - ' + E.Message);
  end;
  try
    JavaService.stopSelf;
  except
    on E: Exception do
      LogGPS('stopSelf error: ' + E.ClassName + ' - ' + E.Message);
  end;
end;

procedure TLocationTrackingModule.StartStopMonitor;
var
  LThread: TThread;
begin
  if FStopMonitorStarted then
    Exit;
  FStopMonitorStarted := True;

  LThread := TThread.CreateAnonymousThread(
    procedure
    begin
      while CanRunLocationServiceNow do
        TThread.Sleep(60000);

      TThread.Queue(nil, StopLocationBySchedule);
    end);
  LThread.FreeOnTerminate := True;
  LThread.Start;
end;

procedure TLocationTrackingModule.ActivateLocationSensor;
begin
  try
    if LocationSensor.Active then
    begin
      LogGPS('LocationSensor active ignorado: ja ativo');
      Exit;
    end;
    LogGPS('LocationSensor active call');
    LocationSensor.Active := True;
    LogGPS('LocationSensor active ok');
  except
    on E: Exception do
      LogGPS('LocationSensor active error: ' + E.ClassName + ' - ' + E.Message);
  end;
end;

procedure TLocationTrackingModule.QueueActivateLocationSensor;
begin
  LogGPS('QueueActivateLocationSensor direto');
  ActivateLocationSensor;
end;

procedure TLocationTrackingModule.QueueRegisterLocation(ALatitude, ALongitude, AVelocidadeKmh, AAccuracy: Double);
var
  LLatitude: Double;
  LLongitude: Double;
  LVelocidadeKmh: Double;
  LThread: TThread;
begin
  LLatitude := ALatitude;
  LLongitude := ALongitude;
  LVelocidadeKmh := AVelocidadeKmh;

  if FGeoWorkerBusy then
  begin
    FPendingLatitude := LLatitude;
    FPendingLongitude := LLongitude;
    FPendingSpeedKmh := LVelocidadeKmh;
    FPendingAccuracy := AAccuracy;
    FPendingLocation := True;
    Exit;
  end;

  FGeoWorkerBusy := True;
  LThread := TThread.CreateAnonymousThread(
    procedure
    begin
      try
        try
          RegisterLocationLite(LLatitude, LLongitude, LVelocidadeKmh, AAccuracy);
        except
          on E: Exception do
            LogGPS('QueueRegisterLocation erro: ' + E.ClassName + ' - ' + E.Message);
        end;
      finally
        FGeoWorkerBusy := False;
        if FPendingLocation then
        begin
          FPendingLocation := False;
          QueueRegisterLocation(FPendingLatitude, FPendingLongitude, FPendingSpeedKmh, FPendingAccuracy);
        end;
      end;
    end);
  LThread.FreeOnTerminate := True;
  LThread.Start;
end;

function TLocationTrackingModule.GetCodRepresentanteLite(ADb: JSQLiteDatabase): Integer;
begin
  Result := StrToIntDef(Trim(GetConfigValueLite(ADb, 'cod_representante')), 0);
end;

function TLocationTrackingModule.GetConfigValueLite(ADb: JSQLiteDatabase; const AKey: string): string;
var
  LCursor: JCursor;
begin
  Result := '';
  LCursor := nil;
  try
    LCursor := ADb.rawQuery(StringToJString(
      'select value from app_config where key = ''' + AKey + ''' limit 1'), nil);
    if Assigned(LCursor) and LCursor.moveToFirst then
      Result := Trim(JStringToString(LCursor.getString(0)));
  except
    on E: Exception do
      LogGPS('GetConfigValueLite erro: ' + E.ClassName + ' - ' + E.Message);
  end;
  try
    if Assigned(LCursor) then
      LCursor.close;
  except
  end;
end;

function JsonEscapeLite(const AValue: string): string;
begin
  Result := AValue;
  Result := Result.Replace('\', '\\');
  Result := Result.Replace('"', '"');
  Result := Result.Replace(#13, '\r');
  Result := Result.Replace(#10, '\n');
end;

function TLocationTrackingModule.OpenDatabaseLite(const ADbPath: string): JSQLiteDatabase;
var
  I: Integer;
begin
  Result := nil;
  for I := 1 to 6 do
  begin
    try
      Result := TJSQLiteDatabase.JavaClass.openOrCreateDatabase(StringToJString(ADbPath), nil);
      Exit;
    except
      on E: Exception do
      begin
        if I = 6 then
          raise;
        LogGPS('SQLite ocupado, tentando novamente ' + I.ToString + ': ' + E.Message);
        TThread.Sleep(500);
      end;
    end;
  end;
end;

function TLocationTrackingModule.IsAppSyncRunning: Boolean;
begin
  Result := False;
  try
    Result := TAndroidHelper.Context
      .getSharedPreferences(StringToJString('worbyrepres_runtime'), TJContext.JavaClass.MODE_PRIVATE)
      .getBoolean(StringToJString('sync_running'), False);
  except
    Result := False;
  end;
end;

function TLocationTrackingModule.GetApiBaseUrlLite(ADb: JSQLiteDatabase): string;
var
  LCursor: JCursor;
begin
  Result := Trim(GetConfigValueLite(ADb, 'api_base_url'));
  if Result = '' then
  begin
    LCursor := nil;
    try
      LCursor := ADb.rawQuery(StringToJString('select base_url from api_session where id = 1'), nil);
      if Assigned(LCursor) and LCursor.moveToFirst then
        Result := Trim(JStringToString(LCursor.getString(0)));
    except
      on E: Exception do
        LogGPS('GetApiBaseUrlLite erro: ' + E.ClassName + ' - ' + E.Message);
    end;
    try
      if Assigned(LCursor) then
        LCursor.close;
    except
    end;
  end;

  if SameText(Result, 'PLASFAN') then
    Result := 'http://plasfan.ddns.com.br:9004';

  while (Result <> '') and (Result[Length(Result)] = '/') do
    Delete(Result, Length(Result), 1);
end;

procedure TLocationTrackingModule.EnsureGeoTablesLite(ADb: JSQLiteDatabase);
begin
  ADb.execSQL(StringToJString(
    'create table if not exists app_config (' +
    'key text primary key, value text, updated_at text default current_timestamp)'));
  ADb.execSQL(StringToJString(
    'create table if not exists representante_localizacao (' +
    'id integer primary key autoincrement, cod_representante integer not null, ' +
    'datahora text not null, velocidade real, latitude real not null, longitude real not null, ' +
    'enviado text default ''N'', sent_at text, last_error text)'));
  ADb.execSQL(StringToJString(
    'create table if not exists representante_km_diario (' +
    'cod_representante integer not null, data text not null, km_rodado real not null default 0, ' +
    'qtd_pontos integer not null default 0, qtd_segmentos integer not null default 0, ' +
    'inicio text, fim text, primary key(cod_representante, data))'));
  ADb.execSQL(StringToJString(
    'create table if not exists cliente_visitas (' +
    'cod_cliente integer not null, data text not null, vendeu text, enviado text default ''N'', ' +
    'motivo_n_venda blob, valor_pedido real, datahora text not null, cod_representante integer, ' +
    'status_visita text, sent_at text, last_error text, primary key(cod_cliente, datahora))'));
end;

procedure TLocationTrackingModule.PostJsonLite(const ABaseUrl, AEndpoint, AJson: string);
var
  LUrlText: string;
  LUrl: JURL;
  LConnection: JHttpURLConnection;
  LBytes: TBytes;
  LJavaBytes: TJavaArray<Byte>;
  LStream: JOutputStream;
  I: Integer;
  LResponseCode: Integer;
begin
  if ABaseUrl = '' then
    raise Exception.Create('API base vazia');

  LUrlText := ABaseUrl + '/' + AEndpoint;
  LUrl := TJURL.JavaClass.init(StringToJString(LUrlText));
  LConnection := TJHttpURLConnection.Wrap((LUrl.openConnection as ILocalObject).GetObjectID);
  try
    LConnection.setConnectTimeout(5000);
    LConnection.setReadTimeout(10000);
    LConnection.setRequestMethod(StringToJString('POST'));
    LConnection.setDoOutput(True);
    LConnection.setRequestProperty(StringToJString('Content-Type'), StringToJString('application/json; charset=utf-8'));
    LConnection.setRequestProperty(StringToJString('Accept'), StringToJString('application/json'));

    LBytes := TEncoding.UTF8.GetBytes(AJson);
    LJavaBytes := TJavaArray<Byte>.Create(Length(LBytes));
    try
      for I := 0 to High(LBytes) do
        LJavaBytes.Items[I] := LBytes[I];

      LStream := LConnection.getOutputStream;
      try
        LStream.write(LJavaBytes);
        LStream.flush;
      finally
        LStream.close;
      end;
    finally
      LJavaBytes.Free;
    end;

    LResponseCode := LConnection.getResponseCode;
    if (LResponseCode < 200) or (LResponseCode >= 300) then
      raise Exception.Create('HTTP ' + LResponseCode.ToString);
  finally
    if Assigned(LConnection) then
      LConnection.disconnect;
  end;
end;

procedure TLocationTrackingModule.StartPendingSender;
var
  LThread: TThread;
begin
  if FPendingSenderStarted then
    Exit;
  FPendingSenderStarted := True;

  LThread := TThread.CreateAnonymousThread(
    procedure
    begin
      while FPendingSenderStarted and CanRunLocationServiceNow do
      begin
        if not IsAppSyncRunning then
          QueueSendPendingLite
        else
          LogGPS('StartPendingSender pausado: sync em andamento');
        TThread.Sleep(60000);
      end;
      FPendingSenderStarted := False;
    end);
  LThread.FreeOnTerminate := True;
  LThread.Start;
end;

procedure TLocationTrackingModule.QueueSendPendingLite;
var
  LThread: TThread;
begin
  if IsAppSyncRunning then
  begin
    LogGPS('QueueSendPendingLite ignorado: sync em andamento');
    Exit;
  end;

  if FPendingSenderBusy then
    Exit;

  FPendingSenderBusy := True;
  LThread := TThread.CreateAnonymousThread(
    procedure
    begin
      try
        try
          SendPendingLite;
        except
          on E: Exception do
            LogGPS('SendPendingLite erro: ' + E.ClassName + ' - ' + E.Message);
        end;
      finally
        FPendingSenderBusy := False;
      end;
    end);
  LThread.FreeOnTerminate := True;
  LThread.Start;
end;

procedure TLocationTrackingModule.SendPendingLite;
var
  LDbPath: string;
  LDir: string;
  LDb: JSQLiteDatabase;
  LCursor: JCursor;
  LBaseUrl: string;
  LJson: string;
  LId: Int64;
  LCodCliente: Integer;
  LDataHora: string;
  LMotivo: string;
  LStatus: string;
begin
  if IsAppSyncRunning then
  begin
    LogGPS('SendPendingLite ignorado: sync em andamento');
    Exit;
  end;

  LDir := TPath.Combine(TPath.GetDocumentsPath, 'WorbyRep');
  LDbPath := TPath.Combine(LDir, 'db.sqllite');
  if not TFile.Exists(LDbPath) then
    Exit;

  LDb := OpenDatabaseLite(LDbPath);
  try
    EnsureGeoTablesLite(LDb);
    LBaseUrl := GetApiBaseUrlLite(LDb);
    if LBaseUrl = '' then
    begin
      LogGPS('SendPendingLite ignorado: API vazia');
      Exit;
    end;

    LogGPS('SendPendingLite begin');
    LCursor := nil;
    try
      LCursor := LDb.rawQuery(StringToJString(
        'select id, cod_representante, datahora, velocidade, latitude, longitude ' +
        'from representante_localizacao where coalesce(enviado, ''N'') <> ''S'' order by id limit 50'), nil);
      while Assigned(LCursor) and LCursor.moveToNext do
      begin
        LId := LCursor.getLong(0);
        LJson := Format(
          '{"id":%d,"cod_representante":%d,"datahora":"%s","velocidade":%.6f,"latitude":%.8f,"longitude":%.8f}',
          [LId, LCursor.getInt(1), JsonEscapeLite(JStringToString(LCursor.getString(2))),
           LCursor.getDouble(3), LCursor.getDouble(4), LCursor.getDouble(5)], TFormatSettings.Invariant);
        try
          PostJsonLite(LBaseUrl, 'api/geolocalizacao', LJson);
          LDb.execSQL(StringToJString(Format(
            'update representante_localizacao set enviado = ''S'', sent_at = datetime(''now''), last_error = null where id = %d',
            [LId])));
        except
          on E: Exception do
            LDb.execSQL(StringToJString(Format(
              'update representante_localizacao set last_error = ''%s'' where id = %d',
              [JsonEscapeLite(E.Message).Replace('''', ''''''), LId])));
        end;
      end;
    finally
      if Assigned(LCursor) then
        LCursor.close;
    end;

    LCursor := nil;
    try
      LCursor := LDb.rawQuery(StringToJString(
        'select cod_cliente, data, vendeu, coalesce(motivo_n_venda, ''''), valor_pedido, datahora, cod_representante, coalesce(status_visita, '''') ' +
        'from cliente_visitas where coalesce(enviado, ''N'') <> ''S'' order by datahora limit 50'), nil);
      while Assigned(LCursor) and LCursor.moveToNext do
      begin
        LCodCliente := LCursor.getInt(0);
        LMotivo := JStringToString(LCursor.getString(3));
        LDataHora := JStringToString(LCursor.getString(5));
        LStatus := Trim(JStringToString(LCursor.getString(7)));
        if LStatus = '' then
        begin
          if SameText(Trim(JStringToString(LCursor.getString(2))), 'S') then
            LStatus := 'Venda'
          else
            LStatus := 'PROXIMIDADE';
        end;
        LJson := Format(
          '{"cod_cliente":%d,"data":"%s","vendeu":"%s","motivo_n_venda":"%s","valor_pedido":%.2f,"status_visita":"%s","datahora":"%s","cod_representante":%d}',
          [LCodCliente, JsonEscapeLite(JStringToString(LCursor.getString(1))),
           JsonEscapeLite(JStringToString(LCursor.getString(2))), JsonEscapeLite(LMotivo), LCursor.getDouble(4),
           JsonEscapeLite(LStatus), JsonEscapeLite(LDataHora), LCursor.getInt(6)], TFormatSettings.Invariant);
        try
          PostJsonLite(LBaseUrl, 'api/cliente_visita', LJson);
          LDb.execSQL(StringToJString(Format(
            'update cliente_visitas set enviado = ''S'', sent_at = datetime(''now''), last_error = null where cod_cliente = %d and datahora = ''%s''',
            [LCodCliente, LDataHora.Replace('''', '''''')])));
        except
          on E: Exception do
            LDb.execSQL(StringToJString(Format(
              'update cliente_visitas set last_error = ''%s'' where cod_cliente = %d and datahora = ''%s''',
              [JsonEscapeLite(E.Message).Replace('''', ''''''), LCodCliente, LDataHora.Replace('''', '''''')])));
        end;
      end;
    finally
      if Assigned(LCursor) then
        LCursor.close;
    end;
    LogGPS('SendPendingLite end');
  finally
    if Assigned(LDb) and LDb.isOpen then
      LDb.close;
  end;
end;

procedure TLocationTrackingModule.RegisterLocationLite(ALatitude, ALongitude, AVelocidadeKmh, AAccuracy: Double);
const
  CEarthRadiusMeters = 6371000.0;
  CVisitRadiusMeters = 100.0;
  CVisitMinMinutes = 30.0;
var
  LDbPath: string;
  LDir: string;
  LDb: JSQLiteDatabase;
  LCodRepresentante: Integer;
  LDataHora: string;
  LData: string;
  LSql: string;
  LFormat: TFormatSettings;
  LCursor: JCursor;
  LCodCliente: Integer;
  LClienteLat: Double;
  LClienteLon: Double;
  LDistance: Double;
  LNearestCliente: Integer;
  LNearestDistance: Double;
  LRecentVisits: Integer;
  LClientesComCoord: Integer;
  LFuncionario: string;
  LHasPreviousPoint: Boolean;
  LPreviousLatitude: Double;
  LPreviousLongitude: Double;
  LSegmentMeters: Double;
  LHasAccuracyColumn: Boolean;

  function DistanceMeters(ALat1, ALon1, ALat2, ALon2: Double): Double;
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

begin
  LDir := TPath.Combine(TPath.GetDocumentsPath, 'WorbyRep');
  if not TDirectory.Exists(LDir) then
    TDirectory.CreateDirectory(LDir);
  LDbPath := TPath.Combine(LDir, 'db.sqllite');

  LFormat := TFormatSettings.Invariant;
  LDataHora := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
  LData := FormatDateTime('yyyy-mm-dd', Date);
  LNearestCliente := 0;
  LNearestDistance := MaxDouble;
  LClientesComCoord := 0;
  LogGPS('RegisterLocationLite db=' + LDbPath);

  LDb := OpenDatabaseLite(LDbPath);
  try
    LDb.execSQL(StringToJString(
      'create table if not exists app_config (' +
      'key text primary key, value text, updated_at text default current_timestamp)'));
    LDb.execSQL(StringToJString(
      'create table if not exists representante_localizacao (' +
      'id integer primary key autoincrement, cod_representante integer not null, ' +
      'datahora text not null, velocidade real, latitude real not null, longitude real not null, ' +
      'enviado text default ''N'', sent_at text, last_error text)'));
    LHasAccuracyColumn := False;
    LCursor := LDb.rawQuery(StringToJString('pragma table_info(representante_localizacao)'), nil);
    try
      while LCursor.moveToNext do
        if SameText(JStringToString(LCursor.getString(1)), 'precisao_m') then
          LHasAccuracyColumn := True;
    finally
      LCursor.close;
      LCursor := nil;
    end;
    if not LHasAccuracyColumn then
      LDb.execSQL(StringToJString('alter table representante_localizacao add column precisao_m real'));
    LDb.execSQL(StringToJString(
      'create table if not exists representante_km_diario (' +
      'cod_representante integer not null, data text not null, km_rodado real not null default 0, ' +
      'qtd_pontos integer not null default 0, qtd_segmentos integer not null default 0, ' +
      'inicio text, fim text, primary key(cod_representante, data))'));
    LDb.execSQL(StringToJString(
      'create table if not exists cliente_visitas (' +
      'cod_cliente integer not null, data text not null, vendeu text, enviado text default ''N'', ' +
      'motivo_n_venda blob, valor_pedido real, datahora text not null, cod_representante integer, ' +
      'status_visita text, sent_at text, last_error text, primary key(cod_cliente, datahora))'));
    LCodRepresentante := GetCodRepresentanteLite(LDb);
    if LCodRepresentante <= 0 then
    begin
      LogGPS('RegisterLocationLite ignorado: cod_representante vazio');
      Exit;
    end;

    LFuncionario := '';
    LCursor := nil;
    try
      LCursor := LDb.rawQuery(StringToJString(Format(
        'select coalesce(funcionario, '''') from representante where id = %d or cod_tablet = %d limit 1',
        [LCodRepresentante, LCodRepresentante])), nil);
      if Assigned(LCursor) and LCursor.moveToFirst then
        LFuncionario := Trim(JStringToString(LCursor.getString(0)));
    except
      on E: Exception do
        LogGPS('RegisterLocationLite funcionario erro: ' + E.ClassName + ' - ' + E.Message);
    end;
    if Assigned(LCursor) then
    begin
      LCursor.close;
      LCursor := nil;
    end;

    if LFuncionario = '' then
    begin
      try
        LFuncionario := Trim(GetConfigValueLite(LDb, 'representante_funcionario'));
        LogGPS('RegisterLocationLite funcionario app_config=' + LFuncionario);
      except
        on E: Exception do
          LogGPS('RegisterLocationLite funcionario app_config erro: ' + E.ClassName + ' - ' + E.Message);
      end;
    end;

    if not (SameText(LFuncionario, '1') or SameText(LFuncionario, '4')) then
    begin
      LogGPS('RegisterLocationLite bloqueado por funcionario=' + LFuncionario + ' rep=' + LCodRepresentante.ToString);
      Exit;
    end;
    LHasPreviousPoint := False;
    LPreviousLatitude := 0;
    LPreviousLongitude := 0;
    LCursor := nil;
    try
      LCursor := LDb.rawQuery(StringToJString(Format(
        'select latitude, longitude from representante_localizacao where cod_representante = %d and date(datahora) = date(''now'', ''localtime'') order by id desc limit 1',
        [LCodRepresentante])), nil);
      if Assigned(LCursor) and LCursor.moveToFirst then
      begin
        LPreviousLatitude := LCursor.getDouble(0);
        LPreviousLongitude := LCursor.getDouble(1);
        LHasPreviousPoint := True;
      end;
    except
      on E: Exception do
        LogGPS('resumo km consulta anterior erro: ' + E.ClassName + ' - ' + E.Message);
    end;
    try
      if Assigned(LCursor) then
        LCursor.close;
    except
    end;

    LSql := Format(
      'insert into representante_localizacao ' +
      '(cod_representante, datahora, velocidade, latitude, longitude, precisao_m, enviado) ' +
      'values (%d, ''%s'', %.6f, %.8f, %.8f, %.3f, ''N'')',
      [LCodRepresentante, LDataHora, AVelocidadeKmh, ALatitude, ALongitude, AAccuracy], LFormat);
    LDb.execSQL(StringToJString(LSql));
    LSegmentMeters := 0;
    if LHasPreviousPoint then
      LSegmentMeters := DistanceMeters(LPreviousLatitude, LPreviousLongitude, ALatitude, ALongitude);
    LDb.execSQL(StringToJString(Format(
      'insert or ignore into representante_km_diario ' +
      '(cod_representante, data, km_rodado, qtd_pontos, qtd_segmentos, inicio, fim) ' +
      'values (%d, ''%s'', 0, 0, 0, ''%s'', ''%s'')',
      [LCodRepresentante, LData, LDataHora, LDataHora], LFormat)));
    LDb.execSQL(StringToJString(Format(
      'update representante_km_diario set qtd_pontos = qtd_pontos + 1, fim = ''%s'' ' +
      'where cod_representante = %d and data = ''%s''',
      [LDataHora, LCodRepresentante, LData], LFormat)));
    if (LSegmentMeters >= 5) and (LSegmentMeters <= 100000) and
       (AVelocidadeKmh <= 180) then
    begin
      LDb.execSQL(StringToJString(Format(
        'update representante_km_diario set km_rodado = km_rodado + %.6f, ' +
        'qtd_segmentos = qtd_segmentos + 1 where cod_representante = %d and data = ''%s''',
        [LSegmentMeters / 1000, LCodRepresentante, LData], LFormat)));
    end;
    LogGPS('representante_localizacao inserido lite rep=' + LCodRepresentante.ToString +
      ' datahora=' + LDataHora + ' segmento_m=' + FormatFloat('0.0', LSegmentMeters, LFormat));

    if AVelocidadeKmh < 1 then
    begin
      LCursor := nil;
      try
        LCursor := LDb.rawQuery(StringToJString(
          'select cod_cliente, latitude, longitude from cliente ' +
          'where latitude is not null and longitude is not null'), nil);
        while Assigned(LCursor) and LCursor.moveToNext do
        begin
          Inc(LClientesComCoord);
          LCodCliente := LCursor.getInt(0);
          LClienteLat := LCursor.getDouble(1);
          LClienteLon := LCursor.getDouble(2);
          LDistance := DistanceMeters(ALatitude, ALongitude, LClienteLat, LClienteLon);
          if LDistance < LNearestDistance then
          begin
            LNearestDistance := LDistance;
            LNearestCliente := LCodCliente;
          end;
        end;
      except
        on E: Exception do
          LogGPS('cliente_visitas lite consulta erro: ' + E.ClassName + ' - ' + E.Message);
      end;
      try
        if Assigned(LCursor) then
          LCursor.close;
      except
      end;

      if (LNearestCliente > 0) and (LNearestDistance <= CVisitRadiusMeters) then
      begin
        LRecentVisits := 0;
        LCursor := nil;
        try
          LSql := Format(
            'select count(*) from cliente_visitas ' +
            'where cod_cliente = %d and datetime(datahora) >= datetime(''%s'', ''-%.0f minutes'')',
            [LNearestCliente, LDataHora, CVisitMinMinutes], LFormat);
          LCursor := LDb.rawQuery(StringToJString(LSql), nil);
          if Assigned(LCursor) and LCursor.moveToFirst then
            LRecentVisits := LCursor.getInt(0);
        except
          on E: Exception do
            LogGPS('cliente_visitas lite recent erro: ' + E.ClassName + ' - ' + E.Message);
        end;
        try
          if Assigned(LCursor) then
            LCursor.close;
        except
        end;

        if LRecentVisits = 0 then
        begin
          LSql := Format(
            'insert or ignore into cliente_visitas ' +
            '(cod_cliente, data, vendeu, enviado, valor_pedido, datahora, cod_representante, status_visita) ' +
            'values (%d, ''%s'', ''N'', ''N'', 0, ''%s'', %d, ''PROXIMIDADE'')',
            [LNearestCliente, LData, LDataHora, LCodRepresentante], LFormat);
          LDb.execSQL(StringToJString(LSql));
          LogGPS('cliente_visitas inserido lite cliente=' + LNearestCliente.ToString +
            ' distancia=' + FormatFloat('0.00', LNearestDistance, LFormat));
        end
        else
          LogGPS('cliente_visitas lite ignorado: visita recente cliente=' + LNearestCliente.ToString);
      end
      else if LNearestCliente > 0 then
        LogGPS('cliente_visitas lite nao inserido cliente=' + LNearestCliente.ToString +
          ' distancia=' + FormatFloat('0.00', LNearestDistance, LFormat) +
          ' clientes_com_coord=' + LClientesComCoord.ToString)
      else
        LogGPS('cliente_visitas lite nao inserido: nenhum cliente com coordenada');
    end
    else
      LogGPS('cliente_visitas lite nao verificado velocidade=' +
        FormatFloat('0.00', AVelocidadeKmh, LFormat));
  finally
    if Assigned(LDb) and LDb.isOpen then
      LDb.close;
  end;
end;

procedure TLocationTrackingModule.StopLocationBySchedule;
begin
  LogGPS('StopLocationBySchedule');
  StopLocationTracking;
end;

procedure TLocationTrackingModule.StartForegroundOnly(const AKeepAliveOnly: Boolean);
begin
  FForegroundOnlyMode := AKeepAliveOnly;
  try
    LogGPS('StartForegroundOnly call');
    JavaService.startForeground(NotificationId, GetNotification);
    FIsRunningInForeground := True;
    LogGPS('StartForegroundOnly ok');
  except
    on E: Exception do
    begin
      FIsRunningInForeground := False;
      LogGPS('StartForegroundOnly error: ' + E.ClassName + ' - ' + E.Message);
    end;
  end;
end;

procedure TLocationTrackingModule.EnsureForegroundTracking;
begin
  LogGPS('EnsureForegroundTracking');
  if not CanRunLocationServiceNow then
  begin
    LogGPS('EnsureForegroundTracking fora do horario');
    StopLocationTracking;
    Exit;
  end;

  StartForegroundOnly(False);
  if not FIsRunningInForeground then
  begin
    LogGPS('Ativacao GPS cancelada: servico sem foreground autorizado');
    Exit;
  end;
  QueueActivateLocationSensor;
  StartStopMonitor;
end;

procedure TLocationTrackingModule.StartForegroundLocation;
begin
  LogGPS('StartForegroundLocation begin');
  if not CanRunLocationServiceNow then
  begin
    LogGPS('StartForegroundLocation fora do horario');
    StopLocationTracking;
    Exit;
  end;

  StartStopMonitor;

  try
    LogGPS('startForeground call');
    JavaService.startForeground(NotificationId, GetNotification);
    FIsRunningInForeground := True;
    LogGPS('startForeground ok');
  except
    on E: Exception do
    begin
      LogGPS('startForeground error: ' + E.ClassName + ' - ' + E.Message);
      FIsRunningInForeground := False;
    end;
  end;

  if FIsRunningInForeground then
    QueueActivateLocationSensor;

  try
    if FIsRunningInForeground and Assigned(FNotificationManager) and
       ((FLastNotificationAt = 0) or
        ((Now - FLastNotificationAt) >= EncodeTime(0, 0, 30, 0))) then
    begin
      FNotificationManager.notify(NotificationId, GetNotification);
      FLastNotificationAt := Now;
    end;
  except
    on E: Exception do
      LogGPS('Notification notify error: ' + E.ClassName + ' - ' + E.Message);
  end;

  LogGPS('StartForegroundLocation end foreground=' + BoolToStr(FIsRunningInForeground, True));
end;

end.
