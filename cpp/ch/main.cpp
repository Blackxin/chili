#include <iostream>
#include <conio.h>
#include <stdlib.h>

using namespace std;


template <typename T,unsigned S>
inline unsigned arraysize(const T (&v)[S]) { return S; }
#define ARRAYSIZE(a) ((sizeof(a) / sizeof(*(a))) / static_cast<size_t>(!(sizeof(a) % sizeof(*(a)))))

template <typename T, int S>
int   size(T (&arg)[S]) { return S; }

int   MaxValueArray(int (&arr)[6]);
char  *space(int x, char c);
int   LenChar(char *a[]);

int main()
{

    char ch = 65; // even though we're initializing ch with an integer
    char caracter(65);
    std::cout << ch       << std::endl; // cout prints a character
    std::cout << caracter << std::endl; // cout prints a character

    static int arr[] = { 0, 2, 5, 3, 59,40};
    static char *m[] = {"um", "dois", "tres"};
    int nMax = sizeof(arr) / sizeof(arr[0]);
    cout << "main::main()"   << space(40, '-') << endl;
    cout << "array[0]      " << (int)sizeof(arr[0]) << endl;
    cout << "sizeof(array) " << (int)sizeof(arr) << endl;
    cout << "nMax          " << nMax << endl;

    cout << "main::MaxValueArray(arr)" << space(40, '-') << endl;
    cout << MaxValueArray(arr) << endl;

    cout << "main::LenArray(m)" << space(40, '-') << endl;
    cout << "size(m)          " << size(m) << endl;
    cout << "LenChar(m)       " << LenChar(m) << endl;

    return 0;
}

int MaxValueArray(int (&arr)[6])
{

    int nMax = sizeof(arr) / sizeof(arr[0]);
    //cout << "array[0]      " << (int)sizeof(arr[0]) << endl;
    //cout << "sizeof(array) " << (int)sizeof(arr) << endl;
    //cout << "nMax          " << nMax << endl;
    int nPos = 1;
    //cout << arr[0] << endl;
    for(nPos=1; nPos <nMax; nPos++)
    {
       //cout << arr[nPos] << endl;
       if(arr[0] < arr[nPos])
          arr[0] = arr[nPos];
    }
   return arr[0];
}

char *space(int x, char c)
{
   char *buf = (char*)malloc(x);
   if(buf)
      if(c)
         memset(buf, c, x);
   return buf;
}

int LenChar(char *a[])
{
   int n = 0;
   int x = 0;
   int y = ARRAYSIZE(*(&a[0]));
   cout << "ARRAYSIZE(*(a) = " << y << endl;
   cout << strlen(a[0]) << "=" << &a[0] << endl;
   cout << strlen(a[1]) << "=" << &a[1] << endl;
   cout << y << endl << sizeof(a) << endl;

   while(*(*a+x)){
     cout << *(a+x)<< endl;
     x++;
   }
   return x;
}

