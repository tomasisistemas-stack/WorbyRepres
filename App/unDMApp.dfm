object dmApp: TdmApp
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 480
  Width = 640
  object FDConnection: TFDConnection
    Params.Strings = (
      'DriverID=SQLite')
    LoginPrompt = False
    Left = 80
    Top = 64
  end
  object FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink
    Left = 208
    Top = 64
  end
  object QExec: TFDQuery
    Connection = FDConnection
    Left = 336
    Top = 64
  end
end
