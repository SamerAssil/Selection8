unit Tulip.Selection8;

interface
uses
  System.SysUtils,
  System.Classes,
  System.Types,
  System.UITypes,
  System.Math,
  System.Math.Vectors,
  System.UIConsts,
  FMX.Types,
  FMX.Graphics,
  FMX.Controls;

Type
{ TSelection8 }

  TSelection8 = class(TControl)
  public const
    DefaultColor = $FF1072C5;
  public type
    TGrabHandle = (None, LeftTop, RightTop, LeftBottom, RightBottom, Top, Right, Left, Bottom);
  private
    FParentBounds: Boolean;
    FOnChange: TNotifyEvent;
    FHideSelection: Boolean;
    FMinSize: Integer;
    FOnTrack: TNotifyEvent;
    FProportional: Boolean;
    FGripSize: Single;
    FRatio: Single;
    FActiveHandle: TGrabHandle;
    FHotHandle: TGrabHandle;
    FDownPos: TPointF;
    FShowHandles: Boolean;
    FColor: TAlphaColor;
    procedure SetHideSelection(const Value: Boolean);
    procedure SetMinSize(const Value: Integer);
    procedure SetGripSize(const Value: Single);
    procedure ResetInSpace(const ARotationPoint: TPointF; ASize: TPointF);
    function GetProportionalSize(const ASize: TPointF): TPointF;
    function GetHandleForPoint(const P: TPointF): TGrabHandle;

    procedure GetTransformLeftTop(AX, AY: Single; var NewSize: TPointF; var Pivot: TPointF);
    procedure GetTransformLeftBottom(AX, AY: Single; var NewSize: TPointF; var Pivot: TPointF);
    procedure GetTransformRightTop(AX, AY: Single; var NewSize: TPointF; var Pivot: TPointF);
    procedure GetTransformRightBottom(AX, AY: Single; var NewSize: TPointF; var Pivot: TPointF);

    procedure MoveHandle(AX, AY: Single);
    procedure SetShowHandles(const Value: Boolean);
    procedure SetColor(const Value: TAlphaColor);
  protected
    function DoGetUpdateRect: TRectF; override;
    procedure Paint; override;
    ///<summary>Draw grip handle</summary>
    procedure DrawHandle(const Canvas: TCanvas; const Handle: TGrabHandle; const Rect: TRectF); virtual;
    ///<summary>Draw frame rectangle</summary>
    procedure DrawFrame(const Canvas: TCanvas; const Rect: TRectF); virtual;
  public
    function PointInObjectLocal(X, Y: Single): Boolean; override;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure DoMouseLeave; override;
    ///<summary>Grip handle where mouse is hovered</summary>
    property HotHandle: TGrabHandle read FHotHandle;
  published
    property Align;
    property Anchors;
    property ClipChildren default False;
    property ClipParent default False;
    property Cursor default crDefault;
    ///<summary>Selection frame and handle's border color</summary>
    property Color: TAlphaColor read FColor write SetColor default DefaultColor;
    property DragMode default TDragMode.dmManual;
    property EnableDragHighlight default True;
    property Enabled default True;
    property GripSize: Single read FGripSize write SetGripSize;
    property Locked default False;
    property Height;
    property HideSelection: Boolean read FHideSelection write SetHideSelection;
    property Hint;
    property HitTest default True;
    property Padding;
    property MinSize: Integer read FMinSize write SetMinSize default 15;
    property Opacity;
    property Margins;
    property ParentBounds: Boolean read FParentBounds write FParentBounds default True;
    property Proportional: Boolean read FProportional write FProportional;
    property PopupMenu;
    property Position;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    property Size;
    ///<summary>Indicates visibility of handles</summary>
    property ShowHandles: Boolean read FShowHandles write SetShowHandles;
    property Visible default True;
    property Width;
    property ParentShowHint;
    property ShowHint;
    property TouchTargetExpansion;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    {Drag and Drop events}
    property OnDragEnter;
    property OnDragLeave;
    property OnDragOver;
    property OnDragDrop;
    property OnDragEnd;
    {Mouse events}
    property OnClick;
    property OnDblClick;

    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseEnter;
    property OnMouseLeave;

    property OnPainting;
    property OnPaint;
    property OnResize;
    property OnResized;
    property OnTrack: TNotifyEvent read FOnTrack write FOnTrack;
  end;


procedure Register;

