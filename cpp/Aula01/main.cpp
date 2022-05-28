#include <iostream>

using namespace std;
enum dias {Dom=1, Seg, Ter, Qua, Qui, Sex, Sab};
void contador(int num, int cont=0);
void soma();
void soma(int n1, int n2);
int mod(int x, int y);

//=====================================================
int main()
{
    contador(10);
    soma();
    soma(20,30);
    cout << "Resto 11/3 : " << mod(11,3);
    return 0;
}

//=====================================================

void contador(int num, int cont)
{
    cout << cont << "\n";
    if( num > cont) {
        contador(num, ++cont);
    }
}
//=====================================================

void soma(int n1, int n2)
{
    int re;
    re = n1 + n2;
    cout << "Soma de " << n1 << " com " << n2 << " = " << re << "\n" ;
}

//=====================================================

void soma()
{
    int n1, n2, re;
    n1 = 10;
    n2 = 20;
    re = n1 + n2;
    cout << "Soma de " << n1 << " com " << n2 << " = " << re << "\n" ;
}

//=====================================================

int mod(int x, int y)
{
    return( x%y );
}
