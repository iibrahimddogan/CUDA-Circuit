#include <raylib.h>
#include <iostream>

#include "../lib/cuda_matrix/matrix_math.cuh"

void DrawLine(int x1, int y1, int x2, int y2)
{
    DrawLineEx({(float)x1, (float)y1}, {(float)x2, (float)y2}, 3.0f, LIGHTGRAY);
}

void DrawNode(int x, int y)
{
    DrawCircle(x, y, 6, RED);
}

void DrawResistorVertical(int x, int y_center, const char *label, Color color)
{
    int w = 20, h = 60;
    DrawRectangleLines(x - w / 2, y_center - h / 2, w, h, color);
    DrawText(label, x + 20, y_center - 10, 18, GREEN);
}

void DrawResistorHorizontal(int x_center, int y, const char *label, Color color)
{
    int w = 60, h = 20;
    DrawRectangleLines(x_center - w / 2, y - h / 2, w, h, color);
    DrawText(label, x_center - 50, y - 40, 18, GREEN);
}

void DrawCurrentSource(int x, int y, bool pointsUp, const char *label, bool labelOnLeft, Color color)
{
    int radius = 30;
    DrawCircleLines(x, y, radius, color);

    if (pointsUp)
    {
        DrawLineEx({(float)x, (float)y + 20}, {(float)x, (float)y - 15}, 2.0f, color);
        DrawTriangle({(float)x, (float)y - 25}, {(float)x - 8, (float)y - 10}, {(float)x + 8, (float)y - 10}, color);
    }
    else
    {
        DrawLineEx({(float)x, (float)y - 20}, {(float)x, (float)y + 15}, 2.0f, color);
        DrawTriangle({(float)x, (float)y + 25}, {(float)x + 8, (float)y + 10}, {(float)x - 8, (float)y + 10}, color);
    }

    if (labelOnLeft)
    {
        DrawText(label, x - 110, y - 10, 18, SKYBLUE);
    }
    else
    {
        DrawText(label, x + 40, y - 10, 18, SKYBLUE);
    }
}

