//
// Copyright 2012 Shaun Simpson
// shauns2029@gmail.com
//

unit ClockMain;

{$mode Delphi}

{$DEFINE PICSHOW}
//{$DEFINE DEBUG}

// Zipit does not support media keys
{$IFNDEF CPUARM}
  {$DEFINE GRABXKEYS}
{$ENDIF}

interface

uses
  gtk2, gdk2, glib2,
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, MetOffice, Alarm, Settings, Reminders, ReminderList, LCLProc,
  Music, Sync, Process, MusicPlayer, PlaylistCreator, UDPCommandServer,
  X, Xlib, CTypes, Black, WaitForMedia, Pictures, DateTime;

const
  VERSION = '2.0.10';

type
  TMusicState = (msOff, msPlaying, msPaused);
  TMusicSource = (msrcNone, msrcSleep, msrcMusic, msrcMeditation);
  TMediaKey = (mkNone, mkAudioPlay, mkAudioNext);

  { TfrmClockMain }

  TfrmClockMain = class(TForm)
    Image1: TImage;
    imgExit: TImage;
    imgPlayAlbums: TImage;
    imgPrevious: TImage;
    imgOn: TImage;
    imgOff: TImage;
    imgDisplay: TImage;
    imgPlay: TImage;
    imgReminders: TImage;
    imgWeather: TImage;
    imgVolUp: TImage;
    imgVolDown: TImage;
    imgNext: TImage;
    Image2: TImage;
    Image3: TImage;
    Image4: TImage;
    Image5: TImage;
    imgMusic: TImage;
    imgMeditation: TImage;
    ImgSleep: TImage;
    imgPictures: TImage;
    imgUpdateMusic: TImage;
    imgSettings: TImage;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    lbPlayAlbums: TLabel;
    lbWeatherSummary: TLabel;
    lbExit: TLabel;
    lbMusic: TLabel;
    Label22: TLabel;
    lbPrevious: TLabel;
    lbPlay: TLabel;
    lbReminders: TLabel;
    lbWeather: TLabel;
    lbSleep: TLabel;
    lbVolUp: TLabel;
    lbVolDown: TLabel;
    lbNext: TLabel;
    lbPictures: TLabel;
    lbDisplay: TLabel;
    labLocation: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    labSong: TLabel;
    lblTime: TLabel;
    UpdateMusic: TLabel;
    lbSettings: TLabel;
    tmrMinute: TTimer;
    tmrWeather: TTimer;
    tmrTime: TTimer;
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyPress(Sender: TObject; var Key: char);
    procedure FormShow(Sender: TObject);
    procedure imgExitClick(Sender: TObject);
    procedure imgMeditationClick(Sender: TObject);
    procedure imgMusicClick(Sender: TObject);
    procedure imgRemindersClick(Sender: TObject);
    procedure imgVolDownClick(Sender: TObject);
    procedure imgVolUpClick(Sender: TObject);
    procedure imgUpdateMusicClick(Sender: TObject);
    procedure imgWeatherClick(Sender: TObject);
    procedure lbDisplayClick(Sender: TObject);
    procedure lblTimeClick(Sender: TObject);
    procedure lbNextClick(Sender: TObject);
    procedure lbPlayAlbumsClick(Sender: TObject);
    procedure lbPicturesClick(Sender: TObject);
    procedure lbPlayClick(Sender: TObject);
    procedure lbPreviousClick(Sender: TObject);
    procedure lbSettingsClick(Sender: TObject);
    procedure lbSleepClick(Sender: TObject);
    procedure tmrTimeTimer(Sender: TObject);
    procedure tmrWeatherTimer(Sender: TObject);
    procedure tmrMinuteTimer(Sender: TObject);
  private
    { private declarations }
    FMPGPlayer: TMusicPlayer;
    FMetOffice: TMetOffice;
    FAlarm, FReminderAlarm: TAlarm;
    FCurrentReminders: TReminders;
    FTimer: TAlarm;
    FSyncServer: TSyncServer;
    FSyncClient: TSyncClient;
    FServerAddress, FServerPort: String;
    FAfterAlarmResumeMusic: boolean;
    FLinuxDateTime: TLinuxDateTime;

    FConfigFilename: string;

    Images: array [0..4] of TImage;
    ImageURLs: array [0..4] of string;
    Labels: array [0..9] of TLabel;
    DayLabels: array[0..4] of TLabel;
    WindLabels: array[0..4] of TLabel;
    Locations: array[0..3] of string;
    FCurrentLocation: integer;

    FMusicPlayer, FSleepPlayer, FMeditationPlayer: TPlayer;
 	  FMusicState: TMusicState;
    FMusicSource: TMusicSource;

    FCOMServer: TCOMServer;
    FWeatherReport: string;
    FWeatherReports: array [0..4] of string;

    FDisplay: PDisplay;
    FAlarmActive: boolean;

    procedure BacklightOff;
    procedure BacklightOn;

    procedure CloseApp;
    procedure ConfigureWifi;
    function DayOfWeekStr(Date: TDateTime): string;
    procedure Execute(Command: string);
    function FormShowModal(MyForm: TForm): integer;
    procedure Log(Message: string);
    procedure PauseMusic;
    procedure PlayAlbums;
    procedure PlayMusic;
    procedure PlayPreviousMusic;
    procedure SetCursorType(MyForm: TForm);
    procedure SetMusicSource(Source: TMusicSource);
    procedure UpdatingMusic(Player: TPlayer);

{$IFDEF GRABXKEYS}
    procedure GrabMediaKeys;
    procedure ReleaseMediaKeys;
    function GetMediaKeyPress: TMediaKey;
    function XErrorHandler(para1: PDisplay; para2: PXErrorEvent): cint; cdecl;
{$ENDIF}

    procedure Shutdown(Reboot: boolean);
    procedure UpdateSettings;
    procedure UpdateWeather;
    procedure UpdateReminders;

    procedure BeforeAlarm;
    procedure AfterAlarm;
  public
    { public declarations }
    HTTPBuffer: string;
    function WaitForMedia(Path: string): boolean;

  published
  end;

var
  frmClockMain: TfrmClockMain;

implementation

{$R *.lfm}

{ TfrmClockMain }

