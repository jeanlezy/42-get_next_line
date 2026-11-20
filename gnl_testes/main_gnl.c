#include "get_next_line.h"
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int	main(void)
{
	int		fd;
	char	*line;
	int		i;

	fd = open("oneline.txt", O_RDONLY);
	if (fd < 0)
		return (printf("Erro ao abrir ficheiro\n"), 1);
	i = 1;
	line = get_next_line(fd);
	while (line)
	{
		printf("Linha %d: %s", i, line);
		free(line);
		line = get_next_line(fd);
		i++;
	}
	close(fd);
	return (0);
}