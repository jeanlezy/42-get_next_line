*This project has been created as part of the 42 curriculum by jeanbarr.*

<h1 align="center">📄 get_next_line</h1>

## 📖 Description

<table> <tr> <td valign="middle" width="50%">

get_next_line recodes a function that reads a text file descriptor **one line at a time**. Each call returns the next line, including the terminating `\n` (except for the last line, if the file does not end with one). When there is nothing left to read, or an error occurs, it returns `NULL`. The goal of the project is to learn how **static variables** work in C: a variable that keeps its value between calls, which lets the function remember what it already read from the file descriptor.

</td> <td align="center" valign="middle" width="50%"> <img src="https://media.tenor.com/KvlY04J4vLsAAAAM/goldberg-wwe.gif" alt="Libft animation" width="100%"> </td> </tr> </table>
The function follows the required prototype:

```c
char	*get_next_line(int fd);
```

It works with regular files, the standard input, and any other file descriptor that `read()` can use. Only `read`, `malloc` and `free` are used.

---

## ⚙️ Instructions

**Requirements:** `cc`.

The project has no Makefile. The buffer size is set at compile time with `-D BUFFER_SIZE=n`. If the flag is not given, the default value is `42`.

**Mandatory part:**

```sh
cc -Wall -Wextra -Werror -D BUFFER_SIZE=42 get_next_line.c get_next_line_utils.c main.c -o gnl
./gnl
```

**Bonus part:**

```sh
cc -Wall -Wextra -Werror -D BUFFER_SIZE=42 get_next_line_bonus.c get_next_line_utils_bonus.c main.c -o gnl_bonus
./gnl_bonus
```

A minimal `main.c`:

```c
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include "get_next_line.h"

int	main(void)
{
	int		fd;
	char	*line;

	fd = open("test.txt", O_RDONLY);
	if (fd < 0)
		return (1);
	line = get_next_line(fd);
	while (line)
	{
		printf("%s", line);
		free(line);
		line = get_next_line(fd);
	}
	close(fd);
	return (0);
}
```

The caller must `free` every line returned.

---

## 🔧 Function description

### Files

| File | Role |
|---|---|
| `get_next_line.h` | Prototype of `get_next_line`, the helper prototypes, and the default values of `BUFFER_SIZE` and `SEP` |
| `get_next_line.c` | `get_next_line` and its three `static` helpers: read, extract, refresh |
| `get_next_line_utils.c` | String helpers: `gnl_strlen`, `gnl_strchr`, `gnl_strjoin`, `gnl_substr` |
| `get_next_line_bonus.h` | Same as the header above, plus `FD_MAX` |
| `get_next_line_bonus.c` | Version that handles several file descriptors at the same time |
| `get_next_line_utils_bonus.c` | Same helpers as the mandatory part |

### Configurable values

| Macro | Default | Meaning |
|---|---|---|
| `BUFFER_SIZE` | `42` | Number of bytes requested in each `read()` call |
| `SEP` | `'\n'` | The character that ends a line |
| `FD_MAX` | `1024` | Number of file descriptors the bonus version can track |

### Algorithm and data structure

**The stash.** The function has one `static char *stash`. It holds the characters that were already read from the file descriptor but not yet returned. Because it is `static`, it keeps its content between calls, and no global variable is needed.

**One call, three steps.** Every call to `get_next_line` does the same three things:

1. **Read and stash** (`ft_read_and_stash`). While the stash has no `SEP` and the file has not ended, it calls `read()` with `BUFFER_SIZE` bytes, ends the buffer with `'\0'`, and appends it to the stash with `gnl_strjoin`. It stops as soon as the stash contains a separator, so it reads as little as possible and never loads the whole file.
2. **Extract the line** (`ft_extract_line`). It finds the first `SEP` in the stash and copies everything up to it, including the separator, with `gnl_substr`. If there is no separator, the end of the file was reached, and it copies what is left.
3. **Refresh the stash** (`ft_refresh_stash`). It builds a new stash with what comes after the returned line, and frees the old one. If nothing is left, the stash becomes `NULL`.

**Error handling.** Before reading, the function checks fd < 0 and BUFFER_SIZE <= 0 (the bonus version also checks fd >= FD_MAX). In these cases it frees the stash and returns NULL. After that, errors are detected during the reading itself: a read() that returns -1, or a failed malloc, frees the stash and returns NULL. A failed call never leaves allocated memory behind, and the next call starts clean.

**Bonus: multiple file descriptors.** The bonus version still has only **one static variable**, but it is an array: `static char *stash[FD_MAX]`. Each file descriptor uses its own position, `stash[fd]`, so reading fd 3, then 4, then 3 again never mixes the state of different files.

*Why this choice:*
- **It reads as little as possible.** The loop stops at the first separator, as the subject asks. A line is returned as soon as it is complete.
- **It works for any `BUFFER_SIZE`.** The stash does not depend on the size of the buffer. With `1`, the function reads byte by byte; with `10000000`, it reads a big chunk and the remainder stays in the stash for the next calls. Only the number of `read()` calls changes.
- **It is simple to follow and to change.** Each of the three helpers has one job, and everything fits inside the Norm. Changing the separator only requires changing `SEP`.
- **Memory has one owner at a time.** `gnl_strjoin` frees the old stash itself and `ft_refresh_stash` frees the stash it replaces, so each block of memory has a clear moment where it is freed.

### Limitations

- Every call to `gnl_strjoin` allocates a new string and copies the whole stash. For a very long line read with a very small `BUFFER_SIZE`, this makes the cost grow quickly. It is the price paid for a simple stash.
- The behavior with binary files, or with a file modified between calls, is undefined, as the subject says.
- The bonus version tracks file descriptors from `0` to `FD_MAX - 1`.

### Testing

Cases worth testing, with several values of `BUFFER_SIZE` (`1`, `2`, `42`, `9999`, `10000000`):

- An empty file, and a file with only `\n`.
- A file that ends with `\n`, and one that does not.
- Lines of very different sizes, including a line longer than `BUFFER_SIZE`.
- Several empty lines in a row.
- The standard input (`./gnl < file` and typing in the terminal).
- An invalid file descriptor (`-1`, a closed fd) and a directory.
- Bonus: alternating calls between two or three open files.

Also run `norminette` on all files (bonus included) and `valgrind --leak-check=full` on the test program.

---

## 📚 Resources

- Manual pages: `man 2 read`, `man 3 malloc`, `man 3 free` and `man 2 open`.
- [GeeksforGeeks - Static Variables in C](https://www.geeksforgeeks.org/c/static-variables-in-c/)
- [Wikipedia - File descriptor](https://en.wikipedia.org/wiki/File_descriptor)
- [The Norm - 42](https://github.com/42School/norminette)
- get_next_line subject provided by the school

### How AI was used

AI was used as a learning and review tool during this project, for these tasks:

- **Understanding the concepts:** explaining what a `static` variable is and how a file descriptor and `read()` behave.
- **Code review and testing:** reviewing edge cases (empty files, no final `\n`, different `BUFFER_SIZE` values, memory leaks) for `get_next_line` and its helpers.
- **README:** drafting this file.

The code of the functions was written by me.