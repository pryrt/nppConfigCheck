#include <stdio.h>

int main(int argc, char *argv[], char **envp)
{
    int i;
    printf("%s ", "running:");
    for(i=0; i<argc; i++)
        printf("%s ", argv[i]);
    printf("\n");
    //for(char** env = envp; *env != 0; env++) {
    //    char* thisEnv = *env;
    //    printf("\t%s\n", thisEnv);
    //}
    //printf("\n");
}