implementation


procedure Register;
begin
  RegisterComponents('Tulip', [TSelection8]);
end;

{ TSelection8 }

constructor TSelection8.Create(AOwner: TComponent);
begin
  inherited;
  AutoCapture := True;
  ParentBounds := True;
  FColor := DefaultColor;
  FShowHandles := True;
  FMinSize := 15;
  FGripSize := 3;
  SetAcceptsControls(False);
end;

destructor TSelection8.Destroy;
begin
  inherited;
end;

function TSelection8.GetProportionalSize(const ASize: TPointF): TPointF;
begin
  Result := ASize;
  if FRatio * Result.Y  > Result.X  then
  begin
    if Result.X < FMinSize then
      Result.X := FMinSize;
    Result.Y := Result.X / FRatio;
    if Result.Y < FMinSize then
    begin
      Result.Y := FMinSize;
      Result.X := FMinSize * FRatio;
    end;
  end
  else
  begin
    if Result.Y < FMinSize then
      Result.Y := FMinSize;
    Result.X := Result.Y * FRatio;
    if Result.X < FMinSize then
    begin
      Result.X := FMinSize;
      Result.Y := FMinSize / FRatio;
    end;
  end;
end;

function TSelection8.GetHandleForPoint(const P: TPointF): TGrabHandle;
var
  Local, R: TRectF;
begin
  Local := LocalRect;
  R := TRectF.Create(Local.Left - GripSize, Local.Top - GripSize, Local.Left + GripSize, Local.Top + GripSize);
  if R.Contains(P) then
    Exit(TGrabHandle.LeftTop);
  R := TRectF.Create(Local.Right - GripSize, Local.Top - GripSize, Local.Right + GripSize, Local.Top + GripSize);
  if R.Contains(P) then
    Exit(TGrabHandle.RightTop);
  R := TRectF.Create(Local.Right - GripSize, Local.Bottom - GripSize, Local.Right + GripSize, Local.Bottom + GripSize);
  if R.Contains(P) then
    Exit(TGrabHandle.RightBottom);
  R := TRectF.Create(Local.Left - GripSize, Local.Bottom - GripSize, Local.Left + GripSize, Local.Bottom + GripSize);
  if R.Contains(P) then
    Exit(TGrabHandle.LeftBottom);

  {Top}
  R := TRectF.Create((Local.Width/2) - GripSize, Local.Top - GripSize, (Local.Width/2) + GripSize ,Local.Top + GripSize);
  if R.Contains(P) then
    Exit(TGrabHandle.Top);

  {Bottom}
  R := TRectF.Create((Local.Width/2) - GripSize, Local.Height - GripSize, (Local.Width/2) + GripSize ,Local.Height + GripSize);
  if R.Contains(P) then
    Exit(TGrabHandle.Bottom);

  {Left}
  R := TRectF.Create(Local.Left - GripSize, (Local.Height/2) - GripSize, Local.Left + GripSize, (Local.Height/2) + GripSize);
  if R.Contains(P) then
    Exit(TGrabHandle.left);

  {Right}
  R := TRectF.Create(Local.Width - GripSize, (Local.Height/2) - GripSize, Local.Width + GripSize, (Local.Height/2) + GripSize);
  if R.Contains(P) then
    Exit(TGrabHandle.Right);

  Result := TGrabHandle.None;
end;


procedure TSelection8.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  // this line may be necessary because TSelection8 is not a styled control;
  // must further investigate for a better fix
  if not Enabled then
    Exit;

  inherited;

  FDownPos := TPointF.Create(X, Y);
  if Button = TMouseButton.mbLeft then
  begin
    FRatio := Width / Height;
    FActiveHandle := GetHandleForPoint(FDownPos);
  end;
end;

procedure TSelection8.MouseMove(Shift: TShiftState; X, Y: Single);
var
  MoveVector: TVector;
  MovePos: TPointF;
  GrabHandle: TGrabHandle;
