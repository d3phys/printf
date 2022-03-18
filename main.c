int print (const char *fmt, ...);
int printf(const char *fmt, ...);

int main()
{
        print ("%s\n", "Hello world");
        printf("%s\n", "Hello world");

        print ("0x%x\n", 0x12378901);
        printf("0x%x\n", 0x12378901);

        print ("0d%d\n", 0076543210);
        printf("0d%d\n", 0076543210);
        
        print ("%c%c%c\n", 'a', '*', 'c');
        printf("%c%c%c\n", 'a', '*', 'c');
        
        return 0;
}
