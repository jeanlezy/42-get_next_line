#!/bin/bash
# **************************************************************************** #
#  gnl_tester.sh - testador para o get_next_line                               #
#                                                                              #
#  Uso:   bash gnl_tester.sh [pasta_do_projeto]                                #
#         (por defeito: a pasta de cima, "..")                                 #
#                                                                              #
#  Opcoes (variaveis de ambiente):                                             #
#    NO_VALGRIND=1   nao usa o valgrind (mais rapido)                          #
#    NO_MALLOC=1     salta o teste de falhas de malloc                         #
#    VERBOSE=1       mostra tambem os testes que passam                        #
# **************************************************************************** #

PROJ="$(cd "${1:-..}" 2>/dev/null && pwd)"
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$HERE/.gnl_tester"
SIZES="1 2 3 5 10 42 1000 10000000"
VG_SIZES="1 42"
CFLAGS="-Wall -Wextra -Werror"
TIMEOUT=10

G="\033[32m"; R="\033[31m"; Y="\033[33m"; B="\033[1m"; C="\033[36m"; N="\033[0m"
OK=0; KO=0; WARN=0

ok()   { OK=$((OK+1)); if [ -n "$VERBOSE" ]; then printf "  ${G}OK${N}   %s\n" "$1"; fi; return 0; }
ko()   { KO=$((KO+1)); printf "\n  ${R}KO${N}   %s\n" "$1"; if [ -n "$2" ]; then printf "       %s\n" "$2"; fi; return 0; }
warn() { WARN=$((WARN+1)); printf "\n  ${Y}AVISO${N} %s\n" "$1"; if [ -n "$2" ]; then printf "       %s\n" "$2"; fi; return 0; }
title(){ printf "\n${B}${C}== %s ==${N}\n" "$1"; }
vgmsg(){ grep -m1 -E 'Invalid|definitely lost|indirectly lost|uninitialised' out/err | sed 's/^==[0-9]*== //'; }
dot()  { if [ -z "$VERBOSE" ]; then printf "${G}.${N}"; fi; return 0; }

if [ -z "$PROJ" ] || [ ! -f "$PROJ/get_next_line.c" ]; then
	printf "${R}Nao encontrei get_next_line.c em '%s'${N}\n" "${1:-..}"
	echo "Uso: bash gnl_tester.sh /caminho/para/o/projeto"
	exit 1
fi
command -v cc >/dev/null || { echo "Falta o compilador cc"; exit 1; }
HAS_VG=0; [ -z "$NO_VALGRIND" ] && command -v valgrind >/dev/null && HAS_VG=1
HAS_BONUS=0; [ -f "$PROJ/get_next_line_bonus.c" ] && HAS_BONUS=1

rm -rf "$WORK"; mkdir -p "$WORK/files" "$WORK/out"
cd "$WORK" || exit 1

printf "${B}Projeto:${N} %s\n" "$PROJ"
printf "${B}Valgrind:${N} %s   ${B}Bonus:${N} %s\n" \
	"$([ $HAS_VG = 1 ] && echo sim || echo nao)" "$([ $HAS_BONUS = 1 ] && echo sim || echo nao)"

# ---------------------------------------------------------------------------- #
#  Ficheiros de teste                                                          #
# ---------------------------------------------------------------------------- #
F=files
printf ""                                   > $F/empty
printf "a"                                  > $F/one_char
printf "\n"                                 > $F/only_nl
printf "\n\n\n\n\n"                         > $F/multiple_nl
printf "abcdefghijklmnopqrstuvwxyz"         > $F/one_line_no_nl
printf "abcdefghijklmnopqrstuvwxyz\n"       > $F/one_line_nl
printf "Ola\nTudo bem?\nTchau"              > $F/texto
printf "\nlinha\n\n\nmais\n\n"              > $F/variable_nls
printf "Olá, ção ã é ü ñ\nÀçênto\n"         > $F/accents
printf "0123456789\n012345678\n90123456789\n0123456789\nxxxx\n" > $F/lines_around_10
printf "tab\there\r\nwindows\r\n"           > $F/special_chars
for n in 9 10 11 19 20 21 41 42 43; do
	head -c $n /dev/zero | tr '\0' 'x' > $F/len_$n
	{ head -c $n /dev/zero | tr '\0' 'x'; printf "\n"; } > $F/len_${n}_nl
