//+------------------------------------------------------------------+
//|                                     Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include "ColorChangeSignal.mqh"
//+------------------------------------------------------------------+
class CSingleLineColorChangeSignal : public CColorChangeSignal
  {
protected:
   virtual bool      InitIndicatorBuffers();
  };

bool CSingleLineColorChangeSignal::InitIndicatorBuffers()
  {
   m_buf_up = m_buf_down = m_indicator.At(m_buf_idx);
   return true;
  }
