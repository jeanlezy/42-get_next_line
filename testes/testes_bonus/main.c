/* ************************************************************************** */
/*  TESTES DO BONUS - get_next_line (varios fd ao mesmo tempo)                */
/*                                                                            */
/*  Esta pasta (testes_bonus) fica DENTRO da pasta do projeto,                */
/*  ao lado do get_next_line_bonus.c. Os comandos correm DENTRO desta pasta:  */
/*                                                                            */
/*      cd testes_bonus                                                       */
/*                                                                            */
/*  1) COMPILAR                                                               */
/*     cc -Wall -Wextra -Werror -D BUFFER_SIZE=42 main.c \                    */
/*        ../get_next_line_bonus.c ../get_next_line_utils_bonus.c \           */
/*        -o gnl_bonus                                                        */
/*                                                                            */
/*     Outros BUFFER_SIZE: troca o 42 por 1, 9999, 10000000...                */
/*                                                                            */
/*  2) CORRER                                                                 */
/*     ./gnl_bonus a.txt b.txt c.txt                                          */
/*                                                                            */
/*     O programa abre os 3 ficheiros e le UMA linha de cada, a vez:          */
/*     a, b, c, a, b, c... As linhas de cada ficheiro tem de sair pela        */
/*     ordem certa e sem se misturarem com as dos outros:                     */
/*       a.txt -> "A1", "A2", "A3", "A4 (ultima, sem enter)"                  */
/*       b.txt -> "B1", "B2"                                                  */
/*       c.txt -> "C1", linha vazia, "C3"                                     */
/*     Quando um ficheiro acaba, aparece (NULL) para esse fd.                 */
/*                                                                            */
/*     Tambem funciona com 1 ficheiro, ou com outros:                         */
/*     ./gnl_bonus a.txt                                                      */
/*     ./gnl_bonus a.txt ../testes_mandatory/texto.txt                        */
/*                                                                            */
/*  3) FD INVALIDOS (o programa testa sozinho no fim)                         */
/*     fd -1, fd 1024 e fd 5000 tem de devolver NULL, sem crash.              */
/*                                                                            */
/*  4) LEAKS                                                                  */
/*     valgrind --leak-check=full ./gnl_bonus a.txt b.txt c.txt               */
/*                                                                            */
/*  5) UMA SO VARIAVEL STATIC                                                 */
/*     grep -n "static" ../get_next_line_bonus.c                              */
/*     So ha uma variavel: "static char *stash[MAX_FD];"                      */
/*     (as outras linhas sao funcoes static, nao variaveis)                   */
/* ************************************************************************** */

#include <fcntl.h>
#include <stdio.h>
#include "../get_next_line_bonus.h"

#define MAX_FILES 10

/* Mostra a linha entre [ ], com o \n visivel como "\n". */
static void	print_line(int fd, char *name, char *line)
{
	int	i;

	printf("fd %d (%s): ", fd, name);
	if (line == NULL)
	{
		printf("(NULL)\n");
		return ;
	}
	printf("[");
	i = 0;
	while (line[i])
	{
		if (line[i] == '\n')
			printf("\\n");
		else
			printf("%c", line[i]);
		i++;
	}
	printf("]\n");
}

static void	test_invalid_fds(void)
{
	int		bad[3];
	int		i;
	char	*line;

	bad[0] = -1;
	bad[1] = 1024;
	bad[2] = 5000;
	printf("\n-- fd invalidos (tem de dar NULL) --\n");
	i = 0;
	while (i < 3)
	{
		line = get_next_line(bad[i]);
		if (line == NULL)
			printf("fd %d: NULL (certo)\n", bad[i]);
		else
			printf("fd %d: devolveu uma linha (ERRADO)\n", bad[i]);
		free(line);
		i++;
	}
}

int	main(int argc, char **argv)
{
	int		fd[MAX_FILES];
	char	*line;
	int		alive;
	int		i;

	if (argc < 2 || argc > MAX_FILES + 1)
		return (printf("Uso: ./gnl_bonus a.txt b.txt c.txt\n"), 1);
	i = 0;
	while (++i < argc)
		fd[i - 1] = open(argv[i], O_RDONLY);
	alive = 1;
	while (alive)
	{
		alive = 0;
		i = 0;
		while (++i < argc)
		{
			line = get_next_line(fd[i - 1]);
			print_line(fd[i - 1], argv[i], line);
			if (line != NULL)
				alive = 1;
			free(line);
		}
		printf("\n");
	}
	i = 0;
	while (++i < argc)
		close(fd[i - 1]);
	test_invalid_fds();
	return (0);
}