done
head -c 20000 /dev/zero | tr '\0' '7'                          > $F/giant_line
{ head -c 20000 /dev/zero | tr '\0' '7'; printf "\nanother line!!!"; } > $F/giant_line_nl
for i in $(seq 1 300); do printf "linha numero %d\n" $i; done  > $F/many_lines
awk 'BEGIN{srand(42); for(k=0;k<20;k++){f="files/random_" k; n=int(rand()*400);
	s=""; for(i=0;i<n;i++){r=rand(); s=s (r<0.15?"\n":(r<0.2?" ":sprintf("%c",97+int(rand()*26))))}
	printf "%s", s > f}}'

# ---------------------------------------------------------------------------- #
#  Programas de teste (C)                                                      #
# ---------------------------------------------------------------------------- #
cat > check.c <<'EOF'
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "get_next_line.h"

/* Le o ficheiro todo com get_next_line e escreve as linhas no stdout.
** Verifica as regras de cada linha e que o fim devolve sempre NULL. */
int	main(int argc, char **argv)
{
	int		fd;
	char	*line;
	char	*nl;
	size_t	len;
	int		ended_without_nl;
	int		n;

	fd = (argc > 1 && strcmp(argv[1], "-")) ? open(argv[1], O_RDONLY) : 0;
	ended_without_nl = 0;
	n = 0;
	while ((line = get_next_line(fd)) != NULL)
	{
		n++;
		len = strlen(line);
		if (len == 0)
			return (fprintf(stderr, "linha %d e uma string vazia \"\" (devia ser NULL)\n", n), 1);
		if (ended_without_nl)
			return (fprintf(stderr, "linha %d veio depois de uma linha sem \\n\n", n), 1);
		nl = strchr(line, '\n');
		if (nl && nl != line + len - 1)
			return (fprintf(stderr, "linha %d tem um \\n no meio (juntou duas linhas)\n", n), 1);
		if (!nl)
			ended_without_nl = 1;
		fwrite(line, 1, len, stdout);
		free(line);
	}
	if ((line = get_next_line(fd)) != NULL)
		return (fprintf(stderr, "depois do NULL final, a chamada seguinte nao devolveu NULL\n"), free(line), 1);
	if ((line = get_next_line(fd)) != NULL)
		return (fprintf(stderr, "segunda chamada depois do fim nao devolveu NULL\n"), free(line), 1);
	if (fd > 0)
		close(fd);
	return (0);
}
EOF

cat > check_fd.c <<'EOF'
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include "HEADER"

int	main(int argc, char **argv)
{
	int		bad[5];
	int		fd;
	int		i;
	int		errors;
	char	*line;

	(void)argc;
	fd = open(argv[1], O_RDONLY);
	close(fd);
	bad[0] = -1; bad[1] = -42; bad[2] = 42; bad[3] = fd; bad[4] = BIGFD;
	errors = 0;
	for (i = 0; i < 5; i++)
	{
		line = get_next_line(bad[i]);
		if (line)
		{
			printf("fd %d devolveu uma linha em vez de NULL\n", bad[i]);
			free(line);
			errors++;
		}
	}
	return (errors != 0);
}
EOF

cat > check_bonus.c <<'EOF'
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "get_next_line_bonus.h"

/* Le varios ficheiros ao mesmo tempo, alternando os fd,
** e escreve o conteudo de cada um em out/bonus_<i>. */
int	main(int argc, char **argv)
{
	int		fd[16];
	FILE	*out[16];
	char	name[64];
	char	*line;
	int		alive;
	int		i;
	int		n;

	n = argc - 1;
	for (i = 0; i < n; i++)
	{
		fd[i] = open(argv[i + 1], O_RDONLY);
		sprintf(name, "out/bonus_%d", i);
		out[i] = fopen(name, "w");
	}
	alive = 1;
	while (alive)
	{
		alive = 0;
		for (i = 0; i < n; i++)
		{
			line = get_next_line(fd[i]);
			if (line)
			{
				alive = 1;
				fwrite(line, 1, strlen(line), out[i]);
				free(line);
			}
		}
	}
	for (i = 0; i < n; i++)
	{
		fclose(out[i]);
		close(fd[i]);
	}
	return (0);
}
EOF

cat > check_malloc.c <<'EOF'
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "get_next_line.h"

/* Faz falhar o 1.o malloc, depois o 2.o, o 3.o... e verifica que o GNL
** nunca devolve uma linha errada: so pode devolver as linhas certas,
** pela ordem certa, ate devolver NULL. */
void	*__real_malloc(size_t size);
static long	g_count = 0;
static long	g_fail = -1;

void	*__wrap_malloc(size_t size)
{
	g_count++;
	if (g_count == g_fail)
		return (NULL);
	return (__real_malloc(size));
}

