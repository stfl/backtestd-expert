//+------------------------------------------------------------------+
//|                                     Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include "LevelCrossSignal.mqh"
//+------------------------------------------------------------------+
class CSingleLineLevelCrossSignal : public CLevelCrossSignal
  {
protected:
   virtual bool      InitIndicatorBuffers();
  };

bool CSingleLineLevelCrossSignal::InitIndicatorBuffers()
{
   m_buf_up = m_buf_down = m_indicator.At(m_buf_idx);
   return true;
}