procedure TfrmClockMain.PauseMusic;
begin
  case FMusicState of
    msPlaying:
      begin
        case FMusicSource of
          msrcSleep: FSleepPlayer.Stop;
          msrcMusic: FMusicPlayer.Stop;
          msrcMeditation: FMeditationPlayer.Stop;
        end;

	      FMusicState := msPaused;
	    end;
  end;
end;

procedure TfrmClockMain.PlayMusic;
var
  Player: TPlayer;
begin
  case FMusicSource of
    msrcSleep: Player := FSleepPlayer;
    msrcMeditation: Player := FMeditationPlayer;
    msrcMusic: Player := FMusicPlayer;
    else Player := nil;
  end;

  if WaitForMedia(Player.SearchPath) then
  begin
    if Assigned(Player) then
    begin
      case FMusicState of
        msOff, msPaused:
          begin
            Player.Play;
          end;
        msPlaying:
          begin
            Player.Next; // if playing play next track
	        end;
      end;

      FMusicState := msPlaying;
    end;
  end;
end;

procedure TfrmClockMain.PlayPreviousMusic;
var
  Player: TPlayer;
begin
  case FMusicSource of
    msrcSleep: Player := FSleepPlayer;
    msrcMeditation: Player := FMeditationPlayer;
    msrcMusic: Player := FMusicPlayer;
    else Player := nil;
  end;

  if WaitForMedia(Player.SearchPath) then
  begin
    if Assigned(Player) then
    begin
      case FMusicState of
        msOff, msPaused, msPlaying:
          begin
            Player.Previous;
	        end;
      end;

      FMusicState := msPlaying;
    end;
  end;
end;

function TfrmClockMain.WaitForMedia(Path: string): boolean;
var
  Timeout: TDateTime;
  frmWait: TfrmWaitForMedia;
begin
  Result := False;

  if (Path <> '') and not DirectoryExists(Path) then
  begin
    Timeout := EncodeTime(0,1,0,0);

    frmWait := TfrmWaitForMedia.Create(Self, Path, Timeout);
    Result := FormShowModal(frmWait) = mrOk;
    frmWait.Free;
  end
  else if (Path <> '') then Result := True;
end;

procedure TfrmClockMain.SetMusicSource(Source: TMusicSource);
var
  Player: TPlayer;
  PlayerPath: String;
begin
  case Source of
    msrcSleep:
      begin
        Player := FSleepPlayer;
        PlayerPath := frmSettings.edtSleepPath.Text;
      end;
    msrcMeditation:
      begin
        Player := FMeditationPlayer;
        PlayerPath := frmSettings.edtMeditationPath.Text;
      end;
    msrcMusic:
      begin
        Player := FMusicPlayer;
        PlayerPath := frmSettings.edtMusicPath.Text;
      end
    else
      begin
        Player := nil;
        PlayerPath := '';
      end;
  end;

  // Test is the search path has changed
  if (Assigned(Player) and (PlayerPath <> Player.SearchPath)) then
    FreeAndNil(Player);

  if not Assigned(Player) then
  begin
    //Create new source
    case Source of
      msrcSleep:
        begin
          FSleepPlayer := TPlayer.Create(FMPGPlayer,
            ChangeFileExt(FConfigFilename, '_sleep.cfg'), frmSettings.edtSleepPath.Text);
        end;
      msrcMusic:
        begin
          FMusicPlayer := TPlayer.Create(FMPGPlayer,
            ChangeFileExt(FConfigFilename, '_music.cfg'), frmSettings.edtMusicPath.Text);
        end;
      msrcMeditation:
        begin
          FMeditationPlayer := TPlayer.Create(FMPGPlayer,
            ChangeFileExt(FConfigFilename, '_meditation.cfg'), frmSettings.edtMeditationPath.Text);
        end;
    end;
  end;

  FMusicSource := Source;
end;

procedure TfrmClockMain.BeforeAlarm;
begin
  FAlarmActive := True;
  FAfterAlarmResumeMusic := FMusicState = msPlaying;
  PauseMusic;
end;

procedure TfrmClockMain.AfterAlarm;
begin
  // Possibly start music after alarm
  if frmSettings.cbxPlayMusic.Checked or FAfterAlarmResumeMusic then
  begin
    case FMusicSource of
      msrcSleep: FSleepPlayer.Play;
      msrcMusic: FMusicPlayer.Play;
      msrcMeditation: FMeditationPlayer.Play;
      else
      begin
        SetMusicSource(msrcMusic);
        FMusicPlayer.Play;
      end;
    end;

    FMusicState := msPlaying;
  end;

  FAlarmActive := False;
end;

function TfrmClockMain.DayOfWeekStr(Date: TDateTime): string;
var
  DOW: Integer;
begin
  DOW := DayOfWeek(Date);

  case DOW of
    1: Result := 'Sunday';
    2: Result := 'Monday';
    3: Result := 'Tuesday';
    4: Result := 'Wednesday';
    5: Result := 'Thursday';
    6: Result := 'Friday';
    else Result := 'Saturday';
  end;
end;

procedure TfrmClockMain.tmrTimeTimer(Sender: TObject);
var
  Current: TDateTime;
  DayStr: string;
  TimeCaption: string;
  ReminderList: TStringList;
  i, j, k: Integer;
  Command: TRemoteCommand;
  Key: Char;
  Player: TPlayer;
  PlayerName, Song: string;
  ReminderState: TAlarmState;
  Day, Month, Year: word;
  Hour, Min, Sec, MSec: word;
