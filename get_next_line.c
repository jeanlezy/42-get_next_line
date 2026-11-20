/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   get_next_line.c                                    :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: jeanbarr <jeanbarr@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/11/15 12:42:17 by jeanbarr          #+#    #+#             */
/*   Updated: 2026/11/19 19:13:06 by jeanbarr         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "get_next_line.h"

static char	*ft_read_and_stash(int fd, char *stash)
{
	char	*buffer;
	int		bytes;

	buffer = malloc((size_t)BUFFER_SIZE + 1);
	if (!buffer)
		return (free(stash), NULL);
	bytes = 1;
	while (bytes > 0 && !gnl_strchr(stash, SEP))
	{
		bytes = read(fd, buffer, BUFFER_SIZE);
		if (bytes < 0)
			break ;
		buffer[bytes] = '\0';
		if (bytes > 0)
			stash = gnl_strjoin(stash, buffer);
		if (!stash)
			break ;
	}
	free(buffer);
	if (bytes < 0)
		return (free(stash), NULL);
	return (stash);
}

static char	*ft_extract_line(char *stash)
{
	int	i;

	i = 0;
	if (!stash || stash[i] == '\0')
		return (NULL);
	while (stash[i] && stash[i] != SEP)
		i++;
	if (stash[i] == SEP)
		return (gnl_substr(stash, 0, i + 1));
	else
		return (gnl_substr(stash, 0, i));
}

static char	*ft_refresh_stash(char *stash)
{
	int		i;
	char	*new_stash;

	i = 0;
	while (stash[i] && stash[i] != SEP)
		i++;
	if (!stash[i])
		return (free(stash), NULL);
	new_stash = gnl_substr(stash, i + 1, gnl_strlen(stash) - i - 1);
	free(stash);
	if (!new_stash || new_stash[0] == '\0')
		return (free(new_stash), NULL);
	return (new_stash);
}

char	*get_next_line(int fd)
{
	static char	*stash;
	char		*line;

	if (fd < 0 || BUFFER_SIZE <= 0)
		return (NULL);
	stash = ft_read_and_stash(fd, stash);
	if (!stash)
		return (NULL);
	line = ft_extract_line(stash);
	if (!line)
		return (free(stash), stash = NULL, NULL);
	stash = ft_refresh_stash(stash);
	return (line);
}
