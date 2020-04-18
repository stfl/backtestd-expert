//+------------------------------------------------------------------+
//|                                     Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include "CustomSignal.mqh"
//+------------------------------------------------------------------+
class CPriceCrossSignal : public CCustomSignal
  {
protected:
   CIndicatorBuffer *m_buf;

public:
   //--- methods of checking if the market models are formed
   virtual bool      LongSide(void);
   virtual bool      ShortSide(void) { return !LongSide(); }
   virtual bool      LongSignal(void);
   virtual bool      ShortSignal(void);

protected:
   virtual bool      InitIndicatorBuffers();
  };

bool CPriceCrossSignal::LongSide(void)
  {
   int idx = StartIndex();
   return (Close(idx) >= m_buf.At(idx));
  }

bool CPriceCrossSignal::LongSignal(void)
  {
   int idx = StartIndex();
   return (Close(idx) > m_buf.At(idx) && Close(idx+1) <= m_buf.At(idx+1));
  }

bool CPriceCrossSignal::ShortSignal(void)
  {
   int idx = StartIndex();
   return (Close(idx) <= m_buf.At(idx) && Close(idx+1) > m_buf.At(idx+1));
  }

bool CPriceCrossSignal::InitIndicatorBuffers()
{
   m_buf = m_indicator.At(m_buffers[0]);
   return true;
}