begin
  Current := FLinuxDateTime.GetLocalTime;

  DayStr := Copy(DayOfWeekStr(Current), 1, 3);
  DecodeDate(Current, Year, Month, Day);
  DecodeTime(Current, Hour, Min, Sec, MSec);
  TimeCaption := Format('%s %.2d/%.2d %.2d:%.2d:%.2d ', [DayStr, Day, Month, Hour, Min, Sec]);

  if TimeCaption <> lblTime.Caption then
    lblTime.Caption := TimeCaption;

  tmrTime.Tag := tmrTime.Tag + 1;

  if tmrTime.Tag >= 1 then
  begin
    tmrWeather.Enabled := True;

    // Disable weather update around alarm times
    if (Current > FAlarm.AlarmTime - EncodeTime(0, 5, 0, 0))
      and (Current < FAlarm.AlarmTime + EncodeTime(0, 5, 0, 0)) then
    begin
      tmrWeather.Enabled := False;
    end;

    // Disable weather when reminder alarm about to be activated
    if (Length(FCurrentReminders) > 0) and (Current > FReminderAlarm.AlarmTime - EncodeTime(0, 2, 0, 0))
      and (Current < FReminderAlarm.AlarmTime + EncodeTime(0, 0, 10, 0)) then
    begin
      tmrWeather.Enabled := False;
    end;

    // Do not update weather if reminder is displayed
    if (lbWeatherSummary.Font.Color = clYellow) then
    begin
      tmrWeather.Enabled := False;
    end;

    // Turn off timer
    if Current > FTimer.AlarmTime + EncodeTime(0, 5, 0, 0) then
    begin
      for i := 0 to High(FTimer.Days) do
      begin
        if FTimer.Days[i] <> False then
          FTimer.Days[i] := False;
      end;
    end;

    ReminderState := FReminderAlarm.State;

    FAlarm.Tick;
    FReminderAlarm.Tick;
    FTimer.Tick;

    if (FReminderAlarm.State = asActive) and (ReminderState <> asActive) then
    begin
      lbWeatherSummary.Font.Color := clYellow;
      ReminderList := TStringList.Create;
      frmReminders.SortReminders(FCurrentReminders);
      frmReminders.PopulateList(FCurrentReminders, ReminderList);
      lbWeatherSummary.Caption := ReminderList.Text;
      ReminderList.Free;
      tmrWeather.Enabled := False;
    end;

    case FMusicSource of
      msrcSleep:
        begin
          Player := FSleepPlayer;
          PlayerName := 'sleep';
        end;
      msrcMeditation:
        begin
          Player := FMeditationPlayer;
          PlayerName := 'meditation';
        end;
      msrcMusic:
        begin
          Player := FMusicPlayer;
          PlayerName := 'music';
        end;
      else Player := nil;
    end;

    Song := 'Shaun''s Clock Version: ' + VERSION;

    if Assigned(Player) then
    begin
      i := Player.Tick;

      if i >= 0  then
        Song := Format('Updating %s list ... %d', [PlayerName, i])
      else
      begin
        if Player.State = psPlaying then
          Song := Player.SongArtist + ' - ' + Player.SongTitle;
      end;
    end;

    if labSong.Caption <> Song then
      labSong.Caption := Song;

    tmrTime.Tag := 0;
  end;

  if Assigned(FCOMServer) then
  begin
    FCOMServer.Playing := LabSong.Caption;
    FCOMServer.WeatherReport := FWeatherReport;
    FCOMServer.SetImageURLs(ImageURLs);
    FCOMServer.SetWeatherReports(FWeatherReports);

    Command := FCOMServer.GetCommand;

    case Command of
      rcomNext:
        begin
          case FMusicSource of
            msrcSleep: Key := 's';
            msrcMeditation: Key := 'd';
            else Key := 'm';
          end;

          FormKeyPress(Self, Key);
        end;
      rcomMusic:
        begin
          Key := 'm';
          FormKeyPress(Self, Key);
        end;
      rcomSleep:
        begin
          Key := 's';
          FormKeyPress(Self, Key);
        end;
      rcomMeditation:
        begin
          Key := 'd';
          FormKeyPress(Self, Key);
        end;
      rcomPause:
        begin
          Key := 'p';
          FormKeyPress(Self, Key);
        end;
      rcomVolumeUp:
        begin
          Key := '.';
          FormKeyPress(Self, Key);
        end;
      rcomVolumeDown:
        begin
          Key := ',';
          FormKeyPress(Self, Key);
        end;
    end;
  end;

{$IFDEF GRABXKEYS}
  case GetMediaKeyPress of
    mkAudioPlay:
      begin
        Key := 'p';
        FormKeyPress(Self, Key);
      end;
    mkAudioNext:
      begin
        case FMusicSource of
          msrcSleep: Key := 's';
          msrcMeditation: Key := 'd';
          else Key := 'm';
        end;

        FormKeyPress(Self, Key);
      end;
  end;
{$ENDIF}
end;

procedure TfrmClockMain.tmrWeatherTimer(Sender: TObject);
begin
  tmrWeather.Enabled := False;
  UpdateWeather;
  // Every 60 Minutes
  tmrWeather.Interval := 60 * 60 * 1000;
  tmrWeather.Enabled := True;
end;

procedure TfrmClockMain.tmrMinuteTimer(Sender: TObject);
var
  Rems: string;
  CurrentList: TStringList;
begin
  tmrMinute.Enabled := False;

  // Reminders
  if tmrMinute.Tag >= 1 then
  begin
    tmrMinute.Tag := 0;

    if Assigned(FSyncServer) then
      FSyncServer.RemindersFile(frmReminders.Filename)
    else if Assigned(FSyncClient) then
    begin
      if FSyncClient.GetReminders(FServerAddress, FServerPort, Rems) then
      begin
        CurrentList := TStringList.Create;

        try
          if FileExists(frmReminders.Filename) then
            CurrentList.LoadFromFile(frmReminders.Filename);

          if CurrentList.Text <> Rems then
          begin
            CurrentList.Text := Rems;
            CurrentList.SaveToFile(frmReminders.Filename);
            frmReminders.ReadReminders;
          end;
        except
        end;

        CurrentList.Free;

        frmReminders.ReadReminders;
      end;
    end;

    frmReminders.RefreshReminders;
    UpdateReminders;
  end
  else tmrMinute.Tag := tmrMinute.Tag + 1;

  tmrMinute.Enabled := True;
end;

procedure TfrmClockMain.BacklightOn;
begin
  try
    Execute('xset dpms force on');
    Execute('backlight-on');
  except
  end;
end;

procedure TfrmClockMain.BacklightOff;
begin
  try
    Execute('xset dpms force off');
    Execute('backlight-off');
  except
  end;
end;

procedure TfrmClockMain.Execute(Command: string);
var
 AProcess: TProcess;