int main()
{
    const int screenWidth = 1600;
    const int screenHeight = 960;

    SetConfigFlags(FLAG_MSAA_4X_HINT);
    InitWindow(screenWidth, screenHeight, "CUDA Circuit Analyzer");
    SetTargetFPS(60);

    float R1 = 25.0f, R2 = 5.0f, R3 = 50.0f, R4 = 75.0f;
    float Ig1 = 12.0f, Ig2 = 16.0f;

    int selected_item = 0;

    // matrisler
    CudaMatrix G;
    G.row = 2;
    G.col = 2;
    G.data = new float[4];
    CudaMatrix G_inv;
    G_inv.row = 2;
    G_inv.col = 2;
    G_inv.data = new float[4];
    CudaMatrix I_mat;
    I_mat.row = 2;
    I_mat.col = 1;
    I_mat.data = new float[2];
    CudaMatrix V_mat;
    V_mat.row = 2;
    V_mat.col = 1;
    V_mat.data = new float[2];

    // duyarlilik analizi
    CudaMatrix dG_dR1;
    dG_dR1.row = 2;
    dG_dR1.col = 2;
    dG_dR1.data = new float[4];
    CudaMatrix Temp1;
    Temp1.row = 2;
    Temp1.col = 1;
    Temp1.data = new float[2];
    CudaMatrix Temp2;
    Temp2.row = 2;
    Temp2.col = 1;
    Temp2.data = new float[2];

    // R2 duyarliligi icin matrisler
    CudaMatrix dG_dR2;
    dG_dR2.row = 2;
    dG_dR2.col = 2;
    dG_dR2.data = new float[4];
    CudaMatrix dV_dR2_mat;
    dV_dR2_mat.row = 2;
    dV_dR2_mat.col = 1;
    dV_dR2_mat.data = new float[2];

    // Akim kaynaklari duyarliligi icin (dI/dIg) vektorleri
    CudaMatrix dI_dIg1;
    dI_dIg1.row = 2;
    dI_dIg1.col = 1;
    dI_dIg1.data = new float[2];
    CudaMatrix dI_dIg2;
    dI_dIg2.row = 2;
    dI_dIg2.col = 1;
    dI_dIg2.data = new float[2];
    CudaMatrix dV_dIg1_mat;
    dV_dIg1_mat.row = 2;
    dV_dIg1_mat.col = 1;
    dV_dIg1_mat.data = new float[2];
    CudaMatrix dV_dIg2_mat;
    dV_dIg2_mat.row = 2;
    dV_dIg2_mat.col = 1;
    dV_dIg2_mat.data = new float[2];

    int offset_x = 50;
    int y_top = 250;
    int y_bottom = 550;
    int y_center = 400;

    int x_ig1 = 150 + offset_x;
    int x_r1 = 400 + offset_x;
    int x_r2_center = 575 + offset_x;
    int x_r3 = 750 + offset_x;
    int x_r4 = 950 + offset_x;
    int x_ig2 = 1100 + offset_x;

    int panelX = 1280;

    while (!WindowShouldClose())
    {

        if (IsKeyPressed(KEY_RIGHT))
        {
            selected_item = (selected_item + 1) % 6;
        }
        if (IsKeyPressed(KEY_LEFT))
        {
            selected_item = (selected_item - 1 + 6) % 6;
        }

        if (IsKeyPressed(KEY_UP))
        {
            switch (selected_item)
            {
            case 0:
                R1 += 0.5f;
                break;
            case 1:
                R2 += 1.0f;
                break;
            case 2:
                R3 += 1.0f;
                break;
            case 3:
                R4 += 1.0f;
                break;
            case 4:
                Ig1 += 1.0f;
                break;
            case 5:
                Ig2 += 1.0f;
                break;
            }
        }
        if (IsKeyPressed(KEY_DOWN))
        {
            switch (selected_item)
            {
            case 0:
                if (R1 > 1.0f)
                    R1 -= 1.0f;
                break;
            case 1:
                if (R2 > 1.0f)
                    R2 -= 1.0f;
                break;
            case 2:
                if (R3 > 1.0f)
                    R3 -= 1.0f;
                break;
            case 3:
                if (R4 > 1.0f)
                    R4 -= 1.0f;
                break;
            case 4:
                Ig1 -= 1.0f;
                break;
            case 5:
                Ig2 -= 1.0f;
                break;
            }
        }

        // iletkenlik matrisi
        G.data[0] = (1.0f / R1) + (1.0f / R2); // 1. dugum
        G.data[1] = (-1.0f / R2);                // ortak direncler. kurala gore - yazilir
        G.data[2] = (-1.0f / R2);
        G.data[3] = (1.0f / R2) + (1.0f / R3) + (1.0f / R4); // 2. dugum

        I_mat.data[0] = -Ig1; // dugum 1 e giren akim, ters oldugundan -
        I_mat.data[1] = Ig2;  // dugum 2 ye giren akim

        for (int i = 0; i < 4; i++)
        {
            G_inv.data[i] = G.data[i];
        }

        reverse_2x2_matrix(G_inv);
        mulofmatrix(G_inv, I_mat, V_mat); // iletkenligin tersi * akim = V matrisi / V = G^-1 * I

        float v1_result = V_mat.data[0];
        float v2_result = V_mat.data[1];

        // duyarlilik r1 icin
        dG_dR1.data[0] = -1.0f / (R1 * R1); // G.data[0] ın  R1 e gore kismi turevi. digerlerinde R1 yok. "-" integralden geliyor
        dG_dR1.data[1] = 0.0f;
        dG_dR1.data[2] = 0.0f;
        dG_dR1.data[3] = 0.0f;

        // dV = -G^-1 * (dG/dR1 * V)
        mulofmatrix(dG_dR1, V_mat, Temp1);
        mulofmatrix(G_inv, Temp1, Temp2);
        mul_scalar(Temp2, -1.0f);

        float dV1_dR1 = Temp2.data[0];
        float dV2_dR1 = Temp2.data[1];

        // --- R2 Icin Duyarlilik ---
        dG_dR2.data[0] = -1.0f / (R2 * R2);
        dG_dR2.data[1] = 1.0f / (R2 * R2); // Isaretler degisir cunku normalde -1/R2 yaziyoruz
        dG_dR2.data[2] = 1.0f / (R2 * R2);
        dG_dR2.data[3] = -1.0f / (R2 * R2);

        mulofmatrix(dG_dR2, V_mat, Temp1);
        mulofmatrix(G_inv, Temp1, Temp2);
        mul_scalar(Temp2, -1.0f);

        float dV1_dR2 = Temp2.data[0];
        float dV2_dR2 = Temp2.data[1];

        // --- Ig1 Icin Duyarlilik ---
        // I_mat.data[0] = -Ig1 oldugundan, Ig1'e gore turevi -1 olur.
        dI_dIg1.data[0] = -1.0f;
        dI_dIg1.data[1] = 0.0f;
        mulofmatrix(G_inv, dI_dIg1, dV_dIg1_mat);
        float dV1_dIg1 = dV_dIg1_mat.data[0];
        float dV2_dIg1 = dV_dIg1_mat.data[1];

        // --- Ig2 Icin Duyarlilik ---
        // I_mat.data[1] = Ig2 oldugundan, Ig2'ye gore turevi 1 olur.
        dI_dIg2.data[0] = 0.0f;
        dI_dIg2.data[1] = 1.0f;
        mulofmatrix(G_inv, dI_dIg2, dV_dIg2_mat);
        float dV1_dIg2 = dV_dIg2_mat.data[0];
        float dV2_dIg2 = dV_dIg2_mat.data[1];

        BeginDrawing();
        ClearBackground((Color){30, 30, 30, 255});
        DrawText("CUDA TABANLI DEVRE ANALIZI", 40, 40, 24, RAYWHITE);

        DrawLine(x_ig1, y_bottom, x_ig2, y_bottom);
        DrawLine(x_ig1, y_top, x_r1, y_top);
        DrawLine(x_r1, y_top, x_r2_center - 30, y_top);
        DrawLine(x_r2_center + 30, y_top, x_r3, y_top);
        DrawLine(x_r3, y_top, x_ig2, y_top);
        DrawLine(x_ig1, y_top, x_ig1, y_center - 30);
        DrawLine(x_ig1, y_center + 30, x_ig1, y_bottom);
        DrawLine(x_r1, y_top, x_r1, y_center - 30);
        DrawLine(x_r1, y_center + 30, x_r1, y_bottom);
        DrawLine(x_r3, y_top, x_r3, y_center - 30);
        DrawLine(x_r3, y_center + 30, x_r3, y_bottom);
        DrawLine(x_r4, y_top, x_r4, y_center - 30);
        DrawLine(x_r4, y_center + 30, x_r4, y_bottom);
        DrawLine(x_ig2, y_top, x_ig2, y_center - 30);
        DrawLine(x_ig2, y_center + 30, x_ig2, y_bottom);

        DrawCurrentSource(x_ig1, y_center, false, TextFormat("Ig1: %.1f A", Ig1), true, SKYBLUE);
        DrawCurrentSource(x_ig2, y_center, true, TextFormat("Ig2: %.1f A", Ig2), false, SKYBLUE);

        DrawResistorVertical(x_r1, y_center, TextFormat("R1: %.1f Ohm", R1), YELLOW);
        DrawResistorVertical(x_r3, y_center, TextFormat("R3: %.1f Ohm", R3), YELLOW);
        DrawResistorVertical(x_r4, y_center, TextFormat("R4: %.1f Ohm", R4), YELLOW);
        DrawResistorHorizontal(x_r2_center, y_top, TextFormat("R2: %.1f Ohm", R2), YELLOW);

        DrawNode(x_r1, y_top);
        DrawNode(x_r3, y_top);
        DrawNode(x_r4, y_top);

        DrawText(TextFormat("V1 = %.4f V", v1_result), x_r1 - 80, y_top - 70, 24, RED);
        DrawText(TextFormat("V2 = %.4f V", v2_result), x_r3 - 80, y_top - 70, 24, RED);
        DrawText(TextFormat("V2 = %.4f V", v2_result), x_r4 - 80, y_top - 70, 24, RED);

        DrawNode(x_r1, y_bottom);
        DrawNode(x_r3, y_bottom);
        DrawNode(x_r4, y_bottom);

        DrawText("0V (GND)", x_r1 - 40, y_bottom + 20, 18, GRAY);
        DrawText("0V (GND)", x_r3 - 40, y_bottom + 20, 18, GRAY);
        DrawText("0V (GND)", x_r4 - 40, y_bottom + 20, 18, GRAY);

        DrawText("+", x_r1 - 25, y_center - 35, 20, ORANGE);
        DrawText("v1", x_r1 - 35, y_center - 10, 22, SKYBLUE);
        DrawText("-", x_r1 - 25, y_center + 20, 20, ORANGE);

        DrawText("+", x_r3 - 25, y_center - 35, 20, ORANGE);
        DrawText("v2", x_r3 - 35, y_center - 10, 22, SKYBLUE);
        DrawText("-", x_r3 - 25, y_center + 20, 20, ORANGE);

        DrawRectangle(panelX, 0, screenWidth - panelX, screenHeight, (Color){45, 45, 45, 255});
        DrawLine(panelX, 0, panelX, screenHeight, GRAY);

        DrawText("KONTROL PANELI", panelX + 30, 40, 24, ORANGE);

        DrawText("[SOL/SAG]   : Eleman Sec", panelX + 30, 90, 16, GRAY);
        DrawText("[YUKARI/ASAGI]: Deger Degistir", panelX + 30, 120, 16, GRAY);

        DrawLine(panelX + 20, 160, screenWidth - 20, 160, GRAY);

        const char *varNames[] = {"R1", "R2", "R3", "R4", "Ig1", "Ig2"};
        float varValues[] = {R1, R2, R3, R4, Ig1, Ig2};

        for (int i = 0; i < 6; i++)
        {
            int y_pos = 200 + (i * 50);
            Color textColor = (i == selected_item) ? GREEN : RAYWHITE; // secili eleman ise yesil degilse beyaz

            if (i == selected_item)
            {
                DrawText(">", panelX + 15, y_pos, 22, GREEN);
            }

            const char *unit = (i < 4) ? "Ohm" : "A";
            DrawText(TextFormat("%s : %.1f %s", varNames[i], varValues[i], unit), panelX + 40, y_pos, 22, textColor);
        }

        DrawLine(panelX + 20, 520, screenWidth - 20, 520, GRAY);
        DrawText("DUYARLILIK (SENSITIVITY)", panelX + 30, 540, 20, ORANGE);
        DrawText("(R1)", panelX + 30, 565, 14, GRAY);

        DrawText(TextFormat("dV1/dR1 = %.4f", dV1_dR1), panelX + 30, 610, 22, GREEN);
        DrawText(TextFormat("dV2/dR1 = %.4f", dV2_dR1), panelX + 30, 650, 22, GREEN);

        // R2 Sonuclari
        DrawText("(R2)", panelX + 30, 690, 14, GRAY);
        DrawText(TextFormat("dV1/dR2 = %.4f", dV1_dR2), panelX + 30, 715, 20, GREEN);
        DrawText(TextFormat("dV2/dR2 = %.4f", dV2_dR2), panelX + 30, 745, 20, GREEN);

        // Akim Kaynaklari Sonuclari
        DrawText("(Akim Kaynaklari)", panelX + 30, 785, 14, GRAY);
        DrawText(TextFormat("dV1/dIg1 = %.4f", dV1_dIg1), panelX + 30, 810, 20, SKYBLUE);
        DrawText(TextFormat("dV2/dIg1 = %.4f", dV2_dIg1), panelX + 30, 840, 20, SKYBLUE);

        DrawText(TextFormat("dV1/dIg2 = %.4f", dV1_dIg2), panelX + 30, 870, 20, SKYBLUE);
        DrawText(TextFormat("dV2/dIg2 = %.4f", dV2_dIg2), panelX + 30, 900, 20, SKYBLUE);

        EndDrawing();
    }

    delete[] G.data;
    delete[] G_inv.data;
    delete[] I_mat.data;
    delete[] V_mat.data;
    delete[] dG_dR1.data;
    delete[] Temp1.data;
    delete[] Temp2.data;
    delete[] dG_dR2.data;
    delete[] dV_dR2_mat.data;
    delete[] dI_dIg1.data;
    delete[] dI_dIg2.data;
    delete[] dV_dIg1_mat.data;
    delete[] dV_dIg2_mat.data;
    CloseWindow();
    return 0;
}