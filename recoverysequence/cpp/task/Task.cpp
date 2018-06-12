#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <string.h>

#include "Task.h"

Task::Task(const char* command) {
  _command = strdup(command);
}

Task::~Task() {
  if (_command) {
    free(_command);
    _command = NULL;
  }
}

int Task::run() {
  pid_t processId;
  if ((processId = fork()) == 0) {
    char * const argv[] = { "/bin/sh", "-c", _command, NULL };
    if (execv("/bin/sh", argv) < 0) {
      perror("execv error");
    }
  } else if (processId < 0) {
    perror("fork error");
  } else {
    return EXIT_SUCCESS;
  }
  return EXIT_FAILURE;
}
