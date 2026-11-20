/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   main.c                                             :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: jeanbarr <jeanbarr@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/11/14 12:19:12 by jeanbarr          #+#    #+#             */
/*   Updated: 2026/11/14 12:35:09 by jeanbarr         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "ft_printf.h"
#include <stdio.h>
int main(void)
{
    int     ret_ft;
    int     ret_orig;
    char    *null_str;
    void    *null_ptr;

    null_str = NULL;
    null_ptr = NULL;

    printf_str("--- TESTES DO FT_PRINTF ---\n\n");

    // 1. Teste de Char (%c)
    printf_str("1. Char (%c):\n");
    ret_ft = ft_printf("FT:   [%c]\n", 'J');
    ret_orig = printf("ORIG: [%c]\n", 'J');
    ft_printf("Retornos -> ft: %d | orig: %d\n\n", ret_ft, ret_orig);

    // 2. Teste de String (%s)
    printf_str("2. String (%s):\n");
    ret_ft = ft_printf("FT:   [%s]\n", "Fellow tarnished!");
    ret_orig = printf("ORIG: [%s]\n", "Fellow tarnished!");
    ft_printf("Retornos -> ft: %d | orig: %d\n\n", ret_ft, ret_orig);

    // Teste de String NULL
    printf_str("2.1. String NULL (%s):\n");
    ret_ft = ft_printf("FT:   %s\n", null_str);
    ret_orig = printf("ORIG: %s\n", null_str);
    ft_printf("Retornos -> ft: %d | orig: %d\n\n", ret_ft, ret_orig);

    // 3. Teste de Ponteiro (%p)
    printf_str("3. Ponteiro (%p):\n");
    int x = 42;
    ret_ft = ft_printf("FT:   [%p]\n", &x);
    ret_orig = printf("ORIG: [%p]\n", &x);
    ft_printf("Retornos -> ft: %d | orig: %d\n\n", ret_ft, ret_orig);

    // Teste de Ponteiro NULL
    printf_str("3.1. Ponteiro NULL (%p):\n");
    ret_ft = ft_printf("FT:   %p\n", null_ptr);
    ret_orig = printf("ORIG: %p\n", null_ptr);
    ft_printf("Retornos -> ft: %d | orig: %d\n\n", ret_ft, ret_orig);

    // 4. Teste de Decimal (%d e %i)
    printf_str("4. Decimal (%d / %i):\n");
    ret_ft = ft_printf("FT:   [%d] e [%i]\n", -42, 2147483647);
    ret_orig = printf("ORIG: [%d] e [%i]\n", -42, 2147483647);
    ft_printf("Retornos -> ft: %d | orig: %d\n\n", ret_ft, ret_orig);

    // 5. Teste de Unsigned (%u)
    printf_str("5. Unsigned (%u):\n");
    ret_ft = ft_printf("FT:   [%u]\n", 42);
    ret_orig = printf("ORIG: [%u]\n", 42);
    ft_printf("Retornos -> ft: %d | orig: %d\n\n", ret_ft, ret_orig);

    // 6. Teste de Hexadecimal (%x e %X)
    printf_str("6. Hexadecimal (%x / %X):\n");
    ret_ft = ft_printf("FT:   [%x] e [%X]\n", 4254, 4254);
    ret_orig = printf("ORIG: [%x] e [%X]\n", 4254, 4254);
    ft_printf("Retornos -> ft: %d | orig: %d\n\n", ret_ft, ret_orig);

    // 7. Teste de Percentagem (%%)
    printf_str("7. Percentagem (%%):\n");
    ret_ft = ft_printf("FT:   [100%%]\n");
    ret_orig = printf("ORIG: [100%%]\n");
    ft_printf("Retornos -> ft: %d | orig: %d\n\n", ret_ft, ret_orig);

    return (0);
}