// fire-and-forget a shell process

#ifndef task_h
#define task_h

class Task {
public:
  Task(const char* command);
  ~Task();
  
  int run();
protected:
  char* _command;
};

#endif