begin
  // this line may be necessary because TSelection8 is not a styled control;
  // must further investigate for a better fix
  if not Enabled then
    Exit;

  inherited;

  MovePos := TPointF.Create(X, Y);
  if not Pressed then
  begin
    // handle painting for hotspot mouse hovering
    GrabHandle := GetHandleForPoint(MovePos);
    if GrabHandle <> FHotHandle then
      Repaint;
    FHotHandle := GrabHandle;
  end
  else if ssLeft in Shift then
  begin
    if FActiveHandle = TGrabHandle.None then
    begin
      MoveVector := LocalToAbsoluteVector(TVector.Create(X - FDownPos.X, Y - FDownPos.Y));
      if ParentControl <> nil then
        MoveVector := ParentControl.AbsoluteToLocalVector(MoveVector);
      Position.Point := Position.Point + TPointF(MoveVector);
      if ParentBounds then
      begin
        if Position.X < 0 then
          Position.X := 0;
        if Position.Y < 0 then
          Position.Y := 0;
        if ParentControl <> nil then
        begin
          if Position.X + Width > ParentControl.Width then
            Position.X := ParentControl.Width - Width;
          if Position.Y + Height > ParentControl.Height then
            Position.Y := ParentControl.Height - Height;
        end
        else
          if Canvas <> nil then
          begin
            if Position.X + Width > Canvas.Width then
              Position.X := Canvas.Width - Width;
            if Position.Y + Height > Canvas.Height then
              Position.Y := Canvas.Height - Height;
          end;
      end;
      if Assigned(FOnTrack) then
        FOnTrack(Self);
      Exit;
    end;
    MoveHandle(X, Y);
  end;
end;

function TSelection8.PointInObjectLocal(X, Y: Single): Boolean;
begin
  Result := inherited or (GetHandleForPoint(TPointF.Create(X, Y)) <> TGrabHandle.None);
end;

procedure TSelection8.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  // this line may be necessary because TSelection8 is not a styled control;
  // must further investigate for a better fix
  if not Enabled then
    Exit;

  inherited;

  if Assigned(FOnChange) then
    FOnChange(Self);
  FActiveHandle := TGrabHandle.None;
end;

procedure TSelection8.DrawFrame(const Canvas: TCanvas; const Rect: TRectF);
begin
  Canvas.DrawDashRect(Rect, 0, 0, AllCorners, AbsoluteOpacity, FColor);
end;

procedure TSelection8.DrawHandle(const Canvas: TCanvas; const Handle: TGrabHandle; const Rect: TRectF);
var
  Fill: TBrush;
  Stroke: TStrokeBrush;
  SavedFillColor: TAlphaColor;
begin
  Fill := TBrush.Create(TBrushKind.Solid, claWhite);
  Stroke := TStrokeBrush.Create(TBrushKind.Solid, FColor);
  try
    SavedFillColor := Fill.Color;
    try
      if Enabled then
        if FHotHandle = Handle then
          Fill.Color := claRed
        else
          Fill.Color := claWhite
      else
        Fill.Color := claGrey;

      Canvas.FillEllipse(Rect, AbsoluteOpacity, Fill);
      Canvas.DrawEllipse(Rect, AbsoluteOpacity, Stroke);
    finally
      Fill.Color := SavedFillColor;
    end;
  finally
    Fill.Free;
    Stroke.Free;
  end;
end;

procedure TSelection8.Paint;
var
  R: TRectF;
begin
  if FHideSelection then
    Exit;

  R := LocalRect;
  R.Inflate(-0.5, -0.5);
  DrawFrame(Canvas, R);

  if ShowHandles then
  begin
    R := LocalRect;
    DrawHandle(Canvas, TGrabHandle.LeftTop, TRectF.Create(R.Left - GripSize, R.Top - GripSize, R.Left + GripSize,
      R.Top + GripSize));
    DrawHandle(Canvas, TGrabHandle.RightTop, TRectF.Create(R.Right - GripSize, R.Top - GripSize, R.Right + GripSize,
      R.Top + GripSize));
    DrawHandle(Canvas, TGrabHandle.LeftBottom, TRectF.Create(R.Left - GripSize, R.Bottom - GripSize, R.Left + GripSize,
      R.Bottom + GripSize));
    DrawHandle(Canvas, TGrabHandle.RightBottom, TRectF.Create(R.Right - GripSize, R.Bottom - GripSize,
      R.Right + GripSize, R.Bottom + GripSize));

    {Top}
    DrawHandle(Canvas, TGrabHandle.Top, TRectF.Create(
              (R.Width / 2) - GripSize ,
              R.Top - GripSize,
              (R.Width / 2) + GripSize,
              R.Top + GripSize));
    {bottom}
    DrawHandle(Canvas, TGrabHandle.Bottom, TRectF.Create(
              (R.Width / 2) - GripSize ,
              R.Height - GripSize,
              (R.Width / 2) + GripSize,
              R.Height + GripSize));
    {Left}
    DrawHandle(Canvas, TGrabHandle.Left, TRectF.Create(
            R.Left - GripSize,
            (R.Height / 2) - GripSize,
            R.Left + GripSize,
            (R.Height / 2) + GripSize));

     {Right}
    DrawHandle(Canvas, TGrabHandle.Right, TRectF.Create(
            R.Width - GripSize,
            (R.Height / 2) - GripSize,
            R.Width + GripSize,
            (R.Height / 2) + GripSize));
  end;
