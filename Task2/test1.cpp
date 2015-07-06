#define _USE_MATH_DEFINES
#include <math.h>
#include <iostream>

extern "C" {
    void calculate_dct_matrix();
    void _fdct(float * in, float * out, int n);
    void _idct(float * in, float * out, int n);
}

/*float test[128] = { -62, 28, -9, 7, 2786, -659, -95, 2975,
579, 88, -678, 762, 6898, 1, -622, -5892,
-88, -1, -556, -97, 68, -779, -28, -62,
-69, -1, 8, 2, 5, 52, -96, 5,
-62, -85, -5, 529, 928, 996, 652, -689,
22, 728, 99, 95, 29, -79, -22, -8672,
87, -955, 96, 26, 6279, 67, 65, -52,
-766, -662, 6, -565, -67, -8, 587, -5, -62, 28, -9, 7, 2786, -659, -95, 2975,
579, 88, -678, 762, 6898, 1, -622, -5892,
-88, -1, -556, -97, 68, -779, -28, -62,
-69, -1, 8, 2, 5, 52, -96, 5,
-62, -85, -5, 529, 928, 996, 652, -689,
22, 728, 99, 95, 29, -79, -22, -8672,
87, -955, 96, 26, 6279, 67, 65, -52,
-766, -662, 6, -565, -67, -8, 587, -5 };
*/
float test[128] = { -16342, 2084, -10049, 10117, 2786, -659, -4905, 12975,
10579, 8081, -10678, 11762, 6898, 444, -6422, -15892,
-13388, -4441, -11556, -10947, 16008, -1779, -12481, -16230,
-16091, -4001, 1038, 2333, 3335, 3512, -10936, 5343,
-1612, -4845, -14514, 3529, 9284, 9916, 652, -6489,
12320, 7428, 14939, 13950, 1290, -11719, -1242, -8672,
11870, -9515, 9164, 11261, 16279, 16374, 3654, -3524,
-7660, -6642, 11146, -15605, -4067, -13348, 5807, -14541, -16342, 2084, -10049, 10117, 2786, -659, -4905, 12975,
10579, 8081, -10678, 11762, 6898, 444, -6422, -15892,
-13388, -4441, -11556, -10947, 16008, -1779, -12481, -16230,
-16091, -4001, 1038, 2333, 3335, 3512, -10936, 5343,
-1612, -4845, -14514, 3529, 9284, 9916, 652, -6489,
12320, 7428, 14939, 13950, 1290, -11719, -1242, -8672,
11870, -9515, 9164, 11261, 16279, 16374, 3654, -3524,
-7660, -6642, 11146, -15605, -4067, -13348, 5807, -14541 };

float res[128];

float cosine(int i, int j) {
    return cos(M_PI * j * (2 * i + 1) / 16);
}

float a(int n) {
    return n == 0 ? sqrt(2) / 4 : 0.5;
}

void fdct(float * input, float * output, int n) {
    for (int y = 0; y != 8; ++y) {
        for (int x = 0; x != 8; ++x) {
            output[y * 8 + x] = 0;
            for (int u = 0; u != 8; ++u) {
                for (int v = 0; v != 8; ++v) {
                    output[y * 8 + x] += input[u * 8 + v] * cosine(u, x) * cosine(v, y) * a(u) * a(v);
                }
            }
        }
    }
}

int main()
{
//    for (int i = 0; i < 8; i++)
//    {
//        for (int j = 0; j < 8; j++)
//        {
//            test[i * 8 + j] = j;
//        }
//    }
//
    _fdct(test, res, 2);

    for (int i = 0; i < 8; i++)
    {
        for (int j = 0; j < 8; j++)
        {
            std::cout << res[i * 8 + j] << " ";
        }
        std::cout << "\n";
    }
    std::cout << "---\n\n";

    _idct(res, test, 2);
    for (int i = 0; i < 8; i++)
    {
        for (int j = 0; j < 8; j++)
        {
            std::cout << test[i * 8 + j] << " ";
        }
        std::cout << "\n";
    }
    std::cout << "----\n\n";

}