begin
 // Now we will create the TProcess object, and
 // assign it to the var AProcess.
 AProcess := TProcess.Create(nil);

 // Tell the new AProcess what the command to execute is.
 // Let's use the FreePascal compiler
 AProcess.CommandLine := Command;

 // We will define an option for when the program
 // is run. This option will make sure that our program
 // does not continue until the program we will launch
 // has stopped running.                vvvvvvvvvvvvvv
 AProcess.Options := AProcess.Options + [poWaitOnExit];

 // Now that AProcess knows what the commandline is
 // we will run it.
 AProcess.Execute;

 // This is not reached until ppc386 stops running.
 AProcess.Free;
end;

procedure TfrmClockMain.UpdateWeather;
var
  Forecast: TWeatherReport;
  i: Integer;
begin
  tmrWeather.Enabled := False;

  lbWeatherSummary.Font.Color := clWhite;

  FWeatherReport := '';

  for i := 0 to 4 do
  begin
    try
      if FMetOffice.GetForecast('http://www.metoffice.gov.uk/mobile/',
        '5dayforecastdetail?forecastid=' + Trim(Locations[FCurrentLocation]),
        i, Forecast, Images, ImageURLs) then
      begin
        if i = 0 then
        begin
          labLocation.Caption := Forecast.Title;
          lbWeatherSummary.Caption := Forecast.Report;
        end;

        DayLabels[i].Caption := Forecast.Day;
        Labels[i*2].Caption := IntToStr(Forecast.TempDay) + '°C';
        Labels[(i*2) + 1].Caption := IntToStr(Forecast.TempNight) + '°C';
        WindLabels[i].Caption := IntToStr(Forecast.WindSpeedDay) + 'mph';

        FWeatherReports[i] := Format('%s %d°C (%d°C) %dmph',
          [Forecast.Day, Forecast.TempDay, Forecast.TempNight, Forecast.WindSpeedDay]);
      end
      else
      begin
        lbWeatherSummary.Caption := 'Failed to update weather' + LineEnding + 'Press W to configure Wifi.';
        tmrWeather.Enabled := True;
        Exit;
      end;
    except
      on E: exception do
      begin
        lbWeatherSummary.Caption := 'Exception updating weather' + LineEnding + 'Press W to configure Wifi.';
        DebugLn('Unhandled Exception: Failure during weather update.');
        DebugLn('Exception: ' + E.Message);
        tmrWeather.Enabled := True;
        Exit;
      end;
    end;

    Application.ProcessMessages;
  end;

  FWeatherReport := labLocation.Caption + LineEnding + lbWeatherSummary.Caption;
  tmrWeather.Enabled := True;
end;


procedure TfrmClockMain.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  FConfigFilename := GetAppConfigFile(False);

  Self.Color := clBlack;

  FMetOffice := TMetOffice.Create;

  labSong.Caption := '';

  Labels[0] := Label1;
  Labels[1] := Label2;
  Labels[2] := Label3;
  Labels[3] := Label4;
  Labels[4] := Label5;
  Labels[5] := Label6;
  Labels[6] := Label7;
  Labels[7] := Label8;
  Labels[8] := Label9;
  Labels[9] := Label10;

  DayLabels[0] := Label11;
  DayLabels[1] := Label12;
  DayLabels[2] := Label13;
  DayLabels[3] := Label14;
  DayLabels[4] := Label15;

  WindLabels[0] := Label16;
  WindLabels[1] := Label17;
  WindLabels[2] := Label18;
  WindLabels[3] := Label19;
  WindLabels[4] := Label20;

  Images[0] := Image1;
  Images[1] := Image2;
  Images[2] := Image3;
  Images[3] := Image4;
  Images[4] := Image5;

  for i := 0 to High(Labels) do
    Labels[i].Caption := '';

  for i := 0 to High(DayLabels) do
    DayLabels[i].Caption := '';

  for i := 0 to High(WindLabels) do
    WindLabels[i].Caption := '';

  FMPGPlayer := TMusicPlayer.Create;
  FMPGPlayer.Equalizer := ChangeFileExt(FConfigFilename, '_eq.cfg');


  FAlarm := TAlarm.Create(FMPGPlayer);
  FAlarm.Path := ExtractFilePath(Application.ExeName);

  FReminderAlarm := TAlarm.Create(FMPGPlayer);
  FReminderAlarm.Path := ExtractFilePath(Application.ExeName);

  FTimer := TAlarm.Create(FMPGPlayer);
  FTimer.Path := ExtractFilePath(Application.ExeName);

  FAlarm.OnBeforeAlarm := BeforeAlarm;
  FReminderAlarm.OnBeforeAlarm := BeforeAlarm;
  FTimer.OnBeforeAlarm := BeforeAlarm;

  FAlarm.OnAfterAlarm := AfterAlarm;
  FReminderAlarm.OnAfterAlarm := AfterAlarm;
  FTimer.OnAfterAlarm := AfterAlarm;

  FCurrentLocation := 0;

  FMusicPlayer := nil;
  FSleepPlayer := nil;
  FMeditationPlayer := nil;
  FSyncServer := nil;
  FSyncClient := nil;

  FMusicState := msOff;
  FMusicSource := msrcNone;
  FAlarmActive := False;

  FCOMServer := TCOMServer.Create(44558);

  FWeatherReport := '';

  FLinuxDateTime := TLinuxDateTime.Create;

{$IFDEF GRABXKEYS}
  GrabMediaKeys;
{$ENDIF}
end;

procedure TfrmClockMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  FAlarm.ResetAlarm;
  FTimer.ResetAlarm;
  FReminderAlarm.ResetAlarm;
  FLinuxDateTime.Free;
{$IFDEF GRABXKEYS}
  ReleaseMediaKeys;
{$ENDIF}
end;

procedure TfrmClockMain.FormActivate(Sender: TObject);
begin
  if frmSettings.cbxForceFullscreen.Checked then
    gdk_window_fullscreen(PGtkWidget(Handle)^.window);
end;

procedure TfrmClockMain.FormDestroy(Sender: TObject);
begin
  if Assigned(FMusicPlayer) then
    FMusicPlayer.Free;

  if Assigned(FSleepPlayer) then
    FSleepPlayer.Free;

  if Assigned(FMeditationPlayer) then
    FMeditationPlayer.Free;

  FMPGPlayer.Free;

  if Assigned(FSyncClient) then
    FreeAndNil(FSyncClient);

  if Assigned(FSyncServer) then
    FreeAndNil(FSyncServer);

  FMetOffice.Free;
  FAlarm.Free;
  FReminderAlarm.Free;
  FTimer.Free;
  FCOMServer.Free;
