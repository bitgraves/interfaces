#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <string.h>

#include "Task.h"

Task::Task(const char* command, const char* arg) {
  _command = strdup(command);
  _arg = strdup(arg);
}

Task::~Task() {
  if (_command) {
    free(_command);
    _command = NULL;
  }
  if (_arg) {
    free(_arg);
    _arg = NULL;
  }
}

int Task::run() {
  pid_t processId;
  if ((processId = fork()) == 0) {
    char * const argv[] = { _command, _arg, NULL };
    if (execv(_command, argv) < 0) {
      perror("execv error");
    }
  } else if (processId < 0) {
    perror("fork error");
  } else {
    return EXIT_SUCCESS;
  }
  return EXIT_FAILURE;
}
