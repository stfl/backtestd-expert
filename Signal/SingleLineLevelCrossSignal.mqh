//+------------------------------------------------------------------+
//|                                     Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include "LevelCrossSignal.mqh"
//+------------------------------------------------------------------+
class CSingleLineLevelCrossSignal : public CLevelCrossSignal
  {
protected:
   CSingleLineLevelCrossSignal(void);
   virtual bool InitIndicatorBuffers(void);
  };

CSingleLineLevelCrossSignal::CSingleLineLevelCrossSignal(void) {
    m_down_idx = m_buf_idx;
}

 bool CSingleLineLevelCrossSignal::InitIndicatorBuffers(void)
 {
    // use the same buffer
    m_buf_down = m_indicator.At(m_buf_idx);

    return true;
 }