end;

procedure TfrmClockMain.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = 112) or (key = 72) then
  begin
    Key := 0;

    ShowMessage('Keyboard Shortcuts' +  LineEnding +
      'Power - Powerdown' + LineEnding +
      'Power + Shift (...) - Reboot' + LineEnding + LineEnding +
      'W - Configure Wifi' + LineEnding + LineEnding +
      'Enter - Settings' + LineEnding +
      'Space - Stop alarm' + LineEnding +
      'M - Play music / skip song' + LineEnding +
      'L - List and select music' + LineEnding +
      'S - Play sleep music / skip song' + LineEnding +
      'P - Stop music' + LineEnding +
      'U - Update music' + LineEnding + LineEnding +
      'N - Next weather location' + LineEnding +
      'R - Reminders'  + LineEnding + LineEnding +
      'Smiley :-) - Exit');
  end
  {$IFNDEF PICSHOW}
  else if (Key = 43) and (ssShift in Shift) then
  begin
    Key := 0;
    Shutdown(True);
  end
  else if Key = 43 then
  begin
    Key := 0;
    Shutdown(False);
  end
  else if Key = 87 then
  begin
    Key := 0;
    ConfigureWifi;
  end
  else if (Key = 27) and (ssShift in Shift) then
  begin
    Key := 0;
    CloseApp;
  end;
  {$ELSE};
  {$ENDIF}
end;

procedure TfrmClockMain.FormKeyPress(Sender: TObject; var Key: char);
var
  Player: TPlayer;
begin
  tmrMinute.Enabled := False;

  FAlarm.ResetAlarm;
  FReminderAlarm.ResetAlarm;
  FTimer.ResetAlarm;

  if Key = #27 then {$IFDEF PICSHOW} Close {$ENDIF}
  else if Key = #13 then
  begin
    FormShowModal(frmSettings);
    UpdateSettings;
  end
  else if (Key = 'l') or (Key='L') then
  begin
    PlayAlbums;
  end
  else if (Key = 'r') or (Key = 'R') then frmReminderList.Show
  else if (Key = 'n') or (Key = 'N') then
  begin
    Inc(FCurrentLocation);
    if FCurrentLocation > High(Locations) then FCurrentLocation := 0;
    UpdateWeather;
  end
  else if (Key = 'm') or (Key = 'M') then
  begin
    SetMusicSource(msrcMusic);

    if not FAlarmActive then PlayMusic
    else PauseMusic;
  end
  else if (Key = 's') or (Key = 'S') then
  begin
    SetMusicSource(msrcSleep);

    if not FAlarmActive then PlayMusic
    else PauseMusic;
  end
  else if (Key = 'd') or (Key = 'D') then
  begin
    SetMusicSource(msrcMeditation);

    if not FAlarmActive then PlayMusic
    else PauseMusic;
  end
  else if (Key = 'p') or (Key = 'P') then
  begin
    case FMusicState of
      msPlaying: PauseMusic;
      else PlayMusic;
    end;
  end
  else if (Key = 'u') or (Key = 'U') then
  begin
    case FMusicSource of
      msrcSleep: Player := FSleepPlayer;
      msrcMeditation: Player := FMeditationPlayer;
      msrcMusic: Player := FMusicPlayer;
      else Player := nil;
    end;

    if Assigned(Player) then
    begin
      Player.RescanSearchPath;
    end;
  end
  else if (Key = '.') then
  begin
    if Assigned(FMPGPlayer) then
    begin
      FMPGPlayer.VolumeUp;
    end;
  end
  else if (Key = ',') then
  begin
    if Assigned(FMPGPlayer) then
    begin
      FMPGPlayer.VolumeDown;
    end;
  end
  else if ((Key = ' ') or (Key = 'w') or (Key = 'W'))
    and (lbWeatherSummary.Font.Color = clYellow) then
  begin
    UpdateWeather;
  end;

  tmrMinute.Enabled := True;
end;

procedure TfrmClockMain.SetCursorType(MyForm: TForm);
var
  i: Integer;
begin

  // Disable cursor if in Touchscreen mode
  if frmSettings.cbxTouchScreen.Checked then
    MyForm.Cursor := crNone
  else MyForm.Cursor := crDefault;

  for i := 0 to MyForm.ComponentCount - 1 do
  begin
    if MyForm.Components[i] is TControl then
    begin
      if frmSettings.cbxTouchScreen.Checked then
        TControl(MyForm.Components[i]).Cursor := crNone
      else TControl(MyForm.Components[i]).Cursor := crDefault;
    end;
  end;
end;

procedure TfrmClockMain.FormShow(Sender: TObject);
begin
  if not FileExists('/usr/bin/mpg123') and not FileExists('/usr/bin/mpg321') then
    ShowMessage('Alarm Not Working' + LineEnding
    + 'The package mpg123 was not found on this system.' + LineEnding
    + 'Please install mpg123 to enable the alarm by running the command:' + LineEnding
    + 'sudo apt-get install mpg123');

  if not FileExists(ExtractFilePath(Application.ExeName) + 'alarm.mp3')
    and not FileExists('/usr/share/clock/alarm.mp3') then
    ShowMessage('Alarm Not Working' + LineEnding
    + 'The mp3 file "alarm.mp3" can not be found.' + LineEnding
    + 'Please copy the file "alarm.mp3" to the location:' + LineEnding
    + '/usr/share/clock/alarm.mp3');

  UpdateSettings;
  frmReminderList.FReminders := frmReminders;

  // Do only once
  if FMusicSource = msrcNone then
  begin
    // Initialise music sources
    SetMusicSource(msrcSleep);
    SetMusicSource(msrcMeditation);
    SetMusicSource(msrcMusic);
  end;

  tmrMinute.Enabled := True;
end;

procedure TfrmClockMain.imgExitClick(Sender: TObject);
begin
  imgExit.Picture.Assign(imgOff.Picture);
  Application.ProcessMessages;
  Close;
end;

