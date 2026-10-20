object LocationTrackingModule: TLocationTrackingModule
  OnCreate = AndroidServiceCreate
  OnBind = AndroidServiceBind
  OnUnBind = AndroidServiceUnBind
  OnRebind = AndroidServiceRebind
  OnStartCommand = AndroidServiceStartCommand
  Height = 238
  Width = 324
  object LocationSensor: TLocationSensor
    Accuracy = 10.000000000000000000
    ActivityType = Automotive
    Distance = 1.000000000000000000
    UsageAuthorization = Always
    OnLocationChanged = LocationSensorLocationChanged
    Left = 32
    Top = 8
  end
  object NotificationCenter: TNotificationCenter
    Left = 128
    Top = 8
  end
end