int	main(int argc, char **argv)
{
	static char	content[100000];
	int			fd;
	int			len;
	char		*line;
	size_t		pos;
	long		wrong;
	long		tested;

	(void)argc;
	fd = open(argv[1], O_RDONLY);
	len = read(fd, content, sizeof(content) - 1);
	close(fd);
	content[len < 0 ? 0 : len] = '\0';
	wrong = 0;
	tested = 0;
	for (g_fail = 1; ; g_fail++)
	{
		g_count = 0;
		fd = open(argv[1], O_RDONLY);
		pos = 0;
		while ((line = get_next_line(fd)) != NULL)
		{
			if (strncmp(content + pos, line, strlen(line)) != 0)
			{
				wrong++;
				printf("falha no malloc #%ld: devolveu uma linha errada\n", g_fail);
				free(line);
				break ;
			}
			pos += strlen(line);
			free(line);
		}
		while ((line = get_next_line(fd)) != NULL)
			free(line);
		close(fd);
		if (g_count < g_fail)
			break ;
		tested++;
	}
	printf("TESTED %ld WRONG %ld\n", tested, wrong);
	return (wrong != 0);
}
EOF

# ---------------------------------------------------------------------------- #
#  Funcoes auxiliares do script                                                #
# ---------------------------------------------------------------------------- #
MAND_SRC="$PROJ/get_next_line.c $PROJ/get_next_line_utils.c"
BONUS_SRC="$PROJ/get_next_line_bonus.c $PROJ/get_next_line_utils_bonus.c"

compile() { # out flags... ; devolve 0 se compilou
	local out=$1; shift
	cc $CFLAGS -I"$PROJ" "$@" -o "$out" 2> out/compile.log
}

run_vg() { # programa args... (com valgrind se existir)
	if [ $HAS_VG = 1 ]; then
		timeout $((TIMEOUT * 6)) valgrind -q --leak-check=full --show-leak-kinds=definite,indirect \
			--errors-for-leak-kinds=definite,indirect --error-exitcode=42 "$@"
	else
		timeout $TIMEOUT "$@"
	fi
}

check_file() { # prog ficheiro bs usa_valgrind
	local prog=$1 f=$2 bs=$3 vg=$4 name rc
	name=$(basename "$f")
	if [ "$vg" = 1 ]; then
		run_vg ./$prog "$f" > out/res 2> out/err; rc=$?
	else
		timeout $TIMEOUT ./$prog "$f" > out/res 2> out/err; rc=$?
	fi
	if [ $rc = 124 ]; then ko "BS=$bs $name: timeout (mais de ${TIMEOUT}s)"; return; fi
	if [ $rc -ge 128 ]; then ko "BS=$bs $name: crash (sinal $((rc - 128)), ex.: segfault)"; return; fi
	if [ $rc = 42 ]; then ko "BS=$bs $name: valgrind encontrou leaks ou erros de memoria" "$(vgmsg)"; return; fi
	if [ $rc != 0 ]; then ko "BS=$bs $name: $(head -1 out/err)"; return; fi
	if ! cmp -s out/res "$f"; then
		ko "BS=$bs $name: o conteudo devolvido e diferente do ficheiro" \
			"esperado $(wc -c < "$f") bytes, recebido $(wc -c < out/res) bytes"
		return
	fi
	ok "BS=$bs $name"; dot
}

# ---------------------------------------------------------------------------- #
#  1. Regras do subject                                                        #
# ---------------------------------------------------------------------------- #
title "1. Regras do subject"
for f in get_next_line.c get_next_line_utils.c get_next_line.h; do
	[ -f "$PROJ/$f" ] && ok "existe $f" || ko "falta o ficheiro $f"
done
if [ $HAS_BONUS = 1 ]; then
	for f in get_next_line_bonus.c get_next_line_utils_bonus.c get_next_line_bonus.h; do
		[ -f "$PROJ/$f" ] && ok "existe $f" || ko "falta o ficheiro $f"
	done
fi
grep -qE "^\*This project has been created as part of the 42 curriculum by .+\*" "$PROJ/README.md" 2>/dev/null \
	&& ok "README.md com a primeira linha certa" \
	|| warn "README.md em falta ou primeira linha diferente do pedido no subject"

