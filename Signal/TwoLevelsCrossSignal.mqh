//+------------------------------------------------------------------+
//|                                     Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include "TwoLinesTwoLevelsCrossSignal.mqh"
//+------------------------------------------------------------------+
class CTwoLevelsCrossSignal : public CTwoLinesTwoLevelsCrossSignal
  {
protected:
   virtual bool      InitIndicatorBuffers();
  };

bool CTwoLevelsCrossSignal::InitIndicatorBuffers()
{
   m_buf_up = m_buf_down = m_indicator.At(m_buffers[0]);
   m_level_up_enter = m_config[0];  // TODO this could be ignored, if this is moved to InitIndicators
   m_level_up_exit = m_config[1];
   m_level_down_enter = m_config[2];
   m_level_down_exit = m_config[3];
   return true;
}
