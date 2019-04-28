
#include "ScrollingBlockGroup.h"
#include "Renderer.h"

ScrollingBlockGroup::ScrollingBlockGroup(Renderer *renderer) : _numBlocks(0), _blocks(NULL) {
  _renderer = renderer;
}

ScrollingBlockGroup::~ScrollingBlockGroup() {
  this->_clear();
}

void ScrollingBlockGroup::setNumBlocks(unsigned int numBlocks) {
  if (numBlocks != _numBlocks) {
    this->_clear();
    _numBlocks = numBlocks;
    if (numBlocks > 0) {
      _blocks = (ScrollingBlock **)malloc(_numBlocks * sizeof(ScrollingBlock *));
      float blockWidth = 1.0 / _numBlocks;
      for (unsigned int ii = 0; ii < _numBlocks; ii++) {
        _blocks[ii] = new ScrollingBlock(_renderer);
        (_blocks[ii])->setBounds(blockWidth * ii, blockWidth * (ii + 1.0));
      }
    }
  }
}

void ScrollingBlockGroup::render(Analyzer *ana) {
  for (unsigned int ii = 0; ii < _numBlocks; ii++) {
    (_blocks[ii])->render(ana);
  }
}

void ScrollingBlockGroup::_clear() {
  if (_numBlocks > 0) {
    for (unsigned int ii = 0; ii < _numBlocks; ii++) {
      delete _blocks[ii];
    }
    free(_blocks);
    _blocks = NULL;
    _numBlocks = 0;
  }
}
