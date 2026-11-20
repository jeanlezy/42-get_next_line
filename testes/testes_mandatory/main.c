/* ************************************************************************** */
/*  TESTES DA PARTE OBRIGATORIA - get_next_line                               */
/*                                                                            */
/*  Esta pasta (testes_mandatory) fica DENTRO da pasta do projeto,            */
/*  ao lado do get_next_line.c. Todos os comandos correm DENTRO desta pasta:  */
/*                                                                            */
/*      cd testes_mandatory                                                   */
/*                                                                            */
/*  1) COMPILAR                                                               */
/*     cc -Wall -Wextra -Werror -D BUFFER_SIZE=42 main.c \                    */
/*        ../get_next_line.c ../get_next_line_utils.c -o gnl                  */
/*                                                                            */
/*     Outros BUFFER_SIZE: troca o 42 por 1, 9999, 10000000...                */
/*     Sem "-D BUFFER_SIZE=42" tambem compila (usa o valor do .h: 42).        */
/*                                                                            */
/*  2) CORRER                                                                 */
/*     ./gnl texto.txt             3 linhas, a ultima sem \n                  */
/*     ./gnl vazio.txt             ficheiro vazio -> 0 linhas                 */
/*     ./gnl so_enters.txt         3 linhas, cada uma so "\n"                 */
/*     ./gnl sem_enter_final.txt   1 linha sem \n                             */
/*     ./gnl acentos.txt           acentos (testar com BUFFER_SIZE=1)         */
/*     ./gnl linha_longa.txt       1 linha de 20000 caracteres + 1 curta      */
/*     ./gnl nao_existe.txt        fd invalido -> 0 linhas, sem crash         */
/*     ./gnl                       le do teclado (stdin); Ctrl+D termina      */
/*     cat texto.txt | ./gnl       le do stdin atraves de um pipe             */
/*                                                                            */
/*     Cada linha aparece entre [ ] e o \n e mostrado como "\n" visivel.      */
/*                                                                            */
/*  3) LEAKS                                                                  */
/*     valgrind --leak-check=full ./gnl texto.txt                             */
/*                                                                            */
/*  4) TESTAR VARIOS BUFFER_SIZE DE SEGUIDA                                   */
/*     for b in 1 2 42 9999 10000000; do echo "== BUFFER_SIZE=$b =="; \       */
/*       cc -Wall -Wextra -Werror -D BUFFER_SIZE=$b main.c \                  */
/*       ../get_next_line.c ../get_next_line_utils.c -o gnl \                 */
/*       && ./gnl texto.txt; done                                             */
/*                                                                            */
/*  5) OUTRO SEPARADOR (em vez de \n)                                         */
/*     cc -Wall -Wextra -Werror -D SEP="';'" main.c \                         */
/*        ../get_next_line.c ../get_next_line_utils.c -o gnl                  */
/*     ./gnl separador.txt         -> [abc;] [def;] [ghi]                     */
/* ************************************************************************** */

#include <fcntl.h>
#include <stdio.h>
#include "../get_next_line.h"

/* Mostra a linha entre [ ], com o \n visivel como "\n". */
static void	print_line(int n, char *line)
{
	int	i;

	printf("linha %d: [", n);
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

int	main(int argc, char **argv)
{
	int		fd;
	int		n;
	char	*line;

	if (argc < 2)
		fd = 0;
	else
		fd = open(argv[1], O_RDONLY);
	n = 0;
	line = get_next_line(fd);
	while (line != NULL)
	{
		n++;
		print_line(n, line);
		free(line);
		line = get_next_line(fd);
	}
	printf("-> get_next_line devolveu NULL depois de %d linha(s)\n", n);
	if (fd > 0)
		close(fd);
	return (0);
}
