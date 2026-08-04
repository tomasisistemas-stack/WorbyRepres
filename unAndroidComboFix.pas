unit unAndroidComboFix;

interface

uses
  FMX.ListBox;

procedure UseAndroidSafeComboPicker(const ACombos: array of TComboBox);

implementation

uses
  FMX.Pickers;

procedure UseAndroidSafeComboPicker(const ACombos: array of TComboBox);
var
  LCombo: TComboBox;
begin
{$IFDEF ANDROID}
  for LCombo in ACombos do
    if Assigned(LCombo) then
      LCombo.DropDownKind := TDropDownKind.Custom;
{$ENDIF}
end;

end.
