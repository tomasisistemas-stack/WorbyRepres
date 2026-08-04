unit unFuncoes;

interface

uses
  System.SysUtils,
  System.IOUtils,
  FMX.Forms,
  System.Generics.Collections,
  FMX.Objects,
  System.Classes,
  System.NetEncoding,
  FMX.Graphics,
  System.Math,
  Soap.EncdDecd,
  FMX.DialogService,
  System.UITypes,
  System.Net.HttpClient,
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
  System.Types;

procedure killApp;
function ChecarConexao: Boolean;
function IsXiaomiDevice: Boolean;
function AndroidNavigationInset(const AIsLandscape: Boolean): Single;
function EncodeBase64(const texto: string): string;
function DecodeBase64(const texto: string): string;
function Base64FromBitmap(Bitmap: FMX.Graphics.TBitmap): string;
function BitmapFromBase64(const base64: string): FMX.Graphics.TBitmap;
procedure ReduzirBitmapParaMaximo(ABitmap: FMX.Graphics.TBitmap; const AMaxWidth, AMaxHeight: Integer);
function GerarNomeArq(extensao: string): string;
function AppVersionName: string;
procedure SairdoSistema;

var
  ApiBaseUrlOverride: string;

implementation

{$IFDEF ANDROID}
uses
  Posix.Unistd,
  IdURI,
  Androidapi.Helpers,
  Androidapi.JNI.JavaTypes,
  Androidapi.JNIBridge,
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.Net,
  Androidapi.JNI.Os,
  Androidapi.JNI.Util,
  Androidapi.IOUtils,
  Androidapi.Jni.App,
  FMX.Helpers.Android,
  FMX.Dialogs,
  FMX.Platform;
{$ENDIF}

procedure killApp;
{$IFDEF ANDROID}
var
  Intent: JIntent;
{$ENDIF}
begin
  {$IFDEF ANDROID}
  Intent := TJIntent.Create;
  try
    Intent := TAndroidHelper.Activity.getPackageManager.getLaunchIntentForPackage(StringToJString('com.embarcadero.mensorlab'));
    TAndroidHelper.Activity.finishAndRemoveTask;
  except
  end;
  {$ENDIF}
  {$IFDEF MSWINDOWS}
  Application.Terminate;
  {$ENDIF}
  {$IFDEF IOS}
  Halt(1);
  {$ENDIF}
end;

function IsXiaomiDevice: Boolean;
{$IFDEF ANDROID}
var
  LManufacturer: string;
  LBrand: string;
  LModel: string;
{$ENDIF}
begin
{$IFDEF ANDROID}
  LManufacturer := Trim(LowerCase(JStringToString(TJBuild.JavaClass.MANUFACTURER)));
  LBrand := Trim(LowerCase(JStringToString(TJBuild.JavaClass.BRAND)));
  LModel := Trim(LowerCase(JStringToString(TJBuild.JavaClass.MODEL)));
  Result := (Pos('xiaomi', LManufacturer) > 0) or
            (Pos('redmi', LManufacturer) > 0) or
            (Pos('poco', LManufacturer) > 0) or
            (Pos('xiaomi', LBrand) > 0) or
            (Pos('redmi', LBrand) > 0) or
            (Pos('poco', LBrand) > 0) or
            (Pos('redmi', LModel) > 0) or
            (Pos('poco', LModel) > 0);

{$ELSE}
  Result := False;
{$ENDIF}
end;


function AndroidNavigationInset(const AIsLandscape: Boolean): Single;
{$IFDEF ANDROID}
var
  LRes: JResources;
  LMetrics: JDisplayMetrics;
  LResourceName: JString;
  LResourceId: Integer;
  LDensity: Single;
{$ENDIF}
begin
  Result := 0;
{$IFDEF ANDROID}
  try
    LRes := TAndroidHelper.Context.getResources;
    if not Assigned(LRes) then
      Exit;

    if AIsLandscape then
      LResourceName := StringToJString('navigation_bar_width')
    else
      LResourceName := StringToJString('navigation_bar_height');

    LResourceId := LRes.getIdentifier(LResourceName, StringToJString('dimen'), StringToJString('android'));
    if LResourceId <= 0 then
      Exit;

    LMetrics := LRes.getDisplayMetrics;
    LDensity := 1;
    if Assigned(LMetrics) and (LMetrics.density > 0) then
      LDensity := LMetrics.density;

    Result := LRes.getDimensionPixelSize(LResourceId) / LDensity;
  except
    Result := 0;
  end;
{$ENDIF}
end;
procedure SairdoSistema;
begin
  TDialogService.MessageDialog('Confirmar a saida do sistema?', System.UITypes.TMsgDlgType.mtInformation, [System.UITypes.TMsgDlgBtn.mbYes, System.UITypes.TMsgDlgBtn.mbNo], System.UITypes.TMsgDlgBtn.mbNo, 0,
    procedure(const AResult: TModalResult)
    begin
      case AResult of
        mrYes:
        begin
          {$IFDEF MSWINDOWS}
            Application.Terminate;
          {$ELSE}
            killApp;
          {$ENDIF}
        end;
      end;
    end);
end;

function ChecarConexao: Boolean;
var
  LHttp: THTTPClient;
  LResponse: IHTTPResponse;
  LUrl: string;
  LText: string;
