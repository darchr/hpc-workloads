#include <iostream>
#include <string>
#include <utility>

/*
The purpose of this code is to verify that the dynamic selection of
the best function to run is correct. The selection is done by analyzing
the number and type of arguments that are being passed into the function.
This way you can have more kind of the same function defined. 

However, the important thing to note here is the priority value begin set.
Within QMCPack, this is used to choose between CUDA HIP and pure CPU libraries 
for this such as FFT. 
CPU based FFT uses the libfftw dependency when no GPU is selected
but this is considerably slower than the GPU implementations. 
The priority is what tells the compiler to prioritize one function over another
when compiling.

So rather than rewrite code for the rocblas or cuda fftw libraries, that use
the GPU, use this "tag_dispatching" method of calling the similar named, 
but different functions. 

*/

template<int N> struct priority : priority<N-1> {};
template<> struct priority<0> {};

template<typename T, typename... Args>
void print_args(const T& arg, const Args&... args) {
    std::cout << arg << (sizeof...(args) == 0 ? "" : ", ");
    print_args(args...);
}

int dispatch_print(priority<1>, int a, int b) {
    std::cout << "Args1: " << a << ", " << b << "\n";
    return 10;
}

template<typename... Args>
int dispatch_print(priority<0>, Args&&... args) {
    std::cout << "Args2: ";
    print_args(std::forward<Args>(args)...); 
    return 5;
}

template<typename... Args>
int print_and_return(Args&&... args) {
    return dispatch_print(priority<1>{}, std::forward<Args>(args)...);
}

int main() {

    int result1 = print_and_return(10, 20);
    std::cout << "Result 1 (Specialized): " << result1 << "\n\n";

    int result2 = print_and_return(10, std::string("hello"), 3.14);
    std::cout << "Result 2 (Generic Fallback): " << result2 << "\n\n";

    return 0;
}