procedure TfrmClockMain.imgMusicClick(Sender: TObject);
begin
  imgMusic.Picture.Assign(imgOff.Picture);
  Application.ProcessMessages;

  SetMusicSource(msrcMusic);

  if not FAlarmActive then PlayMusic
  else PauseMusic;

  imgMusic.Picture.Assign(imgOn.Picture);
end;

procedure TfrmClockMain.imgRemindersClick(Sender: TObject);
begin
  imgReminders.Picture.Assign(imgOff.Picture);
  Application.ProcessMessages;

  if (FAlarm.State = asActive)
    or (FTimer.State = asActive)
    or (FReminderAlarm.State = asActive) then
  begin
    FAlarm.ResetAlarm;
    FTimer.ResetAlarm;
    FReminderAlarm.ResetAlarm;
  end
  else if lbWeatherSummary.Font.Color = clYellow then
  begin
    UpdateWeather;
  end
  else
  begin
    FormShowModal(frmReminderList);
  end;

  imgReminders.Picture.Assign(imgOn.Picture);
end;

procedure TfrmClockMain.imgVolDownClick(Sender: TObject);
begin
  imgVolDown.Picture.Assign(imgOff.Picture);
  Application.ProcessMessages;

  if Assigned(FMPGPlayer) then
  begin
    FMPGPlayer.VolumeDown;
  end;

  imgVolDown.Picture.Assign(imgOn.Picture);
end;

procedure TfrmClockMain.imgVolUpClick(Sender: TObject);
begin
  imgVolUp.Picture.Assign(imgOff.Picture);
  Application.ProcessMessages;

  if Assigned(FMPGPlayer) then
  begin
    FMPGPlayer.VolumeUp;
  end;

  imgVolUp.Picture.Assign(imgOn.Picture);
end;


procedure TfrmClockMain.UpdatingMusic(Player: TPlayer);
var
  i: Integer;
begin
  if Assigned(Player) then
  begin
    repeat
      i := Player.Tick;
      Application.ProcessMessages;
    until i < 0;
  end;
end;

procedure TfrmClockMain.imgUpdateMusicClick(Sender: TObject);
begin
  imgUpdateMusic.Picture.Assign(imgOff.Picture);
  Self.Enabled := False;

  Application.ProcessMessages;

  if Assigned(FSleepPlayer) then
  begin
    FSleepPlayer.RescanSearchPath;
    UpdatingMusic(FSleepPlayer);
  end;

  if Assigned(FMeditationPlayer) then
  begin
    FMeditationPlayer.RescanSearchPath;
    UpdatingMusic(FMeditationPlayer);
  end;

  if Assigned(FMusicPlayer) then
  begin
    FMusicPlayer.RescanSearchPath;
    UpdatingMusic(FMusicPlayer);
  end;

  Self.Enabled := True;
  imgUpdateMusic.Picture.Assign(imgOn.Picture);
end;

procedure TfrmClockMain.imgWeatherClick(Sender: TObject);
begin
  imgWeather.Picture.Assign(imgOff.Picture);
  Application.ProcessMessages;

  Inc(FCurrentLocation);
  if FCurrentLocation > High(Locations) then FCurrentLocation := 0;
  UpdateWeather;

  imgWeather.Picture.Assign(imgOn.Picture);
end;

procedure TfrmClockMain.lbDisplayClick(Sender: TObject);
var
  Form: TfrmBlack;
begin
  imgDisplay.Picture.Assign(imgOff.Picture);
  Application.ProcessMessages;

  BacklightOff;
  Form := TfrmBlack.Create(Self);
  FormShowModal(Form);
  BacklightOn;
  Form.Free;
  imgDisplay.Picture.Assign(imgOn.Picture);
end;

procedure TfrmClockMain.imgMeditationClick(Sender: TObject);
begin
  imgMeditation.Picture.Assign(imgOff.Picture);
  Application.ProcessMessages;

  SetMusicSource(msrcMeditation);

  if not FAlarmActive then PlayMusic
  else PauseMusic;

  imgMeditation.Picture.Assign(imgOn.Picture);
end;

procedure TfrmClockMain.lbSleepClick(Sender: TObject);
begin
  imgSleep.Picture.Assign(imgOff.Picture);
  Application.ProcessMessages;

  SetMusicSource(msrcSleep);

  if not FAlarmActive then PlayMusic
  else PauseMusic;

  imgSleep.Picture.Assign(imgOn.Picture);
end;

procedure TfrmClockMain.lbPlayClick(Sender: TObject);
begin
  imgPlay.Picture.Assign(imgOff.Picture);
  Application.ProcessMessages;

  case FMusicState of
    msPlaying: PauseMusic;
    else PlayMusic;
  end;

  imgPlay.Picture.Assign(imgOn.Picture);
end;

function TfrmClockMain.FormShowModal(MyForm: TForm): integer;
begin
  gdk_window_unfullscreen(PGtkWidget(Handle)^.window);

  SetCursorType(MyForm);
  Result := MyForm.ShowModal;

  if frmSettings.cbxForceFullscreen.Checked then
    gdk_window_fullscreen(PGtkWidget(Handle)^.window);
end;

procedure TfrmClockMain.lbSettingsClick(Sender: TObject);
begin
  imgSettings.Picture.Assign(imgOff.Picture);
  Application.ProcessMessages;

  FormShowModal(frmSettings);

  UpdateSettings;

  imgSettings.Picture.Assign(imgOn.Picture);
end;

procedure TfrmClockMain.lbNextClick(Sender: TObject);
begin
  imgNext.Picture.Assign(imgOff.Picture);
  Application.ProcessMessages;

  PlayMusic;

  imgNext.Picture.Assign(imgOn.Picture);
end;

procedure TfrmClockMain.lbPlayAlbumsClick(Sender: TObject);
begin
  imgPlayAlbums.Picture.Assign(imgOff.Picture);
  Application.ProcessMessages;

  PlayAlbums;

  imgPlayAlbums.Picture.Assign(imgOn.Picture);
end;

procedure TfrmClockMain.lbPreviousClick(Sender: TObject);
begin
  imgPrevious.Picture.Assign(imgOff.Picture);
  Application.ProcessMessages;

  PlayPreviousMusic;

  imgPrevious.Picture.Assign(imgOn.Picture);
