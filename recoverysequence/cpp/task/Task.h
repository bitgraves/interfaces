// fire-and-forget a shell process

#ifndef task_h
#define task_h

class Task {
public:
  Task(const char* command, const char* arg);
  ~Task();
  
  int run();
protected:
  char* _command;
  char* _arg;
};

#endif
