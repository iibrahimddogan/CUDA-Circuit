#include <raylib.h>
#include <iostream>



void DrawLine(int x1, int y1, int x2, int y2) {
    DrawLineEx({(float)x1, (float)y1}, {(float)x2, (float)y2}, 3.0f, LIGHTGRAY);
}

void DrawNode(int x, int y) {
    DrawCircle(x, y, 6, RED);
}

void DrawResistorVertical(int x, int y_center, const char* label, Color color) {
    int w = 20, h = 60;
    DrawRectangleLines(x - w/2, y_center - h/2, w, h, color);
    DrawText(label, x + 20, y_center - 10, 20, GREEN); // R etiketi sağda
}

void DrawResistorHorizontal(int x_center, int y, const char* label, Color color) {
    int w = 60, h = 20;
    DrawRectangleLines(x_center - w/2, y - h/2, w, h, color);
    DrawText(label, x_center - 10, y - 35, 20, GREEN);
}

// Akım kaynağı fonksiyonuna "labelOnLeft" parametresi ekledik
void DrawCurrentSource(int x, int y, bool pointsUp, const char* label, bool labelOnLeft, Color color) {
    int radius = 30;
    DrawCircleLines(x, y, radius, color);
    
    // Ok işareti
    if (pointsUp) {
        DrawLineEx({(float)x, (float)y + 20}, {(float)x, (float)y - 15}, 2.0f, color);
        DrawTriangle({(float)x, (float)y - 25}, {(float)x - 8, (float)y - 10}, {(float)x + 8, (float)y - 10}, color);
    } else {
        DrawLineEx({(float)x, (float)y - 20}, {(float)x, (float)y + 15}, 2.0f, color);
        DrawTriangle({(float)x, (float)y + 25}, {(float)x + 8, (float)y + 10}, {(float)x - 8, (float)y + 10}, color);
    }
    
   
    if (labelOnLeft) {
        DrawText(label, x - 60, y - 10, 20, SKYBLUE); 
    } else {
        DrawText(label, x + 40, y - 10, 20, SKYBLUE); 
    }
}



int main() {
    const int screenWidth = 1200;
    const int screenHeight = 960;
    
    SetConfigFlags(FLAG_MSAA_4X_HINT);
    InitWindow(screenWidth, screenHeight, "CUDA Circuit Analyzer");
    SetTargetFPS(60);

    int y_top = 250;   
    int y_bottom = 550; 
    int y_center = 400; 
    
    int x_ig1 = 200;    
    int x_r1  = 400;    
    int x_r2_center = 550; 
    int x_r3  = 700;    
    int x_r4  = 850;    
    int x_ig2 = 1000;   

    while (!WindowShouldClose()) {
        
        BeginDrawing();
            ClearBackground((Color){ 30, 30, 30, 255 });

            DrawText("DEVRE ANALIZI", 40, 40, 24, RAYWHITE);
            

            // 1. YATAY KABLOLAR
            DrawLine(x_ig1, y_bottom, x_ig2, y_bottom); 
            DrawLine(x_ig1, y_top, x_r1, y_top);        
            DrawLine(x_r1, y_top, x_r2_center - 30, y_top); 
            DrawLine(x_r2_center + 30, y_top, x_r3, y_top); 
            DrawLine(x_r3, y_top, x_ig2, y_top);        

            // 2. DİKEY KOLLAR
            // Ig1 Kolu
            DrawLine(x_ig1, y_top, x_ig1, y_center - 30);
            DrawLine(x_ig1, y_center + 30, x_ig1, y_bottom);
            DrawCurrentSource(x_ig1, y_center, false, "Ig1", true, SKYBLUE); // Yazı SOLDAN

            // R1 Kolu
            DrawLine(x_r1, y_top, x_r1, y_center - 30);
            DrawLine(x_r1, y_center + 30, x_r1, y_bottom);
            DrawResistorVertical(x_r1, y_center, "R1", YELLOW);

            // R3 Kolu
            DrawLine(x_r3, y_top, x_r3, y_center - 30);
            DrawLine(x_r3, y_center + 30, x_r3, y_bottom);
            DrawResistorVertical(x_r3, y_center, "R3", YELLOW);

            // R4 Kolu
            DrawLine(x_r4, y_top, x_r4, y_center - 30);
            DrawLine(x_r4, y_center + 30, x_r4, y_bottom);
            DrawResistorVertical(x_r4, y_center, "R4", YELLOW);

            // Ig2 Kolu
            DrawLine(x_ig2, y_top, x_ig2, y_center - 30);
            DrawLine(x_ig2, y_center + 30, x_ig2, y_bottom);
            DrawCurrentSource(x_ig2, y_center, true, "Ig2", false, SKYBLUE); // Yazı SAĞDAN

            // 3. YATAY ELEMAN
            DrawResistorHorizontal(x_r2_center, y_top, "R2", YELLOW);

            // 4. DÜĞÜM NOKTALARI
            DrawNode(x_r1, y_top); 
            DrawNode(x_r3, y_top); 
            DrawNode(x_r4, y_top); 
            
            DrawNode(x_r1, y_bottom);
            DrawNode(x_r3, y_bottom);
            DrawNode(x_r4, y_bottom);

            // 5. VOLTAJ POLARİTELERİ VE ETİKETLERİ (Fotoğraftaki gibi)
            // R1'in solu (v1)
            DrawText("+", x_r1 - 25, y_center - 35, 20, ORANGE);
            DrawText("v1", x_r1 - 35, y_center - 10, 22, SKYBLUE); // Fotoğraftaki gibi mavi tonunda
            DrawText("-", x_r1 - 25, y_center + 20, 20, ORANGE);

            // R3'ün solu (v2)
            DrawText("+", x_r3 - 25, y_center - 35, 20, ORANGE);
            DrawText("v2", x_r3 - 35, y_center - 10, 22, SKYBLUE);
            DrawText("-", x_r3 - 25, y_center + 20, 20, ORANGE);

        EndDrawing();
    }

    CloseWindow();
    return 0;
}
