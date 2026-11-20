#include "get_next_line_bonus.h"
#include <fcntl.h>
#include <stdio.h>

int	main(void)
{
	int		fd1;
	int		fd2;
	char	*l1;
	char	*l2;

	fd1 = open("06_normal.txt", O_RDONLY);
	fd2 = open("01_empty.txt", O_RDONLY);
	if (fd1 < 0 || fd2 < 0)
		return (1);
	while (1)
	{
		l1 = get_next_line(fd1);
		l2 = get_next_line(fd2);
		if (!l1 && !l2)
			break ;
		if (l1)
		{
			printf("fd1: %s", l1);
			free(l1);
		}
		if (l2)
		{
			printf("fd2: %s", l2);
			free(l2);
		}
	}
	close(fd1);
	close(fd2);
	return (0);
}