check_symbols() { # label ficheiros.c...
	local label=$1; shift
	local objs="" f
	for f in "$@"; do
		cc $CFLAGS -I"$PROJ" -D BUFFER_SIZE=42 -c "$f" -o "out/$(basename "$f").o" 2>>out/compile.log || { ko "$label: nao compila (ver abaixo)"; cat out/compile.log; return; }
		objs="$objs out/$(basename "$f").o"
	done
	local defined undefined bad globals
	defined=$(nm $objs | awk '$2 ~ /[TtDdBbCcRr]/ {print $3}' | sort -u)
	undefined=$(nm -u $objs | awk '{print $NF}' | grep -v ':$' | sort -u)
	bad=$(comm -23 <(echo "$undefined") <(echo "$defined") \
		| grep -vxE 'read|malloc|free|__stack_chk_fail|__stack_chk_guard|_GLOBAL_OFFSET_TABLE_|' )
	[ -z "$bad" ] && ok "$label: so usa read, malloc e free" \
		|| ko "$label: usa funcoes externas proibidas:" "$(echo $bad)   (o printf pode aparecer como puts/putchar)"
	globals=$(nm $objs | awk '$2 ~ /^[DBC]$/ {print $3}')
	[ -z "$globals" ] && ok "$label: sem variaveis globais" \
		|| ko "$label: tem variaveis globais:" "$(echo $globals)"
}
check_symbols "mandatory" $MAND_SRC
[ $HAS_BONUS = 1 ] && check_symbols "bonus" $BONUS_SRC

if command -v norminette >/dev/null; then
	if norminette "$PROJ"/get_next_line*.c "$PROJ"/get_next_line*.h > out/norm 2>&1 && ! grep -q "Error" out/norm; then
		ok "norminette OK"
	else
		ko "norminette encontrou erros:"; grep -E "Error" out/norm | head -10 | sed 's/^/       /'
	fi
else
	warn "norminette nao esta instalado aqui: corre-o a parte"
fi
[ -z "$VERBOSE" ] && echo

