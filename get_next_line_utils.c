/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   get_next_line_utils.c                              :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: jeanbarr <jeanbarr@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/11/15 12:51:50 by jeanbarr          #+#    #+#             */
/*   Updated: 2026/11/19 18:13:41 by jeanbarr         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "get_next_line.h"

size_t	gnl_strlen(const char *str)
{
	size_t	i;

	i = 0;
	if (!str)
		return (0);
	while (str[i])
		i++;
	return (i);
}

char	*gnl_strchr(const char *buffer, int c)
{
	int	i;

	i = 0;
	if (!buffer)
		return (NULL);
	while (buffer[i])
	{
		if (buffer[i] == (char)c)
			return ((char *)&buffer[i]);
		i++;
	}
	if (buffer[i] == (char)c)
		return ((char *)&buffer[i]);
	return (NULL);
}

char	*gnl_strjoin(char *stash, const char *buff)
{
	size_t	i;
	size_t	j;
	char	*total;

	total = malloc(sizeof(char) * (gnl_strlen(stash) + gnl_strlen(buff) + 1));
	if (!total)
		return (free(stash), NULL);
	i = 0;
	while (stash && stash[i])
	{
		total[i] = stash[i];
		i++;
	}
	j = 0;
	while (buff[j])
	{
		total[i + j] = buff[j];
		j++;
	}
	total[i + j] = '\0';
	free(stash);
	return (total);
}

char	*gnl_substr(const char *s, unsigned int start, size_t len)
{
	size_t	i;
	size_t	s_len;
	char	*substr;

	if (!s)
		return (NULL);
	s_len = gnl_strlen(s);
	if (start > s_len)
		start = s_len;
	if (len > s_len - start)
		len = s_len - start;
	substr = malloc(len + 1);
	if (!substr)
		return (NULL);
	i = 0;
	while (i < len)
	{
		substr[i] = s[start + i];
		i++;
	}
	substr[i] = '\0';
	return (substr);
}
