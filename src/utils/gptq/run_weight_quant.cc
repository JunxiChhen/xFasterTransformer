#include <iostream>
#include "gptq.h"

int main() {
    float data[9] = {
            0.123456, 1.234567, 3.456789,
            4.567891, 5.678912, 6.789123,
            7.891234, 8.912345, 9.123456 
    };
    Tensor<float> W(&data[0], 3, 3, 3);
    std::cout << "W" << std::endl;
    W.print();

    Tensor<int> Qint(W.rows, W.columns, true);
    Tensor<float> Qfloat(W.rows, W.columns, true);
    Tensor<float> scale(W.columns, true);
    Tensor<int> zero(W.columns, true);
    GPTQ gptq(W, 8);
    gptq.fasterquant(Qint, Qfloat, scale, zero);

    std::cout << "Qint" << std::endl;
    Qint.print();
    std::cout << "Qfloat" << std::endl;
    Qfloat.print();
    std::cout << "scale" << std::endl;
    scale.print();
    std::cout << "zero" << std::endl;
    zero.print();

    Qint.free();
    Qfloat.free();
    scale.free();
    zero.free();

    return 0;
}