end;

procedure TfrmClockMain.lbPicturesClick(Sender: TObject);
begin
  imgPictures.Picture.Assign(imgOff.Picture);
  Application.ProcessMessages;

  if frmSettings.edtPicturePath.Text = '' then
  begin
    frmSettings.PageControl1.TabIndex := 0;
    FormShowModal(frmSettings);
  end;

  if frmSettings.edtPicturePath.Text <> '' then
  begin
    if WaitForMedia(frmSettings.edtPicturePath.Text) then
    begin
      FormShowModal(frmPictures);
    end;
  end;

  imgPictures.Picture.Assign(imgOn.Picture);
end;

procedure TfrmClockMain.lblTimeClick(Sender: TObject);
begin
  if (FAlarm.State = asActive)
    or (FTimer.State = asActive)
    or (FReminderAlarm.State = asActive) then
  begin
    FAlarm.ResetAlarm;
    FTimer.ResetAlarm;
    FReminderAlarm.ResetAlarm;
  end
  else if lbWeatherSummary.Font.Color = clYellow then
  begin
    UpdateWeather;
  end;
end;

procedure TfrmClockMain.UpdateSettings;
var
  i: Integer;
  Minutes: LongInt;
  Hours: Integer;
  Player: TPlayer;
begin
  Locations[0] := frmSettings.edtLocation.Text;
  Locations[1] := frmSettings.edtLocation1.Text;
  Locations[2] := frmSettings.edtLocation2.Text;
  Locations[3] := frmSettings.edtLocation3.Text;

  FAlarm.Days[1] := frmSettings.cbxSun.Checked;
  FAlarm.Days[2] := frmSettings.cbxMon.Checked;
  FAlarm.Days[3] := frmSettings.cbxTue.Checked;
  FAlarm.Days[4] := frmSettings.cbxWed.Checked;
  FAlarm.Days[5] := frmSettings.cbxThu.Checked;
  FAlarm.Days[6] := frmSettings.cbxFri.Checked;
  FAlarm.Days[7] := frmSettings.cbxSat.Checked;

  FAlarm.AlarmTime := Date + EncodeTime(frmSettings.edtHour.Value,
    frmSettings.edtMinute.Value, 0, 0);

  FAlarm.Silent := frmSettings.cbxSilentAlarm.Checked;

  if frmSettings.TimerActive then
  begin
    for i := 0 to High(FTimer.Days) do
      FTimer.Days[i] := False;

    Minutes := StrToInt(frmSettings.stxtTimer.Caption);

    if Minutes > 0 then
    begin
      Hours := Minutes div 60;
      Minutes := Minutes mod 60;

      FTimer.AlarmTime := Now + EncodeTime(Hours,
        Minutes, 0, 0);

      FTimer.Days[DayOfWeek(FTimer.AlarmTime)] := True;
    end;

    frmSettings.TimerActive := False;
  end;

  if frmSettings.cbxGetReminders.Checked then
  begin
    frmReminderList.CanEdit := False;

    if Assigned(FSyncServer) then
      FreeAndNil(FSyncServer);

    if not Assigned(FSyncClient) then
      FSyncClient := TSyncClient.Create;
  end
  else
  begin
    frmReminderList.CanEdit := True;

    if Assigned(FSyncClient) then
      FreeAndNil(FSyncClient);

    if not Assigned(FSyncServer) then
    begin
      FSyncServer := TSyncServer.Create;
      FSyncServer.RemindersFile(frmReminders.Filename);
    end;
  end;

  case FMusicSource of
    msrcSleep:
      begin
        Player := FSleepPlayer;
      end;
    msrcMeditation:
      begin
        Player := FMeditationPlayer;
      end;
    msrcMusic:
      begin
        Player := FMusicPlayer;
      end
    else Player := nil;
  end;

  // Update search path if needed
  if Assigned(Player) then
  begin
    SetMusicSource(FMusicSource);
  end;

  FServerAddress := frmSettings.edtServerAddress.Text;
  FServerPort := frmSettings.edtServerPort.Text;

  UpdateReminders;
  SetCursorType(Self);

  if frmSettings.cbxForceFullscreen.Checked then
  begin
    BorderStyle := bsNone;
  end
  else
  begin
    BorderStyle := bsSingle;
  end;
end;

procedure TfrmClockMain.UpdateReminders;
var
  i: Integer;
begin
  if frmSettings.cbxEnableReminders.Checked then
    FCurrentReminders := frmReminders.GetCurrentReminders
  else SetLength(FCurrentReminders, 0);

  // Reminders
  for i := 1 to 7 do
    FReminderAlarm.Days[i] := Length(FCurrentReminders) > 0;

  FReminderAlarm.AlarmTime := Date + EncodeTime(frmSettings.edtRemHour.Value,
    frmSettings.edtRemMinute.Value, 0, 0);
end;

procedure TfrmClockMain.Shutdown(Reboot: boolean);
var
  Process: TProcess;