end;

function TSelection8.DoGetUpdateRect: TRectF;
begin
  Result := inherited;
  Result.Inflate((FGripSize + 1) * Scale.X, (FGripSize + 1) * Scale.Y);
end;

procedure TSelection8.ResetInSpace(const ARotationPoint: TPointF; ASize: TPointF);
var
  LLocalPos: TPointF;
  LAbsPos: TPointF;
begin
  LAbsPos := LocalToAbsolute(ARotationPoint);
  if ParentControl <> nil then
  begin
    LLocalPos := ParentControl.AbsoluteToLocal(LAbsPos);
    LLocalPos.X := LLocalPos.X - ASize.X * RotationCenter.X * Scale.X;
    LLocalPos.Y := LLocalPos.Y - ASize.Y * RotationCenter.Y * Scale.Y;
    if ParentBounds then
    begin
      if LLocalPos.X < 0 then
      begin
        ASize.X := ASize.X + LLocalPos.X;
        LLocalPos.X := 0;
      end;
      if LLocalPos.Y < 0 then
      begin
        ASize.Y := ASize.Y + LLocalPos.Y;
        LLocalPos.Y := 0;
      end;
      if LLocalPos.X + ASize.X > ParentControl.Width then
        ASize.X := ParentControl.Width - LLocalPos.X;
      if LLocalPos.Y + ASize.Y > ParentControl.Height then
        ASize.Y := ParentControl.Height - LLocalPos.Y;
    end;
  end
  else
  begin
    LLocalPos.X := LAbsPos.X - ASize.X * RotationCenter.X * Scale.X;
    LLocalPos.Y := LAbsPos.Y - ASize.Y * RotationCenter.Y * Scale.Y;
  end;
  SetBounds(LLocalPos.X, LLocalPos.Y, ASize.X, ASize.Y);
end;

procedure TSelection8.GetTransformLeftTop(AX, AY: Single; var NewSize: TPointF; var Pivot: TPointF);
var
  LCorrect: TPointF;
begin
  NewSize := Size.Size - TSizeF.Create(AX, AY);
  if NewSize.Y < FMinSize then
  begin
    AY := Height - FMinSize;
    NewSize.Y := FMinSize;
  end;
  if NewSize.X < FMinSize then
  begin
    AX := Width - FMinSize;
    NewSize.X := FMinSize;
  end;
  if FProportional then
  begin
    LCorrect := NewSize;
    NewSize := GetProportionalSize(NewSize);
    LCorrect := LCorrect - NewSize;
    AX := AX + LCorrect.X;
    AY := AY + LCorrect.Y;
  end;
  Pivot := TPointF.Create(Width * RotationCenter.X + AX * (1 - RotationCenter.X),
    Height * RotationCenter.Y + AY * (1 - RotationCenter.Y));
end;


procedure TSelection8.GetTransformLeftBottom(AX, AY: Single; var NewSize: TPointF; var Pivot: TPointF);
var
  LCorrect: TPointF;
begin
  NewSize := TPointF.Create(Width - AX, AY);
  if NewSize.Y < FMinSize then
  begin
    AY := FMinSize;
    NewSize.Y := FMinSize;
  end;
  if NewSize.X < FMinSize then
  begin
    AX := Width - FMinSize;
    NewSize.X := FMinSize;
  end;
  if FProportional then
  begin
    LCorrect := NewSize;
    NewSize := GetProportionalSize(NewSize);
    LCorrect := LCorrect - NewSize;
    AX := AX + LCorrect.X;
    AY := AY - LCorrect.Y;
  end;
  Pivot := TPointF.Create(Width * RotationCenter.X + AX * (1 - RotationCenter.X),
    Height * RotationCenter.Y + (AY - Height) * RotationCenter.Y);
end;

