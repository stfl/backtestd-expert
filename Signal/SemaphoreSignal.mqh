//+------------------------------------------------------------------+
//|                                     Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+

#include "CustomSignal.mqh"
//+------------------------------------------------------------------+
class CSemaphoreSignal : public CCustomSignal
  {
protected:
   uint              m_buf_idx;
   uint              m_down_idx;
   CIndicatorBuffer *m_buf_up;
   CIndicatorBuffer *m_buf_down;
   int               m_last_signal;

public:
   //--- methods of checking if the market models are formed
   virtual bool      LongSide(void)  { return (m_last_signal > 0); }
   virtual bool      ShortSide(void) { return (m_last_signal < 0); }
   virtual bool      LongSignal(void);
   virtual bool      ShortSignal(void);

protected:
   virtual bool      InitIndicatorBuffers();
  };

bool CSemaphoreSignal::LongSignal(void)
  {
   int idx = StartIndex();
   double Signal=m_buf_up.At(idx);
   if (Signal && Signal!=EMPTY_VALUE) {
      m_last_signal = 100;
      return true;
   }
   else
   return false;
  }

bool CSemaphoreSignal::ShortSignal(void)
  {
   int idx = StartIndex();
   double Signal=m_buf_down.At(idx);
   if (Signal && Signal!=EMPTY_VALUE) {
      m_last_signal = -100;
      return true;
   }
   else
   return false;
  }

bool CSemaphoreSignal::InitIndicatorBuffers()
  {
   m_buf_up = m_indicator.At(m_buf_idx);
   m_buf_down = m_indicator.At(m_down_idx);

   m_last_signal = 0;
   return true;
  }