begin
  Result := False;
  LHttp := THTTPClient.Create;
  try
    LHttp.ConnectionTimeout := 5000;
    LHttp.ResponseTimeout := 5000;
    LUrl := Trim(ApiBaseUrlOverride);
    if LUrl = '' then
      LUrl := 'http://plasfan.ddns.com.br:9000';
    if LUrl.EndsWith('/') then
      LUrl := LUrl.Substring(0, LUrl.Length - 1);
    LUrl := LUrl + '/health';
    try
      LResponse := LHttp.Get(LUrl);
      LText := LResponse.ContentAsString(TEncoding.UTF8).Trim;
      Result := (LResponse.StatusCode >= 200) and (LResponse.StatusCode < 300) and SameText(LText, '{"status":"ok"}');
    except
      Result := False;
    end;
  finally
    LHttp.Free;
  end;
end;

function EncodeBase64(const texto: string): string;
var
  obj: TBase64Encoding;
begin
  obj := TBase64Encoding.Create;
  try
    Result := obj.Encode(texto);
  finally
    obj.Free;
  end;
end;

function DecodeBase64(const texto: string): string;
var
  obj: TBase64Encoding;
begin
  obj := TBase64Encoding.Create;
  try
    Result := obj.Decode(texto);
  finally
    obj.Free;
  end;
end;

function Base64FromBitmap(Bitmap: FMX.Graphics.TBitmap): string;
var
  Input: TBytesStream;
  Output: TStringStream;
begin
  Input := TBytesStream.Create;
  try
    Bitmap.SaveToStream(Input);
    Input.Position := 0;
    Output := TStringStream.Create('', TEncoding.ASCII);
    try
      Soap.EncdDecd.EncodeStream(Input, Output);
      Result := Output.DataString;
    finally
      Output.Free;
    end;
  finally
    Input.Free;
  end;
end;

procedure ReduzirBitmapParaMaximo(ABitmap: FMX.Graphics.TBitmap; const AMaxWidth, AMaxHeight: Integer);
var
  LSrc: FMX.Graphics.TBitmap;
  LScale: Single;
  LNewWidth: Integer;
  LNewHeight: Integer;
begin
  if (ABitmap = nil) or (AMaxWidth <= 0) or (AMaxHeight <= 0) then
    Exit;

  if (ABitmap.Width <= AMaxWidth) and (ABitmap.Height <= AMaxHeight) then
    Exit;

  LScale := Min(AMaxWidth / ABitmap.Width, AMaxHeight / ABitmap.Height);
  LNewWidth := Max(1, Round(ABitmap.Width * LScale));
  LNewHeight := Max(1, Round(ABitmap.Height * LScale));

  LSrc := FMX.Graphics.TBitmap.Create;
  try
    LSrc.Assign(ABitmap);
    ABitmap.SetSize(LNewWidth, LNewHeight);
    if ABitmap.Canvas.BeginScene then
    try
      ABitmap.Clear(TAlphaColors.Null);
      ABitmap.Canvas.DrawBitmap(LSrc, RectF(0, 0, LSrc.Width, LSrc.Height),
        RectF(0, 0, LNewWidth, LNewHeight), 1, True);
    finally
      ABitmap.Canvas.EndScene;
    end;
  finally
    LSrc.Free;
  end;
end;

function BitmapFromBase64(const base64: string): FMX.Graphics.TBitmap;
var
  Input: TStringStream;
  Output: TBytesStream;
begin
  Input := TStringStream.Create(base64, TEncoding.ASCII);
  try
    Output := TBytesStream.Create;
    try
      Soap.EncdDecd.DecodeStream(Input, Output);
      Output.Position := 0;
      Result := FMX.Graphics.TBitmap.Create;
      try
        Result.LoadFromStream(Output);
      except
        Result.Free;
        raise;
      end;
    finally
      Output.Free;
    end;
  finally
    Input.Free;
  end;
end;

function AppVersionName: string;
{$IFDEF ANDROID}
var
  LInfo: JPackageInfo;
{$ENDIF}
{$IFDEF MSWINDOWS}
var
  LSize: DWORD;
  LHandle: DWORD;
  LBuffer: TBytes;
  LValue: Pointer;
  LLen: UINT;
  LFixed: PVSFixedFileInfo;
{$ENDIF}
begin
  Result := '';
{$IFDEF ANDROID}
  try
    LInfo := TAndroidHelper.Context.getPackageManager.getPackageInfo(TAndroidHelper.Context.getPackageName, 0);
    if Assigned(LInfo) and Assigned(LInfo.versionName) then
      Result := JStringToString(LInfo.versionName);
  except
    Result := '';
  end;
{$ENDIF}
{$IFDEF MSWINDOWS}
  try
    LSize := GetFileVersionInfoSize(PChar(ParamStr(0)), LHandle);
    if LSize > 0 then
    begin
      SetLength(LBuffer, LSize);
      if GetFileVersionInfo(PChar(ParamStr(0)), LHandle, LSize, @LBuffer[0]) and
         VerQueryValue(@LBuffer[0], '\', LValue, LLen) then
      begin
        LFixed := PVSFixedFileInfo(LValue);
        Result := Format('%d.%d.%d.%d', [
          HiWord(LFixed.dwFileVersionMS), LoWord(LFixed.dwFileVersionMS),
          HiWord(LFixed.dwFileVersionLS), LoWord(LFixed.dwFileVersionLS)
        ]);
      end;
    end;
  except
    Result := '';
  end;
{$ENDIF}
  if Result = '' then
    Result := '1.0.0';
end;
function GerarNomeArq(extensao: string): string;
begin
  Result := FormatDateTime('yymmddhhnnsszzz', Now) + '.' + extensao;
end;

end.


