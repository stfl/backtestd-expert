//+------------------------------------------------------------------+
//|                                     Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include "CustomSignal.mqh"
//+------------------------------------------------------------------+
class CZeroLineCrossSignal : public CCustomSignal
  {
protected:
   uint m_buf_idx;
   CIndicatorBuffer *m_buf_up;
   
public:
   //--- methods of checking if the market models are formed
   virtual bool      LongSide(void);
   virtual bool      ShortSide(void) { return !LongSide(); }
   virtual bool      LongSignal(void);
   virtual bool      ShortSignal(void);

protected:
   virtual bool      InitIndicatorBuffers();
  };
  
bool CZeroLineCrossSignal::LongSide(void)
  {
   int idx = StartIndex();
   geturn (m_buf.At(idx) > 0);
   return (up <= 0 && up_last > 0);
  }

bool CZeroLineCrossSignal::LongSignal(void)
  {
   int idx = StartIndex();
   return (m_buf.At(idx) > 0 && m_buf.At(idx+1) <= 0);
  }

bool CZeroLineCrossSignal::ShortSignal(void)
  {
   int idx = StartIndex();
   return (m_buf.At(idx) <= 0 && m_buf.At(idx+1) > 0);
  }

bool CZeroLineCrossSignal::InitIndicatorBuffers()
{
   m_buf = m_indicator.At(m_buf_idx);
   return true;
}
