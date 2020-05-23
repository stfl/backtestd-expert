//+------------------------------------------------------------------+
//|                                     Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include "TwoLinesColorChangeSignal.mqh"
//+------------------------------------------------------------------+
class CColorChangeSignal : public CTwoLinesColorChangeSignal
  {
protected:
   virtual bool      InitIndicatorBuffers();
  };

bool CColorChangeSignal::InitIndicatorBuffers()
  {
   m_buf_up = m_buf_down = m_indicator.At(m_buffers[0]);
   m_color_neutr = (uint)m_config[0];
   m_color_up = (uint)m_config[1];
   m_color_down = (uint)m_config[2];
   return true;
  }
