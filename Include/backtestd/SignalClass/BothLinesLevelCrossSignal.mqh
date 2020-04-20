//+------------------------------------------------------------------+
//|                                     Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include "BothLinesTwoLevelsCrossSignal.mqh"
//+------------------------------------------------------------------+
class CBothLinesLevelCrossSignal : public CBothLinesTwoLevelsCrossSignal {
protected:
  virtual bool InitIndicatorBuffers();
};

bool CBothLinesLevelCrossSignal::InitIndicatorBuffers() {
  m_buf_up = m_indicator.At(m_buffers[0]);
  m_buf_down = m_indicator.At(m_buffers[1]);
  m_level_up_enter = m_level_up_exit = m_level_down_enter = m_level_down_exit =
      m_config[0];
  m_stateful_side = m_config[1];
  return true;
}
