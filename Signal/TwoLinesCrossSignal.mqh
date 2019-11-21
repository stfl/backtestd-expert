//+------------------------------------------------------------------+
//|                                     Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include "CustomSignal.mqh"
//+------------------------------------------------------------------+
class CTwoLinesCrossSignal : public CCustomSignal
  {
protected:
   uint              m_up_idx;
   uint              m_down_idx;
   CIndicatorBuffer *m_buf_up;
   CIndicatorBuffer *m_buf_down;

public:
   //--- methods of checking if the market models are formed
   virtual bool      LongSide(void);
   virtual bool      ShortSide(void) { return !LongSide(); }
   virtual bool      LongSignal(void);
   virtual bool      ShortSignal(void);

protected:
   virtual bool      InitIndicatorBuffers();
  };

bool CTwoLinesCrossSignal::LongSide(void)
  {
   int idx = StartIndex();
   return (m_buf_up.At(idx) > m_buf_down.At(idx));
  }

bool CTwoLinesCrossSignal::LongSignal(void)
  {
   int idx = StartIndex();
   return (m_buf_up.At(idx) > m_buf_down.At(idx) && m_buf_up.At(idx+1) <= m_buf_down.At(idx+1));
  }

bool CTwoLinesCrossSignal::ShortSignal(void)
  {
   int idx = StartIndex();
   return (m_buf_up.At(idx) <= m_buf_down.At(idx) && m_buf_up.At(idx+1) > m_buf_down.At(idx+1));
  }

bool CTwoLinesCrossSignal::InitIndicatorBuffers()
{
   m_buf_up = m_indicator.At(m_up_idx);
   m_buf_down = m_indicator.At(m_down_idx);
   return true;
}
