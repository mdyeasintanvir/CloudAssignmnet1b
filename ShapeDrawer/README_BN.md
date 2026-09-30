# Task 6.1 – ShapeDrawer (Multiple Shape Kinds)

Student ID: 25045535 → **XX = 35**, **X = 5**
- MyRectangle default: Green, 135 x 135 (100 + 35)
- MyCircle default: Blue, radius 85 (50 + 35)
- L key → 5 parallel red lines per click

## Controls
| Key/Mouse | Action |
|---|---|
| R | Rectangle mode |
| C | Circle mode (default) |
| L | Line mode (5 parallel lines) |
| Left click | Add shape at mouse |
| Right click | Select shape(s) at mouse |
| Delete / Backspace | Delete selected |
| Space | Random background colour |

## Nijer project e bosano
Tomar 5.1 project folder e `Shape.cs`, `Drawing.cs`, `Program.cs` replace koro, ar
`MyRectangle.cs`, `MyCircle.cs`, `MyLine.cs` add koro. Namespace `ShapeDrawer` —
tomar project er namespace alada hole shob file e change koro. Tarpor `dotnet run`.

## Interview er jonno
- **Inheritance ("is-a")**: MyRectangle/MyCircle/MyLine `: Shape` — X, Y, Color, Selected base theke pay.
- **Abstract class**: `Shape` er object banano jay na (`new Shape()` error).
- **Abstract method**: Draw/DrawOutline/IsAt er body nai; subclass `override` korte baddho. Abstract method implicitly virtual.
- **Polymorphism (subtype)**: `Shape newShape = new MyCircle();` — `Drawing` shudhu `List<Shape>` rakhe, `s.Draw()` call korle runtime e thik subclass er Draw chole (dynamic dispatch).
- **base(...) call**: subclass constructor theke base class er private `_color` initialize kora.
- **this(...) call**: default constructor onno constructor ke call kore (code duplication kome).
- **Enum ShapeKind**: Program er vitore private nested type.
- Circle IsAt: `SplashKit.PointInCircle(pt, SplashKit.CircleAt(X, Y, radius))`
- Line IsAt: `SplashKit.PointOnLine(pt, SplashKit.LineFrom(X, Y, EndX, EndY))`
