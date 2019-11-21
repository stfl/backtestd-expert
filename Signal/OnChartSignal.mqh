//+------------------------------------------------------------------+
//|                                     Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include "CustomSignal.mqh"
//+------------------------------------------------------------------+
class COnChartSignal : public CCustomSignal
  {
protected:
   uint              m_buf_idx;
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

bool COnChartSignal::LongSide(void)
  {
   int idx = StartIndex();
   return (Close(idx) >= m_buf.At(idx));
  }

bool COnChartSignal::LongSignal(void)
  {
   int idx = StartIndex();
   return (Close(idx) > m_buf.At(idx) && Close(idx+1) <= m_buf.At(idx+1));
  }

bool COnChartSignal::ShortSignal(void)
  {
   int idx = StartIndex();
   return (Close(idx) <= m_buf.At(idx) && Close(idx+1) > m_buf.At(idx+1));
  }

bool COnChartSignal::InitIndicatorBuffers()
{
   m_buf = m_indicator.At(m_buf_idx);
   return true;
}