begin
  tmrWeather.Enabled := False;
  tmrTime.Enabled := False;
  tmrMinute.Enabled := False;

  Self.KeyPreview := False;

  if Reboot then lblTime.Caption := 'Rebooting ...'
  else lblTime.Caption := 'Powering Down ...';

  Application.ProcessMessages;

  PauseMusic;

  Process := TProcess.Create(nil);

  try
    if Reboot then Process.CommandLine := 'sudo /sbin/reboot'
    else Process.CommandLine := 'sudo /sbin/shutdown -h now';

    Process.Options := Process.Options + [poWaitOnExit];
    Process.Execute;
   except
    on E: Exception do
    begin
      DebugLn(Self.ClassName + #9#9 + E.Message);
    end;
  end;

  Process.Free;
end;

procedure TfrmClockMain.ConfigureWifi;
var
  Process: TProcess;
begin
  tmrWeather.Enabled := False;
  tmrTime.Enabled := False;
  tmrMinute.Enabled := False;
  Self.KeyPreview := False;

  PauseMusic;

//  Self.WindowState := wsMinimized;

  lblTime.Caption := 'Configure Wifi ...';
  lbWeatherSummary.Caption := '';
  Application.ProcessMessages;

  Process := TProcess.Create(nil);

  try
    Process.CommandLine := 'sudo /usr/local/sbin/ewoc-z2sid-term';
    Process.Options := Process.Options + [poWaitOnExit];
    Process.Execute;

    lblTime.Caption := 'Updating weather ...';

    Application.ProcessMessages;

    UpdateWeather;

    tmrWeather.Enabled := True;
    tmrTime.Enabled := True;
    tmrMinute.Enabled := True;

    AfterAlarm;

    Self.KeyPreview := True;
  except
    on E: Exception do
    begin
      DebugLn(Self.ClassName + #9#9 + E.Message);
    end;
  end;

  Process.Free;
end;

procedure TfrmClockMain.CloseApp;
var
  Process: TProcess;
begin
  tmrWeather.Enabled := False;
  tmrTime.Enabled := False;
  tmrMinute.Enabled := False;
  Self.KeyPreview := False;

  PauseMusic;

  Process := TProcess.Create(nil);

  try
    if FileExists('/usr/bin/lxpanel') then
    begin
      Process.CommandLine := '/usr/bin/lxpanel';
      Process.Execute;
    end;

    Self.Close;
  except
    on E: Exception do
    begin
      DebugLn(Self.ClassName + #9#9 + E.Message);
    end;
  end;

  Process.Free;
end;

procedure TfrmClockMain.PlayAlbums;
var
  Player: TPlayer;
  SongFile: String;
begin
  // Test is the search path has changed
  case FMusicSource of
    msrcSleep:
      begin
        Player := FSleepPlayer;
        SongFile := ChangeFileExt(FConfigFilename, '_sleep.cfg');
      end;
    msrcMeditation:
      begin
        Player := FMeditationPlayer;
        SongFile := ChangeFileExt(FConfigFilename, '_meditation.cfg');
      end;
    msrcMusic:
      begin
        Player := FMusicPlayer;
        SongFile := ChangeFileExt(FConfigFilename, '_music.cfg');
      end
    else
    begin
      Exit;
    end;
  end;

  frmPlaylist := TfrmPlaylist.Create(Self);

  frmPlaylist.LoadSongs(SongFile, Player.SearchPath);

  if FormShowModal(frmPlaylist) = mrOk then
  begin
    Player.PlaySelection(frmPlaylist.lstSelected.Items.Text, frmPlaylist.Random);
  end;

  frmPlaylist.Free;
end;

procedure TfrmClockMain.Log(Message: string);
begin
{$IFDEF LOGGING}
  DebugLn(Self.ClassName + #9#9 + Message);
{$ENDIF}
end;

{$IFDEF GRABXKEYS}
{
keycode 121 = XF86AudioMute
keycode 122 = XF86AudioLowerVolume
keycode 123 = XF86AudioRaiseVolume
keycode 171 = XF86AudioNext
Keycode 172 = XF86AudioPlay
Keycode 173 = XF86AudioPrev
Keycode 174 = XF86AudioStop
Keycode 180 = XF86HomePage
}
procedure TfrmClockMain.GrabMediaKeys;
var
  Error: Integer;
begin
  FDisplay := nil;

  Log('XOpenDisplay ...');
  FDisplay := XOpenDisplay(nil);

  if FDisplay <> nil then
  begin
    XSetErrorHandler(TXErrorHandler(XErrorHandler));

    Log('XGrabKey ...');
    Error := XGrabKey(FDisplay, XKeysymToKeycode(FDisplay, XStringToKeysym('XF86AudioPlay')),
      {ShiftMask} 0, DefaultRootWindow(FDisplay), 0, GrabModeAsync, GrabModeAsync);

    if Error = 1 then
    begin
      Log('XGrabKey ...');
      Error := XGrabKey(FDisplay, XKeysymToKeycode(FDisplay, XStringToKeysym('XF86AudioNext')),
         0, DefaultRootWindow(FDisplay), 0, GrabModeAsync, GrabModeAsync);
    end;

    if Error = 1 then
    begin
      Log('XGrabKey ...');
      Error := XGrabKey(FDisplay, XKeysymToKeycode(FDisplay, XStringToKeysym('XF86AudioMute')),
         0, DefaultRootWindow(FDisplay), 0, GrabModeAsync, GrabModeAsync);
    end;

    if Error = 1 then
    begin
      Log('XGrabKey ...');
      Error := XGrabKey(FDisplay, XKeysymToKeycode(FDisplay, XStringToKeysym('XF86HomePage')),
         0, DefaultRootWindow(FDisplay), 0, GrabModeAsync, GrabModeAsync);
    end;

    if Error = 1 then
    begin
      { select kind of events we are interested in }
      Log('XSelectInput ...');
      Error := XSelectInput(FDisplay, DefaultRootWindow(FDisplay), KeyPressMask);
      Log('XSelectInput.');
    end;

    if Error <> 1 then
    begin
      Log('GrabMediaKeys Error: ' + IntToStr(Error));
      ReleaseMediaKeys;
    end;
  end;
end;

procedure TfrmClockMain.ReleaseMediaKeys;
var
  Error: Integer;
begin
  if FDisplay = nil then
    Exit;

  Log('XCloseDisplay ...');
  Error := XCloseDisplay(FDisplay);
  Log('XCloseDisplay.');

  if Error <> 0 then
  begin
    Log('ReleaseMediaKeys Error: ' + IntToStr(Error));
  end;

  FDisplay := nil;
end;

function TfrmClockMain.GetMediaKeyPress: TMediaKey;
var
  Event: TXEvent;
begin
  Result := mkNone;

  if FDisplay = nil then
    Exit;

  Log('XCheckMaskEvent ...');
  try
    if XCheckMaskEvent(FDisplay, KeyPressMask, @Event) then
    begin
      Log('XEvent = ' + IntToStr(Event._type));

      if Event._type = 2 then
      begin
        case Event.xkey.keycode of
          171, 180: Result := mkAudioNext;
          172, 121: Result := mkAudioPlay;
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      Log('Exception GetMediaKeyPress: ' + E.Message);
      ReleaseMediaKeys;
    end;
  end;

  Log('XCheckMaskEvent.');
end;

function TfrmClockMain.XErrorHandler(para1:PDisplay; para2:PXErrorEvent):cint;cdecl;
begin
  // do nothing with error
end;

{$ENDIF}

end.