# ---------------------------------------------------------------------------- #
#  2. Leitura de ficheiros com varios BUFFER_SIZE                              #
# ---------------------------------------------------------------------------- #
title "2. Leitura de ficheiros (BUFFER_SIZE: $SIZES)"
for bs in $SIZES; do
	if ! compile mand_$bs -D BUFFER_SIZE=$bs check.c $MAND_SRC; then
		ko "BS=$bs: nao compila"; cat out/compile.log; continue
	fi
	use_vg=0; [[ " $VG_SIZES " == *" $bs "* ]] && use_vg=1
	for f in files/*; do check_file mand_$bs "$f" $bs $use_vg; done
done
if compile mand_default check.c $MAND_SRC; then
	for f in files/texto files/many_lines files/giant_line_nl; do check_file mand_default "$f" "sem -D" 0; done
else
	ko "nao compila SEM -D BUFFER_SIZE (falta o valor por defeito no .h?)"; cat out/compile.log
fi
[ -z "$VERBOSE" ] && echo

# ---------------------------------------------------------------------------- #
#  3. Standard input e fd invalidos                                            #
# ---------------------------------------------------------------------------- #
title "3. Standard input e fd invalidos"
for bs in 1 42; do
	for f in files/texto files/lines_around_10 files/many_lines; do
		timeout $TIMEOUT ./mand_$bs - < "$f" > out/res 2> out/err; rc=$?
		if [ $rc = 0 ] && cmp -s out/res "$f"; then ok "stdin BS=$bs $(basename $f)"; dot
		else ko "stdin BS=$bs $(basename $f): $(head -1 out/err)"; fi
	done
	printf "um\ndois\ntres" | timeout $TIMEOUT ./mand_$bs - > out/res 2>/dev/null
	[ "$(cat out/res)" = "$(printf "um\ndois\ntres")" ] && { ok "pipe BS=$bs"; dot; } || ko "pipe BS=$bs: resultado errado"
done
sed "s/HEADER/get_next_line.h/; s/BIGFD/100000/" check_fd.c > check_fd_m.c
if compile fd_m -D BUFFER_SIZE=42 check_fd_m.c $MAND_SRC; then
	run_vg ./fd_m files/texto > out/res 2> out/err; rc=$?
	case $rc in
		0) ok "fd invalidos (-1, -42, 42, fd fechado, 100000) devolvem NULL"; dot;;
		42) ko "fd invalidos: valgrind encontrou erros" "$(vgmsg)";;
		*) [ $rc -ge 128 ] && ko "fd invalidos: crash (sinal $((rc - 128)))" || ko "fd invalidos:" "$(cat out/res)";;
	esac
fi
[ -z "$VERBOSE" ] && echo

# ---------------------------------------------------------------------------- #
#  4. Bonus                                                                    #
# ---------------------------------------------------------------------------- #
if [ $HAS_BONUS = 1 ]; then
	title "4. Bonus: varios fd ao mesmo tempo"
	BFILES="files/texto files/multiple_nl files/random_3 files/giant_line_nl files/empty files/accents"
	for bs in 1 7 42 10000000; do
		if ! compile bon_$bs -D BUFFER_SIZE=$bs check_bonus.c $BONUS_SRC; then
			ko "bonus BS=$bs: nao compila"; cat out/compile.log; continue
		fi
		rm -f out/bonus_*
		if [[ " $VG_SIZES " == *" $bs "* ]]; then run_vg ./bon_$bs $BFILES 2> out/err; else timeout $TIMEOUT ./bon_$bs $BFILES 2> out/err; fi
		rc=$?
		if [ $rc = 42 ]; then ko "bonus BS=$bs: valgrind encontrou leaks ou erros" "$(vgmsg)"; continue; fi
		if [ $rc != 0 ]; then ko "bonus BS=$bs: crash ou timeout (codigo $rc)"; continue; fi
		i=0; allok=1
		for f in $BFILES; do
			cmp -s out/bonus_$i "$f" || { allok=0; ko "bonus BS=$bs: $(basename $f) misturou-se com outro ficheiro"; }
			i=$((i+1))
		done
		[ $allok = 1 ] && { ok "bonus BS=$bs: 6 ficheiros alternados, nenhum se misturou"; dot; }
	done
	sed "s/HEADER/get_next_line_bonus.h/; s/BIGFD/100000/" check_fd.c > check_fd_b.c
	if compile fd_b -D BUFFER_SIZE=42 check_fd_b.c $BONUS_SRC; then
		run_vg ./fd_b files/texto > out/res 2> out/err; rc=$?
		case $rc in
			0) ok "bonus: fd invalidos e fd enorme (100000) devolvem NULL sem crash"; dot;;
			42) ko "bonus: fd enorme acede a memoria fora do array (falta verificar o limite?)" "$(vgmsg)";;
			*) [ $rc -ge 128 ] && ko "bonus: fd enorme (100000) fez crash: falta verificar o limite do array?" || ko "bonus fd invalidos:" "$(cat out/res)";;
		esac
	fi
	[ -z "$VERBOSE" ] && echo
fi

# ---------------------------------------------------------------------------- #
#  5. Falhas de malloc (o GNL nunca pode devolver uma linha errada)            #
# ---------------------------------------------------------------------------- #
if [ -z "$NO_MALLOC" ]; then
	title "5. Falhas de malloc (extra: o subject nao exige; AVISO nao reprova)"
	if cc -I"$PROJ" -D BUFFER_SIZE=1 -Wl,--wrap=malloc check_malloc.c $MAND_SRC -o mal_test 2>/dev/null; then
		for bs in 1 3 42; do
			cc -I"$PROJ" -D BUFFER_SIZE=$bs -Wl,--wrap=malloc check_malloc.c $MAND_SRC -o mal_$bs 2>/dev/null
			for f in files/texto files/lines_around_10 files/variable_nls files/random_5; do
				run_vg ./mal_$bs "$f" > out/res 2> out/err; rc=$?
				res=$(grep TESTED out/res)
				tested=$(echo "$res" | awk '{print $2}'); wrong=$(echo "$res" | awk '{print $4}')
				if [ $rc = 42 ]; then warn "malloc BS=$bs $(basename $f): leaks quando o malloc falha" "$(vgmsg)"
				elif [ $rc -ge 124 ] || [ -z "$res" ]; then ko "malloc BS=$bs $(basename $f): crash ou timeout quando o malloc falha"
				elif [ "$wrong" != 0 ]; then warn "malloc BS=$bs $(basename $f): $wrong de $tested falhas devolveram uma linha errada" ""
				else ok "malloc BS=$bs $(basename $f): $tested falhas, sempre linhas certas ou NULL"; dot; fi
			done
		done
	else
		warn "o teste de malloc precisa do linker GNU (-Wl,--wrap): saltado neste sistema"
	fi
	[ -z "$VERBOSE" ] && echo
fi

# ---------------------------------------------------------------------------- #
#  Resumo                                                                      #
# ---------------------------------------------------------------------------- #
printf "\n${B}Resumo:${N} ${G}%d OK${N}   ${R}%d KO${N}   ${Y}%d avisos${N}\n" $OK $KO $WARN
[ $HAS_VG = 0 ] && printf "${Y}(sem valgrind: os leaks nao foram verificados)${N}\n"
[ $KO = 0 ] && printf "${G}${B}Tudo certo!${N}\n"
rm -rf "$WORK"
exit $((KO != 0))
