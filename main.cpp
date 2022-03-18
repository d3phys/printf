#include <stdio.h>

extern "C" 
int print (const char *fmt, ...);

#define TEST(fmt, ...)               \
        print (fmt, ##__VA_ARGS__); \
        printf(fmt, ##__VA_ARGS__); 

int main()
{
        setvbuf(stdout, nullptr, _IONBF, 0);
        
        TEST("%s\n", "Hello world")
        TEST("0x%x\n", 0x12378901)
        TEST("0d%d\n", 0076543210)
        TEST("%c%c%c\n", 'a', '*', 'c')
        TEST("%c%s\n", 'a', " hello")
        TEST("%o\n", 0x3213)
        TEST("%%%%%%%%\n")
        TEST("%x%c%d%o\n", 0x12, '2', 100, 0x92)
        
        return 0;
}