procedure TSelection8.GetTransformRightTop(AX, AY: Single; var NewSize: TPointF; var Pivot: TPointF);
var
  LCorrect: TPointF;
begin
  NewSize := TPointF.Create(AX, Height - AY);
  if NewSize.Y < FMinSize then
  begin
    AY := Height - FMinSize;
    NewSize.Y := FMinSize;
  end;
  if AX < FMinSize then
  begin
    AX := FMinSize;
    NewSize.X := FMinSize;
  end;
  if FProportional then
  begin
    LCorrect := NewSize;
    NewSize := GetProportionalSize(NewSize);
    LCorrect := LCorrect - NewSize;
    AX := AX - LCorrect.X;
    AY := AY + LCorrect.Y;
  end;
  Pivot := TPointF.Create(Width * RotationCenter.X + (AX - Width) * RotationCenter.X,
    Height * RotationCenter.Y + AY * (1 - RotationCenter.Y));
end;

procedure TSelection8.GetTransformRightBottom(AX, AY: Single; var NewSize: TPointF; var Pivot: TPointF);
var
  LCorrect: TPointF;
begin
  NewSize := TPointF.Create(AX, AY);
  if NewSize.Y < FMinSize then
  begin
    AY := FMinSize;
    NewSize.Y := FMinSize;
  end;
  if NewSize.X < FMinSize then
  begin
    AX := FMinSize;
    NewSize.X := FMinSize;
  end;
  if FProportional then
  begin
    LCorrect := NewSize;
    NewSize := GetProportionalSize(NewSize);
    LCorrect := LCorrect - NewSize;
    AX := AX - LCorrect.X;
    AY := AY - LCorrect.Y;
  end;
  Pivot := TPointF.Create(Width * RotationCenter.X + (AX - Width) * RotationCenter.X,
    Height * RotationCenter.Y + (AY - Height) * RotationCenter.Y);
end;

procedure TSelection8.MoveHandle(AX, AY: Single);
var
  NewSize, Pivot: TPointF;
begin
  case FActiveHandle of
    TSelection8.TGrabHandle.LeftTop: GetTransformLeftTop(AX, AY, NewSize, Pivot);
    TSelection8.TGrabHandle.LeftBottom: GetTransformLeftBottom(AX, AY, NewSize, Pivot);
    TSelection8.TGrabHandle.RightTop: GetTransformRightTop(AX, AY, NewSize, Pivot);
    TSelection8.TGrabHandle.RightBottom: GetTransformRightBottom(AX, AY, NewSize, Pivot);
    TSelection8.TGrabHandle.Top: GetTransformLeftTop(0, AY, NewSize, Pivot);
    TSelection8.TGrabHandle.left: GetTransformLeftTop(AX, 0, NewSize, Pivot);
    TSelection8.TGrabHandle.Right: GetTransformRightTop(AX, 0, NewSize, Pivot);
    TSelection8.TGrabHandle.Bottom: GetTransformLeftBottom(0, AY, NewSize, Pivot);
  end;
  ResetInSpace(Pivot, NewSize);
  if Assigned(FOnTrack) then
    FOnTrack(Self);
end;

procedure TSelection8.DoMouseLeave;
begin
  inherited;
  FHotHandle := TGrabHandle.None;
  Repaint;
end;

procedure TSelection8.SetHideSelection(const Value: Boolean);
begin
  if FHideSelection <> Value then
  begin
    FHideSelection := Value;
    Repaint;
  end;
end;

procedure TSelection8.SetMinSize(const Value: Integer);
begin
  if FMinSize <> Value then
  begin
    FMinSize := Value;
    if FMinSize < 1 then
      FMinSize := 1;
  end;
end;

procedure TSelection8.SetShowHandles(const Value: Boolean);
begin
  if FShowHandles <> Value then
  begin
    FShowHandles := Value;
    Repaint;
  end;
end;

procedure TSelection8.SetColor(const Value: TAlphaColor);
begin
  if FColor <> Value then
  begin
    FColor := Value;
    Repaint;
  end;
end;

procedure TSelection8.SetGripSize(const Value: Single);
begin
  if not SameValue(FGripSize, Value, TEpsilon.Position) then
  begin
    if Value < FGripSize then
      Repaint;
    FGripSize := EnsureRange(Value, 1, 20);
    HandleSizeChanged;
    Repaint;
  end;
end;

end.
