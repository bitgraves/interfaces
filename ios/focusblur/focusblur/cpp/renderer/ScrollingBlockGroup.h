
#ifndef __SCROLLING_BLOCK_GROUP_H__
#define __SCROLLING_BLOCK_GROUP_H__

#include "ScrollingBlock.h"

class Analyzer;
class Renderer;

class ScrollingBlockGroup {
public:
  ScrollingBlockGroup(Renderer *renderer);
  ~ScrollingBlockGroup();
  
  void setNumBlocks(unsigned int numBlocks);
  void render(Analyzer *ana);
private:
  unsigned int _numBlocks;
  ScrollingBlock **_blocks;
  Renderer *_renderer;
  void _clear();
};

#endif
