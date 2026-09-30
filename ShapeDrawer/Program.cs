using SplashKitSDK;

namespace ShapeDrawer
{
    public class Program
    {
        private enum ShapeKind
        {
            Rectangle,
            Circle,
            Line
        }

        // Student ID 25045535 -> last digit X = 5, so the L key draws 5 parallel lines
        private const int LINE_COUNT = 5;
        private const float LINE_LENGTH = 150.0f;
        private const float LINE_GAP = 15.0f;

        public static void Main()
        {
            Window window = new Window("Shape Drawer", 800, 600);
            Drawing myDrawing = new Drawing();
            ShapeKind kindToAdd = ShapeKind.Circle;

            do
            {
                SplashKit.ProcessEvents();
                SplashKit.ClearScreen();

                if (SplashKit.KeyTyped(KeyCode.RKey))
                {
                    kindToAdd = ShapeKind.Rectangle;
                }

                if (SplashKit.KeyTyped(KeyCode.CKey))
                {
                    kindToAdd = ShapeKind.Circle;
                }

                if (SplashKit.KeyTyped(KeyCode.LKey))
                {
                    kindToAdd = ShapeKind.Line;
                }

                if (SplashKit.MouseClicked(MouseButton.LeftButton))
                {
                    float mouseX = SplashKit.MouseX();
                    float mouseY = SplashKit.MouseY();

                    if (kindToAdd == ShapeKind.Line)
                    {
                        for (int i = 0; i < LINE_COUNT; i++)
                        {
                            float y = mouseY + i * LINE_GAP;
                            myDrawing.AddShape(new MyLine(Color.Red, mouseX, y, mouseX + LINE_LENGTH, y));
                        }
                    }
                    else
                    {
                        Shape newShape;
                        switch (kindToAdd)
                        {
                            case ShapeKind.Rectangle:
                                newShape = new MyRectangle();
                                break;
                            default:
                                newShape = new MyCircle();
                                break;
                        }

                        newShape.X = mouseX;
                        newShape.Y = mouseY;
                        myDrawing.AddShape(newShape);
                    }
                }

                if (SplashKit.KeyTyped(KeyCode.SpaceKey))
                {
                    myDrawing.Background = SplashKit.RandomRGBColor(255);
                }

                if (SplashKit.MouseClicked(MouseButton.RightButton))
                {
                    myDrawing.SelectShapesAt(SplashKit.MousePosition());
                }

                if (SplashKit.KeyTyped(KeyCode.DeleteKey) || SplashKit.KeyTyped(KeyCode.BackspaceKey))
                {
                    foreach (Shape s in myDrawing.SelectedShapes)
                    {
                        myDrawing.RemoveShape(s);
                    }
                }

                myDrawing.Draw();
                SplashKit.RefreshScreen();
            } while (!window.CloseRequested);
        }
    }
}
